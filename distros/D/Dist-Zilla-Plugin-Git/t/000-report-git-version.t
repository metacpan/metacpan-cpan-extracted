use strict;
use warnings;

use Test::More tests => 1;

diag(`git --version`);
ok(1);
