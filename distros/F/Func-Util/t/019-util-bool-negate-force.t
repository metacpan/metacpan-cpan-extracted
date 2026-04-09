#!/usr/bin/perl
use strict;
use warnings;
use Test::More;

use Func::Util;

# Test bool (returns truthy value, not necessarily 0/1)
ok(Func::Util::bool(1), 'bool: 1 is true');
ok(!Func::Util::bool(0), 'bool: 0 is false');
ok(!Func::Util::bool(''), 'bool: empty string is false');
ok(Func::Util::bool('hello'), 'bool: non-empty string is true');
ok(!Func::Util::bool(undef), 'bool: undef is false');
ok(Func::Util::bool([]), 'bool: empty array ref is true');
ok(Func::Util::bool({}), 'bool: empty hash ref is true');

# Test negate
my $is_even = sub { $_[0] % 2 == 0 };
my $is_odd = Func::Util::negate($is_even);
ok($is_odd->(3), 'negate: 3 is odd');
ok(!$is_odd->(4), 'negate: 4 is not odd');

# Test force - check if it exists and works
# Note: force may not evaluate coderefs, just returns them
my $result = Func::Util::force(42);
is($result, 42, 'force: returns number directly');
is(Func::Util::force('hello'), 'hello', 'force: returns string directly');

done_testing();
