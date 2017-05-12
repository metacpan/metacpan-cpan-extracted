use strict;
use warnings;

use Test::More tests => 6;
use Test::EntityModel;

with_model {
	my $model = shift;
	is($model->name, 'simple', 'have correct model');
	is($model->entity->count, 2, 'have two entities');
};

with_model {
	my $model = shift;
	is($model->name, 'simple', 'have correct model');
	is($model->entity->count, 2, 'have two entities');
} model => 'simple';

with_model {
	my $model = shift;
	is($model->name, 'books', 'have correct model');
	is($model->entity->count, 3, 'have the right number of entities');
} model => 'books';

