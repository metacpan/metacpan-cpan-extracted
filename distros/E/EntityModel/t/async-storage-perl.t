use strict;
use warnings;

use Test::More;
BEGIN {
	if(eval { require IO::Async::Loop }) {
		plan tests => 14;
	} else {
		plan skip_all => 'IO::Async::Loop not found';
	}
}

use EntityModel;
use IO::Async::Loop;

my $model = new_ok('EntityModel');
my $entity = new_ok('EntityModel::Entity');
ok($entity->name("kvstore"), 'set name');
ok($model->add_entity($entity), 'can add entity');
my $field = new_ok('EntityModel::Field');
ok($field->name("id"), 'set name');
ok($field->type("varchar"), 'set type');
ok($entity->add_field($field), 'can add field');
$entity->primary($field->name);
$field = new_ok('EntityModel::Field');
ok($field->name("value"), 'set name');
ok($field->type("varchar"), 'set type');
ok($entity->add_field($field), 'can add field');
#ok($model->then(sub {
#	ok(my $self = shift, 'have $self in ->then');
#}), '');
ok($model->add_storage(
	'PerlAsync' => { loop => IO::Async::Loop->new },
)->add_support(
	'Perl'
), 'storage and class setup');
ok($model->commit, 'attempt to flush model');

Entity::Kvstore->create({
	id => 'test',
	value => 'stored entry',
})->then(sub {
	ok(my $obj = Entity::Kvstore->fromID('test'), 'load value');
	is($obj->value, 'stored entry', 'value is correct');
});
