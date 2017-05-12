use strict;
use warnings;

use Test::More;
use Test::RedisServer;
use Test::TCP;

use EV;
use EV::Hiredis;

my $port = empty_port;

my $redis_server;
eval {
    $redis_server = Test::RedisServer->new( conf => { port => $port });
} or plan skip_all => 'redis-server is required to this test';


my $r = EV::Hiredis->new;

my $connected = 0;
my $error = 0;

$r->on_error(sub { $error++ });
$r->on_connect(sub {
    $connected++;

    my $t; $t = EV::timer .1, 0, sub {
        $r->disconnect;
        undef $t;
    };
});

$r->connect('127.0.0.1', $port);

EV::run;

is $connected, 1;
is $error, 0;

$redis_server->stop;

$r = EV::Hiredis->new;

$connected = 0;
$error = 0;

$r->on_error(sub {
    $error++;
});
$r->on_connect(sub {
    $connected++;

    my $t; $t = EV::timer .1, 0, sub {
        $r->disconnect;
        undef $t;
    };
});

$r->connect('127.0.0.1', $port);

EV::run;

is $connected, 0;
is $error, 1;

done_testing;
