use strict;
use warnings;
use Test::More;
use EV;
use EV::Memcached;
use FindBin;
use lib "$FindBin::Bin/lib";
use FakeMemcached;

# Reentrancy: a response callback that tears the connection down and
# synchronously reconnects (AF_UNIX connect completes immediately) must not
# corrupt the read buffer of process_responses. Pre-fix this produced a
# bogus on_error ("protocol error" / "invalid response magic byte") and
# tore down the healthy new connection.

my $srv = FakeMemcached->new(script => sub {
    my ($listen) = @_;
    # Connection 1: answer one noop.
    my $c1 = FakeMemcached->accept($listen);
    my $r1 = $c1->read_request or exit 0;
    $c1->respond(op => $r1->[0], opaque => $r1->[1]);
    # Client disconnects and reconnects; answer the follow-up noop.
    my $c2 = FakeMemcached->accept($listen);
    my $r2 = $c2->read_request or exit 0;
    $c2->respond(op => $r2->[0], opaque => $r2->[1]);
    sleep 3;
});

my (@events, @errors);
my $mc;
$mc = EV::Memcached->new(
    path      => $srv->path,
    on_error  => sub { push @errors, $_[0] },
    on_connect => sub { push @events, 'connect' },
);
# Issued while connecting (deferred completion) or already connected
# (legacy synchronous unix connect) -- either way it reaches the server.
$mc->noop(sub {
    my (undef, $err) = @_;
    push @events, defined $err ? "noop1 err=$err" : 'noop1';
    # Tear down and synchronously reconnect from inside the callback.
    $mc->disconnect;
    $mc->connect_unix($srv->path);
    $mc->noop(sub {
        my (undef, $err2) = @_;
        push @events, defined $err2 ? "noop2 err=$err2" : 'noop2';
    });
});

my $t = EV::timer 2, 0, sub { EV::break };
EV::run;

is_deeply(\@errors, [], 'no on_error fired')
    or diag "errors: @errors";
is_deeply(\@events, ['connect', 'noop1', 'connect', 'noop2'],
    'reconnect from callback: follow-up command works on new connection')
    or diag "events: @events";
ok($mc->is_connected, 'new connection still usable');

$srv->finish;
done_testing;
