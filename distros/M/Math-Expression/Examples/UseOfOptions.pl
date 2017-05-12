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
#	SCCS: @(#)UseOfOptions.pl	1.3 03/04/08 09:00:22
#
# Examples in the use of some of the options available via SetOpt().

use strict;
use Math::Expression;

my $trace = 0;	# Debugging

# A function to provide more functions than those built in.
# Ie in ADDITION to the standard functions.
# This must return undef if the function is not recognised.
# Arguments are:
# 0	Object reference
# 1	Name of the function that we are to try to evaluate
# 2 ..	Arguments to that function
sub moreFun {
	print "moreFun called: '$_[1]'\n" if $trace;

	my ($self, $fname, @arglist) = @_;

	my $last = $arglist[$#arglist];

	return length($last)			if($fname eq 'strlen');

	return undef;	# There is no such extra function
}

my $ArithEnv = new Math::Expression;



$ArithEnv->SetOpt('ExtraFuncEval' => \&moreFun);	# Say that we have an extra function evaluator

# Run some code and print the results
# An extra function:
my $tree0 = $ArithEnv->Parse('strlen("123456")');
print qq[strlen("123456") yeilds: ] . $ArithEnv->EvalToScalar($tree0) . "\n";

# A built in function:
my $tree1 = $ArithEnv->Parse('round(3.3)');
print qq[round(3.3) yeilds: ] . $ArithEnv->EvalToScalar($tree1) . "\n";

# You could have gone:
#	$ArithEnv->SetOpt('FuncEval' => \&myFunEvaluator);
# In this case you need to provide evaluators for all of the built in functions.




# It is an error if variables are not initialised before used:
my $treeUndef = $ArithEnv->Parse('a + b');
print qq["a + b" yeilds: ] . $ArithEnv->EvalToScalar($treeUndef) . "\n";

# Auto initialise variables stops the error:
$ArithEnv->SetOpt('AutoInit' => 1);
print qq["a + b" yeilds: ] . $ArithEnv->EvalToScalar($treeUndef) . "\n";
# Think carefully before doing this, just because you no longer get an error
# message does not mean that it is doing the right thing.




# Alternative places to store variables.
# Variables are stored in a hash, you can specify that hash if you wish:
my %VarHash;
$ArithEnv->SetOpt('VarHash' => \%VarHash);

# This allows variables to given initialising values.
# Note that variables are always arrays:
$VarHash{count} = [22];
my $treeCount = $ArithEnv->Parse('count');
print qq["count" yeilds: ] . $ArithEnv->EvalToScalar($treeCount) . "\n";

my $treeSetResult = $ArithEnv->Parse('result := 42');
print qq["result := 42" yeilds: ] . $ArithEnv->EvalToScalar($treeSetResult) . "\n";

# You can access the variable within your perl script. Again - note that it is held
# as an array:
print "result direct from the hash: '$VarHash{result}[0]'\n";

# You can get more control of setting/getting variables, see the test program test.t
# for examples. (Functions VarValue, VarIsDef, VarSet)



# Define our own error printing function:
sub MyErrorFunction {
	print "MyErrorFunction says: @_\n";
}

$ArithEnv->SetOpt('PrintErrFunc' => \&MyErrorFunction);		# Use that function

# Call an unknown function:
my $treeBadFun = $ArithEnv->Parse('foo(0)');
print qq["foo(0)" yeilds: ] . $ArithEnv->EvalToScalar($treeBadFun) . "\n";



# To show how RoundNegatives affects the rounding of negative numbers:
foreach (0, 1) {
	print "Arithmetic rounding with option RoundNegatives = $_\n";
	$ArithEnv->SetOpt(RoundNegatives => $_);

	foreach my $e (('round(0.6) ', 'round(-0.6) ', 'round(0.4) ', 'round(-0.4) ')) {
		my $treeRound = $ArithEnv->Parse($e);

		print qq[$e yeilds: ] . $ArithEnv->EvalToScalar($treeRound) . "\n";
	}
}

# end

