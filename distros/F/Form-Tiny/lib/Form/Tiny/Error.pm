package Form::Tiny::Error;
$Form::Tiny::Error::VERSION = '2.26';
use v5.10;
use strict;
use warnings;
use Moo;
use Types::Standard qw(Maybe Str InstanceOf);
use Types::TypeTiny qw(StringLike);
use Carp qw(confess);

use overload
	q{""} => 'as_string',
	fallback => 1;

has 'field_def' => (
	is => 'ro',
	isa => InstanceOf['Form::Tiny::FieldDefinition'],
	writer => 'set_field_def',
	predicate => 'has_field_def',
);

has 'field' => (
	is => 'ro',
	isa => Str,
	writer => 'set_field',
	predicate => 'has_field',
);

has 'error' => (
	is => 'ro',
	isa => StringLike,
	writer => 'set_error',
	builder => 'default_error',
);

sub BUILD
{
	my ($self) = @_;

	if (!$self->field && $self->field_def) {
		$self->set_field($self->field_def->name);
	}
}

sub default_error
{
	confess 'no error message supplied';
	return 'Unknown error';
}

sub get_error
{
	my ($self) = @_;

	return $self->error;
}

sub as_string
{
	my ($self) = @_;

	my $field = $self->field // 'general';
	my $error = $self->get_error;
	return "$field - $error";
}

# in-place subclasses
{

	# Internal use only
	package Form::Tiny::Error::NestedFormError;
$Form::Tiny::Error::NestedFormError::VERSION = '2.26';
use parent -norequire, 'Form::Tiny::Error';

}

{

	package Form::Tiny::Error::InvalidFormat;
$Form::Tiny::Error::InvalidFormat::VERSION = '2.26';
use parent -norequire, 'Form::Tiny::Error';

	sub default_error
	{
		return 'input data format is invalid';
	}
}

{

	package Form::Tiny::Error::Required;
$Form::Tiny::Error::Required::VERSION = '2.26';
use parent -norequire, 'Form::Tiny::Error';

	sub default_error
	{
		return 'field is required';
	}
}

{

	package Form::Tiny::Error::IsntStrict;
$Form::Tiny::Error::IsntStrict::VERSION = '2.26';
use Moo;
	use Types::Standard qw(Str);

	extends 'Form::Tiny::Error';

	has 'extra_field' => (
		is => 'ro',
		isa => Str,
		required => 1,
	);

	sub default_error
	{
		return 'input data has unexpected fields';
	}

	sub get_error
	{
		my ($self) = @_;

		my $field = $self->extra_field;
		my $error = $self->error;
		return "$field: $error";
	}
}

{

	package Form::Tiny::Error::DoesNotValidate;
$Form::Tiny::Error::DoesNotValidate::VERSION = '2.26';
use parent -norequire, 'Form::Tiny::Error';

	sub default_error
	{
		return 'data validation failed';
	}
}

1;

__END__

=head1 NAME

Form::Tiny::Error - form error wrapper

=head1 SYNOPSIS

	my $error = Form::Tiny::Error::DoesNotValidate->new(
		field_def => $field_def_obj,
		error => 'some message'
	);

	my $field_def = $error->field_def; # field definition object or undef
	my $field = $error->field; # field name or undef
	my $data = $error->get_error; # error message or nested error object

	# concatenated error message: "$field - $data"
	my $message = $error->as_string;

	# change error message
	$error->set_error('new_message');

=head1 DESCRIPTION

The form errors class features field name which caused validation error, error
message and automatic stringification.

The C<< $error->get_error >> can return a nested error object in case of nested
forms.

A couple of in-place subclasses are provided to differentiate the type of error
which occured. These are:

=over

=item * Form::Tiny::Error::InvalidFormat

=item * Form::Tiny::Error::Required

=item * Form::Tiny::Error::IsntStrict

=item * Form::Tiny::Error::DoesNotValidate

=back

=head1 ATTRIBUTES

=head2 field_def

The definition of a field which had the error - an instance of L<Form::Tiny::FieldDefinition>.

B<writer> I<set_field_def>

B<predicate:> I<has_field_def>

=head2 field

Name of the field with the error. May be a label or something user-readable.
Will be pulled from L</field_def> if not passed.

B<writer> I<set_field>

B<predicate:> I<has_field>

=head2 error

The error string.

B<writer> I<set_error>

