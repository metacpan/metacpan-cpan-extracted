#!/usr/bin/perl

use GoXML::XQI;

my($xqi) = new GoXML::XQI(
		HOST => 'www.goxml.com',
		PORT => 5910,
		VERBOSE => 1,
);

$sock = $xqi->Query("xml","post","15");

while (<$sock>) {
	print;
}
