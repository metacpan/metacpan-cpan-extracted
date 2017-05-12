use strict;
use warnings;

use lib 't/lib';

use Test::Exports qw( test_complete );
use Test::More 0.96;

{

    package Test::Complete;

    use File::LibMagic qw( :complete );
}

test_complete('Test::Complete');

done_testing();
