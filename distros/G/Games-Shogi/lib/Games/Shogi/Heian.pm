package Games::Shogi::Heian;

use strict;
use warnings;
use vars qw(@ISA $VERSION);
use Games::Shogi;

@ISA = qw(Games::Shogi);
$VERSION = '0.01';

sub size() { 9 }
sub promotion_zone() { 3 }
sub allow_drop() { undef }
sub capture() { [ 'K' ] }

# {{{ Board static data
my @board = (
  #    9 8 7 6 5 4 3 2 1
  [qw( L N S G K G S N L )],   # a
  [qw( _ _ _ _ _ _ _ _ _ )],   # b
  [qw( P P P P P P P P P )],   # c
  [qw( _ _ _ _ _ _ _ _ _ )],   # d
  [qw( _ _ _ _ _ _ _ _ _ )],   # e
  [qw( _ _ _ _ _ _ _ _ _ )],   # f
  [qw( p p p p p p p p p )],   # g
  [qw( _ _ _ _ _ _ _ _ _ )],   # h
  [qw( l n s g k g s n l )] ); # i
# }}}

# {{{ Pieces
my $pieces = {
  # {{{ Gold General
  g => {
    name => 'Gold General',
    romaji => 'kinsho',
    neighborhood => [
      q(     ),
      q( ooo ),
      q( o^o ),
      q(  o  ),
      q(     ) ] },
  # }}}
  # {{{ King
  k => {
    name => 'King',
    romaji => 'osho',
    neighborhood => [
      [qw(     )],
      [qw( ooo )],
      [qw( o^o )],
      [qw( ooo )],
      [qw(     )] ] },
  # }}}
  # {{{ Knight
  n => {
    name => 'Knight',
    promote => 'g',
    neighborhood => [
      q( x x ),
      q(     ),
      q(  ^  ),
      q(     ),
      q(     ) ] },
  # }}}
  # {{{ Lance
  l => {
    name => 'Lance',
    romaji => 'kyosha',
    promote => 'g',
    neighborhood => [
      q(     ),
      q(  |  ),
      q(  ^  ),
      q(     ),
      q(     ) ] },
  # }}}
  # {{{ Pawn
  p => {
    name => 'Pawn',
    romaji => 'fuhyo',
    promote => '+p',
    neighborhood => [
      q(     ),
      q(  o  ),
      q(  ^  ),
      q(     ),
      q(     ) ] },
  # }}}
  # {{{ Silver General
  s => {
    name => 'Silver General',
    romaji => 'ginsho',
    promote => 'g',
    neighborhood => [
      q(     ),
      q( ooo ),
      q(  ^  ),
      q( o o ),
      q(     ) ] },
    # }}}

  # {{{ Promoted Pawn
  '+p' => {
    name => 'Promoted Pawn',
    romaji => 'tokin',
    neighborhood => [
      q(     ),
      q( ooo ),
      q( o^o ),
      q(  o  ),
      q(     ) ] },
  # }}}
};
# }}}

# {{{ new
sub new {
  my $proto = shift;
  my $self = { pieces => $pieces };
  bless $self, ref($proto) || $proto;
  $self->{board} = $self->initial_board(\@board);
  return $self }
# }}}

1;
__END__

=head1 NAME

Games::Shogi::Heian - Piece descriptions and initial configuration for Heian era Shogi

=head1 SYNOPSIS

  use Games::Shogi::Heian;
  $Game = Games::Shogi::Heian->new;
  $piece = $Game->board()->[2][2];
  print @{$Game->neighbor($piece);
  print $Game->english_name('c'); # 'Copper General'

=head1 DESCRIPTION

Heian Shogi is a slightly older form of Shogi, with the major differences being the lack of the Bishop and Rook, and apparently not allowing drops. Other than that it's largely the same as regular Shogi.

=head1 SEE ALSO

L<perl>

=head1 AUTHOR

Jeffrey Goff, E<lt>jgoff@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2004 by Jeffrey Goff

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
