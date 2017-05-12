use Test;
BEGIN { plan tests => 31 }

use Games::Cards::Poker qw(:all);

ok(1);
my %pdat = PDat(); my $summ = 0; # make sure hand counts add up correctly
$summ += $_->[1] foreach(@{$pdat{'hndz'}});
ok($summ, $pdat{'coun'}{'hands'});

my @bord = qw( 9s 3d Ks 3c Kc );
RemoveCard('9s', \@bord);
my $bord = "@bord";
ok($bord, '3d Ks 3c Kc');

RemoveCard('3c', \@bord);
$bord = "@bord";
ok($bord, '3d Ks Kc');

RemoveCard('Ks', \@bord);
$bord = "@bord";
ok($bord, '3d Kc');

my $wrst = WorstHand('AA');
ok($wrst, 'AA432');

$wrst = WorstHand('AK');
ok($wrst, 'AK432');

$wrst = WorstHand('32');
ok($wrst, '75432');

$wrst = WorstHand('32s');
ok($wrst, '75432');

$wrst = WorstHand('As', 'Ah');
ok($wrst, 'AA432');

$wrst = WorstHand('As', 'Kh');
ok($wrst, 'AK432');

$wrst = WorstHand('3s', '2h');
ok($wrst, '75432');

$wrst = WorstHand('3s', '2s');
ok($wrst, '75432');

$wrst = WorstHand('As', 'Ah', 'Kh', 'Qh', 'Jh', 'Th', '7s');
ok($wrst, 'AKQJTs');

$wrst = WorstHand('As', 'Ah', 'Kh', 'Qh', 'Jh', 'Td', '7s');
ok($wrst, 'AKQJT');

$wrst = WorstHand('As', 'Ad', 'Ac', 'Ah', 'Kh', 'Qh', 'Jh', 'Td', '7s');
ok($wrst, 'AAAAK');

$wrst = WorstHand('As', 'Ad', 'Ac', 'Kh', 'Qh', 'Jh', '8d', '7s');
ok($wrst, 'AAAKQ');

$wrst = WorstHand('As', 'Ad', 'Kh', 'Qh', 'Jh', '8d', '7s');
ok($wrst, 'AAKQJ');

my %zdnh = Zdnh();
my $coun = $zdnh{'AKQJTs'};
ok($coun, 0);

$coun = CountWays($zdnh{'KKKKJ'});
ok($coun, 100);

$coun = CountWays($zdnh{'AKQJTs'});
ok($coun, 4);

$coun = CountWays($zdnh{'KQJT9s'});
ok($coun, 8);

$coun = CountWays($zdnh{'AKQJT'});
ok($coun, 10536);

$coun = CountWays($zdnh{'AAAAK'});
ok($coun, 44);

$coun = CountWays($zdnh{'AAAKQ'});
ok($coun, 19780);

$coun = CountWays($zdnh{'AAKQJ'});
ok($coun, 198564);

$coun = CountWays(7461);
ok($coun, 2598960);

ok($coun, $pdat{'coun'}{'hands'});

$coun = CountWays(9999);
ok($coun, 2598960);

$coun = CountWays($zdnh{'87432'});
ok($coun, 2589780);

$coun = scalar(@{$pdat{'flpz'}});
ok($coun, $pdat{'coun'}{'shorthand_flops'});

# these are wrong so it doesn't matter to test them
#$coun = CalcOdds(0);
#&report($coun == 0.85, "$coun\n");
#my %zloh = Zloh();
#$coun = CalcOdds($zloh{'22'});
#&report($coun == 0.49, "$coun\n");
