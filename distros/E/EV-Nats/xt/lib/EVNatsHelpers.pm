package EVNatsHelpers;
use strict;
use warnings;
use Exporter 'import';
use IO::Socket::INET;
use Test::More ();
use EV;

our @EXPORT_OK = qw(
    nats_or_skip
    js_or_skip
    free_port
    nats_bin_or_skip
    spawn_nats
);

# Probe TEST_NATS_HOST:TEST_NATS_PORT (defaulting to 127.0.0.1:4222)
# and skip the entire test plan if unreachable. Returns ($host, $port).
sub nats_or_skip {
    my $host = $ENV{TEST_NATS_HOST} || '127.0.0.1';
    my $port = $ENV{TEST_NATS_PORT} || 4222;
    my $sock = IO::Socket::INET->new(
        PeerAddr => $host, PeerPort => $port, Timeout => 1,
    );
    Test::More::plan(skip_all => "NATS server not available at $host:$port")
        unless $sock;
    close $sock;
    return ($host, $port);
}

# Probe whether JetStream is enabled by attempting an idempotent op via
# the supplied callback, which should call its own callback with $err.
# Returns 1 on success, 0 on failure (+ skip_all the plan).
sub js_or_skip {
    my ($nats, $probe) = @_;
    my $available;
    $probe->(sub {
        my ($err) = @_;
        $available = $err ? 0 : 1;
        EV::break;
    });
    EV::timer(3, 0, sub { EV::break });
    EV::run;
    unless ($available) {
        $nats->disconnect;
        Test::More::plan(skip_all => 'JetStream not enabled (start nats-server with --jetstream)');
    }
    return 1;
}

# Bind to an ephemeral port on 127.0.0.1, return the assigned number.
sub free_port {
    my $s = IO::Socket::INET->new(LocalAddr => '127.0.0.1', LocalPort => 0,
                                   Proto => 'tcp', Listen => 1)
        or die "free_port bind: $!";
    my $p = $s->sockport;
    close $s;
    $p;
}

# Locate the nats-server binary (looks in /usr/sbin then PATH); skip the
# plan if it isn't found.
sub nats_bin_or_skip {
    my $bin = '/usr/sbin/nats-server';
    $bin = `which nats-server 2>/dev/null` unless -x $bin;
    chomp $bin;
    Test::More::plan(skip_all => "nats-server not found") unless -x $bin;
    $bin;
}

# fork+exec nats-server with @args, sleep briefly for startup, return pid.
sub spawn_nats {
    my ($bin, @args) = @_;
    my $pid = fork;
    die "fork: $!" unless defined $pid;
    if ($pid == 0) {
        { exec $bin, @args }
        require POSIX;
        POSIX::_exit(1);
    }
    sleep 1;
    return $pid;
}

1;
