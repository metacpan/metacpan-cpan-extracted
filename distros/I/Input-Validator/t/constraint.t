#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 2;

use Input::Validator::Constraint;

my $constraint = Input::Validator::Constraint->new;

ok($constraint);

is($constraint->is_valid(), 0);
