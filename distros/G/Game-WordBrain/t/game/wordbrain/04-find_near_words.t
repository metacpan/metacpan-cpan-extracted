#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::Exception;

use Game::WordBrain::Letter;
use Game::WordBrain::Word;
use Game::WordBrain::WordToFind;
use Game::WordBrain;

use Readonly;
Readonly my $WORD_TO_FIND => Game::WordBrain::WordToFind->new({ num_letters => 4 });

subtest '2x2' => sub {
    my $let_t = Game::WordBrain::Letter->new({ letter => 't', row => 0, col => 0 });
    my $let_a = Game::WordBrain::Letter->new({ letter => 'a', row => 0, col => 1 });
    my $let_l = Game::WordBrain::Letter->new({ letter => 'l', row => 1, col => 0 });
    my $let_k = Game::WordBrain::Letter->new({ letter => 'k', row => 1, col => 1 });

     my $game = Game::WordBrain->new({
        letters => [ $let_t, $let_a, $let_l, $let_k ],
        words_to_find => [ $WORD_TO_FIND ],
    });

    inspect_found_words({
        letter         => $game->{letters}->[0],
        game           => $game,
        expected_words => [
            Game::WordBrain::Word->new({ letters => [ $let_t, $let_a, ] }),
            Game::WordBrain::Word->new({ letters => [ $let_t, $let_a, $let_l, ] }),
            Game::WordBrain::Word->new({ letters => [ $let_t, $let_a, $let_l, $let_k, ] }),
            Game::WordBrain::Word->new({ letters => [ $let_t, $let_a, $let_k, ] }),
            Game::WordBrain::Word->new({ letters => [ $let_t, $let_a, $let_k, $let_l, ] }),
            Game::WordBrain::Word->new({ letters => [ $let_t, $let_l, ] }),
            Game::WordBrain::Word->new({ letters => [ $let_t, $let_l, $let_a, ] }),
            Game::WordBrain::Word->new({ letters => [ $let_t, $let_l, $let_a, $let_k, ] }),
            Game::WordBrain::Word->new({ letters => [ $let_t, $let_l, $let_k, ] }),
            Game::WordBrain::Word->new({ letters => [ $let_t, $let_k, ] }),
            Game::WordBrain::Word->new({ letters => [ $let_t, $let_k, $let_a, ] }),
            Game::WordBrain::Word->new({ letters => [ $let_t, $let_k, $let_l, ] })
        ],
    });

    inspect_found_words({
        letter         => $game->{letters}->[1],
        game           => $game,
        expected_words => [
            Game::WordBrain::Word->new({ letters => [ $let_a, $let_t, ] }),
            Game::WordBrain::Word->new({ letters => [ $let_a, $let_t, $let_l, ] }),
            Game::WordBrain::Word->new({ letters => [ $let_a, $let_t, $let_l, $let_k, ] }),
            Game::WordBrain::Word->new({ letters => [ $let_a, $let_t, $let_k, ] }),
            Game::WordBrain::Word->new({ letters => [ $let_a, $let_l, ] }),
            Game::WordBrain::Word->new({ letters => [ $let_a, $let_l, $let_t, ] }),
            Game::WordBrain::Word->new({ letters => [ $let_a, $let_l, $let_t, $let_k, ] }),
            Game::WordBrain::Word->new({ letters => [ $let_a, $let_l, $let_k, ] }),
            Game::WordBrain::Word->new({ letters => [ $let_a, $let_l, $let_k, $let_t, ] }),
            Game::WordBrain::Word->new({ letters => [ $let_a, $let_k, ] }),
            Game::WordBrain::Word->new({ letters => [ $let_a, $let_k, $let_t, ] }),
            Game::WordBrain::Word->new({ letters => [ $let_a, $let_k, $let_t, $let_l, ] }),
            Game::WordBrain::Word->new({ letters => [ $let_a, $let_k, $let_l, ] }),
        ],
    });

    inspect_found_words({
        letter         => $game->{letters}->[2],
        game           => $game,
        expected_words => [
            Game::WordBrain::Word->new({ letters => [ $let_l, $let_t, ] }),
            Game::WordBrain::Word->new({ letters => [ $let_l, $let_t, $let_a, ] }),
            Game::WordBrain::Word->new({ letters => [ $let_l, $let_t, $let_k, ] }),
            Game::WordBrain::Word->new({ letters => [ $let_l, $let_a, ] }),
            Game::WordBrain::Word->new({ letters => [ $let_l, $let_a, $let_t, ] }),
            Game::WordBrain::Word->new({ letters => [ $let_l, $let_a, $let_t, $let_k, ] }),
            Game::WordBrain::Word->new({ letters => [ $let_l, $let_a, $let_k, ] }),
            Game::WordBrain::Word->new({ letters => [ $let_l, $let_a, $let_k, $let_t, ] }),
            Game::WordBrain::Word->new({ letters => [ $let_l, $let_k, ] }),
        ],
    });

    inspect_found_words({
        letter         => $game->{letters}->[3],
        game           => $game,
        expected_words => [
            Game::WordBrain::Word->new({ letters => [ $let_k, $let_t, ] }),
            Game::WordBrain::Word->new({ letters => [ $let_k, $let_t, $let_a, ] }),
            Game::WordBrain::Word->new({ letters => [ $let_k, $let_t, $let_l, ] }),
            Game::WordBrain::Word->new({ letters => [ $let_k, $let_a, ] }),
            Game::WordBrain::Word->new({ letters => [ $let_k, $let_a, $let_t, ] }),
            Game::WordBrain::Word->new({ letters => [ $let_k, $let_a, $let_t, $let_l, ] }),
            Game::WordBrain::Word->new({ letters => [ $let_k, $let_a, $let_l, ] }),
            Game::WordBrain::Word->new({ letters => [ $let_k, $let_a, $let_l, $let_t, ] }),
            Game::WordBrain::Word->new({ letters => [ $let_k, $let_l, ] }),
            Game::WordBrain::Word->new({ letters => [ $let_k, $let_l, $let_t, ] }),
            Game::WordBrain::Word->new({ letters => [ $let_k, $let_l, $let_a, ] }),
            Game::WordBrain::Word->new({ letters => [ $let_k, $let_l, $let_a, $let_t, ] }),
        ],
    });
};

done_testing;

sub inspect_found_words {
    my $args = shift;

    my $words;

    my $subtest_name = sprintf("Letter '%s' at %d x %d",
        $args->{letter}{letter}, $args->{letter}{row}, $args->{letter}{col} );
    subtest $subtest_name => sub {
        $words = $args->{game}->find_near_words({
            letter => $args->{letter},
        });

        # Used for constructing the expected words
=cut
        for my $word (@{ $words }) {
            print "Game::WordBrain::Word->new({ letters => [";
            for my $letter (@{ $word->{letters} }) {
                printf ' $let_%s,', $letter->{letter};
            }
            print " ] }),\n";
        }
=cut


        cmp_ok( scalar @{ $words }, '==', scalar @{ $args->{expected_words} }, 'Correct number of words' );

        subtest 'Inspect Found Words' => sub {
            for( my $word_index = 0; $word_index < scalar @{ $words }; $word_index++ ) {
                my $found_word    = $words->[ $word_index ];
                my $expected_word = $args->{expected_words}->[ $word_index ];

                is_deeply( $found_word, $expected_word, 'Found ' . $expected_word );
            }
        };
    };

    return $words;
}

