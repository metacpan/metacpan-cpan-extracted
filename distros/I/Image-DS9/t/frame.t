use strict;
use warnings;

use Test::More;
use Image::DS9;

BEGIN { 
	plan( tests => 9 );
      }

require 't/common.pl';

my $ds9 = start_up();
clear($ds9);

$ds9->frame(3);
ok( 3 == $ds9->frame(), "frame create" );

$ds9->frame(4);
ok( 4 == $ds9->frame(), "frame create" );

ok( eq_array([ 1, 3, 4 ], scalar $ds9->frame('all')), 'frame all' );

$ds9->frame( 'first' );
ok( 1 == $ds9->frame(), "frame first" );

$ds9->frame( 'last' );
ok( 4 == $ds9->frame(), "frame last" );

$ds9->frame( 'prev' );
ok( 3 == $ds9->frame(), "frame prev" );

$ds9->frame( 'next' );
ok( 4 == $ds9->frame(), "frame next" );

# avoid strange timing crash on some X servers
sleep(1);

$ds9->frame( 'delete' );
ok( 3 == $ds9->frame(), "frame delete" );

$ds9->frame( 'new' );
ok( 5 == $ds9->frame(), "frame new" );

