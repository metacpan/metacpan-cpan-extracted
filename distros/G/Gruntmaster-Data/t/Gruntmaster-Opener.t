#!/usr/bin/perl
use v5.14;
use warnings;

use Test::More tests => 8;
use Gruntmaster::Opener;

my $opened;
BEGIN {
	no warnings 'redefine';
	*Gruntmaster::Opener::open_problem = sub { $opened = 1 };
}

sub _test {
	my ($line, $should_open, $name) = @_;
	$line =~ s,DATE,[01/Jan/2015:00:00:00 +0200],;
	$opened = '';
	handle_line $line;
	is $opened, $should_open, $name
}

_test '192.0.2.41 - mgv DATE "GET /pb/problem1?contest=test HTTP/1.1" 200 1234', 1, 'normal case';
_test '192.0.2.41 - mgv DATE "HEAD http://gruntmaster.example.org/pb/problem1?contest=test HTTP/1.0" 200 1234', 1, 'absolute url';
_test '2001:db8:abcd::1234 - mgv DATE "GET /pb/%61%62%63%64?%63ontes%74=%62%61%64 SPDY/3" 200 1234', 1, 'superfluous percent encoding';

_test '192.0.2.41 - mgv DATE "GET /pb/problem1?contest=test HTTP/1.1" 500 1234', '', 'internal server error';
_test '192.0.2.41 - - DATE "GET /pb/problem1?contest=test HTTP/1.1" 401 1234', '', 'not logged in';
_test '192.0.2.41 - mgv DATE "GET /pb/?contest=test HTTP/1.0" 200 1234', '', 'problem list';
_test '2001:db8:abcd::1234 - mgv DATE "GET /pb/asd SPDY/3" 200 1234', '', 'not in contest';
_test 'junk', '', 'junk';
