#!/usr/bin/perl

use strict;

my $version = `htmldoc --version`;

if (!$version) {
	print "htmldoc not found. please install first\n";
	exit(1);
}

if( $version!~/^1\.\d+/ ) {
	print "wrong version of htmldoc found\n";
	exit(1);
}

chomp($version);
print "htmldoc version $version found [OK]\n\n";
exit(0);
