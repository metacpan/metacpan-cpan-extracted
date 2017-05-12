
#!perl -T
$|=1;

my $loops;
BEGIN {
    $loops = 3;
    }

use Test::More tests => (($loops - 1) * 5) + 4 + 1;
use Math::Geometry::Delaunay qw(TRI_CONSTRAINED TRI_VORONOI);

my $tri = Math::Geometry::Delaunay->new();
$tri->quiet(1);

SKIP: {

eval('require Devel::Size');
diag('skip unless Devel::Size installed') if $@;
skip 'skip memory leak test', ((($loops - 1) * 5) + 4) if $@;

my $size = 0;
my $prevsize = 0;

for (my $i=0;$i<$loops;$i++) {
    my $el = [];
    my $cnt = 100000;
    my $step=3.14159/$cnt;
    $el->[$cnt] = [];
    for (0..$cnt) {
        $el->[$_] = [100009*cos($_*$step),100009*sin($_*$step)];
        }

    my $before_size = Devel::Size::total_size($tri);
    $tri->addPolygon($el);
    my $full_size = Devel::Size::total_size($tri);
    $tri->triangulate(TRI_CONSTRAINED,'e');
    my $after_size = Devel::Size::total_size($tri);

    if ( $i > 0 ) { 
        ok($before_size > 0, "loop $i: object has size: $size");
        ok($before_size < $full_size, "loop $i: object bigger after geometry loaded: $before_size < $full_size");
        ok($full_size > $after_size, "loop $i: object smaller after geometry transfered to C struct:$full_size > $after_size");
        ok($before_size == $after_size, "loop $i: object the same size before and after geometry load and unload: $before_size == $after_size");
        ok($after_size == $prevsize, "loop $i: reused object is not growing: $size == $prevsize");
        }
    $prevsize = $after_size;
}

my $before_size = Devel::Size::total_size($tri);
$tri->addPolygon([[0,1],[1,2],[4,4]]);
my $full_size = Devel::Size::total_size($tri);
$tri->reset();
my $after_size = Devel::Size::total_size($tri);
ok($before_size > 0, "object has size: $size");
ok($before_size < $full_size, "object bigger after geometry loaded: $before_size < $full_size");
ok($full_size > $after_size, "object smaller after geometry transfered to C struct:$full_size > $after_size");
ok($before_size == $after_size, "object the same size before and after geometry load and unload: $before_size == $after_size");

};

ok(1);

