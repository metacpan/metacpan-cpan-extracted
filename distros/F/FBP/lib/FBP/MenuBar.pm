package FBP::MenuBar;

use Mouse;

our $VERSION = '0.41';

extends 'FBP::Window';
with    'FBP::Children';

has label => (
	is       => 'ro',
	isa      => 'Str',
	required => 1,
	default  => '',
);

has style => (
	is       => 'ro',
	isa      => 'Str',
);

no Mouse;
__PACKAGE__->meta->make_immutable;

1;
