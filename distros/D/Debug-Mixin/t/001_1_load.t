
# test module loading

use strict ;
use warnings ;

use Test::More qw(no_plan);
use Test::Exception ;

BEGIN { use_ok( 'Debug::Mixin' ); } ;
