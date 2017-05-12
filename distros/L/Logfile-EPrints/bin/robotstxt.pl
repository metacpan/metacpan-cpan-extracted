#!/usr/bin/perl

use warnings;
use strict;
use DB_File;
use POSIX qw/ strftime /;

die "Usage: $0 <robots.db>\n" unless $ARGV[0];

tie my %HASH, 'DB_File', $ARGV[0]
		or die "Unable to open robots cache database (".$ARGV[0]."): ".$!;

while( my ($ip,$rest) = each %HASH )
{
	my ($ut,$ua) = split / /, $rest, 2;
	$ua =~ s/\"/\\\"/sg;
	printf("%s\t%s\t\"%s\"\n", $ip, strftime("%Y%m%d%H%M%S",localtime($ut)), $ua);
}

untie %HASH;
