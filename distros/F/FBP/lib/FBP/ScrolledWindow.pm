package FBP::ScrolledWindow;

use Mouse;

our $VERSION = '0.41';

extends 'FBP::Window';
with    'FBP::Children';

has scroll_rate_x => (
	is  => 'ro',
	isa => 'Int',
);

has scroll_rate_y => (
	is  => 'ro',
	isa => 'Int',
);

no Mouse;
__PACKAGE__->meta->make_immutable;

1;
