package Game::WordBrain::Letter;

use strict;
use warnings;

use overload '==' => \&_operator_equality,
             '""' => \&_operator_stringify;

our $VERSION = '0.2.2'; # VERSION
# ABSTRACT: Representation of a Letter in a WordBrain Game

=head1 NAME

Game::WordBrain::Letter - Representation of a Letter in a WordBrain Game

=head1 SYNOPSIS

    # Create a new Game::WordBrain::Letter
    my $letter = Game::WordBrain::Letter->new({
        letter => 'a',
        row    => 1,
        col    => 3,
    });

    # Stringification is overloaded
    print $letter;  # prints 'a'

    # Equality is overloaded
    if( $letter == $letter ) {
        print "Same letter!';
    }

=head1 DESCRIPTION

Represents a Letter in a WordBrain Game.

=head1 ATTRIBUTES

=head2 B<letter>

A single character string that contains the actual letter represented [a-z].

=head2 B<row>

The row in a WordBrain game where this letter appears.

=head2 B<col>

The col in a WordBrain game where this letter appears.

=head1 METHODS

=head2 new

    my $letter = Game::WordBrain::Letter->new({
        letter => 'a',
        row    => 1,
        col    => 3,
    });

Given a letter, a row, and a col, returns an instance of a Game::WordBrain::Letter.

=cut

sub new {
    my $class = shift;
    my $args  = shift;

    return bless $args, $class;
}

sub _operator_equality {
    my ( $a, $b ) = @_;

    if(    $a->{letter} eq $b->{letter}
        && $a->{row}    == $b->{row}
        && $a->{col}    == $b->{col} ) {

        return 1;
    }

    return 0;
}

sub _operator_stringify {
    my $self = shift;

    return $self->{letter};
}

1;
