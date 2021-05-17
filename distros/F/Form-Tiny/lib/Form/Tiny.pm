package Form::Tiny;

use v5.10;
use warnings;
use Types::Standard qw(Str Maybe ArrayRef InstanceOf HashRef Bool CodeRef);
use Carp qw(croak);
use Storable qw(dclone);
use Scalar::Util qw(blessed);
use Import::Into;

use Form::Tiny::FieldDefinition;
use Form::Tiny::Error;
use Form::Tiny::FieldData;
use Moo::Role;

our $VERSION = '1.13';

with "Form::Tiny::Form";

has "field_defs" => (
	is => "ro",
	isa => ArrayRef [
		(InstanceOf ["Form::Tiny::FieldDefinition"])
		->plus_coercions(HashRef, q{ Form::Tiny::FieldDefinition->new($_) })
	],
	coerce => 1,
	lazy => 1,
	default => sub {
		my ($self) = @_;
		my @data = $self->can('build_fields') ? $self->build_fields : ();
		return shift @data
			if @data == 1 && ref $data[0] eq ref [];
		return \@data;
	},
	trigger => \&_clear_form,
	writer => "set_field_defs",
);

has "input" => (
	is => "ro",
	writer => "set_input",
	trigger => \&_clear_form,
);

has "fields" => (
	is => "ro",
	isa => Maybe [HashRef],
	writer => "_set_fields",
	clearer => "_clear_fields",
	init_arg => undef,
);

has "valid" => (
	is => "ro",
	isa => Bool,
	writer => "_set_valid",
	lazy => 1,
	builder => "_validate",
	clearer => 1,
	predicate => "is_validated",
	init_arg => undef,
);

has "errors" => (
	is => "ro",
	isa => ArrayRef [InstanceOf ["Form::Tiny::Error"]],
	default => sub { [] },
	init_arg => undef,
);

has "cleaner" => (
	is => "ro",
	isa => Maybe [CodeRef],
	default => sub {
		my ($self) = @_;
		return $self->can("build_cleaner") ? $self->build_cleaner : undef;
	},
);

sub BUILD
{
	my ($self) = @_;
	$self->field_defs;    # build fields
}

sub import
{
	my ($package, $caller) = (shift, scalar caller);
	return unless @_;

	my @wanted = @_;
	my @wanted_subs = qw(form_field form_cleaner);
	my @wanted_roles = qw(Form::Tiny);

	my %subs = (
		form_field => sub {
			my ($name, @params) = @_;
			my $is_coderef = @params == 1 && ref $params[0] eq 'CODE';

			my $previous = $caller->can('build_fields') // sub { () };
			no strict 'refs';
			no warnings 'redefine';

			*{"${caller}::build_fields"} = sub {
				my %real_params = (
					(
						$is_coderef
						? %{$params[0]->(@_)}
						: @params
					),
					name => $name,
				);

				return (
					$previous->(@_),
					\%real_params
				);
			};
		},
		form_cleaner => sub {
			my ($sub) = @_;

			no strict 'refs';
			*{"${caller}::build_cleaner"} = sub {
				return $sub;
			};
		},
		form_filter => sub {
			my ($type, $sub) = @_;
			my $previous = $caller->can('build_filters') // sub { () };

			no strict 'refs';
			no warnings 'redefine';
			*{"${caller}::build_filters"} = sub {
				return (
					$previous->(@_),
					[$type, $sub],
				);
			};
		},
	);

	my %behaviors = (
		-base => {
			subs => [],
			roles => [],
		},
		-strict => {
			subs => [],
			roles => [qw(Form::Tiny::Strict)],
		},
		-filtered => {
			subs => [qw(form_filter)],
			roles => [qw(Form::Tiny::Filtered)],
		},
	);

	require Moo;
	Moo->import::into($caller);

	foreach my $type (@wanted) {
		croak "no Form::Tiny import behavior for: $type"
			unless exists $behaviors{$type};
		push @wanted_subs, @{$behaviors{$type}->{subs}};
		push @wanted_roles, @{$behaviors{$type}->{roles}};
	}

	{
		no strict 'refs';

		Moo::Role->apply_roles_to_package(
			$caller, @wanted_roles
		);

		*{"${caller}::$_"} = $subs{$_} foreach @wanted_subs;
	}

	return;
}

sub _clear_form
{
	my ($self) = @_;

	$self->_clear_fields;
	$self->clear_valid;
	$self->_clear_errors;
}

sub pre_mangle { $_[2] }
sub pre_validate { $_[1] }

sub _mangle_field
{
	my ($self, $def, $path_value) = @_;

	my $current = $path_value->value;

	# if the parameter is required (hard), we only consider it if not empty
	if (!$def->hard_required || ref $current || length($current // "")) {

		# coerce, validate, adjust
		$current = $def->get_coerced($self, $current);
		if ($def->validate($self, $current)) {
			$current = $def->get_adjusted($current);
		}

		$path_value->set_value($current);
		return 1;
	}

	return;
}

sub _find_field
{
	my ($self, $fields, $field_def) = @_;

	my @found;
	my $traverser;
	$traverser = sub {
		my ($curr_path, $next_path, $value) = @_;

		if (@$next_path == 0) {
			push @found, [$curr_path, $value];
		}
		else {
			my $next = shift @$next_path;
			my $want_array = $next eq $Form::Tiny::FieldDefinition::array_marker;

			if ($want_array && ref $value eq ref []) {
				for my $index (0 .. $#$value) {
					return    # may be an error, exit early
						unless $traverser->([@$curr_path, $index], [@$next_path], $value->[$index]);
				}

				if (@$value == 0) {
					if (@$next_path > 0) {
						return;
					}
					else {
						# we had aref here, so we want it back in resulting hash
						push @found, [$curr_path, [], 1];
					}
				}
			}
			elsif (!$want_array && ref $value eq ref {} && exists $value->{$next}) {
				push @$curr_path, $next;
				return $traverser->($curr_path, $next_path, $value->{$next});
			}
			else {
				return;
			}
		}

		return 1;    # all ok
	};

	my @parts = $field_def->get_name_path;
	if ($traverser->([], \@parts, $fields)) {
		return Form::Tiny::FieldData->new(items => \@found);
	}
	return;
}

sub _assign_field
{
	my ($self, $fields, $field_def, $path_value) = @_;

	my @arrays = map { $_ eq $Form::Tiny::FieldDefinition::array_marker } $field_def->get_name_path;
	my @parts = @{$path_value->path};
	my $current = \$fields;
	for my $i (0 .. $#parts) {

		# array_path will contain array indexes for each array marker
		if ($arrays[$i]) {
			$current = \${$current}->[$parts[$i]];
		}
		else {
			$current = \${$current}->{$parts[$i]};
		}
	}

	$$current = $path_value->value;
}

sub _validate
{
	my ($self) = @_;
	my $dirty = {};
	$self->_clear_errors;

	if (ref $self->input eq ref {}) {
		my $fields = $self->pre_validate(dclone($self->input));
		foreach my $validator (@{$self->field_defs}) {
			my $curr_f = $validator->name;

			my $current_data = $self->_find_field($fields, $validator);
			if (defined $current_data) {
				my $all_ok = 1;

				# This may have multiple iterations only if there's an array
				foreach my $path_value (@{$current_data->items}) {
					unless ($path_value->structure) {
						$path_value->set_value($self->pre_mangle($validator, $path_value->value));
						$all_ok = $self->_mangle_field($validator, $path_value) && $all_ok;
					}
					$self->_assign_field($dirty, $validator, $path_value);
				}

				# found and valid, go to the next field
				next if $all_ok;
			}

			# for when it didn't pass the existence test
			if ($validator->has_default) {
				$self->_assign_field($dirty, $validator, $validator->get_default($self));
			}
			elsif ($validator->required) {
				$self->add_error(Form::Tiny::Error::DoesNotExist->new(field => $curr_f));
			}
		}
	}
	else {
		$self->add_error(Form::Tiny::Error::InvalidFormat->new);
	}

	$self->cleaner->($self, $dirty)
		if defined $self->cleaner && !$self->has_errors;

	my $form_valid = !$self->has_errors;
	$self->_set_fields($form_valid ? $dirty : undef);

	return $form_valid;
}

sub check
{
	my ($self, $input) = @_;

	$self->set_input($input);
	return $self->valid;
}

sub validate
{
	my ($self, $input) = @_;

	return if $self->check($input);
	return $self->errors;
}

sub add_error
{
	my ($self, $error) = @_;
	croak "error has to be an instance of Form::Tiny::Error"
		unless blessed $error && $error->isa("Form::Tiny::Error");

	push @{$self->errors}, $error;
	return;
}

sub has_errors
{
	my ($self) = @_;
	return @{$self->errors} > 0;
}

sub _clear_errors
{
	my ($self) = @_;
	@{$self->errors} = ();
	return;
}

1;

__END__

=head1 NAME

Form::Tiny - Input validator implementation centered around Type::Tiny

=head1 SYNOPSIS

	package MyForm;

	use Form::Tiny -base;

	form_filed 'my_field' => {
		required => 1,
	};

	form_filed 'another_field' => {
		required => 1,
	};

=head1 DESCRIPTION

Main class of the Form::Tiny system - this is a role that provides most of the module's functionality.

=head1 DOCUMENTATION INDEX

=over

=item * L<Form::Tiny::Manual> - main reference

=item * L<Form::Tiny::Manual::Internals> - Form::Tiny without syntactic sugar

=item * Most regular packages contains information on symbols they contain.

=back

=head1 IMPORTING

Starting with version 1.10 you can enable syntax helpers by using import flags:

	package MyForm;

	# imports form_field and form_cleaner helpers
	use Form::Tiny -base;

	# imports form_field, form_filter and form_cleaner helpers
	use Form::Tiny -filtered;

	# fully-featured form:
	use Form::Tiny -filtered, -strict;


=head2 IMPORTED FUNCTIONS

=head3 form_field

	form_field $name => %arguments;
	form_field $name => $coderef;

Imported when any flag is present. $coderef gets passed the form instance and should return a hashref. Neither %arguments nor $coderef return data should include the name in the hash, it will be copied from the first argument.

Note that this field definition method is not capable of returning a subclass of L<Form::Tiny::FieldDefinition>. If you need a subclass, you will need to use bare-bones method of form construction. Refer to L<Form::Tiny::Manual::Internals> for details.

=head3 form_cleaner

	form_cleaner $sub;

Imported when any flag is present. C<$sub> will be ran as the very last step of form validation. There can't be more than one cleaner in a form. See L</build_cleaner>.

=head3 form_filter

	form_filter $type, $sub;

Imported when the -filtered flag is present. $type should be a Type::Tiny (or compatible) type check. For each input field that passes that check, $sub will be ran. See L<Form::Tiny::Filtered> for details on filters.

=head1 ADDED INTERFACE

This section describes the interface added to your class after mixing in the Form::Tiny role.

=head2 ATTRIBUTES

Each of the attributes can be accessed by calling its name as a function on Form::Tiny object.

=head3 field_defs

Contains an array reference of L<Form::Tiny::FieldDefinition> instances. A coercion from a hash reference can be performed upon writing.

B<writer:> I<set_field_defs>

B<built by:> I<build_fields>

=head3 input

Contains the input data passed to the form.

B<writer:> I<set_input>

=head3 fields

Contains the validated and cleaned fields set after the validation is complete. Cannot be specified in the constructor.

=head3 valid

Contains the result of the validation - a boolean value. Gets produced lazily upon accessing it, so calling C<< $form->valid; >> validates the form automatically.

B<clearer:> I<clear_valid>

B<predicate:> I<is_validated>

=head3 errors

Contains an array reference of form errors which were detected by the last performed validation. Each error is an instance of L<Form::Tiny::Error>.

B<predicate:> I<has_errors>

=head2 METHODS

This section describes standalone methods available in the module - they are not directly connected to any of the attributes.

=head3 new

This is a Moose-flavored constructor for the class. It accepts a hash or hash reference of parameters, which are the attributes specified above.

=head3 check

=head3 validate

These methods are here to ensure that a Form::Tiny instance can be used as a type validator itself by other form classes.

I<check> returns a boolean value that indicates whether the validation of input data was successful.

I<validate> does the same thing, but instead of returning a boolean it returns a list of errors that were detected, or undef if none.

Both methods take input data as the only argument.

=head3 add_error

Adds an error to form - should be called with an instance of L<Form::Tiny::Error> as its only argument. This should only be done during validation with customization methods listed below.

=head1 CUSTOMIZATION

A form instance can be customized by overriding any of the following methods:

=head2 build_fields

This method should return an array or array reference of field definitions: either L<Form::Tiny::FieldDefinition> instances or hashrefs which can be used to construct these instances.

It is passed a single argument, which is the class instance. It can be used to add errors in coderefs or to use class fields in form building.

=head2 build_cleaner

An optional cleaner is a function that will be called as the very last step of the validation process. It can be used to have a broad look on all of the validated form fields at once and introduce any synchronization errors, like a field requiring other field to be set.

Using I<add_error> inside this function will cause the form to fail the validation process.

In I<build_cleaner> method you're required to return a subroutine reference that will be called with two arguments: a form being validated and a set of "dirty" fields - validated and ready to be cleaned. This subroutine should not return the data - its return value will be discarded.

=head2 pre_mangle

This method is called every time an input field value is about to be changed by coercing and adjusting. It gets passed two arguments: an instance of L<Form::Tiny::FieldDefinition> and a value obtained from input data.

This method should return a new value for the field, which will replace the old one.

=head2 pre_validate

This method is called once before the validation process has started. It gets passed a deep copy of input data and is expected to return a value that will be used to obtain every field value during validation.

=head1 AUTHOR

Bartosz Jarzyna E<lt>brtastic.dev@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2020 - 2021 by Bartosz Jarzyna

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.1 or,
at your option, any later version of Perl 5 you may have available.

=cut
