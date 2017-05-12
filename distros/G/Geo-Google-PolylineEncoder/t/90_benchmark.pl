use strict;
use warnings;

use lib 'lib';
use lib 't/lib';

use Test::More;

BEGIN {
    if (!$ENV{BENCHMARK}) {
	plan( skip_all => '$ENV{BENCHMARK} not set' );
	exit 0;
    } else {
	plan( 'no_plan' );
    }
}

use IO::File;
use Benchmark;
# use Text::CSV_XS;  # don't use to minimize deps...
use_ok( 'Geo::Google::PolylineEncoder' );

# British Coastline data from:
# http://facstaff.unca.edu/mcmcclur/GoogleMaps/EncodePolyline/BritishCoastline.html
# (approx 50k points)
my $filename = 't/data/BritishShoreline.csv';
my $fh = IO::File->new( $filename );

my @points;
while (my $line = <$fh>) {
    chomp $line;
    my ($lat, $lon) = split( /\s*,\s*/, $line );
    push @points, { lat => $lat, lon => $lon };
}


my $encode_sub = sub {
    diag( 'encoding...' ); # this shouldn't affect stats too much
    my $encoder = Geo::Google::PolylineEncoder->new(zoom_factor => 2, num_levels => 18);
    my $eline   = $encoder->encode( \@points );
};

# run it 5 times, to get a fair test...
my $count = 5;
my $r1 = Benchmark::timethis( $count, $encode_sub );
my $encodes_per_sec = sprintf( '%.2f', iters_per_sec( $r1 ) );

my $num_points = scalar @points;
diag( "$count loops of encoding $num_points points took: ", timestr( $r1 ) );
diag( "encodes $encodes_per_sec polylines/sec" );


# this really belongs in Benchmark.pm:
sub iters_per_sec {
    my $benchmark = shift;
    eval { $benchmark->iters / ($benchmark->[1] + $benchmark->[2]) };
}
