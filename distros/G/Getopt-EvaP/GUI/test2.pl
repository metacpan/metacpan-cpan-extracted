#!/usr/local/bin/perl -w

use Getopt::EvaP;		# Evaluate Parameters
use subs qw/exit/;

sub exit {} # override builtin to check command line processing errors

@PDT = split /\n/, <<'end-of-PDT';
PDT sample
  set, s: list of 2 float = $required
PDTEND optional_file_list
end-of-PDT

@MM = split /\n/, <<'end-of-MM';
sample

	A sample program demonstrating typical Evaluate Parameters
	usage.
end-of-MM

EvaP \@PDT, \@MM;

print "set=", join(',', @opt_set), "!\n";
