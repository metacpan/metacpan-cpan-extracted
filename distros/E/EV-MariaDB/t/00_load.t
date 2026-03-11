use strict;
use warnings;
use Test::More tests => 2;

use_ok('EV::MariaDB');

ok(EV::MariaDB->lib_version > 0, 'lib_version returns positive number');
