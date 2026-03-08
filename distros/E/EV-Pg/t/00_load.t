use strict;
use warnings;
use Test::More tests => 3;

use_ok('EV::Pg');

ok(EV::Pg->lib_version > 0, 'lib_version returns positive number');

# Constants are importable
use EV::Pg qw(:status);
ok(PGRES_COMMAND_OK == 1, 'PGRES_COMMAND_OK constant');
