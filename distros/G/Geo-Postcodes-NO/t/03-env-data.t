use strict;
use warnings;
use utf8;

use File::Temp qw(tempfile);
use Test::More;

my ($fh, $path) = tempfile();
binmode $fh, ':raw';
print {$fh} join("\t", '9999', 'EGENFIL', '0301', 'OSLO', 'G'), "\r\n";
close $fh or die "Cannot close $path: $!";

$ENV{GEO_POSTCODES_NO_DATA} = $path;

require Geo::Postcodes::NO;

is(Geo::Postcodes::NO::data_file(), $path, 'environment data file path is used');
is(Geo::Postcodes::NO::data_valid_from(), undef, 'environment data file has no bundled validity date');

delete $ENV{GEO_POSTCODES_NO_DATA};
is(Geo::Postcodes::NO::data_file(), $path, 'loaded data file path does not change after environment changes');
is(Geo::Postcodes::NO::data_valid_from(), undef, 'loaded environment data still has no bundled validity date');

ok(Geo::Postcodes::NO::valid('9999'), 'postcode from environment data file is valid');
is(Geo::Postcodes::NO::location_of('9999'), 'EGENFIL', 'environment data file content is loaded');
ok(!Geo::Postcodes::NO::valid('1178'), 'bundled data is not loaded when environment override is set');

done_testing;
