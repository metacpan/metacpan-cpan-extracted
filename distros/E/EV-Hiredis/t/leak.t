use strict;
use warnings;
use Test::More;
use Test::RedisServer;
use Devel::Peek qw/SvREFCNT/;
use Devel::Refcount qw/refcount/;
my $redis_server;
eval {
    $redis_server = Test::RedisServer->new;
} or plan skip_all => 'redis-server is required to this test';

plan tests => 3;

my %connect_info = $redis_server->connect_info;

use EV;
use EV::Hiredis;

my $r = EV::Hiredis->new( path => $connect_info{sock} );
my ($get_command, $test);
my $result;
$get_command = sub {
    $r->lrange('foo', 0, -1, sub {
        $result = shift;
        $r->lrange('foo', 0, -1, $test);
        $get_command = undef;
    });
};
$test = sub {
    is refcount($result), 2, 'reference count of array is 2(no_leaks_ok and $test)';
    is SvREFCNT($result->[0]), 1, 'reference count of first element is 1';
    is SvREFCNT($result->[1]), 1, 'reference count of second element is 1';
    $r->disconnect;
};
$r->rpush('foo' => 'bar1', sub {
    $r->rpush('foo' => 'bar2', $get_command);
});
EV::run;

done_testing;
