use strict;
use warnings;

use Test::More tests => 5;
use Image::DS9;

require 't/common.pl';

my $ds9 = start_up();

$ds9->file( 'data/m31.fits.gz', { new => 1 }  );

$ds9->zoom( to => 'fit' );
my $zval = $ds9->zoom;

$ds9->zoom( to => 1);
ok( 1 == $ds9->zoom, 'zoom to' );

$ds9->zoom( abs => 2);
ok( 2 == $ds9->zoom, 'zoom abs' );

$ds9->zoom( rel => 2);
ok( 4 == $ds9->zoom, 'zoom rel' );

$ds9->zoom( 0.5);
ok( 2 == $ds9->zoom, 'zoom' );

$ds9->zoom( 0 );
ok( $zval == $ds9->zoom, 'zoom 0' );

