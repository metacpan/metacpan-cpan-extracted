package FBP::HyperlinkCtrl;

use Mouse;

our $VERSION = '0.41';

extends 'FBP::Control';

has label => (
	is       => 'ro',
	isa      => 'Str',
);

has url => (
	is       => 'ro',
	isa      => 'Str',
);

has hover_color => (
	is       => 'ro',
	isa      => 'Str',
);

has normal_color => (
	is       => 'ro',
	isa      => 'Str',
);

has visited_color => (
	is       => 'ro',
	isa      => 'Str',
);

has style => (
	is       => 'ro',
	isa      => 'Str',
);

has OnHyperlink => (
	is  => 'ro',
	isa => 'Str',
);

no Mouse;
__PACKAGE__->meta->make_immutable;

1;
