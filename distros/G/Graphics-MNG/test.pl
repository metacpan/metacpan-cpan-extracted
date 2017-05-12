#!perl 
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

use strict;
use Test::Harness;

# $Test::Harness::verbose=1;
warn "Support files are not created by default.\n".
     "If you want to generate new PNG and reference files,\n".
     "edit test.pl and change '1..6' to '0..6',\n".
     "or type 'perl -Mblib -w t/t0.pl'\n";
my @test_files = map { "t/t$_.pl" } ( 1..6 );
my $allok = runtests(@test_files);
exit(0);

