use strict;
use warnings;
use Test::Class;

package EntityModel::Storage::Test;
use base qw(Test::Class);
use Test::More;
use Test::Deep;
use EntityModel::Storage;
use EntityModel;

# Set up an EntityModel from a Perl hash
sub setup_model : Test(startup => 2) {
	my $self = shift;
	my $model = new_ok('EntityModel');
	ok($model->load_from(
		Perl	=> {
	 "name" => "mymodel",
	 "entity" => [ {
	  "name" => "thing",
	  "primary" => "id",
	  "field" => [
	   { "name" => "id", "type" => "int" },
	   { "name" => "name", "type" => "varchar" }
	  ] }, {
	  "name" => "other",
	  "primary" => "id",
	  "field" => [
	   { "name" => "id", "type" => "int" },
	   { "name" => "extra", "type" => "varchar" }
	  ] }
	  ] }), 'load model');
	$self->{model} = $model;
}

sub test_storage : Test(236) {
	my $self = shift;
	note $self->current_method;
	my $storage = $self->{storage} or die 'no storage';
	can_ok($storage, $_) for qw(read store remove find adjacent outer first last prev next);

	foreach my $entity ($self->{model}->entity->list) {
		note "Basic creation and removal for entity [" . $entity->name . "]";
		my %data = map { $_ => 'test' } $entity->field->list;
		delete $data{$entity->primary};
		ok(my $id = $storage->create(
			entity	=> $entity,
			data	=> \%data,
		), 'create object for ' . $entity->name);
		$data{id} = $id;
		ok(my $obj = $storage->read(
			entity	=> $entity,
			id	=> $id,
		), 'read object back for ' . $entity->name);
		cmp_deeply($obj, \%data, 'check data matches');
		ok($storage->remove(
			entity	=> $entity,
			id	=> $id,
		), 'remove object for ' . $entity->name);
		ok(!$storage->read(
			entity	=> $entity,
			id	=> $id,
		), 'can no longer read object for ' . $entity->name);
		delete $data{id};

		note "Check uniqueness on assigned ID keys";
		my %uniq;
		for (1..100) {
			my $id = $storage->create(
				entity	=> $entity,
				data	=> \%data,
			);
			ok(!($uniq{$id}++), 'ID ' . $id . ' is unique for ' . $entity->name);
		}
		$storage->remove(
			entity	=> $entity,
			id	=> $_
		) for keys %uniq;

		note "Check adjacent record handling";
		my @objs;
		for my $idx (0..8) {
			push @objs, $storage->create(
				entity	=> $entity,
				data	=> \%data,
			);
		}
		my ($prev, $next) = $storage->adjacent(
			entity	=> $entity,
			id	=> $objs[4]
		);
		ok($prev < $objs[4], 'Previous value is lower');
		ok($next > $objs[4], 'Next value is greater');
		is($prev, $storage->prev(
			entity	=> $entity,
			id	=> $objs[4]
		), 'prev value matches ->prev');
		is($next, $storage->next(
			entity	=> $entity,
			id	=> $objs[4]
		), 'next value matches ->next');
		note "Check outer handling";
		my ($first, $last) = $storage->outer(
			entity	=> $entity,
		);
		is($first, $objs[0], 'first entry is correct');
		is($last, $objs[-1], 'last entry is correct');
		is($first, $storage->first(
			entity	=> $entity,
		), 'first value matches ->first');
		is($last, $storage->last(
			entity	=> $entity,
		), 'last value matches ->last');
	}
}

package EntityModel::Storage::PerlTest;
use base qw(EntityModel::Storage::Test);
use Test::More;

sub setup_model : Test(startup => +4) {
	my $self = shift;
	$self->SUPER::setup_model;
	my $model = $self->{model};
	ok($model->add_storage(Perl => { }), 'add Perl storage');
	is($model->storage->count, 1, 'have single storage entry');
	my ($storage) = $model->storage->list;
	isa_ok($storage, 'EntityModel::Storage');
	isa_ok($storage, 'EntityModel::Storage::Perl');
	$self->{storage} = $storage;
}

package main;
Test::Class->runtests(qw(EntityModel::Storage::PerlTest));
