use strict;
use Test;
BEGIN { plan tests => 1 }

use Dunce::time::Zerofill;

my $t1 = time;
ok(length(time) == 10);

