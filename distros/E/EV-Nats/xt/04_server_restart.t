use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use POSIX qw(_exit);
use EV;
use EV::Nats;

my $nats_bin = '/usr/sbin/nats-server';
$nats_bin = `which nats-server 2>/dev/null` unless -x $nats_bin;
chomp $nats_bin;
unless (-x $nats_bin) {
    plan skip_all => "nats-server not found";
}

plan tests => 4;

my $tmp = tempdir(CLEANUP => 1);
my $port = 24421;

sub start_server {
    my $pid = fork;
    die "fork: $!" unless defined $pid;
    if ($pid == 0) {
        exec $nats_bin, '-p', $port, '-a', '127.0.0.1',
             '--pid', "$tmp/nats.pid";
        _exit(1);
    }
    sleep 1;
    return $pid;
}

my $srv_pid = start_server();

my $guard = EV::timer 20, 0, sub { fail 'global timeout'; EV::break };

my $connect_count = 0;
my $disconnect_count = 0;
my $received_after = 0;

my $nats;
$nats = EV::Nats->new(
    host                   => '127.0.0.1',
    port                   => $port,
    reconnect              => 1,
    reconnect_delay        => 500,
    max_reconnect_delay    => 2000,
    max_reconnect_attempts => 20,
    on_error   => sub { diag "error: @_" },
    on_connect => sub {
        $connect_count++;
        if ($connect_count == 1) {
            pass 'initial connect';
            $nats->subscribe('restart.test', sub {
                $received_after++ if $_[1] eq 'after-restart';
            });

            # Kill server
            my $t; $t = EV::timer 0.5, 0, sub {
                undef $t;
                diag "killing server (pid $srv_pid)";
                kill 'TERM', $srv_pid;
                waitpid $srv_pid, 0;

                # Restart after delay
                my $r; $r = EV::timer 2, 0, sub {
                    undef $r;
                    diag "restarting server";
                    $srv_pid = start_server();
                };
            };
        } elsif ($connect_count == 2) {
            pass 'reconnected after server restart';

            my $p; $p = EV::timer 0.5, 0, sub {
                undef $p;
                $nats->publish('restart.test', 'after-restart');

                my $c; $c = EV::timer 0.5, 0, sub {
                    undef $c;
                    is $received_after, 1, 'message received after restart';
                    ok $connect_count == 2, 'connected exactly twice';
                    $nats->disconnect;
                    EV::break;
                };
            };
        }
    },
    on_disconnect => sub {
        $disconnect_count++;
    },
);

EV::run;

kill 'TERM', $srv_pid;
waitpid $srv_pid, 0;
