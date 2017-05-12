use strict;
use warnings;

use Games::Ratings::Chess::FIDE;

use Test::More tests => 1;

## see the following link for performance calculation (player Magnus Carlsen)
## * http://www.chess.co.uk/twic/chessnews/events/london-chess-classic-2009

my %expected = (
                performance     => '2839',
               );
my $player = Games::Ratings::Chess::FIDE->new();
$player->set_rating(2801);
$player->set_coefficient(10);
my @opponent_ratings =   (2772,2597,2698,2615,2665,2715,2707);
my @results          = qw(win  draw draw win  win  draw draw);
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



