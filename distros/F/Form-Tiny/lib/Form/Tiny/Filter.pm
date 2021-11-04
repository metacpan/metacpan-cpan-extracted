package Form::Tiny::Filter;

use v5.10;
use strict;
use warnings;
use Moo;
use Types::Standard qw(HasMethods CodeRef Maybe Str);

use namespace::clean;

our $VERSION = '2.03';

has "type" => (
	is => "ro",
	isa => HasMethods ["check"],
	required => 1,
);

has 'field' => (
	is => 'ro',
	isa => Maybe [Str],
	default => sub { undef },
);

has "code" => (
	is => "ro",
	isa => CodeRef,
	required => 1,
);

sub check_field
{
	my ($self, $field) = @_;

	return ($self->field // $field) eq $field;
}

sub filter
{
	my ($self, $value, @params) = @_;

	if ($self->type->check($value)) {
		return $self->code->(@params, $value);
	}

	return $value;
}

1;

__END__

=head1 NAME

Form::Tiny::Filter - a representation of a filter

=head1 SYNOPSIS

	# in your form class

	# the following will be coerced into Form::Tiny::Filter
	form_filer Str, sub { uc shift() };

=head1 DESCRIPTION

This is a simple class which stores a L<Type::Tiny> type and a sub which will perform the filtering.

=head1 ATTRIBUTES

=head2 type

A Type::Tiny type that will be checked against.

Required.

=head2 field

B<DEPRECATED>

A string name of a field that should be filtered, or undef if this filter should execute for every field in the form.

=head2 code

A code reference accepting a single scalar and performing the filtering. The scalar will already be checked against the type.

Required.

=head1 METHODS

=head2 check_field

Accepts a single string, which is a name of a field. Returns a boolean value, which determines whether this filter should be used for that field.

=head2 filter

	$filtered = $filter->filter($filtered, @more_params);

Accepts a single scalar, checks if it matches the type and runs the code reference with it as an argument. Can accept more parameters, which will be inserted before the value in the subroutine call (the value is always the last parameter to the coderef).

The return value is the scalar value, either changed or unchanged.
