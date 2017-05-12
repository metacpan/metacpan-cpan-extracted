package Games::Tournament::BlackJack::Player::DealerPlayer;
# dealer player for blackjack
#  -- follows standard vegas casino rules on dealer behavior:
#  --   hit on soft 17 or less, stand on hard 17 or more

use Games::Tournament::BlackJack::Player;
use Games::Tournament::BlackJack::Utilities;
use Exporter;
@ISA = qw(Games::Tournament::BlackJack::Player);


  # decide_simple returns true for hit, false for stand.
  
sub decide_simple {
   my $self = shift;
   my $hit_threshold = 16; # hit on hard 16 or less
   my $handValue = $self->myHandValue();
   
   if ($handValue == 17 and $self->isHandSoft()) {  
      return 'hit'; # on a soft 17
   }
   
   # otherwise, hit on hard 16 or less as usual.
   return ($handValue <= $hit_threshold) ? 'hit' : 'stand';
}

1;
