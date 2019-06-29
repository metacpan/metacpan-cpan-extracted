#!/usr/bin/perl
# $Id: parallel.pl,v 1.7 2008/05/06 20:41:33 dk Exp $
# 
# This example fetches two pages in parallel, one with http/1.0 another with
# http/1.1 . The idea is to demonstrate three different ways of doing so, by
# using object API, and explicit and implicit loop unrolling
#

use lib qw(./lib);
use HTTP::Request;
use IO::Lambda qw(:lambda);
use IO::Lambda::HTTP::Client qw(http_request);
use LWP::ConnCache;

my $a = HTTP::Request-> new(
	GET => "http://www.perl.com/",
);
$a-> protocol('HTTP/1.1');
$a-> headers-> header( Host => $a-> uri-> host);

my @chain = ( 
	$a, 
	HTTP::Request-> new(GET => "http://www.perl.com/"),
);

sub report
{
	my ( $result) = @_;
	if ( ref($result) and ref($result) eq 'HTTP::Response') {
		print "good:", length($result-> content), "\n";
	} else {
		print "bad:$result\n";
	}
#	print $result-> content;
}

my $style;
#$style = 'object';
#$style = 'explicit';
$style = 'implicit';

# $IO::Lambda::DEBUG++; # uncomment this to see that it indeed goes parallel

if ( $style eq 'object') {
	## object API, all references and bindings are explicit
	sub handle {
		shift;
		report(@_);
	}
	my $master = IO::Lambda-> new;
	for ( @chain) {
		my $lambda = IO::Lambda::HTTP::Client-> new( $_ );
		$master-> watch_lambda( $lambda, \&handle);
	}
	run IO::Lambda;
} elsif ( $style eq 'explicit') {
	#
	# Functional API, based on context() calls. context is
	# $obj and whatever arguments the current call needs, a RPN of sorts.
	# The context though is not stack in this analogy, because it stays
	# as is in the callback
	#
	# Explicit loop unrolling - we know that we have exactly 2 steps
	# It's not practical in this case, but it is when a (network) protocol
	# relies on precise series of reads and writes
	this lambda {
		context $chain[0];
		http_request \&report;
		context $chain[1];
		http_request \&report;
	};
	this-> wait;
} else {
	# implicit loop - we don't know how many states we need
	# 
	# also, use 'tail'
	this lambda {
		context map { IO::Lambda::HTTP::Client-> new( $_, async_dns => 1 ) } @chain;
		tails { report $_ for @_ };
	};
	this-> wait;
}

