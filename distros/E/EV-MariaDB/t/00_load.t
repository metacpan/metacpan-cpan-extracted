use strict;
use warnings;
use Test::More tests => 4;

use_ok('EV::MariaDB');

ok(EV::MariaDB->lib_version > 0, 'lib_version returns positive number');
ok(EV::MariaDB->lib_version < 1_000_000, 'lib_version under 1M (sanity bound)');
ok(length(EV::MariaDB->lib_info) > 0, 'lib_info returns non-empty string');
