#! perl

use strict;
use warnings;

use Test::More tests => 6;
use Image::DS9;
use Cwd;

require './t/common.pl';

my $ds9 = start_up();

for my $server ( qw[ dsssao dsseso dssstsci ] ) {
    test_stuff(
        $ds9,
        (
            $server => [
                size => [ 10, 10, 'arcmin' ],
                name => 'NGC5846'
            ],
        ) );

    $ds9->$server( 'close' );
}
