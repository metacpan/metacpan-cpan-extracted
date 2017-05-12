package FBP::GridSizer;

use Mouse;

our $VERSION = '0.41';

extends 'FBP::Sizer';

has rows => (
	is       => 'ro',
	isa      => 'Int',
	required => 1,
);

has cols => (
	is       => 'ro',
	isa      => 'Int',
	required => 1,
);

has vgap => (
	is       => 'ro',
	isa      => 'Int',
	required => 1,
);

has hgap => (
	is       => 'ro',
	isa      => 'Int',
	required => 1,
);

no Mouse;
__PACKAGE__->meta->make_immutable;

1;
