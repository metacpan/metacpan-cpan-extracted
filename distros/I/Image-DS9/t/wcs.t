#! perl

use v5.10;
use strict;
use warnings;

use Test2::V0;
use Image::DS9;
use Image::DS9::Constants::V1
  -sky_coord_systems,
  'SKY_COORD_SYSTEMS',
  'ANGULAR_FORMATS',
  'WCS',
  ;

use Test::Lib;
use My::Util;
use Path::Tiny;

my $ds9 = start_up( image => 1 );
$ds9->zoom( 0 );
$ds9->mode( 'crosshair' );

$ds9->wcs( 'reset' );

# nameserver ned-sao seems to be broken
$ds9->nameserver( server => 'ned-cds' );

my @coords = ( wcs => SKY_COORDSYS_FK5 );

my $coords = $ds9->crosshair( @coords );

# the leading spaces are there on purpose to
# make sure that the string cleanup conversion for
# replace & append works.
my $wcs = <<'END';
  CRPIX1  =               257.75
  CRPIX2  =               258.93
  CRVAL1  =      -201.94541667302
  CRVAL2  =             -47.45444
  CDELT1  =        -2.1277777E-4
  CDELT2  =         2.1277777E-4
  CTYPE1  = 'RA---TAN'
  CTYPE2  = 'DEC--TAN'
END

$ds9->wcs( 'reset' );
$ds9->wcs( replace => $wcs );
my $ncoords = $ds9->crosshair( @coords );
isnt( $coords, $ncoords, 'wcs scalar' );
$ds9->wcs( 'reset' );
is( $coords, scalar $ds9->crosshair( @coords ), 'wcs reset' );

$ds9->wcs( 'reset' );
$ds9->wcs( replace => \$wcs );
is( $ncoords, scalar $ds9->crosshair( @coords ), 'wcs scalarref' );

my @wcs = split( /\n/, $wcs );

$ds9->wcs( 'reset' );
$ds9->wcs( replace => \@wcs );
is( $ncoords, scalar $ds9->crosshair( @coords ), 'wcs arrayref' );

my %wcs = (
    CRPIX1 => 257.75,
    CRPIX2 => 258.93,
    CRVAL1 => -201.94541667302,
    CRVAL2 => -47.45444,
    CDELT1 => -2.1277777E-4,
    CDELT2 => 2.1277777E-4,
    CTYPE1 => 'RA---TAN',
    CTYPE2 => 'DEC--TAN',
);

$ds9->wcs( 'reset' );
$ds9->wcs( replace => \%wcs );
is( $ncoords, scalar $ds9->crosshair( @coords ), 'wcs hashref' );

subtest 'load/save' => sub {

    # here we have to remove the leading spaces from the WCS above or
    # it won't work
    my $wcsfile = Path::Tiny->tempfile;
    ( my $fixed_wcs = $wcs ) =~ s/^\s+//mg;
    $wcsfile->spew( $fixed_wcs );
    $ds9->wcs( 'reset' );
    $ds9->wcs( load => $wcsfile->stringify );
    my $ncoords = $ds9->crosshair( @coords );
    isnt( $coords, $ncoords, 'wcs scalar' );
    $ds9->wcs( 'reset' );
    is( $coords, scalar $ds9->crosshair( @coords ), 'wcs reset' );
};

test_stuff(
    $ds9,
    (
        wcs => [
            ( map { ( system => $_ ) } WCS ),
            ( map { ( []     => $_ ) } WCS ),
            ( map { ( sky    => $_ ) } grep { !/^(?:B1950|J2000)/i } SKY_COORD_SYSTEMS ),
            sky => { out => ['j2000'], in => ['fk5'] },
            sky => { out => ['b1950'], in => ['fk4'] },
            ( map { ( skyformat => $_ ) } ANGULAR_FORMATS ),
            align => !!1,
            align => !!0,
        ],
    ) );

done_testing;
