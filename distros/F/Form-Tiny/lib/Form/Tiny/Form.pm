package Form::Tiny::Form;

use v5.10;
use strict;
use warnings;
use Types::Standard qw(Maybe ArrayRef InstanceOf HashRef Bool);
use Carp qw(croak);
use Scalar::Util qw(blessed);

use Form::Tiny::PathValue;
use Form::Tiny::Error;
use Form::Tiny::Utils qw(try get_package_form_meta);
use Moo::Role;

our $VERSION = '2.06';

has 'field_defs' => (
	is => 'ro',
	isa => ArrayRef [InstanceOf ['Form::Tiny::FieldDefinition']],
	clearer => '_ft_clear_field_defs',
	default => sub {
		my ($self) = shift;
		return $self->form_meta->resolved_fields($self);
	},
	lazy => 1,
	init_arg => undef,
);

has '_ft_field_cache' => (
	is => 'ro',
	isa => HashRef [InstanceOf ['Form::Tiny::FieldDefinition']],
	clearer => '_ft_clear_field_cache',
	default => sub {
		return {map { $_->name => $_ } @{shift()->field_defs}};
	},
	lazy => 1,
	init_arg => undef,
);

has 'input' => (
	is => 'ro',
	writer => 'set_input',
	trigger => \&_ft_clear_form,
);

has 'fields' => (
	is => 'ro',
	isa => Maybe [HashRef],
	writer => '_ft_set_fields',
	clearer => '_ft_clear_fields',
	init_arg => undef,
);

has 'valid' => (
	is => 'ro',
	isa => Bool,
	lazy => 1,
	builder => '_ft_validate',
	clearer => 1,
	predicate => 'is_validated',
	init_arg => undef,
);

has 'errors' => (
	is => 'ro',
	isa => ArrayRef [InstanceOf ['Form::Tiny::Error']],
	lazy => 1,
	default => sub { [] },
	init_arg => undef,
);

sub _ft_clear_form
{
	my ($self) = @_;

	$self->_ft_clear_field_defs;
	$self->_ft_clear_field_cache;
	$self->_ft_clear_fields;
	$self->clear_valid;
	$self->_ft_clear_errors;
}

sub _ft_mangle_field
{
	my ($self, $def, $path_value, $out_ref) = @_;

	my $current = $out_ref ? $path_value : $path_value->value;

	# We got the parameter, now we have to check if it is not empty
	# Even if it is, it may still be handled if isn't hard-required
	if (ref $current || length($current // '') || !$def->hard_required) {

		# coerce, validate, adjust
		$current = $def->get_coerced($self, $current);
		if ($def->validate($self, $current)) {
			$current = $def->get_adjusted($self, $current);
		}

		if ($out_ref) {
			$$out_ref = $current;
		}
		else {
			$path_value->set_value($current);
		}

		return 1;
	}

	return;
}

sub _ft_find_field
{
	my ($self, $fields, $field_def) = @_;

	# the result goes here
	my @found;
	my $traverser;
	$traverser = sub {
		my ($curr_path, $path, $index, $value) = @_;
		my $last = $index == @{$path->meta};

		if ($last) {
			push @found, [$curr_path, $value];
		}
		else {
			my $next = $path->path->[$index];
			my $meta = $path->meta->[$index];

			if ($meta eq 'ARRAY' && ref $value eq 'ARRAY') {
				for my $ind (0 .. $#$value) {
					return    # may be an error, exit early
						unless $traverser->([@$curr_path, $ind], $path, $index + 1, $value->[$ind]);
				}

				if (@$value == 0) {

					# we wanted to have a deeper structure, but its not there, so clearly an error
					return unless $index == $#{$path->meta};

					# we had aref here, so we want it back in resulting hash
					push @found, [$curr_path, [], 1];
				}
			}
			elsif ($meta eq 'HASH' && ref $value eq 'HASH' && exists $value->{$next}) {
				return $traverser->([@$curr_path, $next], $path, $index + 1, $value->{$next});
			}
			else {
				# something's wrong with the input here - does not match the spec
				return;
			}
		}

		return 1;    # all ok
	};

	if ($traverser->([], $field_def->get_name_path, 0, $fields)) {
		return [
			map {
				Form::Tiny::PathValue->new(
					path => $_->[0],
					value => $_->[1],
					structure => $_->[2]
				)
			} @found
		];
	}
	return;
}

sub _ft_assign_field
{
	my ($self, $fields, $field_def, $path_value) = @_;

	my @arrays = map { $_ eq 'ARRAY' } @{$field_def->get_name_path->meta};
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

### OPTIMIZATION: detect and use faster route for flat forms

sub _ft_validate_flat
{
	my ($self, $fields, $dirty) = @_;
	my $meta = $self->form_meta;

	my $inline_hook = $meta->_inline_hook('before_mangle');
	foreach my $validator (@{$self->field_defs}) {
		my $curr_f = $validator->name;

		if (exists $fields->{$curr_f}) {
			next if $self->_ft_mangle_field(
				$validator,
				(
					$inline_hook
					? $inline_hook->($self, $validator, $fields->{$curr_f})
					: $fields->{$curr_f}
				),
				\$dirty->{$curr_f}
			);
		}

		# for when it didn't pass the existence test
		if ($validator->has_default) {
			$dirty->{$curr_f} = $validator->get_default($self);
		}
		elsif ($validator->required) {
			$self->add_error($meta->build_error(Required => field => $curr_f));
		}
	}
}

sub _ft_validate_nested
{
	my ($self, $fields, $dirty) = @_;
	my $meta = $self->form_meta;

	my $inline_hook = $meta->_inline_hook('before_mangle');
	foreach my $validator (@{$self->field_defs}) {
		my $curr_f = $validator->name;

		my $current_data = $self->_ft_find_field($fields, $validator);
		if (defined $current_data) {
			my $all_ok = 1;

			# This may have multiple iterations only if there's an array
			foreach my $path_value (@$current_data) {
				unless ($path_value->structure) {
					$path_value->set_value($inline_hook->($self, $validator, $path_value->value))
						if $inline_hook;
					$all_ok = $self->_ft_mangle_field($validator, $path_value) && $all_ok;
				}
				$self->_ft_assign_field($dirty, $validator, $path_value);
			}

			# found and valid, go to the next field
			next if $all_ok;
		}

		# for when it didn't pass the existence test
		if ($validator->has_default) {
			$self->_ft_assign_field(
				$dirty,
				$validator,
				Form::Tiny::PathValue->new(
					path => $validator->get_name_path->path,
					value => $validator->get_default($self),
				)
			);
		}
		elsif ($validator->required) {
			$self->add_error($meta->build_error(Required => field => $curr_f));
		}
	}
}

sub _ft_validate
{
	my ($self) = @_;
	my $meta = $self->form_meta;
	$self->_ft_clear_errors;

	my $fields = $self->input;
	my $err = try sub {
		$fields = $meta->run_hooks_for('reformat', $self, $fields);
	};

	my $dirty = {};
	if (!$err && ref $fields eq 'HASH') {
		$meta->run_hooks_for('before_validate', $self, $fields);

		if ($meta->is_flat) {
			$self->_ft_validate_flat($fields, $dirty);
		}
		else {
			$self->_ft_validate_nested($fields, $dirty);
		}
	}
	else {
		$self->add_error($meta->build_error(InvalidFormat =>));
	}

	$meta->run_hooks_for('after_validate', $self, $dirty);

	$meta->run_hooks_for('cleanup', $self, $dirty)
		if !$self->has_errors;

	my $form_valid = !$self->has_errors;
	$self->_ft_set_fields($form_valid ? $dirty : undef);

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
	my ($self, @error) = @_;

	my $error;
	if (@error == 1) {
		if (defined blessed $error[0]) {
			$error = shift @error;
			croak 'error passed to add_error must be an instance of Form::Tiny::Error'
				unless $error->isa('Form::Tiny::Error');
		}
		else {
			$error = Form::Tiny::Error->new(error => @error);
		}
	}
	elsif (@error == 2) {
		$error = Form::Tiny::Error->new(
			field => $error[0],
			error => $error[1],
		);
	}
	else {
		croak 'invalid arguments passed to $form->add_error';
	}

	# check if the field exists
	for ($error->field) {
		croak "form does not contain a field definition for $_"
			if defined $_ && !exists $self->_ft_field_cache->{$_};
	}

	# unwrap nested form errors
	$error = $error->error
		if $error->isa('Form::Tiny::Error::NestedFormError');

	push @{$self->errors}, $error;
	$self->form_meta->run_hooks_for('after_error', $self, $error);
	return $self;
}

sub errors_hash
{
	my ($self) = @_;

	my %ret;
	for my $error (@{$self->errors}) {
		push @{$ret{$error->field // ''}}, $error->error;
	}

	return \%ret;
}

sub has_errors
{
	my ($self) = @_;
	return @{$self->errors} > 0;
}

sub _ft_clear_errors
{
	my ($self) = @_;

	@{$self->errors} = ();
	return;
}

# This fixes form inheritance for other role systems than Moose
around DOES => sub {
	my ($orig, $self, @args) = @_;

	return Moo::Role::does_role($self, @args)
		|| $self->$orig(@args);
};

1;

__END__

=head1 NAME

Form::Tiny::Form - main role of the Form::Tiny system

=head1 SYNOPSIS

See L<Form::Tiny::Manual>

=head1 DESCRIPTION

This role gets automatically mixed in by importing L<Form::Tiny> into your namespace.

=head1 ADDED INTERFACE

This section describes the interface added to your class after mixing in the Form::Tiny role.

=head2 ATTRIBUTES

Each of the attributes can be accessed by calling its name as a function on Form::Tiny object.

=head3 input

Contains the input data passed to the form.

B<writer:> I<set_input>

=head3 fields

Contains the validated and cleaned fields set after the validation is complete. Cannot be specified in the constructor.

=head3 field_defs

Contains an array reference of L<Form::Tiny::FieldDefinition> instances fetched from the metaclass with context of current instance. Rebuilds everytime new input data is set.

=head3 valid

Contains the result of the validation - a boolean value. Gets produced lazily upon accessing it, so calling C<< $form->valid; >> validates the form automatically.

B<clearer:> I<clear_valid>

B<predicate:> I<is_validated>

=head3 errors

Contains an array reference of form errors which were detected by the last performed validation. Each error is an instance of L<Form::Tiny::Error>.

B<predicate:> I<has_errors>

=head2 METHODS

This section describes standalone methods available in the module - they are not directly connected to any of the attributes.

=head3 form_meta

Returns the form metaobject, an instance of L<Form::Tiny::Meta>.

=head3 new

This is a Moose-flavored constructor for the class. It accepts a hash or hash reference of parameters, which are the attributes specified above.

=head3 check

=head3 validate

These methods are here to ensure that a Form::Tiny instance can be used as a type validator itself by other form classes.

I<check> returns a boolean value that indicates whether the validation of input data was successful.

I<validate> does the same thing, but instead of returning a boolean it returns a list of errors that were detected, or undef if none.

Both methods take input data as the only argument.

=head3 errors_hash

Helper method which returns errors much like the C<errors> form attribute, but in a hash reference with form field names as keys. Errors not assigned to any specific field end up in empty string key. The values are array references of error messages (strings).

Each field will only be present in the hash if it has an error assigned to it. If no errors are present, the hash will be empty.

It allows you to get errors in format which is easier to navigate:

	{
		'' => [
			# global form errors
		],
		# specific field errors
		'field1' => [
			'something went wrong'
		],

	}

=head3 add_error

	$form->add_error($error_string);
	$form->add_error($field_name => $error_string);
	$form->add_error($error_object);

Adds an error to the form. If C<$error_object> style is used, it must be an instance of L<Form::Tiny::Error>.

