package Games::Tournament::BlackJack::Player::ExamplePlayer1;
# (very simple) example player module for blackjack
# this player will hit on a 16 or less.

use Games::Tournament::BlackJack::Player;
use Games::Tournament::BlackJack::Utilities;
@ISA = qw(Games::Tournament::BlackJack::Player);

  # decide_simple     returns "hit", "stand", or true for hit, false for stand.
sub decide_simple { 
  return  handValue($_[0]->{'hand'}) <= 16 ? 'hit' : 'stand';
}	# hit on 16 or less


1;
