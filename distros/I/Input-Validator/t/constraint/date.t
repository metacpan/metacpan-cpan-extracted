#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 5;

use Input::Validator::Constraint::Date;

my $constraint =
  Input::Validator::Constraint::Date->new(args => [split => qr/\//]);

ok($constraint);

is($constraint->is_valid('Hello'),       0);
is($constraint->is_valid('2008-12-12'),  0);
is($constraint->is_valid('2008/12/122'), 0);

is($constraint->is_valid('2008/12/12'), 1);
