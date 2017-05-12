package FBP::FlexGridSizerBase;

use Mouse::Role;

our $VERSION = '0.41';

has vgap => (
	is       => 'ro',
	isa      => 'Int',
	required => 1,
);

has hgap => (
	is       => 'ro',
	isa      => 'Int',
	required => 1,
);

has growablerows => (
	is      => 'ro',
	isa     => 'Str',
	default => '',
);

has growablecols => (
	is      => 'ro',
	isa     => 'Str',
	default => '',
);

has flexible_direction => (
	is  => 'ro',
	isa => 'Str',
);

has non_flexible_grow_mode => (
	is  => 'ro',
	isa => 'Str',
);

no Mouse::Role;

1;
