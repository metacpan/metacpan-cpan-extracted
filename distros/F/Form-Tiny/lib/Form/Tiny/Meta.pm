package Form::Tiny::Meta;

use v5.10;
use strict;
use warnings;
use Moo;
use Types::Standard qw(Str ArrayRef HashRef InstanceOf Bool);
use Scalar::Util qw(blessed);
use Carp qw(croak carp);

use Form::Tiny::FieldDefinitionBuilder;
use Form::Tiny::Hook;
use Form::Tiny::Error;
use Form::Tiny::Utils qw(try uniq);
require Moo::Role;

use namespace::clean;

our $VERSION = '2.04';

# more clear error messages in some crucial cases
our @CARP_NOT = qw(Form::Tiny Form::Tiny::Form);

has 'package' => (
	is => 'ro',
	writer => 'set_package',
	isa => Str,
	predicate => 1,
);

has 'fields' => (
	is => 'ro',
	writer => 'set_fields',
	isa => ArrayRef [
		InstanceOf ['Form::Tiny::FieldDefinitionBuilder'] | InstanceOf ['Form::Tiny::FieldDefinition']
	],
	default => sub { [] },
);

has 'hooks' => (
	is => 'ro',
	writer => 'set_hooks',
	isa => HashRef [
		ArrayRef [InstanceOf ['Form::Tiny::Hook']]
	],
	default => sub { {} },
);

has 'complete' => (
	is => 'ro',
	isa => Bool,
	writer => '_complete',
	default => sub { 0 },
);

has 'meta_roles' => (
	is => 'ro',
	writer => 'set_meta_roles',
	isa => ArrayRef,
	default => sub { [] },
);

has 'form_roles' => (
	is => 'ro',
	writer => 'set_form_roles',
	isa => ArrayRef,
	default => sub { [] },
);

has 'messages' => (
	is => 'ro',
	isa => HashRef [Str],
	default => sub { {} },
);

sub build_error
{
	my ($self, $name, %params) = @_;
	my $class = "Form::Tiny::Error::$name";
	my $message = $self->messages->{$name};

	if (defined $message) {
		$params{error} = $message;
	}

	return $class->new(%params);
}

sub run_hooks_for
{
	my ($self, $stage, @data) = @_;

	my @hooks = @{$self->hooks->{$stage} // []};

	# running hooks always returns the last element they're passed
	# (unless they are not modifying, then they don't return anything)
	for my $hook (@hooks) {
		my $ret = $hook->code->(@data);
		splice @data, -1, 1, $ret
			if $hook->is_modifying;
	}

	return $data[-1];
}

sub setup
{
	my ($self) = @_;

	# at this point, all roles should already be merged and all inheritance done
	# we can make the meta definition complete
	$self->_complete(1);
	return;
}

sub resolved_fields
{
	my ($self, $object) = @_;

	croak 'resolved_fields requires form object'
		unless defined blessed $object;

	return [
		map {
			$_->isa('Form::Tiny::FieldDefinitionBuilder')
				? $_->build($object)
				: $_
		} @{$self->fields}
	];
}

sub add_field
{
	my ($self, @parameters) = @_;

	croak 'adding a form field requires at least one parameter'
		unless scalar @parameters;

	my $scalar_param = shift @parameters;
	if (ref $scalar_param eq '') {
		$scalar_param = {@parameters, name => $scalar_param};
	}

	my $builder = Form::Tiny::FieldDefinitionBuilder->new(data => $scalar_param)->build;
	push @{$self->fields}, $builder;

	return $builder;
}

sub add_field_validator
{
	my ($self, $field, $message, $code) = @_;

	push @{$field->addons->{validators}}, [$message, $code];
	return $self;
}

sub add_hook
{
	my ($self, $hook, $code) = @_;

	if (defined blessed $hook && $hook->isa('Form::Tiny::Hook')) {
		push @{$self->hooks->{$hook->hook}}, $hook;
	}
	else {
		push @{$self->hooks->{$hook}}, Form::Tiny::Hook->new(
			hook => $hook,
			code => $code
		);
	}
	return $self;
}

sub add_message
{
	my ($self, $name, $message) = @_;

	my $isa;
	my $err = try sub {
		$isa = "Form::Tiny::Error::$name"->isa('Form::Tiny::Error');
	};

	croak "$name is not a valid Form::Tiny error class name"
		unless !$err && $isa;

	$self->messages->{$name} = $message;
	return $self;
}

# this is required so that proper hooks on inherit_from can be fired
sub inherit_roles_from
{
	my ($self, $parent) = @_;

	if (defined $parent) {
		$self->set_meta_roles([uniq(@{$parent->meta_roles}, @{$self->meta_roles})]);
		$self->set_form_roles([uniq(@{$parent->form_roles}, @{$self->form_roles})]);
	}

	Moo::Role->apply_roles_to_object(
		$self, @{$self->meta_roles}
	) if @{$self->meta_roles};

	Moo::Role->apply_roles_to_package(
		$self->package, @{$self->form_roles}
	) if $self->has_package && @{$self->form_roles};

	return $self;
}

sub inherit_from
{
	my ($self, $parent) = @_;

	croak 'can only inherit from objects of Form::Tiny::Meta'
		unless defined blessed $parent && $parent->isa('Form::Tiny::Meta');

	# TODO validate for fields with same names
	$self->set_fields([@{$parent->fields}, @{$self->fields}]);

	# hooks inheritance - need to filter out hooks that are not
	# meant to be inherited
	my %hooks = %{$self->hooks};
	my %parent_hooks = %{$parent->hooks};
	for my $key (keys %parent_hooks) {
		$parent_hooks{$key} = [
			grep { $_->inherited } @{$parent_hooks{$key}}
		];
	}

	# actual hooks inheritance
	$self->set_hooks(
		{
			map {
				$_ => [@{$parent_hooks{$_} // []}, @{$hooks{$_} // []}]
			} keys %parent_hooks,
			keys %hooks
		}
	);

	return $self;
}

1;
