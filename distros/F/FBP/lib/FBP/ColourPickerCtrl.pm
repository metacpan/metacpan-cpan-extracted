package FBP::ColourPickerCtrl;

use Mouse;

our $VERSION = '0.41';

extends 'FBP::Control';

has colour => (
	is  => 'ro',
	isa => 'Str',
);

has style => (
	is  => 'ro',
	isa => 'Str',
);

has OnColourChanged => (
	is  => 'ro',
	isa => 'Str',
);

no Mouse;
__PACKAGE__->meta->make_immutable;

1;
