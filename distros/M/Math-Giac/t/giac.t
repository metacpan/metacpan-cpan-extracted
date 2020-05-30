#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

my $extra_tests=0;

BEGIN {
    use_ok( 'Math::Giac' ) || print "Bail out!\n";
}

my $the_bin = `/bin/sh -c 'which giac 2> /dev/null'`;
if ( $? eq 0 ){

	$extra_tests=7;

	my $worked=0;
	my $giac;
	eval{
		$giac=Math::Giac->new;
		$worked=1;
	};
	ok( $worked eq '1', 'init check') or diag('failed to init the module... '.$@);

	# basic single line return test
	my $returned='';
	my $extra_error='';
	eval{
		$returned=$giac->run("sin(pi)+3");
	};
	if ( $@ ){
		$extra_error='... '.$@;
	}
	ok( $returned eq '3', 'run check') or diag('"sin(pi)+3" returned "'.$returned.'" instead of "3"'.$extra_error);

	# basic multi line return test
	$returned='';
	$extra_error='';
	eval{
		$returned=$giac->run("mathml(sin(pi))");
	};
	if ( $@ ){
		$extra_error='... '.$@;
	}
	ok( $returned =~ /MathML/, 'run check') or diag('"mathml(sin(pi))" returned "'.$returned.'" and does not match /MathML/'.$extra_error);

	# make sure that we can set the variables
	$worked=1;
	eval{
		$giac->vars_set({A=>2});
		$worked=1;
	};
	ok( $worked eq '1', 'vars_set') or diag('Calling vars_set failed... '.$@);

	# run a test using a variable
	$returned='';
	$extra_error='';
	eval{
		$returned=$giac->run("3+A");
	};
	if ( $@ ){
		$extra_error='... '.$@;
	}
	ok( $returned eq '5', 'variable test') or diag('"3+A" where A=2 returned "'.$returned.'" instead of "5"'.$extra_error);

	# make sure that we can clear
	$worked=1;
	eval{
		$giac->vars_clear;
		$worked=1;
	};
	ok( $worked eq '1', 'vars_clear') or diag('Calling vars_clear failed... '.$@);

	# run a test using a variable post clearing the vars
	$returned='';
	$extra_error='';
	eval{
		$returned=$giac->run("3+A");
	};
	if ( $@ ){
		$extra_error='... '.$@;
	}
	ok( $returned eq '3+A', 'variable test 2') or diag('"3+A" where A=undef returned "'.$returned.'" instead of "3+A"'.$extra_error);

}

my $tests_ran=1+$extra_tests;
done_testing($tests_ran);
