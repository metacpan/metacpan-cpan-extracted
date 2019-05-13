#!/usr/bin/perl
# $Id: loop.pl,v 1.3 2008/08/07 09:26:31 dk Exp $

# This example implements a loop with lambdas, as a tail-chain
# of subsequent calls. There are two loops that run in parallel.

use strict;
use IO::Lambda qw(:lambda);

# first layer: constant value lambdas
my @q = map {
	my $x = $_; 
	lambda { $x } 
} (1..5);

# second layer: lambdas that read one by one from the @q pool until it is empty
sub reader
{ 
	my $id = shift;
	lambda {
		my $q  = shift @q;
		return unless $q;

		context $q;
	tail {
		print "$id:$_[0]\n";

		# Note that this construction is an efficient 'again' for the whole lambda
		this-> start;
	}
}};

# third layer: a lambda that creates 2 2nd layer lambdas that read from @q in parallel
this lambda {
	context map { reader($_) } (1,2);
	&tails;
};
this-> wait;
