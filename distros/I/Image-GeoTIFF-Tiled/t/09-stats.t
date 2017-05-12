#!/usr/bin/perl
use strict;
use warnings;
use Test::More tests => 9;
use File::Basename;
use Image::GeoTIFF::Tiled;

# Computes stats emitted from gdalinfo -stats
# NOTE: Skipping big images for now

my %s = (
    'NED_89026470_t.tif' => {
        STATISTICS_MINIMUM => -1.0598638057709,
        STATISTICS_MAXIMUM => 36.374229431152,
        STATISTICS_MEAN    => 8.1929194331697,
        STATISTICS_STDDEV  => 7.3135221485853,
    },
    'usgs1_.tif' => {
        STATISTICS_MINIMUM => 0,
        STATISTICS_MAXIMUM => 12,
        STATISTICS_MEAN    => 4.10170243,
        STATISTICS_STDDEV  => 1.89868687,
    },
    # SKIP to expedite testing:
    # 'usgs2_.tif' => {
        # STATISTICS_MINIMUM => 0,
        # STATISTICS_MAXIMUM => 12,
        # STATISTICS_MEAN    => 4.79840314,
        # STATISTICS_STDDEV  => 0.88186109,
    # }
);

$| = 1;
for my $file ( <./t/samples/*.tif> ) {
    # print "Raster: $file\n";
    my $tif = Image::GeoTIFF::Tiled->new( $file );
    # $tif->print_meta();
    # print "Tile(134):\n";
    # $tif->dump_tile(134);
    my $stats = $s{ basename( $file ) };
    next unless $stats;
    # my @data;
    my ( $min, $max );
    my ( $sum, $n ) = ( 0, 0 );
    my $ntiles = $tif->number_of_tiles;
    # for ( 0 .. $ntiles - 1 ) {
    # my $iter = $tif->get_iterator( $_ );
    print "Getting $ntiles tiles of data...\n";
    my $iter = $tif->get_iterator( 0, $ntiles - 1 );
    while ( defined( my $v = $iter->next ) ) {
        $n++;
        $sum += $v;
        $min = $v unless defined $min and $min <= $v;
        $max = $v unless defined $max and $max >= $v;
    }
    # }
    # print "Min: $min\nMax: $max\nSum: $sum\nN: $n\n";
    is( $n,             $tif->length * $tif->width,               'n' );
    is( _round( $min ), _round( $stats->{ STATISTICS_MINIMUM } ), 'min' );
    is( _round( $max ), _round( $stats->{ STATISTICS_MAXIMUM } ), 'max' );
    my $mean = $sum / $n;
    is( _round( $mean ), _round( $stats->{ STATISTICS_MEAN } ), 'mean' );

    if ( $file =~ /NED_/ ) {
        # Bigger images too slow for testing
        my $sd = 0;
        for ( 0 .. $tif->number_of_tiles - 1 ) {
            my $iter = $tif->get_iterator( $_ );
            while ( defined( my $v = $iter->next ) ) {
                $sd += ( $v - $mean )**2;
            }
        }
        $sd = sqrt( 1 / $n * $sd );
        is( _round( $sd ), _round( $stats->{ STATISTICS_STDDEV } ), 'sd' );
    }
    # ( $min, $max ) = _minmax( \@data );
    # my $mean = _mean( \@data );
    # $sd = _sd( \@data, $mean );
    # last;
} ## end for my $file ( <./t/samples/*.tif>)

sub _minmax {
    my $data = shift;
    my ( $min, $max );
    for ( @$data ) {
        $min = $_ unless defined $min and $min <= $_;
        $max = $_ unless defined $max and $max >= $_;
    }
    ( $min, $max );
}

sub _mean {
    my $data = shift;
    my $sum  = 0;
    $sum += $_ for @$data;
    $sum / @$data;
}

sub _sd {
    my ( $data, $mean ) = @_;
    my $n = 0;
    $n += ( $_ - $mean )**2 for @$data;
    sqrt( $n / @$data );
}

sub _round { sprintf "%.6f", $_[ 0 ]; }
