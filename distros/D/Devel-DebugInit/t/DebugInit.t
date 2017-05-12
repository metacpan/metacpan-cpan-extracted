#!/usr/bin/perl -w

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..3\n"; }
END {print "not ok 1\n" unless $loaded;}
# use blib;
use Devel::DebugInit;


$loaded = 1;
print "ok 1\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

use Config;
use strict;
use Carp;
my $g;

$SIG{__WARN__} = sub {confess @_;};

$g = new Devel::DebugInit 
  'filenames' => ["$Config{'archlib'}/CORE/perl.h", 
		  "$Config{'archlib'}/CORE/sv.h",
		  "$Config{'archlib'}/CORE/XSUB.h"],
  'macros_no_args' => "$Devel::DebugInit::MACROS_LOCAL",
  'macros_args' => "$Devel::DebugInit::MACROS_LOCAL";

print "ok 2\n";

eval{ $g->write(".gdbinit") };	# can't print without a backend
$@ ? print "ok 3\n" : print "not ok 3\n";


