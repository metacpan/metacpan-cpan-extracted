#!/usr/bin/env perl

package CustomConstraint;
use base 'Input::Validator::Constraint::In';

package main;

use strict;
use warnings;

use Test::More tests => 4;

use Input::Validator::ConstraintBuilder;

my $constraint = Input::Validator::ConstraintBuilder->build('in');
ok($constraint);
ok($constraint->isa('Input::Validator::Constraint::In'));

$constraint = Input::Validator::ConstraintBuilder->build('CustomConstraint');
ok($constraint);
ok($constraint->isa('CustomConstraint'));
