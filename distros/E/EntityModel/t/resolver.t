use strict;
use warnings;

=pod

package Storage::Simulator;

sub store {
	my $self = shift;
	my %args = @_;
	my $entity = delete $args{entity} or die "No entity supplied":
	my $data = delete $args{data} or die "No data supplied":
	$self
}

sub retrieve {
	my $self = shift;
	my %args = @_;
	my $entity = delete $args{entity} or die "No entity supplied":
	my $primary = delete $args{primary} or die "No primary key supplied";
	$self
}

=cut

package main;
use Test::More tests => 17;
use Test::Fatal;
use Scalar::Util qw(looks_like_number);

use IO::Async::Loop;
use Future;
use EntityModel;
use EntityModel::Resolver;

# Set up a small model
ok(my $model = EntityModel->default_model, 'get the default model');
ok($model->add_storage(
	'PerlAsync' => { loop => my $loop = IO::Async::Loop->new },
), 'attach in-memory storage');
ok($model->create_entity(
	name => $_,
	keyfield => 'name',
	auto_primary => 1,
	field => [
		{ name => 'name', type => 'text', },
	],
), 'add ' . $_) for qw(first_entity second_entity);
is($model->entity->count, 2, 'have the two entities we expected');
is($_->field->count, 2, 'have the two fields we expected for $_') for $model->entity->list;

my $completion = Future->new;
is(exception {
	resolve {
		first_entity => 'test',
		second_entity => 'second',
	} sub {
		my @id = @_;
		is(@id, 2, 'have the expected 2 entries');
		ok(my $x = shift(@id), 'first_entity has something in it');
		ok(looks_like_number($x), 'and it looks like a number');
		ok($x = shift(@id), 'second_entity has something in it');
		ok(looks_like_number($x), 'and it looks like a number');
		$completion->done;
	};
}, undef, 'can resolve without exceptions');
ok($completion->on_ready(sub {
	$loop->loop_stop;
}), 'request loop stop on completion');
ok(!$completion->is_ready, 'not yet resolved') or die 'should not have resolved already';
is(exception { $loop->loop_forever }, undef, 'can loop without raising any exceptions');
ok($completion->is_ready, 'now resolved');

done_testing;

