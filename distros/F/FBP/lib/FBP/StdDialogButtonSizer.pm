package FBP::StdDialogButtonSizer;

use Mouse;

our $VERSION = '0.41';

extends 'FBP::Sizer';

has OK => (
	is  => 'ro',
	isa => 'Bool',
);

has Yes => (
	is  => 'ro',
	isa => 'Bool',
);

has Save => (
	is  => 'ro',
	isa => 'Bool',
);

has Apply => (
	is  => 'ro',
	isa => 'Bool',
);

has No => (
	is  => 'ro',
	isa => 'Bool',
);

has Cancel => (
	is  => 'ro',
	isa => 'Bool',
);

has Help => (
	is  => 'ro',
	isa => 'Bool',
);

has ContextHelp => (
	is  => 'ro',
	isa => 'Bool',
);

has OnOKButtonClick => (
	is  => 'ro',
	isa => 'Str',
);

has OnYesButtonClick => (
	is  => 'ro',
	isa => 'Str',
);

has OnSaveButtonClick => (
	is  => 'ro',
	isa => 'Str',
);

has OnApplyButtonClick => (
	is  => 'ro',
	isa => 'Str',
);

has OnNoButtonClick => (
	is  => 'ro',
	isa => 'Str',
);

has OnCancelButtonClick => (
	is  => 'ro',
	isa => 'Str',
);

has OnHelpButtonClick => (
	is  => 'ro',
	isa => 'Str',
);

has OnContextHelpButtonClick => (
	is  => 'ro',
	isa => 'Str',
);

no Mouse;
__PACKAGE__->meta->make_immutable;

1;
