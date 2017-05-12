package FBP::Tool;

use Mouse;

our $VERSION = '0.41';

extends 'FBP::Object';

has id => (
	is  => 'ro',
	isa => 'Str',
);

has name => (
	is  => 'ro',
	isa => 'Str',
);

has label => (
	is  => 'ro',
	isa => 'Str',
);

has bitmap => (
	is  => 'ro',
	isa => 'Str',
);

has kind => (
	is  => 'ro',
	isa => 'Str',
);

has tooltip => (
	is  => 'ro',
	isa => 'Str',
);

has statusbar => (
	is  => 'ro',
	isa => 'Str',
);

has OnToolClicked => (
	is  => 'ro',
	isa => 'Str',
);

has OnMenuSelection => (
	is  => 'ro',
	isa => 'Str',
);

has OnToolRClicked => (
	is  => 'ro',
	isa => 'Str',
);

has OnToolEnter => (
	is  => 'ro',
	isa => 'Str',
);

has OnUpdateUI => (
	is  => 'ro',
	isa => 'Str',
);

no Mouse;
__PACKAGE__->meta->make_immutable;

1;
