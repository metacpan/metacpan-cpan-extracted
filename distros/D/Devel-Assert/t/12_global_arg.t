use strict;
use Test::Exception tests => 5;

use Devel::Assert 'global';

package T_one;
use Devel::Assert;
use Test::Exception;

lives_ok{ assert(log(12)) };
throws_ok{ assert(0) } qr/failed/;

package T_two;
use Devel::Assert;
use Test::Exception;

lives_ok{ assert(1) };
throws_ok{ eval 'assert(0); 1' or die $@ } qr/failed/;
throws_ok{ assert(0) } qr/failed/;

