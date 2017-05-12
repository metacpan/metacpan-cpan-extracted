package Games::Shogi::Tori;

use strict;
use warnings;
use vars qw(@ISA $VERSION);
use Games::Shogi;

@ISA = qw(Games::Shogi);
$VERSION = '0.01';

sub size() { 7 }
sub promotion_zone() { 2 }
sub allow_drop() { 1 }
sub capture() { ['PH'] }

# {{{ Board static data
my @board = (
  #     7  6  5  4  3  2  1
  [qw( RQ PT CR PH CR PT LQ )],   # a
  [qw( _  _  _  FA _  _  _  )],   # b
  [qw( SW SW SW SW SW SW SW )],   # c
  [qw( _  _  SW _  sw  _ _  )],   # d
  [qw( sw sw sw sw sw sw sw )],   # e
  [qw( _  _  _  fa _  _  _  )],   # f
  [qw( lq pt cr ph cr pt rq )] ); # g
# }}}

# {{{ Pieces
my $pieces = {
  # {{{ Crane
  cr => {
    name => 'Crane',
    romaji => 'tsuru',
    neighborhood => [
      q(     ),
      q( ooo ),
      q(  ^  ),
      q( ooo ),
      q(     ) ] },
  # }}}
  # {{{ Eagle
  eg => {
    name => 'Eagle',
    romaji => 'washi',
    neighborhood => [
      q(     ),
      q( \ / ),
      q( o^o ),
      q( o|o ),
      q(o   o) ] },
  # }}}
  # {{{ Falcon
  fa => {
    name => 'Falcon',
    romaji => 'taka',
    promote => 'eg',
    neighborhood => [
      q(     ),
      q( ooo ),
      q( o^o ),
      q( o o ),
      q(     ) ] },
  # }}}
  # {{{ Goose
  go => {
    name => 'Goose',
    romaji => 'kari',
    neighborhood => [
      q(x   x),
      q(     ),
      q(  ^  ),
      q(     ),
      q(  x  ) ] },
  # }}}
  # {{{ Pheasant
  pt => {
    name => 'Pheasant',
    romaji => 'kiji',
    neighborhood => [
      q(  x  ),
      q(     ),
      q(  ^  ),
      q( o o ),
      q(     ) ] },
  # }}}
  # {{{ Phoenix
  ph => {
    name => 'Phoenix',
    romaji => 'otori',
    neighborhood => [
      q(     ),
      q( ooo ),
      q( o^o ),
      q( ooo ),
      q(     ) ] },
  # }}}
  # {{{ Left Quail
  lq => {
    name => 'Left Quail',
    romaji => 'uzuru',
    neighborhood => [
      q(     ),
      q(  |  ),
      q(  ^  ),
      q( / o ),
      q(     ) ] },
  # }}}
  # {{{ Right Quail
  rq => {
    name => 'Right Quail',
    romaji => 'uzuru',
    neighborhood => [
      q(     ),
      q(  |  ),
      q(  ^  ),
      q( o \ ),
      q(     ) ] },
  # }}}
  # {{{ Swallow
  sw => {
    name => 'Swallow',
    romaji => 'tsubame',
    promote => 'go',
    neighborhood => [
      q(     ),
      q(  o  ),
      q(  ^  ),
      q(     ),
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

Games::Shogi::Tori - Piece descriptions and initial configuration for Tori Shogi

=head1 SYNOPSIS

  use Games::Shogi::Tori;
  $Game = Games::Shogi::Tori->new;
  $piece = $Game->board()->[2][2];
  print @{$Game->neighbor($piece);
  print $Game->english_name('c'); # 'Copper General'

=head1 DESCRIPTION

Tori Shogi is the smallest Shogi variant known to be played in antiquity. Like most of the early variants its pieces are named after birds, with no really exotic pieces among them. The Left and Right Quails are asymmetrical, and a few pieces ave some slightly odd moves (slide forward, move one or two squares backward), but there aren't any real surprises. 

=head1 SEE ALSO

L<perl>

=head1 AUTHOR

Jeffrey Goff, E<lt>jgoff@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2004 by Jeffrey Goff

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
