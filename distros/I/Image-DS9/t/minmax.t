#! perl

use strict;
use warnings;

use Test::More tests => 6;
use Image::DS9;

require 't/common.pl';

my $ds9 = start_up();
$ds9->file( 'data/m31.fits.gz' );

my @tests = (
    mode     => 'scan',
    mode     => 'datamin',
    mode     => 'irafmin',
    []       => 'scan',
    []       => 'datamin',
    []       => 'irafmin',
    (
        $ds9->version < 7.4
        ? (
            mode => 'sample',
            []   => 'sample',
          )
        : ()
    ),
);

test_stuff( $ds9, minmax => \@tests );

