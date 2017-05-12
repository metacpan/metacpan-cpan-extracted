#!/usr/bin/perl

use HTML::Merge::Development;
use CGI qw/:standard/;
use strict;

ReadConfig();

die "Not in web mode" if (length($HTML::Merge::Ini::CACHE_PATH) < 6);

use File::Path;

rmtree $HTML::Merge::Ini::CACHE_PATH;
mkdir $HTML::Merge::Ini::CACHE_PATH, 0755;

print <<HTML;
Content-type: text/html

<HTML>
<BODY onLoad="opener.focus(); window.close();">
</BODY>
</HTML>
HTML

sub recur {
die "Obsolete";
	my $dir = shift;
	foreach (glob("$dir/*")) {
		if (-d $_) {
			&recur($_);
			rmdir $_;
			next;
		}
		unlink $_;
	}
}
