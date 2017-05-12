use strict;
use warnings;
use Test::More;
use Test::Exception;
use Test::Deep;

use blib;

use_ok 'Image::SVG::Transform';

##simple transform
my $trans = Image::SVG::Transform->new();
$trans->extract_transforms('translate(1,1) scale(2)');
is_deeply
    $trans->transforms,
    [
        { type => 'translate', params => [1,1], },
        { type => 'scale', params => [2], }
    ],
    'checking setup for transform';

my $ctm = $trans->ctm();
cmp_deeply dump_matrix( $ctm ),
          [
            [ 2, 0, 1 ],
            [ 0, 2, 1 ],
            [ 0, 0, 1 ],
          ],
          'Getting the combined transform matrix for a double transform';

my $view1 = $trans->transform([0, 0]);
is_deeply $view1, [ 1, 1 ], 'Translate and scale from 0,0 to 1,1';

##Now, reverse the order and apply the same point
$trans->extract_transforms('scale(2) translate(1,1)');
my $view2 = $trans->transform([0,0]);
is_deeply $view2, [ 2, 2 ], 'scale and translate from 0,0 to 2,2';

$trans->extract_transforms('translate(50,90) rotate(-45) translate(130,160)');
#diag explain dump_matrix($trans->ctm);
my $reference = Math::Matrix->new(
    [ 0.707,  0.707, 255.03],
    [-0.707,  0.707, 111.21],
    [     0,      0,      1],
);
$Math::Matrix::eps = 0.1;
ok $trans->ctm->equal($reference), 'Checking SVG spec example';

done_testing();

sub dump_matrix {
    my $matrix = shift;
    my $dumped = [ ];
    $dumped->[0] = clone $matrix->[0];
    $dumped->[1] = clone $matrix->[1];
    $dumped->[2] = clone $matrix->[2];
    return $dumped;
}
