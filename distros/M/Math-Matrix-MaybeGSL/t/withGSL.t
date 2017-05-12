#!perl

if (eval { require Math::GSL::Matrix; 1; }) {

	require 't/tests.pl';

} else {

	print "1..0 # SKIP Math::GSL::Matrix not found"

}
