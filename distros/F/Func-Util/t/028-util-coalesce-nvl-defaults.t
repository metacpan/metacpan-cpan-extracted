#!/usr/bin/perl
use strict;
use warnings;
use Test::More;

use Func::Util;

# Test coalesce (returns first defined value)
is(Func::Util::coalesce(undef, undef, 'hello'), 'hello', 'coalesce: first defined is hello');
is(Func::Util::coalesce(undef, 42, 'hello'), 42, 'coalesce: first defined is 42');
is(Func::Util::coalesce('first', 'second'), 'first', 'coalesce: first is defined');
is(Func::Util::coalesce(0, 1), 0, 'coalesce: 0 is defined');
is(Func::Util::coalesce('', 'default'), '', 'coalesce: empty string is defined');
is(Func::Util::coalesce(undef, undef, undef), undef, 'coalesce: all undef');

# Test nvl (null value logic - similar to coalesce)
is(Func::Util::nvl(undef, 'default'), 'default', 'nvl: undef returns default');
is(Func::Util::nvl('value', 'default'), 'value', 'nvl: defined returns value');
is(Func::Util::nvl(0, 'default'), 0, 'nvl: 0 is defined');
is(Func::Util::nvl('', 'default'), '', 'nvl: empty string is defined');

# Test maybe - returns undef if val is undef, otherwise returns coderef
my $cb = Func::Util::maybe(42, sub { $_[0] * 2 });
ok(ref($cb) eq 'CODE', 'maybe: returns coderef when value defined');
is($cb->(42), 84, 'maybe: coderef works correctly');
is(Func::Util::maybe(undef, sub { 999 }), undef, 'maybe: returns undef for undef input');

# Test defaults
my $hash = {a => 1, b => 2};
my $defaults = {b => 99, c => 3, d => 4};
my $merged = Func::Util::defaults($hash, $defaults);
is($merged->{a}, 1, 'defaults: a unchanged');
is($merged->{b}, 2, 'defaults: b not overwritten');
is($merged->{c}, 3, 'defaults: c added from defaults');
is($merged->{d}, 4, 'defaults: d added from defaults');

done_testing();
