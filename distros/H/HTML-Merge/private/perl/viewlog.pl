#!/usr/bin/perl

use HTML::Merge::Development;
use HTML::Merge::Error;
use CGI qw/:standard/;
use strict;

ReadConfig();

my $log = param('log');

my $file = "$HTML::Merge::Ini::MERGE_ABSOLUTE_PATH/$HTML::Merge::Ini::MERGE_ERROR_LOG_PATH/$log";

print "Content-type: text/html\n\n";

unless (open(FILE, $file)) {
	&HTML::Merge::Error::ForceError("Could not open $file: $!");
	exit;
}

print join("", <FILE>);

close(FILE);
