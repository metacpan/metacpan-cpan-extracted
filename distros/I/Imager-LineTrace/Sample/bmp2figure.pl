use v5.14;
use strict;
use warnings;
use Imager::LineTrace;

if ( (not @ARGV) or (not -e $ARGV[0]) ) {
    say "Usage:
    perl $0 file_path";
    exit( 0 );
}

my $img = Imager::LineTrace->new( file => $ARGV[0] ) or die Imager->errstr;
my $figures_ref = $img->line_trace();

my $i = 0;
foreach my $figure (@{$figures_ref}) {
    print "-------- [", $i++, "] --------", "\n";
    print "type        : ", $figure->{type}, "\n";
    print "trace_value : ", sprintf("0x%06X", $figure->{value}), "\n";
    print "is_closed   : ", $figure->{is_closed}, "\n";
    foreach my $p (@{$figure->{points}}) {
        printf( "(%2d,%2d)\n", $p->[0], $p->[1] );
    }
}
