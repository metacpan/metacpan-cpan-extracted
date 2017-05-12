use strict;
use warnings;
use Test::More tests => 24;
use Test::Deep;

use EntityModel;
# EntityModel::Log->instance->min_level(0);
EntityModel::Log->instance->disabled(1);

check_json();
check_xml();
check_perl();
exit 0;

sub check_xml {
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
	check_model($model);
}

sub check_json {
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
	check_model($model);
}

sub check_perl {
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
	check_model($model);
}

sub check_model {
	my $model = shift;
	is($model->entity->count, 2, 'have 2 entities');
	cmp_deeply([ map { $_->name } $model->entity->list ], ['thing', 'other'], 'has correct name for both entities in the right order');
	ok(my $entity = $model->entity_by_name('thing'), 'get entity by name');
	isa_ok($entity, 'EntityModel::Entity');
	is($entity->field->count, 2, 'has 2 fields');
	cmp_deeply([ map { $_->name } $entity->field->list ], ['id', 'name'], 'has correct name for both fields in the right order');
}
