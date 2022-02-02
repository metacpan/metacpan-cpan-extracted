package Form::Tiny::Error;

use v5.10;
use strict;
use warnings;
use Moo;
use Types::Standard qw(Maybe Str);
use Types::TypeTiny qw(StringLike);
use Carp qw(confess);

use namespace::clean;

our $VERSION = '2.09';

use overload
	q{""} => 'as_string',
	fallback => 1;

has 'field' => (
	is => 'ro',
	isa => Maybe [Str],
	writer => 'set_field',
	default => sub { undef },
);

has 'error' => (
	is => 'ro',
	isa => StringLike,
	writer => 'set_error',
	builder => 'default_error',
);

sub default_error
{
	confess 'no error message supplied';
	return 'Unknown error';
}

sub as_string
{
	my ($self) = @_;

	my $field = $self->field // 'general';
	my $error = $self->error;
	return "$field - $error";
}

# in-place subclasses
{

	# Internal use only
	package Form::Tiny::Error::NestedFormError;
	use parent -norequire, 'Form::Tiny::Error';

}

{

	package Form::Tiny::Error::InvalidFormat;
	use parent -norequire, 'Form::Tiny::Error';

	sub default_error
	{
		return 'input data format is invalid';
	}
}

{

	package Form::Tiny::Error::Required;
	use parent -norequire, 'Form::Tiny::Error';

	sub default_error
	{
		return 'field is required';
	}
}

{

	package Form::Tiny::Error::IsntStrict;
	use parent -norequire, 'Form::Tiny::Error';

	sub default_error
	{
		return 'input data has unexpected fields';
	}
}

{

	package Form::Tiny::Error::DoesNotValidate;
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
		field => 'some_field',
		error => 'some message'
	);

	my $field = $error->field; # field name or undef
	my $data = $error->error; # error message or nested error object

	# concatenated error message: "$field - $data"
	my $message = $error->as_string;

	# change error message
	$error->set_error('new_message');

=head1 DESCRIPTION

The form errors class features field name which caused validation error, error message and automatic stringification.

The C<< $error->error >> can return a nested error object in case of nested forms.

A couple of in-place subclasses are provided to differentiate the type of error which occured. These are:

=over

=item * Form::Tiny::Error::InvalidFormat

=item * Form::Tiny::Error::Required

=item * Form::Tiny::Error::IsntStrict

=item * Form::Tiny::Error::DoesNotValidate

=back
