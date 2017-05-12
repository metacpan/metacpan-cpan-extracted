package Bar::Foo;
use strict;
use warnings;

use Bar::Foo::Good;
use Bar::Foo::Bad;

our $VERSION = 0.01;

sub contents {
    local $/;
    <DATA>
}

1;

__DATA__
__DATA__ for Bar::Foo
