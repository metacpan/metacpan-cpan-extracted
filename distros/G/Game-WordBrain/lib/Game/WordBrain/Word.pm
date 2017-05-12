package Game::WordBrain::Word;

use strict;
use warnings;

use overload '""' => \&_operator_stringify;

use Game::WordBrain::Letter;

our $VERSION = '0.2.2'; # VERSION
# ABSTRACT: Representation of a Word for WordBrain

=head1 NAME

Game::WordBrain::Word - Representation of a Word for WordBrain

=head1 SYNOPSIS

    # Create a new word
    my @letters = (
        Game::WordBrain::Letter->new( ... ),
        Game::WordBrain::Letter->new( ... ),
        ...;
    );

    my $word = Game::WordBrain::Word->new( letters => \@letters );

    # Stringify
    print $word;            # Overloaded Stringification
    print $word->word;      # Explict stringification

=head1 DESCRIPTION

A L<Game::WordBrain::Word> is composed of an ArrayRef of L<Game::WordBrain::Letter>s that are used to construct it.

=head1 ATTRIBUTES

=head2 B<letters>

An ArrayRefof L<Game::WordBrain::Letter>s that comprise the word.

=head1 METHODS

=head2 new

    my @letters = (
        Game::WordBrain::Letter->new( ... ),
        Game::WordBrain::Letter->new( ... ),
        ...;
    );

    my $word = Game::WordBrain::Word->new( letters => \@letters );

Given an ArrayRef of L<Game::WordBrain::Letter>s, create a new potential WordBrain word.

=cut

sub new {
    my $class = shift;
    my $args  = shift;

    return bless $args, $class;
}

=head2 word

    my $word = Game::WordBrain::Word->new( ... );

    print $word->word;

Explict stringification of the word.  There is also overloaded " stringification but you are free to use which ever method you are most comfortable with.

=cut

sub word {
    my $self = shift;

    my $word;
    for my $letter (@{ $self->{letters} }) {
        $word .= $letter->{letter};
    }

    return $word;
}

sub _operator_stringify {
    my $word = shift;

    return $word->word;
}

1;
