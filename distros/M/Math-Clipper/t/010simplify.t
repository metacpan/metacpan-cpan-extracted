use strict;
use warnings;

use Math::Clipper ':all';
use Test::More tests => 4;

my $p1 = [
    [1,1],
    [3,3],
    [3,1],
    [1,3]
];

my $p2 = [
    [0,0],
    [4,0],
    [4,4],
    [0,4],
];

{
    my $simplified = simplify_polygon($p1, PFT_EVENODD);
    is scalar(@$simplified), 2, 'simplify_polygon returned 2 polygons';
    is scalar(grep !orientation($_), @$simplified), 0, 'simplified polygons are ccw';
}

# check that the same simplified polygons are returned as holes now
{
    my $simplified = simplify_polygons([$p1, $p2], PFT_EVENODD);
    is scalar(@$simplified), 3, 'simplify_polygon returned 3 polygons';
    is scalar(grep !orientation($_), @$simplified), 2, '2 out of 3 polygons are cw (holes)';
}

__END__
