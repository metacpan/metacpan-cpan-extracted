#!/usr/bin/perl
# $Id: http-redirect.pl,v 1.8 2009/01/16 16:30:10 dk Exp $

use strict;
use HTTP::Request;
use HTTP::Response;
use IO::Lambda qw(:lambda);
use IO::Socket::INET;

# create chain of event on an existsing lambda object, that when
# finished, will contain the result

sub http_request
{
	my $req    = shift;
	my $socket = IO::Socket::INET-> new(
		PeerAddr => $req-> uri-> host,
		PeerPort => $req-> uri-> port,
		Blocking => 0,
	);

	lambda {
		return "socket error:$@" unless $socket;
		context $socket;
	writable  {
		print $socket $req-> as_string or return "error:$!";
		my $buf = '';
	readable  {
		my $n = sysread( $socket, $buf, 1024, length($buf));
		return "error:$!" unless defined $n;
		return HTTP::Response-> parse($buf) unless $n;
		again;
	}}};
}

# wrap http_request by listening to events from http_request
sub http_redirect_request
{
	my $req = shift;

	lambda   {
		context http_request($req);
		tail {
			my $result = shift;
			return $result unless ref($result);
			return $result if $result-> code !~ /^30/;
			$req-> uri( $result-> header('Location'));
			warn "redirected to ", $req-> uri, "\n";

			context http_request($req);
			again;
		}
	};
}

# main call
my $r = HTTP::Request-> new( GET => 'http://google.com/');
$r-> protocol('HTTP/1.1');
$r-> headers-> header( Host => $r-> uri-> host);

# this example doesn't deal with Connection: Keep-Alive for the simplicity of it
# see IO::Lambda::HTTP::Client for implementation that does
$r-> headers-> header( Connection => 'close'); 

this http_redirect_request( $r);
$r = this-> wait;
unless ( ref($r)) {
	print "some error:$r\n";
} else {
	print "read ", length($r->as_string), " bytes\n";
}
