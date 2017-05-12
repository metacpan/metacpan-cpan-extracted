package Games::Shogi::Dai;

use strict;
use warnings;
use vars qw(@ISA $VERSION);
use Games::Shogi;

@ISA = qw(Games::Shogi);
$VERSION = '0.01';

sub size() { 15 }
sub promotion_zone() { 5 }
sub allow_drop() { undef }
sub capture() { [ 'K', 'CP' ] }

# {{{ Board static data
my @board = (
  #    15  14  13  12  11  10   9   8   7   6   5   4   3   2   1
  [qw(  L   N  ST   I   _   S   G   K   G   S   _   I  ST   N   L )],  # a
  [qw( RC  VO  CS   _  FL   _  BT  DE  BT   _  FL   _  CS  VO  RC )],  # b
  [qw(  _   _   _  AB   _  EW  PH  LN  KI  EW   _  AB   _   _   _ )],  # c
  [qw(  R  FD  SM  VM   B  DH  DK  FK  DK  DH   B  VM  SM  FD   R )],  # d
  [qw(  P   P   P   P   P   P   P   P   P   P   P   P   P   P   P )],  # e
  [qw(  _   _   _   _  GB   _   _   _   _   _  GB   _   _   _   _ )],  # f
  [qw(  _   _   _   _   _   _   _   _   _   _   _   _   _   _   _ )],  # g
  [qw(  _   _   _   _   _   _   _   _   _   _   _   _   _   _   _ )],  # h
  [qw(  _   _   _   _   _   _   _   _   _   _   _   _   _   _   _ )],  # i
  [qw(  _   _   _   _  gb   _   _   _   _   _  gb   _   _   _   _ )],  # j
  [qw(  p   p   p   p   p   p   p   p   p   p   p   p   p   p   p )],  # k
  [qw(  r  fd  sm  vm   b  dh  dk  fk  dk  dh   b  vm  sm  fd   r )],  # l
  [qw(  _   _   _  ab   _  ew  ki  ln  ph  ew   _  ab   _   _   _ )],  # m
  [qw( rc  vo  cs   _  fl   _  bt  de  bt   _  fl   _  cs  vo  rc )],  # n
  [qw(  l   n  st   i   _   s   g   k   g   s   _   i  st   n   l )] ),# o
# }}}

# {{{ Pieces
my $pieces = {
  # {{{ Angry Bear
  ab => {
    name => 'Angry Bear',
    romaji => 'shincho',
    promote => 'g',
    neighborhood => [
      q(     ),
      q(  o  ),
      q( o^o ),
      q(  o  ),
      q(     ) ] },
  # }}}
  # {{{ Bishop
  b => {
    name => 'Bishop',
    romaji => 'kakugyo',
    promote => 'dh',
    neighborhood => [
      q(     ),
      q( \ / ),
      q(  ^  ),
      q( / \ ),
      q(     ) ] },
  # }}}
  # {{{ Blind Tiger
  bt => {
    name => 'Blind Tiger',
    romaji => 'moko',
    promote => 'fs',
    neighborhood => [
      q(     ),
      q( o o ),
      q( o^o ),
      q( ooo ),
      q(     ) ] },
  # }}}
  # {{{ Cat Sword
  cs => {
    name => 'Cat Sword',
    romaji => 'myojin',
    promote => 'g',
    neighborhood => [
      q(     ),
      q( o o ),
      q(  ^  ),
      q( o o ),
      q(     ) ] },
  # }}}
  # {{{ Copper General
  c => {
    name => 'Copper General',
    romaji => 'dosho',
    promote => 'sm',
    neighborhood => [
      q(     ),
      q( ooo ),
      q(  ^  ),
      q(  o  ),
      q(     ) ] },
  # }}}
  # {{{ Dragon Horse
  dh => {
    name => 'Dragon Horse',
    romaji => 'ryume',
    promote => 'hf',
    neighborhood => [
      q(     ),
      q( \o/ ),
      q( o^o ),
      q( /o\ ),
      q(     ) ] },
  # }}}
  # {{{ Dragon King
  dk => {
    name => 'Dragon King',
    romaji => 'ryuo',
    promote => 'se',
    neighborhood => [
      q(     ),
      q( o|o ),
      q( -^- ),
      q( o|o ),
      q(     ) ] },
  # }}}
  # {{{ Drunk Elephant
  de => {
    name => 'Drunk Elephant',
    romaji => 'suizo',
    promote => 'cp',
    neighborhood => [
      q(     ),
      q( ooo ),
      q( o^o ),
      q( o o ),
      q(     ) ] },
  # }}}
  # {{{ Evil Wolf
  ew => {
    name => 'Evil Wolf',
    romaji => 'akuro',
    promote => 'g',
    neighborhood => [
      q(     ),
      q( ooo ),
      q( o^o ),
      q(     ),
      q(     ) ] },
  # }}}
  # {{{ Ferocious Leopard
  fl => {
    name => 'Ferocious Leopard',
    romaji => 'mohyo',
    promote => 'b',
    neighborhood => [
      q(     ),
      q( ooo ),
      q(  ^  ),
      q( ooo ),
      q(     ) ] },
  # }}}
  # {{{ Flying Dragon
  fd => {
    name => 'Flying Dragon',
    romaji => 'hiryu',
    promote => 'g',
    neighborhood => [
      q(o   o),
      q( o o ),
      q(  ^  ),
      q( o o ),
      q(o   o) ] },
  # }}}
  # {{{ Free King
  fk => {
    name => 'Free King',
    romaji => "hon'o",
    neighborhood => [
      q(     ),
      q( \|/ ),
      q( -^- ),
      q( /|\ ),
      q(     ) ] },
  # }}}
  # {{{ Go-Between
  gb => {
    name => 'Go-Between',
    romaji => 'chunin',
    promote => 'de',
    neighborhood => [
      q(     ),
      q(  o  ),
      q(  ^  ),
      q(  o  ),
      q(     ) ] },
  # }}}
  # {{{ Gold General
  g => {
    name => 'Gold General',
    romaji => 'kinsho',
    promote => 'r',
    neighborhood => [
      q(     ),
      q( ooo ),
      q( o^o ),
      q(  o  ),
      q(     ) ] },
  # }}}
  # {{{ Iron General
  i => {
    name => 'Iron General',
    romaji => 'tessho',
    promote => 'g',
    neighborhood => [
      q(     ),
      q( ooo ),
      q(  ^  ),
      q(     ),
      q(     ) ] },
  # }}}
  # {{{ King
  k => {
    name => 'King',
    romaji => 'osho',
    neighborhood => [
      q(     ),
      q( ooo ),
      q( o^o ),
      q( ooo ),
      q(     ) ] },
  # }}}
  # {{{ Knight
  n => {
    name => 'Knight',
    romaji => 'keima',
    promote => 'g',
    neighborhood => [
      q( x x ),
      q(     ),
      q(  ^  ),
      q(     ),
      q(     ) ] },
  # }}}
  # {{{ Kirin
  ki => {
    name => 'Kirin',
    romaji => 'kylin',
    promote => 'ln',
    neighborhood => [
      q(  x  ),
      q( o o ),
      q(x ^ x),
      q( o o ),
      q(  x  ) ] },
  # }}}
  # {{{ Lance
  l => {
    name => 'Lance',
    romaji => 'kyosha',
    promote => 'wh',
    neighborhood => [
      q(     ),
      q(  |  ),
      q(  ^  ),
      q(     ),
      q(     ) ] },
  # }}}
  # {{{ Lion
  ln => {
    name => 'Lion',
    romaji => 'shishi',
    igui => 1,
    neighborhood2 => [
      q(xxxxx), # The 'x' is a jump area, not the inside
      q(xooox),
      q(xo^ox),
      q(xooox),
      q(xxxxx) ],
    neighborhood => { area => 2 }, # Really an area of 1 and a spare move...
    jump => { area => 2 } }, # Not quite correct, more of area 2 radius 1...
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
  # {{{ Phoenix
  ph => {
    name => 'Phoenix',
    romaji => 'hoo',
    promote => 'fk',
    neighborhood => [
      q(x   x),
      q(  o  ),
      q( o^o ),
      q(  o  ),
      q(x   x) ] },
  # }}}
  # {{{ Reverse Chariot
  rc => {
    name => 'Reverse Chariot',
    romaji => 'hansha',
    promote => 'w',
    neighborhood => [
      q(     ),
      q(  |  ),
      q(  ^  ),
      q(  |  ),
      q(     ) ] },
  # }}}
  # {{{ Rook
  r => {
    name => 'Rook',
    romaji => 'hisha',
    promote => 'dk',
    neighborhood => [
      q(     ),
      q(  |  ),
      q( -^- ),
      q(  |  ),
      q(     ) ] },
  # }}}
  # {{{ Side Mover
  sm => {
    name => 'Side Mover',
    romaji => 'ogyo',
    promote => 'fb',
    neighborhood => [
      q(     ),
      q(  o  ),
      q( -^- ),
      q(  o  ),
      q(     ) ] },
  # }}}
  # {{{ Stone General
  st => {
    name => 'Stone General',
    romaji => 'sekisho',
    promote => 'g',
    neighborhood => [
      q(     ),
      q( o o ),
      q(  ^  ),
      q(     ),
      q(     ) ] },
  # }}}
  # {{{ Silver General
  s => {
    name => 'Silver General',
    romaji => 'ginsho',
    promote => 'vm',
    neighborhood => [
      q(     ),
      q( ooo ),
      q(  ^  ),
      q( o o ),
      q(     ) ] },
  # }}}
  # {{{ Violent Ox
  vo => {
    name => 'Violent Ox',
    romaji => 'mogyu',
    promote => 'g',
    neighborhood => [
      q(  o  ),
      q(  o  ),
      q(oo^oo),
      q(  o  ),
      q(  o  ) ] },
  # }}}
  # {{{ Vertical Mover
  vm => {
    name => 'Vertical Mover',
    romaji => 'kengyo',
    promote => 'fo',
    neighborhood => [
      q(     ),
      q(  |  ),
      q( o^o ),
      q(  |  ),
      q(     ) ] },
  # }}}

  # {{{ Crown Prince
  cp => {
    name => 'Crown Prince',
    romaji => 'taishi',
    neighborhood => [
      q(     ),
      q( ooo ),
      q( o^o ),
      q( ooo ),
      q(     ) ] },
  # }}}
  # {{{ Flying Ox
  fo => {
    name => 'Flying Ox',
    romaji => 'higyu',
    neighborhood => [
      q(     ),
      q( \|/ ),
      q(  ^  ),
      q( /|\ ),
      q(     ) ] },
  # }}}
  # {{{ Flying Stag
  fs => {
    name => 'Flying Stag',
    romaji => 'hiroku',
    neighborhood => [
      q(     ),
      q( o|o ),
      q( o^o ),
      q( o|o ),
      q(     ) ] },
  # }}}
  # {{{ Free Boar
  fb => {
    name => 'Free Boar',
    romaji => 'honcho',
    neighborhood => [
      q(     ),
      q( \ / ),
      q( -^- ),
      q( / \ ),
      q(     ) ] },
  # }}}
  # {{{ Horned Falcon
  hf => {
    name => 'Horned Falcon',
    romaji => 'kakuo',
    neighborhood2 => [
      q(\ 2 /),
      q( \1/ ),
      q( -^- ),
      q( /|\ ),
      q(     ) ],
    neighborhood => {
      diagonal => 'range',
      horizontal => 'range',
      n => 1,
      s => 'range' },
    jump => { n => 2 } },
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
  # {{{ Soaring Eagle
  se => {
    name => 'Soaring Eagle',
    romaji => 'hiju',
    neighborhood => [
      q(2   2),
      q( 1|1 ),
      q( -^- ),
      q( /|\ ),
      q(     ) ] },
  # }}}
  # {{{ Whale
  wh => {
    name => 'Whale',
    romaji => 'keigei',
    neighborhood => [
      q(     ),
      q(  |  ),
      q(  ^  ),
      q( /|\ ),
      q(     ) ] },
  # }}}
  # {{{ White Horse
  who => {
    name => 'White Horse',
    romaji => 'hakku',
    neighborhood => [
      q(     ),
      q( \|/ ),
      q(  ^  ),
      q(  |  ),
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

Games::Shogi::Dai - Piece descriptions and initial configuration for Dai Shogi

=head1 SYNOPSIS

  use Games::Shogi::Dai;
  $Game = Games::Shogi::Dai->new;
  $piece = $Game->board()->[2][2];
  print @{$Game->neighbor($piece);
  print $Game->english_name('c'); # 'Copper General'

=head1 DESCRIPTION

Dai Shogi is a larger variant, on a 15 x 15 board. The Lion and Horned Falcon are probably the two most exotic pieces, everything else is relatively mundane.

=head1 SEE ALSO

L<perl>

=head1 AUTHOR

Jeffrey Goff, E<lt>jgoff@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2004 by Jeffrey Goff

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
cut
