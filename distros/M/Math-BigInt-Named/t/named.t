# -*- mode: perl; -*-

use strict;
use warnings;

use Test::More tests => 8;

use Math::BigInt::Named;
use Math::BigInt;

my $c = 'Math::BigInt::Named';

###############################################################################
# check delegating

my $x = $c->new(123);

is($x->name(), 'one hundred and twenty-three', 'default en');

is($x->name(language => 'german'),
   'einhundertunddreiundzwanzig', 'german');
is($x->name(language => 'de'),
   'einhundertunddreiundzwanzig', 'german');
is($x->name(language => 'en'),
   'one hundred and twenty-three', 'en again');
is($x->name(language => 'no'),
   'ett hundre og tjuetre', 'norwegian');

is($x, 123, "value shouldn't change");

is($c->new('foobar'), 'NaN', 'NaN');

###############################################################################
# check ->name()

my $name = Math::BigInt::Named->name(123);
is($name, 'one hundred and twenty-three', 'default en')
