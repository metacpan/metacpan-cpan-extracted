#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 8;

use Input::Validator;

my $validator = Input::Validator->new;

$validator->field([qw/foo bar baz/])->each(sub { shift->regexp(qr/^\d+$/) });

ok($validator->validate({foo => 1, bar => 2, baz => 3}));
ok(!$validator->validate({foo => 'a', bar => 2,   baz => 3}));
ok(!$validator->validate({foo => 'a', bar => 'b', baz => 3}));
ok(!$validator->validate({foo => 'a', bar => 'b', baz => 'c'}));


# Custom errors bulk
$validator = Input::Validator->new;
$validator->field([qw/foo bar/])->each(
    sub {
        shift->length(3, 20)
          ->messages(LENGTH_CONSTRAINT_FAILED =>
              'Name can have between %s and %s characters, you entered %s!');
    }
);

my $field = $validator->field('foo');
$field->value('Hi');
ok(!$field->is_valid);
is($field->error,
    'Name can have between 3 and 20 characters, you entered 2!');

$field = $validator->field('bar');
$field->value('Hi');
ok(!$field->is_valid);
is($field->error,
    'Name can have between 3 and 20 characters, you entered 2!');
