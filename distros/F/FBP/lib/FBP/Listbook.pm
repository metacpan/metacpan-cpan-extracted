package FBP::Listbook;

use Mouse;

our $VERSION = '0.41';

extends 'FBP::Control';
with    'FBP::Children';

has style => (
	is  => 'ro',
	isa => 'Str',
);

has OnListbookPageChanged => (
	is  => 'ro',
	isa => 'Str',
);

has OnListbookPageChanging => (
	is  => 'ro',
	isa => 'Str',
);

no Mouse;
__PACKAGE__->meta->make_immutable;

1;
