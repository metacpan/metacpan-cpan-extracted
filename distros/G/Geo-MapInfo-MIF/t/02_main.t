#!/usr/bin/perl

use 5.006;
use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 4;

use Geo::MapInfo::MIF;
use File::Spec;





######################################################################
# Basic Query

SCOPE: {
	my $mif_file = File::Spec->catfile("t", "data", "act.mif");
	my @file_contents = Geo::MapInfo::MIF::read_files($mif_file);
	my %mif_info = Geo::MapInfo::MIF::get_mif_info(@{$file_contents[0]});
	my %regions = Geo::MapInfo::MIF::process_regions(1, $file_contents[0], $file_contents[1]);
	is( scalar(@file_contents), 2, 'Both files read' );
	is( $file_contents[1][0], "1,\"Canberra\",283,0,0,0,0,1920.48,\"Canberra\"", "MID file read correctly");
	is( $mif_info{Coordsys}, 'Earth Projection 1, 116', "MIF file read correctly");
	is( scalar(@{$regions{Canberra}->[0]}), 4316, 'Regions read correctly');
}
