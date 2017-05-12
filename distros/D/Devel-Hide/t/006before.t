
use strict;
use Test::More tests => 4;

use_ok('lib', 't');

# this script tests that already loaded modules can't be hidden

use_ok('P'); # loads P
use_ok('Devel::Hide', 'P'); # too late to hide

eval { require P }; 
ok(!$@, "P was loaded (as it should)");
