package FBP::TreeCtrlBase;

use Mouse::Role;

our $VERSION = '0.41';

has OnTreeBeginDrag => (
	is  => 'ro',
	isa => 'Str',
);

has OnTreeBeginRDrag => (
	is  => 'ro',
	isa => 'Str',
);

has OnTreeEndDrag => (
	is  => 'ro',
	isa => 'Str',
);

has OnTreeBeginLabelEdit => (
	is  => 'ro',
	isa => 'Str',
);

has OnTreeEndLabelEdit => (
	is  => 'ro',
	isa => 'Str',
);

has OnTreeDeleteItem => (
	is  => 'ro',
	isa => 'Str',
);

has OnTreeItemActivated => (
	is  => 'ro',
	isa => 'Str',
);

has OnTreeItemCollapsed => (
	is  => 'ro',
	isa => 'Str',
);

has OnTreeItemCollapsing => (
	is  => 'ro',
	isa => 'Str',
);

has OnTreeItemExpanded => (
	is  => 'ro',
	isa => 'Str',
);

has OnTreeItemExpanding => (
	is  => 'ro',
	isa => 'Str',
);

has OnTreeItemRightClick => (
	is  => 'ro',
	isa => 'Str',
);

has OnTreeItemMiddleClick => (
	is  => 'ro',
	isa => 'Str',
);

has OnTreeSelChanged => (
	is  => 'ro',
	isa => 'Str',
);

has OnTreeSelChanging => (
	is  => 'ro',
	isa => 'Str',
);

has OnTreeKeyDown => (
	is  => 'ro',
	isa => 'Str',
);

has OnTreeItemMenu => (
	is  => 'ro',
	isa => 'Str',
);

no Mouse::Role;

1;
