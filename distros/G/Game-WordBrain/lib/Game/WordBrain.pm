package Game::WordBrain;

use strict;
use warnings;

use Game::WordBrain::Letter;
use Game::WordBrain::Word;
use Game::WordBrain::Solution;
use Game::WordBrain::WordToFind;
use Game::WordBrain::Prefix;
use Game::WordBrain::Speller;

use Storable qw( dclone );
use List::Util qw( reduce first );
use List::MoreUtils qw( first_index );

our $VERSION = '0.2.2'; # VERSION
# ABSTRACT: Solver for Mag Interactive's WordBrain Mobile Game

=head1 NAME

Game::WordBrain - Solver for the Mobile App "WordBrain"

=head1 SYNOPSIS

    # Create a new Game::WordBrain
    my @letters;
    push @letters, Game::WordBrain::Letter->new({ letter => 't', row => 0, col => 0 });
    push @letters, Game::WordBrain::Letter->new({ letter => 'a', row => 0, col => 1 });
    push @letters, Game::WordBrain::Letter->new({ letter => 'l', row => 1, col => 0 });
    push @letters, Game::WordBrain::Letter->new({ letter => 'k', row => 1, col => 1 });

    my $words_to_find = [ Game::WordBrain::WordToFind->... ];
    my $speller       = Game::WordBrain::Speller->...;
    my $prefix        = Game::WordBrain::Prefix->...;

    my $game = Game::WordBrain->new({
        letters       => \@letters,
        words_to_find => $words_to_find,
        speller       => $speller,       # optional
        prefix        => $prefix,        # optional
    });

    # Solve a Game
    $game->solve();
    print "Number of Solutions Found: " . ( scalar @{ $game->{solutions} } ) . "\n";

    # Construct a game without a word
    my $already_used_word = Game::WordBrain::Word->...;
    my $sub_game = $game->construct_game_without_word( $already_used_word  );

    # Get letter at position
    my $letter = $game->get_letter_at_position({
        row => 2,
        col => 3,
    });


    # Find Near letters
    my $near_letters = $game->find_near_letters({
        used       => [ Game::WordBrain::Letter->... ],
        row_number => 1,
        col_number => 1,
    });


    # Find Near Words
    my $near_words = $game->find_near_words({
        letter          => WordBrain::Letter->...,
        used            => [ ],   # Optional
        max_word_length => 5,     # Optional
    });

=head1 DESCRIPTION

Game::WordBrain is a solver created to generation potential solutions for L<Mag Interactive|http://maginteractive.com>'s WordBrain.  WordBrain is available for:

=over 4

=item L<iOS|https://itunes.apple.com/us/app/wordbrain/id708600202?mt=8>

=item L<Android|https://play.google.com/store/apps/details?id=se.maginteractive.wordbrain&hl=en>

=back

This module is currently functional for I<simple> games ( 4x4 and less ) but it requires B<SIGNIFICANT> time to process larger ones.  Feel free to propose improvements at the L<GitHub|https://github.com/drzigman/game-wordbrain> for this repo!

If you are new to WordBrain or simply want a jumpstart on how this module works and it's limitations (and evolution) please see:

=over 4

=item L<YAPC::2016 Presentation on YouTube - "Solving WordBrain - A Depth First Search of a Problem Of Great Breadth"|https://www.youtube.com/watch?v=_1fnTyJg7uA>

=item L<Presentation Slides|https://drive.google.com/file/d/0B7wWgMKY-dDxb1RwMWxRZ3lEWFE/view>

=back

=head1 ATTRIBUTES

=head2 B<letters>

ArrayRef of L<Game::WordBrain::Letter>s that comprise the game field

=head2 B<words_to_find>

ArrayRef of L<Game::WordBrain::WordToFind>s that indicate the number of words to find as well as the length of each word.

=head2 speller

An instance of L<Game::WordBrain::Speller> that is used to spell check potential words.

If this is not provided it will be automagically built.  You generally do not need to provide this but if you wish to use something other than the provided wordlist creating your own L<Game::WordBrain::Speller> and providing it in the call to new would be how to accomplish that.

=head2 prefix

An instance of L<Game::WordBrain::Prefix> used to speed up game play.

If not provided, the max word_to_find will be detected and used to construct it.  You generally do not need to provide this but if you wish to use something other than the provided wordlist creating your own L<Game::WordBrain::Prefix> and providing it in the call to new would be how to accomplish that.

=head2 solutions

Generated after a call to ->solve has been made.  This is an ArrayRef of L<Game::WordBrain::Solution>s.

=head1 METHODS

=head2 new

    my $letters       = [ Game::WordBrain::Letter->... ];
    my $words_to_find = [ Game::WordBrain::WordToFind->... ];
    my $speller       = Game::WordBrain::Speller->...;
    my $prefix        = Game::WordBrain::Prefix->...;

    my $game = Game::WordBrain->new({
        letters       => $letters,
        words_to_find => $words_to_find,
        speller       => $speller,       # optional
        prefix        => $prefix,        # optional
    });

Given an ArrayRef of L<Game::WordBrain::Letter>s, an ArrayRef of L<Game::WordBrain::WordToFind>, and optionally an instance of L<Game::WordBrain::Speller> and L<Game::WordBrain::Prefix> constructs and returns a new WordBrain game.

B<NOTE> While it is also possible to pass solutions => [ Game::WordBrain::Solution->...], there is really no reason for a consumer to do so.

=cut

sub new {
    my $class = shift;
    my $args  = shift;

    if( !exists $args->{solutions} ) {
        $args->{solutions} = undef;
    }

    if( !exists $args->{speller} ) {
        $args->{speller} = Game::WordBrain::Speller->new();
    }

    if( !exists $args->{prefix} ) {
        my $largest_word_to_find = reduce {
            $a->{num_letters} > $b->{num_letters} ? $a : $b
        } @{ $args->{words_to_find} };

        $args->{prefix} = Game::WordBrain::Prefix->new({
            max_prefix_length => $largest_word_to_find->{num_letters}
        });
    }

    return bless $args, $class;
}

=head2 solve

    my @letters;
    push @letters, WordBrain::Letter->new({ letter => 't', row => 0, col => 0 });
    push @letters, WordBrain::Letter->new({ letter => 'a', row => 0, col => 1 });
    push @letters, WordBrain::Letter->new({ letter => 'l', row => 1, col => 0 });
    push @letters, WordBrain::Letter->new({ letter => 'k', row => 1, col => 1 });

    my @words_to_find;
    push @words_to_find, WordBrain::WordToFind->new({ num_letters => 4 });

    my $game = Game::WordBrain->new({
        letters       => \@letters,
        words_to_find => \@words_to_find,
    });

    $game->solve();

    print "Number of Solutions Found: " . ( scalar @{ $game->{solutions} } ) . "\n";

The solve method is the real meat of L<Game::WordBrain>.  When called on a fully formed game this method will enumerate potential solutions and set the $game->{solutions} attribute.

B<NOTE> Depending on the size of the game grid, this method can take a very long time to run.

=cut

sub solve {
    my $self = shift;

    my $max_word_length = 0;
    for my $word_to_find (@{ $self->{words_to_find} }) {
        if( $max_word_length < $word_to_find->{num_letters} ) {
            $max_word_length = $word_to_find->{num_letters};
        }
    }

    my @solutions;
    for my $letter (@{ $self->{letters} }) {
        my $possible_words = $self->find_near_words({
            letter          => $letter,
            max_word_length => $max_word_length,
        });

        my @actual_words;
        for my $possible_word (@{ $possible_words }) {
            if( grep { $_->{num_letters} == length ( $possible_word->word ) } @{ $self->{words_to_find} } ) {
                if( $self->{speller}->is_valid_word( $possible_word ) ) {
                    push @actual_words, $possible_word;
                }
            }
        }


        for my $word ( @actual_words ) {
            if( scalar @{ $self->{words_to_find} } > 1 ) {
                my $updated_game           = $self->construct_game_without_word( $word );
                my $updated_game_solutions = $updated_game->solve();

                for my $updated_game_solution (@{ $updated_game_solutions }) {
                    push @solutions, Game::WordBrain::Solution->new({
                        words => [ $word, @{ $updated_game_solution->{words} } ],
                    });
                }
            }
            else {
                push @solutions, Game::WordBrain::Solution->new({
                    words => [ $word ],
                });
            }
        }
    }

    $self->{solutions} = \@solutions;
}

=head2 construct_game_without_word

    my $word = Game::WordBrain::Word->...;
    my $game = Game::WordBrain->...;

    my $sub_game = $game->construct_game_without_word( $word );

In WordBrain, once a word is matched the letters for it are removed from the playing field, causing all other letters to shift down (think of it like gravity pulling the letters straight down).  This method exists to simplify the process of generating a new instance of a L<Game::WordBrain> from an existing instance minus the found word.

There really isn't a reason for a consumer to call this method directly, rather it is used by the solve method during solution enumeration.

=cut

sub construct_game_without_word {
    my $self       = shift;
    my $found_word = shift;

    my $words_to_find = dclone $self->{words_to_find};
    my $index_of_found_word = first_index {
        $_->{num_letters} == scalar @{ $found_word->{letters} }
    } @{ $self->{words_to_find} };

    splice @{ $words_to_find }, $index_of_found_word, 1;

    my @new_letters;
    for my $letter (@{ $self->{letters} }) {
        if( grep { $_ == $letter } @{ $found_word->{letters} } ) {
            next;
        }

        my $num_letters_used_below = grep {
               $_->{col} == $letter->{col}
            && $_->{row} >  $letter->{row}
        } @{ $found_word->{letters} };

        push @new_letters, Game::WordBrain::Letter->new({
            letter => $letter->{letter},
            row    => $letter->{row} + $num_letters_used_below,
            col    => $letter->{col},
        });
    }

    return Game::WordBrain->new({
        letters       => \@new_letters,
        words_to_find => $words_to_find,
        speller       => $self->{speller},
        prefix        => $self->{prefix},
    });
}

=head2 get_letter_at_position

    my $game = Game::WordBrain->...
    my $letter = $game->get_letter_at_position({
        row => 2,
        col => 3,
    });

Simple convenience method to retrieve the instance of L<Game::WordBrain::Letter> at a given row and col.

=cut

sub get_letter_at_position {
    my $self = shift;
    my $args = shift;

    return first {
           $_->{row} == $args->{row}
        && $_->{col} == $args->{col}
    } @{ $self->{letters} };
}

=head2 find_near_letters

    my $game = Game::WordBrain->...
    my $near_letters = $game->find_near_letters({
        used       => [ Game::WordBrain::Letter->... ],
        row_number => 1,
        col_number => 1,
    });

Given an ArrayRef of already used (for other words) L<Game::WordBrain::Letter>s, and the row and col number of a position, returns an ArrayRef of L<Game::WordBrain::Letter>s that are "near" the specified position.  By "near" we mean a letter that is touching the specified position in one of the 8 cardinal directions and has not already been used.

=cut

sub find_near_letters {
    my $self = shift;
    my $args = shift;

    my @near_letters;
    for my $row_offset ( -1, 0, 1 ) {
        for my $col_offset ( -1, 0, 1 ) {
            if( $row_offset == 0 && $col_offset == 0 ) {
                ### Skipping Center Letter
                next;
            }

            my $near_row_number = $args->{row_number} + $row_offset;
            my $near_col_number = $args->{col_number} + $col_offset;

            my $letter = $self->get_letter_at_position({
                row => $near_row_number,
                col => $near_col_number,
            });

            if( !$letter ) {
                next;
            }

            if( grep { $_ == $letter } @{ $args->{used} } ) {
                ### Skipping Already Used Letter
                next;
            }

            push @near_letters, $letter;
        }
    }

    return \@near_letters;
}

=head2 find_near_words

    my $game = Game::WordBrain->...;
    my $near_words = $game->find_near_words({
        letter          => WordBrain::Letter->...,
        used            => [ ],   # Optional
        max_word_length => 5,     # Optional
    });

Similiar to find_near_letters, but returns an ArrayRef of L<Game::WordBrain::Word>s that can be constructed from the given L<Game::WordBrain::Letter>, ArrayRef of used L<Game::WordBrain::Letter>s and the max_word_length that should be searched for ( this should be the max L<Game::WordBrain::WordToFind>->{num_letters} ).

=cut

sub find_near_words {
    my $self = shift;
    my $args = shift;

    $args->{used} //= [ ];
    $args->{max_word_length} //= scalar @{ $self->{letters} };

    return $self->_find_near_words({
        word_root => Game::WordBrain::Word->new({ letters => [ $args->{letter} ] }),
        letter    => $args->{letter},
        used      => $args->{used},
        max_word_length => $args->{max_word_length},
    });
}

sub _find_near_words {
    my $self = shift;
    my $args = shift;

    push @{ $args->{used} }, $args->{letter};

    if( scalar @{ $args->{word_root}->{letters} } >= $args->{max_word_length} ) {
        return [ ];
    }

    if( !$self->{prefix}->is_start_of_word( $args->{word_root} ) ) {
        return [ ];
    }

    my @words;
    my $near_letters = $self->find_near_letters({
        used       => $args->{used},
        game       => $args->{game},
        row_number => $args->{letter}{row},
        col_number => $args->{letter}{col},
    });

    for my $near_letter (@{ $near_letters }) {
        my $new_word_root = Game::WordBrain::Word->new({
            letters => [ @{ $args->{word_root}{letters} }, $near_letter ]
        });

        push @words, $new_word_root;

        my $near_letter_used = dclone $args->{used};

        push @words, @{
            $self->_find_near_words({
                word_root => $new_word_root,
                letter    => $near_letter,
                used      => $near_letter_used,
                max_word_length => $args->{max_word_length},
            });
        };
    }

    return \@words;
}

=head1 AUTHORS

Robert Stone, C<< <drzigman AT cpan DOT org > >>

=head1 CONTRIBUTORS

Special thanks to the following individuals who submitted bug reports, performance ideas, and/or pull requests.

=over 4

=item Todd Rinaldo

=item Mohammad S Anwar C< mohammad.anwar@yahoo.com >

=back

=head1 ACKNOWLEDGMENTS

Special thanks to L<BrainStorm Incubator|http://brainstormincubator.com> for funding the development of this module and providing test resources.

Further thanks to L<Houston Perl Mongers|http://houston.pm.org> for providing input and ideas for improvement.

=head1 COPYRIGHT & LICENSE

Copyright 2016 Robert Stone

This program is free software; you can redistribute it and/or modify it under the terms of either: the GNU Lesser General Public License as published by the Free Software Foundation; or any compatible license.

See http://dev.perl.org/licenses/ for more information.

=cut

1;
