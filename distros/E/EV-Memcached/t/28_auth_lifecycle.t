use strict;
use warnings;
use Test::More;
use EV;
use EV::Memcached;
use FindBin;
use lib "$FindBin::Bin/lib";
use FakeMemcached;

{
    my $srv = FakeMemcached->new(script => sub {
        my $c = FakeMemcached->accept(shift);
        my $auth = $c->read_request or exit 0;
        $c->respond(op => $auth->[0], opaque => $auth->[1]);
        my $fence = $c->read_request or exit 0;
        $c->respond(op => $fence->[0], opaque => $fence->[1]);
        sleep 2;
    });
    my ($connects, $done);
    my $mc = EV::Memcached->new(path => $srv->path, on_error => sub {});
    $mc->on_connect(sub { ++$connects });
    $mc->sasl_auth('u', 'p');
    $mc->noop(sub { $done = $_[0]; EV::break });
    my $t = EV::timer 2, 0, sub { EV::break };
    EV::run;
    is($done, 1, 'manual auth without a callback completes');
    is($connects, 1, 'manual auth does not repeat on_connect');
    $mc->disconnect;
    $srv->finish;
}

# Authentication failures count toward the configured reconnect limit.
{
    my $srv = FakeMemcached->new(script => sub {
        my $listen = shift;
        for (1 .. 5) {
            my $c = FakeMemcached->accept($listen);
            my $auth = $c->read_request or exit 0;
            $c->respond(op => $auth->[0], opaque => $auth->[1], status => 0x20);
            $c->read_request;
        }
    });
    my (@errors, $done, $connects);
    my $mc = EV::Memcached->new(path => $srv->path,
        username => 'u', password => 'p', reconnect => 1,
        reconnect_delay => 10, max_reconnect_attempts => 2,
        resume_waiting_on_reconnect => 1,
        on_error => sub { push @errors, $_[0] },
        on_connect => sub { ++$connects });
    $mc->get('k', sub { $done = $_[1]; EV::break });
    my $t = EV::timer 0.4, 0, sub { EV::break };
    EV::run;
    is(scalar(grep { /^SASL auth failed/ } @errors), 3,
        'initial authentication plus two retries');
    ok(grep({ /max reconnect attempts reached/ } @errors), 'authentication retries stop at the limit');
    is($done, 'disconnected', 'terminal authentication failure drains waiting commands');
    ok(!$connects, 'failed authentication never emits on_connect');
    $mc->disconnect;
    $srv->finish;
}

done_testing;
