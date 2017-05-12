package Games::Shogi::DaiDai;

use strict;
use warnings;
use vars qw(@ISA $VERSION);
use Games::Shogi;

@ISA = qw(Games::Shogi);
$VERSION = '0.01';

sub size() { 17 }
sub promotion_zone() { 6 }
sub allow_drop() { undef }
sub capture() { [ 'K', 'CP' ] }

# {{{ Board static data
my @board = (
  #    17  16  15  14  13  12  11  10   9   8   7   6   5   4   3   2   1
  [qw(  L  HM  DO   R  SM  DK FTP RIG   K  LG  FK  FD  DH  SC  SD LNG   L)],  #a
  [qw(RCH  PS  LD  BM  FD  RB  KI   G  NK   G  PH  CS  PS  OR   ?  OK RCH)],  #b
  [qw(  _   B   _  EB   _  FH   _  EW GDR  EW   _ WBF   _  EF   _  VM   _)],  #c
  [qw( WT  WE  SB EBA   W   S   I   C  GB   C   I   S   W WBA NBA  FE BDR)],  #d
  [qw( RC  SM  VO  AB  EW  VB  FL  ST SBR  ST  FL  VB  EW  AB  VO  SM  LC)],  #e
  [qw(  P   P   P   P   P   P   P   P   P   P   P   P   P   P   P   P   P)],  #f
  [qw(  _   _   _   _   _  HD   _   _   _   _   _  HD   _   _   _   _   _)],  #g
  [qw(  _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _)],  #h
  [qw(  _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _)],  #i
  [qw(  _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _)],  #j
  [qw(  _   _   _   _   _  hd   _   _   _   _   _  hd   _   _   _   _   _)],  #k
  [qw(  p   p   p   p   p   p   p   p   p   p   p   p   p   p   p   p   p)],  #l
  [qw( lc  sm  vo  ab  ew  vb  fl  st sbr  st  fl  vb  ew  ab  vo  sm  rc)],  #m
  [qw(bdr  fe nba wba   w   s   i   c  gb   c   i   s   w eba  sb  we  wt)],  #n
  [qw(  _  vm   _  ef   _ wbf   _  ew gdr  ew   _  fh   _  eb   _   b   _)],  #o
  [qw(rch  ok   ?  or  ps  cs  ph   g  nk   g  ki  rb  fd  bm  ld  ps rch)],  #p
  [qw(  l lng  sd  sc  dh  fd  fk  lg   k rig ftp  dk  sm   r  do  hm   l)] ),#q
# }}}

# {{{ Pieces
my $pieces = {
  # {{{ Angry Boar
  ab => {
    name => 'Angry Boar',
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
  # {{{ Blind Monkey
  bm => {
    name => 'Blind Monkey',
    neighborhood => [
      q(     ),
      q( o o ),
      q( o^o ),
      q( o o ),
      q(     ) ] },
  # }}}
  # {{{ Blue Dragon
  bd => {
    name => 'Blue Dragon',
    neighborhood => [
      q(  o  ),
      q( oo/ ),
      q( -^- ),
      q(  o  ),
      q(  o  ) ] },
  # }}}
  # {{{ Cat Sword
  cs => {
    name => 'Cat Sword',
    romaji => 'myojin',
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
    neighborhood => [
      q(     ),
      q( ooo ),
      q(  ^  ),
      q(  o  ),
      q(     ) ] },
  # }}}
  # {{{ Dove
  d => {
    name => 'Dove',
    promote => 'eba',
    neighborhood => [
      q(o o o),
      q( 525 ),
      q(o2^2o),
      q( 525 ),
      q(o o o) ] },
  # }}}
  # {{{ Dragon Horse
  dh => {
    name => 'Dragon Horse',
    romaji => 'ryume',
    promote => 'cs',
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
    promote => 'fd',
    neighborhood => [
      q(     ),
      q( o|o ),
      q( -^- ),
      q( o|o ),
      q(     ) ] },
  # }}}
  # {{{ Eastern Barbarian
  eb => {
    name => 'Eastern Barbarian',
    promote => 'ln',
    neighborhood => [
      q(  o  ),
      q( o2o ),
      q( o^o ),
      q(  2  ),
      q(  o  ) ] },
  # }}}
  # {{{ Enchanted Badger
  eba => {
    name => 'Enchanted Badger',
    neighborhood => [
      q(  o  ),
      q(  2  ),
      q(o2^2o),
      q(     ),
      q(     ) ] },
  # }}}
  # {{{ Enchanted Fox
  ef => {
    name => 'Enchanted Fox',
    neighborhood => [
      q(o   o),
      q( 2 2 ),
      q(  ^  ),
      q(  2  ),
      q(  o  ) ] },
  # }}}
  # {{{ Evil Wolf
  ew => {
    name => 'Evil Wolf',
    romaji => 'akuro',
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
    neighborhood => [
      q(o   o),
      q( 2 2 ),
      q(  ^  ),
      q( 2 2 ),
      q(o   o) ] },
  # }}}
  # {{{ Flying Horse
  fh => {
    name => 'Flying Horse',
    promote => 'fk',
    neighborhood => [
      q(     ),
      q( ooo ),
      q(o2^2o),
      q( o o ),
      q(     ) ] },
  # }}}
  # {{{ Fragrant Elephant
  fel => {
    name => 'Fragrant Elephant',
    neighborhood => [
      q(  o  ),
      q( \2/ ),
      q(o2^2o),
      q( 222 ),
      q(o o o) ] },
  # }}}
  # {{{ Free Demon
  fd => {
    name => 'Free Demon',
    promote => 'rb',
    neighborhood => [
      q(  o  ),
      q( \5/ ),
      q( -^- ),
      q( /5\ ),
      q(  o  ) ] },
  # }}}
  # {{{ Free Tapir
  ftp => {
    name => 'Free Tapir',
    promote => 'wb',
    neighborhood => [
      q(     ),
      q( \|/ ),
      q(o5^5o),
      q( /|\ ),
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
  # {{{ Golden Bird
  gbd => {
    name => 'Golden Bird',
    promote => 'ph',
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
    promote => 'ki',
    neighborhood => [
      q(o   o),
      q( 323 ),
      q( -^- ),
      q( 323 ),
      q(o   o) ] },
  # }}}
  # {{{ Great Elephant
  ge => {
    name => 'Great Elephant',
    promote => 'ld',
    neighborhood => [
      q(o o o),
      q( 333 ),
      q(o5^5o),
      q( 535 ),
      q(o o o) ] },
  # }}}
  # {{{ Hook Mover
  hm => {
    name => 'Hook Mover',
    promote => 'ps',
    neighborhood => [
      q(  +  ),
      q(  |  ),
      q(+-^-+),
      q(  |  ),
      q(  +  ) ] },
  # }}}
  # {{{ Howling Dog
  hd => {
    name => 'Howling Dog',
    neighborhood => [
      q(     ),
      q(  |  ),
      q(  ^  ),
      q(  o  ),
      q(     ) ] },
  # }}}
  # {{{ Iron General
  i => {
    name => 'Iron General',
    romaji => 'tessho',
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
    neighborhood => [
      q(     ),
      q( \|  ),
      q(  ^  ),
      q(  o\ ),
      q(     ) ] },
  # }}}
  # {{{ Left General
  lg => {
    name => 'Left General',
    neighborhood => [
      q(     ),
      q( ooo ),
      q(  ^o ),
      q( ooo ),
      q(     ) ] },
  # }}}
  # {{{ Lion Dog
  ld => {
    name => 'Lion Dog',
    neighborhood => [
      q(o o o),
      q( 333 ),
      q(o3^3o),
      q( 333 ),
      q(o o o) ] },
  # }}}
  # {{{ Long Nosed Goblin
  lng => {
    name => 'Long Nosed Goblin',
    promote => 'okh',
    neighborhood => [
      q(X   X),
      q( \o/ ),
      q( o^o ),
      q( /o\ ),
      q(X   X) ] },
  # }}}
  # {{{ Mountain Witch
  mw => {
    name => 'Mountain Witch',
    promote => 'bm',
    neighborhood => [
      q(     ),
      q( \o/ ),
      q(  ^  ),
      q( / \ ),
      q(     ) ] },
  # }}}
  # {{{ Neighboring King
  nk => {
    name => 'Neighboring King',
    promote => 'sbr',
    neighborhood => [
      q(     ),
      q( ooo ),
      q( o^o ),
      q( o o ),
      q(     ) ] },
  # }}}
  # {{{ Northern Barbarian
  nb => {
    name => 'Northern Barbarian',
    promote => 'fel',
    neighborhood => [
      q(o   o),
      q( 2 2 ),
      q( o^o ),
      q( o o ),
      q(     ) ] },
  # }}}
  # {{{ Old Kite Hawk
  ok => {
    name => 'Old Kite Hawk',
    neighborhood => [
      q(  o  ),
      q( o2o ),
      q(o2^2o),
      q(  2  ),
      q(  o  ) ] },
  # }}}
  # {{{ Old Rat
  or => {
    name => 'Old Rat',
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
    neighborhood => [
      q(x   x),
      q(  o  ),
      q( o^o ),
      q(  o  ),
      q(x   x) ] },
  # }}}
  # {{{ Poisonous Snake
  ps => {
    name => 'Poisonous Snake',
    neighborhood => [
      q(  x  ),
      q(     ),
      q( o^o ),
      q(     ),
      q(x   x) ] },
  # }}}
  # {{{ Prancing Stag
  pst => {
    name => 'Prancing Stag',
    neighborhood => [
      q(     ),
      q( ooo ),
      q(o2^2o),
      q( o o ),
      q(x   x) ] },
  # }}}
  # {{{ Reverse Chariot
  rc => {
    name => 'Reverse Chariot',
    romaji => 'hansha',
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
    neighborhood => [
      q(     ),
      q(  |/ ),
      q(  ^  ),
      q( /o  ),
      q(     ) ] },
  # }}}
  # {{{ Right General
  rig => {
    name => 'Right General',
    neighborhood => [
      q(     ),
      q( ooo ),
      q( o^  ),
      q( ooo ),
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
  # {{{ Rushing Bird
  rb => {
    name => 'Rushing Bird',
    neighborhood => [
      q(     ),
      q( \|/ ),
      q( -^- ),
      q( /|\ ),
      q(     ) ] },
  # }}}
  # {{{ Savage Tiger
  st => {
    name => 'Savage Tiger',
    neighborhood => [
      q(  o  ),
      q( o2o ),
      q(  ^  ),
      q(  2  ),
      q(  o  ) ] },
  # }}}
  # {{{ She-Devil
  sd => {
    name => 'She-Devil',
    promote => 'ef',
    neighborhood => [
      q(o o o),
      q( 252 ),
      q(o5^5o),
      q( 252 ),
      q(o o o) ] },
  # }}}
  # {{{ Side Chariot
  sm => {
    name => 'Side Chariot',
    neighborhood => [
      q(     ),
      q(  |  ),
      q( -^- ),
      q( o|o ),
      q(     ) ] },
  # }}}
  # {{{ Side Mover
  sm => {
    name => 'Side Mover',
    romaji => 'ogyo',
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
    neighborhood => [
      q(     ),
      q( ooo ),
      q(  ^  ),
      q( o o ),
      q(     ) ] },
  # }}}
  # {{{ Southern Barbarian
  sb => {
    name => 'Southern Barbarian',
    promote => 'we',
    neighborhood => [
      q(     ),
      q( o o ),
      q( o^o ),
      q( 2 2 ),
      q(o   o) ] },
  # }}}
  # {{{ Square Mover
  sm => {
    name => 'Square Mover',
    promote => 'ps',
    neighborhood => [
      q(     ),
      q( o|o ),
      q( -^- ),
      q(  |  ),
      q(     ) ] },
  # }}}
  # {{{ Standard Bearer
  sbr => {
    name => 'Standard Bearer',
    neighborhood => [
      q(     ),
      q( \|/ ),
      q(oo^oo),
      q( ooo ),
      q(o o o) ] },
  # }}}
  # {{{ Stone General
  st => {
    name => 'Stone General',
    romaji => 'ryume',
    neighborhood => [
      q(     ),
      q( o o ),
      q(  ^  ),
      q(     ),
      q(     ) ] },
  # }}}
  # {{{ Vertical Mover
  vm => {
    name => 'Vertical Mover',
    romaji => 'kengyo',
    neighborhood => [
      q(     ),
      q(  |  ),
      q( o^o ),
      q(  |  ),
      q(     ) ] },
  # }}}
  # {{{ Violent Bear
  vb => {
    name => 'Violent Bear',
    neighborhood => [
      q(o   o),
      q( 2 2 ),
      q(  ^  ),
      q(     ),
      q(     ) ] },
  # }}}
  # {{{ Violent Ox
  vo => {
    name => 'Violent Ox',
    romaji => 'mogyu',
    neighborhood => [
      q(  o  ),
      q(  2  ),
      q(o2^2o),
      q(  2  ),
      q(  o  ) ] },
  # }}}
  # {{{ Water Buffalo
  wbf => {
    name => 'Water Buffalo',
    neighborhood => [
      q(  o  ),
      q( \o/ ),
      q( -^- ),
      q( /o\ ),
      q(  o  ) ] },
  # }}}
  # {{{ Western Barbarian
  wb => {
    name => 'Western Barbarian',
    promote => 'ld',
    neighborhood => [
      q(     ),
      q( ooo ),
      q( 2^2 ),
      q(  o  ),
      q(     ) ] },
  # }}}
  # {{{ White Elephant
  we => {
    name => 'White Elephant',
    neighborhood => [
      q(o o o),
      q( 222 ),
      q(o2^2o),
      q( /2\ ),
      q(  o  ) ] },
  # }}}
  # {{{ White Tiger
  wt => {
    name => 'White Tiger',
    neighborhood => [
      q(  o  ),
      q( \oo ),
      q( -^- ),
      q(  o  ),
      q(  o  ) ] },
  # }}}
  # {{{ Wizard Stork
  ws => {
    name => 'Wizard Stork',
    promote => 'or',
    neighborhood => [
      q(     ),
      q( \ / ),
      q(  ^  ),
      q( /o\ ),
      q(     ) ] },
  # }}}
  # {{{ Wood General
  w => {
    name => 'Wood General',
    neighborhood => [
      q(o   o),
      q( 2 2 ),
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

Games::Shogi::DaiDai - Piece descriptions and initial configuration for Dai Dai Shogi

=head1 SYNOPSIS

  use Games::Shogi::DaiDai;
  $Game = Games::Shogi::DaiDai->new;
  $piece = $Game->board()->[2][2];
  print @{$Game->neighbor($piece);
  print $Game->english_name('c'); # 'Copper General'

=head1 DESCRIPTION

Dai Dai Shogi has some of the wilder pieces in Shogi, namely the Hook Mover and Long-Nosed Goblin. The Hook Mover moves orthogonally, and the Long-Nosed Goblin along the diagonals. This in itself isn't terribly exotic, until you find that the hook mover slides orthogonally like a rook, then slides any distance perpendicular to the first move. So, it can move into enemy territory like a rook *and* slide left or right to capture any piece along the rank it lands on.

As such, notating these pieces' movements is a little bit exotic. Rather than attempting to enumerate every possible location these pieces can move to, they're simply notated with a slight variation on the C<--> jump notation, with '+' replacing the final '-'. If a piece is ever found that both hook-moves and jumps, possibly in the rumored Mujotai Shogi, we'll use C<--+> or the equivalent.

=head1 SEE ALSO

L<perl>

=head1 AUTHOR

Jeffrey Goff, E<lt>jgoff@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2004 by Jeffrey Goff

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
