use strict;
use warnings;
package Games::Board::Piece;
{
  $Games::Board::Piece::VERSION = '1.013';
}
# ABSTRACT: a parent class for board game pieces

use Carp;



sub new {
  my ($class, %args) = @_;

  return unless $args{id};
  return unless eval { $args{board}->isa('Games::Board') };

  my $piece = { %args };

  bless $piece => $class;
}


sub id {
  my $self = shift;
  $self->{id};
}


sub board {
  my $self = shift;
  $self->{board};
}


sub current_space_id {
  my $piece = shift;
  $piece->{current_space};
}


sub current_space {
  my $piece = shift;
  return unless $piece->{current_space};
  $piece->board->space($piece->{current_space});
}


sub move {
  my $piece = shift;
  my ($how, $which) = @_;
  my $space;

  if ($how eq 'dir') {
    return unless $piece->current_space;
    return unless $space = $piece->current_space->dir($which);
  } elsif ($how eq 'to') {
    return unless eval { $which->isa('Games::Board::Space') };
    $space = $which;
  } else {
    return;
  }

  $space->receive($piece);
}

1;

__END__

=pod

=head1 NAME

Games::Board::Piece - a parent class for board game pieces

=head1 VERSION

version 1.013

=head1 SYNOPSIS

  use Games::Board;

  my $board = Games::Board->new;

  $board->add_space(
    id   => 'go',
    dir  => { next => 'mediterranean', prev => 'boardwalk' },
    cost => undef
  );

  my $tophat = Games::Board::Piece->new(id => 'tophat')->move(to => 'go');

=head1 DESCRIPTION

This module provides a base class for representing the pieces in a board game.  

=head1 METHODS

=head2 new

This method constructs a new game piece and returns it.

=head2 id

This returns the piece's id.

=head2 board

This returns the board object to which the piece is related.

=head2 current_space_id

This returns the id of the space on which the piece currently rests, if any.
It it's not on any space, it returns undef.

=head2 current_space

This returns the Space on which the piece currently rests, if any.  It it's not
on any space, it returns undef.

=head2 move

  $piece->move(dir => 'up')

  $piece->move(to  => $space)

This method moves the piece to a new space on the board.  If the method call is
in the first form, the piece is moved to the space in the given direction from
the piece's current space.  If the method call is in the second form, and
C<$space> is a Games::Board::Space object, the piece is moved to that space.

=head1 AUTHOR

Ricardo SIGNES <rjbs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2003 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
