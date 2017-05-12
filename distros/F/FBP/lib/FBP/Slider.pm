package FBP::Slider;

use Mouse;

our $VERSION = '0.41';

extends 'FBP::Control';

has value => (
	is  => 'ro',
	isa => 'Int',
);

has minValue => (
	is  => 'ro',
	isa => 'Int',
);

has maxValue => (
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

has OnCommand => (
	is  => 'ro',
	isa => 'Str',
);

has OnCommandTop => (
	is  => 'ro',
	isa => 'Str',
);

has OnCommandBottom => (
	is  => 'ro',
	isa => 'Str',
);

has OnCommandLineUp => (
	is  => 'ro',
	isa => 'Str',
);

has OnCommandLineDown => (
	is  => 'ro',
	isa => 'Str',
);

has OnCommandPageUp => (
	is  => 'ro',
	isa => 'Str',
);

has OnCommandPageDown => (
	is  => 'ro',
	isa => 'Str',
);

has OnCommandThumbTrack => (
	is  => 'ro',
	isa => 'Str',
);

has OnCommandThumbRelease => (
	is  => 'ro',
	isa => 'Str',
);

has OnCommandChanged => (
	is  => 'ro',
	isa => 'Str',
);

no Mouse;
__PACKAGE__->meta->make_immutable;

1;
