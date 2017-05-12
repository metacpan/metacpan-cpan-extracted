use strict;
use warnings;

package Games::Hanabi;
# ABSTRACT: 'hanabi' card game
$Games::Risk::VERSION = '0.001';

use List::Util qw(shuffle);
use Carp;
use Clone qw(clone);
use Data::Dumper;

my @colors  = qw(R G B Y W);
my @numbers = qw(1 2 3 4 5);
my %revealed_cache;

# Needs players and variants
sub new {
    my ( $class, %params ) = @_;
    $params{players} //= 2;
    $params{derive}  //= 1;

    # R = red
    # G = Green
    # B = Blue
    # W = White
    # Y = Yellow
    # M = Multicolor
    my @cards = qw(
      R1 R1 R1 R2 R2 R3 R3 R4 R4 R5
      G1 G1 G1 G2 G2 G3 G3 G4 G4 G5
      B1 B1 B1 B2 B2 B3 B3 B4 B4 B5
      Y1 Y1 Y1 Y2 Y2 Y3 Y3 Y4 Y4 Y5
      W1 W1 W1 W2 W2 W3 W3 W4 W4 W5
    );
    my @deck;
    my ( %starting_count, %public_count );

    for my $card (@cards) {
        my ( $color, $number ) = split //, $card;
        push @deck, { color => $color, number => $number };
        $starting_count{$color}{$number}++;
        $public_count{$color}{$number} = 0;
    }
    @deck = shuffle @deck;

    my $self = {
        players        => $params{players},
        derive         => $params{derive},
        deck           => \@deck,
        starting_deck  => clone( \@deck ),
        starting_count => \%starting_count,
        public_count   => \%public_count,
        turn           => int( rand( $params{players} ) ),
        hints          => 8,
        bombs          => 0,
        debug          => $params{debug},
        score          => 0,
        discards       => [],
        top_card       => {
            'R' => 0,
            'G' => 0,
            'B' => 0,
            'Y' => 0,
            'W' => 0,
        },
    };

    bless $self, $class;

    # Draw starting hands
    my $starting_cards = 4;
    if ( $params{players} < 4 ) {
        $starting_cards = 5;
    }
    for my $i ( 0 .. $params{players} - 1 ) {
        for ( 1 .. $starting_cards ) {
            $self->_draw($i);
        }
    }

    return $self;
}

# Draw a new card and add it to the player's hand
sub _draw {
    my $self = shift;
    my ($player) = @_;
    return if @{ $self->{deck} } == 0;    # empty deck
    my $card = shift @{ $self->{deck} };
    $card->{known_information} =
      { number_score => 0, color_score => 0, score => 0 };
    push @{ $self->{hands}[$player] }, $card;

    # Deck just got empty, begin the end game
    if ( scalar @{ $self->{deck} } == 0 ) {
        $self->{countdown} = $self->{players};
    }
    return;
}

# The game state consists of what each player is holding,
# what cards are in play, the deck, and what information is known about
# the cards players are holding
sub get_game_state {
    my $self = shift;
    return {
        players   => $self->{players},
        deck      => $self->{deck},
        discards  => $self->{discards},
        hands     => $self->{hands},
        turn      => $self->{turn},
        hints     => $self->{hints},
        bombs     => $self->{bombs},
        top_card  => $self->{top_card},
        score     => $self->{score},
        countdown => $self->{countdown},
    };
}

# Return an array of valid moves.
# actions: play, discard, hint
# For play / discard, the 'card' value will be an int representing the index of the card in hand
# For hint, also pass 'player' index, and the 'value' which is either a number of color letter.
sub get_valid_moves {
    my $self = shift;
    return if defined $self->{countdown} && $self->{countdown} == 0;
    return if $self->{bombs} == 3;
    return if $self->{score} == 25;
    my @moves;
    my $current_player = $self->{turn};

    # Play or discard a card
    for my $i ( 0 .. scalar @{ $self->{hands}[$current_player] } - 1 ) {
        push @moves, { action => 'play',    index => $i };
        push @moves, { action => 'discard', index => $i };
    }

    # Give a hint
    if ( $self->{hints} ) {
        for my $player ( 0 .. $self->{players} - 1 ) {
            next if $player == $current_player;
            my %colors;
            my %numbers;
            for my $i ( 0 .. scalar @{ $self->{hands}[$player] } - 1 ) {
                my $card = $self->{hands}[$player][$i];
                $colors{ $card->{color} }   = 1;
                $numbers{ $card->{number} } = 1;
            }
            for my $c ( sort keys %colors ) {
                push @moves,
                  { action => 'hint', player => $player, hint => $c };
            }
            for my $n ( sort keys %numbers ) {
                push @moves,
                  { action => 'hint', player => $player, hint => $n };
            }
        }
    }

    return @moves;
}

# Perform an action.  Return 1 for game on, 0 for game over.
sub take_action {
    my $self           = shift;
    my ($move)         = @_;
    my $current_player = $self->{turn};
    if ( $move->{action} eq 'discard' ) {

        #print "Player: $current_player / index : $move->{index} \n";
        my $card = $self->{hands}[$current_player][ $move->{index} ];
        print "Player $current_player is discarding "
          . $card->{color}
          . $card->{number} . "\n"
          if $self->{debug};
        push @{ $self->{discards} }, $card;
        splice @{ $self->{hands}[$current_player] }, $move->{index}, 1;
        $self->{public_count}{ $card->{color} }{ $card->{number} }++;
        if ( $self->{hints} < 8 ) {
            $self->{hints}++;
        }
        $self->_draw($current_player);
    }
    elsif ( $move->{action} eq 'play' ) {
        my $card = $self->{hands}[$current_player][ $move->{index} ];
        print "Player $current_player is playing "
          . $card->{color}
          . $card->{number} . "\n"
          if $self->{debug};
        splice @{ $self->{hands}[$current_player] }, $move->{index}, 1;
        $self->{public_count}{ $card->{color} }{ $card->{number} }++;

        if ( $self->is_valid_play($card) ) {
            print "It worked!\n" if $self->{debug};
            $self->{top_card}{ $card->{color} }++;
            if ( $self->{top_card}{ $card->{color} } == 5 ) {
                $self->{hints}++;
            }
            $self->{score}++;
        }
        else {
            print "If did not work...\n" if $self->{debug};
            push @{ $self->{discards} }, $card;
            $self->{bombs}++;
            if ( $self->{bombs} == 3 ) {
                return 0;    # game over
            }
        }
        $self->_draw($current_player);
    }
    elsif ( $move->{action} eq 'hint' ) {
        $self->{hints}--;
        croak "Used up a hint when there were none to use\n"
          if $self->{hints} < 0;
        my $player = $move->{player};
        print
"Player $current_player is giving a hint of $move->{hint} to player $player\n"
          if $self->{debug};
        for my $i ( 0 .. scalar @{ $self->{hands}[$player] } - 1 ) {
            my $card = $self->{hands}[$player][$i];
            if ( $move->{hint} =~ /\d/ ) {
                if ( $card->{number} == $move->{hint} ) {
                    print "Found a match!\n" if $self->{debug};
                    for my $number (@numbers) {
                        if (
                            !defined $card->{known_information}{number}{$number}
                          )
                        {
                            $card->{known_information}{number_score}++;
                            $card->{known_information}{number}{$number} = 0;
                        }
                    }
                    $card->{known_information}{number}{ $move->{hint} } = 1;
                    $card->{known_information}{number_score} = 10;
                }
                else {
                    if ( !defined $card->{known_information}{number}
                        { $move->{hint} } )
                    {
                        $card->{known_information}{number_score}++;
                        $card->{known_information}{number}{ $move->{hint} } = 0;
                    }
                }
            }
            elsif ( $move->{hint} =~ /[a-z]/i ) {
                if ( $card->{color} eq $move->{hint} ) {
                    print "Found a match!\n" if $self->{debug};
                    for my $color (@colors) {
                        if (
                            !defined $card->{known_information}{color}{$color} )
                        {
                            $card->{known_information}{color_score}++;
                            $card->{known_information}{color}{$color} = 0;
                        }

                    }
                    $card->{known_information}{color}{ $move->{hint} } = 1;
                    $card->{known_information}{color_score} = 10;
                }
                else {
                    if ( !defined $card->{known_information}{color}
                        { $move->{hint} } )
                    {
                        $card->{known_information}{color_score}++;
                        $card->{known_information}{color}{ $move->{hint} } = 0;
                    }
                }
            }
            $card->{known_information}{score} =
              $card->{known_information}{color_score} +
              $card->{known_information}{number_score};
        }
    }
    else {
        croak "Unknown action: $move->{action}";
    }

    # Advance the turn counter
    $self->{turn} = ( $self->{turn} + 1 ) % $self->{players};
    if ( defined $self->{countdown} ) {
        $self->{countdown}--;
        if ( $self->{countdown} == 0 ) {
            return 0;    # game over
        }
    }

    if ( $self->{derive} ) {
        $self->derive_information();
    }
    return 1;
}

sub is_valid_play {
    my $self = shift;
    my ($card) = @_;
    if ( $card->{number} == $self->{top_card}{ $card->{color} } + 1 ) {
        return 1;
    }
    return;
}

# Is the play valid from the perspective of the player?
sub is_valid_known_play {
    my $self = shift;
    my ($card) = @_;
    return $self->is_valid_play($card) if $self->is_card_known($card);

# If we know just the number, see if that number if valid for all possible cards
    if ( $self->is_number_known($card) ) {

        #print "number is known for $card->{color}$card->{number}\n";
        for my $color (@colors) {
            if ( not defined $card->{known_information}{color}{$color} ) {
                if ( $card->{number} != $self->{top_card}{$color} + 1 ) {
                    return;
                }
            }
        }
    }
    else {
        return;
    }
    return 1;
}

sub is_junk {
    my $self = shift;
    my ( $card, $known ) = @_;
    return 1 if $card->{known_information}{is_junk};

    # A card is junk if it is known, and already played
    if ( $known || $self->is_card_known($card) ) {
        if ( $card->{number} <= $self->{top_card}{ $card->{color} } ) {
            $card->{known_information}{is_junk} = 1;
            return 1;
        }

        # or dead.
        elsif ( $card->{number} > $self->max_score_for_color( $card->{color} ) )
        {
            $card->{known_information}{is_junk} = 1;
            return 1;
        }

        # or we have 2 copies
        elsif (
            scalar(
                grep {
                    $_->{number} == $card->{number}
                      && $_->{color} eq $card->{color}
                } @{ $self->{hands}[ $self->{turn} ] }
            ) > 1
          )
        {
            $card->{known_information}{is_junk} = 1;
            return 1;
        }
    }

    # A card is junk if a color is dead and the card has that color
    elsif ( my $color = $self->is_color_known($card) ) {
        if ( $self->{top_card}{$color} == $self->max_score_for_color($color) ) {
            $card->{known_information}{is_junk} = 1;
            return 1;
        }
    }

    # A card is junk if a number is dead and the card has that number
    elsif ( my $number = $self->is_number_known($card) ) {
        for my $color ( keys %{ $self->{top_card} } ) {
            if ( $self->{top_card}{$color} < $number ) {
                return;
            }
        }
        $card->{known_information}{is_junk} = 1;
        return 1;
    }

    return;
}

# What's the best score this color can get?
sub max_score_for_color {
    my $self      = shift;
    my ($color)   = @_;
    my $max_score = $self->{top_card}{$color};
    for my $i ( $max_score + 1 .. 5 ) {
        my $matches = grep { $_->{color} eq $color && $_->{number} == $i }
          @{ $self->{discards} };
        my $starting = grep { $_->{color} eq $color && $_->{number} == $i }
          @{ $self->{starting_deck} };
        if ( $matches < $starting ) { $max_score++; }
    }
    return $max_score;
}

# Determine information about cards in our hand based on what else we can see
sub derive_information {
    my $self = shift;
    my ($retain_cache) = @_;
    %revealed_cache = () if !$retain_cache;
    my $information_gained = 0;

    for my $player ( 0 .. $self->{players} - 1 ) {
        for my $i ( 0 .. @{ $self->{hands}[$player] } - 1 ) {
            my $card = $self->{hands}[$player][$i];

            my $color_known  = $self->is_color_known($card);
            my $number_known = $self->is_number_known($card);

            # If we know the number, try to figure out the color
            if ( $number_known && !$color_known ) {

                # Eliminate any colors that are fully revealed
                for my $color (@colors) {
                    if ( not defined $card->{known_information}{color}{$color} )
                    {
                        if (
                            $self->revealed_count( $player,
                                { color => $color, number => $number_known } )
                            == $self->{starting_count}{$color}{$number_known}
                          )
                        {
                            $card->{known_information}{color}{$color} = 0;
                            $card->{known_information}{color_score}++;
                            $information_gained++;
                        }
                    }
                }
            }

            # If we know the color try to figure out the number
            if ( $color_known && !$number_known ) {

                # Eliminate any numbers that are fully revealed
                for my $number (@numbers) {
                    if (
                        not defined $card->{known_information}{number}{$number}
                      )
                    {
                        if (
                            $self->revealed_count( $player,
                                { color => $color_known, number => $number } )
                            == $self->{starting_count}{$color_known}{$number}
                          )
                        {
                            $card->{known_information}{number}{$number} = 0;
                            $card->{known_information}{number_score}++;
                            $information_gained++;
                        }
                    }
                }

            }

            # If we know it's NOT every other color, then we know its color
            if ( !$color_known ) {
                my $negative_colors = 0;
                my $positive_color;
                for my $color (@colors) {
                    if ( defined $card->{known_information}{color}{$color}
                        && !$card->{known_information}{color}{$color} )
                    {
                        $negative_colors++;
                    }
                    elsif ( !defined $card->{known_information}{color}{$color} )
                    {
                        $positive_color = $color;
                    }
                }
                if ( $negative_colors == 4 ) {
                    $card->{known_information}{color}{$positive_color} = 1;
                    $card->{known_information}{color_score} = 10;
                    $information_gained++;
                }
            }

            # If we know it's NOT every other number, then we know its number
            if ( !$number_known ) {
                my $negative_numbers = 0;
                my $positive_number;
                for my $number (@numbers) {
                    if ( defined $card->{known_information}{number}{$number}
                        && !$card->{known_information}{number}{$number} )
                    {
                        $negative_numbers++;
                    }
                    elsif (
                        !defined $card->{known_information}{number}{$number} )
                    {
                        $positive_number = $number;
                    }
                    else {
                        $positive_number = $number;
                    }
                }
                if ( $negative_numbers == 4 ) {
                    $card->{known_information}{number}{$positive_number} = 1;
                    $card->{known_information}{number_score} = 10;
                    $information_gained++;
                }
            }
        }

        # Is there a dead number?

        for my $number (@numbers) {
            my $total          = 0;
            my $total_revealed = 0;
            for my $color (@colors) {
                $total_revealed += $self->revealed_count( $player,
                    { number => $number, color => $color } );
                $total += $self->{starting_count}{$color}{$number};
            }
            if ( $total == $total_revealed ) {
                for my $i ( 0 .. @{ $self->{hands}[$player] } - 1 ) {
                    my $card = $self->{hands}[$player][$i];
                    if ( !defined $card->{known_information}{number}{$number} )
                    {
                        $card->{known_information}{number}{$number} = 0;
                        $card->{known_information}{number_score}++;
                        $information_gained++;
                    }
                }
            }
        }

        # Is there a dead color?
        for my $color (@colors) {
            my $total          = 0;
            my $total_revealed = 0;
            for my $number (@numbers) {
                $total_revealed += $self->revealed_count( $player,
                    { number => $number, color => $color } );
                $total += $self->{starting_count}{$color}{$number};
            }
            if ( $total == $total_revealed ) {
                for my $i ( 0 .. @{ $self->{hands}[$player] } - 1 ) {
                    my $card = $self->{hands}[$player][$i];
                    if ( !defined $card->{known_information}{color}{$color} ) {
                        $card->{known_information}{color}{$color} = 0;
                        $card->{known_information}{color_score}++;
                        $information_gained++;
                    }
                }
            }
        }

    }

    if ($information_gained) {

        # Recompute the total scores and derive again
        for my $player ( 0 .. $self->{players} - 1 ) {
            for my $i ( 0 .. @{ $self->{hands}[$player] } - 1 ) {
                my $card = $self->{hands}[$player][$i];
                $card->{known_information}{score} =
                  $card->{known_information}{number_score} +
                  $card->{known_information}{color_score};
            }
        }

        $self->derive_information(1);
    }
    return;
}

# How may copies of $card does $player know about?
sub revealed_count {
    my $self = shift;
    my ( $player, $card ) = @_;
    return $revealed_cache{$player}{ $card->{color} }{ $card->{number} }
      if $revealed_cache{$player}{ $card->{color} }{ $card->{number} };

    # If all copies of a card are revealed, stop looking
    my $color  = $card->{color};
    my $number = $card->{number};
    my $count  = $self->{public_count}{$color}{$number};
    if ( $self->{starting_count}{$color}{$number} == $count ) {
        $revealed_cache{$player}{ $card->{color} }{ $card->{number} } = $count;
        return $count;
    }

    # Look for cards in players' hands... even our own
    for my $p ( 0 .. $self->{players} - 1 ) {
        if ( $p == $player ) {
            $count += grep {
                     $_->{known_information}{color}{$color}
                  && $_->{known_information}{number}{$number}
            } @{ $self->{hands}[$player] };
        }
        else {
            $count += grep { $_->{color} eq $color && $_->{number} == $number }
              @{ $self->{hands}[$p] };
        }
    }
    $revealed_cache{$player}{ $card->{color} }{ $card->{number} } = $count;
    return $count;
}

sub is_card_known {
    my $self = shift;
    my ($card) = @_;
    return $card
      if $card->{known_information}{score}
      && $card->{known_information}{score} == 20;
    return;
}

sub is_color_known {
    my $self = shift;
    my ($card) = @_;
    return $card->{color}
      if $card->{known_information}{color_score}
      && $card->{known_information}{color_score} == 10;
    return;
}

sub is_number_known {
    my $self = shift;
    my ($card) = @_;
    return $card->{number}
      if $card->{known_information}{number_score}
      && $card->{known_information}{number_score} == 10;
    return;
}

sub print_game_state {
    my $self = shift;

    # Print the piles
    print "-----------------------------------------\n";
    print "Board: ";
    for my $color ( keys %{ $self->{top_card} } ) {
        print $color . $self->{top_card}{$color} . " ";
    }
    print "\n";

    # Print the hands
    for my $i ( 0 .. $self->{players} - 1 ) {
        print "Player $i: ";
        for my $card ( @{ $self->{hands}[$i] } ) {
            print $card->{color} . $card->{number} . ' ';
        }
        print "\n";
    }
    print "\n";

    # Print the discard pile
    print "Discards: ";
    for my $card ( @{ $self->{discards} } ) {
        print $card->{color} . $card->{number} . ' ';
    }
    print "\n";

    # Print the deck size, turns left, and bombs
    print "Turn: " . $self->{turn};
    print "\tHints: " . $self->{hints};
    print "\tScore: " . $self->{score};
    print "\tDeck: " . scalar @{ $self->{deck} };
    print "\tBombs: " . $self->{bombs};
    print "\tTurns Left: " . $self->{countdown} if defined $self->{countdown};
    print "\n\n";
    return;
}

1;

__END__

=pod

=head1 NAME

Games::Hanabi - rules engine for the 'hanabi' card game

=head1 VERSION

version 0.001

=head1 DESCRIPTION

Hanabi is a card game in which players take turns playing cards
in 5 suits, sequentially from 1 to 5.  The catch is that players
can only see each others' hands, and not their own.
They must give hints to each in order to succceed.

This distribution implements the rules for the game (no variations).

C<Games::Hanabi> itself tracks everything needed for a game of Hanabi.

To see an example of this module in use, look at the attached script bin/hanabi_ai.pl

=head1 METHODS

=head2 Constructor

=over 4

=item * my $game = Games::Hanabi->new(players=>2, derive=>1, debug=>0);

Create a new hanabi game. All params are optional.

=over 4

=item * players: the number of players in the game.  Starting player is random. (default 2)	

=item * derive: tell the game to deduce information about cards in players' hands.
	For example, if a player knows a card is not 1, 2, 3, or 4, it must be a 5. (default true)
	This greatly slows down turn processing.

=item * debug: Print some addition debug messages during a game. (default false)	
	
=back

=back

=head2 Game State

The game state is represented by a deep data structure described below.
If is accessed via 

  my $game_state = $game->get_game_state();

A game state is a hash with the following keys:  

=over 4

=item * players

The number of players in the game.

=item * turn

The current player.  0-index so 0 is player 1, 1 is player 2, etc.

=item * score

The score that the players have earned so far.

=item * hints

The number of hints remaining.

=item * bombs

The number of times the players have made invalid plays, 
earning a bomb.

=item * countdown

The number of turns remaining before the game ends.
Before the deck is empty, this is undefined.
Afterwards, it is set to the number of players,
and decremented on each player's turn.

=item * top_card

A hash with keys of B, G, R, W, and Y (the card colors).
The values of each is the highest card legally played in that color.

=item * hands

An array of hands, with 1 entry per player.
Each player's hand is an array of cards.
A card is a hashref with the following keys:

=over 4

=item * color

The color of the card.  One of B, G, R, W, or Y.

=item * number

The number of the card.  One of 1, 2, 3, 4, or 5.

=item * color_score

A score representing how much information is known about the card's color.
10 points for positive information (i.e. the card is blue), or
1 point for each piece of negative information (i.e. the card is not blue).

=item * number_score

A score representing how much information is known about the card's number.
10 points for positive information (i.e. the card is a 3), or
1 point for each piece of negative information (i.e. the card is a 3).

=item * score

A score representing how much information is known about the card.
score = color_score + number_score.

=item * known_information

A hashref with keys color and number representing what the holder of the
card knows about this card.

=over 4

=item * color

A hashref with keys of B, G, R, W, and Y.
Each value is one of:
  0 - the card is not that color
  1 - the card is that color
  undef - Unknown either way

=item * number

A hashref with keys of 1, 2, 3, 4, and 5.
Each value is one of:
  0 - the card is not that number
  1 - the card is that number
  undef - Unknown either way

=back

=back

=item * deck

An arrayref of cards representing the deck.

=item * discards

An arrayref of cards that have been discarded.

=back

A card hash may have addition information used for internal record-keeping,
but it is not reliable.

=head2 Public methods

=over 4

=item * $game->get_valid_moves()

Return an array of moves that are valid for the current player.
If the games is over, there are no valid moves, so return undef.
The moves will have one of the following forms:

=over 4

=item * { action => 'play', index => 3 }

Play the card with index 3 (i.e. the 4th card) from your hand.

=item * { action => 'discard', index => 3 }

Discard the card with index 3 (i.e. the 4th card) from your hand.

=item * { action => 'hint', hint => 'G', player => 1 }

Tell the player with index 1 (i.e. player 2) which cards in their hand are Green.

=back

=item * $game->take_action($action)

Perform a valid game action.  $action is of the form returned by get_valid_moves()
Once the action is taken, move on to the next player's turn.

=item * $game->is_valid_play($card)

Boolean.  Return whether the card can be played without triggering a bomb.

=item * $game->is_valid_known_play($card)

Boolean.  Return whether the card can be played without triggering a bomb,
using only the information the holder of the card knows about it.
When unknown, return false.

=item * $game->is_junk($card, $known)

Boolean.  Return whether the card is obsolete for this game,
from the perspective of the holder of the card.
If $known is true, then use perfect information instead.

=item * max_score_for_color($color)

Return the highest score a color can still earn (1-5).
For example, if all of he Green 3's are discarded, the
highest max score for Green is 2.

=item * is_card_known($card)

Boolean.  Return whether the card's number AND color are known by the holding player.

=item * is_number_known($card)

Boolean.  Return whether the card's number is known by the holding player.

=item * is_card_known($card)

Boolean.  Return whether the card's color is known by the holding player.

=item * print_game_state()

Print a basic representation of the game state to the screen.

=back

=head1 BUGS

Please report any bugs or feature requests to C<bug-games-hanabi at
rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Games-Hanabi>.  I will be
notified, and then you'll automatically be notified of progress on your
bug as I make changes.

=head1 ACKNOWLEDGEMENTS

I definitely recommend you to buy a C<hanabi> card game and play with
friends, you'll have an exciting time.

=head1 SEE ALSO

You can find more information on the C<hanabi> game on wikipedia
at L<http://en.wikipedia.org/wiki/Hanabi>.

You can find more information on this module at:

=over 4

=item * Search CPAN

L<http://search.cpan.org/dist/Games-Hanabi>

=item * See open / report bugs

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Games-Hanabi>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Games-Hanabi>

=back

=head1 AUTHOR

Jeff Till

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2014 by Jeff Till.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
