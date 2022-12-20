package Form::Tiny::Plugin::Filtered::Filter;
$Form::Tiny::Plugin::Filtered::Filter::VERSION = '2.16';
use v5.10;
use strict;
use warnings;
use Moo;
use Types::Standard qw(HasMethods CodeRef);

has 'type' => (
	is => 'ro',
	isa => HasMethods ['check'],
	required => 1,
);

has 'code' => (
	is => 'ro',
	isa => CodeRef,
	required => 1,
);

sub filter
{
	my ($self, $obj, $value) = @_;

	if ($self->type->check($value)) {
		return $self->code->($obj, $value);
	}

	return $value;
}

1;

