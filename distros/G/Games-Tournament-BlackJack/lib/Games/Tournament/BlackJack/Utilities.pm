# Games::Tournament::BlackJack::Utilities.pm - utilities for blackjack
#	Author: Paul Jacobs, paul@pauljacobs.net
package Games::Tournament::BlackJack::Utilities;

use Exporter;
use Games::Tournament::BlackJack::Shoe;

our @ISA = qw(Exporter);

our @EXPORT = qw( 
				handValue
				cardValue
				handStr
				firstLetter
);


# general utilities
sub firstLetter { return  substr($_[0],0,1); }

# Stats utilities
sub handValue {
	my $hand = shift; 
	my $total = 0;
	my $counts = {};
	
	foreach my $card (@$hand) {
      $total += cardValue($card);
      $counts->{ firstLetter($card) }++;
	}
	
	if ($total > 21) { 
	   $total++;
	   $total--; 
	   }
	
	if ($total > 21 and $counts->{'A'} > 0) {
	   # try using aces as 1 instead of 11 if total is too high
	   foreach my $card (@$hand) {
	      if ($card =~ /^A/ and $total > 21) {
	         $card =~ s/^A/a/;
	         $total = handValue($hand); # recurse as much as possible to reduce the As below 21
	      }
	   }
	}
	
	return $total;
}

sub cardValue {
					my $card = shift;
					
					
					my %values = (	
						'a'		=>		1,	# 'a' is an ace in a hand that can't fit an 11 - it is forced to 1.
						'2'		=>		2,
						'3'		=>		3,
						'4'		=>		4,
						'5'		=>		5,
						'6'		=>		6,
						'7'		=>		7,
						'8'		=>		8,
						'9'		=>		9,
						'10'	=>		10,
						'1'   =>    10, # abbrev for 10, so they can all be 1 character and still work.
						'J'		=>		10,
						'Q'		=>		10,
						'K'		=>		10,
						'A'		=>		11,  
                  # 'A' is an "open" ace, and is assumed to be 11 but may change to 1 later.
                  # Aces are dealt as 'A's.
					);
					
					return $values{ firstLetter($card) };
}

sub handStr {
   my $hand = shift;
   die "bad hand $hand [@$hand]" unless ref $hand eq 'ARRAY';
   my @h = @$hand;
   my $out = "";

   foreach my $c (@h) {
      my $card = $c;
      $card =~ s/_/ /g;
      $card =~ s/ of /\-/g;
      
      $card =~ s/Clubs/C/g;
      $card =~ s/Diamonds/D/g;
      $card =~ s/Hearts/H/g;
      $card =~ s/Spades/S/g;

      $card =~ s/King/K/g;
      $card =~ s/Jack/J/g;
      $card =~ s/Queen/Q/g;
      $card =~ s/Ace/A/g;
      $card =~ s/ace/a/g;


      $out .= "${card}, "
   }
   
   # remove trailing comma + space
   chop($out);
   chop($out);
   
   return $out;
}

1;
