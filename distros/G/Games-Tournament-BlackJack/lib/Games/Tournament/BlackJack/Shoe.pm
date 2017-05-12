# Shoe.pm - perl module for manipulating shoes (one or more decks combined) of cards
#	Author: Paul Jacobs, paul@pauljacobs.net
package Games::Tournament::BlackJack::Shoe;

use Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw( 
				printCards
				printCardsNumbered 
				deal 
				openNewDeck
				openNewShoe
				setShoeSize
				noticeCards
				maybeNoticeCards
				);
				
our $shoeSize = 2; # default number of decks in a shoe.
@suits = qw(Spades Clubs Diamonds Hearts);
@faceValues = qw(Ace 2 3 4 5 6 7 8 9 10 Jack Queen King);
%facePoints = (
		"Ace"		=>	1,
		2			=>	2,
		3			=>	3,
		4			=>	4,
		5			=>	5,
		6			=>	6,
		7			=>	7,
		8			=>	8,
		9			=>	9,
		10			=>	10,
		"Jack"		=>	11,
		"Queen"		=>	12,
		"King"		=>	13,
);

sub setShoeSize {
	my $newSize = shift;
	my $possibleSize = shift;
	if (ref $newSize) {
		# if the first arg turned out to be an object ref, use the second
		$newSize = $possibleSize;
	}

	die "invalid shoe size (number of decks in shoe) [$newSize] must be an integer 1-10"
		unless ($newSize >= 1 and $newSize <= 10 and (int $newSize == $newSize));
	
	$shoeSize = $newSize;
}

sub shoeSize { return $shoeSize; }

sub openNewShoe {
	my @newShoe = ();
	foreach (0..$shoeSize) {
		push @newShoe, @{openNewDeck()};
	}
	return bless [@newShoe];
}

sub openNewDeck {
	my @newDeck = ();
		foreach $suit (@suits) {
		foreach $value (@faceValues) {
			push @newDeck, ($value  . "_of_" . $suit);
		}
	}
	return bless [@newDeck];
}

@dek = @{openNewShoe()};

sub noticeCards {
	my $cards = $_[0];
	my %noticed = %${$_[1]};
	
	foreach my $card (@$cards)
	{
		$noticed{$card}++;
	}
}

sub maybeNoticeCards {
	my $cards = $_[0];
	my $noticed = %${$_[1]};
	my $noticeLikelyhood = $_[2];
	
	if ($noticeLikelyhood >= 1) 
	{
		$noticeLikelyhood = 0;
	}
	foreach my $card (@$cards)
	{
		if ( (rand 1) > $noticeLikelyhood)
		{
			$noticed{$card}++;
		}
	}
}

sub deal {
	my $numToDeal = $_[0];
	my $from = $_[1];
	my $to = $_[2];
	
	foreach (1..$numToDeal)
		{ 
		   my $card = pop @{$from} || die "card not dealt from empty deck $from [@$from] to $to [@$to]";
		   push @{$to}, $card;
		}
}

sub shuffle {
	my $self = shift;
	my $shuffleThoroughness = 8; # min for good shuffle
	my $i;
	
	foreach (1..($shuffleThoroughness)) {
		for ($i = scalar (@$self); --$i; ) {
			my $j = int rand ($i + 1);
			next if $i == $j;
			($$self[$i], $$self[$j]) = ($$self[$j], $$self[$i]);
		}
	}

	return $self;
}

sub sprintCards {
	my $self = $_[0];
  my $hand;
	if (ref $self eq 'Games::Tournament::BlackJack::Shoe') {
	 $hand = $self;
	} else {
	 if (@_) {
	   $hand = bless [@_];
	 } else {
	   $hand = bless [];
	 }
	}
	
	my $output = "";

	foreach	my $card (@$hand) {
		$card =~ s/_/ /g;
		$output .= "\t\t$card\n";	
	}
  
  return $output;
}

sub printCards {
  print sprintCards(@_);
}


sub sprintCardsNumbered {
	my $self = shift;
	my @hand = @_;
  my $output = "";

	my $index = 0;
	foreach	my $card (@hand) {
		$output .= "$index: $card\n";	
		$index++;
	}
  return $output;
}


sub printCardsNumbered {
  print sprintCardsNumbered(@_);
}

1;
