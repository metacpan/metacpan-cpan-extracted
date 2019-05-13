#! /usr/bin/perl
# $Id: 08_http.t,v 1.3 2008/08/08 07:37:50 dk Exp $

use strict;
use warnings;

use Test::More;
use HTTP::Request;
use IO::Lambda qw(:all);
use IO::Lambda::HTTP;

plan skip_all => "online tests disabled" unless -e 't/online.enabled';
plan tests    => 2;

my %opt;

if ( defined ( my $p = $ENV{http_proxy} )) {
	$p =~ s{^http://}{};
	$p =~ s{[\.\-\w]*\@([\.\-w]*:)}{}; # user-pass
	$p =~ s{/$}{};
	my ( $host, $port ) = $p =~ /^([\.\-\w]+):?(\d*)$/;
	$port ||= 80;
	$opt{proxy} = [ $host, $port ];
}

sub http_lambda
{
	IO::Lambda::HTTP-> new(
		HTTP::Request-> new( 
			GET => "http://$_[0]/"
		), %opt)
}

# single
my $r = http_lambda('www.google.com')-> wait;
ref($r) ? ok(1,"http_get(google)") : ok(0,"http_get(google):$r");

# many
lambda {
	context map { http_lambda('www.google.com') } 1..3;
	tails { ok(( 3 == grep { ref($_) } @_), 'parallel resolve') }
}-> wait;
