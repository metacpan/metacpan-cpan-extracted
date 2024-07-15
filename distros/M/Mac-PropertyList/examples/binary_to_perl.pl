#!/usr/local/bin/perl
use warnings;
use strict;
use v5.10;

use Data::Dumper;
use Mac::PropertyList qw(parse_plist_file);

use Mac::PropertyList;

my $data = do {
	open my $fh, '<:raw', $ARGV[0];
	sysread $fh, my $rec, -s $fh;
	};

my $plist = parse_plist_file( $ARGV[0] );

say Dumper( $plist );
