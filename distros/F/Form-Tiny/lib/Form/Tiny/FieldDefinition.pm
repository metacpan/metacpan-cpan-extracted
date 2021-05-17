package Form::Tiny::FieldDefinition;

use v5.10;
use warnings;
use Moo;
use Types::Standard qw(Enum Bool HasMethods CodeRef Maybe Str);
use Types::Common::String qw(NonEmptySimpleStr);
use Carp qw(croak);
use Scalar::Util qw(blessed);

use Form::Tiny::Utils;
use Form::Tiny::Error;
use Form::Tiny::PathValue;

use namespace::clean;

our $VERSION = '1.13';

our $nesting_separator = q{.};
our $array_marker = q{*};

has "name" => (
	is => "ro",
	isa => NonEmptySimpleStr,
	required => 1,
);

has "required" => (
	is => "ro",
	isa => Enum [0, 1, "soft", "hard"],
	default => sub { 0 },
);

has "type" => (
	is => "ro",
	isa => HasMethods ["validate", "check"],
	predicate => 1,
);

has "coerce" => (
	is => "ro",
	isa => Bool | CodeRef,
	default => sub { 0 },
);

has "adjust" => (
	is => "ro",
	isa => CodeRef,
	predicate => "is_adjusted",
	writer => "set_adjustment",
);

has "default" => (
	is => "ro",
	isa => CodeRef,
	predicate => 1,
	writer => "set_default",
);

has "message" => (
	is => "ro",
	isa => Str,
	predicate => 1,
);

has "data" => (
	is => "ro",
	writer => "set_data",
	predicate => 1,
);

sub BUILD
{
	my ($self, $args) = @_;

	if ($self->coerce && ref $self->coerce ne "CODE") {

		# checks for coercion == 1
		my $t = $self->type;
		croak "type doesn't provide coercion"
			if !$self->has_type
			|| !($t->can("coerce") && $t->can("has_coercion") && $t->has_coercion);
	}

	if ($self->has_default) {

		croak "default value for an array field is unsupported"
			if scalar grep { $_ eq $array_marker } $self->get_name_path;
	}

	if ($self->is_subform && !$self->is_adjusted) {
		$self->set_adjustment(sub { $self->type->fields });
	}
}

sub is_subform
{
	my ($self) = @_;

	return $self->has_type && $self->type->DOES("Form::Tiny::Form");
}

sub get_name_path
{
	my ($self) = @_;

	my $sep = quotemeta $nesting_separator;
	my @parts = split /(?<!\\)$sep/, $self->name;
	return map { s/\\$sep/$nesting_separator/g; $_ } @parts;
}

sub hard_required
{
	my ($self) = @_;

	return $self->required eq "hard" || $self->required eq "1";
}

sub get_coerced
{
	my ($self, $form, $value) = @_;

	my $coerce = $self->coerce;
	my $coerced = $value;

	my $error = try sub {
		if (ref $coerce eq "CODE") {
			$coerced = $coerce->($value);
		}
		elsif ($coerce) {
			$coerced = $self->type->coerce($value);
		}
	};

	if ($error) {
		$form->add_error(
			Form::Tiny::Error::DoesNotValidate->new(
				{
					field => $self->name,
					error => $self->has_message ? $self->message : $error,
				}
			)
		);
	}

	return $coerced;
}

sub get_adjusted
{
	my ($self, $value) = @_;

	if ($self->is_adjusted) {
		return $self->adjust->($value);
	}
	return $value;
}

sub get_default
{
	my ($self, $form) = @_;

	if ($self->has_default) {
		my $default = $self->default->($form);
		if (!$self->has_type || $self->type->check($default)) {
			return Form::Tiny::PathValue->new(
				path => [$self->get_name_path],
				value => $default,
			);
		}

		croak 'invalid default value was set';
	}

	croak 'no default value set but was requested';
}

sub validate
{
	my ($self, $form, $value) = @_;

	# no validation if no type specified
	return 1
		if !$self->has_type;

	my $valid;
	my $error;
	if ($self->has_message) {
		$valid = $self->type->check($value);
		$error = $self->message;
	}
	else {
		$error = $self->type->validate($value);
		$valid = !defined $error;
	}

	if (!$valid) {
		if ($self->is_subform && ref $error eq ref []) {
			foreach my $exception (@$error) {
				if (defined blessed $exception && $exception->isa("Form::Tiny::Error")) {
					$exception->set_field(
						join $nesting_separator,
						$self->name, ($exception->field // ())
					);
				}
				else {
					$exception = Form::Tiny::Error::DoesNotValidate->new(
						{
							field => $self->name,
							error => $exception,
						}
					);
				}

				$form->add_error($exception);
			}
		}
		else {
			my $exception = Form::Tiny::Error::DoesNotValidate->new(
				{
					field => $self->name,
					error => $error,
				}
			);

			$form->add_error($exception);
		}
	}

	return $valid;
}

1;

__END__

=head1 NAME

Form::Tiny::FieldDefinition - definition of a field to be validated

=head1 SYNOPSIS

	# you usually don't have to do this by hand, see examples in Form::Tiny::Manual
	# name is the only required attribute
	my $definition = Form::Tiny::FieldDefinition->new(
		name => "something",
		type => Str,
		...
	);

=head1 DESCRIPTION

Main class of the Form::Tiny system - this is a role that provides most of the module's functionality.

=head1 ATTRIBUTES

Each of the attributes can be accessed by calling its name as a function on Form::Tiny::FieldDefinition object. See L<Form::Tiny::Manual> for more in depth examples.

=head2 name

A string which should specify the hash structure path of the field.

Special characters are:

=over

=item * dot [.], which specifies nesting. Can be escaped with backslash [\]

=item * star [*], which specifies any number of array elements, but only if it is the only character on level, like a.*.b

=back

=head2 required

A field is not required by default (value 0), which means that its absence does not produce an error.

A field can also be soft required ("soft") or hard required ("hard" or 1).

Soft required field errors only if it is undefined or not present in the input data.

Hard required field also checks if the field is not an empty string.

=head2 type

A type is where you can plug in a Type::Tiny check. It has to be an instance of a class that provider I<validate> and I<check> methods, just like Type::Tiny. This can also be a different Form::Tiny form instance.

B<predicate:> I<has_type>

=head2 coerce

Coercions take place just before the validation. By default, values are not coerced. Specifying value I<1> will turn on coercions from the type object.

It can also be a code reference which will be called to coerce the value.

=head2 adjust

Adjustments take place just after the validation. By default, values are not adjusted. You can specify a code reference which will be called to adjust the value (change the value after the validation).

B<predicate:> I<is_adjusted>

B<writer:> I<set_adjustment>

=head2 default

A coderef returning the default value for the field. Will be used when the field is not present in the input at all. Making the field hard-required will make the default value be used in place of undefined / empty value as well.

This coderef will be passed form instance as the only argument and is expected to return a scalar value.

B<predicate>: I<has_default>

B<writer>: I<set_default>

=head2 message

If type class error messages are not helpful enough, you can specify your own message string which will be inserted into form errors if the validation for the field fails.

B<predicate:> I<has_message>

=head2 data

Custom data for the field. Can be anything and will not be used by Form::Tiny system itself. It should be anything that will help user's own system use the form instance.

B<writer:> I<set_data>

B<predicate:> I<has_data>

=head1 METHODS

=head2 is_subform

Checks if the field definition's type is a form - mixes in L<Form::Tiny::Form> role.

=head2 get_name_path

Parses and returns the name of the field as an array - a path to get the value in a hash.

=head2 hard_required

Checks if the field is hard-required (any of the two values which are allowed for this flag)

=head2 get_coerced

Coerces and returns a scalar value, according to the definition.

=head2 get_adjusted

Adjusts and returns a scalar value, according to the definition.

=head2 get_default

Returns a L<Form::Tiny::PathValue> object with the default value for this field definition.

=head2 validate

Validates a scalar value. Arguments are C<$parent_form, $field_value>. Returns a boolean, whether the validation passed.
