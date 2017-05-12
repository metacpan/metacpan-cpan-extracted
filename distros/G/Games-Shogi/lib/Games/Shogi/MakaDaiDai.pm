package Games::Shogi::MakaDaiDai;

use strict;
use warnings;
use vars qw(@ISA $VERSION);
use Games::Shogi;

@ISA = qw(Games::Shogi);
$VERSION = '0.01';

sub size() { 19 }
sub promotion_zone() { 6 }
sub allow_drop() { undef }
sub capture() { [ 'K', 'CP', 'EM' ] }

# {{{ Board static data
my @board = (
  #   19  18  17  16  15  14  13  12  11  10   9   8   7   6   5   4   3   2   1
  [qw( L   E  ST   T   I   C   S   G DSP   K  DV   G   S   C   I   T  ST   E   L  )],  # a
  [qw(RC   _  CS   _  OM   _ RDR  FL  BT  DE  BT  FL CSE   _  CC   _  CS   _  RC  )],  # b
  [qw( _  OR   _  AB   _  BB   _  EW  PH  LN  KI  EW   _  BB   _  AB   _  OR   _  )],  # c
  [qw(DO   _   N   _  VO   _  FD  SD GGD  LD  WR BDE  FD   _  VO   _   N   _  DO  )],  # d
  [qw( R RCH  SM  SF  VM   B  DH  DK  HM  FK  CA  DK  DH   B  VM  SF  SM LCH   R  )],  # e
  [qw( P   P   P   P   P   P   P   P   P   P   P   P   P   P   P   P   P   P   P  )],  # f
  [qw( _   _   _   _   _  GB   _   _   _   _   _   _   _  GB   _   _   _   _   _  )],  # g
  [qw( _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _  )],  # h
  [qw( _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _  )],  # i
  [qw( _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _  )],  # j
  [qw( _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _  )],  # k
  [qw( _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _  )],  # l
  [qw( _   _   _   _   _  gb   _   _   _   _   _   _   _  gb   _   _   _   _   _  )],  # m
  [qw( p   p   p   p   p   p   p   p   p   p   p   p   p   p   p   p   p   p   p  )],  # n
  [qw( r lch  sm  sf  ve   b  dh  dk  ca  fk  hm  dk  dh   b  vm  sf  sm rch   r  )],  # o
  [qw(do   _   n   _  vo   _  fd bde  wk  ld ggd  sd  fd   _  vo   _   n   _  do  )],  # p
  [qw( _  or   _  ab   _  bb   _  ew  ki  ln  ph  ew   _  bb   _  ab   _  or   _  )],  # q
  [qw(rc   _  cs   _  cc   _ cse  fl  bt  de  bt  fl rdr   _  om   _  cs   _  rc  )],  # r
  [qw( l   e  st   t   i   c   s   g  dv   k dsp   g   s   c   i   t  st   e   l  )] ),# s
# }}}

# {{{ Pieces
my $pieces = {
  # {{{ Angry Boar
  ab => {
    name => 'Angry Boar',
    promote => 'fb',
    neighborhood => [
      q(     ),
      q(  o  ),
      q( o^o ),
      q(  o  ),
      q(     ) ] },
  # }}}
  # {{{ Bat
  ba => { 
    name => 'Bat',
    neighborhood => [
      q(     ),
      q(  |  ),
      q(  ^  ),
      q( / \ ),
      q(     ) ] },
  # }}}
  # {{{ Bishop
  b => { 
    name => 'Bishop',
    romaji => 'kakugyo',
    promote => 'g',
    neighborhood => [
      q(     ),
      q( \ / ),
      q(  ^  ),
      q( / \ ),
      q(     ) ] },
  # }}}
  # {{{ Blind Bear
  bb => {
    name => 'Blind Bear',
    promote => 'fbe',
    neighborhood => [
      q(     ),
      q( o o ),
      q(  ^  ),
      q( o|o ),
      q(     ) ] },
  # }}}
  # {{{ Blind Tiger
  bt => {
    name => 'Blind Tiger',
    promote => 'ftg',
    neighborhood => [
      q(     ),
      q( o o ),
      q( o^o ),
      q( ooo ),
      q(     ) ] },
  # }}}
  # {{{ Buddhist Devil
  bde => {
    name => 'Buddhist Devil',
    promote => 'g',
    neighborhood => [
      q(o   o),
      q( 3 3 ),
      q( o^o ),
      q(  o  ),
      q(  o  ) ] },
  # }}}
  # {{{ Buddhist Spirit
  bsp => {
    name => 'Buddhist Spirit',
    neighborhood => [
      q(\\  |  /),
      q( L L L ),
      q(  333  ),
      q(-L3^3L-),
      q(  333  ),
      q( L L L ),
      q(/  |  \\) ] },
  # }}}
  # {{{ Capricorn
  ca => {
    name => 'Capricorn',
    promote => 'g',
    neighborhood => [
      q(X   X),
      q( \ / ),
      q(  ^  ),
      q( / \ ),
      q(X   X) ] },
  # }}}
  # {{{ Cat Sword
  cs => {
    name => 'Cat Sword',
    romaji => 'myojin',
    promote => 'fca',
    neighborhood => [
      q(     ),
      q( o o ),
      q(  ^  ),
      q( o o ),
      q(     ) ] },
  # }}}
  # {{{ Chinese Cock
  cc => {
    name => 'Chinese Cock',
    promote => 'ws',
    neighborhood => [
      q(     ),
      q( o o ),
      q( o^o ),
      q(  o  ),
      q(     ) ] },
  # }}}
  # {{{ Coiled Serpent
  cse => {
    name => 'Coiled Serpent',
    promote => 'fse',
    neighborhood => [
      q(     ),
      q(  o  ),
      q(  ^  ),
      q( ooo ),
      q(     ) ] },
  # }}}
  # {{{ Copper General
  c => {
    name => 'Copper General',
    romaji => 'dosho',
    promote => 'fc',
    neighborhood => [
      q(     ),
      q( ooo ),
      q(  ^  ),
      q(  o  ),
      q(     ) ] },
  # }}}
  # {{{ Dark Spirit
  dsp => {
    name => 'Dark Spirit',
    promote => 'bsp',
    neighborhood => [
      q(     ),
      q( o o ),
      q(  ^o ),
      q( o   ),
      q(     ) ] },
  # }}}
  # {{{ Deva
  dv => {
    name => 'Deva',
    promote => 'tk',
    neighborhood => [
      q(     ),
      q( o o ),
      q( o^  ),
      q(   o ),
      q(     ) ] },
  # }}}
  # {{{ Donkey
  do => {
    name => 'Donkey',
    promote => 'g',
    neighborhood => [
      q(  x  ),
      q(     ),
      q( o^o ),
      q(     ),
      q(  x  ) ] },
  # }}}
  # {{{ Dragon Horse
  dh => {
    name => 'Dragon Horse',
    romaji => 'ryume',
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
    neighborhood => [
      q(     ),
      q( ooo ),
      q( o^o ),
      q( o o ),
      q(     ) ] },
  # }}}
  # {{{ Earth General
  e => {
    name => 'Earth General',
    promote => 'fe',
    neighborhood => [
      q(     ),
      q(  o  ),
      q(  ^  ),
      q(  o  ),
      q(     ) ] },
  # }}}
  # {{{ Emperor
  em => {
    name => 'Emperor', # XXX AIYEE
    neighborhood => [ # XXX May move instantly to any square on the board, but it
      q(     ), # XXX can't capture a protected piece
      q( ooo ),
      q( o^o ),
      q(  o  ),
      q(     ) ] },
  # }}}
  # {{{ Evil Wolf
  ew => {
    name => 'Evil Wolf',
    romaji => 'akuro',
    promote => 'fw',
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
    promote => 'fle',
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
      q( 2 2 ),
      q(  ^  ),
      q( 2 2 ),
      q(o   o) ] },
  # }}}
  # {{{ Free Bear
  fbe => {
    name => 'Free Bear',
    neighborhood => [
      q(x   x),
      q( \ / ),
      q( -^- ),
      q( / \ ),
      q(     ) ] },
  # }}}
  # {{{ Free Boar
  fb => {
    name => 'Free Boar',
    neighborhood => [
      q(     ),
      q( \ / ),
      q( -^- ),
      q( / \ ),
      q(     ) ] },
  # }}}
  # {{{ Free Cat
  fca => {
    name => 'Free Cat',
    neighborhood => [
      q(     ),
      q( \ / ),
      q(  ^  ),
      q( / \ ),
      q(     ) ] },
  # }}}
  # {{{ Free Copper
  fc => {
    name => 'Free Copper',
    neighborhood => [
      q(     ),
      q( \\|/ ),
      q(  ^  ),
      q(  |  ),
      q(     ) ] },
  # }}}
  # {{{ Free Earth
  fe => {
    name => 'Free Earth',
    neighborhood => [
      q(     ),
      q(  |  ),
      q(  ^  ),
      q(  |  ),
      q(     ) ] },
  # }}}
  # {{{ Free Gold
  fg => {
    name => 'Free Gold',
    promote => 'fg',
    neighborhood => [
      q(     ),
      q( \|/ ),
      q( -^- ),
      q(  |  ),
      q(     ) ] },
  # }}}
  # {{{ Free Go-Between
  fgb => {
    name => 'Go-Between',
    romaji => 'chunin',
    neighborhood => [
      q(     ),
      q(  o  ),
      q(  ^  ),
      q(  o  ),
      q(     ) ] },
  # }}}
  # {{{ Free Iron
  fi => {
    name => 'Free Iron',
    neighborhood => [
      q(     ),
      q( \|/ ),
      q(  ^  ),
      q(     ),
      q(     ) ] },
  # }}}
  # {{{ Free Leopard
  fle => {
    name => 'Free Leopard',
    neighborhood => [
      q(     ),
      q( \|/ ),
      q(  ^  ),
      q( /|\ ),
      q(     ) ] },
  # }}}
  # {{{ Free Serpent
  fse => {
    name => 'Free Serpent',
    neighborhood => [
      q(     ),
      q(  |  ),
      q(  ^  ),
      q( /|\ ),
      q(     ) ] },
  # }}}
  # {{{ Free Silver
  fs => {
    name => 'Free Silver',
    neighborhood => [
      q(     ),
      q( \|/ ),
      q(  ^  ),
      q( / \ ),
      q(     ) ] },
  # }}}
  # {{{ Free Stone
  fst => {
    name => 'Free Stone',
    neighborhood => [
      q(     ),
      q( \ / ),
      q(  ^  ),
      q(     ),
      q(     ) ] },
  # }}}
  # {{{ Free Wolf
  fw => {
    name => 'Free Wolf',
    neighborhood => [
      q(     ),
      q( \|/ ),
      q(o5^5o),
      q( /|\ ),
      q(     ) ] },
  # }}}
  # {{{ Free Dragon
  frd => {
    name => 'Free Dragon',
    neighborhood => [
      q(     ),
      q( \|/ ),
      q(  ^  ),
      q( ooo ),
      q(     ) ] },
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
  # {{{ Free Tapir
  ftp => {
    name => 'Free Tapir',
    neighborhood => [
      q(     ),
      q( \|/ ),
      q(o5^5o),
      q( /|\ ),
      q(     ) ] },
  # }}}
  # {{{ Free Tiger
  ftg => {
    name => 'Free Tiger',
    neighborhood => [
      q(     ),
      q( \ / ),
      q( -^- ),
      q( /|\ ),
      q(     ) ] },
  # }}}
  # {{{ Furious Fiend
  ff => {
    name => 'Furious Fiend',
    neighborhood => [
      q(L L L),
      q( 333 ),
      q(L3^3L),
      q( 333 ),
      q(L L L) ] },
  # }}}
  # {{{ Go-Between
  gb => {
    name => 'Go-Between',
    romaji => 'chunin',
    promote => 'fgb',
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
    promote => 'fg',
    neighborhood => [
      q(     ),
      q( ooo ),
      q( o^o ),
      q(  o  ),
      q(     ) ] },
  # }}}
  # {{{ Golden Bird
  gbd => {
    name => 'Golden Bird',
    neighborhood => [
      q(o   o),
      q( 3|3 ),
      q(o2^2o),
      q( 3|3 ),
      q(o   o) ] },
  # }}}
  # {{{ Great Dragon
  gdr => {
    name => 'Great Dragon',
    neighborhood => [
      q(o   o),
      q( 323 ),
      q( -^- ),
      q( 323 ),
      q(o   o) ] },
  # }}}
  # {{{ Guardian of the Gods
  ggd => {
    name => 'Guardian of the Gods',
    promote => 'g',
    neighborhood => [
      q(  o  ),
      q( o3o ),
      q(o3^3o),
      q(  3  ),
      q(  o  ) ] },
  # }}}
  # {{{ Hook Mover
  hm => {
    name => 'Hook Mover',
    promote => 'g',
    neighborhood => [
      q(  +  ),
      q(  |  ),
      q(+-^-+),
      q(  |  ),
      q(  +  ) ] },
  # }}}
  # {{{ Iron General
  i => {
    name => 'Iron General',
    romaji => 'tessho',
    promote => 'fi',
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
    promote => 'em',
    neighborhood => [
      q(     ),
      q( ooo ),
      q( o^o ),
      q( ooo ),
      q(     ) ] },
  # }}}
  # {{{ Kirin
  ki => {
    name => 'Kirin',
    romaji => 'kylin',
    promote => 'gd',
    neighborhood => [
      q(  x  ),
      q( o o ),
      q(x ^ x),
      q( o o ),
      q(  x  ) ] },
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
  # {{{ Left Chariot
  lch => {
    name => 'Left Chariot',
    promote => 'g',
    neighborhood => [
      q(     ),
      q( \|  ),
      q(  ^  ),
      q(  o\ ),
      q(     ) ] },
  # }}}
  # {{{ Lion
  ln => {
    name => 'Lion',
    romaji => 'shishi',
    promote => 'ff',
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
  # {{{ Lion Dog
  ld => {
    name => 'Lion Dog',
    promote => 'g',
    neighborhood => [
      q(o o o),
      q( 333 ),
      q(o3^3o),
      q( 333 ),
      q(o o o) ] },
  # }}}
  # {{{ Mountain Witch
  mw => {
    name => 'Mounntain Witch',
    neighborhood => [
      q(     ),
      q( \\o/ ),
      q(  ^  ),
      q( /|\\ ),
      q(     ) ] },
  # }}}
  # {{{ Old Monkey
  om => {
    name => 'Old Monkey',
    promote => 'mw',
    neighborhood => [
      q(     ),
      q( o o ),
      q(  ^  ),
      q( ooo ),
      q(     ) ] },
  # }}}
  # {{{ Old Rat
  or => {
    name => 'Old Rat',
    promote => 'ba',
    neighborhood => [
      q(o   o),
      q( 2 2 ),
      q(  ^  ),
      q(  2  ),
      q(  o  ) ] },
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
    promote => 'gb',
    neighborhood => [
      q(x   x),
      q(  o  ),
      q( o^o ),
      q(  o  ),
      q(x   x) ] },
  # }}}
  # {{{ Prince
  pr => {
    name => 'Prince',
    neighborhood => [
      q(     ),
      q( ooo ),
      q( o^o ),
      q( ooo ),
      q(     ) ] },
  # }}}
  # {{{ Reclining Dragon
  rdr => {
    name => 'Reclining Dragon',
    promote => 'fdr',
    neighborhood => [
      q(     ),
      q(  o  ),
      q( o^o ),
      q( ooo ),
      q(     ) ] },
  # }}}
  # {{{ Reverse Chariot
  rc => {
    name => 'Reverse Chariot',
    romaji => 'hansha',
    promote => 'g',
    neighborhood => [
      q(     ),
      q(  |  ),
      q(  ^  ),
      q(  |  ),
      q(     ) ] },
  # }}}
  # {{{ Right Chariot
  rch => {
    name => 'Right Chariot',
    promote => 'g',
    neighborhood => [
      q(     ),
      q(  |/ ),
      q(  ^  ),
      q( /o  ),
      q(     ) ] },
  # }}}
  # {{{ Rook
  r => {
    name => 'Rook',
    romaji => 'hisha',
    promote => 'g',
    neighborhood => [
      q(     ),
      q(  |  ),
      q( -^- ),
      q(  |  ),
      q(     ) ] },
  # }}}
  # {{{ She-Devil
  sd => {
    name => 'She-Devil',
    promote => 'g',
    neighborhood => [
      q(o o o),
      q( 252 ),
      q(o5^5o),
      q( 252 ),
      q(o o o) ] },
  # }}}
  # {{{ Side Flyer
  sf => {
    name => 'Side Flyer',
    promote => 'g',
    neighborhood => [
      q(     ),
      q( o o ),
      q( -^- ),
      q( o o ),
      q(     ) ] },
  # }}}
  # {{{ Side Mover
  sm => {
    name => 'Side Mover',
    romaji => 'ogyo',
    promote => 'g',
    neighborhood => [
      q(     ),
      q(  o  ),
      q( -^- ),
      q(  o  ),
      q(     ) ] },
  # }}}
  # {{{ Silver General
  s => {
    name => 'Silver General',
    romaji => 'ginsho',
    promote => 'fs',
    neighborhood => [
      q(     ),
      q( ooo ),
      q(  ^  ),
      q( o o ),
      q(     ) ] },
  # }}}
  # {{{ Soldier
  so => {
    name => 'Soldier',
    neighborhood => [
      q(     ),
      q(  |  ),
      q( -^- ),
      q( /|\ ),
      q(     ) ] },
  # }}}
  # {{{ Square Mover
  sm => {
    name => 'Square Mover',
    neighborhood => [
      q(     ),
      q( o|o ),
      q( -^- ),
      q(  |  ),
      q(     ) ] },
  # }}}
  # {{{ Stone General
  st => {
    name => 'Stone General',
    romaji => 'sekisho',
    promote => 'fst',
    neighborhood => [
      q(     ),
      q( o o ),
      q(  ^  ),
      q(     ),
      q(     ) ] },
  # }}}
  # {{{ Teaching King
  tk => {
    name => 'Teaching King',
    neighborhood => [
      q(     ),
      q( \|/ ),
      q( -^- ),
      q( /|\ ),
      q(     ) ] },
  # }}}
  # {{{ Tile General
  t => {
    name => 'Tile General',
    #promote => 'free tile', # XXX Doesn't exist
    neighborhood => [
      q(     ),
      q( o o ),
      q(  ^  ),
      q(  o  ),
      q(     ) ] },
  # }}}
  # {{{ Vertical Mover
  vm => {
    name => 'Vertical Mover',
    romaji => 'kengyo',
    promote => 'g',
    neighborhood => [
      q(     ),
      q(  |  ),
      q( o^o ),
      q(  |  ),
      q(     ) ] },
  # }}}
  # {{{ Violent Ox
  vo => {
    name => 'Violent Ox',
    romaji => 'mogyu',
    promote => 'g',
    neighborhood => [
      q(  o  ),
      q(  2  ),
      q(o2^2o),
      q(  2  ),
      q(  o  ) ] },
  # }}}
  # {{{ Wizard Stork
  ws => {
    name => 'Wizard Stork',
    neighborhood => [
      q(     ),
      q( \ / ),
      q(  ^  ),
      q( /o\ ),
      q(     ) ] },
  # }}}
  # {{{ Wrestler
  wr => {
    name => 'Wrestler',
    promote => 'g',
    neighborhood => [
      q(o   o),
      q( 3 3 ),
      q( o^o ),
      q( 3 3 ),
      q(o   o) ] },
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

Games::Shogi::MakaDaiDai - Piece descriptions and initial configuration for Maka Dai Dai Shogi

=head1 SYNOPSIS

  use Games::Shogi::MakaDaiDai;
  $Game = Games::Shogi::MakaDaiDai->new;
  $piece = $Game->board()->[2][2];
  print @{$Game->neighbor($piece);
  print $Game->english_name('c'); # 'Copper General'

=head1 DESCRIPTION

Maka Dai Dai Shogi, at 19 squares on a side, is the second largest commonly known Shogi game. Tai Shogi is the largest commonly known game, with Taikyoku Shogi thought to be the largest ever played, nearly 4x as large as Maka Dai Dai, with 36 squares on a side.

The more bizarre pieces include the Buddhist Devil, Capricorn and the Lion appearing again. L<Games::Shogi> explains most of the piece's moves, and there is some annotation here with the 'igui' key in a piece's hash indicating exotic powers.

=head1 SEE ALSO

L<perl>

=head1 AUTHOR

Jeffrey Goff, E<lt>jgoff@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2004 by Jeffrey Goff

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
