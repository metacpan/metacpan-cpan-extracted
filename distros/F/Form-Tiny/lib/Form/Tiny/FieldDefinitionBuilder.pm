package Form::Tiny::FieldDefinitionBuilder;

use v5.10;
use warnings;
use Moo;
use Carp qw(croak);
use Scalar::Util qw(blessed);

use Form::Tiny::FieldDefinition;

use namespace::clean;

our $VERSION = '2.01';

has "data" => (
	is => "ro",
	required => 1,
);

sub build
{
	my ($self, $context) = @_;

	my $data = $self->data;
	my $dynamic = ref $data eq 'CODE';
	if ($dynamic && defined blessed $context) {
		croak 'building a dynamic field definition requires Form::Tiny::Form object'
			unless $context->DOES('Form::Tiny::Form');
		$data = $data->($context);
		$dynamic = 0;
	}

	return $self if $dynamic;

	if (defined blessed $data && $data->isa('Form::Tiny::FieldDefinition')) {
		return $data;
	}
	elsif (ref $data eq 'HASH') {
		return Form::Tiny::FieldDefinition->new($data);
	}
	else {
		croak sprintf 'Invalid form field "%s" data: must be hashref or instance of Form::Tiny::FieldDefinition',
			$self->name;
	}
}

1;
