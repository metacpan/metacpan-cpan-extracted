use strict;
use Test::Exception tests => 1;

use Devel::Assert 'on';
throws_ok{ assert 0 } qr/failed/;
