use strict;
use warnings;

use Test::More tests => 2;
use EntityModel;
my $model = EntityModel->new;
$model->add_storage(Perl => { });
subtest 'single entity' => sub {
	plan tests => 2;
	$model->add_entity(EntityModel::Entity->new(
		'test'
	));
	is($model->entity->count, 1, 'have single entity');
	my ($e) = $model->entity->list;
	is($e->name, 'test', 'name matches');
	done_testing();
};

use constant COUNT => 1_000;

subtest 'multiple entities' => sub {
	plan tests => COUNT * 3;
	# could use $id but may replace with a list of meaningful entity names
	my $count = 1;
	for my $id (1..COUNT) {
		my $name = 'test_' . $id;
		$model->add_entity(my $entity = EntityModel::Entity->new($name));
		is($model->entity->count, ++$count, 'have correct entity count');
		my ($e) = $model->entity->last;
		is($e->name, $name, 'name matches expected');
		is($e->name, $entity->name, 'name matches original created entity');
	}
	done_testing();
};
done_testing();
