use strict;
use warnings;
use Test::More;
use Test::Exception;
use Test::Deep;
use Clone qw/clone/;

use blib;

use_ok 'Image::SVG::Transform';

##simple transform
my $trans = Image::SVG::Transform->new();
$trans->extract_transforms('translate(1,1)');
is_deeply $trans->transforms, [ { type => 'translate', params => [1,1], } ], 'checking setup for transform';

my $ctm = $trans->ctm();
cmp_deeply dump_matrix( $ctm ),
          [
            [ 1, 0, 1 ],
            [ 0, 1, 1 ],
            [ 0, 0, 1 ],
          ],
          'Getting the combined transform matrix for a single transform';

my $view1 = $trans->transform([2, 2]);
is_deeply $view1, [ 3, 3 ], 'Translate from 2,2 to 3,3';

my $view2 = $trans->transform([6, 9]);
is_deeply $view2, [ 7, 10 ], 'Translate from 6,9 to 7,10';
is_deeply $trans->untransform([2, 3]), [ 1, 2], 'untranslate from 2,3 to 0,1';

$trans->extract_transforms("translate(5)");
my $view3 = $trans->transform([10, 10]);
is_deeply $view3, [15, 10], 'X-only translation from 10,10 to 15,10';

$trans->extract_transforms("translate(5,10)");
my $view3a = $trans->transform([10, 10]);
is_deeply $view3a, [15, 20], 'X&Y translation from 10,10 to 15,20';

$trans->extract_transforms("scale(3)");
my $view4 = $trans->transform([12, 7]);
is_deeply $view4, [36, 21], '3X scaling from 12,7 to 36,21';

my $user4 = $trans->untransform([6,6]);
is_deeply $user4, [2, 2], 'untransform 3X scaling from 6,6 to 2,2';

$trans->extract_transforms("scale(2,4)");
my $view5 = $trans->transform([4, 4]);
is_deeply $view5, [8, 16], '2,4 scaling from 4,4 to 8,16';

$trans->extract_transforms("rotate(90.0)");
my $view6 = $trans->transform([4, 0]);
cmp_ok abs($view6->[0]-0), '<=', 1e-6, 'checking approximate x coordinate for 90 degree rotation';
cmp_ok abs($view6->[1]-4), '<=', 1e-6, 'checking approximate y coordinate for 90 degree rotation';

done_testing();

sub dump_matrix {
    my $matrix = shift;
    my $dumped = [ ];
    $dumped->[0] = clone $matrix->[0];
    $dumped->[1] = clone $matrix->[1];
    $dumped->[2] = clone $matrix->[2];
    return $dumped;
}
