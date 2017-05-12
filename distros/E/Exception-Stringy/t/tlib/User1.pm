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
User1;

use ExceptionDeclaration;
use Exception::Stringy;

sub test_user1 {
    throw_exception("user1", field1 => 1);
}

1;
