package FBP::SearchCtrl;

use Mouse;

our $VERSION = '0.41';

extends 'FBP::Control';

has value => (
	is       => 'ro',
	isa      => 'Str',
	required => 1,
	default  => '',
);

has style => (
	is       => 'ro',
	isa      => 'Str',
);

has search_button => (
	is       => 'ro',
	isa      => 'Bool',
	required => 1,
	default  => 0,
);

has cancel_button => (
	is       => 'ro',
	isa      => 'Bool',
	required => 1,
	default  => 0,
);

has OnText => (
	is  => 'ro',
	isa => 'Str',
);

has OnTextEnter => (
	is  => 'ro',
	isa => 'Str',
);

has OnSearchButton => (
	is  => 'ro',
	isa => 'Str',
);

has OnCancelButton => (
	is  => 'ro',
	isa => 'Str',
);

no Mouse;
__PACKAGE__->meta->make_immutable;

1;
