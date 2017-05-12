#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::Exception;

use Game::WordBrain::Letter;
use Game::WordBrain::WordToFind;
use Game::WordBrain;

use Readonly;
Readonly my $WORD_TO_FIND => Game::WordBrain::WordToFind->new({ num_letters => 8 });
Readonly my $GAME         => Game::WordBrain->new({
    letters => [
        Game::WordBrain::Letter->new({ letter => 'a', row => 0, col => 0 }),
        Game::WordBrain::Letter->new({ letter => 'b', row => 0, col => 1 }),
        Game::WordBrain::Letter->new({ letter => 'c', row => 0, col => 2 }),
        Game::WordBrain::Letter->new({ letter => 'd', row => 1, col => 0 }),
        Game::WordBrain::Letter->new({ letter => 'e', row => 1, col => 1 }),
        Game::WordBrain::Letter->new({ letter => 'f', row => 1, col => 2 }),
        Game::WordBrain::Letter->new({ letter => 'g', row => 2, col => 0 }),
        Game::WordBrain::Letter->new({ letter => 'h', row => 2, col => 1 }),
        Game::WordBrain::Letter->new({ letter => 'i', row => 2, col => 2 }),
    ],
    words_to_find => [ $WORD_TO_FIND ],
});

subtest 'Middle - Nothing Used' => sub {
    my $near_letters;
    lives_ok {
        $near_letters = $GAME->find_near_letters({
            used       => [ ],
            row_number => 1,
            col_number => 1,
        });
    } 'Lives through finding near letters';

    cmp_ok( scalar @{ $near_letters }, '==', 8, 'Correct number of near letters' );

    for my $expected_letter (qw( a b c d f g h i )) {
        ok( ( grep { $_->{letter} eq $expected_letter } @{ $near_letters } ), "Correctly found $expected_letter" );
    }
};

subtest 'Middle - Some Used' => sub {
    my $near_letters;
    lives_ok {
        $near_letters = $GAME->find_near_letters({
            used       => [ map { $GAME->{letters}->[$_] } qw( 0 1 5 7 ) ],
            row_number => 1,
            col_number => 1,
        });
    } 'Lives through finding near letters';

    cmp_ok( scalar @{ $near_letters }, '==', 4, 'Correct number of near letters' );

    for my $expected_letter (qw( c d g i )) {
        ok( ( grep { $_->{letter} eq $expected_letter } @{ $near_letters } ), "Correctly found $expected_letter" );
    }
};

subtest 'Middle - All Used' => sub {
    my $near_letters;
    lives_ok {
        $near_letters = $GAME->find_near_letters({
            used       => [ map { $GAME->{letters}->[$_] } qw( 0 1 2 3 5 6 7 8 ) ],
            row_number => 1,
            col_number => 1,
        });
    } 'Lives through finding near letters';

    cmp_ok( scalar @{ $near_letters }, '==', 0, 'Correct number of near letters' );
};

subtest 'Top Left' => sub {
    my $near_letters;
    lives_ok {
        $near_letters = $GAME->find_near_letters({
            used       => [ ],
            row_number => 0,
            col_number => 0,
        });
    } 'Lives through finding near letters';

    cmp_ok( scalar @{ $near_letters }, '==', 3, 'Correct number of near letters' );

    for my $expected_letter (qw( b d e )) {
        ok( ( grep { $_->{letter} eq $expected_letter } @{ $near_letters } ), "Correctly found $expected_letter" );
    }
};

subtest 'Top Right' => sub {
    my $near_letters;
    lives_ok {
        $near_letters = $GAME->find_near_letters({
            used       => [ ],
            row_number => 0,
            col_number => 2,
        });
    } 'Lives through finding near letters';

    cmp_ok( scalar @{ $near_letters }, '==', 3, 'Correct number of near letters' );

    for my $expected_letter (qw( b e f )) {
        ok( ( grep { $_->{letter} eq $expected_letter } @{ $near_letters } ), "Correctly found $expected_letter" );
    }
};

subtest 'Bottom Left' => sub {
    my $near_letters;
    lives_ok {
        $near_letters = $GAME->find_near_letters({
            used       => [ ],
            row_number => 2,
            col_number => 0,
        });
    } 'Lives through finding near letters';

    cmp_ok( scalar @{ $near_letters }, '==', 3, 'Correct number of near letters' );

    for my $expected_letter (qw( d e h )) {
        ok( ( grep { $_->{letter} eq $expected_letter } @{ $near_letters } ), "Correctly found $expected_letter" );
    }
};

subtest 'Bottom Right' => sub {
    my $near_letters;
    lives_ok {
        $near_letters = $GAME->find_near_letters({
            used       => [ ],
            row_number => 2,
            col_number => 2,
        });
    } 'Lives through finding near letters';

    cmp_ok( scalar @{ $near_letters }, '==', 3, 'Correct number of near letters' );

    for my $expected_letter (qw( e f h  )) {
        ok( ( grep { $_->{letter} eq $expected_letter } @{ $near_letters } ), "Correctly found $expected_letter" );
    }
};

subtest 'No Direct Path' => sub {
    my $near_letters;
    lives_ok {
        $near_letters = $GAME->find_near_letters({
            used       => [ map { $GAME->{letters}->[$_] } qw( 1 3 4 ) ],
            row_number => 0,
            col_number => 0,
        });
    } 'Lives through finding near letters';

    cmp_ok( scalar @{ $near_letters }, '==', 0, 'Correct number of near letters' );
};

done_testing;
