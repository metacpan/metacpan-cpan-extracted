
use strict;
use warnings;

use Test::More 'no_plan';

use Image::Heatmap;
use_ok('Image::Heatmap');

ok( my $heatmap = Image::Heatmap->new() );
ok( $heatmap->map('blib/lib/Image/Heatmap/bolilla.png') );
ok( ! defined( Image::Heatmap::private::validate( $heatmap ) ) );
ok( -r $heatmap->colors() );
ok( -r $heatmap->plot_base() );
ok( -d $heatmap->tmp_dir() );

