package FBP::SplitterWindow;

use Mouse;

our $VERSION = '0.41';

extends 'FBP::Window';
with    'FBP::Children';

has style => (
	is  => 'ro',
	isa => 'Str',
);

has splitmode => (
	is       => 'ro',
	isa      => 'Str',
	required => 1,
);

has sashgravity => (
	is       => 'ro',
	isa      => 'Str',
	required => 1,
);

has sashpos => (
	is       => 'ro',
	isa      => 'Str',
	required => 1,
);

has sashsize => (
	is       => 'ro',
	isa      => 'Str',
	required => 1,
);

has min_pane_size => (
	is       => 'ro',
	isa      => 'Str',
	required => 1,
);

has OnSplitterSashPosChanging => (
	is  => 'ro',
	isa => 'Str',
);

has OnSplitterSashPosChanged => (
	is  => 'ro',
	isa => 'Str',
);

has OnSplitterUnsplit => (
	is  => 'ro',
	isa => 'Str',
);

has OnSplitterDClick => (
	is  => 'ro',
	isa => 'Str',
);

no Mouse;
__PACKAGE__->meta->make_immutable;

1;
