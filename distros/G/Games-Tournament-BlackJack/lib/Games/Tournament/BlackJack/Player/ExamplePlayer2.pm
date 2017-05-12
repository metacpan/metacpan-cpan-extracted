package Games::Tournament::BlackJack::Player::ExamplePlayer2;
# (very simple) example player module for blackjack
# this player will hit on a 16 or less by default, or the theshold
# he is sent in the initialization parameter "hit_threshold".


use Games::Tournament::BlackJack::Player;
use Games::Tournament::BlackJack::Utilities;
@ISA = qw(Games::Tournament::BlackJack::Player);

  # decide_simple     returns true for hit, false for stand.
sub decide_simple {
   my $self = shift;
   my $hit_threshold = $self->{'hit_threshold'} || 16; # hit on 16 or less _by_default_
   return (handValue($self->{'hand'}) <= $hit_threshold); 	
}

1;
