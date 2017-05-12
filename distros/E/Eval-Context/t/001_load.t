
# test module loading

use strict ;
use warnings ;

use Test::NoWarnings ;

use Test::More qw(no_plan);
use Test::Exception ;

BEGIN { use_ok( 'Eval::Context' ) or BAIL_OUT("Can't load module"); } ;

my $object = new Eval::Context ;

is(defined $object, 1, 'default constructor') ;
isa_ok($object, 'Eval::Context');

my $new_config = $object->new() ;
is(defined $new_config, 1, 'constructed from object') ;
isa_ok($new_config , 'Eval::Context');


dies_ok
	{
	Eval::Context::new () ;
	} "invalid constructor" ;
