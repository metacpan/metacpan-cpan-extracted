use Test::More tests => 25;
use strict;

use_ok("List::Vectorize", qw(:stat));

can_ok("main", "sign");
can_ok("main", "sum");
can_ok("main", "mean");
can_ok("main", "geometric_mean");
can_ok("main", "sd");
can_ok("main", "var");
can_ok("main", "cov");
can_ok("main", "cor");
can_ok("main", "dist");
can_ok("main", "freq");
can_ok("main", "table");
can_ok("main", "scale");
can_ok("main", "sample");
can_ok("main", "rnorm");
can_ok("main", "rbinom");
can_ok("main", "max");
can_ok("main", "min");
can_ok("main", "which_max");
can_ok("main", "which_min");
can_ok("main", "median");
can_ok("main", "quantile");
can_ok("main", "iqr");
can_ok("main", "cumf");
can_ok("main", "abs");
