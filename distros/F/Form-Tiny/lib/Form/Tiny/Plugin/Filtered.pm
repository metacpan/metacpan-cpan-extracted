package Form::Tiny::Plugin::Filtered;
$Form::Tiny::Plugin::Filtered::VERSION = '2.16';
use v5.10;
use strict;
use warnings;
use Types::Standard qw(ArrayRef InstanceOf Str);
use Scalar::Util qw(blessed);
use Carp qw(carp);

use Form::Tiny::Hook;
use Form::Tiny::Plugin::Filtered::Filter;
use Form::Tiny::Utils qw(trim);

use parent 'Form::Tiny::Plugin';

sub plugin
{
	my ($self, $caller, $context) = @_;

	return {
		subs => {
			form_filter => sub {
				$$context = undef;
				$caller->form_meta->add_filter(@_);
			},
			field_filter => sub {
				$caller->form_meta->add_field_filter($self->use_context($context), @_);
			},
			field_validator => sub {
				$caller->form_meta->add_field_validator($self->use_context($context), @_);
			},
			form_trim_strings => sub {
				$$context = undef;
				$caller->form_meta->add_global_trim_filter;
			},
		},

		meta_roles => [__PACKAGE__],
	};
}

use Moo::Role;

requires qw(inherit_from setup);

has 'filters' => (
	is => 'ro',
	writer => 'set_filters',
	isa => ArrayRef [
		InstanceOf ['Form::Tiny::Plugin::Filtered::Filter']
	],
	default => sub { [] },
);

sub _create_filter
{
	my ($self, $filter, $code) = @_;

	return $filter
		if defined blessed $filter && $filter->isa('Form::Tiny::Plugin::Filtered::Filter');

	return Form::Tiny::Plugin::Filtered::Filter->new(
		type => $filter,
		code => $code
	);
}

sub add_global_trim_filter
{
	my ($self) = @_;

	return $self->add_filter(Str, sub { trim $_[1] });
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

	if ($parent->DOES('Form::Tiny::Plugin::Filtered')) {
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

