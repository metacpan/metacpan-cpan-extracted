package HMTest;
use strict;
use warnings;

use Exporter ();
use Errno ();
use File::Spec ();
use IO::Socket::INET ();
use POSIX ();

our @ISA       = 'Exporter';
our @EXPORT_OK = qw(free_ports quiet_child server_guard server_status
                    server_reap slurp);

# SIGPIPE, for the test process itself.
#
# Half of these tests exist to prove the server REFUSES something - a body
# over max_body, a smuggled request - and a refusal is a response followed by
# a close. The client is still writing the body it was told not to send, so
# its next write gets EPIPE, and EPIPE's default action kills the writer. That
# is a dead test file after every assertion in it has already passed: the
# smokers report `Wstat: 13 (Signal: PIPE)` with `0/476 subtests failed` and
# no plan, because done_testing never ran.
#
# Ignoring it turns the write into an undef return, which every write loop
# here already handles. The forked server is unaffected either way - it sets
# SIG_IGN itself, as any server must.
$SIG{PIPE} = 'IGNORE';

# Test helpers shared by the tests that fork a real server.
#
# Ports: every one of these tests used to derive its port from $$, which is
# fine on a developer box and wrong on a smoker. Two runs of this
# distribution whose pids happen to agree modulo 1000 land on the same port,
# the second one's bind() fails with EADDRINUSE, run() croaks, and - because
# the forked server has its STDERR pointed somewhere quiet - the test file
# carries on talking to the *other* run's server. It reads real pids out of
# real responses and reports nonsense. Ask the kernel for a port instead.

# Bind $n ephemeral listeners at once, note the ports, then drop them all.
# Holding them simultaneously is what stops two calls handing back the same
# port; the gap between the close here and the server's own bind is small
# and, unlike a pid-derived port, it is not systematically wrong.
sub free_ports {
    my $n = shift || 1;
    my (@sock, @port);
    for (1 .. $n) {
        my $s = IO::Socket::INET->new(
            LocalAddr => '127.0.0.1',
            LocalPort => 0,
            Proto     => 'tcp',
            Listen    => 5,
            ReuseAddr => 1,
        ) or last;
        push @sock, $s;
        push @port, $s->sockport;
    }
    close $_ for @sock;
    return @port == $n ? @port : ();
}

# First thing in a forked server child. Nothing in that child may hold the
# harness's TAP pipe: the harness reads until EOF, so one surviving server
# makes `make test` hang after every test in the file has already passed, and
# the smoker reports that as a SIGKILL rather than a failure.
#
# Reopening STDOUT is not enough. Test::Builder dups the pipe into its own
# handles when it loads, and a child forked afterwards inherits that copy
# untouched by the reopen, so those are closed too.
#
# The alarm is the backstop for the child that is never reaped at all - a die
# mid-test, or a parent killed outright. SIGALRM's default action kills; a
# TERM does not, because perl defers it to an op boundary the child never
# reaches while it is wedged in accept(2) or an SSL handshake.
#
# A supervisor owns SIGALRM itself (its scoreboard tick), so it carries this
# deadline rather than firing at it - 0.52; before that it cancelled it, and an
# orphaned pool ran for ever. Either way the backstop is a last resort measured
# in minutes: server_guard() below is what takes a pool down at once.
sub quiet_child {
    my (%o) = @_;
    my $null = File::Spec->devnull;
    # Which stream is the harness's, named by the pipe itself - taken BEFORE
    # the reopen below, while STDOUT and STDERR still point at it.
    my %tap;
    for my $h (\*STDOUT, \*STDERR) {
        next unless -p $h;
        my ($dev, $ino) = (stat $h)[0, 1];
        $tap{"$dev:$ino"} = 1 if defined $ino;
    }
    open STDOUT, '>', $null;
    open STDERR, '>', (defined $o{stderr} ? $o{stderr} : $null);
    if (my $tb = eval { Test::Builder->new }) {
        for my $h (eval { $tb->output }, eval { $tb->failure_output },
                   eval { $tb->todo_output }) {
            close $h if defined $h;
        }
    }
    # ... and then by descriptor, because closing them by name is not enough:
    # under a Test2-based Test::Builder those three handles are not the only
    # dups of the TAP stream, and an orphaned server holding one write end of
    # it makes the harness wait for an EOF that never comes - `make test` hangs
    # after the test file itself is gone, which a smoker reports as the whole
    # run being SIGKILLed.
    #
    # Only dups of THAT pipe, identified by its inode: a forked server can hold
    # an inherited pipe it needs - the arena's wakeup descriptors are pipes
    # made before the fork - and closing those leaves a worker deaf. Probed
    # through a dup of its own, so anything else is left exactly as it was.
    #
    # And pointed at the null device rather than closed. A descriptor closed
    # under the PerlIO handle that owns it leaves the handle live and the
    # NUMBER free, so the next thing this server opens takes it and a later
    # flush of that handle writes into a socket, or a mapping, that belongs to
    # somebody else. The harness gets its EOF either way, since no write end of
    # its pipe survives.
    if (%tap && open my $sink, '>', $null) {
        my $nul = fileno $sink;
        for my $fd (3 .. 63) {
            next if $fd == $nul;
            my $dup = eval { POSIX::dup($fd) };
            next unless defined $dup;
            my $theirs = 0;
            if (open my $probe, '<&=', $dup) {
                my ($dev, $ino) = (stat $probe)[0, 1];
                $theirs = defined $ino && $tap{"$dev:$ino"};
                close $probe;
            }
            else { POSIX::close($dup) }
            POSIX::dup2($nul, $fd) if $theirs;
        }
    }
    alarm(defined $o{alarm} ? $o{alarm} : 120);
}

# Reaped children, so a status check and a later wait agree on what happened.
my %status;

# A forked server this test process is responsible for. Register it as soon as
# fork() returns and the END block below tears it down however the file ends -
# including a die in the middle, which is the case the tests themselves cannot
# cover: an assertion that fails on the way to `kill TERM` leaves a whole pool
# running, and a pool nobody kills outlives the harness. A smoker reports that
# as the entire run being SIGKILLed, so the report loses every test file after
# the one that died. The pid is returned so a fork can be wrapped in place.
my $owner = $$;
my @guarded;

sub server_guard {
    my $pid = shift;
    push @guarded, $pid if $pid;
    return $pid;
}

END {
    return unless $$ == $owner;      # never from inside a forked server
    for my $pid (reverse @guarded) {
        next if exists $status{$pid};
        next unless kill 'TERM', $pid;
        my $gone = 0;
        for (1 .. 40) {
            if (waitpid($pid, POSIX::WNOHANG()) == $pid) { $gone = 1; last }
            select undef, undef, undef, 0.05;
        }
        next if $gone;
        kill 'KILL', $pid;
        waitpid $pid, 0;
    }
}

sub _describe {
    my $st = shift;
    return sprintf 'killed by signal %d', $st & 127 if $st & 127;
    # perl exits a failed process with errno when errno is set, so a croak
    # out of a failed bind() surfaces as an exit status of EADDRINUSE.
    my $code = $st >> 8;
    return sprintf 'exited with %d%s', $code,
        $code == Errno::EADDRINUSE() ? ' (EADDRINUSE: the port was taken)' : '';
}

# Has the forked server already gone? undef while it is alive, a printable
# status once it is not, so a test about to poll a dead port for fifteen
# seconds can say why nobody is answering.
sub server_status {
    my $pid = shift;
    return _describe($status{$pid}) if exists $status{$pid};
    return undef unless waitpid($pid, POSIX::WNOHANG()) == $pid;
    $status{$pid} = $?;
    return _describe($?);
}

# Blocking reap, returning the raw wait status. Safe after server_status()
# has already collected the child.
sub server_reap {
    my $pid = shift;
    return $status{$pid} if exists $status{$pid};
    waitpid $pid, 0;
    return $status{$pid} = $?;
}

sub slurp {
    my $file = shift;
    open my $fh, '<', $file or return '';
    local $/;
    my $c = <$fh>;
    close $fh;
    return defined $c ? $c : '';
}

1;
