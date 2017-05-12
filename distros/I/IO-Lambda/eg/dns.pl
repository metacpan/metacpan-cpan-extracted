#!/usr/bin/perl
# $Id: dns.pl,v 1.4 2012/01/14 10:33:30 dk Exp $
use strict;
use IO::Lambda::DNS qw(:all);
use IO::Lambda qw(:lambda);

sub show
{
	my $res = shift;
	unless ( ref($res)) {
		print "$res\n";
		return;
	}

	for ( $res-> answer) {
		if ( $_-> type eq 'CNAME') {
			print "CNAME: ", $_-> cname, "\n";
		} elsif ( $_-> type eq 'A') {
			print "A: ", $_-> address, "\n";
		} else {
			$_-> print;
		}
	}
}

# style one -- dns_query() is a condition
lambda {
	for my $site ( map { "www.$_.com" } qw(google yahoo perl)) {
		context $site,
			timeout => 1.0, 
			retry => 1;
		dns { show(@_) }
	}
}-> wait;

print "--------------\n";

# style two -- dns_lambda returns a lambda
lambda {
	context map { 
		IO::Lambda::DNS-> new( "www.$_.com" )
	} qw(google perl yahoo);
	tails { show($_) for @_ };
}-> wait;
