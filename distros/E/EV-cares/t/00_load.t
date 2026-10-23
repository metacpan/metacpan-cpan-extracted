use strict;
use warnings;
use Test::More tests => 7;

use_ok('EV::cares');

ok(EV::cares::lib_version(), 'lib_version: ' . EV::cares::lib_version());
my @v = split /\./, EV::cares::lib_version();
cmp_ok(($v[0] << 16) | ($v[1] << 8) | $v[2], '>=', 0x012208,
       'linked c-ares supports safe reentrant completion');
is(EV::cares::strerror(0), 'Successful completion', 'strerror ARES_SUCCESS');

use EV::cares qw(:status :types :classes);

is(ARES_SUCCESS, 0, 'ARES_SUCCESS == 0');
is(T_A, 1, 'T_A == 1');
is(C_IN, 1, 'C_IN == 1');
