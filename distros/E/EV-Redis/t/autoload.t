use strict;
use warnings;
use Test::More;

use EV::Redis;

my $redis = EV::Redis->new;

ok !$redis->can('foo');

eval {
    $redis->foo(sub {});
};

ok $@;
ok $redis->can('foo');

done_testing;
