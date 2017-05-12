#!perl -T
use warnings; use strict;
use Test::More tests => 20;
use Test::Warn;

use Elive::Util;
use Elive::DAO::Array;
use Elive::Entity::Role;
use Elive::Entity::Participants;

my $type = Elive::Util::inspect_type('Int');

is($type->elemental_type => 'Int',
   'inspect_type(Int); elemental_type as expected');
ok(! $type->is_array,'inspect_type(Int); is_array - as expected');
ok(! $type->is_struct,'inspect_type(Int); is_struct - as expected');
ok(! $type->is_ref,'inspect_type(Int); is_ref - as expected');
is($type->type => 'Int', 'inspect_type(Int); type as expected');

$type = Elive::Util::inspect_type('Elive::DAO::Array');

is($type->elemental_type => 'Str',
   'inspect_type(array); elemental_type as expected');
ok($type->is_array,'inspect_type(array); is_array - as expected');
ok(! $type->is_struct,'inspect_type(array); is_struct - as expected');
ok($type->is_ref,'inspect_type(array); is_ref - as expected');
is($type->type => 'Elive::DAO::Array', 'inspect_type(array); type as expected');

$type = Elive::Util::inspect_type('Elive::Entity::Role');

is($type->elemental_type => 'Elive::Entity::Role',
   'inspect_type(role); elemental_type as expected');
ok(! $type->is_array,'inspect_type(role); is_array - as expected');
ok($type->is_struct,'inspect_type(role); is_struct - as expected');
ok($type->is_ref,'inspect_type(role); is_ref - as expected');
is($type->type => 'Elive::Entity::Role', 'inspect_type(role); type as expected');

$type = Elive::Util::inspect_type('Elive::Entity::Participants|Str');

is($type->elemental_type => 'Elive::Entity::Participant',
   'inspect_type(participants); elemental_type as expected');
ok($type->is_array,'inspect_type(participants); is_array - as expected');
ok($type->is_struct,'inspect_type(participants); is_struct - as expected');
ok($type->is_ref,'inspect_type(participants); is_ref - as expected');
is($type->type => 'Elive::Entity::Participants',
   'inspect_type(participants); type as expected');



