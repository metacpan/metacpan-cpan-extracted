use strict;
use warnings;

use lib 't/lib';

use Test::Exports qw( test_easy );
use Test::More 0.96;

{

    package Test::Easy;

    use File::LibMagic qw( :easy );
}

test_easy('Test::Easy');

done_testing();
