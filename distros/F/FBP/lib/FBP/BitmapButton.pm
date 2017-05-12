package FBP::BitmapButton;

use Mouse;

our $VERSION = '0.41';

extends 'FBP::Control';

has style => (
	is  => 'ro',
	isa => 'Str',
);

has bitmap => (
	is  => 'ro',
	isa => 'Str',
);

has disabled => (
	is  => 'ro',
	isa => 'Str',
);

has selected => (
	is  => 'ro',
	isa => 'Str',
);

has focus => (
	is  => 'ro',
	isa => 'Str',
);

has hover => (
	is  => 'ro',
	isa => 'Str',
);

has OnButtonClick => (
	is  => 'ro',
	isa => 'Str',
);

no Mouse;
__PACKAGE__->meta->make_immutable;

1;
