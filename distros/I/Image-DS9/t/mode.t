use strict;
use warnings;

use Test::More tests => 9;
use Image::DS9;

require 't/common.pl';

my $ds9 = start_up();
$ds9->file( 'data/m31.fits.gz' );

my @modes = qw[ none region crosshair colorbar pan zoom rotate catalog examine ];

test_stuff( $ds9, (
		   mode => [ map { [] => $_ } @modes ],
		  ) );

