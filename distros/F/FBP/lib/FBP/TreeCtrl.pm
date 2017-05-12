package FBP::TreeCtrl;

use Mouse;

our $VERSION = '0.41';

extends 'FBP::Control';
with    'FBP::TreeCtrlBase';

has style => (
	is  => 'ro',
	isa => 'Str',
);

has OnTreeGetInfo => (
	is  => 'ro',
	isa => 'Str',
);

has OnTreeSetInfo => (
	is  => 'ro',
	isa => 'Str',
);

has OnTreeItemGetTooltip => (
	is  => 'ro',
	isa => 'Str',
);

has OnTreeStateImageClick => (
	is  => 'ro',
	isa => 'Str',
);

no Mouse;
__PACKAGE__->meta->make_immutable;

1;
