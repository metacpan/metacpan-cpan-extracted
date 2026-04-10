use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use IO::Socket::INET;
use EV;
use EV::Nats;

# This test uses socat to proxy a unix socket to a TCP nats-server.
# Requires: socat, running nats-server

my $socat = `which socat 2>/dev/null`;
chomp $socat;
unless ($socat && -x $socat) {
    plan skip_all => "socat not found";
}

my $host = $ENV{TEST_NATS_HOST} || '127.0.0.1';
my $port = $ENV{TEST_NATS_PORT} || 4222;

my $sock = IO::Socket::INET->new(
    PeerAddr => $host,
    PeerPort => $port,
    Timeout  => 1,
);
unless ($sock) {
    plan skip_all => "NATS server not available at $host:$port";
}
close $sock;

plan tests => 4;

my $tmp = tempdir(CLEANUP => 1);
my $sock_path = "$tmp/nats.sock";

# socat: unix socket -> TCP nats-server
my $socat_pid = fork;
die "fork: $!" unless defined $socat_pid;
if ($socat_pid == 0) {
    exec $socat, "UNIX-LISTEN:$sock_path,fork",
         "TCP:$host:$port";
    POSIX::_exit(1);
}

sleep 1;
ok -S $sock_path, 'socat unix socket created';

my $guard = EV::timer 10, 0, sub { fail 'timeout'; EV::break };

my $nats;
$nats = EV::Nats->new(
    path     => $sock_path,
    on_error => sub { diag "error: @_" },
    on_connect => sub {
        pass 'connected via unix socket';

        my $received = 0;
        $nats->subscribe('unix.test', sub {
            $received++;
            if ($received >= 3) {
                is $received, 3, 'received 3 messages via unix socket';

                $nats->request('unix.echo', 'ping', sub {
                    my ($resp, $err) = @_;
                    is $resp, 'pong', 'request/reply over unix socket';
                    $nats->disconnect;
                    EV::break;
                }, 5000);
            }
        });

        $nats->subscribe('unix.echo', sub {
            my ($s, $p, $r) = @_;
            $nats->publish($r, 'pong') if $r;
        });

        my $t; $t = EV::timer 0.1, 0, sub {
            undef $t;
            $nats->publish('unix.test', "msg-$_") for 1..3;
        };
    },
    connect_timeout => 5000,
);

EV::run;

kill 'TERM', $socat_pid;
waitpid $socat_pid, 0;
