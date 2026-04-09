#!/usr/bin/perl
use strict;
use warnings;
use Test::More;

use Func::Util;

# Test compose
my $add5 = sub { $_[0] + 5 };
my $mul2 = sub { $_[0] * 2 };
my $composed = Func::Util::compose($add5, $mul2);
is($composed->(3), 11, 'compose: (3 * 2) + 5 = 11');

my $composed2 = Func::Util::compose($mul2, $add5);
is($composed2->(3), 16, 'compose: (3 + 5) * 2 = 16');

# Test pipeline - applies functions to value directly, returns result
# Usage: pipeline($value, \&fn1, \&fn2, ...)
is(Func::Util::pipeline(3, $add5, $mul2), 16, 'pipeline: (3 + 5) * 2 = 16');
is(Func::Util::pipeline(3, $mul2, $add5), 11, 'pipeline: (3 * 2) + 5 = 11');
is(Func::Util::pipeline(10, sub { $_[0] / 2 }, sub { $_[0] + 3 }), 8, 'pipeline: (10 / 2) + 3 = 8');

# Test partial
my $add = sub { $_[0] + $_[1] };
my $add10 = Func::Util::partial($add, 10);
is($add10->(5), 15, 'partial: add10(5) = 15');

my $greet = sub { "$_[0] $_[1]!" };
my $hello = Func::Util::partial($greet, 'Hello');
is($hello->('World'), 'Hello World!', 'partial: hello(World)');

done_testing();
