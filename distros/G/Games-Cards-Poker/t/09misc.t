#!/usr/bin/perl
use warnings;use Test::More;
BEGIN { plan tests => 48 }
use     Games::Cards::Poker qw(:all);
use_ok('Games::Cards::Poker');
my $summ = 0; # make sure hand counts add up correctly
for(@{$pd8a{'hndz'}}){ $summ += CountWays($zdnh{$_},$zdnh{$_},'hndz'); }
ok($summ == $pd8a{'coun'}{'hands'}, "summing CountWays for hands to $summ");
my @bord = qw( 9s 3d Ks 3c Kc );
RemoveCard('9s', \@bord);
my $bord = "@bord";
ok($bord eq '3d Ks 3c Kc'         , "test RemoveCard(9s) from a hand");
RemoveCard('3c', \@bord);
   $bord = "@bord";
ok($bord eq '3d Ks Kc'            , "test RemoveCard(3c) from a hand");
RemoveCard('Ks', \@bord);
   $bord = "@bord";
ok($bord eq '3d Kc'               , "test RemoveCard(Ks) from a hand");
my $wrst = WorstHand('AA');
ok($wrst eq 'AA432'               , "WorstHand(AA ) to $wrst");
   $wrst = WorstHand('AK');
ok($wrst eq 'AK432'               , "WorstHand(AK ) to $wrst");
   $wrst = WorstHand('32');
ok($wrst eq '75432'               , "WorstHand(32 ) to $wrst");
   $wrst = WorstHand('32s');
ok($wrst eq '75432'               , "WorstHand(32s) to $wrst");
   $wrst = WorstHand('As', 'Ah');
ok($wrst eq 'AA432'               , "WorstHand(As Ah) to $wrst");
   $wrst = WorstHand('As', 'Kh');
ok($wrst eq 'AK432'               , "WorstHand(As Kh) to $wrst");
   $wrst = WorstHand('3s', '2h');
ok($wrst eq '75432'               , "WorstHand(3s 2h) to $wrst");
   $wrst = WorstHand('3s', '2s');
ok($wrst eq '75432'               , "WorstHand(3s 2s) to $wrst");
   $wrst = WorstHand('As', 'Ah', 'Kh', 'Qh', 'Jh', 'Th', '7s');
ok($wrst eq 'AKQJTs'              , "WorstHand(As Ah Kh Qh Jh Th 7s) to $wrst");
   $wrst = WorstHand('As', 'Ah', 'Kh', 'Qh', 'Jh', 'Td', '7s');
ok($wrst eq 'AKQJT'               , "WorstHand(As Ah Kh Qh Jh Td 7s) to $wrst");
   $wrst = WorstHand('As', 'Ad', 'Ac', 'Ah', 'Kh', 'Qh', 'Jh', 'Td', '7s');
ok($wrst eq 'AAAAK'               , "WorstHand(As Ad Ac Ah Kh Qh Jh Td 7s) to $wrst");
   $wrst = WorstHand('As', 'Ad', 'Ac', 'Kh', 'Qh', 'Jh', '8d', '7s');
ok($wrst eq 'AAAKQ'               , "WorstHand(As Ad Ac Kh Qh Jh 8d 7s) to $wrst");
   $wrst = WorstHand('As', 'Ad', 'Kh', 'Qh', 'Jh', '8d', '7s');
ok($wrst eq 'AAKQJ'               , "WorstHand(As Ad Kh Qh Jh 8d 7s) to $wrst");
my $coun =           $zdnh{'AKQJTs'};
ok($coun ==       0               , "          zdnh{AKQJTs}  to $coun");
   $coun = CountWays($zdnh{'KKKKJ' });
ok($coun ==     100               , "CountWays(zdnh{KKKKJ }) to $coun");
   $coun = CountWays($zdnh{'AKQJTs'});
ok($coun ==       4               , "CountWays(zdnh{AKQJTs}) to $coun");
   $coun = CountWays($zdnh{'KQJT9s'});
ok($coun ==       8               , "CountWays(zdnh{KQJT9s}) to $coun");
   $coun = CountWays($zdnh{'AKQJT'});
ok($coun ==   10536               , "CountWays(zdnh{AKQJT }) to $coun");
   $coun = CountWays($zdnh{'AAAAK'});
ok($coun ==      44               , "CountWays(zdnh{AAAAK }) to $coun");
   $coun = CountWays($zdnh{'AAAKQ'});
ok($coun ==   19780               , "CountWays(zdnh{AAAKQ }) to $coun");
   $coun = CountWays($zdnh{'AAKQJ'});
ok($coun ==  198564               , "CountWays(zdnh{AAKQJ }) to $coun");
   $coun = CountWays(7461);
ok($coun == 2598960               , "CountWays(      7461  ) to $coun");
ok($coun == $pd8a{'coun'}{'hands'}, "match pd8a count of hands: $coun");
   $coun = CountWays(9999);
ok($coun == 2598960               , "CountWays(      9999  ) to $coun");
   $coun = CountWays($zdnh{'87432'});
ok($coun == 2589780               , "CountWays(zdnh{87432 }) to $coun");
   $coun = scalar(@{$pd8a{'flpz'}});
ok($coun == $pd8a{'coun'}{'shorthand_flops'}, "size of pd8a{flops} to shorthand count:$coun");

# these are wrong so it doesn't matter to test them
#$coun = CalcOdds(0);
#&report($coun == 0.85, "$coun\n");
#$coun = CalcOdds($zloh{'22'});
#&report($coun == 0.49, "$coun\n");

# this was errantly returning AA222 FullHouse reported from Iain at HTTPS://RT.CPAN.Org/Public/Bug/Display.html?id=100391 so making new test for it
   $wrst = WorstHand('As', '2s');
ok($wrst eq 'A6432'               , "WorstHand(As 2s) to $wrst");

for(0..15){my $sabb='';my $deck= join('','A'..'Z','a'..'z');my $rndx= int(rand(462)) + 6000; # try just l8 midl bordz?
# $sabb=$pd8a{'sabb'}[$rndx];for my $bchr (split(//,$sabb)){$deck=~ s/$bchr//;} # old loading random index of SuitAbstractB64Boardz
  while(length($sabb) < (3+int(rand(3)))){$sabb .= substr($deck,int(rand(length($deck))),1,'');} # just 3 flop, 4 turn, or full 5 seem to all work well,but!>5
  $sabb  = join('',sort(split(//,$sabb))); # pick 5 randoms && re-sort before looking for Nuts, maybe better results than using rndx?
   @bstr = FindNuts($sabb); # this is kinda slow for 5 boards, but still should only take a few seconds for each test
ok(@bstr == 3, sprintf("FindNuts sabb:%-5s scor:%4d size:%4d bstr:%s",$sabb,shift(@bstr),shift(@bstr),join(' ',@bstr)));}
