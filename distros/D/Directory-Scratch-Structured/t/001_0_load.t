
# test module loading

use strict ;
use warnings ;

use Test::NoWarnings ;

use Test::More qw(no_plan);
use Test::Exception ;

BEGIN { use_ok( 'Directory::Scratch::Structured', qw(create_structured_tree piggyback_directory_scratch) ) or BAIL_OUT("Can't load module"); } ;


