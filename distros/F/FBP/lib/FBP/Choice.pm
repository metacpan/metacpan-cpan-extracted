package FBP::Choice;

use Mouse;

our $VERSION = '0.41';

extends 'FBP::ControlWithItems';

has selection => (
	is       => 'ro',
	isa      => 'Int',
	required => 1,
);

has OnChoice => (
	is       => 'ro',
	isa      => 'Str',
);

no Mouse;
__PACKAGE__->meta->make_immutable;

1;
