use strict;
use warnings;
use Test::More;
use Data::Dumper;
BEGIN { use_ok('Games::Hanabi') }

my @colors  = qw(R G B Y W);
my @numbers = qw(1 2 3 4 5);

test_new();
test_draw();
test_get_valid_moves();
test_take_action();
test_devive_information();
done_testing();

# Test new and get_game_state
sub test_new {
    my $game = Games::Hanabi->new( players => 2 );
    ok( defined $game, 'game is defined' );

    # Each player should have 5 cards
    my $state = $game->get_game_state();
    is( scalar @{ $state->{hands}[0] }, 5, 'player 0 has 5 cards' );
    is( scalar @{ $state->{hands}[1] }, 5, 'player 1 has 5 cards' );

    # The deck should have 40 cards left
    is( scalar @{ $state->{deck} }, 40, 'deck has 30 cards' );

    # 8 hints, 0 bombs, etc...
    is( $state->{hints},       8,     '8 starting hints' );
    is( $state->{bombs},       0,     '0 starting bombs' );
    is( $state->{score},       0,     '0 starting score' );
    is( $state->{top_card}{G}, 0,     '0 starting top card for green' );
    is( $state->{countdown},   undef, 'countdown does not exist yet' );
    return;
}

sub test_draw {
    my $game = Games::Hanabi->new( players => 2 );

    my $state = $game->get_game_state();
    my @current_hand =
      map { $_->{color} . $_->{number} } @{ $state->{hands}[0] };
    my $deck_count = scalar @{ $state->{deck} };

    # Throw out a card and draw a new one
    pop @{ $state->{hands}[0] };
    $game->_draw(0);
    my @new_hand = map { $_->{color} . $_->{number} } @{ $state->{hands}[0] };
    for my $i ( 0 .. 3 ) {
        is( $current_hand[$i], $new_hand[$i], "card $i is the same" );
    }
    ok( $current_hand[4] ne $new_hand[4], 'new card does not match' );
    my $new_deck_count = scalar @{ $state->{deck} };
    is( $new_deck_count + 1, $deck_count, 'deck size went down' );

    # Draw 40 more cards and the deck runs out
    for my $i ( 0 .. 39 ) {
        pop @{ $state->{hands}[0] };
        $game->_draw(0);
    }
    $state = $game->get_game_state();
    is( $state->{countdown}, 2, 'the countdown has begun' );
    return;
}

sub test_get_valid_moves {
    my $game = Games::Hanabi->new( players => 2 );
    my $state = $game->get_game_state();

    # Fake the player's hands to test the valid moves
    $game->{turn}      = 0;
    $state->{hands}[0] = build_cards(qw(G1 G1 G1 G4 G5));
    $state->{hands}[1] = build_cards(qw(Y2 Y2 R2 R2 B2));

    my @valid_moves    = $game->get_valid_moves();
    my $expected_moves = [
        {
            'index'  => 0,
            'action' => 'play'
        },
        {
            'index'  => 0,
            'action' => 'discard'
        },
        {
            'index'  => 1,
            'action' => 'play'
        },
        {
            'index'  => 1,
            'action' => 'discard'
        },
        {
            'index'  => 2,
            'action' => 'play'
        },
        {
            'index'  => 2,
            'action' => 'discard'
        },
        {
            'index'  => 3,
            'action' => 'play'
        },
        {
            'index'  => 3,
            'action' => 'discard'
        },
        {
            'index'  => 4,
            'action' => 'play'
        },
        {
            'index'  => 4,
            'action' => 'discard'
        },
        {
            'hint'   => 'B',
            'action' => 'hint',
            'player' => 1
        },
        {
            'hint'   => 'R',
            'action' => 'hint',
            'player' => 1
        },
        {
            'hint'   => 'Y',
            'action' => 'hint',
            'player' => 1
        },
        {
            'hint'   => '2',
            'action' => 'hint',
            'player' => 1
        }
    ];
    is_deeply( \@valid_moves, $expected_moves, 'move are as expected' );

    # 3 bombs ends the game
    $game->{bombs} = 3;
    @valid_moves = $game->get_valid_moves();
    is( scalar @valid_moves, 0, 'no valid moves when the bombs have gone off' );

    $game->{bombs}     = 0;
    $game->{countdown} = 0;
    @valid_moves       = $game->get_valid_moves();
    is( scalar @valid_moves, 0, 'no valid moves when the countdown is over' );

    $game->{countdown} = 5;
    $game->{score}     = 25;
    @valid_moves       = $game->get_valid_moves();
    is( scalar @valid_moves, 0, 'no valid moves when we have won' );

    return;
}

sub test_take_action {
    my $game = Games::Hanabi->new( players => 2 );
    my $state = $game->get_game_state();

    # Fake the player's hands to test the valid moves
    $game->{turn}     = 0;
    $game->{hands}[0] = build_cards(qw(G1 G1 G1 G4 G5));
    $game->{hands}[1] = build_cards(qw(Y2 Y2 R2 R2 B2));
    $game->{deck}     = build_cards(qw(Y5 R5 B5 Y4 R4 B4));

    # Give a color hint, which will update known information
    $game->take_action( { action => 'hint', player => 1, hint => 'R' } );
    $state = $game->get_game_state();
    is( $state->{hints}, 7, 'a hint got consumed' );
    my $info = $state->{hands}[1][2]{known_information};
    is( $info->{color}{R},    1,  'card is known to be red' );
    is( $info->{color_score}, 10, 'color score is max' );
    is( $info->{score},       10, 'score is same as color score' );
    is_deeply( $state->{hands}[1][2], $state->{hands}[1][3], 'cards match' );

    $info = $state->{hands}[1][0]{known_information};
    is( $info->{color}{R},    0,     'card is known to be NOT red' );
    is( $info->{color}{G},    undef, 'we have no information about green' );
    is( $info->{color_score}, 1,     'color score is small' );
    is( $info->{score},       1,     'score is same as color score' );

    is( $state->{turn}, 1, 'turn counter advanced' );

    # Give a number hint now
    $game->take_action( { action => 'hint', player => 0, hint => 4 } );
    $state = $game->get_game_state();
    is( $state->{hints}, 6, 'a hint got consumed' );
    $info = $state->{hands}[0][3]{known_information};
    is( $info->{number}{4},    1,  'card is known to be 4' );
    is( $info->{number_score}, 10, 'number score is max' );
    is( $info->{score},        10, 'score is same as number score' );

    $info = $state->{hands}[0][0]{known_information};
    is( $info->{number}{4},    0,     'card is known to be NOT 4' );
    is( $info->{number}{5},    undef, 'we have no information about 5' );
    is( $info->{number_score}, 1,     'number score is small' );
    is( $info->{score},        1,     'score is same as number score' );

    is( $state->{turn}, 0, 'turn counter advanced back' );

    # Discard card 2, and get a new card and the hint back
    $game->take_action( { action => 'discard', index => 2 } );
    $state = $game->get_game_state();
    my @new_hand = map { $_->{color} . $_->{number} } @{ $state->{hands}[0] };
    is( "@new_hand", "G1 G1 G4 G5 Y5", 'new card added to the end' );
    is( $state->{discards}[0]->{color},  'G', 'green was discarded' );
    is( $state->{discards}[0]->{number}, 1,   '1 was discarded' );
    is( $game->{public_count}{G}{1},     1,   "1 cards is known to all now" );
    is( $state->{hints},                 7,   'got a hint back' );

    # Discard twice more, but hints cap at 8
    $game->take_action( { action => 'discard', index => 4 } );
    $game->take_action( { action => 'discard', index => 4 } );
    is( $game->{hints}, 8, 'hints capped at 8' );

    # Try playing cards
    $game->{turn} = 0;
    $game->take_action( { action => 'play', index => 0 } );
    $state = $game->get_game_state();
    is( $state->{bombs},       0, 'valid card = no bomb' );
    is( $state->{top_card}{G}, 1, 'top card for G updated' );
    is( $state->{score},       1, 'we scored a point' );
    @new_hand = map { $_->{color} . $_->{number} } @{ $state->{hands}[0] };
    is( "@new_hand", "G1 G4 G5 B5 Y4", 'new card added to the end' );
    is( $game->{public_count}{G}{1}, 2, "2 cards is known to all now" );

    # Finally play an invalid card
    $game->{turn} = 0;
    $game->take_action( { action => 'play', index => 0 } );
    $state = $game->get_game_state();
    is( $state->{bombs},       1, 'invalid card = bomb' );
    is( $state->{top_card}{G}, 1, 'top card for G the same' );
    is( $state->{score},       1, 'score not updated' );
    @new_hand = map { $_->{color} . $_->{number} } @{ $state->{hands}[0] };
    is( "@new_hand", "G4 G5 B5 Y4 R4", 'new card added to the end' );
    is( $game->{public_count}{G}{1}, 3, "3 cards is known to all now" );

    #warn Dumper $state->{hands}[1][2];
    return;
}

sub test_devive_information {
    my $game = Games::Hanabi->new( players => 2 );
    my $state = $game;
    $state->{hands}[0] = build_cards(qw(G1 G1 G1 G4 G5));
    $state->{hands}[1] = build_cards(qw(Y2 Y2 R2 R2 B2));

    # Mark every card as known
    for my $card ( @{ $game->{starting_deck} } ) {
        $game->{public_count}{ $card->{color} }{ $card->{number} }++;
    }

    # Except the cards in our hands
    for my $player ( 0 .. 1 ) {
        for my $card ( @{ $state->{hands}[$player] } ) {
            $game->{public_count}{ $card->{color} }{ $card->{number} }--;
        }
    }

    $game->derive_information();

    # Player 0 knows all his cards are Green, and not 2, 3
    my $expected_info = {
        'color' => {
            'W' => 0,
            'R' => 0,
            'G' => 1,
            'Y' => 0,
            'B' => 0
        },
        'number' => {
            '3' => 0,
            '2' => 0
        }
    };
    for my $card ( @{ $state->{hands}[0] } ) {
        is_deeply(
            $card->{known_information}{color},
            $expected_info->{color},
            'greens color look good'
        );
        is_deeply(
            $card->{known_information}{number},
            $expected_info->{number},
            'greens number look good'
        );
    }

    # Player knows all of his cards are 2's, not Green or White
    $expected_info = {
        'color' => {
            'W' => 0,
            'G' => 0
        },
        'number' => {
            '4' => 0,
            '1' => 0,
            '3' => 0,
            '2' => 1,
            '5' => 0
        }
    };
    for my $card ( @{ $state->{hands}[1] } ) {
        is_deeply(
            $card->{known_information}{color},
            $expected_info->{color},
            '2s color look good'
        );
        is_deeply(
            $card->{known_information}{number},
            $expected_info->{number},
            '2s number look good'
        );
    }

    # If we know that the 1st card isn't a 4 or 5, we can deduce it's a 1
    $state->{hands}[0] = build_cards(qw(G1 G1 G1 G4 G5));
    $state->{hands}[0][0]{known_information}{number} = { 4 => 0, 5 => 0 };
    $game->derive_information();
    is( $state->{hands}[0][0]{known_information}{number}{1},
        1, 'figured out we have a 1' );

    return;
}

# Convert array of strings of cards into an AoH.
sub build_cards {
    my (@cards) = @_;
    my @list;
    for my $card (@cards) {
        my ( $color, $number ) = split //, $card;
        push @list,
          {
            color  => $color,
            number => $number,
            known_information =>
              { score => 0, number_score => 0, color_score => 0 }
          };
    }
    return \@list;
}
