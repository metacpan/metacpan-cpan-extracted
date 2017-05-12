#!/usr/bin/env perl

use strict;
use warnings;

use Getopt::Long;
use File::Basename;

use WordBrain::Letter;
use WordBrain::WordToFind;
use WordBrain::Game;

use List::MoreUtils qw( uniq );

my $help = !@ARGV;
my $playfield;
my @length_of_words_to_find;

my $got_valid_options = GetOptions(
    'help'           => \$help,
    'playfield=s'    => \$playfield,
    'word-to-find=i' => \@length_of_words_to_find,
);

if( !$got_valid_options || $help ) {
    output_usage();
    exit( 1 );
}

my $game = _build_game( );

$game->solve();

_display_game( $game );

my $sorted_solutions = _sort_solutions( $game->{solutions} );

_display_sorted_solutions( $sorted_solutions );

exit;


sub output_usage {
    my $script_name = File::Basename::basename( $0 );
    my $help_message = <<"END_MESSAGE";

USAGE $script_name ( --help ) [ --playfield="a,b,c..." ] [ --word-to-find=i --word-to-find=i ...]

Script for solving WordBrain games.

--help       Display this help message and exit

--playfield="a,b,c..."  The playfield starting in the upper left hand corner and moving from left to right
--word-to-find          Can be repeated multiple times, the length of a word to find

END_MESSAGE

    print STDERR $help_message;

    return;
}

sub _build_game {
    my @words_to_find;
    for my $length ( @length_of_words_to_find ) {
        push @words_to_find, WordBrain::WordToFind->new({ num_letters => $length });
    }

    my @raw_letters = split( ',', $playfield );

    my ( $rows, $cols );
    $rows = $cols = sqrt( scalar @raw_letters );

    my @letters;
    for( my $row = 0; $row < $rows; $row++ ) {
        for( my $col = 0; $col < $cols; $col++ ) {
            push @letters, WordBrain::Letter->new({
                letter => shift @raw_letters,
                row    => $row,
                col    => $col,
            });
        }
    }

    return WordBrain::Game->new({
        letters => \@letters,
        words_to_find => \@words_to_find,
    });
}

sub _display_game {
    my $game_to_display = shift;

    print "======= Game =======\n";
    for my $letter (@{ $game_to_display->{letters} }) {
        if( $letter->{col} == 0 && $letter->{row} != 0 ) {
            print "\n";
        }

        print ' ' . $letter->{letter} . ' ';
    }

    print "\n\n";

    return;
}

sub _sort_solutions {
    my $unsorted_solutions = shift;

    my $sorted_solutions = __sort_solutions(
        $unsorted_solutions,
        0,
    );

    return $sorted_solutions;
}

sub __sort_solutions {
    my $unsorted_solutions = shift;
    my $level              = shift;

    my $sorted_solutions;
    for my $unsorted_solution (@{ $unsorted_solutions }) {
        my $word = $unsorted_solution->{words}->[$level]->word;

        if( exists $unsorted_solution->{words}->[ $level + 1 ] ) {
            my @solutions_with_word = grep { $_->{words}->[ $level ]->word eq $word } @{ $unsorted_solutions };
            $sorted_solutions->{ $word } = __sort_solutions(
                \@solutions_with_word,
                $level + 1,
            );
            $sorted_solutions->{ $word }{ _word } = $solutions_with_word[0]->{words}->[ $level ];
        }
        else {
            if( exists $sorted_solutions->{ $word } ) {
                if( grep {
                        $_->{words}->[ $level ]->word eq $unsorted_solution->{words}->[ $level ]->word
                    } @{ $sorted_solutions->{ $word } } ) {
                    next;
                }

                push @{ $sorted_solutions->{$word} }, $unsorted_solution;
            }
            else {
                $sorted_solutions->{ $word } = [ $unsorted_solution ];
            }
        }
    }

    return $sorted_solutions;
}

sub _display_sorted_solutions {
    my $sorted_solutions = shift;
    my $higher_word_keys = shift;

    $higher_word_keys //= [ ];

    if( ref $sorted_solutions eq 'ARRAY' ) {
        for my $sorted_solution (@{ $sorted_solutions }) {
            print "\t" x ( scalar @{ $higher_word_keys } - 1);
            _display_word( $sorted_solution->{words}->[ scalar @{ $higher_word_keys } - 1 ] );
        }

        return;
    }
    else {
        if( scalar @{ $higher_word_keys } == 0 ) {
            print "===== Possible Solution =====\n";
        }

        if( exists $sorted_solutions->{ '_word' } ) {
            print "\t" x ( scalar @{ $higher_word_keys } - 1);
            _display_word( $sorted_solutions->{ '_word' } );
        }

        for my $word_key (keys %{ $sorted_solutions }) {
            if( $word_key eq '_word' ) {
               next;
            }

            _display_sorted_solutions(
                $sorted_solutions->{ $word_key },
                [ @{ $higher_word_keys }, $word_key ],
            );
        }
    }

    return;
}

sub _display_word {
    my $word_to_display = shift;

    print 'Word: ' . $word_to_display->word . " \t| ";
    for my $letter (@{ $word_to_display->{letters} }) {
        printf "%s - %d x %d | ", $letter->{letter}, $letter->{row}, $letter->{col};
    }
    print "\n";


    return;
}
