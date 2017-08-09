package Types;

use strict;
use warnings;
use Dios;

sub import {
    subtype PosInt of Int where { $_ >= 0 }
    subtype ShortStr of Str where { length() < 10 }
}

1;

