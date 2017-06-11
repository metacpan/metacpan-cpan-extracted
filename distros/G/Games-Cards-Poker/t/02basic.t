#!/usr/bin/perl
use warnings;use Test::More;
BEGIN { plan tests => 15 }
eval 'use Games::Cards::Poker qw(:all)';
use_ok(  'Games::Cards::Poker');
my @deck = Deck();
ok(@deck ==  52 , 'check new deck size');

my $card = $deck[0];
ok($card eq 'As', 'first  card As');

$card = $deck[3];
ok($card eq 'Ac', 'fourth card Ac');

$card = $deck[4];
ok($card eq 'Ks', 'fifth  card Ks');

$card = $deck[51];
ok($card eq '2c', 'last   card 2c');

my @hand = qw( 4c 9d Td 4s Ah );
SortCards(\@hand);
$card = $hand[0];
ok($card eq 'Ah', 'SortCards and check first is Ah');

$card = $hand[1];
ok($card eq 'Td', '  second Td');

$card = $hand[2];
ok($card eq '9d', '  third  9d');

$card = $hand[3];
ok($card eq '4s',  ' fourth 4s');

$card = $hand[4];
ok($card eq '4c',  ' fifth  4c');

my $shrt =                     ShortHand(@hand)  ;
ok($shrt eq 'AT944', 'ShortHand AT944');

my $scor =           HandScore(          @hand ) ;
ok($scor ==   5552 , 'HandScore           5552');

   $scor =           HandScore(ShortHand(@hand)) ;
ok($scor ==   5552 , 'HndScr(ShortHand()) 5552');

   $shrt = ScoreHand(HandScore(ShortHand(@hand)));
ok($shrt eq 'AT944', 'roundtrip ScoreHand(HandScore(ShortHand())) AT944');
