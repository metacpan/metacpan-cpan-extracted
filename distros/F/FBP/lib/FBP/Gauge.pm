package FBP::Gauge;

use Mouse;

our $VERSION = '0.41';

extends 'FBP::Control';





######################################################################
# Properties

has value => (
	is       => 'ro',
	isa      => 'Int',
);

has range => (
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
