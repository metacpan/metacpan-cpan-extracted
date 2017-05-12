package FBP::ScrollBar;

use Mouse;

our $VERSION = '0.41';

extends 'FBP::Control';

has value => (
	is  => 'ro',
	isa => 'Int',
);

has range => (
	is  => 'ro',
	isa => 'Int',
);

has thumbsize => (
	is  => 'ro',
	isa => 'Int',
);

has pagesize => (
	is  => 'ro',
	isa => 'Int',
);

has style => (
	is  => 'ro',
	isa => 'Str',
);

has OnScroll => (
	is  => 'ro',
	isa => 'Str',
);

has OnScrollTop => (
	is  => 'ro',
	isa => 'Str',
);

has OnScrollBottom => (
	is  => 'ro',
	isa => 'Str',
);

has OnScrollLineUp => (
	is  => 'ro',
	isa => 'Str',
);

has OnScrollLineDown => (
	is  => 'ro',
	isa => 'Str',
);

has OnScrollPageUp => (
	is  => 'ro',
	isa => 'Str',
);

has OnScrollPageDown => (
	is  => 'ro',
	isa => 'Str',
);

has OnScrollThumbTrack => (
	is  => 'ro',
	isa => 'Str',
);

has OnScrollThumbRelease => (
	is  => 'ro',
	isa => 'Str',
);

has OnScrollChanged => (
	is  => 'ro',
	isa => 'Str',
);

has OnCommandScroll => (
	is  => 'ro',
	isa => 'Str',
);

has OnCommandScrollTop => (
	is  => 'ro',
	isa => 'Str',
);

has OnCommandScrollBottom => (
	is  => 'ro',
	isa => 'Str',
);

has OnCommandScrollLineUp => (
	is  => 'ro',
	isa => 'Str',
);

has OnCommandScrollLineDown => (
	is  => 'ro',
	isa => 'Str',
);

has OnCommandScrollPageUp => (
	is  => 'ro',
	isa => 'Str',
);

has OnCommandScrollPageDown => (
	is  => 'ro',
	isa => 'Str',
);

has OnCommandScrollThumbTrack => (
	is  => 'ro',
	isa => 'Str',
);

has OnCommandScrollThumbRelease => (
	is  => 'ro',
	isa => 'Str',
);

has OnCommandScrollChanged => (
	is  => 'ro',
	isa => 'Str',
);


no Mouse;
__PACKAGE__->meta->make_immutable;

1;
