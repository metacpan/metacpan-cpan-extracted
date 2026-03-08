use strict;
use warnings;
use Test::More 'no_plan';
use FindBin;
use lib "$FindBin::Bin/../lib";
use Graphics::Penplotter::GcodeXY;

my $g = Graphics::Penplotter::GcodeXY->new();
ok($g, 'constructed object');
$g->newpath();

ok( $g->polygon_clip(0,0, 10,0, 10,10, 0,10, 0,0), 'add first polygon_clip' );
ok( $g->polygon_clip(5,-5, 15,-5, 15,5, 5,5, 5,-5), 'add overlapping polygon_clip' );
ok( $g->polygon_clip_end(), 'flush clip queue' );

done_testing();
