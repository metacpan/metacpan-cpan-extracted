use strict;
use warnings;

use File::Basename qw(dirname);
use File::Path qw(mkpath);
use File::Copy qw(copy);

my($file, $from) = @ARGV;
unless( -d( my $dir = dirname $file ) ) { mkpath $dir, 1 }
copy($from, $file) or die $!;
