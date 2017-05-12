#!/usr/bin/perl -w

use strict;
use Test::More;

BEGIN
  {
  chdir 't' if -d 't';
  unshift @INC, '../lib'; # for running manually
  plan tests => 7;
  }

# testing of Math::BigInt::Named::German, primarily for the $x->name() and
# $x->from_name() functionality, and not for the math functionality

use Math::BigInt::Named;
use Math::BigInt;

my $c = 'Math::BigInt::Named';

###############################################################################
# check delegating

my $x = $c->new(123);

is ($x->name(), 'onehundredtwentythree', 'default en');

is ($x->name( language => 'german'),
		'einhundertunddreiundzwanzig', 'german');
is ($x->name( language => 'de'),
		'einhundertunddreiundzwanzig', 'german');
is ($x->name( language => 'en'),
		'onehundredtwentythree', 'en again');

is ($x,123, "value shouldn't change");

is ($c->new('foobar'),'NaN', 'NaN');

###############################################################################
# check ->name()

my $name = Math::BigInt::Named->name(123);
is ($name, 'onehundredtwentythree', 'default en')
