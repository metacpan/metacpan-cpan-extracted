#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 5;

use Input::Validator::Constraint::Callback;

my $constraint = Input::Validator::Constraint::Callback->new(
    args => sub {
        my $value = shift;

        return 1 if $value =~ m/^\d+$/;

        return 0;
    }
);

ok($constraint);

ok(!$constraint->is_valid('hello'));
ok($constraint->is_valid(123));

$constraint = Input::Validator::Constraint::Callback->new(
    args => sub {
        my $value = shift;

        return 1 if $value =~ m/^\d+$/;

        return (0, 'Value is not a number');
    }
);

ok(!$constraint->is_valid('hello'));
is($constraint->error, 'Value is not a number');
