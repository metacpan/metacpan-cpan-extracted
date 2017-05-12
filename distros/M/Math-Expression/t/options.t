#!/usr/bin/perl -w
#      /\
#     /  \		(C) Copyright 2008 Parliament Hill Computers Ltd.
#     \  /		All rights reserved.
#      \/
#       .		Author: Alain Williams, March 2008
#       .		addw@phcomp.co.uk
#        .
#          .
#
#	SCCS: @(#)options.t	1.1 03/04/08 09:01:27
#
# Test options for the module Math::Expression.
#
# May want to run as:
#	PERL5LIB=blib/lib t/options.t
#	PERL5LIB=../blib/lib options.t

# You can also set environment variables:
#  TRACE	1	print out expression and result
#		2	also print out the parse tree
# eg:
#	TRACE=1 perl -Iblib/lib t/test.t

# Copyright (c) 2008 Parliament Hill Computers Ltd/Alain D D Williams. All rights reserved.
# This module is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself. You must preserve this entire copyright
# notice in any use or distribution.
# The author makes no warranty what so ever that this code works or is fit
# for purpose: you are free to use this code on the understanding that any problems
# are your responsibility.

# Permission to use, copy, modify, and distribute this software and its documentation for any purpose and without fee is
# hereby granted, provided that the above copyright notice appear in all copies and that both that copyright notice and
# this permission notice appear in supporting documentation.

use strict;
use Math::Expression;

my $NumFails = 0;
my $ExprError;
my $RunError;
my $errtree = 0;
my $verbose = 0;
my $var=0;
my @arr = (1,2,3);

my $OriginalExpression;
my $Operation;

sub MyPrintError {
	printf "#Error in $Operation '%s': ", $OriginalExpression;
	printf @_;
	print "\n";

	if($Operation eq 'parsing') {
		$ExprError = 1;
	} else {
		$RunError = 1;
	}
}

sub printv {
	return unless($verbose > 1);

	if($#_ > 0) {
		my $fmt = shift @_;
		printf $fmt, @_;
	} else {
		print $_[0];
	}
}

# **** Start here ****

# Debug/trace options from the environment:
$verbose = $ENV{TRACE}    if(exists($ENV{TRACE}));
$errtree = $ENV{ERR_TREE} if(exists($ENV{ERR_TREE}));

printf "Math::Expression Version '%s'\n", $Math::Expression::VERSION if($verbose);

my $ArithEnv = new Math::Expression;

my $Now = time;

use Test::Simple;

my @round = ('round(0.6) ', 'round(-0.6) ', 'round(0.4) ', 'round(-0.4) ');
# Results of the above, twice, depending on option:
my @round_res = (
	[ 1,  0, 0, 0],
	[ 1, -1, 0, 0]
);

# Output # tests that we expect to do:
my $NumTests = (scalar @round) * 2;
print "1..$NumTests\n";

my $Tests = 0;

# To show how RoundNegatives affects the rounding of negative numbers:
foreach my $opt (0, 1) {

	$ArithEnv->SetOpt(RoundNegatives => $opt);

	my $test = 0;
	foreach my $e (@round) {
		$Tests++;
		my $tree = $ArithEnv->Parse($e);
		$ArithEnv->PrintTree($tree) if($verbose > 1);
		my $res = $ArithEnv->EvalToScalar($tree);
		my $ok = $res == $round_res[$opt][$test] ? 'ok' : ($NumFails++, 'not ok');
		print qq[$ok $Tests - expr '$e' res '$res' expected '$round_res[$opt][$test]'\n];

		$test++;
	}
}

print "\n\n";
print "# $Tests tests run\n";
print $NumFails == 0 ? "# All tests OK\n" : "# $NumFails tests failed\n";

# end
