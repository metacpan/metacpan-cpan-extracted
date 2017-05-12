package Game::WordBrain::Speller;

use strict;
use warnings;

use Game::WordBrain::WordList;

our $VERSION = '0.2.2'; # VERSION
# ABSTRACT: Checks Spelling of Words

=head1 NAME

Game::WordBrain::Speller - Spell Checks Words

=head1 SYNOPSIS

    # Create new Spell Checker
    my $speller = Game::WordBrain::Speller->new({
        word_list => '/path/to/wordlist',   # Optional
    });

    # Test if a word is valid
    my $word = 'nerds';
    if( $speller->is_valid_word( $word ) ) {
        print "Looks like a valid word";
    }
    else {
        print "Nope, not a real word";
    }

=head1 DESCRIPTION

Originally L<Game::WordBrain> made use of L<Text::Aspell> as a speller.  The problem was that L<Text:Aspell> provided much more functionalty (and many more dependencies) then what L<Game::WordBrain> really needed.  Hence, Game::WordBrain::Speller was born.

This module loads a wordlist into memory and exposes a method to spellcheck words.

=head1 ATTRIBUTES

=head2 word_list

Path to a new line delimited word list.  If not provided, the wordlist provided with this distrubtion will be used.

=head1 METHODS

=head2 new

    my $speller = Game::WordBrain::Speller->new({
        word_list => '/path/to/wordlist',  # Optional
    });

If the word_list is not specified the bundled wordlist will be used.

Returns an instance of L<Game::WordBrain::Speller>.

=cut

sub new {
    my $class = shift;
    my $args = shift;

    if( !exists $args->{word_list} ) {
        $args->{word_list} = 'Game::WordBrain::WordList';
    }

    $args->{_words_cache} = _load_words( $args );

    return bless $args, $class;
}

sub _load_words {
    my $args = shift;

    my $words_cache = { };

    if( $args->{word_list} eq 'Game::WordBrain::WordList' ) {
        my $data_start = tell Game::WordBrain::WordList::DATA;

        while( my $word = <Game::WordBrain::WordList::DATA> ) {
            chomp $word;
            $words_cache->{ $word } = 1;
        }

        seek Game::WordBrain::WordList::DATA, $data_start, 0;
    }
    else {
        open( my $words_fh, "<", $args->{word_list} ) or die "Unable to open words file";

        while( my $word = <$words_fh> ) {
            chomp $word;
            $words_cache->{ $word } = 1;
        }

        close $words_fh;
    }

    return $words_cache;
}

=head2 is_valid_word

    my $speller = Game::WordBrain::Speller->...;

    if( $speller->is_valid_word( 'nerds' ) ) {
        print 'This is a real word';
    }
    else {
        print 'Nope, not really a word.';
    }

Spell checks a word.  Returns a truthy value if the provided word is valid, falsey if it does not.

=cut

sub is_valid_word {
    my $self = shift;
    my $word = shift;

    return exists $self->{_words_cache}{$word};
}

1;
