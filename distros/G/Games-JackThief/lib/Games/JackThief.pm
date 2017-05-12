##########################################################################################################################################
### 	Games::JackThief -- 2015, Kapil Rathore <kapil.rthr@gmail.com>
###
###		What is JackThief Game ? 
###
###			This game is played with 51 * (Decks-1) cards.  The jokers have no role here and out of 4 jacks, 
###			one jack is removed which can be of any suit. This game is usually played by 2 players or more.
###			After the shuffle, it would be very tedious for the dealer to give one card to each and every player 
###			since the entire 51 cards have  to be distributed amongst all the players equally or nearly equally.
###
###			After both the players get their respective bunch of cards, the process of separation begins.
###			All paired cards are discarded.  For example, if the player 1 has two aces, two Kings, two 10s, two 5s, 
###			then he will remove these cards. Similarly for cards such as four 7s, four 4s and so on, 
###			because these form two pairs.
###			Once all the cards discarded, player will fetch a random card from neighbouring player, 
###			he will again discard from his set of cards if match is found. Process continues until the 
###			player with jack left and became the looser of the game
###
###
###			After the pairs are weeded out, both the players will be left with odd number of cards usually one of each,
###			since if there are three cards of six say, then two of them form pairs and are discarded and only one six is left. 
###
###			This would go on till the all the cards are not discarded except one jack and the player who will be having the Jack 
###			in the end would be called as JackThief.			
###
###		How to Run the Games::JackThief ?
#####################################################################
###				use warnings; 
###				use strict;
###				use Games::JackThief;
###				#use Data::Dumper;  				# To see the process of card Fetching enable this
###
###				my $Decks_and_Players = {
###											no_of_Decks => 1, 
###											no_of_Players => 3,
###										};
###
###				my $JackThief = Games::JackThief->new($Decks_and_Players);	#my $JackThief = Games::JackThief->new();  # Still Works and Takes default values
###				$JackThief->JackThief_Hand;
###				$JackThief->CreateFetchSeq;
###				do
###				{
###						#print Dumper($JackThief);		# To see the process of card Fetching enable this
###						#print "\n\n#####\n\n";			# To see the process of card Fetching enable this
###					$JackThief->JackThief_RunFetchRound;
###						#<STDIN>;						# To see the process of card Fetching enable this
###				} while($JackThief->LooserFound);
###
###				print "Looser is Player $JackThief->{FetchSeq}[0]\n";
###					##########	END		#############
###
####
######################################################################
###			How to Run the Games::JackThief ?
###				1) Defining the hash with information of no_of_Decks and no_of_Players.
###				2) Taking the JackThief object --> generating the valid Deck Sequence of  51*(Decks-1) cards ---> Randomizing the sequence
###				3) Now Distributing the cards to each players --> the process of separation begins and players discards the cards of same type 
###				4) create a circular fetch sequence --> after fetch player will discard the card --> Rotations goes until the loose with Jack is found
###############################################################################################################################################
package Games::JackThief;

use 5.006;
use strict;
use warnings;
use Data::Dumper;
=head1 NAME

Games::JackThief - The great new Games::JackThief!

=head1 VERSION

Version 0.02

=cut

our $VERSION = '0.02';


=head1 SYNOPSIS

Quick summary of what the module does.

Perhaps a little code snippet.

    use Games::JackThief;

    my $foo = Games::JackThief->new();
    ...

=head1 EXPORT

A list of functions that can be exported.  You can delete this section
if you don't export anything, such as for a purely object-oriented module.

=head1 SUBROUTINES/METHODS

=head2 function1

=cut


#################################
## Constructor ->  GenerateDeckSequence -> Shuffle
sub new	{
#################################
	my $Class = shift;
	my $Data = shift;
	
	my $Self = {};
	bless $Self, $Class;
	
	$Self->{no_of_Decks} = (defined $Data->{no_of_Decks} && $Data->{no_of_Decks} > 0 && $Data->{no_of_Decks} <= 5) ? $Data->{no_of_Decks} : 1;
	$Self->{no_of_Players} = (defined $Data->{no_of_Players} && $Data->{no_of_Players} > 2 && $Data->{no_of_Players} <= 10) ? $Data->{no_of_Players} : 2;
	
	$Self->_GenerateDeckSequence;
	
	return $Self;
}

#################################
## Creates Hand and Discards the pair
sub JackThief_Hand {
#################################
	my $Self = shift;
	while (scalar @{$Self->{AllCards}} > 0)
	{
		for (my $a = 1; $a <= $Self->{no_of_Players}; $a++)
		{
			push(@{$Self->{'Player'.$a}}, pop @{$Self->{AllCards}}) if (scalar @{$Self->{AllCards}} > 0);
		}
	}
	$Self->JackThief_DiscardCards($Self->{no_of_Players});
	# valid hand to start
	my $ValidHand = 1;
	foreach(1..$Self->{no_of_Players})
	{
		if (scalar (@{$Self->{'Player'.$_}}) == 0)
		{
			print "## Not a valid hand  Try again ##\n";
			exit;
		}
	}
	#
	return $Self;
}

#################################
# Run the Fetch Sequence until looser found
sub JackThief_RunFetchRound {
#################################
		my $Self = shift;
		my $fetch_by 	= 	$Self->{FetchSeq}[0];
		my $fetch_from 	=	$Self->{FetchSeq}[1];
		
		my $randSel   = int rand @{$Self->{'Player'. $fetch_from}}; 
		my $ftchd_card =  splice(@{$Self->{'Player'. $fetch_from}}, $randSel , 1);
		push (@{$Self->{'Player'. $fetch_by}}, $ftchd_card);
		$Self->JackThief_DiscardCards(1, $Self->{FetchSeq}[0]);
		
		if (scalar @{$Self->{'Player'. $fetch_by}} == 0)
		{
		# $fetch_by player  wins here;
			$Self->_UpdateFetchSeq(0);
		}
		elsif (scalar @{$Self->{'Player'. $fetch_from }} == 0)
		{
		# $fetch_from  player wins here;
			$Self->_UpdateFetchSeq(1);
		}
		else
		{
		# non of the player wins;
			$Self->_UpdateFetchSeq(2);
		}
	
	return $Self;
}

#################################
# Check looser found or not
sub LooserFound {
#################################
	my $Self = shift;
	return 1 if (scalar (@{$Self->{FetchSeq}}) > 1);
	return 0 if (scalar (@{$Self->{FetchSeq}}) == 1);
}

#################################
# it actually creates the Fetch Seq
sub CreateFetchSeq {
#################################
	my $Self = shift;
	$Self->{FetchSeq} = [1..$Self->{no_of_Players}];
	return $Self;
}

#################################
## Discards the pair
sub JackThief_DiscardCards {
#################################
	my $Self = shift;
	my $Players = shift;
	my $a=shift;
	$Players = (defined $Players) ? $Players : 1;
	$a = (defined $a) ? $a : 1;
	foreach(1..$Players)
	#for (my $a = 1; $a <= $Players; $a++)
	{
		my $plyr = 'Player'.$a;
		@{$Self->{$plyr}} = sort (@{$Self->{$plyr}}); 
		for (my $b = 0; $b < @{$Self->{$plyr}}; $b++)
		{
			if ((defined $Self->{$plyr}[$b]) && (defined $Self->{$plyr}[$b+1]))
			{
				if ((($Self->{$plyr}[$b] =~ m/\d+/) && ($Self->{$plyr}[$b+1] =~ m/\d+/)) && ($Self->{$plyr}[$b] == $Self->{$plyr}[$b+1]))
					{
						$Self->{$plyr}[$b] = $Self->{$plyr}[$b+1] = "";
						$b++;
					}
				elsif((($Self->{$plyr}[$b] =~ m/\w+/i) && ($Self->{$plyr}[$b+1] =~ m/\w+/i)) && ($Self->{$plyr}[$b] eq $Self->{$plyr}[$b+1]))
					{
						$Self->{$plyr}[$b] = $Self->{$plyr}[$b+1] = "";
						$b++;
					}
			}
		}
		@{$Self->{$plyr}} = grep { $_ ne '' } @{$Self->{$plyr}};
	$a++
	}
	return $Self;
}

##Private methods

#################################
# rotate the Fetch Seq
sub _UpdateFetchSeq {
#################################
	my $Self = shift;
	my $arg = shift;
	if (!$arg)
	{
		shift @{$Self->{FetchSeq}};
	}
	elsif($arg == 1)
	{
		my $tmp = shift @{$Self->{FetchSeq}};
		shift @{$Self->{FetchSeq}};
		push (@{$Self->{FetchSeq}}, $tmp);
	}
	elsif($arg == 2)
	{
		my $tmp = shift @{$Self->{FetchSeq}};
		push (@{$Self->{FetchSeq}}, $tmp);
	}
	return $Self;
}

#################################
## generates the cards sequences and drops one jack
sub _GenerateDeckSequence {
#################################
	my $Self = shift;
	my @DeckTypes = ('Heart', 'Diamond', 'Spade', 'Club');
	my @DeckNumbers = ('A', 2, 3, 4, 5, 6, 7, 8, 9, 10, 'J', 'Q', 'K');
	my $i = 1;
	my $DropOneJack = 0;
	foreach(1..$Self->{no_of_Decks})
	{
		foreach(@DeckTypes) {
				my $D = $_;
				foreach(@DeckNumbers) {
					my $N = $_;
					if (($N eq "J") && (!$DropOneJack)) { $DropOneJack++; }
					else {
						#$Self->{'AllCards'}->{$i}->{$D} = $N;
						push(@{$Self->{AllCards}}, $N);
						$i++;
					}
				}
			}
	}
	$Self->_shuffle;
	return $Self;
}

#################################
## randomize the sequence of cards
sub _shuffle {
#################################
	my $Self = shift;
    my $i;
    for ($i = @{$Self->{AllCards}}; --$i; ) {
        my $j = int rand ($i+1);
        next if $i == $j;
         @{$Self->{AllCards}}[$i,$j] = @{$Self->{AllCards}}[$j,$i];
    }
}

#########################################################################################

=head1 AUTHOR

Kapil Rathore, C<< <kapil.rthr at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-games-jackthief at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Games-JackThief>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Games::JackThief


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Games-JackThief>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Games-JackThief>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Games-JackThief>

=item * Search CPAN

L<http://search.cpan.org/dist/Games-JackThief/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2015 Kapil Rathore.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (1.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_1_0>

Aggregation of this Package with a commercial distribution is always
permitted provided that the use of this Package is embedded; that is,
when no overt attempt is made to make this Package's interfaces visible
to the end user of the commercial distribution. Such use shall not be
construed as a distribution of this Package.

The name of the Copyright Holder may not be used to endorse or promote
products derived from this software without specific prior written
permission.

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.


=cut

1; # End of Games::JackThief
