#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 74;

use_ok('Input::Validator::Field');

my $field = Input::Validator::Field->new(name => 'foo');
$field->required(1);
$field->length([3, 20]);
$field->regexp(qr/^\d+$/);

ok(!$field->is_valid);
is($field->error, 'REQUIRED');

$field->value('');
ok(!$field->is_valid);
is($field->error, 'REQUIRED');

$field->value('   ');
ok(!$field->is_valid);
is($field->error, 'REQUIRED');

$field->value('ab');
ok(!$field->is_valid);
is($field->error, 'LENGTH_CONSTRAINT_FAILED');

$field->value('abc');
ok(!$field->is_valid);
is($field->error, 'REGEXP_CONSTRAINT_FAILED');

$field->value(123);
ok($field->is_valid);
ok(!$field->error);

$field = Input::Validator::Field->new(name => 'foo');
$field->length([3, 20]);

ok($field->is_valid);
ok(!$field->error);

$field->value('ab');
ok(!$field->is_valid);
is($field->error, 'LENGTH_CONSTRAINT_FAILED');

$field->value('abc');
ok($field->is_valid);
ok(!$field->error);

$field = Input::Validator::Field->new(name => 'foo');
$field->length([3, 20]);

$field->value([qw/fo bar/]);
is($field->value, 'fo');
ok(!$field->is_valid);
is($field->error, 'LENGTH_CONSTRAINT_FAILED');

$field->value([qw/foo ba/]);
is($field->value, 'foo');
ok($field->is_valid);
ok(!$field->error);

$field->multiple(1);
$field->value([qw/foo ba/]);
is_deeply($field->value, [qw/foo ba/]);
ok(!$field->is_valid);

$field = Input::Validator::Field->new(name => 'foo');
$field->multiple(1);
$field->value([]);
is_deeply($field->value, []);
ok($field->is_valid);

$field = Input::Validator::Field->new(name => 'foo');
$field->multiple(1);
$field->value([]);
$field->required(1);
is_deeply($field->value, []);
ok(!$field->is_valid);

$field->value([qw/foo bar/]);
is_deeply($field->value, [qw/foo bar/]);
ok($field->is_valid);

$field = Input::Validator::Field->new(name => 'foo');
$field->required(1)->in(0, 1);
ok(!$field->is_defined);
ok($field->is_empty);
ok(!$field->is_valid);

$field->value(0);
ok($field->is_defined);
ok(!$field->is_empty);
ok($field->is_valid);

$field = Input::Validator::Field->new(name => 'foo');
$field->multiple(2, 3);
$field->value([qw/foo/]);
ok(!$field->is_valid);
is($field->error, 'NOT_ENOUGH');

$field->value([qw/foo bar/]);
ok($field->is_valid);

$field->value([qw/foo bar baz/]);
ok($field->is_valid);

$field->value([qw/foo bar baz urgh/]);
ok(!$field->is_valid);
is($field->error, 'TOO_MUCH');

$field = Input::Validator::Field->new(name => 'foo');
$field->multiple(2);
$field->value([qw/foo/]);
ok(!$field->is_valid);
is($field->error, 'NOT_ENOUGH');

$field->value([qw/foo bar/]);
ok($field->is_valid);

$field->value([qw/foo bar baz/]);
ok(!$field->is_valid);
is($field->error, 'TOO_MUCH');

# Multiple constraints
$field = Input::Validator::Field->new(name => 'foo');
$field->multiple(1, 10);
$field->unique;
$field->value([qw/1 2 3 4 5/]);
ok($field->is_valid);

$field = Input::Validator::Field->new(name => 'foo');
$field->multiple(1, 10);
$field->unique;
$field->value([qw/1 2 3 4 4/]);
ok(!$field->is_valid);

$field = Input::Validator::Field->new(name => 'foo');
$field->multiple(1, 10);
$field->equal;
$field->value([qw/1 1 1 1 1/]);
ok($field->is_valid);

$field = Input::Validator::Field->new(name => 'foo');
$field->multiple(1, 10);
$field->equal;
$field->value([qw/1 1 2 1 1/]);
ok(!$field->is_valid);

# Custom error messages
$field = Input::Validator::Field->new(name => 'foo');
$field->length([3, 20]);
$field->messages(LENGTH_CONSTRAINT_FAILED =>
      'Name can have between %s and %s characters, you entered %s!');

$field->value('Hi');
ok(!$field->is_valid);
is($field->error,
    'Name can have between 3 and 20 characters, you entered 2!');

# Custom error messages inherit default messages
$field = Input::Validator::Field->new(name => 'foo', messages => {REQUIRED => 'Required'});
$field->required(1);
$field->messages(LENGTH_CONSTRAINT_FAILED =>
      'Name can have between %s and %s characters, you entered %s!');

ok(!$field->is_valid);
is($field->error, 'Required');

# inflate
$field = Input::Validator::Field->new(name => 'foo');
$field->inflate(sub { $_ = 'inflate' });
$field->value('raw');
ok($field->is_valid);
is($field->value, 'inflate');

$field->inflate(sub { s/bar/baz/; $_ });
$field->multiple(1);
$field->value([qw/foo bar/]);
ok($field->is_valid);
is_deeply($field->value, [qw/foo baz/]);

$field = Input::Validator::Field->new(name => 'foo');
$field->multiple(1);
$field->regexp(qr/^\d+$/);

$field->inflate(sub { split /:/ });
$field->value('10:20:30');
ok($field->is_valid);
is_deeply($field->value, [qw/10 20 30/]);

$field->inflate(sub { s/:/0/g; $_ });
$field->value('10:20:30');
ok($field->is_valid);
is_deeply($field->value, [qw/10020030/]);

# deflate
$field = Input::Validator::Field->new(name => 'foo');
$field->deflate(sub { $_ = 'deflate' });
$field->value('raw');
ok($field->is_valid);
is($field->value, 'deflate');

$field->deflate(sub { s/bar/baz/; $_ });
$field->multiple(1);
$field->value([qw/foo bar/]);
ok($field->is_valid);
is_deeply($field->value, [qw/foo baz/]);

$field->deflate(sub { split /:/ });
$field->multiple(1);
$field->value('10:20:30');
$field->regexp(qr/^[\d:]+$/);
ok($field->is_valid);
is_deeply($field->value, [qw/10 20 30/]);

# inflate/deflate
$field = Input::Validator::Field->new(name => 'foo');
$field->inflate(sub { s/bar/baz/; $_ });
$field->deflate(sub { s/baz/foo/; $_ });
$field->value('bar');
ok($field->is_valid);
is($field->value, 'foo');
