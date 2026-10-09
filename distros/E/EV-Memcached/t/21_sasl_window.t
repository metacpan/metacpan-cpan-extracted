use strict;
use warnings;
use Test::More;
use EV;
use EV::Memcached;
use IO::Select;
use FindBin;
use lib "$FindBin::Bin/lib";
use FakeMemcached;

# Commands issued during the SASL handshake must wait for auth to complete,
# not go on the wire pre-auth (where the server rejects them). on_connect
# has not fired yet, so the user has no signal to gate on.

{
my $srv = FakeMemcached->new(script => sub {
    my ($listen) = @_;
    my $c = FakeMemcached->accept($listen);
    my $auth = $c->read_request or exit 0;
    exit 99 unless $auth->[0] == 0x21;  # SASL_AUTH first

    # If a second request is already on its way before we answer auth,
    # the client sent pre-auth (pre-fix): reject it like a real server.
    my $sel = IO::Select->new($c->sock);
    if ($sel->can_read(0.8)) {
        my $early = $c->read_request;
        $c->respond(op => $auth->[0], opaque => $auth->[1]);  # auth OK
        $c->respond(op => $early->[0], opaque => $early->[1],
            status => 0x20, value => 'auth required') if $early;
    } else {
        $c->respond(op => $auth->[0], opaque => $auth->[1]);  # auth OK
        my $late = $c->read_request or exit 0;
        $c->respond_hit(op => $late->[0], opaque => $late->[1], value => 'VA');
    }
    sleep 2;
});

my (@errors, $got_val, $got_err, $connected);
my $mc = EV::Memcached->new(
    path     => $srv->path,
    username => 'u', password => 'p',
    on_error => sub { push @errors, $_[0] },
    on_connect => sub { $connected = 1 },
);

# Fire while TCP is up but SASL is still in flight (server holds auth OK
# for ~0.8s). connect completes on unix sockets on the first iteration.
my $w; $w = EV::timer 0.3, 0, sub {
    undef $w;
    ok(!$connected, 'get issued before on_connect (in the SASL window)');
    $mc->get('a', sub { ($got_val, $got_err) = @_; EV::break });
};

my $t = EV::timer 4, 0, sub { EV::break };
EV::run;

ok($connected, 'auto-auth completed, on_connect fired');
is($got_err, undef, 'in-window get not rejected');
is($got_val, 'VA', 'in-window get answered after auth');
is(scalar @errors, 0, 'no connection errors');
$srv->finish;
}

# --- skip_pending during auto-auth must not strand the gate ---
# The internal SASL entry has no user callback; skipping it would
# swallow the reply that lifts auth_pending, wedging the client
# (no on_connect, everything queued forever).
{
my $srv = FakeMemcached->new(script => sub {
    my ($listen) = @_;
    my $c = FakeMemcached->accept($listen);
    my $auth = $c->read_request or exit 0;
    exit 99 unless $auth->[0] == 0x21;
    select(undef, undef, undef, 1.0);  # hold past the skip
    $c->respond(op => $auth->[0], opaque => $auth->[1]);  # auth OK
    my $sel = IO::Select->new($c->sock);
    if ($sel->can_read(1.5)) {
        my $g = $c->read_request;
        $c->respond_hit(op => $g->[0], opaque => $g->[1], value => 'VA') if $g;
        sleep 3;
    }
});

my (@errors, $got_val, $got_err, $connected);
my $mc = EV::Memcached->new(
    path     => $srv->path,
    username => 'u', password => 'p',
    on_error => sub { push @errors, $_[0] },
    on_connect => sub { $connected = 1 },
);

my $w; $w = EV::timer 0.3, 0, sub {
    undef $w;
    $mc->get('a', sub { ($got_val, $got_err) = @_; EV::break });
    $mc->skip_pending;
};

my $t = EV::timer 4, 0, sub { EV::break };
EV::run;

ok($connected, 'skip: on_connect still fires after auth');
is($got_err, undef, 'skip: queued get not rejected');
is($got_val, 'VA', 'skip: queued get answered after auth');
is(scalar @errors, 0, 'skip: no connection errors');
$srv->finish;
}

done_testing();
