# t/locations2gpx.t - script to convert locations.fit file
use Test::More tests => 2;

use strict;
use warnings;
use Geo::FIT;
use File::Temp qw/ tempfile /;
use IPC::System::Simple qw(system);

my $output_file = 't/Locations.gpx';
unlink $output_file if -f $output_file;

my @args = qw( --force --indent=4 t/Locations.fit );
system($^X, 'script/locations2gpx.pl', @args);
is(-f $output_file, 1, "    locations2gpx.pl: results in new gpx file");
unlink $output_file;

my ($fh, $tmp_fname) = tempfile();
@args = ('--force', '--indent=4', "--outfile=$tmp_fname", 't/Locations.fit' );
system($^X, 'script/locations2gpx.pl', @args);
is(-f $tmp_fname, 1, "    locations2gpx.pl: results in new gpx file");

print "so debugger doesn't exit\n";
