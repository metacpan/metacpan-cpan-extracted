use strict;
use warnings;
use Test::More;
use lib 'xt/lib';
use EVNatsHelpers qw(nats_bin_or_skip free_port spawn_nats);
use EV;
use EV::Nats;

my $nats_bin = nats_bin_or_skip();

plan tests => 3;

my $port = free_port();
my $pid  = spawn_nats($nats_bin, '-p', $port, '-a', '127.0.0.1');

my $flush_err;
my $flush_called = 0;
my $connected    = 0;
my $nats;

$nats = EV::Nats->new(
    host          => '127.0.0.1',
    port          => $port,
    on_disconnect => sub { diag "on_disconnect" },
    on_error      => sub { diag "error: @_" },
    on_connect    => sub {
        $connected = 1;
        # Queue a flush; immediately disconnect before its PONG can
        # arrive. nats_cleanup drains pong_cbs with "disconnected".
        $nats->flush(sub {
            $flush_called = 1;
            $flush_err    = $_[0];
            EV::break;
        });
        $nats->disconnect;
    },
);

my $guard = EV::timer(10, 0, sub { fail 'timeout'; EV::break });
EV::run;

ok $connected,    'connected before disconnect';
ok $flush_called, 'flush callback invoked despite disconnect';
like $flush_err,  qr/disconnect/i, 'flush callback received the disconnect error'
    or diag "got err: " . ($flush_err // '<undef>');

$nats->disconnect if $nats;
kill 'TERM', $pid;
waitpid $pid, 0;
