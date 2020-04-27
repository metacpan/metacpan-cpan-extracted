use strict;
use warnings;

use FindBin qw( $Bin );
use lib "$Bin/../lib";

use Test::Exports qw( test_complete );
use Test::More 0.96;

{

    package Test::Complete;

    use File::LibMagic qw( :complete );
}

test_complete( 'Test::Complete', "$Bin/../samples" );

done_testing();
