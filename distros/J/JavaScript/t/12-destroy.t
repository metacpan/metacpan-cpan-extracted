#!perl

use Test::More tests => 7;

use warnings;
use strict;

use JavaScript;

# manual destruction/creation
ok( my $rt1 = JavaScript::Runtime->new(), "created new runtime" );
ok( my $cx1 = $rt1->create_context(), "created context" );
ok( $cx1->_destroy(), "destroyed context");
ok( $rt1->_destroy(), "destroyed runtime");

# automatic destruction/creation
# comment this out for BOUNS! bus error.
{
  ok( my $rt1 = JavaScript::Runtime->new(), "created new runtime" );
  ok( my $cx1 = $rt1->create_context(), "created context" );
}

ok( 1, "left scope, hopefully they're gone.");
