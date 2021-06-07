package Form::Tiny::Meta::Filtered;

use v5.10;
use warnings;
use Types::Standard qw(ArrayRef InstanceOf);
use Scalar::Util qw(blessed);

use Form::Tiny::Hook;
use Form::Tiny::Filter;
use Moo::Role;

our $VERSION = '2.01';

requires qw(setup);

has "filters" => (
	is => "ro",
	writer => 'set_filters',
	isa => ArrayRef [
		InstanceOf ["Form::Tiny::Filter"]
	],
	default => sub { [] },
);

sub add_filter
{
	my ($self, $filter, $code) = @_;

	if (defined blessed $filter && $filter->isa('Form::Tiny::Filter')) {
		push @{$self->filters}, $filter;
	}
	else {
		push @{$self->filters}, Form::Tiny::Filter->new(
			type => $filter,
			code => $code
		);
	}

	return $self;
}

sub add_field_filter
{
	my ($self, $field, $filter, $code) = @_;

	if (defined blessed $field && $field->isa('Form::Tiny::Filter')) {
		push @{$self->filters}, $field;
	}
	else {
		push @{$self->filters}, Form::Tiny::Filter->new(
			field => $field,
			type => $filter,
			code => $code
		);
	}

	return $self;
}

sub _apply_filters
{
	my ($self, $obj, $def, $value) = @_;

	my $name = $def->name;
	for my $filter (@{$self->filters}) {
		$value = $filter->filter($value)
			if $filter->check_field($name);
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

