use strict;
use warnings;
use Test::More;
use IO::Socket::INET;
use File::Temp qw(tempdir);
use POSIX qw(_exit);
use lib 'xt/lib';
use EVNatsHelpers qw(nats_bin_or_skip free_port);
use EV;
use EV::Nats;

# This test starts 3 nats-server instances in a cluster,
# connects to one, kills it, and verifies failover via reconnect.

my $nats_bin = nats_bin_or_skip();

plan tests => 5;

my $tmp = tempdir(CLEANUP => 1);
my @ports   = (free_port(), free_port(), free_port());
my @cluster = (free_port(), free_port(), free_port());
my @pids;

# Write configs and start servers
for my $i (0..2) {
    my $routes = join(",", map { "nats-route://127.0.0.1:$_" }
                          grep { $_ != $cluster[$i] } @cluster);
    my $conf = "$tmp/nats$i.conf";
    open my $fh, '>', $conf or die "write $conf: $!";
    print $fh <<CONF;
listen: 127.0.0.1:$ports[$i]
server_name: node$i
cluster {
    listen: 127.0.0.1:$cluster[$i]
    routes: [$routes]
}
CONF
    close $fh;

    my $pid = fork;
    die "fork: $!" unless defined $pid;
    if ($pid == 0) {
        exec $nats_bin, '-c', $conf, '--pid', "$tmp/nats$i.pid";
        _exit(1);
    }
    push @pids, $pid;
}

# Wait for cluster to form
sleep 2;

for my $p (@ports) {
    my $s = IO::Socket::INET->new(PeerAddr => "127.0.0.1", PeerPort => $p, Timeout => 2);
    unless ($s) {
        kill 'TERM', @pids;
        waitpid($_, 0) for @pids;
        plan skip_all => "cluster did not start (port $p)";
    }
    close $s;
}

pass 'cluster started (3 nodes)';

my $guard = EV::timer 30, 0, sub { fail 'global timeout'; EV::break };

my $nats;
my $connected_count  = 0;
my $disconnected     = 0;
my $received_after   = 0;

$nats = EV::Nats->new(
    host                   => '127.0.0.1',
    port                   => $ports[0],
    reconnect              => 1,
    reconnect_delay        => 500,
    max_reconnect_delay    => 2000,
    max_reconnect_attempts => 10,
    on_error   => sub { diag "error: @_" },
    on_connect => sub {
        $connected_count++;
        if ($connected_count == 1) {
            pass "connected to node0 (port $ports[0])";

            # Subscribe — should survive failover
            $nats->subscribe('cluster.test', sub {
                my ($subj, $payload) = @_;
                $received_after++ if $payload eq 'after-failover';
            });

            # Kill node0 after a short delay
            my $kill; $kill = EV::timer 1, 0, sub {
                undef $kill;
                diag "killing node0 (pid $pids[0])";
                kill 'TERM', $pids[0];
            };
        } elsif ($connected_count == 2) {
            pass "reconnected to another node after failover";

            # Publish after failover
            my $pub; $pub = EV::timer 0.5, 0, sub {
                undef $pub;
                $nats->publish('cluster.test', 'after-failover');

                my $check; $check = EV::timer 1, 0, sub {
                    undef $check;
                    is $received_after, 1, 'received message after failover';
                    ok $connected_count >= 2, "connected $connected_count times total";
                    $nats->disconnect;
                    EV::break;
                };
            };
        }
    },
    on_disconnect => sub {
        $disconnected++;
        diag "disconnected (count: $disconnected)";
    },
);

EV::run;

# Cleanup
kill 'TERM', @pids;
waitpid($_, 0) for @pids;
