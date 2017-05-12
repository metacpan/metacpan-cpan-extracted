package FBP::ListBox;

use Mouse;

our $VERSION = '0.41';

extends 'FBP::ControlWithItems';

has style => (
	is  => 'ro',
	isa => 'Str',
);

has OnListBox => (
	is  => 'ro',
	isa => 'Str',
);

has OnListDClick => (
	is  => 'ro',
	isa => 'Str',
);

no Mouse;
__PACKAGE__->meta->make_immutable;

1;
