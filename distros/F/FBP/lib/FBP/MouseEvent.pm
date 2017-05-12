package FBP::MouseEvent;

use Mouse::Role;

our $VERSION = '0.41';

has OnEnterWindow => (
	is  => 'ro',
	isa => 'Str',
);

has OnLeaveWindow => (
	is  => 'ro',
	isa => 'Str',
);

has OnLeftDClick => (
	is  => 'ro',
	isa => 'Str',
);

has OnLeftDown => (
	is  => 'ro',
	isa => 'Str',
);

has OnLeftUp => (
	is  => 'ro',
	isa => 'Str',
);

has OnMiddleDClick => (
	is  => 'ro',
	isa => 'Str',
);

has OnMiddleDown => (
	is  => 'ro',
	isa => 'Str',
);

has OnMiddleUp => (
	is  => 'ro',
	isa => 'Str',
);

has OnMotion => (
	is  => 'ro',
	isa => 'Str',
);

has OnMouseEvents => (
	is  => 'ro',
	isa => 'Str',
);

has OnMouseWheel => (
	is  => 'ro',
	isa => 'Str',
);

has OnRightDClick => (
	is  => 'ro',
	isa => 'Str',
);

has OnRightDown => (
	is  => 'ro',
	isa => 'Str',
);

has OnRightUp => (
	is  => 'ro',
	isa => 'Str',
);

no Mouse::Role;

1;
