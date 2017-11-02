#! perl

use strict;
use warnings;

use Test::More tests => 2;
use Image::DS9;


require './t/common.pl';


my $ds9 = start_up();
$ds9->file( 'data/m31.fits.gz' );

SKIP: {
      skip 'pixeltable currently untestable', 2;

test_stuff( $ds9, (
                   pixeltable =>
                   [
                    [] => 'yes',
                    [] => 'no',
                   ],
                  ) );
}
