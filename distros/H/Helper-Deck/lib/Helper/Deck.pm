use common::sense;

our $VERSION = '1.05';

# ABSTRACT: Work with a deck of playing cards in the fashion engineered by Duane O'Brien of I.B.M. developerWorks.

package Helper::Deck {
    use Moose;
    
    use common::sense;
 
    use List::Util qw(shuffle);
   
    use feature 'say';
   
    sub roll {
        my $self = shift;
        my $sides = shift;
        return(int( rand( $sides ) + 1));
    }
   
    sub random_nick {
        my $self = shift;
        my @nicks = @_;
 
        return((shuffle(@nicks))[-1]);
    }
   
    sub random_name {
        my $self = shift;
        my @names = @_;
 
        return((shuffle(@names))[-1]);
    }
   
    sub random_scenario {
        my $self = shift;
        my %args = @_;
       
        my @settings = shuffle(@{$args{settings}});
        my @objectives = shuffle(@{$args{objectives}});
        my @antagonists = shuffle(@{$args{antagonists}});
        my @complications = shuffle(@{$args{complications}});
            
        return(
            'setting' => $settings[-1],
            'objective' => $objectives[-1],
            'antagonist' => $antagonists[-1],
            'complication' => $complications[-1],
        );
    }
   
    sub build_deck {
        my $self = shift;
        
        my @suits = (
            'Spades',
            'Hearts',
            'Clubs',
            'Diamonds',
        );
       
        my @faces = (
            'Two',
            'Three',
            'Four',
            'Five',
            'Six',
            'Seven',
            'Eight',
            'Nine',
            'Ten',
            'Jack',
            'Queen',
            'King',
            'Ace',
        );
       
        my @deck;
       
        foreach my $suit (@suits) {
            foreach my $face (@faces) {
                push @deck,\%{{'face' => $face, 'suit' => $suit}};
            }
        }
        
        return(\@deck);
    }
   
    sub shuffle_deck {
        my $self = shift;
        my $deck_ref = shift;
        my @deck = @{$deck_ref};
        my @shuffled_deck = shuffle(@deck);
        return(\@shuffled_deck);
    }
   
    sub top_card {
        my $self = shift;
        my $deck_ref = shift;
        my $card = pop @{$deck_ref};
        return($card);        
    }
   
    sub card_to_string {
        my $self = shift;
        my $card_ref = shift;
        my %card = %{$card_ref};
       
        return($card{face} . ' of ' . $card{suit});
    }
   
    sub draw {
        my $self = shift;
        my $deck_ref = shift;
        my $max = shift;
        my @deck = @{$deck_ref};
        my @draw;
       
        foreach my $item (1 .. $max ) {
            push(@draw,$self->top_card($deck_ref));
        }
       
        return(\@draw);
    }
   
    sub calculate_odds {
        my $self = shift;
        my $deck = shift;
        my $chosen = shift;
              
        my $remaining = scalar @{$deck};
        my $odds = 0;
        foreach my $card (@{$deck}) {
            $odds++ if (($card->{'face'} eq $chosen->{'face'} && $card->{'suit'} eq $chosen->{'suit'}) || ($card->{'face'} eq '' && $card->{'suit'} eq $chosen->{'suit'}) || ($chosen->{'face'} eq $chosen->{'face'} && $card->{'suit'} eq ''));
        }
       
        return($odds . ' in ' . $remaining);
    }
   
}
 
1;

__END__

# MAN3 POD

=head1 NAME

Helper::Deck - Work with a deck of playing cards in the fashion engineered by Duane O'Brien of I.B.M. developerWorks.

=cut

=head1 SYNOPSIS

    use common::sense;
    use Helper::Deck;
    
    my $d1 = Helper::Deck->new;
    my $roll1 = $d1->roll(6);
    
    my $nick1 = $d1->random_nick(('nd', 'jp', 'smoke', 'gehenna'));
    my $name1 = $d1->random_name(('james doe', 'john doe', 'jason doe', 'justin doe'));
    
    my %scene1 = $d1->random_scenario(
        settings => [ 'the beach', 'the Yaht' ],
        objectives => [ 'get suntan', 'go swimming' ],
        antagonists => [ 'gull', 'kid' ],
        complications => [ 'very thirsty', 'very drunk' ],
    );
    
    print "I'm ", $scene1{'complication'}, " so I will ", $scene1{'objective'}, ".", "\n";
    
    my $deck1 = $d1->build_deck;
    my $deck1 = $d1->shuffle_deck($deck1);
    
    my $tc = $d1->top_card($deck1);
    
    print $d1->card_to_string($tc), " was drawn.", "\n";
    
    my $deal1 = $d1->draw($deck1, 5);
    
    print "Player 1 has been given ", $d1->card_to_string($deal1->[0]), "\n";
    print "Player 2 has been given ", $d1->card_to_string($deal1->[1]), "\n";
    print "Player 3 has been given ", $d1->card_to_string($deal1->[2]), "\n";
    print "Player 4 has been given ", $d1->card_to_string($deal1->[3]), "\n";
    print "The dealer gave himself ", $d1->card_to_string($deal1->[4]), "\n";
    
    my $odds = $d1->calculate_odds($deck1, $tc);

=cut

=head1 INTRODUCTION

Work with a deck of playing cards in the fashion engineered by Duane O'Brien of I.B.M. developerWorks.

=cut

=head1 METHODS

=head2 roll
    usage :
    
        Parameters : 
            Let s be the count of sides of the die,
        Results :
            Let r be a fair dice roll between 1 and s,
            
        my $r = $obj->roll($s);

This method provides a simulation of a fair dice roll.  The roll method takes a parameter indicating the count of sides of the die.  The roll method returns a value, proven to be pseudo-random, as a whole integer value.  The result of this method is a number between 1 and the count of sides of the die.

=cut

=head2 random_nick
    usage :
    
        Parameters : 
            An array of strings containing nicks (or handles / aliases / monikers) to be used as a pool from which to draw,
        Results :
            A scalar containing a string which is a random nick (or handle / alias / moniker) drawn from the pool supplied,
            
        my $nick1 = $obj->random_nick(('nd', 'jp', 'smoke', 'gehenna')));

This method is supplied with an array of strings containing nicks (or handles / aliases / moniker) to be used as a pool from which to draw a random value.  This value is a nick (or handle / alias / moniker).

=cut

=head2 random_name
    usage :
    
        Parameters : 
            An array of strings containing names to be used as a pool from which to draw
        Results :
            A scalar containg a string which is a random name drawn from the pool supplied
            
        my $r = $obj->random_name(('james doe', 'john doe', 'jason doe', 'justin doe'));

This method is supplied with an array of strings containing names to be used as a pool from which to draw a random value.  This value is a name.

=cut

=head2 random_scenario
    usage :
    
        Parameters (as a Hash) : 
            Let settings be an array of strings where each string is an illustrative description of a setting,
            Let objectives be an array of strings where each string is an illustrative description of a objective,
            Let antagonists be an array of strings where each string is an illustrative description of a antagonist,
            Let complications be an array of strings where each string is an illustrative description of a complication,
            
        Results (as a Hash) :
            Let setting be a string which is an illustrative description of the setting,
            Let objective be a string which is an illustrative description of the objective,
            Let antagonist be a string which is an illustrative description of the antagonist,
            Let complication be a string which is an illustrative description of the complication,
            
        my %scene1 = $d1->random_scenario(
            settings => [ 'the beach', 'the Yaht' ],
            objectives => [ 'get suntan', 'go swimming' ],
            antagonists => [ 'gull', 'kid' ],
            complications => [ 'very thirsty', 'very drunk' ],
        );

This method is supplied with a hash which contains 4 arrays of strings.  The array of strings accessed by the key titled settings contains illustrative descriptions of settings. The array of strings accessed by the key titled objectives contains illustrative descriptions of objective. The array of strings accessed by the key titled antagonists contains illustrative descriptions of antagonists. The array of strings accessed by the key titled settings contains complications descriptions of complications.  This method returns a hash containg keys titled setting, objective, antagonist and complication.  These resultant strings are used to describe a randomly generated scenario.

=cut

=head2 build_deck
    usage :
    
        Results :
            Let r be a reference to an array containing a ordered deck of playing cards where each card is a hash containg keys titled face and suit.
            
        my $r = $obj->build_deck;

This method is used to build a deck of playing cards.  The build_deck method returns a reference to an array containing a ordered deck of playing cards where each card is a hash containg keys titled face and suit.

=cut

=head2 shuffle_deck
    usage :
    
        Parameters : 
            Let d1 be a reference to a deck of playing cards (see method titled build_deck),
        Results :
            Let r be a reference to d1 once shuffled,
            
        my $r = $obj->shuffle_deck($d1);

This method is used to shuffle a deck of playing cards.

=cut

=head2 top_card
    usage :
    
        Parameters : 
            Let d1 be a reference to a deck of playing cards (see method titled build_deck),
        Results :
            Let tc be a reference to the top card drawn from the deck,
            
        my $tc = $obj->top_card($d1);

This method draws the top card from the deck.  The top_card method accepts a refereence to a deck of playing cards.  The top_card method draws the top card from the deck then supplies this card as a return value which is a hash containing two strings identified by the keys titled face and suit respectively.

=cut

=head2 card_to_string
    usage :
    
        Parameters : 
            Let c1 be a reference to a card,
        Results :
            Let r be an illustrative description of this card as a string,
            
        my $r = $obj->card_to_string($c1);

This method accepts a reference to a card, which is a hash containing two values identified by the keys titled face and suit.  This method returns an illustrative description of this card as a scalar containing a string of text.

=cut

=head2 draw
    usage :
    
        Parameters : 
            Let d1 be a reference to a deck of playing cards (see method titled build_deck),
            Let i be the number of cards to draw,
        Results :
            Let r be description of return value,
            
        my $r = $obj->draw($d1, $i);

This method will collect the number of top cards specified and push them into an array.  The draw method returns a reference to an array of cards drawn from the top of the deck.

=cut

=head2 calculate_odds
    usage :
    
        Parameters : 
            Let d1 be a reference to a deck of playing cards (see the method titled build_deck),
            Let c1 be a reference to a card illustrative of the selected draw,
        Results :
            Let r be description of the odds as a string,
            
        my $r = $obj->calculate_odds($d1, $c1);

This method returns a description of the odds as a string.  The calculate odds method is passed a reference to a deck of playing cards (see the method titled build_deck) as well as the selected card through which odds are calculated.  A reference to a card is a reference to a hash containing values to keys titled face and suit.  In the case only face is specified, then odds are calculated for this face in all 4 suits.  In the case only suit is specified, then odds are calculated for this suit in all 12 faces.

=cut

=head1 AUTHOR

Jason McVeigh, <jmcveigh@outlook.com>

=cut

=head1 COPYRIGHT AND LICENSE

Copyright 2016 by Jason McVeigh

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut