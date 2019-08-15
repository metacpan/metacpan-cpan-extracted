use 5.012;
use warnings;
use Test::More;
use Test::Warnings;

use Geo::Geos::IntersectionMatrix;
use Geo::Geos::Dimension qw/TYPE_DONTCARE TYPE_True TYPE_False TYPE_P TYPE_L TYPE_A/;

my $im1 = Geo::Geos::IntersectionMatrix->new;
ok $im1;

my $im2 = Geo::Geos::IntersectionMatrix->new('T*T******');
ok $im2;
is $im2->toString, 'T*T******';

$im2->set('TTT******');
is "$im2", 'TTT******';

$im2->set(2,2,TYPE_False);
is "$im2", 'TTT*****F';
is $im2->get(2,2), TYPE_False;

$im2->setAll(TYPE_DONTCARE);
is "$im2", '*********';

ok $im2->matches('*********');

$im2->setAtLeast(2,2,TYPE_True);
is "$im2", '********T';

$im2->setAtLeast('FFFFFFFFF');
is "$im2", 'FFFFFFFFF';

$im2->setAtLeastIfValid(2,2,TYPE_L);
is "$im2", 'FFFFFFFF1';

ok $im2->isDisjoint;
ok !$im2->isIntersects;
ok !$im2->isWithin;
ok !$im2->isContains;
ok !$im2->isCovers;
ok !$im2->isCoveredBy;

ok !$im2->isTouches(TYPE_A, TYPE_A);
ok !$im2->isCrosses(TYPE_A, TYPE_A);
ok !$im2->isEquals(TYPE_A, TYPE_A);
ok !$im2->isOverlaps(TYPE_A, TYPE_A);

my $im3 = Geo::Geos::IntersectionMatrix->new('*T*******');
is($im3->transpose->toString, '***T*****');

done_testing;
