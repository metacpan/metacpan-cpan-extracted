package Local::BoundedCommand;

use strict;
use warnings;
use utf8;

use Exporter qw(import);
use POSIX qw(:sys_wait_h);
use Time::HiRes ();

our @EXPORT_OK = qw(run_bounded);

# How often the parent asks whether the child has finished. Short enough that a
# command which exits normally is not delayed noticeably, long enough that
# waiting costs nothing measurable.
my $POLL_SECONDS = 0.05;

# How long a signalled process group is given to die politely before it is killed
# outright. The wedge this module exists to prevent held a browser tree open for
# two days, so the escalation is not optional - but a browser asked to stop does
# usually stop, and a TERM lets it close its own children.
my $GRACE_SECONDS = 2;

# Linux prctl(2) has no core Perl binding, so the two constants below are the
# raw values needed to call it via syscall(). PR_SET_CHILD_SUBREAPER is stable
# ABI (Linux since 3.4); the syscall number is architecture-specific, which is
# why _set_child_subreaper restricts itself to the one architecture this
# project builds and tests on (DD-1051 KD).
my $PR_SET_CHILD_SUBREAPER = 36;
my $SYS_PRCTL_X86_64_LINUX = 157;

# run_bounded(%args)
# Runs one command with a wall-clock bound and reports what happened, instead of
# waiting for a command that may never return.
# Input: hash with command arrayref, seconds number, and optional label string.
# Output: hashref with timed_out, exit, and message fields.
#
# WHY IT SIGNALS A PROCESS GROUP RATHER THAN A PID
#   The failure that produced this module left seven processes alive for two
#   days: a perl parent, its Devel::Cover child, a web server, a starman master
#   and worker, and a browser tree. Killing the direct child would have reaped
#   one of them. The child is therefore given its own process group and the GROUP
#   is signalled, so everything the command started dies with it.
#
# WHY IT RETURNS A VERDICT INSTEAD OF DYING
#   The caller knows what the command was for and can say so; this only knows
#   that a bound was exceeded. Returning lets the caller fail in its own words,
#   and lets a test assert the timeout without trapping an exception.
#
# WHY IT BECOMES A SUBREAPER BEFORE FORKING (DD-1051)
#   A command that backgrounds a job and is then signalled before it reaps
#   that job itself orphans it. On a bare host that orphan reparents to init,
#   which reaps it straight away - but inside a container run without an init
#   that reaps orphans (a bare `docker run`, the shape this project's own
#   gate containers use), the orphan reparents to a PID 1 that never calls
#   wait() on anything, and it is a zombie for ever: `kill 0` still reports it
#   "alive" because the kernel keeps a zombie's pid slot until someone reaps
#   it. Declaring ourselves the reaper first means that orphan reparents to
#   THIS process instead of PID 1, and _terminate_group's sweep then reaps it
#   directly - the same mechanism every zombie-reaping init (tini, dumb-init)
#   uses, applied to just the one process group this call created.
sub run_bounded {
    my (%args) = @_;
    my $command = $args{command} || [];
    my $seconds = $args{seconds};
    my $label   = $args{label} || 'command';

    die 'run_bounded requires a command array reference' if ref($command) ne 'ARRAY' || !@{$command};
    die 'run_bounded requires a positive seconds bound' if !defined $seconds || $seconds <= 0;

    my $became_subreaper = _set_child_subreaper(1);

    my $pid = fork();
    die "run_bounded could not fork for $label: $!" if !defined $pid;

    if ( !$pid ) {
        # Own process group, so the parent can signal this command and everything
        # it starts without touching itself or its siblings.
        setpgrp( 0, 0 );
        exec { $command->[0] } @{$command};

        # exec only returns on failure, and the child must not fall through into
        # the caller's test code.
        exit 127;
    }

    my $deadline = Time::HiRes::time() + $seconds;
    while (1) {
        my $reaped = waitpid( $pid, WNOHANG );
        if ( $reaped == $pid ) {
            _set_child_subreaper(0) if $became_subreaper;
            return {
                timed_out => 0,
                exit      => $? >> 8,
                message   => '',
            };
        }

        last if Time::HiRes::time() >= $deadline;
        Time::HiRes::sleep($POLL_SECONDS);
    }

    _terminate_group( $pid, $became_subreaper );
    _set_child_subreaper(0) if $became_subreaper;

    return {
        timed_out => 1,
        exit      => -1,
        message   => sprintf(
            '%s exceeded its %s second bound and was killed with its whole process group; '
              . 'it was not waited on further, because an unbounded wait reports nothing at all',
            $label, $seconds
        ),
    };
}

# _set_child_subreaper($on)
# Best-effort prctl(2) PR_SET_CHILD_SUBREAPER toggle (see run_bounded's POD
# note for why). Perl has no core binding for prctl(2), so this reaches it via
# the raw syscall - restricted to the one platform/architecture this project
# builds and tests on, and never fatal: a process that cannot become the
# reaper simply cannot rescue an orphan, which is exactly the behaviour this
# module had before DD-1051.
# Input: 1 to become the subreaper for this process, 0 to stop.
# Output: true if the call is believed to have taken effect.
sub _set_child_subreaper {
    my ($on) = @_;

    return 0 if $^O ne 'linux';                                            # uncoverable branch true

    require Config;
    return 0 if $Config::Config{archname} !~ m{\Ax86_64-linux};            # uncoverable branch true

    my $ok = eval { syscall( $SYS_PRCTL_X86_64_LINUX, $PR_SET_CHILD_SUBREAPER, $on, 0, 0, 0 ) == 0 };
    return $ok ? 1 : 0;                                                    # uncoverable branch false
}

# _terminate_group($pid, $can_reap_orphans)
# Ends one process group politely, then without asking, and - when this
# process declared itself the group's reaper - collects any grandchild that
# outlived its own immediate parent instead of leaving it a zombie nobody
# will ever wait() on (DD-1051).
# Input: process id that is also its own group leader; whether
#        _set_child_subreaper(1) is believed to have taken effect.
# Output: none.
sub _terminate_group {
    my ( $pid, $can_reap_orphans ) = @_;

    kill 'TERM', -$pid;

    my $reaped_politely = 0;
    my $deadline         = Time::HiRes::time() + $GRACE_SECONDS;
    while ( Time::HiRes::time() < $deadline ) {
        if ( waitpid( $pid, WNOHANG ) == $pid ) {
            $reaped_politely = 1;
            last;
        }
        Time::HiRes::sleep($POLL_SECONDS);
    }

    if ( !$reaped_politely ) {
        kill 'KILL', -$pid;
        waitpid( $pid, 0 );
    }

    # A leader that dies from the TERM alone (dash, and most other direct
    # commands, do not trap it) never reaches the KILL escalation above - but
    # a grandchild it had backgrounded dies from that same group-wide TERM
    # and is orphaned exactly the same way, so the sweep runs on BOTH exit
    # paths, not only the escalated one (DD-1051: the earlier version of this
    # function returned on the polite path before ever reaching it).
    _reap_orphaned_group_members($pid) if $can_reap_orphans;
    return;
}

# _reap_orphaned_group_members($pid)
# Collects every process in $pid's process group that reparented to us
# because we are its subreaper - a backgrounded grandchild whose own parent
# died before it did.
#
# Reparenting happens as part of the dying parent's own exit, and the caller
# has already blocked on that exit via waitpid($pid, 0) - so by the time this
# runs, the kernel has already reparented every surviving member of the
# group to us; a WNOHANG of -1 (no such child) here means genuinely nothing
# was orphaned, not "not yet". What is NOT guaranteed instantaneous is a
# reparented process finishing its own death from the KILL it already
# received, so a 0 (exists, not yet exited) keeps polling up to the grace
# window rather than being treated as done.
# Input: the process group id (the killed command's own pid).
# Output: none.
sub _reap_orphaned_group_members {
    my ($pid) = @_;

    my $deadline = Time::HiRes::time() + $GRACE_SECONDS;
    while ( Time::HiRes::time() < $deadline ) {
        my $reaped = waitpid( -$pid, WNOHANG );
        last if $reaped == -1;    # nothing in this group was ever reparented to us
        Time::HiRes::sleep($POLL_SECONDS) if $reaped == 0;
    }
    return;
}

1;

__END__

=head1 NAME

Local::BoundedCommand - run an external command under a wall-clock bound

=head1 PURPOSE

Give the test suite a way to run an external program that cannot hang the run.
The command is given a time budget; if it outlives it, the command and every
process it started are killed and the caller is told, in words, what exceeded
what.

=head1 WHY IT EXISTS

On 11 August 2026 a coverage run wedged in the SSL browser smoke test on a
headless Chrome fetch of a loopback URL that never answered, and sat there for
one day and twenty hours. Nothing failed, nothing exited, and no error was
printed; the run's log simply stopped growing, which looks exactly like a log
between two slow tests. Two days of wall clock were lost, and seven processes
stayed alive the whole time.

The browser fault itself is tracked separately and this module does not fix it.
What it fixes is the shape of the failure. An unbounded wait produces no
failure, no exit status and no last line - and silence from a gate is
indistinguishable from a gate that is still working. A bounded failure is
legible, and legibility is what makes a gate a check rather than a hope.

=head1 WHEN TO USE

For any external program a test runs whose completion is not guaranteed -
browsers, servers, network clients, anything that talks to something else.
Ordinary fast local commands do not need it, though nothing breaks if they use
it.

=head1 A GRANDCHILD OUTLIVING ITS OWN PARENT (DD-1051)

A command that backgrounds work of its own (C<sh -c 'sleep 600 & sleep 600'>)
and is then killed before it reaps that background job orphans it. A bare
C<docker run> - no C<--init>, the shape of every container this project's own
gate scripts start - never reaps an orphan: it becomes a permanent zombie
under a PID 1 that never calls C<wait()>, and C<kill 0> keeps reporting it
"alive" because the kernel holds a zombie's pid slot open until someone
reaps it. C<run_bounded> now declares itself the reaper (Linux
C<PR_SET_CHILD_SUBREAPER>, x86_64 only - see C<_set_child_subreaper>) before
forking, so that orphan reparents to the caller instead of to PID 1, and gets
reaped directly once the group is killed. On a bare host, or on any other
platform/architecture, this is a no-op: init there already reaps the orphan
on its own, which is the behaviour this module always had.

=head1 HOW TO USE

    use Local::BoundedCommand qw(run_bounded);

    my $result = run_bounded(
        command => [ $browser, '--dump-dom', $url ],
        seconds => 120,
        label   => "browser fetch of $url",
    );
    die $result->{message} if $result->{timed_out};

=head1 WHAT USES IT

C<t/33-web-server-ssl-browser.t> for every external command it runs, and
C<t/152-bounded-command.t> which is its spec.

=head1 EXAMPLES

A command that finishes is unaffected and reports its own status:

    run_bounded( command => [ 'sh', '-c', 'exit 3' ], seconds => 30 );
    # { timed_out => 0, exit => 3, message => '' }

A command that outlives its bound is killed with its process group:

    run_bounded( command => [ 'sleep', '600' ], seconds => 2 );
    # { timed_out => 1, exit => -1, message => 'command exceeded its 2 second bound ...' }

=cut
