use strict;
use warnings;

use Test::More;
use Image::DS9;

BEGIN { plan( tests => 3 ) ;}

require 't/common.pl';


my $ds9 = start_up();
load_events( $ds9 );
$ds9->file( 'data/m31.fits.gz', { new => 1 } );

$ds9->blink();
ok( 1 == $ds9->blink('state'), "single" );
ok( 0 == $ds9->single('state'), "single; blink off");
ok( 0 == $ds9->tile('state'), "single; tile off");

$ds9->single(); # return to sanity


