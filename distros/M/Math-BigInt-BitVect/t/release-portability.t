#!perl

BEGIN {
    unless ($ENV{RELEASE_TESTING}) {
        print "1..0 # SKIP these tests are for release candidate testing";
        exit;
    }
}

use strict;
use warnings;

use Test::More;

eval 'use Test::Portability::Files';

plan skip_all => 'Test::Portability::Files required for testing portability'
  if $@;

options(
        use_file_find       => 0,
        test_amiga_length   => 0,
        test_ansi_chars     => 1,
        test_case           => 1,
        test_dos_length     => 0,
        test_mac_length     => 0,
        test_one_dot        => 1,
        test_space          => 1,
        test_special_chars  => 1,
        test_symlink        => 1,
        test_vms_length     => 0,
        windows_reserved    => 1,
       );

run_tests();
