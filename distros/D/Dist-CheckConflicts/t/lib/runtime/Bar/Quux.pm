package Bar::Quux;
use strict;
use warnings;

use Bar::Quux::Good;
use Bar::Quux::Bad;

our $VERSION = 0.02;

sub contents {
    local $/;
    <DATA>
}

1;

__DATA__
__DATA__ for Bar::Quux
