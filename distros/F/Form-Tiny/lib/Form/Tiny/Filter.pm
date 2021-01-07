package Form::Tiny::Filter;

use v5.10;
use warnings;
use Moo;
use Types::Standard qw(HasMethods CodeRef);
use Carp qw(croak);

use namespace::clean;

our $VERSION = '1.12';

has "type" => (
	is => "ro",
	isa => HasMethods ["check"],
	required => 1,
);

has "code" => (
	is => "ro",
	isa => CodeRef,
	required => 1,
	writer => "set_code",
);

around "BUILDARGS" => sub {
	my ($orig, $class, @args) = @_;

	croak "Argument to Form::Tiny::Filter->new must be a single arrayref with two elements"
		unless @args == 1 && ref $args[0] eq ref [] && @{$args[0]} == 2;
	return {type => $args[0][0], code => $args[0][1]};
};

sub filter
{
	my ($self, $value) = @_;

	if ($self->type->check($value)) {
		return $self->code->($value);
	}

	return $value;
}

1;

__END__

=head1 NAME

Form::Tiny::Filter - a representation of filtering condition

=head1 SYNOPSIS

	# in your form class
	sub build_filters
	{
		return (
			# the following will be coerced into Form::Tiny::Filter
			# [ type, filtering sub ]
			[Str, sub { uc shift() }],
		);
	}

=head1 DESCRIPTION

This is a simple class which stores a L<Type::Tiny> type and a sub which will perform the filtering.

=head1 ATTRIBUTES

=head2 type

A Type::Tiny type that will be checked against.

Required.

=head2 code

A code reference accepting a single scalar and performing the filtering. The scalar will already be checked against the type.

Required.

=head1 METHODS

=head2 filter

Accepts a single scalar, checks if it matches the type and runs the code reference with it as an argument.

The return value is the scalar value, either changed or unchanged.
