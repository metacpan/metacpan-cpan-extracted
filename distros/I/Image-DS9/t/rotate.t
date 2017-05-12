use strict;
use warnings;

use Test::More tests => 4;
use Image::DS9;


require 't/common.pl';

my $ds9 = start_up();

$ds9->file( 'data/m31.fits.gz', { new => 1 }  );

$ds9->rotate( abs => 45 );
ok( $ds9->rotate == '45', 'rotate abs' );

$ds9->rotate( to => 45 );
ok( $ds9->rotate == '45', 'rotate to' );

$ds9->rotate( rel => 45 );
ok( $ds9->rotate == '90', 'rotate rel' );

$ds9->rotate( 45 );
ok( $ds9->rotate == '135', 'rotate' );

