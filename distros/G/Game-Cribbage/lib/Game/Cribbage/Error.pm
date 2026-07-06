package Game::Cribbage::Error;

use strict;
use warnings;

use Object::Proto::Sugar;

has [qw/error message over go score/] => (
	is => 'ro',
);

1;
