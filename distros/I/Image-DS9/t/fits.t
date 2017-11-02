#! perl

use strict;
use warnings;

use Test::More tests => 2;
use Image::DS9;
use Test::Fatal;

require './t/common.pl';

my $ds9 = start_up();
load_events( $ds9 );

my $fitsimg;
is(
    exception {
        $fitsimg = $ds9->fits( 'image', 'gz' );
    },
    undef,
    "fits image gz get"
);

SKIP: {
    skip "unable to proceed without an image", 1 unless defined $fitsimg;
    is(
        exception {
            $ds9->fits( $fitsimg, { new => 1 } );
        },
        undef,
        "fits image gz set"
    );

}
