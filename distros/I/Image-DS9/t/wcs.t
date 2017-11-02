use strict;
use warnings;

use Test::More tests => 68;
use Image::DS9;

require './t/common.pl';

my $ds9 = start_up();
$ds9->file( 'data/m31.fits.gz' );
$ds9->zoom(0);
$ds9->mode( 'crosshair' );

$ds9->wcs( 'reset' );

my @coords = qw( wcs fk5 );

my $coords = $ds9->crosshair( @coords );

my $wcs = "
  CRPIX1  =               257.75
  CRPIX2  =               258.93
  CRVAL1  =      -201.94541667302
  CRVAL2  =             -47.45444
  CDELT1  =        -2.1277777E-4
  CDELT2  =         2.1277777E-4
  CTYPE1  = 'RA---TAN'
  CTYPE2  = 'DEC--TAN'
";

$ds9->wcs( 'reset' );
$ds9->wcs( replace => $wcs );
my $ncoords = $ds9->crosshair( @coords );
ok( ! eq_array( $coords, $ncoords ), 'wcs scalar' );
$ds9->wcs( 'reset' );
ok( eq_array( $coords, scalar $ds9->crosshair( @coords ) ), 'wcs reset' );

$ds9->wcs( 'reset' );
$ds9->wcs( replace => \$wcs );
ok( eq_array( $ncoords, scalar $ds9->crosshair( @coords ) ), 'wcs scalarref' );

my @wcs = split(/\n/, $wcs );

$ds9->wcs( 'reset' );
$ds9->wcs( replace => \@wcs );
ok( eq_array( $ncoords, scalar $ds9->crosshair( @coords ) ), 'wcs arrayref' );

my %wcs =
   (
    CRPIX1  =>               257.75,
    CRPIX2  =>               258.93,
    CRVAL1  =>      -201.94541667302,
    CRVAL2  =>             -47.45444,
    CDELT1  =>        -2.1277777E-4,
    CDELT2  =>         2.1277777E-4,
    CTYPE1  => 'RA---TAN',
    CTYPE2  => 'DEC--TAN',
   );

$ds9->wcs( 'reset' );
$ds9->wcs( replace => \%wcs );
ok( eq_array( $ncoords, scalar $ds9->crosshair( @coords ) ), 'wcs hashref' );


test_stuff( $ds9, (
                   wcs =>
                   [
                    ( map { ( system => $_ ) }
                      ( (map { 'wcs' . $_ } ('a'..'z')), 'wcs' )
                    ),
                    ( map { ( [] => $_ ) }
                      ( (map { 'wcs' . $_ } ('a'..'z')), 'wcs' )
                    ),
                    ( map { (sky => $_) }
                         qw( fk4 icrs galactic ecliptic fk5 )
                    ),
                    ( map { (skyformat => $_) }
                         qw( degrees sexagesimal )
                    ),
                    align => 1,
                    align => 0,
                   ],
                  ) );
