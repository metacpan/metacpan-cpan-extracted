use strict;
use warnings;
package Games::Board::Space;
{
  $Games::Board::Space::VERSION = '1.013';
}
# ABSTRACT: a parent class for spaces on game board

use Carp;



sub new {
  my $class = shift;
  my %args  = @_;

  return unless $args{id};
  croak "no board supplied in space creation"
    unless eval { $args{board}->isa('Games::Board') };

  my $space = {
    id    => $args{id},
    board => $args{board},
  };

  $space->{dir} = $args{dir}
    if $args{dir} and (ref $args{dir} eq 'HASH');

  bless $space => $class;
}


sub id {
  my $space = shift;

  return $space->{id};
}


sub board {
  my $space = shift;
  $space->{board};
}


sub dir_id {
  my ($space, $dir) = @_;

  return $space->{dir}{$dir} if (ref $space->{dir} eq 'HASH');
}


sub dir {
  my ($space, $dir) = @_;
  $space->board->space($space->dir_id($dir));
}


sub contains {
  my ($self, $piece) = @_;
  return 1 if grep { $_ eq $piece->id } @{$self->{contents}};
}


sub receive {
  my ($self, $piece) = @_;

  return unless eval { $piece->isa('Games::Board::Piece') };
  return if $self->contains($piece);

  $piece->{current_space} = $self->id;
  push @{$self->{contents}}, $piece->id;
}

1;

__END__

=pod

=head1 NAME

Games::Board::Space - a parent class for spaces on game board

=head1 VERSION

version 1.013

=head1 SYNOPSIS

  use Games::Board;

  my $board = Games::Board->new;

  $board->add_space(Games::Board::Space->new(
    id   => 'go',
    dir  => { next => 'mediterranean', prev => 'boardwalk' },
    cost => undef
  ));

  my $tophat = Games::Board::Piece->new(id => 'tophat')->move(to => 'go');

=head1 DESCRIPTION

This module provides a base class for representing the spaces on a game board.

=head1 METHODS

=head2 new

This method constructs a new space and returns it.

=head2 id

This method returns the id of the space.

=head2 board

This method returns board on which this space sits.

=head2 dir_id

  my $id = $space->dir_id($dir);

This method returns the id of the space found in the given direction from this
space.

=head2 dir

  my $new_space = $space->dir($dir);

This method returns the space found in the given direction from this space.

=head2 contains

  my $bool = $space->contains($piece);

This method returns a true value if the space contains the passed piece.

=head2 receive

  $space->receive($piece);

This method will place the given piece onto this space.

=head1 AUTHOR

Ricardo SIGNES <rjbs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2003 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
