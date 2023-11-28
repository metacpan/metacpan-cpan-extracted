package Form::Tiny::Meta;
$Form::Tiny::Meta::VERSION = '2.22';
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
use Form::Tiny::Utils qw(try uniq get_package_form_meta has_form_meta);
require Moo::Role;

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
			goto \&get_package_form_meta;
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

		my @real_parents = grep { has_form_meta($_) } @parents;

		croak 'Form::Tiny does not support multiple inheritance'
			if @real_parents > 1;

		my ($parent) = @real_parents;

		# this is required so that proper hooks on inherit_from can be fired
		$self->inherit_roles_from($parent ? $parent->form_meta : undef);
		$self->inherit_from($parent->form_meta) if $parent;
	}
	else {
		# no package means no inheritance, but run this to properly consume meta roles
		$self->inherit_roles_from;
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

	my $builder = Form::Tiny::FieldDefinitionBuilder->new(build_data => $scalar_param)->build;
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
	my ($self, $context, %params) = @_;
	my %result;

	my $recurse = $params{recurse} // 1;
	my $transform_base = sub {
		my ($def) = @_;

		if ($def->is_subform && $recurse) {
			my $meta = get_package_form_meta($def->type);
			return $meta->blueprint($def->type, %params);
		}

		return $def;
	};

	my $transform = $params{transform} // $transform_base;

	# croak, since we don't know anything about dynamic fields in static context
	croak "Can't create a blueprint of a dynamic form"
		if $self->is_dynamic && !$context;

	# if context is given, get the cached resolved fields from it
	# note: context will never be passed when it is called by Moo to build 'blueprint'
	my $fields = $context ? $context->field_defs : $self->fields;

	for my $def (@$fields) {
		my $meta = $def->get_name_path->meta_arrays;
		my @path = @{$def->get_name_path->path};

		# adjust path so that instead of stars (*) we get zeros
		@path = map { $meta->[$_] ? 0 : $path[$_] } 0 .. $#path;

		Form::Tiny::Utils::_assign_field(
			\%result,
			$def, [[\@path, scalar $transform->($def, $transform_base)]]
		);
	}

	return \%result;
}

sub blueprint
{
	my ($self, @args) = @_;
	my $context;
	$context = shift @args
		if @args && has_form_meta($args[0]);

	if ($self->is_dynamic || @args) {
		return $self->_build_blueprint($context, @args);
	}
	else {
		# $context can be skipped if the form is not dynamic
		return $self->static_blueprint;
	}
}

1;

__END__

=head1 NAME

Form::Tiny::Meta - main class of the Form::Tiny metamodel

=head1 SYNOPSIS

	my $meta_object = FormClass->form_meta;

=head1 DESCRIPTION

This documentation lists attributes and methods of the metamodel class of a
Form::Tiny form. For an overview, see L<Form::Tiny::Manual::Internals>.

=head1 ADDED INTERFACE

This section describes the interface added to your class after mixing in the
Form::Tiny role.

=head2 ATTRIBUTES

Each of the attributes can be accessed by calling its name as a function on
Form::Tiny::Meta object.

=head3 package

Contains the name of a package this metaobject belongs to. May be empty if the
form is anonymous.

Setting the package will automatically install a C<form_meta> method for it,
if it doesn't exist already.

B<predicate:> I<has_package>

B<writer:> I<set_package>

=head3 fields

Array reference of fields defined for this form. Each field can be either of
class L<Form::Tiny::FieldDefinition> (if it is static) or
Form::Tiny::FieldDefinitionBuilder (if dynamic).

Don't use this attribute if you want to obtain finished fields for a particular
form object - use L</resolved_fields> for that instead.

B<writer:> I<set_fields>

=head3 hooks

Array reference of hooks defined for this form. Each will be an instance of
L<Form::Tiny::Hook>.

B<writer:> I<set_hooks>

=head3 complete

Boolean flag used to keep track whether the form building has finished. The
form is considered finished after L<setup> method was fired.

A finished form is done with inheritance and ready to be customized. This
should usually not be a concern since form bootstrapping is done as soon as
possible.

=head3 meta_roles

A list of roles which have been applied to this metaobject. Children forms will
use it to apply the same roles to themselves. It is also used to apply
C<meta_roles> from L<Form::Tiny::Plugin>.

B<writer:> I<set_meta_roles>

=head3 form_roles

A list of roles which have been applied to the L</package>. Since the form
packages inherit from one another, this is not inherited from the parent's
metaobject. It is used to apply C<roles> from L<Form::Tiny::Plugin>.

B<writer:> I<set_form_roles>

=head3 messages

A list of messages used for creating errors in L</build_error>. The values are
usually set with L<Form::Tiny/form_message>.

=head3 is_flat

Boolean flag used to keep track whether the form is flat. Form is considered
flat if it has no nested or dynamic fields.

B<writer:> I<set_flat>

=head3 is_dynamic

Boolean flag used to keep track whether the form is dynamic. Form is considered
dynamic if it has dynamic fields. Note that a form cannot be flat and dynamic
at the same time.

B<writer:> I<set_dynamic>

=head2 METHODS

This section describes standalone methods available in the module - they are
not directly connected to any of the attributes.

=head3 new

This is a Moose-flavored constructor for the class. It accepts a hash or hash
reference of parameters, which are the attributes specified above.

=head3 build_error

	my $error = $meta->build_error($class => %params);

Builds an error of class C<"Form::Tiny::Class::$class"> and uses C<%params> to
contsruct it. If a custom message was defined for this type, it will be used.

=head3 run_hooks_for

	$meta->run_hooks_for($stage => @data);

Runs hooks for a given C<$stage>. C<@data> should contain all a hook type need for running.

=head3 bootstrap

	$meta->bootstrap;

Main metaobject initialization routine. It only runs if the model is not yet
complete. Performs inheritance and runs L</setup> after it's done.

=head3 setup

	$meta->setup;

Sets the form as complete and does nothing otherwise. It is meant to be used as
a checkpoint for any extensions where they can safely hook in and install their
custom behavior, for example:

	after 'setup' => sub {
		my ($self) = @_;

		$self->add_hook(...);
	};

=head3 resolved_fields

	my $result_aref = $meta->resolved_fields($form_object);

Returns field objects resolved for given C<$form_object>. The resulting array
reference will only contain instances of L<Form::Tiny::FieldDefinition> built
for given form.

=head3 add_field

Adds a new field to the form.

=head3 add_field_validator

Adds a new field validator to the form's field.

=head3 add_hook

Adds a new hook to the form.

=head3 add_message

Adds a new error message to the form.

=head3 inherit_roles_from

	$meta->inherit_roles_from($parent);

Inherits and applies various roles. If an extension would alter the way roles
are treated, this is the place to hook into.

=head3 inherit_from

	$meta->inherit_from($parent);

Inherits all the form attributes from C<$parent>. If an extension introduces
new fields and you want them to be inherited, you must hook to this method,
like:

	after 'inherit_from' => sub {
		my ($self, $parent) = @_;

		$self->set_my_field([@{$self->my_field}, @{$parent->my_field}]);
	};

=head3 static_blueprint

=head3 blueprint

	# for dynamic forms or when
	# it is not known whether the form in dynamic
	$blueprint = $meta->blueprint($form_object, %options);

	# for static forms
	$blueprint = $meta->blueprint(%options);

For blueprint explanation, see L<Form::Tiny::Manual::Internals/Form blueprint>.

For static forms without extra options, the blueprint will be cached and reused
on the next call. Otherwise, it has to be generated each time, which will
impose a performance hit if it is called frequently.

Additionally, the C<blueprint> method can accept a hash of options. Currently
supported options are:

=over

=item * recurse => Bool

If passed C<0>, subforms will not be turned into their own blueprints, but will
end up as a L<Form::Tiny::FieldDefinition> object instead. C<1> by default.

=item * transform => sub ($field_definition, $default_handler)

This option enables a way to specify a custom handler which will be used to
turn C<$field_definition> into a blueprint value. This subroutine reference is
expected to return a scalar value - a new blueprint value.

In case you want to turn back into the default handler, call C<<
$default_handler->($field_definition) >>.

=back

=head3 inline_hooks

Internal, implementation specific - returns flattened hook runners for runtime optimization.

