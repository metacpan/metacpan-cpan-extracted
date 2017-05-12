package FBP::GenericDirCtrl;

use Mouse;

our $VERSION = '0.41';

extends 'FBP::Control';
with    'FBP::TreeCtrlBase';

has defaultfolder => (
	is  => 'ro',
	isa => 'Str',
);

has filter => (
	is  => 'ro',
	isa => 'Str',
);

has defaultfilter => (
	is  => 'ro',
	isa => 'Str',
);

has show_hidden => (
	is  => 'ro',
	isa => 'Bool',
);

has style => (
	is  => 'ro',
	isa => 'Str',
);

no Mouse;
__PACKAGE__->meta->make_immutable;

1;
