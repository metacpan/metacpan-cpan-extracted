#!perl

use Test::More tests => 11;

use warnings;
use strict;

use JSPL;

# manual destruction/creation
ok( my $rt1 = JSPL::Runtime->new(), "created new runtime" );
ok( my $cx1 = $rt1->create_context(), "created context" );
ok( !undef $rt1 , "destroyed runtime");
ok( !undef $cx1 , "destroyed context");

# automatic destruction/creation
ok( $rt1 = JSPL::Runtime->new(), "created new runtime" );
ok( $cx1 = $rt1->create_context(), "created context" );
ok( my $cx2 = $rt1->create_context(), "created context" );
$cx1 = undef;
ok( my $cx3 = $rt1->create_context(), "created context" );
ok( my $cx4 = $rt1->create_context(), "created context" );
ok( my $cx5 = $rt1->create_context(), "created context" );
$rt1 = undef;

ok( 1, "left scope, hopefully they're gone.");
