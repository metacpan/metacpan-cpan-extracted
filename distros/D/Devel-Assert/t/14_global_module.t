use strict;
use Test::Exception tests => 7;

use Devel::Assert::Global;
use Test::Exception;

lives_ok{ assert(1) };
throws_ok{ assert(0) } qr/failed/;

package T_two;
use Devel::Assert;
use Test::Exception;

lives_ok{ assert(1) };
no Devel::Assert;
lives_ok{ assert(1) };
throws_ok{ eval 'assert(0); 1' or die $@ } qr/failed/;
throws_ok{ assert(0) } qr/failed/;
use Devel::Assert;
throws_ok{ assert(0) } qr/failed/;
