use strict;
use warnings;
use Test::Class;

package EntityModel::Definition::Test;
use parent qw(Test::Class);
use Test::More;
use Test::Deep;
use EntityModel;

# Provide a setup method in subclasses.

sub check_model : Test(6) {
	my $self = shift;
	my $model = $self->{model} or return 'base class';

	is($model->entity->count, 2, 'have 2 entities');
	cmp_deeply([ map { $_->name } $model->entity->list ], ['thing', 'other'], 'has correct name for both entities in the right order');
	ok(my $entity = $model->entity_by_name('thing'), 'get entity by name');
	isa_ok($entity, 'EntityModel::Entity');
	is($entity->field->count, 2, 'has 2 fields');
	cmp_deeply([ map { $_->name } $entity->field->list ], ['id', 'name'], 'has correct name for both fields in the right order');
}

package EntityModel::Definition::PerlTest;
use base qw(EntityModel::Definition::Test);
use Try::Tiny;
use Test::More;

# Set up an EntityModel from a Perl hash
sub setup : Test(setup => 2) {
	my $self = shift;
	my $model = new_ok('EntityModel');
	ok($model->load_from(
		Perl	=> {
	 "name" => "mymodel",
	 "entity" => [ {
	  "name" => "thing",
	  "field" => [
	   { "name" => "id", "type" => "int" },
	   { "name" => "name", "type" => "varchar" }
	  ] }, {
	  "name" => "other",
	  "field" => [
	   { "name" => "id", "type" => "int" },
	   { "name" => "extra", "type" => "varchar" }
	  ] }
	  ] }), 'load model');
	$self->{model} = $model;
	try {
		require Devel::Size;
		note sprintf "Model was %.2fKB", (Devel::Size::total_size($model) / 1024);
	} catch {
		# don't care if we fail
		note "Size check failed: $_";
	};
}

package EntityModel::Definition::XMLTest;
use base qw(EntityModel::Definition::Test);
use Test::More;

sub setup : Test(setup => 2) {
	my $self = shift;
	my $model = new_ok('EntityModel');
	ok($model->load_from(
		XML	=> { string => q(
<entitymodel>
 <name>mymodel</name>
 <entity>
  <name>thing</name>
  <field>
   <name>id</name>
   <type>int</type>
  </field>
  <field>
   <name>name</name>
   <type>varchar</type>
  </field>
 </entity>
 <entity>
  <name>other</name>
  <field>
   <name>id</name>
   <type>int</type>
  </field>
  <field>
   <name>extra</name>
   <type>varchar</type>
  </field>
 </entity>
</entitymodel>) }), 'load model');
	  $self->{model} = $model;
}

package EntityModel::Definition::JSONTest;
use base qw(EntityModel::Definition::Test);
use Test::More;

sub setup : Test(setup => 2) {
	my $self = shift;
	my $model = new_ok('EntityModel');
	ok($model->load_from(
		JSON	=> { string => q({
	 "name" : "mymodel",
	 "entity" : [ {
	  "name" : "thing",
	  "field" : [
	   { "name" : "id", "type" : "int" },
	   { "name" : "name", "type" : "varchar" }
	  ] }, {
	  "name" : "other",
	  "field" : [
	   { "name" : "id", "type" : "int" },
	   { "name" : "extra", "type" : "varchar" }
	  ] }
	  ] }) }), 'load model');
	$self->{model} = $model;
}

package main;
# EntityModel::Log->instance->min_level(0);
Test::Class->runtests;
