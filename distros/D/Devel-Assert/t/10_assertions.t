use strict;
use Test::Exception tests => 4;

package T_one;
use Devel::Assert;
use Test::Exception;

lives_ok{ assert(0) };
lives_ok{ assert(1) };

package T_two;
use Test::Exception;
use Devel::Assert 'on';

lives_ok{ assert(1) };
throws_ok{ assert(0) } qr/failed/;
