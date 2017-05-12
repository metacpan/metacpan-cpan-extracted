package FBP::ChoicebookPage;

use Mouse;

our $VERSION = '0.41';

extends 'FBP::Object';
with    'FBP::Children';

has label => (
	is  => 'ro',
	isa => 'Str',
);

has select => (
	is  => 'ro',
	isa => 'Int',
);

no Mouse;
__PACKAGE__->meta->make_immutable;

1;
