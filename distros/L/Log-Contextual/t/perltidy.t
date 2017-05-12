#!perl

use strict;
use warnings;

use Test::More;

plan skip_all => 'Set TIDY_TESTING if you want to run this test'
  unless $ENV{TIDY_TESTING};

require Test::PerlTidy;

Test::PerlTidy::run_tests(
   path       => '.',
   perltidyrc => '.perltidyrc',
   exclude    => ['.build/'],
);

done_testing;
