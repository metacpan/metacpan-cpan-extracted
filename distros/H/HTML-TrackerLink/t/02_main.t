#!/usr/bin/perl

# Formal testing for HTML::TrackerLink

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 13;
use HTML::TrackerLink ();





#####################################################################
# Basic Testing

# A couple of very basic tests
SCOPE: {
	my $tracker = HTML::TrackerLink->new();
	ok( defined $tracker, "->new() returns defined" );
	ok( $tracker, "->new() returns true" );
	isa_ok( $tracker, 'HTML::TrackerLink' );
}





#####################################################################
# Regression Tests from CPAN #17304

# Multiple named trackers
SCOPE: {
	my $url1 = 'http://ali.as/foo?n=%n';
	my $url2 = 'http://ali.as/bar?n=%n';
	my $tracker = HTML::TrackerLink->new( foo => $url1, bar => $url2 );
	isa_ok( $tracker, 'HTML::TrackerLink' );

	# Check some parsing runs
	$_ = 'this';
	my $html1 = $tracker->process( 'A foo #1234 bug' );
	is( $html1, "A <a href='http://ali.as/foo?n=1234'>foo #1234</a> bug",
		'Multiple named trackers links correctly' );
	is( $_, 'this', '->process does not clobber $_' );

	# Set a default
	my $url3 = 'http://ali.as/default?n=%n';
	is( $tracker->default($url3), $url3, 'Set default tracker' );
	$html1 = $tracker->process( 'A foo #1234 bug' );
	is( $html1, "A <a href='http://ali.as/foo?n=1234'>foo #1234</a> bug",
		'Multiple named trackers links correctly' );

	# * when processing texts where a default keyword among two or more
	# would be applied, leading spaces were cut.
	# $linker->process("this is #288") => "this is<a href='link'>#288</a>"
	my $html2 = $tracker->process( 'A #1234 bug' );
	is( $html2, "A <a href='http://ali.as/default?n=1234'>#1234</a> bug",
		'Default tracker links correctly' );

}

SCOPE: {
	my $linker = HTML::TrackerLink->new();
	$linker->keyword('bug' => 'http://host1/path?id=%n');
	$linker->keyword('change' => 'http://host2/path?id=%n');
	$linker->default_keyword('bug');
	isa_ok( $linker, 'HTML::TrackerLink' );

	# Basic processing
	my $string1 = 'This is #3';
	my $html1   = $linker->process($string1);
	ok( $html1 , "process ok" );
	is( $html1, "This is <a href='http://host1/path?id=3'>#3</a>",
		"HTML created OK" );

	# A string containing all three
	my $string2 = <<'END_STRING';
This is a message containing links to #456 and BuG 1234 and #456.

Also to change #2345 and to #543 as well.

END_STRING

	my $html2 = $linker->process($string2);
	is( $html2, <<'END_HTML', 'All three match types occured in one string' );
This is a message containing links to <a href='http://host1/path?id=456'>#456</a> and <a href='http://host1/path?id=1234'>BuG 1234</a> and <a href='http://host1/path?id=456'>#456</a>.

Also to <a href='http://host2/path?id=2345'>change #2345</a> and to <a href='http://host1/path?id=543'>#543</a> as well.

END_HTML
}
