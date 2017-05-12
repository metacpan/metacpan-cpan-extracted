#!/usr/bin/perl

use strict;

foreach (@ARGV) {
  $ENV{MASON_NO_CLEANUP} = 1;
  my @command = (-e 'Build' ?
                 ('Build', 'test', "test_files=$_", 'verbose=1') :
                 ('make', 'test', "TEST_FILES=$_", 'TEST_VERBOSE=1')
                );
  print "@command\n";
  system @command;
}
