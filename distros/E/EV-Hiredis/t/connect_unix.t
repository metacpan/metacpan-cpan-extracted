use strict;
use warnings;

use Test::More;
use Test::RedisServer;
use Test::TCP;

use EV;
use EV::Hiredis;

my $redis_server;
eval {
    $redis_server = Test::RedisServer->new;
} or plan skip_all => 'redis-server is required to this test';

my %connect_info = $redis_server->connect_info;

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

$r->connect_unix( $connect_info{sock} );

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

$r->connect_unix( $connect_info{sock} );

EV::run;

is $connected, 0;
is $error, 1;

done_testing;
