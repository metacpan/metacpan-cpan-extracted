#!/usr/bin/perl -w
#      /\
#     /  \		(C) Copyright 2008 Parliament Hill Computers Ltd.
#     \  /		All rights reserved.
#      \/
#       .		Author: Alain Williams, February 2008.
#       .		addw@phcomp.co.uk
#        .
#          .
#
#	SCCS: @(#)BasicUse.pl	1.2 02/13/08 13:57:24
#
# Examples in basic use of the module.

use strict;
use Math::Expression;
use Data::Dumper;

my $trace = 0;	# Debugging

my $ArithEnv = new Math::Expression;


my $tree0 = $ArithEnv->Parse(' 12 * 4');
# Print: 48
print qq[12 * 4 yeilds: ] . $ArithEnv->EvalToScalar($tree0) . "\n";

my $treeList = $ArithEnv->Parse(' split(":", "ab:cde:fg")');
# Print: fg -- because the scalar is the last element
print qq[split(":", "ab:cde:fg") yeilds: ] . $ArithEnv->EvalToScalar($treeList) . "\n";

# Evaluate getting back a list (array):
my @result = $ArithEnv->Eval($treeList);
print Dumper(\@result);

# end

