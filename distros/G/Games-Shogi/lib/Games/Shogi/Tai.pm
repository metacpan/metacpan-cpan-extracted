package Games::Shogi::Tai;

use strict;
use warnings;
use vars qw(@ISA $VERSION);
use Games::Shogi;

@ISA = qw(Games::Shogi);
$VERSION = '0.01';

sub size() { 25 }
sub promotion_zone() { 7 }
sub allow_drop() { undef }
sub capture() { [ 'K', 'CP' ] }

# {{{ Board static data
my @board = (
    #     25  24  23  22  21  20  19  18  17  16  15  14  13  12  11  10   9   8   7   6   5   4   3   2   1
    [qw(   L  WT  WH  FD  LG   D   R  DH  DK  FK   G DSP   E  DB  FK   G  DK  DH   R   D  LG  FD  WH  TS   L )],  # a
    [qw(  RC SDR  SE   N  PS FTP   B  FE  WE FDE   S RIG  LG   S FDE  WE  FE   B FTP  PS   N SDR  SE SDR  RC )],  # b
    [qw( SCH WHO  RS  VO CSW  BB SDE GDE  BM  BT  SD  GG  NK  WR BDE  BT  BM GDE SDE  BB CSW  VO  RS WHO SCH )],  # c
    [qw(  SO WBF  FL  NB  SB  CC  HF  OM  OK  PC GBD  PH  LN  KI  GD  PC  RB  OM  HF  CC  EB  WB  FL WBF  SO )],  # d
    [qw( RCH  VS  WO  Ea  ST   T   I   C  OR  CS  RD  HM  DE  CA  RD  CS  OR   C   I   T  ST  EA  WO  BD LCH )],  # e
    [qw(  HD  FH EBA  DO  FO  SM  VM VBE SBR PST  AB  EW  LD  EW  AB PST SBR VBE  VM  SM  FO  DO EBA  FH  HD )],  # f
    [qw(   P   P   P   P   P   P   P   P   P   P   P   P   P   P   P   P   P   P   P   P   P   P   P   P   P )],  # g
    [qw(   _   _   _   _   _   _   _  GB   _   _   _   _   _   _   _   _   _  GB   _   _   _   _   _   _   _ )],  # h
    [qw(   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _ )],  # i
    [qw(   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _ )],  # j
    [qw(   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _ )],  # k
    [qw(   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _ )],  # l
    [qw(   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _ )],  # m
    [qw(   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _ )],  # n
    [qw(   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _ )],  # o
    [qw(   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _ )],  # p
    [qw(   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _   _ )],  # q
    [qw(   _   _   _   _   _   _   _   gb  _   _   _   _   _   _   _   _   _   gb  _   _   _   _   _   _   _ )],  # r
    [qw(   p   p   p   p   p   p   p   p   p   p   p   p   p   p   p   p   p   p   p   p   p   p   p   p   p )],  # s
    [qw(  hd  fh eba  do  fo  sm  vm vbe sbr pst  ab  ew  ld  ew  ab pst sbr vbe  vm  sm  fo  do  eba fh  hd )],  # t
    [qw( lch  bd  wo  ea  st   t   i   c  or  cs  rd  ca  de  hm  rd  cs  or   c   i   t  st  ea  wo  vs rch )],  # u
    [qw(  so wbf  fl  wb  eb  cc  hf  om  ok  pc  gd  ki  ln  ph  gbd pc  rb  om  hf  cc  sb  nb  fl  wbf so )],  # v
    [qw( sch who  rs  vo csw  bb sde gde  bm  bt bde  wr  nk  gg  sd  bt  bm gde sde  bb csw  vo  rs who sch )],  # w
    [qw(  rc sdr  se   n  ps ftp   b  fe  we fde   s  lg  cp rig   s fde  we  fe   b ftp  ps   n  se sdr  rc )],  # x
    [qw(   l  bd   w  fd  lg   d   r  dh  dk  fk   g  dv   e dsp  fk   g  dk  dh   r   d  lg  fd   w  wt   l )] );# y
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
  # {{{ Blind Bear
  bb => {
    name => 'Blind Bear',
    neighborhood => [
      q(     ),
      q( o o ),
      q(  ^  ),
      q( o|o ),
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
  # {{{ Crown Prince
  cp => {
    name => 'Crown Prince',
    romaji => 'taishi',
    promote => 'em',
    neighborhood => [
      q(     ),
      q( ooo ),
      q( o^o ),
      q( ooo ),
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
  # {{{ Dove
  d => {
    name => 'Dove',
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
    promote => 'cp',
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
    neighborhood => [
      q(     ),
      q(  o  ),
      q(  ^  ),
      q(  o  ),
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
  # {{{ Enchanted Badger
  eba => {
    name => 'Enchanted Badger',
    promote => 'do',
    neighborhood => [
      q(  o  ),
      q(  2  ),
      q(o2^2o),
      q(     ),
      q(     ) ] },
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
  # {{{ Fierce Eagle
  fe => {
    name => 'Fierce Eagle',
    neighborhood => [
      q(o   o),
      q( 2 2 ),
      q( o^o ),
      q( 2 2 ),
      q(o   o) ] },
  # }}}
  # {{{ Flying Dragon
  fd => {
    name => 'Flying Dragon',
    romaji => 'hiryu',
    promote => 'dk',
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
    neighborhood => [
      q(  o  ),
      q( \5/ ),
      q( -^- ),
      q( /5\ ),
      q(  o  ) ] },
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
  # {{{ Golden Deer
  gd => {
    name => 'Golden Deer',
    neighborhood => [
      q(     ),
      q( \ / ),
      q(  ^  ),
      q( 2 2 ),
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
  # {{{ Great Elephant
  ge => {
    name => 'Great Elephant',
    neighborhood => [
      q(o o o),
      q( 333 ),
      q(o5^5o),
      q( 535 ),
      q(o o o) ] },
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
    neighborhood => [
      q(  +  ),
      q(  |  ),
      q(+-^-+),
      q(  |  ),
      q(  +  ) ] },
  # }}}
  # {{{ Horned Falcon
  hf => {
    name => 'Horned Falcon',
    romaji => 'kakuo',
    neighborhood => [
      q(  2  ),
      q( \1/ ),
      q( -^- ),
      q( /|\ ),
      q(     ) ] },
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
  # {{{ Kirin
  ki => {
    name => 'Kirin',
    romaji => 'kylin',
    promote => 'GD',
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
    promote => 'ge',
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
    promote => 'fe',
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
    promote => 'lgn',
    neighborhood => [
      q(  o  ),
      q( o2o ),
      q(o2^2o),
      q(  2  ),
      q(  o  ) ] },
  # }}}
  # {{{ Old Monkey
  om => {
    name => 'Old Monkey',
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
    promote => 'ws',
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
  # {{{ Peacock
  pc => {
    name => 'Peacock',
    neighborhood => [
      q(X   X),
      q( \ / ),
      q(  ^  ),
      q( o o ),
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
  # {{{ Poisonous Snake
  ps => {
    name => 'Poisonous Snake',
    promote => 'hm',
    neighborhood => [
      q(  x  ),
      q(     ),
      q( o^o ),
      q(     ),
      q(x   x) ] },
  # }}}
  # {{{ Ramshead Soldier
  rs => {
    name => 'Ramshead Soldier',
    neighborhood => [
      q(     ),
      q( \ / ),
      q(  ^  ),
      q(     ),
      q(  x  ) ] },
  # }}}
  # {{{ Reclining Dragon
  rdr => {
    name => 'Reclining Dragon',
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
    promote => 'fde',
    neighborhood => [
      q(     ),
      q( \|/ ),
      q( -^- ),
      q( /|\ ),
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
  # {{{ Side Dragon
  sdr => {
    name => 'Side Dragon',
    neighborhood => [
      q(     ),
      q(  |  ),
      q( -^- ),
      q(  o  ),
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
  # {{{ Silver Demon
  sde => {
    name => 'Silver Demon',
    neighborhood => [
      q(o   o),
      q( 2 2 ),
      q(  ^  ),
      q( / \ ),
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
    romaji => 'sekisho',
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
    neighborhood => [
      q(     ),
      q( o o ),
      q(  ^  ),
      q(  o  ),
      q(     ) ] },
  # }}}
  # {{{ Turtle-Snake
  ts => {
    name => 'Turtle-Snake',
    neighborhood => [
      q(     ),
      q( \o/ ),
      q(  ^  ),
      q( o o ),
      q(o   o) ] },
  # }}}
  # {{{ Vermillion Sparrow
  vs => {
    name => 'Vermillion Sparrow',
    neighborhood => [
      q(     ),
      q( \|/ ),
      q(  ^  ),
      q( ooo ),
      q(o   o) ] },
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
    promote => 'ftp',
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

Games::Shogi::Tai - Piece descriptions and initial configuration for Tai Shogi

=head1 SYNOPSIS

  use Games::Shogi::Tai;
  $Game = Games::Shogi::Chu->new;
  $piece = $Game->board()->[2][2];
  print @{$Game->neighbor($piece);
  print $Game->english_name('c'); # 'Copper General'

=head1 DESCRIPTION

At 25 x 25, Tai Shogi is the largest game conclusively known to be played in antiquity. It includes almost all of the hard-to-define pieces in the smaller Shogis and introduces the Emperor. Thankfully it doesn't occur in the starting configuration, but if you manage to promote the Crown Prince you can play with one. This piece can move instantaneously to any piece on the board, capturing any piece that isn't protected by another piece.

Of course, it still includes pieces like the Buddhist Spirit, Lion, Capricorn and Vice General.

=head1 SEE ALSO

L<perl>

=head1 AUTHOR

Jeffrey Goff, E<lt>jgoff@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2004 by Jeffrey Goff

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
