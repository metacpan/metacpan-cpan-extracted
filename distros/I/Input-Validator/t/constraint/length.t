#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 10;

use Input::Validator::Constraint::Length;

my $constraint =
  Input::Validator::Constraint::Length->new(args => [3, 5]);

ok($constraint);

is($constraint->is_valid('Hello'), 1);
is_deeply([$constraint->is_valid('He')], [0,[3,5,2]] );
is_deeply([$constraint->is_valid('Hello!')], [0,[3,5,6]] );

$constraint = Input::Validator::Constraint::Length->new(args => 1);

ok($constraint);

is($constraint->is_valid('Hello'), 0);
is($constraint->is_valid('a'), 1);

$constraint = Input::Validator::Constraint::Length->new(args => [1]);

ok($constraint);

is($constraint->is_valid('Hello'), 0);
is($constraint->is_valid('a'), 1);
