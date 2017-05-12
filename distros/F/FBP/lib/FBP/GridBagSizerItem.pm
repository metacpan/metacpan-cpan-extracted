package FBP::GridBagSizerItem;

use Mouse;

our $VERSION = '0.41';

extends 'FBP::Object';
with    'FBP::Children';
with    'FBP::SizerItemBase';

has row => (
	is  => 'ro',
	isa => 'Int',
);

has column => (
	is  => 'ro',
	isa => 'Int',
);

has rowspan => (
	is  => 'ro',
	isa => 'Int',
);

has colspan => (
	is  => 'ro',
	isa => 'Int',
);

no Mouse;
__PACKAGE__->meta->make_immutable;

1;
