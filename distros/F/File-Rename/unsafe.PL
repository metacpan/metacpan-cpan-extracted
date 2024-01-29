use strict;
use warnings;

use File::Basename qw(dirname);
use File::Path qw(mkpath);

my($file, $from) = @ARGV;
unless( -d( my $dir = dirname $file ) ) { mkpath $dir, 1 }

open my $IN, '<', $from or die "$0 can't open $from: $!\n";
open my $OUT, '>', $file or die "$0 can't open $file: $!\n";
select $OUT;

while( <$IN> ) {
    s/;\s+\#\s+REQUIRE_ORDER\b/ qw(:config no_require_order);/;
    print;
}

close $OUT or die $!;
close $IN or die $!;
