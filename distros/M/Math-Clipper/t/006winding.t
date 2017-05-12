use Math::Clipper ':all';
use Test::More tests => 4;

my $ccw = [
[0,0],
[4,0],
[4,4],
[0,4]
];
my $cw = [
[0,0],
[0,4],
[4,4],
[4,0]
];
my $tricky = [
[0,0],
[40,40],
[40,0],
[0,41]
];

ok(   orientation($ccw)    , 'is_ccw on a counter-clockwise polygon');
ok( ! orientation($cw)     , 'is_ccw on a clockwise polygon');
ok(   orientation($tricky) , 'is_ccw on a bowtie polygon');

is( is_counter_clockwise($ccw), orientation($ccw), 'is_counter_clockwise() === orientation()');
