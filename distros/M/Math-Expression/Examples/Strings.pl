#!/usr/bin/perl -w
#      /\
#     /  \		(C) Copyright 2015 Parliament Hill Computers Ltd.
#     \  /		All rights reserved.
#      \/
#       .		Author: Alain Williams, March 2015.
#       .		addw@phcomp.co.uk
#        .
#          .
#
#	SCCS: @(#)Strings.pl	1.1 03/27/15 13:13:14
#
# Examples in the use of strings.

use strict;
use feature qw/switch say/;

use Data::Dumper;
use Math::Expression;

my $trace = 0;	# Debugging

my $ArithEnv = new Math::Expression;

# Show what is going on:
print Dumper($ArithEnv);

my $tree0 = $ArithEnv->Parse('lang := "perl"');
print qq[lang has the value: ${\$ArithEnv->EvalToScalar($tree0)}\n];

$ArithEnv->ParseToScalar("creator := 'Larry Wall'");

# Do a string compare, this could print "lip = " . $ArithEnv->ParseToScalar('langIsPerl := lang eq "perl"') . "\n";
print "lip = " . $ArithEnv->ParseToScalar('lang eq "perl"') . "\n";

my $tree1 = $ArithEnv->Parse('intro := lang . " was created by " . creator');
print qq[intro has the value: ${\$ArithEnv->EvalToScalar($tree1)}\n];

#say $ArithEnv->ParseToScalar('loc := localtime(_TIME); strftime("date=%Y/%m/%d", loc)');
say $ArithEnv->ParseToScalar('strftime("date=%Y/%m/%d", localtime(_TIME))');

# _TIME is pre-set
print $ArithEnv->ParseToScalar('strftime("date=%Y/%m/%d", localtime(_TIME))') . "\n";


# end
