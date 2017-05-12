package Bar::Bar;
use strict;
use warnings;

use Bar::Bar::Good;
use Bar::Bar::Bad;

our $VERSION = 0.01;

sub contents {
    local $/;
    <DATA>
}

1;

__DATA__
__DATA__ for Bar::Bar
