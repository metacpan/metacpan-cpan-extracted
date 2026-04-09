#!/usr/bin/perl
use strict;
use warnings;
use Test::More;

use Func::Util;

# Test dig - nested hash access
my $data = {
    user => {
        name => 'John',
        address => {
            city => 'NYC',
            zip => '10001'
        }
    }
};

is(Func::Util::dig($data, 'user', 'name'), 'John', 'dig: user.name');
is(Func::Util::dig($data, 'user', 'address', 'city'), 'NYC', 'dig: user.address.city');
is(Func::Util::dig($data, 'user', 'address', 'zip'), '10001', 'dig: user.address.zip');
is(Func::Util::dig($data, 'user', 'missing'), undef, 'dig: missing key returns undef');
is(Func::Util::dig($data, 'user', 'address', 'missing', 'deep'), undef, 'dig: deep missing returns undef');

# Test lazy
my $evaluated = 0;
my $lazy_val = Func::Util::lazy(sub { $evaluated++; 42 });
is($evaluated, 0, 'lazy: not evaluated yet');
is(Func::Util::force($lazy_val), 42, 'lazy: force returns value');
is($evaluated, 1, 'lazy: evaluated once');

# Test memo
my $call_count = 0;
my $expensive = Func::Util::memo(sub {
    my ($x) = @_;
    $call_count++;
    $x * 2;
});
is($expensive->(5), 10, 'memo: first call');
is($call_count, 1, 'memo: called once');
is($expensive->(5), 10, 'memo: cached call');
is($call_count, 1, 'memo: still called once');
is($expensive->(10), 20, 'memo: different arg');
is($call_count, 2, 'memo: called twice now');

done_testing();
