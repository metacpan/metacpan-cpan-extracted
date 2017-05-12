package Games::Shogi::Tenjiku;

use strict;
use warnings;
use vars qw(@ISA $VERSION);
use Games::Shogi;

@ISA = qw(Games::Shogi);
$VERSION = '0.01';

sub size() { 16 }
sub promotion_zone() { 5 }
sub allow_drop() { undef }
sub capture() { [ 'K', 'CP' ] }

# {{{ Board
my @board = (
  #    16  15  14  13  12  11  10   9   8   7   6   5   4   3   2   1
  [qw(  L   N  FL   I   C   S   G  DE   K   G   S   C   I  FL   N   L )],  # 1
  [qw( RC   _ CHS CHS   _  BT  PH  FK  LN  KI  BT   _ CHS CHS   _  RC )],  # 2
  [qw( SS  VS   B  DH  DK WBF FID FEG LHK FID WBF  DK  DH   B  VS  SS )],  # 3
  [qw( SM  VM   R  HF  SE  BG  RG   V  GG  RG  BG  SE  HF   R  VM  SM )],  # 4
  [qw(  P   P   P   P   P   P   P   P   P   P   P   P   P   P   P   P )],  # 5
  [qw(  _   _   _   _  DG   _   _   _   _   _   _  DG   _   _   _   _ )],  # 6
  [qw(  _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _ )],  # 7
  [qw(  _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _ )],  # 8
  [qw(  _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _ )],  # 9
  [qw(  _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _ )],  # 10
  [qw(  _   _   _   _  dg   _   _   _   _   _   _  dg   _   _   _   _ )],  # 11
  [qw(  p   p   p   p   p   p   p   p   p   p   p   p   p   p   p   p )],  # 12
  [qw( sm  vm   r  hf  se  bg  rg  gg   v  rg  bg  se  hf   r  vm  sm )],  # 13
  [qw( ss  vs   b  dh  dk wbf fid lhk feg fid wbf  dk  dh   b  vs  ss )],  # 14
  [qw( rc   _ chs chs   _  bt  ki  ln  fk  ph  bt   _ chs chs   _  rc )],  # 15
  [qw(  l   n  fl   i   c   s   g  de   k   g   s   c   i  fl   n   l )] );# 16
# }}}

# {{{ Pieces
my $pieces = {
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
  # {{{ Bishop General
  bg => {
    name => 'Bishop General',
    promote => 'v',
    neighborhood => [
      q(\   /),
      q( \ / ),
      q(  ^  ),
      q( / \ ),
      q(/   \\) ] },
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
  # {{{ Chariot Soldier
  chs => {
    name => 'Chariot Soldier',
    promote => 'ht',
    neighborhood => [
      q(     ),
      q( \|/ ),
      q(oo^oo),
      q( /|\ ),
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
  # {{{ Dog
  d => {
    name => 'Dog',
    promote => 'mg',
    neighborhood => [
      q(     ),
      q(  o  ),
      q(  ^  ),
      q( o o ),
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
  # {{{ Fire Demon
  fid => {
    name => "Fire Demon",
    neighborhood => [
      q(\    |    /),
      q( ooooooooo ),
      q( ooooooooo ),
      q( ooooooooo ),
      q( ooo!!!ooo ),
      q(-ooo!^!ooo-),
      q( ooo!!!ooo ),
      q( ooooooooo ),
      q( ooooooooo ),
      q( ooooooooo ),
      q(/    |    \\) ] },
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
  # {{{ Free Eagle
  feg => {
    name => 'Free Eagle',
    neighborhood => [
      q(  x  ),
      q( \|/ ),
      q(x-^-x),
      q( /|\ ),
      q(  x  ) ] },
  # }}}
  # {{{ Free King
  fk => {
    name => 'Free King',
    romaji => "hon'o",
    promote => 'feg',
    neighborhood => [
      q(     ),
      q( \|/ ),
      q( -^- ),
      q( /|\ ),
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
  # {{{ Great General
  gg => {
    name => "Great General",
    neighborhood => [
      q(\ | /),
      q( \|/ ),
      q( -^- ),
      q( /|\ ),
      q(/   \\) ] },
  # }}}
  # {{{ Heavenly Tetrarchs
  ht => {
    name => 'Heavenly Tetrarchs',
    neighborhood => [
      q(\     /),
      q( \   / ),
      q(  !!!  ),
      q(ox!^!xo),
      q(  !!!  ),
      q( /   \ ),
      q(/     \\) ] },
  # }}}
  # {{{ Horned Falcon
  hf => {
    name => 'Horned Falcon',
    romaji => 'kakuo',
    promote => 'bg',
    igui => 1,
    neighborhood => [
      q(  2  ),
      q( \1/ ),
      q( -^- ),
      q( /|\ ),
      q(     ) ] },
  # }}}
  # {{{ Iron General
  i => {
    name => 'Iron General',
    romaji => 'tessho',
    promote => 'vs',
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
  # {{{ Knight
  n => {
    name => 'Knight',
    romaji => 'keima',
    promote => 'ss',
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
    promote => 'who',
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
    promote => 'lhk',
    igui => 1,
    neighborhood => [
      q(22222),
      q(21112),
      q(21^12),
      q(21112),
      q(22222) ],
    move => { area => 2 }, # Really an area of 1 and a spare move...
    jump => { area => 2 } }, # Not quite correct, more of area 2 radius 1...
  # }}}
  # {{{ Lion Hawk
  lhk => {
    name => 'Lion Hawk',
    neighborhood => [
      q(\     /),
      q( ooooo ),
      q( ooooo ),
      q( oo^oo ),
      q( ooooo ),
      q( ooooo ),
      q(/     \\) ] },
  # }}}
  # {{{ Multi General
  mg => {
    name => 'Multi General',
    neighborhood => [
      q(     ),
      q(  |  ),
      q(  ^  ),
      q( / \ ),
      q(     ) ] },
  # }}}
  # {{{ Pawn
  p => {
    name => 'Pawn',
    romaji => 'fuhyo',
    promote => 'g',
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
    promote => 'wh',
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
  # {{{ Rook General
  rg => {
    name => "Rook General",
    promote => 'gg',
    neighborhood => [
      q(  |  ),
      q(  |  ),
      q(--^--),
      q(  |  ),
      q(  |  ) ] },
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
  # {{{ Side Soldier
  ss => {
    name => 'Side Soldier',
    promote => 'wbf',
    neighborhood => [
      q(  o  ),
      q(  o  ),
      q( -^- ),
      q(  o  ),
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
  # {{{ Soaring Eagle
  se => {
    name => 'Soaring Eagle',
    romaji => 'hiju',
    promote => 'rg',
    igui => 1,
    neighborhood => [
      q(2   2),
      q( 1|1 ),
      q( -^- ),
      q( /|\ ),
      q(     ) ] },
  # }}}
  # {{{ Vertical Soldier
  vs => {
    name => 'Vertical Soldier',
    promote => 'chs',
    neighborhood => [
      q(     ),
      q(  |  ),
      q(oo^oo),
      q(  o  ),
      q(     ) ] },
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
  # {{{ Vice General
  v => {
    name => "Vice General",
    neighborhood => [
      q(\    |    /),
      q( \   |   / ),
      q(  xxxxxxx  ),
      q(  xxxxxxx  ),
      q(  xxxxxxx  ),
      q(--xxx^xxx--),
      q(  xxxxxxx  ),
      q(  xxxxxxx  ),
      q(  xxxxxxx  ),
      q( /   |   \ ),
      q(/    |    \\) ] },
  # }}}
  # {{{ Water Buffalo
  wbf => {
    name => 'Water Buffalo',
    promote => 'fid',
    neighborhood => [
      q(  o  ),
      q( \2/ ),
      q( -^- ),
      q( /2\ ),
      q(  o  ) ] },
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

Games::Shogi::Tenjiku - Piece descriptions and initial configuration for Tenjiku Shogi

=head1 SYNOPSIS

  use Games::Shogi::Tenjiku;
  $Game = Games::Shogi::Tenjiku->new;
  $piece = $Game->board()->[2][2];
  print @{$Game->neighbor($piece);
  print $Game->english_name('c'); # 'Copper General'

=head1 DESCRIPTION

Tenjiku Shogi is one of the larger variants, and one we have the most research on. Containing a wealth of exotic pieces such as the Bishop General (the Bishop with the ability to jump), Fire Demons and the Heavenly Tetrarchs, it makes for every interesting gameplay. Thankfully it doesn't include drops, like almost every other known Shogi variant.

=head1 SEE ALSO

L<perl>

=head1 AUTHOR

Jeffrey Goff, E<lt>jgoff@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2004 by Jeffrey Goff

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=_END__
