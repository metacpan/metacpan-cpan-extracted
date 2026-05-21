use strict;
use warnings;
use Test::More;
use lib 'xt/lib';
use EVNatsHelpers qw(nats_bin_or_skip free_port spawn_nats);
use EV;
use EV::Nats;

my $nats_bin = nats_bin_or_skip();

plan tests => 2;

my $port = free_port();
# Use server defaults: SIGUSR2 immediately sends INFO with ldm:true to
# existing clients, then enters the grace period before disconnecting them.
my $pid = spawn_nats($nats_bin, '-p', $port, '-a', '127.0.0.1');

my $ldm_fired = 0;
my $connected = 0;
my $nats;
$nats = EV::Nats->new(
    host          => '127.0.0.1',
    port          => $port,
    on_error      => sub { diag "error: @_" },
    on_disconnect => sub { diag "disconnected" },
    on_connect    => sub {
        $connected = 1;
        # After connecting, signal the server to enter lame-duck mode.
        diag "connected; sending SIGUSR2 to nats-server pid=$pid";
        kill 'USR2', $pid;
    },
    on_lame_duck  => sub { $ldm_fired = 1; EV::break },
);

my $guard = EV::timer 10, 0, sub { fail 'timeout waiting for on_lame_duck'; EV::break };
EV::run;

ok $connected, 'connected before lame-duck';
ok $ldm_fired, 'on_lame_duck fired after SIGUSR2';

$nats->disconnect if $nats;
kill 'TERM', $pid;
waitpid $pid, 0;
