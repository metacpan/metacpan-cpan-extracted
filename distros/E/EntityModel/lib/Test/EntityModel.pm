package Test::EntityModel;
{
  $Test::EntityModel::VERSION = '0.102';
}
use EntityModel::Class {};
use parent qw(Exporter);
use EntityModel;
use IO::Async::Loop;
use Test::Refcount;

our @EXPORT = qw(with_model);
our @EXPORT_OK = @EXPORT;

my %model_data = (
	simple => {
		name => 'simple',
		entity => [ {
			name => 'first_entity',
			keyfield => 'name',
			auto_primary => 1,
			field => [
				{ name => 'name', type => 'text', },
			],
		}, {
			name => 'second_entity',
			keyfield => 'name',
			auto_primary => 1,
			field => [
				{ name => 'name', type => 'text', },
			],
		} ],
	},
	books => {
		name => 'books',
		entity => [ {
			name => 'author',
			auto_primary => 1,
			field => [
				{ name => 'name', type => 'text', },
				{ name => 'born', type => 'date', },
				{ name => 'died', type => 'date', },
			],
		}, {
			name => 'book',
			auto_primary => 1,
			field => [
				{ name => 'title', type => 'text', },
				{ name => 'published', type => 'date', },
				{ name => 'pages', type => 'date', },
			],
		}, {
			name => 'book_author',
			primary => [qw(idbook idauthor)],
			field => [
				{ name => 'book', type => 'text', },
				{ name => 'author', type => '', },
			],
		} ],
	},
);

sub with_model(&;@) {
	my $code = shift;
	my %args = @_;
	my $def = $model_data{$args{model} || 'simple'} or die 'unknown model - ' . $args{model};

	my $weak_model;
	{
		my $model = EntityModel->default_model;
		Scalar::Util::weaken($weak_model = $model);
		$model->add_storage(
			# TODO extract this
			'PerlAsync' => { loop => my $loop = IO::Async::Loop->new },
		);
		$model->name($def->{name});
		foreach my $entity_def (@{$def->{entity} || []}) {
			$model->create_entity(%$entity_def);
		}
		$code->($model);
		$model->remove_entity($_) for $model->entity->list;
		EntityModel->default_model(undef);
	}
	is_refcount($weak_model, 0, 'have no remaining refs') if $weak_model;
}

1;

