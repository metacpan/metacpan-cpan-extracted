#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 6;

use_ok('Input::Validator::Group');
use_ok('Input::Validator::Field');

my $foo = Input::Validator::Field->new(name => 'foo')->value(1);
my $bar = Input::Validator::Field->new(name => 'bar')->value(2);

my $group = Input::Validator::Group->new(name => 'group1', fields => [$foo, $bar]);
$group->unique;
ok($group->is_valid);
ok(!$group->error);

$bar->value(1);
$group = Input::Validator::Group->new(fields => [$foo, $bar]);
$group->unique;
ok(!$group->is_valid);
is($group->error, 'UNIQUE_CONSTRAINT_FAILED');
