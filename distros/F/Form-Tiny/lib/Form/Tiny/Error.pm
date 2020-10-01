package Form::Tiny::Error;

use v5.10; use warnings;
use Moo;
use Types::Standard qw(Maybe Str Object ArrayRef InstanceOf);
use Carp qw(confess);

use namespace::clean;

our $VERSION = '1.01';

use overload
	q{""} => "as_string",
	fallback => 1;

has "field" => (
	is => "ro",
	isa => Maybe [Str],
	writer => "set_field",
);

has "error" => (
	is => "ro",
	isa => Str | Object,
	builder => "_default_error",
);

sub _default_error
{
	confess "no error message supplied";
	return "Unknown error";
}

sub as_string
{
	my ($self) = @_;

	my $field = $self->field // "general";
	my $error = $self->error;
	return "$field - $error";
}

# in-place subclasses

{

	package Form::Tiny::Error::InvalidFormat;
	use parent "Form::Tiny::Error";

	sub _default_error
	{
		return "input data has invalid format";
	}
}

{

	package Form::Tiny::Error::DoesNotExist;
	use parent "Form::Tiny::Error";

	sub _default_error
	{
		return "does not exist";
	}
}

{

	package Form::Tiny::Error::IsntStrict;
	use parent "Form::Tiny::Error";

	sub _default_error
	{
		return "does not meet the strictness criteria";
	}
}

{

	package Form::Tiny::Error::DoesNotValidate;
	use parent "Form::Tiny::Error";

	sub _default_error
	{
		return "validation fails";
	}
}

1;

__END__

=head1 NAME

Form::Tiny::Error - form error wrapper

=head1 SYNOPSIS

	my $error = Form::Tiny::Error::DoesNotValidate->new(
		field => "some_field",
		error => "some message"
	);

	my $field = $error->field; # field name or undef
	my $data = $error->error; # error message or nested error object

	my $message = $error->as_string;

=head1 DESCRIPTION

Form errors feature field name which caused validation error, error message and automatic stringification.

The C<< $error->error >> can return a nested error object in case of nested forms.

A couple of in-place subclasses are provided to differentiate the type of error which occured. There are:

=over

=item * Form::Tiny::Error::InvalidFormat

=item * Form::Tiny::Error::DoesNotExist

=item * Form::Tiny::Error::IsntStrict

=item * Form::Tiny::Error::DoesNotValidate

=back
