package Game::WordBrain::Solution;

use strict;
use warnings;

use Game::WordBrain::Word;

our $VERSION = '0.2.2'; # VERSION
# ABSTRACT: Representation of Potential WordBrain Solution

=head1 NAME

Game::WordBrain::Solution - Representation of Potential WordBrain Solution

=head1 SYNOPSIS

    my @words = (
        Game::WordBrain::Word->new( ... ),
        Game::WordBrain::Word->new( ... ),
        ...
    );

    my $solution = Game::WordBrain::Solution->new({
        words => \@words,
    });

=head1 DESCRIPTION

For any L<Game::WordBrain> there are multiple possible solutions.  A solution is defined as an ordered collection of words ( ArrayRef of L<Game::WordBrain::Word> ).

B<NOTE> Each of these solutions is just a potential solution and may not be *THE* solution that WordBrain is looking for.  The only way to know for sure is to try the solution.

=head1 ATTRIBUTES

=head2 B<words>

ArrayRef of L<Game::WordBrain::Word>s

=head1 METHODS

=head2 new

    my @words = (
        Game::WordBrain::Word->new( ... ),
        Game::WordBrain::Word->new( ... ),
        ...
    );

    my $solution = Game::WordBrain::Solution->new({
        words => \@words,
    });

Given an ArrayRef of L<Game::WordBrain::Word>s, returns a Game::WordBrain::Solution.

=cut

sub new {
    my $class = shift;
    my $args  = shift;

    return bless $args, $class;
}

1;
