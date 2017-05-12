use strict;
use warnings;
use Test::More;

use EV::Hiredis;

my $redis = EV::Hiredis->new;

ok !$redis->can('foo');

eval {
    $redis->foo(sub {});
};

ok $@;
ok $redis->can('foo');

done_testing;
