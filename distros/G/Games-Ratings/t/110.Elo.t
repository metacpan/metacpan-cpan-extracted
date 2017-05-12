use strict;
use warnings;

use Games::Ratings::Chess::FIDE;

use Test::More tests => 1;

## test for a bug in FIDE.pm (present until version 0.0.4)

my %expected = (
                performance     => '2178',
               );
my $player = Games::Ratings::Chess::FIDE->new();
$player->set_rating(2250);
$player->set_coefficient(5);
my @opponent_ratings =   (2250,2250,2250,2250,2250,);
my @results          = qw(loss draw draw draw draw );
foreach my $game ( 0 .. $#results ) {
    $player->add_game( { opponent_rating => $opponent_ratings[$game],
                         result          => $results[$game], });  
}

my %computed;

## test 1: check performance
$computed{performance} = $player->get_performance();

## run actual tests for all test_items in %expected
foreach my $test_item ( sort keys %expected ) {
    is( $computed{$test_item}, $expected{$test_item}, 
        "$test_item: $computed{$test_item} -> $expected{$test_item}" );
}
