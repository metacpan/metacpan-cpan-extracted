use Test;
BEGIN { plan tests => 15 }

use Games::Cards::Poker qw(:all);

ok(1);
my @hol0 = qw( As Ac );
my @hol1 = qw( Ad Kh );
my @hol2 = qw( Ah Kd );
my @bord = qw( 9s 3d Ks );
my @best = BestIndices(@hol0, @bord);
my @crdz = @hol0; push(@crdz, @bord);
my @hand = (); foreach(@best) { push(@hand, $crdz[$_]); }
my $scor = ScoreHand(@hand);
ok($scor, 3357);

$scor = ScoreHand(BestHand(BestIndices(@hol0, @bord), @hol0, @bord));
ok($scor, 3357);

$scor = ScoreHand(BestHand(@hol0, @bord));
ok($scor, 3357);

$scor = ScoreHand(BestHand(@hol1, @bord));
ok($scor, 3577);

@bord = qw( 9s 3d Ks 3c );
$scor = ScoreHand(BestHand(@hol0, @bord));
ok($scor, 2577);

$scor = ScoreHand(BestHand(@hol1, @bord));
ok($scor, 2698);

$scor = ScoreHand(BestHand(@hol2, @bord));
ok($scor, 2698);
@bord = qw( 9s 3d Ks 3c Kc );
$scor = ScoreHand(BestHand(@hol0, @bord));
ok($scor, 2470);

$scor = ScoreHand(BestHand(@hol1, @bord));
ok($scor, 188);

$scor = ScoreHand(BestHand(@hol2, @bord));
ok($scor, 188);

$scor = ScoreHand('AT944');
ok($scor, 5552);

$scor = ScoreHand('AT943s');
ok($scor, 708);

@hand = qw( As Ts 9s 4s 4h );
$scor = ScoreHand(\@hand);
ok($scor, 5552);

$hand[4] = '3s';
$scor = ScoreHand(\@hand);
ok($scor, 708);
