#!/usr/bin/perl
use strict;
use warnings;
use Test::More;

use Func::Util;

# Test always
my $always42 = Func::Util::always(42);
is($always42->(), 42, 'always: returns 42');
is($always42->(1, 2, 3), 42, 'always: ignores arguments');

my $always_hello = Func::Util::always('hello');
is($always_hello->(), 'hello', 'always: returns hello');

# Test identity
is(Func::Util::identity(42), 42, 'identity: returns 42');
is(Func::Util::identity('hello'), 'hello', 'identity: returns hello');
my $ref = [1, 2, 3];
is(Func::Util::identity($ref), $ref, 'identity: returns same reference');

# Test noop
is(Func::Util::noop(), undef, 'noop: returns undef');
is(Func::Util::noop(1, 2, 3), undef, 'noop: ignores arguments');

# Test once
my $counter = 0;
my $increment = Func::Util::once(sub { ++$counter });
is($increment->(), 1, 'once: first call increments');
is($increment->(), 1, 'once: second call returns cached');
is($increment->(), 1, 'once: third call returns cached');
is($counter, 1, 'once: function only called once');

done_testing();
