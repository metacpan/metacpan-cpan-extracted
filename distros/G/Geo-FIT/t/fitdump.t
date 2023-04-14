# t/fitdump.t - script to print the contents of Garmin FIT files to standard output or a file
use Test::More tests => 1;

use strict;
use warnings;
use Geo::FIT;
use IPC::System::Simple qw(system);

my $output_file = 't/fitdump.txt';
unlink $output_file if -f $output_file;

my @args = ('--force', 't/10004793344_ACTIVITY.fit', $output_file );
system($^X, 'script/fitdump.pl',  @args);

is(-f $output_file, 1,              "    fitdump.pl: results in new .txt file");

# this test relies on git status telling us if t/dump.txt has changed

print "so debugger doesn't exit\n";
