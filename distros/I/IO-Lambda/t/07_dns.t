#! /usr/bin/perl
# $Id: 07_dns.t,v 1.5 2009/11/30 14:56:36 dk Exp $

use strict;
use warnings;

use Test::More;
use IO::Lambda qw(:all);
use IO::Lambda::DNS qw(:all);
use Net::DNS;

plan skip_all => "online tests disabled" unless -e 't/online.enabled';

# test if net::dns is functional at all
eval {
	my $obj  = Net::DNS::Resolver-> new();
	my $sock = $obj-> bgsend('www.google.com');
	my $time = time + 5;
	while ( not $obj-> bgisready( $sock )) { die if time > $time };
	my $packet = $obj-> bgread( $sock);
	die unless $packet;
};
plan skip_all => "Net::DNS cannot resolve google.com in this environment" if $@;

plan tests    => 3;

# simple
ok(
	IO::Lambda::DNS-> new('www.google.com')-> wait =~ /^\d/,
	"resolve google(a)"
);

# packet-wise
ok(
	ref(IO::Lambda::DNS-> new('www.google.com', 'mx')-> wait),
	"resolve google(mx)"
);

# resolve many
lambda {
	context map { 
		IO::Lambda::DNS-> new('www.google.com')
	} 1..3;
	tails { ok(( 3 == grep { /^\d/ } @_), 'parallel resolve') }
}-> wait;
