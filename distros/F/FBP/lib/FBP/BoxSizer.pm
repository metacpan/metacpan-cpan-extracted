package FBP::BoxSizer;

use Mouse;

our $VERSION = '0.41';

extends 'FBP::Sizer';

has orient => (
	is       => 'ro',
	isa      => 'Str',
	required => 1,
);

no Mouse;
__PACKAGE__->meta->make_immutable;

1;
