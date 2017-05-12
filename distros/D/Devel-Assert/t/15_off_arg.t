use strict;
use Test::Exception tests => 2;

use Devel::Assert 'global';

package T_one;
use Devel::Assert 'off';
use Test::Exception;

lives_ok{ assert(1) };
lives_ok{ assert(0) };

