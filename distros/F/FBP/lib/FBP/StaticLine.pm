package FBP::StaticLine;

use Mouse;

our $VERSION = '0.41';

extends 'FBP::Control';

has style => (
	is  => 'ro',
	isa => 'Str',
);

no Mouse;
__PACKAGE__->meta->make_immutable;

1;
