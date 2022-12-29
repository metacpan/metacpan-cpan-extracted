use strict;
use File::Basename qw(dirname);
use File::Path qw(mkpath);

my($file, $from) = @ARGV;
unless( -d( my $dir = dirname $file ) ) { mkpath $dir, 1 }
my $has_warnings = eval { require warnings; };

open IN, '<', $from or die "$0 can't open $from: $!\n";
open OUT, '>'. $file or die "$0 can't open $file: $!\n";

while( <IN> ) {
    s/;\s+\#\s+REQUIRE_ORDER\b/ qw(:config no_require_order);/;
    print OUT;
}

close OUT or die $!;
close IN or die $!;
