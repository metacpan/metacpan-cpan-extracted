# vim: set ft=perl :
# invalid_spec.t: Tests of invalid parameters passed to parameters()
# (as opposed to invalid parameters passed to the _caller_ of parameters())

{
	package MyTestClass;
	sub new { bless {} }
}

my @tests;
BEGIN {
	@tests =(
		[ {} ],					# can't take non-[] ref
		[ MyTestClass->new ],	# can't take non-[] ref
		[ [qw(a b ; c d ; e)], 1, 2 ],	# only one semicolon allowed
		[ [qw(;; a)], 1 ],		# only one semicolon allowed
		[ [qw(;)] ],			# Semicolon without an actual name
		[ [' ;'] ],				# Ditto, but with leading WS
		[ ['; '] ],				# Ditto, but with trailing WS
	);
}

use Test::More tests => (1+2*@tests);
BEGIN { use_ok('Getargs::Mixed') };

my $testidx=0;
foreach (@tests) {
	eval {
		parameters(@$_, 1);
	};

	#diag("Expected exception; got $@");
	if ($@) {
		pass("Exception thrown as it should be.");
	} else {
		fail("Exception not thrown for test $testidx");
	}

	eval {
		Getargs::Mixed->new->parameters(@$_, 1);
	};

	#diag("Expected exception; got $@");
	if ($@) {
		pass("Exception thrown as it should be (OO).");
	} else {
		fail("Exception not thrown for test $testidx (OO)");
	}

	++$testidx;
} #foreach test
