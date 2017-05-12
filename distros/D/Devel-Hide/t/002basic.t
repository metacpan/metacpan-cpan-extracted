
use strict;
use Test::More tests => 5;

use_ok('lib', 't');

# this script tests the standard use statement

use_ok('Devel::Hide', 'Q.pm', 'R');

eval { require P }; 
ok(!$@, "P was loaded (as it should)");

eval { require Q }; 
like($@, qr/^Can't locate Q\.pm/, "Q not found (as it should)");

eval { require R }; 
like($@, qr/^Can't locate R\.pm/, "R not found (as it should)");
