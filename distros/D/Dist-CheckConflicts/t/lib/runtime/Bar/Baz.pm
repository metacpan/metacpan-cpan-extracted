package Bar::Baz;
use strict;
use warnings;

use Bar::Baz::Good;
use Bar::Baz::Bad;

our $VERSION = 0.02;

sub contents {
    local $/;
    <DATA>
}

1;

__DATA__
__DATA__ for Bar::Baz
