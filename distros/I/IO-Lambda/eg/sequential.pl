#!/usr/bin/perl
# $Id: sequential.pl,v 1.7 2008/11/03 09:24:02 dk Exp $
# 
# This example fetches sequentially two pages, one with http/1.0 another with
# http/1.1 . The idea is to demonstrate three different ways of doing so, by
# using object API, and explicit and implicit loop unrolling
#
# Note how connections are reused with LWP::ConnCache.

use lib qw(./lib);
use HTTP::Request;
use IO::Lambda qw(:lambda);
use IO::Lambda::HTTP::Client qw(http_request);
use LWP::ConnCache;

my $cache = LWP::ConnCache-> new;
my $url   = "http://www.perlmonks.org/";

my $a = HTTP::Request-> new( GET => $url);
$a-> protocol('HTTP/1.1');
$a-> headers-> header( Host => $a-> uri-> host);

my @chain = (
	$a,
	HTTP::Request-> new( GET => $url)
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

# $IO::Lambda::DEBUG++; # uncomment this to see that it indeed goes sequential

if ( $style eq 'object') {
	# object API, all references and bindings are explicit
	while ( @chain) {
		my $lambda = IO::Lambda::HTTP::Client-> new( shift(@chain), conn_cache => $cache);
		$lambda-> wait;
		report( $lambda-> peek);
	}
} elsif ( $style eq 'explicit') {

	#
	# Functional API, based on context() calls. context is
	# $obj and whatever agruments the current call needs, a RPN of sorts.
	# The context though is not stack in this analogy, because it stays
	# as is in the callback
	#
	# Explicit loop unrolling - we know that we have exactly 2 steps
	# It's not practical in this case, but it is when a (network) protocol
	# relies on precise series of reads and writes
	this lambda {
		context $chain[0], conn_cache => $cache;
		http_request {
			report shift;
			context $chain[1], conn_cache => $cache;
			http_request \&report;
		}
	};
	this-> wait;
} else {
	# implicit loop - we don't know how many states we need
	this lambda {
		context shift(@chain), conn_cache => $cache;
		http_request {
			report shift;
			return unless @chain;
			context shift(@chain), conn_cache => $cache;
			again;
		}
	};
	this-> wait;
}
