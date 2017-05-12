#!/usr/local/bin/perl
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..1\n"; }
END {print "not ok 1\n" unless $loaded;}
use Math::MVPoly::Parser;
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

$p = Math::MVPoly::Parser->new();

opendir(DIR, "samples");
@list = grep {! /^\./} readdir(DIR);

foreach $f (sort @list)
{
	print "\nRunning $f:\n";
	$r = $p->parseFile("samples/$f");
	print $r;
}

closedir(DIR);
