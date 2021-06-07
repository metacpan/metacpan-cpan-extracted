package Form::Tiny::Filter;

use v5.10;
use warnings;
use Moo;
use Types::Standard qw(HasMethods CodeRef Maybe Str);

use namespace::clean;

our $VERSION = '2.01';

has "type" => (
	is => "ro",
	isa => HasMethods ["check"],
	required => 1,
);

has 'field' => (
	is => 'ro',
	isa => Maybe[Str],
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
	my ($self, $value) = @_;

	if ($self->type->check($value)) {
		return $self->code->($value);
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

A string name of a field that should be filtered, or undef if this filter should execute for every field in the form.

=head2 code

A code reference accepting a single scalar and performing the filtering. The scalar will already be checked against the type.

Required.

=head1 METHODS

=head2 check_field

Accepts a single string, which is a name of a field. Returns a boolean value, which determines whether this filter should be used for that field.

=head2 filter

Accepts a single scalar, checks if it matches the type and runs the code reference with it as an argument.

The return value is the scalar value, either changed or unchanged.
