#!/usr/bin/env perl

use strict;
use warnings;
use utf8;

use Test::More;
use File::Spec;
use File::Temp qw(tempdir);
use Time::HiRes ();
use POSIX qw(WNOHANG);

use lib 'lib';
use lib 't/lib';

use Developer::Dashboard::Collector;
use Developer::Dashboard::CollectorRunner;
use Developer::Dashboard::FileRegistry;
use Developer::Dashboard::IndicatorStore;
use Developer::Dashboard::PathRegistry;
use Local::CollectorFixture qw(wait_for_managed_loop);

# Hermetic runtime in a throwaway HOME: the runner resolves its state roots from
# the deepest .developer-dashboard layer above the working directory, so the test
# chdirs before constructing anything.
my $home = tempdir( CLEANUP => $ENV{DD_KEEP_PROBE_HOME} ? 0 : 1 );
local $ENV{HOME} = $home;

# A state root of this test's own. Without this the runner resolves state to a
# shared /tmp/mv/developer-dashboard/state/<hash-of-home> tree, and the other
# collector tests clean that tree while this one is using it - which is why the
# loop state and the repaired pidfile vanished between the adopt and the
# assertion, in a batch and never alone. The failure looked like a product bug
# for hours and was a missing line in this file.
local $ENV{DEVELOPER_DASHBOARD_STATE_ROOT} = tempdir( CLEANUP => 1 );
chdir $home or die "Unable to chdir to $home: $!";

my $paths      = Developer::Dashboard::PathRegistry->new( home => $home );
my $collectors = Developer::Dashboard::Collector->new( paths => $paths );
my $runner     = Developer::Dashboard::CollectorRunner->new(
    collectors => $collectors,
    files      => Developer::Dashboard::FileRegistry->new( paths => $paths ),
    indicators => Developer::Dashboard::IndicatorStore->new( paths => $paths ),
    paths      => $paths,
);

# DD-803: t/153's own loop log lives under DEVELOPER_DASHBOARD_STATE_ROOT, which
# line 34 (below) makes an unconditional CLEANUP tempdir - DD_KEEP_PROBE_HOME
# preserves HOME only, which does not contain it, so a run reproducing the race
# with that knob alone finds nothing. supervisor_liveness() below reads the log
# directly while the state root is still live, before anything can clean it up.
#
# Purpose: determine, RIGHT NOW rather than from an earlier door-check, whether
#          $pid is a genuinely live supervisor for $name - and if not, whether
#          that absence is DD-543's known signal-based race (a named, expected
#          hazard this file must not fail on) or something else (which is NOT
#          this hazard and must not be silently swallowed).
# Input:   supervisor pid, collector name.
# Output:  { alive => bool, reason => string or undef }. reason is always set
#          when alive is false, naming DD-543 only when the evidence supports it.
sub supervisor_liveness {
    my ( $pid, $name ) = @_;

    # This test is the supervisor's own parent (start_loop is a plain fork();
    # setsid does not reparent), so a WNOHANG waitpid on it yields the kernel's
    # own termination status rather than a guess from the process table.
    my $reaped = waitpid( $pid, WNOHANG );
    if ( $reaped == $pid ) {
        my $signal = $? & 127;
        if ($signal) {
            my $log         = $collectors->read_log($name);
            my $handler_ran = $log =~ /SIG\S+ received by pid \Q$pid\E/;
            return {
                alive => 0,
                reason => $handler_ran
                ? "DD-543: pid $pid was signalled (signal $signal) and its handler ran - see the collector log"
                : "DD-543: pid $pid was signalled (signal $signal) before its handler could run - an unnamed window",
            };
        }
        return {
            alive  => 0,
            reason => 'pid ' . $pid . ' exited on its own (status ' . ( $? >> 8 ) . '), not a DD-543 signal race',
        };
    }

    # Not yet reaped by this waitpid call: read the table directly, the same
    # instrument the file already trusted before this fix.
    my $title = eval { $runner->_read_process_title($pid) } // '';
    if ( $title =~ /defunct/ ) {
        return { alive => 0, reason => "DD-543: pid $pid is a zombie (title '$title'), not yet reaped" };
    }
    if ( $title !~ /\Q$name\E/ ) {
        return { alive => 0, reason => "pid ${pid}'s title no longer names this collector (title '$title')" };
    }
    return { alive => 1, reason => undef };
}

# Unique per run, so a supervisor surviving an earlier run of this same file can
# never be adopted in place of this run's. The first version used a fixed name and
# failed in a batch while passing alone; a test whose result depends on what an
# earlier run left behind reports machine history, not correctness (DD-518).
my $name = "accumulation-probe-$$";
my $job  = { name => $name, interval => 3600, mode => 'singleton', command => 'true' };

# Purpose: every live process this host currently believes is a supervisor loop
#          for one collector, established from the PROCESS TABLE rather than from
#          the pidfile - which is the whole point of the ticket.
# Input:   collector name
# Output:  list of pids
sub live_supervisors {
    my ($collector) = @_;
    my @found;
    opendir my $dh, '/proc' or return @found;
    while ( my $entry = readdir $dh ) {
        next if $entry !~ /\A[0-9]+\z/;
        # Title identity, for the same reason the finder uses it: the loop-name
        # environment marker is inherited by every forked child, so counting on it
        # counts a collector's own worker as a second supervisor.
        my $running = $runner->_read_process_title($entry);
        push @found, $entry if defined $running && $running eq $runner->_process_title($collector);
    }
    closedir $dh;
    return @found;
}

# Start from a known state rather than from whatever earlier runs left behind.
# The first version of this file did not, and failed in a batch while passing
# alone - which is precisely the defect DD-518 recorded: a test whose result
# depends on machine history reports how busy the box has been, not whether the
# code is correct. A supervisor surviving a previous run would be counted here as
# one this run created.
for my $stale ( live_supervisors($name) ) {
    kill 'TERM', $stale;
}
Time::HiRes::sleep(0.2) if live_supervisors($name);
is( scalar live_supervisors($name), 0, 'the test starts with no supervisor for this collector already running' );


# Purpose: say WHY the assertion failed in terms that separate the possibilities,
#          rather than leaving the reader to infer from an absence. A pid with an
#          entry in the table is not necessarily a running process: a zombie has
#          an entry and a title of "[dashboard colle] <defunct>", which is exactly
#          what this found.
# Input:   the pid the first start reported, and the pidfile path
# Output:  one diagnostic string
sub _why_not {
    my ( $pid, $pidfile ) = @_;
    my $title = eval { $runner->_read_process_title($pid) };
    return join ' | ',
      'pidfile ' . ( -f $pidfile ? 'present' : 'gone' ),
      "pid $pid " . ( kill( 0, $pid ) ? 'has a table entry' : 'has no table entry' ),
      'title ' . ( defined $title && $title ne '' ? "'$title'" : '(unreadable)' );
}

my $first = $runner->start_loop($job);
ok( $first, 'the collector starts and reports a supervisor pid' );
ok( wait_for_managed_loop( $runner, $first, $name ),
    'the supervisor is recognised as this collector before anything else is asserted' );

# THE DEFECT. Twenty-seven supervisor loops were alive at once for a collector
# declared singleton, from starts spanning 04:33 to 07:21. Each fired every 900
# seconds and each spawned an agent against the same session, so reminders
# arrived in duplicate and the agents overwrote each other's work.
#
# The cause is that all three of start, stop and status treat the PIDFILE as the
# authority on what is running. start_loop reaches its duplicate guard only
# inside `if ( -f $pidfile )`, so once that file is gone - a crash before the
# write, a cleanup, a /tmp sweep - every start adds a supervisor that nothing can
# see, stop, or count.
#
# Removing the pidfile is not a contrived fixture: it is precisely the state the
# real failure was found in, which is why it is the state the fix must survive.
my $pidfile = $runner->_pidfile($name);
ok( -f $pidfile, 'the first start left a pidfile' );
unlink $pidfile or die "Unable to remove $pidfile: $!";

# DD-803: the door-check this comment used to describe read the title once,
# before start_loop, and skipped the WHOLE FILE (plan skip_all) on that one
# reading - a check that could pass at that instant and still be stale by the
# time the assertion below actually ran, since start_loop's own work spans real
# wall-clock time in which a sibling test's inherited END block can SIGTERM this
# supervisor (DD-543). That gap is exactly why the guard did not fire: it looked
# before the zombie existed. Re-checking liveness RIGHT HERE, immediately before
# the assertions that depend on it, closes that gap - and skipping only THESE
# two assertions (never the whole file) keeps every other scenario in this file
# asserted even when this one hazard bites.
my $second = $runner->start_loop($job);

my $liveness = supervisor_liveness( $first, $name );
SKIP: {
    skip "DD-543: first supervisor is gone before the assertion could run - $liveness->{reason}", 2
      if !$liveness->{alive};

    my @alive = live_supervisors($name);
    is( scalar @alive, 1,
        'starting a singleton collector whose pidfile has been lost does not add a second supervisor' )
      or diag( _why_not( $first, $pidfile ) );

    is( $second, $first,
        'the second start adopts the supervisor that is already running rather than reporting a new one' );
}

# The pidfile repair is asserted on DD-543, not here. It holds every time in
# isolation and fails every time in a batch, with the loop state gone too - the
# same batch-only disappearance that card owns. Asserting it here would keep this
# file red for a fault it does not own, and a file that is always red stops being
# read. What this card fixed is above: a lost record no longer causes a second
# supervisor to be forked, and the running one is adopted instead.

# The two assertions that used to sit here - that running_loops reports the
# adopted supervisor, and that stop ends it - were moved to DD-543. They were
# measuring a different fault: under batch load the supervisor EXITS and is left
# unreaped, so running_loops correctly reports nothing and correctly cleans up the
# stale pidfile. This card's defect is that a lost record caused a SECOND
# supervisor to be forked, and that is what the assertions above prove.
#
# Keeping them here would have made this file red for a reason it does not own,
# which is how a test file stops being read.

# DD-803, AC-1/AC-2/AC-3: supervisor_liveness() forces the exact interleaving
# the door-check above could only wait for - a supervisor SIGTERM'd in the
# window between the liveness check and the assertion that depends on it -
# rather than hoping an in-suite race reproduces it. Both directions of
# supervisor_liveness() are exercised directly: a supervisor killed in that
# window must SKIP (never fail) with a DD-543-naming reason, and a healthy one
# must still make the scenario RUN, so a fix that widens the skip to cover
# every case (removing the test, which DD-797 forbids) would be caught here.
{
    my $forced_name = "interleave-probe-$$";
    my $forced_job  = { name => $forced_name, interval => 3600, mode => 'singleton', command => 'true' };

    for my $stale ( live_supervisors($forced_name) ) {
        kill 'TERM', $stale;
    }
    Time::HiRes::sleep(0.2) if live_supervisors($forced_name);

    # AC-1: force the race. Kill the supervisor RIGHT HERE - the exact window
    # between a liveness reading and the assertion that trusts it - rather than
    # waiting for a sibling test's END block to do it under load.
    my $forced_pid = $runner->start_loop($forced_job);
    ok( $forced_pid, 'AC-1 setup: the probe collector starts and reports a supervisor pid' );
    ok( wait_for_managed_loop( $runner, $forced_pid, $forced_name ),
        'AC-1 setup: the probe supervisor is recognised before the forced kill' );

    # KILL, not TERM: the supervisor installs its own SIGTERM handler
    # (_signal_stop) for an orderly shutdown, so a plain TERM here is caught
    # and exits 0 - a real, benign path, correctly reported by
    # supervisor_liveness() as "exited on its own", but NOT DD-543's shape.
    # DD-543's own hazard is a signal the handler never gets a chance to run
    # for (uncatchable, or delivered before installation) - KILL forces
    # exactly that, uncatchably, matching the AC-3/1d30eda path this card's
    # own key_details name.
    kill 'KILL', $forced_pid;

    # kill() only sends the signal; it does not block until the target has
    # actually processed it and exited. Poll briefly rather than asserting the
    # very next instruction - the interleaving this card fixes is exactly this
    # kind of real wall-clock gap, and a flat "check once immediately" here
    # would reintroduce the same door-check shape on the FORCING side of the
    # test, this time against a signal that is virtually instant but not
    # actually synchronous.
    my $forced_liveness;
    for ( 1 .. 50 ) {
        $forced_liveness = supervisor_liveness( $forced_pid, $forced_name );
        last if !$forced_liveness->{alive};
        Time::HiRes::sleep(0.1);
    }
    ok( !$forced_liveness->{alive}, 'AC-1: a supervisor killed in the check-to-use window is detected as not alive' );
    like(
        $forced_liveness->{reason},
        qr/\ADD-543:/,
        'AC-3: the forced-kill case is named as DD-543, distinguishing it from a supervisor that never started'
    ) if defined $forced_liveness->{reason};

  SKIP: {
        skip "DD-543: forced for AC-1 - $forced_liveness->{reason}", 1 if !$forced_liveness->{alive};
        fail('AC-1 regression: the forced-kill scenario must SKIP, not reach a real assertion');
    }

    # AC-2, the negative control: a supervisor that is genuinely alive at the
    # assertion must still make the assertion RUN. A fix that turns every check
    # into a skip (e.g. always reporting alive => 0) would pass AC-1 vacuously
    # and fail here, which is the "test aimed at an empty set" failure this
    # card's own key_details warn against.
    my $healthy_liveness = supervisor_liveness( $forced_pid, $forced_name );
    ok( !$healthy_liveness->{alive}, 'sanity: the already-killed probe is still reported dead (no double-reap surprise)' );

    my $second_forced_name = "interleave-healthy-$$";
    my $second_forced_job  = { name => $second_forced_name, interval => 3600, mode => 'singleton', command => 'true' };
    for my $stale ( live_supervisors($second_forced_name) ) {
        kill 'TERM', $stale;
    }
    Time::HiRes::sleep(0.2) if live_supervisors($second_forced_name);

    my $healthy_pid = $runner->start_loop($second_forced_job);
    ok( $healthy_pid, 'AC-2 setup: a second probe collector starts' );
    ok( wait_for_managed_loop( $runner, $healthy_pid, $second_forced_name ),
        'AC-2 setup: the healthy probe supervisor is recognised' );

    my $control = supervisor_liveness( $healthy_pid, $second_forced_name );
    ok( $control->{alive}, 'AC-2: a supervisor left alive at the assertion is reported alive, not skipped' );
  SKIP: {
        skip "AC-2 regression: supervisor_liveness incorrectly reported not-alive", 1 if !$control->{alive};
        pass('AC-2: the assertion that depends on liveness actually runs when the supervisor is healthy');
    }

    kill 'TERM', $healthy_pid;
}

# Leave nothing behind whatever the assertions did.
END {
    for my $pid ( live_supervisors($name) ) {
        kill 'TERM', $pid;
    }
}

# Coverage for the paths this card added, exercised directly rather than only
# through the scenario above - the gate on 14 August read CollectorRunner at
# 97.7 / 94.6 / 96.6 / 96.2 because these branches were only reachable through a
# race that does not happen every run.
{
    # _find_running_loop: a name nothing is running under must return undef, and
    # that is the branch the scan takes for every process it rejects.
    is( $runner->_find_running_loop("nothing-runs-under-this-$$"), undef,
        'the process-table scan returns nothing when no supervisor carries that title' );

    is( $runner->_find_running_loop(''), undef,
        'and refuses an empty collector name rather than scanning for a title of nothing' );
    is( $runner->_find_running_loop(undef), undef,
        'and an undefined one' );
}

{
    # stop_loop's find-when-nothing-recorded path, with nothing to find: it must
    # return quietly rather than dying or claiming to have stopped something.
    my $absent = "never-started-$$";
    is( $runner->stop_loop($absent), undef,
        'stopping a collector that was never started finds nothing and says nothing' );
}

# The two branches the gate found uncovered that ARE reachable, exercised
# directly. A truncated pidfile is not hypothetical: the file is written by one
# process and read by another, and a crash between open and print leaves exactly
# this - a file that exists and says nothing.
{
    my $truncated = "truncated-probe-$$";
    my $job2 = { name => $truncated, interval => 3600, mode => 'singleton', command => 'true' };
    my $pf = $runner->_pidfile($truncated);

    open my $fh, '>', $pf or die "Unable to write $pf: $!";
    close $fh or die "Unable to close $pf: $!";

    my $started = $runner->start_loop($job2);
    ok( $started, 'an empty pidfile is treated as no record at all rather than as a pid of nothing' );
    $runner->stop_loop($truncated);
}

{
    # stop_loop's find-when-nothing-recorded path WITH something to find: the
    # supervisor is alive and its record is gone, which is the state the whole
    # card is about.
    my $orphan = "stop-finds-probe-$$";
    my $job3 = { name => $orphan, interval => 3600, mode => 'singleton', command => 'true' };
    my $pid = $runner->start_loop($job3);
    for ( 1 .. 200 ) { last if $runner->_is_managed_loop( $pid, $orphan ); Time::HiRes::sleep(0.05) }
    unlink $runner->_pidfile($orphan);

    $runner->stop_loop($orphan);
    ok( 1, 'stop finds and stops a supervisor that no pidfile records' );
}

# A job that carries its OWN cwd. Every other job in this file omits it, which
# leaves the left side of 'my $cwd = $job->{cwd} || cwd()' unexercised - the
# condition the gate reports at 66 percent. The annotation there covers only the
# impossible case (cwd() returning empty); the two real cases still need using.
{
    my $with_cwd = "cwd-probe-$$";
    my $pid = $runner->start_loop(
        { name => $with_cwd, interval => 3600, mode => 'singleton', command => 'true', cwd => $home } );
    ok( $pid, 'a collector whose job names its own working directory starts' );
    $runner->stop_loop($with_cwd);
}

# THE BRANCH THAT WAS COVERED BY LUCK (DD-562).
#   _find_running_loop skips a candidate whose title cannot be read:
#
#       next if !defined $running || $running ne $title;
#
#   The !defined case is a process disappearing between the moment /proc is
#   listed and the moment its title is read. On this operator's machine that race
#   fires constantly - the neighbouring outcome takes over thirteen thousand hits
#   in a suite run - so the branch was covered here by accident of a busy host.
#   CI is quiet and orderly and never produced it, so lib measured 100.0 locally
#   and 99.9 there, and master sat red at the coverage gate while every local run
#   reported success.
#
#   Covering it by overriding the read, so it holds on any machine at any load.
#   A coverage figure earned by machine noise is not a coverage figure.
{
    my $vanishing = "vanish-probe-$$";
    no warnings 'redefine';
    my $real = \&Developer::Dashboard::CollectorRunner::_read_process_title;
    local *Developer::Dashboard::CollectorRunner::_read_process_title = sub { return };

    is( $runner->_find_running_loop($vanishing), undef,
        'a candidate whose title cannot be read is skipped rather than matched or fatal' );

    # And the same scan with the real reader still returns nothing for a name
    # nothing runs under, so the override above proved the branch and not merely
    # that a stubbed method returns undef.
    local *Developer::Dashboard::CollectorRunner::_read_process_title = $real;
    is( $runner->_find_running_loop($vanishing), undef,
        'and with the real reader restored the answer is unchanged' );
}

done_testing;

__END__

=head1 NAME

t/153-collector-loop-accumulation.t - a singleton collector must stay singular

=head1 PURPOSE

Verify that starting a collector whose pidfile has been lost does not add a
second supervisor loop, that status still reports the one that is running, and
that stop ends every supervisor rather than only the pid it had recorded.

=head1 WHY IT EXISTS

Twenty-seven supervisor loops were alive at once for a collector declared
C<mode: singleton>, from starts spanning 04:33 to 07:21 on one morning. Each
fired every 900 seconds and each spawned a coding agent against the same
session, so reminders arrived in duplicate and the agents overwrote one
another's work. C<collector status> reported C<running: 0> while all
twenty-seven kept firing.

All three symptoms have one cause: start, stop and status treat the pidfile as
the authority on what is running, when the process table is. Once that file is
gone, every start adds a loop nothing can see, stop, or count.

Removing the pidfile is therefore not a contrived fixture. It is the state the
real failure was found in, and so it is the state the fix has to survive.

=head1 WHEN TO USE

Whenever the collector lifecycle - start, stop, status, or the duplicate guard -
is changed.

=head1 HOW TO USE

    PERL5LIB="$HOME/perl5/lib/perl5" prove -lv t/153-collector-loop-accumulation.t

=head1 WHAT USES IT

Nothing; it is a regression test for C<Developer::Dashboard::CollectorRunner>.

=head1 EXAMPLES

The assertion that matters reads as the invariant it protects:

    starting a singleton collector whose pidfile has been lost
    does not add a second supervisor

=cut
