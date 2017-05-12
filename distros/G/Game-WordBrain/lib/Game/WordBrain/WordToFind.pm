package Game::WordBrain::WordToFind;

use strict;
use warnings;

our $VERSION = '0.2.2'; # VERSION
# ABSTRACT: Representation of a WordBrain Word To Find

=head1 NAME

Game::WordBrain::WordToFind - Representation of a WordBrain Word To Find

=head1 SYNOPSIS

    my $word_to_find = Game::WordBrain::WordToFind->new({
        num_letters => 5
    });


=head1 DESCRIPTION

In WordBrain, all we are given is the length ( and number of ) unknown words.  L<Game::WordBrain::WordToFind> represents a single unknown word, containing only it's length.

=head1 ATTRIBUTES

=head2 B<num_letters>

The length of the word to find.

=head1 METHODS

=head2 new

    my $word_to_find = Game::WordBrain::WordToFind->new({
        num_letters => 5
    });

Given the length of the unknown L<Game::WordBrain::Word>, returns an instance of L<Game::WordBrain::WordToFind>.

=cut

sub new {
    my $class = shift;
    my $args  = shift;

    return bless $args, $class;
}

1;
