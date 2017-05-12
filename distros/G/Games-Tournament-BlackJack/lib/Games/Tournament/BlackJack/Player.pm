# Games::Tournament::BlackJack::Utilities.pm - Utility functions for blackjack
#	Author: Paul Jacobs, paul@pauljacobs.net
package Games::Tournament::BlackJack::Player;

use Games::Tournament::BlackJack::Utilities;
use Games::Tournament::BlackJack::Shoe;
use Exporter;

# Constructors
sub scenario {
    my $invocant = shift;
    my $class   = ref($invocant) || $invocant;
    my $self = {
        'storage'   => {}, # opaque storage for higher level processes.
        'hand'      => [],
        'memory'    => [], # recommended to start with a set of (up to) 13 integer counts of cards seen, degraded
                           # proportionally to memory used. scalars only, no nested arrays or hashes allowed (?)
                           # this count is automatically maintained unless auto_count is set to false

        'autoCount' => 1, # when true, a card count will be automatically maintained in the first 13 memory spaces.
                           # Aces are put in spot 13. Spot 1 keeps a running total count of all cards auto_counted.
                           # Spot 0 is user defined, as are all entries past 13.

        'dealerUpcard' => '',
        'otherPlayerUpcards' => '',
        'numDecks'  =>  $Games::Tournament::BlackJack::Shoe::shoeSize, # ideally this doesn't change after you create a player
        'options' => ['hit','stand'], # list of acceptable responses to a decide_complex 
                                      # call, may include split, double..
        @_,                 # Override previous (default) attributes
    };
    return bless $self, $class;
}

sub new {
    return scenario(@_);
}




# Main API Calls ----------------

    # Simple API
sub decide_simple {
   my $self = shift;
   # by default it will always stay when given the chance. Not the best strategy.
   return 0;
}

    # Complex API
sub decide_complex {
   my $self = shift;
   return $self->decide_simple();
}

# accessors to try to avoid the _need_ for $self examination  ----------------
sub hand { return $_[0]->{'hand'} || []; }


# utility functions  ----------------
sub myHandValue { return handValue($_[0]->hand()) }
sub myHandStr   { return handStr($_[0]->hand()) }

sub isHandSoft  { return $_[0]->doesHandContain("Ace")}

sub doesHandContain {
   my $self = shift;
   my $searchKey = firstLetter(shift);
   my $handString = $self->myHandStr();
   
   return ($handString =~ /$searchKey/);
}

sub auto_count_cards {
   my $self = shift;
   my $hand = shift;

   if ($self->{'autoCount'}) {
      foreach my $card (@$hand) {
         $self->{'memory'}->[Games::Tournament::BlackJack::Utilities::cardValue(uc($card))]++; # update specific-card total
         $self->{'memory'}->[1]++; # update total number of all cards counted
      }
   }
}

1;

__END__

=head1 Games::Tournament::BlackJack::Player

Subclass this module to create your own entries to GTB Tournaments.
More documentation to come soon.

=cut

