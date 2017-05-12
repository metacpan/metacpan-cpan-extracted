use strict;
use warnings;
use Test::More;
use Test::Deep;
use Test::RedisServer;

my $redis_server;
eval {
    $redis_server = Test::RedisServer->new;
} or plan skip_all => 'redis-server is required to this test';

my %connect_info = $redis_server->connect_info;

use EV;
use EV::Hiredis;

my $r = EV::Hiredis->new;
$r->connect_unix( $connect_info{sock} );

my $called = 0;
$r->command('get', 'foo', sub {
    my ($res, $err) = @_;

    $called++;
    ok !$res;
    ok !$err;

    $r->disconnect;
});
EV::run;
ok $called;

$called = 0;
$r->connect_unix( $connect_info{sock} );
$r->command('set', 'foo', 'bar', sub {
    my ($res, $err) = @_;

    $called++;
    is $res, 'OK';;
    ok !$err;

    $r->command('get', 'foo', sub {
        my ($res, $err) = @_;

        $called++;
        is $res, 'bar';
        ok !$err;

        $r->disconnect;
    });
});
EV::run;
is $called, 2;

$called = 0;
$r->connect_unix( $connect_info{sock} );
$r->command('set', '1', 'one', sub {
    $r->command('set', '2', 'two', sub {
        $r->command('keys', '*', sub {
            my ($res) = @_;

            $called++;
            cmp_deeply($res, bag('foo', '1', '2'));

            $r->disconnect;
        });
    });
});
EV::run;
is $called, 1;

$called = 0;
$r->connect_unix( $connect_info{sock} );
$r->command('set', 'foo', sub {
    my ($res, $err) = @_;

    $called++;

    ok !$res;
    ok $err;

    $r->disconnect;
});
EV::run;
is $called, 1;

done_testing;
