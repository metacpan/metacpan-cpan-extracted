
# test module loading

use strict ;
use warnings ;

use Test::NoWarnings ;

use Test::More qw(no_plan);
use Test::Exception ;
use Test::Block qw($Plan);

BEGIN { use_ok( 'Directory::Scratch::Structured' ) or BAIL_OUT("Can't load module"); } ;

{
local $Plan = {'piggyback' => 1} ;

my $object = new Directory::Scratch ;

ok(! UNIVERSAL::can($object, 'create_structured_tree'), "no piggybacking by default") ;
}
