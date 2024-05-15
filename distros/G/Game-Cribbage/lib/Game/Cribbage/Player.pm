package Game::Cribbage::Player;

use strict;
use warnings;

use Rope;
use Rope::Autoload;

property [qw/id name number/] => (
	initable => 1,
	writeable => 0,
	configurable => 0,
	enumerable => 1
);

function player => sub {
	return 'player' . $_[0]->number;
};

# should player have cards here to think.

1;
