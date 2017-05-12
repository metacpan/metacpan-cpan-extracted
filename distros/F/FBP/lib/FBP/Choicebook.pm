package FBP::Choicebook;

use Mouse;

our $VERSION = '0.41';

extends 'FBP::Control';
with    'FBP::Children';

has style => (
	is  => 'ro',
	isa => 'Str',
);

has OnChoicebookPageChanged => (
	is  => 'ro',
	isa => 'Str',
);

has OnChoicebookPageChanging => (
	is  => 'ro',
	isa => 'Str',
);

no Mouse;
__PACKAGE__->meta->make_immutable;

1;
