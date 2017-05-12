package FBP::StatusBar;

use Mouse;

our $VERSION = '0.41';

extends 'FBP::Window';





######################################################################
# Properties

has fields => (
	is       => 'ro',
	isa      => 'Int',
);

has style => (
	is       => 'ro',
	isa      => 'Str',
);

no Mouse;
__PACKAGE__->meta->make_immutable;

1;
