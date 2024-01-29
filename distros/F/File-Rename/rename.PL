use strict;
use warnings;

use File::Basename qw(dirname);
use File::Path qw(mkpath);
use File::Copy qw(copy);

my($file, $from) = @ARGV;
unless( -d( my $dir = dirname $file ) ) { mkpath $dir, 1 }
if ( $] >= 5.032 and !$ENV{FILE_RENAME_OLD_PERL}) {
    copy($from, $file) or die $!; exit; 
}

open my $IN, '<', $from or die "$0 can't open $from: $!\n";
open my $OUT, '>', $file or die "$0 can't open $file: $!\n";
select $OUT;

while( <$IN> ) {
    s/^use\s+5\.032;\s*\#\s*//;
    print;
}

close $OUT or die $!;
close $IN or die $!;
