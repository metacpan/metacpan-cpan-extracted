#!/usr/bin/perl

use strict;
use warnings;

use Test::Most;
use Test::Output;

use lib 't/lib';
use TestClassWithBuild;

my $latin1_test_file = "t/test_data/some_file_latin1.txt";

stdout_is
  {my $t = TestClassWithBuild->new({ file => $latin1_test_file }) }
  $latin1_test_file . "\n",
  "filename available in class' own BUILD";

done_testing;
