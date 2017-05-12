#!/usr/bin/perl env

use strict;
use warnings;

use Test::More tests => 5;

use Input::Validator::Constraint::In;

my $constraint = Input::Validator::Constraint::In->new(args => [1, 5, 7]);
ok($constraint);
is($constraint->is_valid(1), 1);
is($constraint->is_valid(7), 1);
is($constraint->is_valid(2), 0);

$constraint = Input::Validator::Constraint::In->new(args => [0, 1]);
is($constraint->is_valid(0), 1);
