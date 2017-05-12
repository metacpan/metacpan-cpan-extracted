package Games::Tournament::BlackJack::Player::HumanPlayer;
# example interactive human player module for blackjack

use Games::Tournament::BlackJack::Player;
use Games::Tournament::BlackJack::Utilities;
@ISA = qw(Games::Tournament::BlackJack::Player);

  # decide_simple returns true for hit, false for stand.
sub decide_simple {
   my $self = shift;
   my @hand = @{$self->{'hand'}};
   my $hval = handValue(\@hand);
   my $hand_str = handStr(\@hand);
   $output = "dealer shows $self->{'dealerUpcard'}, you have [ $hand_str ] for a total of $hval.\n";

   print $output;
   print "[h]it or stay>";

   my $input = <>;
   if ($input =~ m/h/i) 
      { return 1; } # hit if the user says to.
   else 
      { return 0; }
}


1;

