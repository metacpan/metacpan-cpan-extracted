#
# This file is part of Exception-Stringy
#
# This software is Copyright (c) 2014 by Damien Krotkine.
#
# This is free software, licensed under:
#
#   The Artistic License 2.0 (GPL Compatible)
#
package # hide from CPAN
User2;

use ExceptionDeclaration;
use Exception::Stringy;

sub test_user2 {
    throw_exception("user2", field2 => 1);
}

1;
