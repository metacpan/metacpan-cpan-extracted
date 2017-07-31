use Test::More;
use strict;
use warnings;
use Version::Compare;

my $gpsbabel = `gpsbabel --version`;
if($? != 0) {
	plan skip_all => "WARNING: GPSBabel not found! Skipping GPSBabel Version Test!";
}

my ($version) = ($gpsbabel =~ /GPSBabel Version (\d+\.\d+\.\d+)/i);

ok(Version::Compare::version_compare($version, "1.4.3") >= 0, "GPSBabel Version $version is greater or equal 1.4.3") or BAIL_OUT "GPSBabel version requirement >= 1.4.3 not met!";;

done_testing();
