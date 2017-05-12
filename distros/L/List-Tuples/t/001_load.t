
# test module loading

use strict ;
use warnings ;

use Test::NoWarnings ;

use Test::More qw(no_plan);
use Test::Exception ;

BEGIN { use_ok( 'List::Tuples' ) or BAIL_OUT("Can't load module"); } ;

