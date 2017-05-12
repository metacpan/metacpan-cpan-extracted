package FBP::ListCtrl;

use Mouse;

our $VERSION = '0.41';

extends 'FBP::Control';

has style => (
	is  => 'ro',
	isa => 'Str',
);

has OnListBeginDrag => (
	is  => 'ro',
	isa => 'Str',
);

has OnListBeginRDrag => (
	is  => 'ro',
	isa => 'Str',
);

has OnListBeginLabelEdit => (
	is  => 'ro',
	isa => 'Str',
);

has OnListEndLabelEdit => (
	is  => 'ro',
	isa => 'Str',
);

has OnListDeleteItem => (
	is  => 'ro',
	isa => 'Str',
);

has OnListDeleteAllItems => (
	is  => 'ro',
	isa => 'Str',
);

has OnListItemSelected => (
	is  => 'ro',
	isa => 'Str',
);

has OnListItemDeselected => (
	is  => 'ro',
	isa => 'Str',
);

has OnListItemActivated => (
	is  => 'ro',
	isa => 'Str',
);

has OnListItemFocused => (
	is  => 'ro',
	isa => 'Str',
);

has OnListItemMiddleClick => (
	is  => 'ro',
	isa => 'Str',
);

has OnListItemRightClick => (
	is  => 'ro',
	isa => 'Str',
);

has OnListKeyDown => (
	is  => 'ro',
	isa => 'Str',
);

has OnListInsertItem => (
	is  => 'ro',
	isa => 'Str',
);

has OnListColClick => (
	is  => 'ro',
	isa => 'Str',
);

has OnListColRightClick => (
	is  => 'ro',
	isa => 'Str',
);

has OnListColBeginDrag => (
	is  => 'ro',
	isa => 'Str',
);

has OnListColDragging => (
	is  => 'ro',
	isa => 'Str',
);

has OnListColEndDrag => (
	is  => 'ro',
	isa => 'Str',
);

has OnListCacheHint => (
	is  => 'ro',
	isa => 'Str',
);

no Mouse;
__PACKAGE__->meta->make_immutable;

1;
