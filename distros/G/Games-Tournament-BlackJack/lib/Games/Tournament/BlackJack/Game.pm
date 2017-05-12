# Games::Tournament::BlackJack::Game.pm - perl module for playing blackjack with a deck.pm of cards.
#	Author: Paul Jacobs, paul@pauljacobs.net
package Games::Tournament::BlackJack::Game;

use Games::Tournament::BlackJack::Shoe;
use Games::Tournament::BlackJack::Utilities;
use Games::Tournament::BlackJack::Player;

our $running = 0; # not running at first

sub new {
    my $invocant = shift;
    my $class   = ref($invocant) || $invocant;
    my $self = {
        'deck'      => Games::Tournament::BlackJack::Shoe::openNewShoe(), # shuffles before every round, and before returning for good measure.
        'players'  => [], # add them later or override
        'playersScores' => [], # 1 per win
        'playersHands' => [], # need seperate official record -- can't trust player code to not change hand
                  # is parallel array to players[]. is 2D array (one array of cards per player)
        'dealer'  => undef, # add later or specify in override attribute
        'dealersHand' => [], # card 1 is the upcard
        'numDecks'  =>  2, # defaults to 2 decks
        'srand'   => time(), # rand seed for game - can be overridden by attr.
        'options' => ['hit','stand'], # list of acceptable responses to a decide_complex 
                                      # call, may (later) include split, døuble..
        @_,                 # Override previous (default) attributes
    };
    srand($self->{'srand'}); # randomness is per game.
    $self->{'deck'}->shuffle(); # have to do after the srand().
    return bless $self, $class;
}

sub clearHands {
   my $self = shift;
   foreach my $p (@{$self->{'players'}}) {
         $self->{'playersHands'}[$p->{'storage'}{'num'}] = [];
         $p->{'hand'} = [];
   }
   $self->{'dealersHand'} = [];
}

my $total_players = 0;
sub addPlayers {
   my $self = shift;
   my @players = @_;
   foreach my $player (@players) {
      $player->{'storage'}{'num'} = $total_players++;
      push @{$self->{'players'}}, $player;
      push @{$self->{'playersHands'}}, [];
   }
}

sub addPlayer { return addPlayers(@_); }

sub setDealer { 
   $_[0]->{'dealer'} = $_[1]; # set the dealer pointer to point to the passed obj.
}

sub dealersUpcard { $_[0]->{'dealersHand'}->[1] || ''; }

sub playersScores { $_[0]->{'playersScores'} || []; }

sub setupPlayerScenario {
   my $self = shift;
   my $player = shift;
   
   if ($player eq $self->{'dealer'}) {
      # player is the dealer
      $player->{'hand'} = $self->{'dealersHand'} || [];         
   } else {
      # player is not the dealer
      $player->{'hand'} = $self->{'playersHands'}->[$player->{'storage'}{'num'}] || [];
      $player->{'dealerUpcard'} = $self->dealersUpcard() || '';
   } 
   return $player;
}

# playRound is the SIMPLE version. playComplexRound will come later.
sub playRound {
	my $self = shift;
   my @players = @{$self->{'players'}};
   
   # open new deck
   $self->{"deck"} = openNewDeck();
   
   # shuffle deck
	$self->{"deck"}->shuffle;

   # clear hands
   $self->clearHands();

   # deal two cards in proper order:
   foreach (0..1) {
      print "dealing card to each player..\n";
      foreach (0..$#players) {
        #deal one    from the deck        to each player's hand
         deal(	1, 	$self->{"deck"}, 	 	$self->{"playersHands"}->[$_]);
      }

         print "dealing card to dealer..\n";
              #deal one    from the deck        to the dealer's hand 
      	deal(	1,    $self->{"deck"}, 	 	$self->{"dealersHand"}	);   	
   }

   # each player in turn decides to hit or stay until they are done.
   my $player_hit = 1; # to get into loop
   foreach (0..$#players) {
      $player_hit = 1; # to get into loop
      $player = $players[$_] = $self->setupPlayerScenario($players[$_]); # load up private data fields in player obj.
      my $handVal = handValue($self->{"playersHands"}->[$_]);
      while ( ($handVal = handValue($self->{"playersHands"}->[$_])) < 21 and $player_hit) {
         my $decision = $player->decide_simple();
         if ($decision eq 'hit' or ($decision and $decision ne 'stand')) {
           #deal one    from the deck        to the player's hand
            deal(	1, 	$self->{"deck"}, 	 	$self->{"playersHands"}->[$_]);
            print "player $_ hits on $handVal..\n";
         } else {
            print "player $_ stays on $handVal..\n";
            $player_hit = 0;
         }
      }
   
   }   

   # now let dealer play out
   my $dealer = $self->{'dealer'} = $self->setupPlayerScenario($self->{'dealer'});
   $player_hit = 1; # get into loop
   while ( ($handVal = $dealer->myHandValue()) < 21 and $player_hit) {
      my $decision = $dealer->decide_simple();
      my $handStr = $dealer->myHandStr(); 
      if ($decision eq 'hit' or ($decision and $decision ne 'stand')) {
        #deal one    from the deck        to the player's hand
         deal(	1, 	$self->{"deck"}, 	 	$self->{"dealersHand"});
         print "dealer hits on [$handStr] ($handVal)..\n";
         if ($handVal == 0) {my $handStr = $dealer->myHandStr(); print "dealer hand [$handStr]";}
      } else {
         print "dealer stays on [$handStr] ($handVal)..\n";
         $player_hit = 0;
      }
   }


   
   # compare values
   my $dval = handValue($self->{'dealersHand'});
   print "dealer hand value $dval\n";

   my @pvals = map {handValue($_)} @{$self->{'playersHands'}};
   print "player hand values [@pvals]\n";

   my @phstrs = map {handStr($_)} @{$self->{'playersHands'}};

   if ($dval > 21) {
      # dealer busts
      print "dealer busts with $dval; all players win.\n";
      foreach (0..$#players) {$self->{'playersScores'}[$_]++} # add 1 for all players
      return; # and end the round.
   }
   my $pnum = 0;
   foreach my $p (@pvals) {
      
      if ($p > 21) {
         print "player $pnum busts with $p ($phstrs[$pnum]).\n"; 
         $pnum++; 
         next; }
      elsif ($p == 21) {
         print "player $pnum gets a 21 (Assuming blackjack for now) $p ($phstrs[$pnum]) (score 1.5).\n"; 
         $self->{'playersScores'}[$pnum] += 1.5;
         next; }
      elsif ($p == $dval) {
         print "player $pnum has $p ($phstrs[$pnum]) vs. dealer's $dval, push (score 0.5).\n";
         $self->{'playersScores'}[$pnum] += 0.5;
      }
      elsif ($p > $dval) {
         print "player $pnum has $p ($phstrs[$pnum]) vs. dealer's $dval, player $pnum wins (score 1).\n";
         $self->{'playersScores'}[$pnum]++;
      } else {
         print "player $pnum has $p ($phstrs[$pnum]) vs. dealer's $dval, player $pnum loses (score 0)\n";
      }
      $pnum++;
   }

}

sub running {
   return $running;
}

sub quit {
   $running = 0;
}

sub start {
   my $self = shift;
   my @players = @{$self->{'players'}};
   # game config is done and I can prepare to run game
   $running = 1;
   # blank out player scores
   foreach (0..$#players) {
      $self->{'playersScores'}[$_] = 0;
   }
}

1;
