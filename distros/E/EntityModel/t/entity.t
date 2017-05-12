use strict;
use warnings;
use Test::More tests => 4;
use Test::Fatal;

use EntityModel::Entity;

new_ok('EntityModel::Entity');
subtest 'deprecated ->new($name) API' => sub {
	plan tests => 2;
	my $entity = new_ok('EntityModel::Entity' => [
		'test'
	]);
	is($entity->name, 'test', 'name is correct');
	done_testing;
};
subtest '->new(%args) API' => sub {
	plan tests => 11;
	my $entity = new_ok('EntityModel::Entity' => [
		name => 'test'
	]);
	is($entity->name, 'test', 'name is correct');
	is($entity->field->count, 0, 'have no fields');
	$entity = new_ok('EntityModel::Entity' => [
		name => 'test',
		primary => 'idtest',
		field => [
			{ name => 'idtest', type => 'bigserial' },
			{ name => 'something', type => 'text' },
		]
	]);
	is($entity->name, 'test', 'name is correct');
	is($entity->primary, 'idtest', 'primary key name is correct');
	is($entity->keyfield, undef, 'no keyfield');
	is($entity->field->count, 2, 'have two fields');
	is((my $pri = $entity->field->first)->name, 'idtest', 'first field name is correct');
	is($pri->name, $entity->primary, 'primary key is a valid field');
	is($pri->type, 'bigserial', 'primary key type is correct');
	done_testing;
};
subtest 'auto_primary' => sub {
	plan tests => 14;
	my $entity = new_ok('EntityModel::Entity' => [
		name => 'test',
		auto_primary => 1
	]);
	is($entity->name, 'test', 'name is correct');
	is($entity->field->count, 1, 'have one field');
	is((my $pri = $entity->field->first)->name, 'idtest', 'name is correct');
	is($pri->type, 'bigserial', 'type is correct');
	is($entity->primary, $pri->name, 'primary key matches');

	$entity = new_ok('EntityModel::Entity' => [
		name => 'test',
		auto_primary => 1,
		field => [
			{ type => 'text', name => 'something' },
		]
	]);
	is($entity->name, 'test', 'name is correct');
	is($entity->field->count, 2, 'have two fields');
	is(($pri = $entity->field->first)->name, 'idtest', 'name is correct');
	is($pri->type, 'bigserial', 'type is correct');
	is($entity->primary, $pri->name, 'primary key matches');
	is((my $f = $entity->field->last)->name, 'something', 'have the other field');
	is($f->type, 'text', 'field type matches');
	done_testing;
};
done_testing;

