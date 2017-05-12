#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 24;

use Input::Validator::Condition;
use Input::Validator::Field;

my $condition = Input::Validator::Condition->new;
$condition->when('bar');

my $foo = Input::Validator::Field->new(name => 'foo');
my $bar = Input::Validator::Field->new(name => 'bar');

ok(!$condition->match({}));
ok(!$condition->match({bar => $bar}));
$bar->value('');
ok(!$condition->match({bar => $bar}));
$bar->value('foo');
ok($condition->match({bar => $bar}));

$condition = Input::Validator::Condition->new;
$condition->when([qw/foo bar/]);

$foo = Input::Validator::Field->new(name => 'foo');
$bar = Input::Validator::Field->new(name => 'bar');

ok(!$condition->match({}));
$foo->value('bar');
ok(!$condition->match({foo => $foo}));
$bar->value('foo');
ok(!$condition->match({bar => $bar}));
ok($condition->match({foo => $foo, bar => $bar}));
$foo->multiple(1)->value([qw/bar baz/]);
ok($condition->match({foo => $foo, bar => $bar}));

$foo = Input::Validator::Field->new(name => 'foo');
$bar = Input::Validator::Field->new(name => 'bar');

ok(!$condition->match({}));
$foo->value('bar');
ok(!$condition->match({foo => $foo}));
$bar->value('foo');
ok(!$condition->match({bar => $bar}));
ok($condition->match({foo => $foo, bar => $bar}));
$foo->multiple(1)->value(qw/bar baz/);
ok($condition->match({foo => $foo, bar => $bar}));

$condition = Input::Validator::Condition->new;
$condition->when('foo')->regexp(qr/^\d+$/)->length(1, 3);

$foo = Input::Validator::Field->new(name => 'foo');
$bar = Input::Validator::Field->new(name => 'bar');

ok(!$condition->match({}));
$foo->value('bar');
ok(!$condition->match({foo => $foo}));
$foo->value(1234);
ok(!$condition->match({foo => $foo}));
$foo->value(123);
ok($condition->match({foo => $foo}));

$condition = Input::Validator::Condition->new;
$condition->when('foo')->regexp(qr/^\d+$/)->length(1, 3);

$foo = Input::Validator::Field->new(name => 'foo');
$bar = Input::Validator::Field->new(name => 'bar');

$foo->error('Required');
ok(!$condition->match({foo => $foo}));
$foo->clear_error;

$condition = Input::Validator::Condition->new;
$condition->when('foo')->regexp(qr/^\d+$/)->length(1, 3)->when('bar')
  ->regexp(qr/^\d+$/);
 
$foo = Input::Validator::Field->new(name => 'foo');
$bar = Input::Validator::Field->new(name => 'bar');

ok(!$condition->match({}));
$foo->value('bar');
$bar->value('foo');
ok(!$condition->match({foo => $foo, bar => $bar}));
$foo->value('barr');
$bar->value('foo');
ok(!$condition->match({foo => $foo, bar => $bar}));
$foo->value(123);
$bar->value('foo');
ok(!$condition->match({foo => $foo, bar => $bar}));
$foo->value(123);
$bar->value(123);
ok($condition->match({foo => $foo, bar => $bar}));
