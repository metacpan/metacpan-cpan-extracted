use Test::More tests => 5;
use strict;

use_ok("List::Vectorize", qw(:io));

can_ok("main", "print_ref");
can_ok("main", "print_matrix");
can_ok("main", "read_table");
can_ok("main", "write_table");
