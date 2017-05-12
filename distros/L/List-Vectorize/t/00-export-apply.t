use Test::More tests => 5;
use strict;

use_ok("List::Vectorize", qw(:apply));

can_ok("main", "sapply");
can_ok("main", "mapply");
can_ok("main", "tapply");
can_ok("main", "happly");
