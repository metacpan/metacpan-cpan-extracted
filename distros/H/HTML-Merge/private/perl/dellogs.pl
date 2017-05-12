#!/usr/bin/perl

use HTML::Merge::Development;
use CGI qw/:standard/;
use strict;

ReadConfig();

my $log_dir = "$HTML::Merge::Ini::MERGE_ABSOLUTE_PATH/$HTML::Merge::Ini::MERGE_ERROR_LOG_PATH/$ENV{'REMOTE_ADDR'}";

die "Not in web mode" if (length($log_dir) < 6);

use File::Path;
rmtree $log_dir;
mkdir $log_dir, 0755;

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

