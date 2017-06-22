use strict;
use Test::More 0.98;

BEGIN { 
  $List::Flat::NO_REF_UTIL = 1;
}

use List::Flat(qw/flat flat_f flat_r/);

note("Use perl's ref function for checking array references");

require './t/lib/list_flat.pl';

done_testing;
