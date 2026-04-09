#!/usr/bin/perl
use strict;
use warnings;
use Test::More;

use Func::Util;

# Test all predicate
ok(Func::Util::all(sub { $_ > 0 }, 1, 2, 3, 4, 5), 'all: all positive');
ok(!Func::Util::all(sub { $_ > 0 }, 1, 2, -1, 4, 5), 'all: not all positive');
ok(Func::Util::all(sub { $_ % 2 == 0 }, 2, 4, 6, 8), 'all: all even');
ok(!Func::Util::all(sub { $_ % 2 == 0 }, 2, 4, 5, 8), 'all: not all even');

# Test any predicate
ok(Func::Util::any(sub { $_ > 0 }, -1, -2, 3, -4), 'any: has positive');
ok(!Func::Util::any(sub { $_ > 0 }, -1, -2, -3, -4), 'any: no positive');
ok(Func::Util::any(sub { $_ eq 'x' }, 'a', 'b', 'x', 'd'), 'any: has x');

# Test none predicate
ok(Func::Util::none(sub { $_ > 0 }, -1, -2, -3, -4), 'none: no positive');
ok(!Func::Util::none(sub { $_ > 0 }, -1, 2, -3, -4), 'none: has positive');

done_testing();
