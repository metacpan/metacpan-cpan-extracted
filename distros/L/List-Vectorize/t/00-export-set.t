use Test::More tests => 6;
use strict;

use_ok("List::Vectorize", qw(:set));

can_ok("main", "intersect");
can_ok("main", "union");
can_ok("main", "setdiff");
can_ok("main", "setequal");
can_ok("main", "is_element");
