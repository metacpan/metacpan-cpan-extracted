#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::Exception;
use Test::Deep;

use Game::WordBrain::Letter;
use Game::WordBrain::Word;
use Game::WordBrain::WordToFind;
use Game::WordBrain;

subtest '2x2 - 1 Word' => sub {
    my @letters;
    push @letters, Game::WordBrain::Letter->new({ letter => 't', row => 0, col => 0 });
    push @letters, Game::WordBrain::Letter->new({ letter => 'a', row => 0, col => 1 });
    push @letters, Game::WordBrain::Letter->new({ letter => 'l', row => 1, col => 0 });
    push @letters, Game::WordBrain::Letter->new({ letter => 'k', row => 1, col => 1 });

    my @words_to_find;
    push @words_to_find, Game::WordBrain::WordToFind->new({ num_letters => 4 });

    my $game;
    subtest 'Play Game' => sub {
        lives_ok {
            $game = Game::WordBrain->new({
                letters       => \@letters,
                words_to_find => \@words_to_find,
            });
        } 'Lives through bulding game';

        lives_ok {
            $game->solve();
        } 'Lives through solving game';
    };

    subtest 'Check Solutions' => sub {
        if( cmp_ok( scalar @{ $game->{solutions} }, '==', 1, 'Correct number of solutions' ) ) {
            my $solution = $game->{solutions}->[0];

            if( cmp_ok( scalar @{ $solution->{words} }, '==', 1, 'Correct number of words in solution' ) ) {
                my $word = $solution->{words}->[0];

                cmp_ok( $word->word, 'eq', 'talk', 'Correct word in solution' );

                for my $letter_index ( 0 .. 3 ) {
                    is_deeply( $word->{letters}->[ $letter_index ], $letters[ $letter_index ],
                        "Correct letter at $letter_index" );
                }
            }
        }
    };
};

subtest '3x3 - 2 Words' => sub {
    my @letters;
    push @letters, Game::WordBrain::Letter->new({ letter => 'l', row => 0, col => 0 });
    push @letters, Game::WordBrain::Letter->new({ letter => 's', row => 0, col => 1 });
    push @letters, Game::WordBrain::Letter->new({ letter => 'e', row => 0, col => 2 });
    push @letters, Game::WordBrain::Letter->new({ letter => 'l', row => 1, col => 0 });
    push @letters, Game::WordBrain::Letter->new({ letter => 'i', row => 1, col => 1 });
    push @letters, Game::WordBrain::Letter->new({ letter => 'd', row => 1, col => 2 });
    push @letters, Game::WordBrain::Letter->new({ letter => 'l', row => 2, col => 0 });
    push @letters, Game::WordBrain::Letter->new({ letter => 'o', row => 2, col => 1 });
    push @letters, Game::WordBrain::Letter->new({ letter => 'd', row => 2, col => 2 });

    my @words_to_find;
    push @words_to_find, Game::WordBrain::WordToFind->new({ num_letters => 5 });
    push @words_to_find, Game::WordBrain::WordToFind->new({ num_letters => 4 });

    my $game;
    subtest 'Play Game' => sub {
        lives_ok {
            $game = Game::WordBrain->new({
                letters       => \@letters,
                words_to_find => \@words_to_find,
            });
        } 'Lives through bulding game';

        lives_ok {
            $game->solve();
        } 'Lives through solving game';
    };

    subtest 'Check Solutions' => sub {
        my $expected_solution = [qw( slide doll )];

        if( cmp_ok( scalar @{ $game->{solutions} }, '==', 73, 'Correct number of solutions' ) ) {
            my $found_solution = 0;
            for my $solution (@{ $game->{solutions} }) {
                if( $solution->{words}->[0]->word eq $expected_solution->[0]
                 && $solution->{words}->[1]->word eq $expected_solution->[1] ) {
                    $found_solution = 1;
                    last;
                }
            }

            ok( $found_solution, 'Expected Solution Was Found' );
        }
    };
};

done_testing;

=cut
        for my $solution (@{ $game->solutions } ) {
            print "===== Posible Solution ====\n";
            for my $word (@{ $solution->words }) {
                print 'Word: ' . $word->word . " |\t";
                for my $letter (@{ $word->letters }) {
                    printf "%s - %d x %d | ", $letter->letter, $letter->row, $letter->col;
                }
                print "\n";
            }
            print "\n";
        }

        for my $solution (@{ $game->solutions } ) {
            print '[qw( ';
            for my $word (@{ $solution->words }) {
                print $word->word . ' ';
            }
            print ")],\n";
        }
=cut

