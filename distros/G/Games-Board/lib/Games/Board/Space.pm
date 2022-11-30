use strict;
use warnings;
package Games::Board::Space 1.014;
# ABSTRACT: a parent class for spaces on game board

use Carp;

#pod =head1 SYNOPSIS
#pod
#pod   use Games::Board;
#pod
#pod   my $board = Games::Board->new;
#pod
#pod   $board->add_space(Games::Board::Space->new(
#pod     id   => 'go',
#pod     dir  => { next => 'mediterranean', prev => 'boardwalk' },
#pod     cost => undef
#pod   ));
#pod
#pod   my $tophat = Games::Board::Piece->new(id => 'tophat')->move(to => 'go');
#pod
#pod =head1 DESCRIPTION
#pod
#pod This module provides a base class for representing the spaces on a game board.
#pod
#pod =cut

#pod =method new
#pod
#pod This method constructs a new space and returns it.
#pod
#pod =cut

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

#pod =method id
#pod
#pod This method returns the id of the space.
#pod
#pod =cut

sub id {
  my $space = shift;

  return $space->{id};
}

#pod =method board
#pod
#pod This method returns board on which this space sits.
#pod
#pod =cut

sub board {
  my $space = shift;
  $space->{board};
}

#pod =method dir_id
#pod
#pod   my $id = $space->dir_id($dir);
#pod
#pod This method returns the id of the space found in the given direction from this
#pod space.
#pod
#pod =cut

sub dir_id {
  my ($space, $dir) = @_;

  return $space->{dir}{$dir} if (ref $space->{dir} eq 'HASH');
}

#pod =method dir
#pod
#pod   my $new_space = $space->dir($dir);
#pod
#pod This method returns the space found in the given direction from this space.
#pod
#pod =cut

sub dir {
  my ($space, $dir) = @_;
  $space->board->space($space->dir_id($dir));
}

#pod =method contains
#pod
#pod   my $bool = $space->contains($piece);
#pod
#pod This method returns a true value if the space contains the passed piece.
#pod
#pod =cut

sub contains {
  my ($self, $piece) = @_;
  return 1 if grep { $_ eq $piece->id } @{$self->{contents}};
}

#pod =method receive
#pod
#pod   $space->receive($piece);
#pod
#pod This method will place the given piece onto this space.
#pod
#pod =cut

sub receive {
  my ($self, $piece) = @_;

  return unless eval { $piece->isa('Games::Board::Piece') };
  return if $self->contains($piece);

  $piece->{current_space} = $self->id;
  push @{$self->{contents}}, $piece->id;
}

#pod =method take
#pod
#pod   $space->take($piece);
#pod
#pod This method removes the piece from this space.
#pod
#pod =cut

sub take {
  my ($self, $piece) = @_;

  return unless eval { $piece->isa('Games::Board::Piece') };
  return unless $self->contains($piece);

  delete $piece->{current_space};
  $self->{contents} = [ grep { $_ ne $piece->id } @{$self->{contents}} ];
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Games::Board::Space - a parent class for spaces on game board

=head1 VERSION

version 1.014

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

=head2 take

  $space->take($piece);

This method removes the piece from this space.

=head1 AUTHOR

Ricardo SIGNES <cpan@semiotic.systems>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2003 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
