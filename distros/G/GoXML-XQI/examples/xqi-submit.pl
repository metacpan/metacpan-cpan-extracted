#!/usr/bin/perl
# (c)1999 XML Global Technologies, Inc. All Rights Reserved

# Sends a URL to GoXML

use GoXML::XQI;

my $q = new GoXML::XQI(VERBOSE => 1);


my $resp =$q->Submit(
		HREF => 'http://some.xml.file.com/xml.xml',
		DESCRIPTION => 'Just another file',
		CATEGORY => 8);

print "The url is probably bad.\n" if ! $resp;
