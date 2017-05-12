
use strict;
use Test::More tests => 4;

use_ok('lib', 't');

# this script tests "use lib" after "use Devel::Hide"

use_ok('Devel::Hide');
use_ok('lib', 't'); # put 't' before the Devel::Hide hook in @INC

eval { require P }; 
ok(!$@, "P was loaded (as it should)");
