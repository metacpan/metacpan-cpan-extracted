package Form::Tiny::Filtered;

use v5.10;
use warnings;
use Types::Standard qw(Str ArrayRef InstanceOf);

use Form::Tiny::Filter;
use Moo::Role;

our $VERSION = '1.12';

requires qw(pre_mangle _clear_form);

has "filters" => (
	is => "ro",
	isa => ArrayRef [
		(InstanceOf ["Form::Tiny::Filter"])
		->plus_coercions(ArrayRef, q{ Form::Tiny::Filter->new($_) })
	],
	coerce => 1,
	default => sub {
		[shift->build_filters]
	},
	trigger => sub { shift->_clear_form },
	writer => "set_filters",
);

sub trim
{
	my ($self, $value) = @_;
	$value =~ s/\A\s+//;
	$value =~ s/\s+\z//;

	return $value;
}

sub build_filters
{
	my ($self) = @_;

	return (
		[Str, sub { $self->trim(@_) }],
	);
}

sub _apply_filters
{
	my ($self, $value) = @_;

	for my $filter (@{$self->filters}) {
		$value = $filter->filter($value);
	}

	return $value;
}

around "pre_mangle" => sub {
	my ($orig, $self, $def, $value) = @_;

	$value = $self->_apply_filters($value);
	return $self->$orig($def, $value);
};

1;

__END__

=head1 NAME

Form::Tiny::Filtered - early filtering for form fields

=head1 SYNOPSIS

	# in your form class
	with qw(Form::Tiny Form::Tiny::Filtered);

	# optional - only trims string by default
	sub build_filters
	{
		return (
			[Int, sub { abs shift() }],
		);
	}

=head1 DESCRIPTION

This class is a role which is meant to be mixed in together with L<Form::Tiny> role. Having the filtered role enriches Form::Tiny by adding a filtering mechanism which can change the field value before it gets validated.

The filtering system is designed to perform a type check on field values and only apply a filtering subroutine when the type matches.

By default, adding this role to a class will cause all string to be filtered with C<< Form::Tiny::Filtered->trim >>. Specifying the I<build_filters> method explicitly will override that behavior.

=head1 ADDED INTERFACE

=head2 ATTRIBUTES

=head3 filters

Stores an array reference of L<Form::Tiny::Filter> objects, which are used during filtering.

B<writer:> I<set_filters>

=head2 METHODS

=head3 trim

Built in trim functionality, to avoid dependencies. Returns its only argument trimmed.

=head3 build_filters

Just like build_fields, this method should return an array of elements.

Each of these elements should be an instance of Form::Tiny::Filter or an array reference, in which the first element is the type and the second element is the filtering code reference.
