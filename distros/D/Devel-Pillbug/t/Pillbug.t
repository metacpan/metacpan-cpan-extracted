use strict;
use warnings;

use Test::More qw| no_plan |;

use_ok("Devel::Pillbug");

ok(Devel::Pillbug->new(65432));
