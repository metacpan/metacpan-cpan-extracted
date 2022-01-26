package Form::Tiny::Meta::Filtered;

use v5.10;
use strict;
use warnings;
use Types::Standard qw(ArrayRef InstanceOf);
use Scalar::Util qw(blessed);
use Carp qw(carp);

use Form::Tiny::Hook;
use Form::Tiny::Filter;
use Moo::Role;

our $VERSION = '2.04';

requires qw(setup);

has "filters" => (
	is => "ro",
	writer => 'set_filters',
	isa => ArrayRef [
		InstanceOf ["Form::Tiny::Filter"]
	],
	default => sub { [] },
);

sub _create_filter
{
	my ($self, $filter, $code) = @_;

	return $filter
		if defined blessed $filter && $filter->isa('Form::Tiny::Filter');

	return Form::Tiny::Filter->new(
		type => $filter,
		code => $code
	);
}

sub add_filter
{
	my ($self, $filter, $code) = @_;

	push @{$self->filters}, $self->_create_filter($filter, $code);
	return $self;
}

sub add_field_filter
{
	my ($self, $field, $filter, $code) = @_;

	push @{$field->addons->{filters}}, $self->_create_filter($filter, $code);
	return $self;
}

sub _apply_filters
{
	my ($self, $obj, $def, $value) = @_;

	for my $filter (@{$self->filters}) {
		$value = $filter->filter($obj, $value);
	}

	for my $filter (@{$def->addons->{filters}}) {
		$value = $filter->filter($obj, $value);
	}

	return $value;
}

after 'inherit_from' => sub {
	my ($self, $parent) = @_;

	if ($parent->DOES('Form::Tiny::Meta::Filtered')) {
		$self->set_filters([@{$parent->filters}, @{$self->filters}]);
	}
};

after 'setup' => sub {
	my ($self) = @_;

	$self->add_hook(
		Form::Tiny::Hook->new(
			hook => 'before_mangle',
			code => sub { $self->_apply_filters(@_) },
			inherited => 0,
		)
	);
};

1;

