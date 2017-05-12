#!/usr/bin/perl -w

use Test::More;
use strict;

if (!eval q{ use Test::Pod::Coverage 1.00; 1 }) {
    plan skip_all => "Test::Pod::Coverage 1.00 required for testing POD coverage";
    exit 0;
}

my @mod_defs = (
		['Info'],
		['Info::BMP'],
		['Info::PPM'],
		['Info::SVG'],
		['Info::XBM'],
		['Info::XPM'],
		['Info::TIFF'],
		['TIFF',       uncovered => 1],
		['Info::GIF',  uncovered => 1],
		['Info::PNG',  uncovered => 1],
		['Info::JPEG', uncovered => 1],
	       );

plan tests => scalar @mod_defs;

for my $mod_def (@mod_defs) {
    my $mod = 'Image::' . shift(@$mod_def);
    my %test_opts = @$mod_def;
    local $TODO;
    if ($test_opts{uncovered}) {
	$TODO = "$mod is not yet covered";
    }

 SKIP: {
	skip "Cannot test Pod coverage of $mod, maybe prereqs are missing", 1
	    if !eval qq{ require $mod; 1 };

	pod_coverage_ok($mod, "$mod is covered");
    }
}
