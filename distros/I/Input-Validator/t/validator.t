#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 17;

use Input::Validator;

my $validator = Input::Validator->new;
$validator->field('firstname')->required(1);
$validator->field('website')->length(3, 20);

is_deeply($validator->values, {});

# Ok
ok($validator->validate({firstname => 'bar', website => 'http://fooo.com'}));
is_deeply($validator->values,
    {firstname => 'bar', website => 'http://fooo.com'});

# Ok and only known fields are returned
ok($validator->validate({firstname => 'bar', foo => 1}));
is_deeply($validator->values, {firstname => 'bar'});

# Required field is missing
ok(!$validator->validate({}));
is_deeply($validator->values, {});

# Optional field is wrong
ok(!$validator->validate({firstname => 'foo', website => '12'}));
is_deeply($validator->values, {firstname => 'foo'});
is_deeply($validator->all_values, {firstname => 'foo', website => '12'});

$validator = Input::Validator->new;
$validator->field('foo')->in(0, 1);
ok($validator->validate({foo => 0}));

$validator = Input::Validator->new;
$validator->field('firstname')->each(sub { shift->required(1) });
ok($validator->validate({firstname => 'foo'}));

$validator = Input::Validator->new(messages => {REQUIRED => 'Required!'});
$validator->field('firstname')->required(1);
ok(!$validator->validate());
is($validator->errors->{firstname}, 'Required!');

$validator = Input::Validator->new;
$validator->field('firstname');
ok($validator->validate({firstname => ''}));
is_deeply($validator->values, {firstname => ''});

$validator = Input::Validator->new;
$validator->field('tags')->multiple(1, 10);
ok($validator->validate({}));
