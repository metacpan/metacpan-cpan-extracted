use strict;
use warnings;
use Test::More;
use EV;
use EV::Memcached;
use FindBin;
use lib "$FindBin::Bin/lib";
use FakeMemcached;

# A synchronous failure handler can choose a healthy replacement endpoint.
for my $reconnect (0, 1) {
    my $srv = FakeMemcached->new(script => sub {
        my $c = FakeMemcached->accept(shift);
        my $r = $c->read_request or exit 0;
        $c->respond_hit(op => $r->[0], opaque => $r->[1], value => 'healthy');
        sleep 2;
    });
    my ($value, $error, $connected, @errors);
    EV::now_update;
    my $mc = EV::Memcached->new(reconnect => $reconnect, reconnect_delay => 10,
        on_error => sub {});
    $mc->on_connect(sub { ++$connected });
    $mc->on_error(sub {
        push @errors, $_[0];
        return if @errors > 1;
        $mc->connect_unix($srv->path);
        $mc->get('k', sub { ($value, $error) = @_; EV::break });
    });
    $mc->connect_unix($srv->path . '.missing');
    my $t = EV::timer 2, 0, sub { EV::break };
    EV::run;
    is($value, 'healthy', "reconnect=$reconnect: replacement command survives error handler");
    is($error, undef, "reconnect=$reconnect: no stale cancellation");
    # Stay up past reconnect_delay to catch an extra timer on the new session.
    my $settle = EV::timer 0.05, 0, sub { EV::break };
    EV::run;
    is($connected, 1, "reconnect=$reconnect: replacement connects exactly once");
    is(scalar @errors, 1, "reconnect=$reconnect: only the original failure reported");
    $mc->disconnect;
    $srv->finish;
}

# A disconnect handler reconnecting manually must own the new session.
{
    my $srv = FakeMemcached->new(script => sub {
        my $listen = shift;
        my $first = FakeMemcached->accept($listen);
        $first->read_request;
        $first->sock->close;
        my $next = FakeMemcached->accept($listen);
        my $r = $next->read_request or exit 0;
        $next->respond_hit(op => $r->[0], opaque => $r->[1], value => 'next');
        sleep 2;
    });
    my ($value, $connected);
    EV::now_update;
    my $mc = EV::Memcached->new(path => $srv->path, reconnect => 1,
        reconnect_delay => 10, on_error => sub {});
    $mc->on_connect(sub { ++$connected });
    $mc->on_disconnect(sub {
        $mc->connect_unix($srv->path);
        $mc->get('k', sub { $value = $_[0]; EV::break });
    });
    $mc->noop;
    my $t = EV::timer 2, 0, sub { EV::break };
    EV::run;
    is($value, 'next', 'manual reconnect from on_disconnect delivers work');
    my $settle = EV::timer 0.05, 0, sub { EV::break };
    EV::run;
    is($connected, 2, 'no redundant automatic connect after manual reconnect');
    $mc->on_disconnect(undef);
    $mc->disconnect;
    $srv->finish;
}

done_testing;
