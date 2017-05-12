
use strict;
use warnings;

use Test::More;

use lib './lib';

if ( !( $ENV{RELEASE_TESTING} || $ENV{AUTHOR_TESTING} || $ENV{AUTHOR_TESTS} ) )
{
   plan skip_all => 'these tests are for testing by the author';
}
else
{
  plan skip_all => 'Test::Portability::Files needed'
     and last unless eval 'use Test::Portability::Files; 1';
}

options
(
   test_dos_length   => 0,
   test_amiga_length => 0,
   test_vms_length   => 0,
   test_one_dot      => 0,
);

run_tests();

exit;
