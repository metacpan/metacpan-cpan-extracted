# t/fit2tcx.t - script to convert FIT files to TCX 
use Test::More tests => 2;

use strict;
use warnings;
use Geo::FIT;
use File::Temp qw/ tempfile /;
use IPC::System::Simple qw(system);

my ($input_file, $output_file);
$input_file = 't/10004793344_ACTIVITY.fit';
($output_file = $input_file) =~ s/\.fit$/.tcx/;
unlink $output_file if -f $output_file;

my @args = ('--indent=4', $input_file, $output_file );
system($^X, 'script/fit2tcx.pl', @args);
is(-f $output_file, 1, "    fit2tcx.pl: results in new gpx file");
unlink $output_file;

my ($fh, $tmp_fname) = tempfile();
# may have to add option --force once it is added to the script
@args = ('--indent=4', $input_file, $tmp_fname );
system($^X, 'script/fit2tcx.pl', @args);
is(-f $tmp_fname, 1, "    fit2tcx.pl: results in new tcx temporry file");

print "so debugger doesn't exit\n";

