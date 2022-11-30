use strict;
use warnings;
package Games::Board::Piece 1.014;
# ABSTRACT: a parent class for board game pieces

use Carp;

#pod =head1 SYNOPSIS
#pod
#pod   use Games::Board;
#pod
#pod   my $board = Games::Board->new;
#pod
#pod   $board->add_space(
#pod     id   => 'go',
#pod     dir  => { next => 'mediterranean', prev => 'boardwalk' },
#pod     cost => undef
#pod   );
#pod
#pod   my $tophat = Games::Board::Piece->new(id => 'tophat')->move(to => 'go');
#pod
#pod =head1 DESCRIPTION
#pod
#pod This module provides a base class for representing the pieces in a board game.  
#pod
#pod =cut

#pod =method new
#pod
#pod This method constructs a new game piece and returns it.
#pod
#pod =cut

sub new {
  my ($class, %args) = @_;

  return unless $args{id};
  return unless eval { $args{board}->isa('Games::Board') };

  my $piece = { %args };

  bless $piece => $class;
}

#pod =method id
#pod
#pod This returns the piece's id.
#pod
#pod =cut

sub id {
  my $self = shift;
  $self->{id};
}

#pod =method board
#pod
#pod This returns the board object to which the piece is related.
#pod
#pod =cut

sub board {
  my $self = shift;
  $self->{board};
}

#pod =method current_space_id
#pod
#pod This returns the id of the space on which the piece currently rests, if any.
#pod It it's not on any space, it returns undef.
#pod
#pod =cut

sub current_space_id {
  my $piece = shift;
  $piece->{current_space};
}

#pod =method current_space
#pod
#pod This returns the Space on which the piece currently rests, if any.  It it's not
#pod on any space, it returns undef.
#pod
#pod =cut

sub current_space {
  my $piece = shift;
  return unless $piece->{current_space};
  $piece->board->space($piece->{current_space});
}

#pod =method move
#pod
#pod   $piece->move(dir => 'up')
#pod
#pod   $piece->move(to  => $space)
#pod
#pod This method moves the piece to a new space on the board.  If the method call is
#pod in the first form, the piece is moved to the space in the given direction from
#pod the piece's current space.  If the method call is in the second form, and
#pod C<$space> is a Games::Board::Space object, the piece is moved to that space.
#pod
#pod =cut

sub move {
  my $piece = shift;
  my ($how, $which) = @_;
  my $new_space;
  my $old_space = $piece->current_space;

  if ($how eq 'dir') {
    return unless $old_space;
    return unless $new_space = $old_space->dir($which);
  } elsif ($how eq 'to') {
    return unless eval { $which->isa('Games::Board::Space') };
    $new_space = $which;
  } else {
    return;
  }

  return unless !$old_space || $old_space->take($piece);
  $new_space->receive($piece);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Games::Board::Piece - a parent class for board game pieces

=head1 VERSION

version 1.014

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

=head1 PERL VERSION

This module should work on any version of perl still receiving updates from
the Perl 5 Porters.  This means it should work on any version of perl released
in the last two to three years.  (That is, if the most recently released
version is v5.40, then this module should work on both v5.40 and v5.38.)

Although it may work on older versions of perl, no guarantee is made that the
minimum required version will not be increased.  The version may be increased
for any reason, and there is no promise that patches will be accepted to lower
the minimum required perl.

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

Ricardo SIGNES <cpan@semiotic.systems>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2003 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
