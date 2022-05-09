package Form::Tiny::Meta;

use v5.10;
use strict;
use warnings;
use Moo;
use Types::Standard qw(Str ArrayRef HashRef InstanceOf Bool);
use Scalar::Util qw(blessed);
use Carp qw(croak carp);
use Sub::Util qw(set_subname);

use Form::Tiny::FieldDefinitionBuilder;
use Form::Tiny::Hook;
use Form::Tiny::Error;
use Form::Tiny::Utils qw(try uniq get_package_form_meta);
require Moo::Role;

use namespace::clean;

our $VERSION = '2.12';

# more clear error messages in some crucial cases
our @CARP_NOT = qw(Form::Tiny Form::Tiny::Form);

has 'package' => (
	is => 'ro',
	writer => '_set_package',
	isa => Str,
	predicate => 'has_package',
);

has 'fields' => (
	is => 'ro',
	writer => 'set_fields',
	isa => ArrayRef [
		InstanceOf ['Form::Tiny::FieldDefinitionBuilder'] | InstanceOf ['Form::Tiny::FieldDefinition']
	],
	default => sub { [] },
);

has 'is_flat' => (
	is => 'ro',
	writer => 'set_flat',
	default => sub { 1 },
);

has 'is_dynamic' => (
	is => 'ro',
	writer => 'set_dynamic',
	default => sub { 0 },
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
	writer => '_set_complete',
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

has 'static_blueprint' => (
	is => 'ro',
	isa => HashRef,
	lazy => 1,
	builder => '_build_blueprint',
);

sub set_package
{
	my ($self, $package) = @_;
	$self->_set_package($package);

	if (!$package->can('form_meta')) {
		no strict 'refs';
		no warnings 'redefine';

		*{"${package}::form_meta"} = sub {
			return get_package_form_meta(ref $_[0] || $_[0]);
		};
		set_subname "${package}::form_meta", *{"${package}::form_meta"};
	}
}

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

	# running hooks always returns the last element they're passed
	# (unless they are not modifying, then they don't return anything)
	for my $hook (@{$self->hooks->{$stage} // []}) {
		my $ret = $hook->code->(@data);
		splice @data, -1, 1, $ret
			if $hook->is_modifying;
	}

	return $data[-1];
}

sub inline_hooks
{
	my ($self) = @_;

	$self->{_cache}{inline_hooks} //= do {
		my %inlined;
		for my $stage (keys %{$self->hooks}) {
			my @hooks = @{$self->hooks->{$stage}};
			$inlined{$stage} = sub {
				my @data = @_;

				for my $hook (@hooks) {
					my $ret = $hook->code->(@data);
					splice @data, -1, 1, $ret
						if $hook->is_modifying;
				}

				return $data[-1];
			};
		}

		\%inlined;
	};

	return $self->{_cache}{inline_hooks};
}

sub bootstrap
{
	my ($self) = @_;
	return if $self->complete;

	# package name may be non-existent if meta is anon
	if ($self->has_package) {

		# when this breaks, mst gets to point and laugh at me
		my @parents = do {
			my $package_name = $self->package;
			no strict 'refs';
			@{"${package_name}::ISA"};
		};

		my @real_parents = grep { $_->can('form_meta') && $_->form_meta->isa(__PACKAGE__) } @parents;

		croak 'Form::Tiny does not support multiple inheritance'
			if @real_parents > 1;

		my ($parent) = @real_parents;

		# this is required so that proper hooks on inherit_from can be fired
		$self->inherit_roles_from($parent ? $parent->form_meta : undef);
		$self->inherit_from($parent->form_meta) if $parent;
	}

	$self->setup;
}

sub setup
{
	my ($self) = @_;

	# at this point, all roles should already be merged and all inheritance done
	# we can make the meta definition complete
	$self->_set_complete(1);
	return;
}

sub resolved_fields
{
	my ($self, $object) = @_;

	return [@{$self->fields}] if !$self->is_dynamic;

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
	delete $self->{_cache};

	croak 'adding a form field requires at least one parameter'
		unless scalar @parameters;

	my $scalar_param = shift @parameters;
	if (ref $scalar_param eq '') {
		$scalar_param = {@parameters, name => $scalar_param};
	}

	my $builder = Form::Tiny::FieldDefinitionBuilder->new(data => $scalar_param)->build;
	push @{$self->fields}, $builder;

	$self->set_dynamic(1)
		if $builder->isa('Form::Tiny::FieldDefinitionBuilder');

	# NOTE: we can only know if the form is flat if it is not dynamic
	# otherwise we need to assume it is not flat
	$self->set_flat(0)
		if $self->is_dynamic || @{$builder->get_name_path->path} > 1;

	return $builder;
}

sub add_field_validator
{
	my ($self, $field, $message, $code) = @_;
	delete $self->{_cache};

	push @{$field->addons->{validators}}, [$message, $code];
	return $self;
}

sub add_hook
{
	my ($self, $hook, $code) = @_;
	delete $self->{_cache};

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

sub inherit_roles_from
{
	my ($self, $parent) = @_;

	if (defined $parent) {
		$self->set_meta_roles([uniq(@{$parent->meta_roles}, @{$self->meta_roles})]);
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

	$self->set_flat($parent->is_flat);
	$self->set_dynamic($parent->is_dynamic);

	return $self;
}

sub _build_blueprint
{
	my ($self, $context) = @_;
	my %result;

	# croak, since we don't know anything about dynamic fields in static context
	croak "Can't create a blueprint of a dynamic form"
		if $self->is_dynamic && !$context;

	# if context is given, get the cached resolved fields from it
	# note: context will never be passed when it is called by Moo to build 'blueprint'
	my $fields = $context ? $context->field_defs : $self->fields;

	for my $def (@$fields) {
		my $value = $def;
		if ($def->is_subform) {
			my $meta = get_package_form_meta(ref $def->type);
			$value = $meta->blueprint($def->type);
		}

		my @meta = @{$def->get_name_path->meta};
		my @path = @{$def->get_name_path->path};

		# adjust path so that instead of stars (*) we get zeros
		@path = map { $meta[$_] eq 'ARRAY' ? 0 : $path[$_] } 0 .. $#path;

		Form::Tiny::Utils::_assign_field(
			\%result,
			$def, [
				{
					path => \@path,
					value => $value
				}
			]
		);
	}

	return \%result;
}

sub blueprint
{
	my ($self, $context) = @_;

	if ($self->is_dynamic) {
		return $self->_build_blueprint($context);
	}
	else {
		# $context can be skipped if the form is not dynamic
		return $self->static_blueprint;
	}
}

1;

