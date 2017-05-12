#! perl

use strict;
use warnings;

use Test::More;
use Test::Warnings;

use File::Slurper 'read_text';
use File::Spec::Functions 'catfile';
use FindBin '$RealBin';
use File::Temp 'tempfile';

my $inputfile = catfile( $RealBin, 'data', 'cp1252.txt' );

my $s = read_text( $inputfile, 'cp1252' );

my ( $outfh, $outputfile ) = tempfile();
binmode $outfh, ':encoding(utf8)';

print $outfh "Snowman! \x{2603}\n";
close $outfh;

done_testing;
