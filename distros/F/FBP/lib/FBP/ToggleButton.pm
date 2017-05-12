package FBP::ToggleButton;

use Mouse;

our $VERSION = '0.41';

extends 'FBP::Control';

has label => (
	is  => 'ro',
	isa => 'Str',
);

has value => (
	is  => 'ro',
	isa => 'Bool',
);

has OnToggleButton => (
	is  => 'ro',
	isa => 'Str',
);

no Mouse;
__PACKAGE__->meta->make_immutable;

1;
