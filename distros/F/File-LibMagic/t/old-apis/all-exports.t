use strict;
use warnings;

use lib 't/lib';

use Test::Exports qw( test_complete test_easy );
use Test::More 0.88;

{

    package Test::AllExports;

    use File::LibMagic qw( :all );
}

subtest(
    'complete API exported by :all',
    sub { test_complete('Test::AllExports') }
);

subtest(
    'easy API exported by :all',
    sub { test_easy('Test::AllExports') }
);

done_testing();
