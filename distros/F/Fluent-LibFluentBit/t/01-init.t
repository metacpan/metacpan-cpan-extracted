use strict;
use warnings;
use Test::More;

use_ok( 'Fluent::LibFluentBit' ) or BAIL_OUT;

is( Fluent::LibFluentBit::FLB_LIB_OK(), 'FLB_LIB_OK', 'constants by name' );
is( 0+Fluent::LibFluentBit::FLB_LIB_OK(), 1, 'constants by value' );

ok( my $flb= Fluent::LibFluentBit::flb_create(), 'flb_create' );
local $@;
is( eval { $flb->flb_destroy; 1; }, 1, 'flb_destroy' )
   or diag $@;

done_testing;
