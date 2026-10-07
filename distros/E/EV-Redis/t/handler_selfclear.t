use strict;
use warnings;

use Test::More;
use Test::RedisServer;
use Test::TCP qw(empty_port);

use EV;
use EV::Redis;

# a handler clearing itself mid-call must not free its own running CV
my $port = empty_port;
my $redis_server;
eval {
    $redis_server = Test::RedisServer->new(conf => { port => $port, bind => '127.0.0.1' });
} or plan skip_all => 'redis-server is required for this test';

plan tests => 3;

{
    my $connect_calls = 0;
    my $r = EV::Redis->new;
    $r->on_error(sub { });
    $r->on_disconnect(sub { EV::break });
    $r->on_connect(sub {
        $connect_calls++;
        $r->on_connect(undef);
        $r->disconnect;
    });
    $r->connect('127.0.0.1', $port);
    my $t = EV::timer 3, 0, sub { EV::break };
    EV::run;
    is($connect_calls, 1,
        'self-clearing on_connect fired exactly once (handler SV pinned)');
}

{
    my $dead = empty_port;
    my $err_calls = 0;
    my $r = EV::Redis->new;
    $r->on_error(sub {
        $err_calls++;
        $r->on_error(undef);
        EV::break;
    });
    $r->connect('127.0.0.1', $dead);
    my $t = EV::timer 3, 0, sub { EV::break };
    EV::run;
    ok($err_calls >= 1,
        'self-clearing on_error fired without crashing (handler SV pinned)');
}

pass('process survived handlers that cleared themselves mid-call');
