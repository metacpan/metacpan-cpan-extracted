package Game::Cribbage::Error;

use strict;
use warnings;

use Rope;
use Rope::Autoload;

property [qw/error message over go/] => (
	value => 1,
	initable => 1,
	writeable => 0,
	configurable => 0,
	enumerable => 1
);

1;
