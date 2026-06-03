use strict;
use warnings;

use Test::More;
use Test::RedisServer;
use Test::TCP qw(empty_port);

use EV;
use EV::Redis;

# A connect/disconnect/error handler that clears itself from within its own
# invocation (e.g. one-shot use via $r->on_connect(undef)) must not crash:
# the handler SV is pinned across call_sv, so dropping the last reference
# mid-callback does not free the CV that is still running.
my $port = empty_port;
my $redis_server;
eval {
    $redis_server = Test::RedisServer->new(conf => { port => $port });
} or plan skip_all => 'redis-server is required for this test';

plan tests => 3;

# on_connect clears itself mid-callback
{
    my $connect_calls = 0;
    my $r = EV::Redis->new;
    $r->on_error(sub { });
    $r->on_disconnect(sub { EV::break });
    $r->on_connect(sub {
        $connect_calls++;
        $r->on_connect(undef);   # clear self mid-callback -> exercises the pin
        $r->disconnect;
    });
    $r->connect('127.0.0.1', $port);
    my $t = EV::timer 3, 0, sub { EV::break };
    EV::run;
    is($connect_calls, 1,
        'self-clearing on_connect fired exactly once (handler SV pinned)');
}

# on_error clears itself mid-callback (connection to a dead port)
{
    my $dead = empty_port;       # nothing is listening here
    my $err_calls = 0;
    my $r = EV::Redis->new;
    $r->on_error(sub {
        $err_calls++;
        $r->on_error(undef);     # clear self mid-error-callback -> emit_error pin
        EV::break;
    });
    $r->connect('127.0.0.1', $dead);
    my $t = EV::timer 3, 0, sub { EV::break };
    EV::run;
    ok($err_calls >= 1,
        'self-clearing on_error fired without crashing (handler SV pinned)');
}

pass('process survived handlers that cleared themselves mid-call');
