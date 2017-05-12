#!/usr/bin/perl

use URI::Escape;
use CGI qw/:standard/;
use HTML::Merge::Development;
use strict;

&ReadConfig();

my $template = param('template');

my @tokens;

my $cand;

for (;;) {
	$cand++;
	my $key = param("key$cand");
	my $data = param("data$cand");
	last unless defined $key;
	next unless $key;

	push(@tokens, uri_escape($key) . '='
			. uri_escape($data));
}

my $string = join("&", @tokens);
$string = "&$string" if $string;

print "Content-type: text/html\n\n";

print <<HTML;

<SCRIPT>
<!--
	opener.opener.opener.opener.top.location = "$HTML::Merge::Ini::MERGE_PATH/$HTML::Merge::Ini::MERGE_SCRIPT?template=$template$string";
	opener.opener.opener.opener.focus();
	close();
// -->
</SCRIPT>
HTML
