package HMTest;
use strict;
use warnings;

use Exporter ();
use Errno ();
use IO::Socket::INET ();
use POSIX ();

our @ISA       = 'Exporter';
our @EXPORT_OK = qw(free_ports server_status server_reap slurp);

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

# Reaped children, so a status check and a later wait agree on what happened.
my %status;

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
