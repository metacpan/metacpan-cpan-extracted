#! perl
use strict;
use warnings;

use Test::More tests => 2;
use Test::Deep;

use Image::DS9;

require './t/common.pl';

my $ds9 = start_up();
$ds9->file( 'data/m31.fits.gz' );

$ds9->crosshair( 0, 0, 'image' );
cmp_deeply( [0, 0],
            scalar $ds9->crosshair( 'image' ),
            'crosshair'
          );

my @coords = qw( 00:42:41.399 +41:15:23.78 );
$ds9->crosshair( @coords, wcs => 'fk5');

my @exp = ( re( qr/0?0:42:41.399/ ), re( qr/\+41:15:23.780?/ ) );

cmp_deeply( scalar $ds9->crosshair( qw[ wcs fk5 sexagesimal ] ),
            \@exp,
            'crosshair'
          );
