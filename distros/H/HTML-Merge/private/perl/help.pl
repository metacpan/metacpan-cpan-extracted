#!/usr/bin/perl

use CGI qw/:standard/;
use strict;

print "Content-type: text/html\n\n";

unless (open(I, "../../docs/Tags.html")) {
	print <<HTML;
	Sorry, help not available.
	<A HREF="javascript: opener.focus(); window.close();">Close</A>
HTML
	exit;
}

my $year = (localtime)[5] + 1900;
my $text = do { local ($/); <I> };

$text =~ s/\<BODY.*?\>/<BODY BGCOLOR="Silver">\nMerge &copy; 1999-$year Raz Information Systems, http:\/\/www.raz.co.il<BR>/;

$text =~ s|</BODY>|<A HREF="javascript: opener.focus(); window.close();">Close</A>\n</BODY>|;

print $text;
