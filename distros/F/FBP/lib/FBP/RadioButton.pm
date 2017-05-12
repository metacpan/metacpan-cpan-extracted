package FBP::RadioButton;

use Mouse;

our $VERSION = '0.41';

extends 'FBP::Control';

has label => (
	is  => 'ro',
	isa => 'Str',
);

has style => (
	is  => 'ro',
	isa => 'Str',
);

has value => (
	is  => 'ro',
	isa => 'Bool',
);

has OnRadioButton => (
	is  => 'ro',
	isa => 'Str',
);

no Mouse;
__PACKAGE__->meta->make_immutable;

1;
