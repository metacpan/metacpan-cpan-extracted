#!/usr/bin/perl
use warnings;use Test::More;
BEGIN { plan tests => 16 }
use     Games::Cards::Poker qw(:all);
use_ok('Games::Cards::Poker');
my @hol0 = qw( As Ac );
my @hol1 = qw( Ad Kh );
my @hol2 = qw( Ah Kd );
my @bord = qw( 9s 3d Ks );
my @best = BestIndices(@hol0, @bord);
my @crdz = @hol0; push(@crdz, @bord);
my @hand = ();     for(@best){push(@hand,$crdz[$_]);}
my $scor = HandScore(@hand);
ok($scor == 3357, 'HandScore               3357');

   $scor = HandScore(ScoreHand($scor));
ok($scor == 3357, 'HandScore(ScoreHand())  3357');

$scor = HandScore(BestHand(BestIndices(@hol0, @bord), @hol0, @bord));
ok($scor == 3357, 'Score of BestH of BestI 3357');

$scor = HandScore(BestHand(@hol0, @bord));
ok($scor == 3357, 'Score of BestHand       3357');

$scor = HandScore(BestHand(@hol1, @bord));
ok($scor == 3577, 'Score of BestHand hol1  3577');

@bord = qw( 9s 3d Ks 3c );
$scor = HandScore(BestHand(@hol0, @bord));
ok($scor == 2577, 'Score of BestHand hol0  2577');

$scor = HandScore(BestHand(@hol1, @bord));
ok($scor == 2698, 'Score of BestHand hol1  2698');

$scor = HandScore(BestHand(@hol2, @bord));
ok($scor == 2698, 'Score of BestHand hol2  2698');
@bord = qw( 9s 3d Ks 3c Kc );
$scor = HandScore(BestHand(@hol0, @bord));
ok($scor == 2470, 'HandScor(BestHand hol0) 2470');

$scor = HandScore(BestHand(@hol1, @bord));
ok($scor ==  188, 'HandScor(BestHand hol1)  188');

$scor = HandScore(BestHand(@hol2, @bord));
ok($scor ==  188, 'HandScor(BestHand hol2)  188');

$scor = HandScore('AT944');
ok($scor == 5552, 'HandScore AT944         5552');

$scor = HandScore('AT943s');
ok($scor ==  708, 'HandScore AT943s         708');

@hand = qw( As Ts 9s 4s 4h );
$scor = HandScore(\@hand);
ok($scor == 5552, 'HandScore    hand       5552');

$hand[4] = '3s';
$scor = HandScore(\@hand);
ok($scor ==  708, 'HandScore    hand        708');
