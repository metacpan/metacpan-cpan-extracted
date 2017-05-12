use strict;
use warnings;

use Gedcom::Date;

use Test::More;

# -------------------

my $gd1 = Gedcom::Date->parse( "10 JUL 2003" );
my $gd2 = Gedcom::Date->parse( "20 JUL 2003" );

ok( $gd1 < $gd2, 'Simple comparison' );

done_testing();
