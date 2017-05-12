package FBP::FlexGridSizer;

use Mouse;

our $VERSION = '0.41';

extends 'FBP::Sizer';
with    'FBP::FlexGridSizerBase';

has rows => (
	is  => 'ro',
	isa => 'Int',
);

has cols => (
	is  => 'ro',
	isa => 'Int',
);

no Mouse;
__PACKAGE__->meta->make_immutable;

1;
