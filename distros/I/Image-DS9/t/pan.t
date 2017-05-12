#! perl

use strict;
use warnings;

use Test::More tests => 1;
use Test::Deep;

use Image::DS9;

require 't/common.pl';

my $ds9 = start_up();
$ds9->file( 'data/m31.fits.gz' );

my @coords = qw( 00:42:41.377 +41:15:24.28 );
$ds9->pan( to => @coords, qw( wcs fk5) );

my @exp = ( re( qr/0?0:42:41.377/ ), '+41:15:24.28' );

cmp_deeply( scalar $ds9->pan( qw( wcs fk5 sexagesimal ) ), \@exp, 'pan', );
