package Games::Shogi::Taikyoku;

use 5.008001;
use strict;
use warnings;
use vars qw(@ISA $VERSION);
use Games::Shogi;

@ISA = qw(Games::Shogi);
$VERSION = '0.01';

sub size() { 36 }
sub promotion_zone() { 12 }
sub allow_drop() { undef }
sub capture() { [ 'K', 'CP', 'EM' ] }

# {{{ Board static data
my @board = (
  #      36   35   34   33   32   31   30   29   28   27   26   25   24   23   22   21   20   19   18   17   16   15   14   13   12   11   10    9    8    7    6    5    4    3    2    1
  [qw(    L   WT   RR   WH  FID  MEL  LNG   BC   RH  FDE  EDR   WD  FTP   FK  RST  RIG    G   CP    K    G   LG  RST   FK  FTP   CD  EDR  FDE   RH   BC  LNG  MEL  FID   WH   RR   TS    L )], # a
  [qw(   RC  FEL   MD   FS   CO RADR  FOD   MS   RP  RSE  SSE   GD  RUT  RUB   NS  GGD    S  DEL   NK    S   WR  BDE  RUB  RUT   GD  SSE  RSE   RP   MS  FOD RADR   CO   FS   MD  WEL   RC )], # b
  [qw(   GC  SDR RUST   RW   BG   RG  RTI  RDR   BO  WDR   FP   RB   OK   PC WADR FIDR    C  PHM  KIM    C FIDR WADR   PC   OK   RB   FP  WDR   BO  LDR  LTI   RG   BG   RW RUST  SDR   GC )], # c
  [qw(  SCH   VB    N   PI  CHG  PUG   HG   OG  CST  SBR  SRB  GDE   LN  CAC   GS  VDR  WDE    V   GG  WDE  VDR   GS  CAC   LN  GDE  SRB  SBR  CST   OG   HG  PUG  CHG   PI    N   VB  SCH )], # d
  [qw(  STC  CLE    B    R   SW   FC   MF   VT   SO  LST  CDR  CCH RUCH   RS   VO  GDR  GBD  DSP   DV  GBD  GDR   VO   RS RUCH  CCH  CDR  LST   SO   VT   MF   FC   SW    R    B  CLE  STC )], # e
  [qw(  WCH  WHO  HDR   SM   PS  WBF   FL   FE  FDR  PSN   FG   SC  BLD   WG    F   PH   KI   HM   LT   GT   CA    F   WG  BLD   SC   FG  PSN  FDR   FE   FL  WBF   PS   SM  HDL  WHO  WCH )], # f
  [qw(  TCH  VEW  SOX  DON  FLH  VIB   AB   EW   LH  FCO   OM   CC  NBA  SBA   VS   VW   TF   CM   RM   TF   VW   VS  EBA  WBA   CC   OM  FCO   LH   EW   AB  VIB  FLH  DON  SOX  VEW  TCH )], # g
  [qw(  ECH  VSP ENBA  HOM  SWO  CMO   CS  SWW   BM   BT   OC   SF   BB   OR  SQM  CSE REDR  FEG  LHK REDR  CSE  SQM   OR   BB   SF   OC   BT   BM  SWW   CS  CMO  SWO  HOM ENBA  BDR  ECH )], # h
  [qw(  CSO  SSO  VSO  WIG  RVG    M  FST  HSO    W  OSO    E  BSO   ST  LSO    T BESO    I  GST  GMA    I BESO    T  LSO   ST  BSO    E  OSO    W  HSO  FST    M  RVG  WIG  VSO  SSO  CSO )], # i
  [qw(  RCH  SMO   VM   FO LBSO   VP  VHO BUSO   DH   DK SWSO   HF   SE SPSO   VL  STI SBSO  RDO   LD SBSO  STI   VL SPSO   SE   HF SWSO   DK   DH BUSO  VHO   VP LBSO   FO   VM  SMO  LCH )], # j
  [qw(    P    P    P    P    P    P    P    P    P    P    P    P    P    P    P    P    P    P    P    P    P    P    P    P    P    P    P    P    P    P    P    P    P    P    P    P )], # k
  [qw(    _    _    _    _    _    _    _    _    _    _    _    _    _    _    _    _    _    _    _    _    _    _    _    _    _    _    _    _    _    _    _    _    _    _    _    _ )], # l
  [qw(    _    _    _    _    _    _    _    _    _    _    _    _    _    _    _    _    _    _    _    _    _    _    _    _    _    _    _    _    _    _    _    _    _    _    _    _ )], # m
  [qw(    _    _    _    _    _    _    _    _    _    _    _    _    _    _    _    _    _    _    _    _    _    _    _    _    _    _    _    _    _    _    _    _    _    _    _    _ )], # n
  [qw(    _    _    _    _    _    _    _    _    _    _    _    _    _    _    _    _    _    _    _    _    _    _    _    _    _    _    _    _    _    _    _    _    _    _    _    _ )], # o
  [qw(    _    _    _    _    _    _    _    _    _    _    _    _    _    _    _    _    _    _    _    _    _    _    _    _    _    _    _    _    _    _    _    _    _    _    _    _ )], # p
  [qw(    _    _    _    _    _    _    _    _    _    _    _    _    _    _    _    _    _    _    _    _    _    _    _    _    _    _    _    _    _    _    _    _    _    _    _    _ )], # q
  [qw(    _    _    _    _    _    _    _    _    _    _    _    _    _    _    _    _    _    _    _    _    _    _    _    _    _    _    _    _    _    _    _    _    _    _    _    _ )], # r
  [qw(    _    _    _    _    _    _    _    _    _    _    _    _    _    _    _    _    _    _    _    _    _    _    _    _    _    _    _    _    _    _    _    _    _    _    _    _ )], # s
  [qw(    _    _    _    _    _    _    _    _    _    _    _    _    _    _    _    _    _    _    _    _    _    _    _    _    _    _    _    _    _    _    _    _    _    _    _    _ )], # t
  [qw(    _    _    _    _    _    _    _    _    _    _    _    _    _    _    _    _    _    _    _    _    _    _    _    _    _    _    _    _    _    _    _    _    _    _    _    _ )], # u
  [qw(    _    _    _    _    _    _    _    _    _    _    _    _    _    _    _    _    _    _    _    _    _    _    _    _    _    _    _    _    _    _    _    _    _    _    _    _ )], # v
  [qw(    _    _    _    _    _    _    _    _    _    _    _    _    _    _    _    _    _    _    _    _    _    _    _    _    _    _    _    _    _    _    _    _    _    _    _    _ )], # w
  [qw(    _    _    _    _    _    _    _    _    _    _    _    _    _    _    _    _    _    _    _    _    _    _    _    _    _    _    _    _    _    _    _    _    _    _    _    _ )], # x
  [qw(    _    _    _    _    _    d    _    _    _    _   gb    _    _    _    d    _    _    _    _    _    _    d    _    _    _   gb    _    _    _    _    d    _    _    _    _    _ )], # y
  [qw(    p    p    p    p    p    p    p    p    p    p    p    p    p    p    p    p    p    p    p    p    p    p    p    p    p    p    p    p    p    p    p    p    p    p    p    p )], # z
  [qw(  lch  smo   vm   fo lbso   vp  vho buso   dh   dk swso   hf   se spso   vl  sti sbso   ld  rdo sbso  sti   vl spso   se   hf swso   dk   dh buso  vho   vp lbso   fo   vm  smo  rch )], # aa
  [qw(  cso  sso  vso  wig  rvg    m  fst  hso    w  oso    e  bso   st  lso    t beso    i  gma  gst    i beso    t  lso   st  bso    e  oso    w  hso  fst    m  rvg  wig  vso  sso  cso )], # ab
  [qw(  ech  bdr enba  hom  swo  cmo   cs  sww   bm   bt   oc   sf   bb   or  sqm  cse redr  lhk  feg redr  cse  sqm   or   bb   sf   oc   bt   bm  sww   cs  cmo  swo  hom enba  vsp  ech )], # ac
  [qw(  tch  vew  sox  don  flh  vib   ab   ew   lh  fco   om   cc  wba  eba   vs   vw   tf   rm   cm   tf   vw   vs  sba  nba   cc   om  fco   lh   ew   ab  vib  flh  don  sox  vew  tch )], # ad
  [qw(  wch  who  hdl   sm   ps  wbf   fl   fe  fdr  psn   fg   sc  bld   wg    f   ca   gt   lt   hm   ki   ph    f   wg  bld   sc   fg  psn  fdr   fe   fl  wbf   ps   sm  hdr  who  wch )], # ae
  [qw(  stc  cle    b    r   sw   fc   mf   vt   so  lst  cdr  cch ruch   rs   vo  gdr  gbd   dv  dsp  gbd  gdr   vo   rs ruch  cch  cdr  lst   so   vt   mf   fc   sw    r    b  cle  stc )], # af
  [qw(  sch   vb    n   pi  chg  pug   hg   og  cst  sbr  srb  gde   ln  cac   gs  vdr  wde   gg  vdr  wde    v   gs  cac   ln  gde  srb  sbr  cst   og   hg  pug  chg   pi    n   vb  sch )], # ag
  [qw(   gc  sdr rust   rw   bg   rg  lti  ldr   bo  wdr   fp   rb   ok   pc wadr fidr    c  kim  phm    c fidr wadr   pc   ok   rb   fp  wdr   bo  rdr  rti   rg   bg   rw rust  sdr   gc )], # ah
  [qw(   rc  wel   md   fs   co radr  fod   ms   rp  rse  sse   gd  rut  rub  bde   wr    s   nk  del    s  ggd   ns  rub  rut   gd  sse  rse   rp   ms  fod radr   co   fs   md  fel   rc )], # ai
  [qw(    l   wt   rr   wh  fid  mel  lng   bc   rh  fde  edr   cd  ftp   fk  rst   lg    g    k   cp    g  rig  rst   fk  ftp   wd  edr  fde   rh   bc  lng  mer  fid   wh   rr   ts    l )], # aj
);
# }}}

# {{{ Pieces
my $pieces = {
# {{{ Page 210
# {{{ 210
# King			steps 2 orthogonal or diagonal
# Crown Prince		steps 1 orthogonal or diagonal
# Gold General		steps 1 orthogonal or forward diagonal
# 
# Right General		steps 1 orthogonal or diagonal
# Left General		steps 1 orthogonal or diagonal
# Rear Standard		steps 2 diagonal, slides orthogonal
# 
# Free King		slides orthogonal or diagonal
# Free Tapir		steps 5 left orthogonal or right orthogonal, slides forward orthogonal or backward orthogonal or diagonal
# Wooden Dove		steps 2 orthogonal, slides diagonal
# 
# Wooden Dove, in addition to the normal diagonal slide, may leap 3 spaces (diagonally) then step 2 (diagonally).
# 
# 				-210-
# }}}
# {{{ Row 1
  # {{{ King
  k => {
    name => 'King',
    romaji => 'osho',
    neighborhood => [
      q(o o o),
      q( ooo ),
      q(oo^oo),
      q( ooo ),
      q(o o o) ] },
  # }}}
  # {{{ Crown Prince
  cp => {
    name => 'Crown Prince',
    romaji => 'taishi',
    promote => 'k',
    neighborhood => [
      q(     ),
      q( ooo ),
      q( o^o ),
      q( ooo ),
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
# }}}
# {{{ Row 2
  # {{{ Right General
  rig => {
    name => 'Right General',
    promote => 'ra',
    neighborhood => [
      q(     ),
      q( ooo ),
      q( o^o ),
      q( ooo ),
      q(     ) ] },
  # }}}
  # {{{ Left General
  lg => {
    name => 'Left General',
    promote => 'la',
    neighborhood => [
      q(     ),
      q( ooo ),
      q( o^o ),
      q( ooo ),
      q(     ) ] },
  # }}}
  # {{{ Rear Standard
  rst => {
    name => 'Rear Standard',
    promote => 'cst',
    neighborhood => [
      q(o   o),
      q( o|o ),
      q( -^- ),
      q( o|o ),
      q(o   o) ] },
  # }}}
# }}}
# {{{ Row 3
  # {{{ Free King
  fk => {
    name => 'Free King',
    romaji => "hon'o",
    promote => 'gg',
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
    promote => 'fk',
    neighborhood => [
      q(     ),
      q( \|/ ),
      q(o5^5o),
      q( /|\ ),
      q(     ) ] },
  # }}}
  # {{{ Wooden Dove
  wd => {
    name => 'Wooden Dove',
    neighborhood => [ [
        q(     ),
        q( \ / ),
        q(  ^  ),
        q( / \ ) ],
      [ q(o   o),
        q( 2 2 ),
        q(  ^  ),
        q( 2 2 ),
        q(o   o) ],
      [ q(x   x),
        q( 3 3 ),
        q(  ^  ),
        q( 3 3 ),
        q(x   x) ] ] },
  # }}}
# }}}
# }}}
# {{{ Page 211
# {{{ 211
# Earth Dragon		steps 1 forward diagonal or backward orthogonal, steps 2 forward orthogonal, slides backward diagonal
# Free Demon		steps 5 forward orthogonal or backward orthogonal, slides left orthogonal or right orthogonal or diagonal
# Running Horse		steps 1 backward orthogonal, leaps to the second backward diagonal, slides forward orthogonal or forward diagonal
# 
# Beast Cadet		steps 2 forward orthogonal or left orthogonal or right orthogonal or diagonal
# Long-Nosed Goblin	diagonal hook-move
# Mountain Eagle(Right)	steps 2 left backward diagonal, leaps 2 right diagonal, slides orthogonal or right diagonal or left forward diagonal
# 
# Mountain Eagle(Left)	steps 2 right backward diagonal, leaps 2 left diagonal, slides orthogonal or left diagonal or right forward diagonal
# Fire Demon		steps 2 forward orthogonal or backward orthogonal, slides left orthogonal or right orthogonal or diagonal
# Whale			slides foward orthogonal or backward orthogonal or backward diagonal
# 
# Running Rabbit		steps 1 backward orthogonal or backward diagonal, slides forward orthogonal or forward diagonal
# White Tiger		steps 2 forward orthogonal or backward orthgonal, slides left orthogonal or right orthogonal or left forward diagonal
# Turtle Snake		steps 1 orthogonal or left forward diagonal or right backward diagonal, slides right forward diagonal or left backward diagonal
# }}}
# {{{ Row 1
  # {{{ Earth Dragon
  edr => {
    name => 'Earth Dragon',
    promote => 'radr',
    neighborhood => [
      q(  o  ),
      q( ooo ),
      q(  ^  ),
      q( /o\ ),
      q(     ) ] },
  # }}}
  # {{{ Free Demon
  fde => {
    name => 'Free Demon',
    promote => 'fk',
    neighborhood => [
      q(  o  ),
      q( \5/ ),
      q( -^- ),
      q( /5\ ),
      q(  o  ) ] },
  # }}}
  # {{{ Running Horse
  rh => {
     name => 'Running Horse',
     promote => 'fde',
     neighborhood => [
       q(     ),
       q( \|/ ),
       q(  ^  ),
       q(  o  ),
       q(x   x) ] },
  # }}}
# }}}
# {{{ Row 2
  # {{{ Beast Cadet
  bc => {
    name => 'Beast Cadet',
    promote => 'bo',
    neighborhood => [
      q(o o o),
      q( ooo ),
      q(oo^oo),
      q( ooo ),
      q(o   o) ] },
  # }}}
  # {{{ Long-Nosed Goblin
  lng => {
    name => 'Long-Nosed Goblin',
    neighborhood => [
      q(X   X), # Hook mover
      q( \ / ),
      q(  ^  ),
      q( / \ ),
      q(X   X) ] },
  # }}}
  # {{{ Mountain Eagle (Right)
  mer => {
    name => 'Mountain Eagle (Right)',
    prommote => 'se',
    neighborhood => [
      q(    x),
      q( \|/ ),
      q( -^- ),
      q( o|\ ),
      q(o   x) ] },
  # }}}
# }}}
# {{{ Row 3
  # {{{ Mountain Eagle (Left)
  mel => {
    name => 'Mountain Eagle (Left)',
    prommote => 'se',
    neighborhood => [
      q(x    ),
      q( \|/ ),
      q( -^- ),
      q( /|o ),
      q(x   o) ] },
  # }}}
  # {{{ Fire Demon
  fid => {
    name => 'Fire Demon',
    promote => 'ffi',
    neighborhood => [
      q(  o  ),
      q( \o/ ),
      q( -^- ),
      q( /o\ ),
      q(  o  ) ] },
  # }}}
  # {{{ Whale
  wh => {
    name => 'Whale',
    romaji => 'keigei',
    promote => 'gw',
    neighborhood => [
      q(     ),
      q(  |  ),
      q(  ^  ),
      q( /|\ ),
      q(     ) ] },
  # }}}
# }}}
# {{{ Row 4
  # {{{ Running Rabbit
  rr => {
    name => 'Running Rabbit',
    promote => 'tf',
    neighborhood => [
      q(     ),
      q( \|/ ),
      q(  ^  ),
      q( ooo ),
      q(     ) ] },
  # }}}
# {{{ White Tiger
  wt => {
    name => 'White Tiger',
    promote => 'dt',
    neighborhood => [
      q(  o  ),
      q( \o  ),
      q( -^- ),
      q(  o  ),
      q(  o  ) ] },
  # }}}
  # {{{ Turtle Snake
  ts => {
    name => 'Turtle Snake',
    promote => 'dtu',
    neighborhood => [
      q(     ),
      q( oo/ ),
      q( o^o ),
      q( /oo ),
      q(     ) ] },
  # }}}
# }}}
# }}}
# {{{ Page 212
# {{{ 212
# Ceramic Dove		steps 2 orthogonal, slides diagonal
# Lance			slides forward orthogonal
# Reverse Chariot		slides forward orthogonal or backward orthogonal
# 
# Fragrant Elephant	steps 2 orthogonal or diagonal
# White Elephant		steps 2 orthogonal or diagonal
# Mountain Dove		steps 1 left orthogonal or right orthogonal or backward orthogonal, steps 5 forward diagonal
# 
# Flying Swallow		steps 1 backward orthogonal, slides forward diagonal
# Captive Officer		steps 2 forward orthogonal or left orthogonal or right orthogonal, steps 3 diagonal
# Rain Dragon		steps 1 forward orthogonal or forward diagonal, slides left orthogonal or right orthogonal or backward orthogonal or backward diagonal
# 
# Forest Demon		steps 3 forward orthogonal or left orthogonal or right orthogonal, slides backward orthogonal or forward diagonal
# Mountian Stag		steps 1 forward orthogonal, steps 2 left orthogonal or right orthogonal, steps 3 forward diagonal, step 4 backward orthogonal
# Running Pup		steps 1 left orthogonal or right orthogonal, slides forward orthogonal or backward orthogonal
# }}}
# {{{ Row 1
  # {{{ Ceramic Dove
  cd => {
    name => 'Ceramic Dove',
    neighborhood => [
      q(  o  ),
      q( \o/ ),
      q(oo^oo),
      q( /o\ ),
      q(  o  ) ] },
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
# }}}
# {{{ Row 2
  # {{{ Fragrant Elephant
  fel => {
    name => 'Fragrant Elephant',
    promote => 'ek',
    neighborhood => [
      q(o o o),
      q( ooo ),
      q(oo^oo),
      q( ooo ),
      q(o o o) ] },
  # }}}
  # {{{ White Elephant
  wel => {
    name => 'White Elephant',
    promote => 'ek',
    neighborhood => [
      q(o o o), # Yes, this is a copy of above
      q( ooo ),
      q(oo^oo),
      q( ooo ),
      q(o o o) ] },
  # }}}
  # {{{ Mountain Dove
  md => {
    name => 'Mountain Dove',
    promote => 'gd',
    neighborhood => [
      q(o   o),
      q( 5 5 ),
      q( o^o ),
      q(  o  ),
      q(     ) ] },
  # }}}
# }}}
# {{{ Row 3
  # {{{ Flying Swallow
  fs => {
    name => 'Flying Swallow',
    promote => 'r',
    neighborhood => [
      q(     ),
      q( \ / ),
      q(  ^  ),
      q(  o  ),
      q(     ) ] },
  # }}}
  # {{{ Captive Officer
  co => {
    name => 'Captive Officer',
    promote => 'cb',
    neighborhood => [
      q(o o o),
      q( 3o3 ),
      q(oo^oo),
      q( 3o3 ),
      q(o   o) ] },
  # }}}
  # {{{ Rain Dragon
  radr => {
    name => 'Rain Dragon',
    promote => 'gdr',
    neighborhood => [
      q(     ),
      q( ooo ),
      q( -^- ),
      q( /|\ ),
      q(     ) ] },
  # }}}
# }}}
# {{{ Row 4
  # {{{ Forest Demon
  fod => {
    name => 'Forest Demon',
    promote => 'thr',
    neighborhood => [
      q(  o  ),
      q( \3/ ),
      q(o3^3o),
      q(  |  ),
      q(     ) ] },
  # }}}
  # {{{ Mountain Stag
  ms => {
    name => 'Mountain Stag',
    promote => 'gs',
    neighborhood => [
      q(o   o),
      q( 3o3 ),
      q(oo^oo),
      q(  4  ),
      q(  o  ) ] },
  # }}}
  # {{{ Running Pup
  rp => {
    name => 'Running Pup',
    promote => 'fle',
    neighborhood => [
      q(     ),
      q(  |  ),
      q( o^o ),
      q(  |  ),
      q(     ) ] },
  # }}}
# }}}
# }}}
# {{{ Page 213
# {{{ 213
# Running Serpent		steps 1 left orthogonal or right orthogonal, slides forward orthogonal or backward orthogonal
# Side Serpent		steps 1 backward orthogonal, steps 3 forward orthogonal, slides left orthogonal or right orthogonal
# Great Dove		steps 3 orthogonal, slides diagonal
# 
# Running Tiger		steps 2 left orthogonal or right orthogonal, slides backward orthogonal or forward orthogonal
# Running Bear		steps 2 left orthogonal or right orthogonal, slides backward orthogonal or forward orthogonal
# Night Sword		steps 1 backward orthogonal or forward diagonal, steps 3 left orthogonal or right orthogonal
# 
# Buddhist Devil		steps 1 backward orthogonal or left orthogonal or right orthogonal, steps 3 forward diagonal
# Guardian of the Gods	steps 3 orthogonal
# Wrestler		steps 3 diagonal
# 
# Silver General		steps 1 forward orthogonal or diagonal
# Drunk Elephant		steps 1 forward orthogonal or left orthogonal or right orthogonal or diagonal
# Neighboring King	steps 1 forward orthogonal or left orthogonal or right orthogonal or diagonal
# }}}
# {{{ Row 1
  # {{{ Running Serpent
  rse => {
    name => 'Running Serpent',
    promote => 'fse',
    neighborhood => [
      q(     ),
      q(  |  ),
      q( o^o ),
      q(  |  ),
      q(     ) ] },
  # }}}
  # {{{ Side Serpent
  sse => {
    name => 'Side Serpent',
    promote => 'sh',
    neighborhood => [
      q(  o  ),
      q(  3  ),
      q( -^- ),
      q(  o  ),
      q(     ) ] },
  # }}}
  # {{{ Great Dove
  gd => {
    name => 'Great Dove',
    promote => 'wd',
    neighborhood => [
      q(  o  ),
      q( \3/ ),
      q(o3^3o),
      q( /3\ ),
      q(  o  ) ] },
  # }}}
# }}}
# {{{ Row 2
  # {{{ Running Tiger
  rut => {
    name => 'Running Tiger',
    promote => 'fti',
    neighborhood => [
      q(     ),
      q(  |  ),
      q(oo^oo),
      q(  |  ),
      q(     ) ] },
  # }}}
  # {{{ Running Bear
  rub => {
    name => 'Running Bear',
    promote => 'fbe',
    neighborhood => [
      q(     ), # Yes, this is a copy of above
      q(  |  ),
      q(oo^oo),
      q(  |  ),
      q(     ) ] },
  # }}}
  # {{{ Night Sword
  ns => {
    name => 'Night Sword',
    promote => 'ht',
    neighborhood => [
      q(     ),
      q( o o ),
      q(o3^3o),
      q(  o  ),
      q(     ) ] },
  # }}}
# }}}
# {{{ Row 3
  # {{{ Buddhist Devil
  bde => {
    name => 'Buddhist Devil',
    promote => 'ht',
    neighborhood => [
      q(o   o),
      q( 3 3 ),
      q( o^o ),
      q(  o  ),
      q(     ) ] },
  # }}}
  # {{{ Guardian of the Gods
  ggd => {
    name => 'Guardian of the Gods',
    promote => 'ht',
    neighborhood => [
      q(  o  ),
      q(  3  ),
      q(o3^3o),
      q(  3  ),
      q(  o  ) ] },
  # }}}
  # {{{ Wrestler
  wr => {
    name => 'Wrestler',
    promote => 'ht',
    neighborhood => [
      q(o   o),
      q( 3 3 ),
      q(  ^  ),
      q( 3 3 ),
      q(o   o) ] },
  # }}}
# }}}
# {{{ Row 4
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
  # {{{ Drunk Elephant
  del => {
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
  # {{{ Neighboring King
  nk => {
    name => 'Neighboring King',
    promote => 'fst',
    neighborhood => [
      q(     ),
      q( ooo ),
      q( o^o ),
      q( o o ),
      q(     ) ] },
  # }}}
# }}}
# }}}
# {{{ Page 214
# {{{ 214
# Gold Chariot		steps 1 diagonal, steps 2 left orthogonal or right orthogonal, slides forward orthogonal or backward orthogonal
# Side Dragon		slides forward orthogonal or left orthogonal or right orthogonal
# Running Stag		steps 2 backward orthogonal, slides left orthogonal or right orthogonal or forward diagonal
# 
# Running Wolf		steps 1 forward orthogonal, slides left orthogonal or right orthogonal or forward diagonal
# Bishop General		range jump diagonal(ranking noted at end of document)
# Rook General		range jump orthogonal(ranking noted at end of document)
# 
# Right Tiger		steps 1 right diagonal, slides left orthogonal or left diagonal
# Left Tiger		steps 1 left diagonal, slides right orthogonal or right diagonal
# Right Dragon		steps 2 right orthogonal, slides left orthogonal or left diagonal
# 
# Left Dragon		steps 2 left orthogonal, slides right orthogonal or right diagonal
# Beast Officer		steps 2 left orthogonal or right orthogonal, steps 3 forward orthogonal or diagonal
# Wind Dragon		steps 1 left backward diagonal, slides left orthogonal or right orthogonal or right backward diagonal or forward diagonal
# }}}
# {{{ Row 1
  # {{{ Gold Chariot
  gc => {
    name => 'Gold Chariot',
    promote => 'plc',
    neighborhood => [
      q(     ),
      q( o|o ),
      q(oo^oo),
      q( o|o ),
      q(     ) ] },
  # }}}
  # {{{ Side Dragon
  sdr => {
    name => 'Side Dragon',
    promote => 'rudr',
    neighborhood => [
      q(     ),
      q(  |  ),
      q( -^- ),
      q(     ),
      q(     ) ] },
  # }}}
  # {{{ Running Stag
  rust => {
    name => 'Running Stag',
    promote => 'frst',
    neighborhood => [
      q(     ),
      q( \ / ),
      q( -^- ),
      q(  o  ),
      q(  o  ) ] },
  # }}}
# }}}
# {{{ Row 2
  # {{{ Running Wolf
  rw => {
    name => 'Running Wolf',
    promote => 'fwo',
    neighborhood => [
      q(     ),
      q( \o/ ),
      q( -^- ),
      q(     ),
      q(     ) ] },
  # }}}
  # {{{ Bishop General
  bg => {
    name => 'Bishop General',
    promote => 'rde',
    neighborhood => [
      q(\   /), # Jump
      q( \ / ),
      q(  ^  ),
      q( / \ ),
      q(/   \\) ] },
  # }}}
  # {{{ Rook General
  rg => {
    name => 'Rook General',
    promote => 'fcr',
    neighborhood => [
      q(  |  ),
      q(  |  ),
      q(--^--),
      q(  |  ),
      q(  |  ) ] },
  # }}}
# }}}
# {{{ Row 3
  # {{{ Right Tiger
  rti => {
    name => 'Right Tiger',
    promote => 'wt',
    neighborhood => [
      q(     ),
      q( \ o ),
      q( -^  ),
      q( / o ),
      q(     ) ] },
  # }}}
  # {{{ Left Tiger
  lti => {
    name => 'Left Tiger',
    promote => 'ts',
    neighborhood => [
      q(     ),
      q( o / ),
      q(  ^- ),
      q( o \ ),
      q(     ) ] },
  # }}}
  # {{{ Right Dragon
  rdr => {
    name => 'Right Dragon',
    promote => 'bdr',
    neighborhood => [
      q(     ),
      q( \   ),
      q( -^oo),
      q( /   ),
      q(     ) ] },
  # }}}
# }}}
# {{{ Row 4
  # {{{ Left Dragon
  ldr => {
    name => 'Left Dragon',
    promote => 'vsp',
    neighborhood => [
      q(     ),
      q(   / ),
      q(oo^- ),
      q(   \ ),
      q(     ) ] },
  # }}}
  # {{{ Beast Officer
  bo => {
    name => 'Beast Officer',
    promote => 'bbd',
    neighborhood => [
      q(o o o),
      q( 333 ),
      q( o^oo),
      q( 3 3 ),
      q(o   o) ] },
  # }}}
  # {{{ Wind Dragon
  wdr => {
    name => 'Wind Dragon',
    promote => 'frdr',
    neighborhood => [
      q(     ),
      q( \ / ),
      q( -^- ),
      q( o \ ),
      q(     ) ] },
  # }}}
# }}}
# }}}
# {{{ Page 215
# {{{ 215
# Free Pup		steps 1 backward diagonal, steps 2 left orthogonal or right orthogonal, slides backward orthogonal or forward orthogonal or forward diagonal
# Rushing Bird		steps 1 left orthogonal or right orthogonal or diagonal, steps 2 forward orthogonal
# Old Kite Hawk		steps 1 left orthogonal or right orthogonal, steps 2 diagonal
# 
# Peacock			steps 2 backward diagonal, forward diagonal hook-move
# Water Dragon		steps 2 forward diagonal, steps 4 backward diagonal, slides orthogonal
# Fire Dragon		steps 2 backward diagonal, steps 4 forward diagonal, slides orthogonal
# 
# Copper General		steps 1 backward orthogonal or forward orthogonal or forward diagonal
# Phoenix Master		steps 3 left orthogonal or right orthogonal or forward diagonal, slides backward orthogonal or forward orthogonal or backward diagonal, leaps 3 then slides forward diagonal
# Kylin Master		steps 3 backward orthogonal or forward orthogonal or left orthogonal or right orthogonal , slides diagonal, leaps 3 then slides backward orthogonal or forward orthogonal
# 
# Silver Chariot		steps 1 backward diagonal, steps 2 forward diagonal, slides backward orthogonal or forward orthogonal
# Vertical Bear		steps 1 backward orthogonal, steps 2 left orthogonal or right orthogonal, slides forward orthogonal
# Knight			leaps 1 forward orthogonal then 1 forward diagonal
# }}}
# {{{ Row 1
  # {{{ Free Pup
  fp => {
    name => 'Free Pup',
    promote => 'fdo',
    neighborhood => [
      q(     ),
      q( \|/ ),
      q(oo^oo),
      q( o|o ),
      q(     ) ] },
  # }}}
  # {{{ Rushing Bird
  rb => {
    name => 'Rushing Bird',
    promote => 'fde',
    neighborhood => [
      q(  o  ),
      q( ooo ),
      q( o^o ),
      q( o o ),
      q(     ) ] },
  # }}}
  # {{{ Old Kite Hawk
  ok => {
    name => 'Old Kite Hawk',
    promote => 'lng',
    neighborhood => [
      q(o   o),
      q( o o ),
      q( o^o ),
      q( o o ),
      q(o   o) ] },
  # }}}
# }}}
# {{{ Row 2
  # {{{ Peacock
  pc => {
    name => 'Peacock',
    promote => 'lng',
    neighborhood => [
      q(X   X),
      q( \ / ),
      q(  ^  ),
      q( o o ),
      q(o   o) ] },
  # }}}
  # {{{ Water Dragon
  wadr => {
    name => 'Water Dragon',
    promote => 'phm',
    neighborhood => [
      q(o   o),
      q( o|o ),
      q( -^- ),
      q( 4|4 ),
      q(o   o) ] },
  # }}}
  # {{{ Fire Dragon
  fidr => {
    name => 'Fire Dragon',
    promote => 'kim',
    neighborhood => [
      q(o   o),
      q( 4|4 ),
      q( -^- ),
      q( o|o ),
      q(o   o) ] },
  # }}}
# }}}
# {{{ Row 3
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
  # {{{ Phoenix Master
  phm => {
    name => 'Phoenix Master',
    neighborhood => [ [
        q(     ),
        q( \|/ ),
        q(  ^  ),
        q( /|\ ),
        q(     ) ],
      [ q(x   x),
        q( 3 3 ),
        q(o3^3o),
        q(     ),
        q(     ) ] ] },
  # }}}
  # {{{ Kirin Master
  kim => {
    name => 'Kirin Master',
    neighborhood => [ [
        q(  x  ),
        q(  3  ),
        q(o3^3o),
        q(  3  ),
        q(  x  ) ],
      [
        q(     ),
        q( \|/ ),
        q(  ^  ),
        q( /|\ ),
        q(     ) ] ] },
  # }}}
# }}}
# {{{ Row 4
  # {{{ Silver Chariot
  sch => {
    name => 'Silver Chariot',
    promote => 'gw',
    neighborhood => [
      q(o   o),
      q( o|o ),
      q(  ^  ),
      q( o|o ),
      q(     ) ] },
  # }}}
  # {{{ Vertical Bear
  vb => {
    name => 'Vertical Bear',
    promote => 'fbe',
    neighborhood => [
      q(     ),
      q(  |  ),
      q(oo^oo),
      q(  o  ),
      q(     ) ] },
  # }}} 
  # {{{ Knight
  n => {
    name => 'Knight',
    romaji => 'keima',
    promote => 'sso',
    neighborhood => [
      q( x x ),
      q(     ),
      q(  ^  ),
      q(     ),
      q(     ) ] },
  # }}}
# }}}
# }}}
# {{{ Page 216
# {{{ 216
# Pig General		steps 2 backward orthogonal, steps 4 forward diagonal
# Chicken General		steps 1 backward diagonal, steps 4 forward orthogonal
# Pup General		steps 1 backward diagonal, steps 4 forward orthogonal
# 
# Horse General		steps 1 backward orthogonal or forward diagonal, steps 3 forward orthogonal
# Ox General		steps 1 backward orthogonal or forward diagonal, steps 3 forward orthogonal
# Center Standard		steps 3 diagonal, slides orthogonal
# 
# Side Boar		steps 1 backward orthogonal or forward orthogonal or diagonal, slides left orthogonal or right orthogonal
# Silver Rabbit		steps 2 forward diagonal, slides backward diagonal
# Golden Deer		steps 2 backward diagonal, slides forward diagonal
# 
# Lion			2-space Lion move
# Captive Cadet		steps 3 left orthogonal or right orthogonal or forward orthogonal or diagonal
# Great Stag		steps 2 backward diagonal, leaps 2 forward diagonal, slides orthogonal
# 
# 	The Lion moves similar to its counterpart in Chu Shogi.
# }}}
# {{{ Row 1
  # {{{ Pig General
  pi => {
    name => 'Pig General',
    promote => 'fpg',
    neighborhood => [
      q(o   o),
      q( 4 4 ),
      q(  ^  ),
      q(  o  ),
      q(  o  ) ] },
  # }}}
  # {{{ Chicken General
  chg => {
    name => 'Chicken General',
    promote => 'fch',
    neighborhood => [
      q(  o  ),
      q(  4  ),
      q(  ^  ),
      q( o o ),
      q(     ) ] },
  # }}}
  # {{{ Pup General
  pug => {
    name => 'Pup General',
    promote => 'fp',
    neighborhood => [
      q(  o  ), # Yes, duplicate
      q(  4  ),
      q(  ^  ),
      q( o o ),
      q(     ) ] },
  # }}}
# }}}
# {{{ Row 2
  # {{{ Horse General
  hg => {
    name => 'Horse General',
    promote => 'fh',
    neighborhood => [
      q(  o  ),
      q( o3o ),
      q(  ^  ),
      q(  o  ),
      q(     ) ] },
  # }}}
  # {{{ Ox General
  og => {
    name => 'Ox General',
    promote => 'fro',
    neighborhood => [
      q(  o  ), # Another dupe
      q( o3o ),
      q(  ^  ),
      q(  o  ),
      q(     ) ] },
  # }}}
  # {{{ Center Standard
  cst => {
    name => 'Center Standard',
    promote => 'fst',
    neighborhood => [
      q(o   o),
      q( 3|3 ),
      q( -^- ),
      q( 3|3 ),
      q(o   o) ] },
  # }}}
# }}}
# {{{ Row 3
  # {{{ Side Boar
  sbr => {
    name => 'Side Boar',
    promote => 'fbo',
    neighborhood => [
      q(     ),
      q( ooo ),
      q( -^- ),
      q( ooo ),
      q(     ) ] },
  # }}}
  # {{{ Silver Rabbit
  srb => {
    name => 'Silver Rabbit',
    promote => 'wh',
    neighborhood => [
      q(o   o),
      q( o o ),
      q(  ^  ),
      q( / \ ),
      q(     ) ] },
  # }}}
  # {{{ Golden Deer
  gde => {
    name => 'Golden Deer',
    promote => 'who',
    neighborhood => [
      q(     ),
      q( \ / ),
      q(  ^  ),
      q( o o ),
      q(o   o) ] },
  # }}}
# }}}
# {{{ Row 4
  # {{{ Lion
  ln => {
    name => 'Lion',
    romaji => 'shishi',
    promote => 'ff',
    neighborhood => [
      q(22222),
      q(21112),
      q(21^12),
      q(21112),
      q(22222) ] },
  # }}}
  # {{{ Captive Cadet
  cac => {
    name => 'Captive Cadet',
    promote => 'co',
    neighborhood => [
      q(o o o),
      q( 333 ),
      q(o3^3o),
      q( 3 3 ),
      q(o   o) ] },
  # }}}
  # {{{ Great Stag
  gs => {
    name => 'Great Stag',
    promote => 'frst',
    neighborhood => [
      q(x   x),
      q(  |  ),
      q( -^- ),
      q( o|o ),
      q(o   o) ] },
  # }}}
# }}}
# }}}
# {{{ Page 217
# {{{ 217
# Violent Dragon		steps 2 orthogonal, range jump diagonal(ranking noted at end of document)
# Woodland Demon		steps 2 left orthogonal or right orthogonal or backward diagonal, slides backward orthogonal or forward orthogonal or forward diagonal
# Vice General		leaps 2 orthogonal, range jump diagonal(ranking noted at end of document)
# 
# Great General		range jump orthogonal or diagonal(ranking noted at end of document)
# Stone Chariot		steps 1 forward diagonal, steps 2 left orthogonal or right orthogonal, slides backward orthogonal or forward orthogonal
# Cloud Eagle		steps 1 left orthogonal or right orthogonal, steps 3 forward diagonal, slides backward orthogonal or forward orthogonal
# 
# Bishop			slides diagonal
# Rook			slide orthogonal
# Side Wolf		steps 1 left forward diagonal or right backward diagonal, slides left orthogonal or right orthogonal
# 
# Flying Cat		steps 1 backward orthogonal or backward diagonal, leaps 3 left orthogonal or right orthogonal or forward orthogonal or forward diagonal
# Mountain Falcon		steps 2 forward orthogonal or backward diagonal, slides backward orthogonal or left orthogonal or right orthogonal or forward diagonal, leaps 2 then slides forward orthogonal
# Vertical Tiger		steps 2 backward orthogonal, slides forward orthogonal
# }}}
# {{{ Row 1
  # {{{ Violent Dragon
  vdr => {
    name => 'Violent Dragon',
    promote => 'gdr',
    neighborhood => [
      q(\ o /),
      q( \o/ ),
      q(oo^oo),
      q( /o\ ),
      q(/ o \\) ] },
  # }}}
  # {{{ Woodland Demon
  wde => {
    name => 'Woodland Demon',
    promote => 'rph',
    neighborhood => [
      q(     ),
      q( \|/ ),
      q(oo^oo),
      q( o|o ),
      q(o | o) ] },
  # }}}
  # {{{ Vice General
  v => {
    name => 'Vice General',
    promote => 'gg',
    neighborhood => [
      q(\ x /),
      q( \ / ),
      q(x ^ x),
      q( / \ ),
      q(/ x \\) ] },
  # }}}
# }}}
# {{{ Row 2
  # {{{ Great General
  gg => {
    name => 'Great General',
    neighborhood => [
      q(\ | /),
      q( \|/ ),
      q(--^--),
      q( /|\ ),
      q(/ | \\) ] },
  # }}}
  # {{{ Stone Chariot
  stc => {
    name => 'Stone Chariot',
    promote => 'whe',
    neighborhood => [
      q(     ),
      q( o|o ),
      q(oo^oo),
      q(  |  ),
      q(     ) ] },
  # }}}
  # {{{ Cloud Eagle
  cle => {
    name => 'Cloud Eagle',
    promote => 'seg',
    neighborhood => [
      q(o   o),
      q( 3|3 ),
      q( o^o ),
      q(  |  ),
      q(     ) ] },
  # }}}
# }}}
# {{{ Row 3
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
  # {{{ Side Wolf
  sw => {
    name => 'Side Wolf',
    promote => 'fwo',
    neighborhood => [
      q(     ),
      q( o   ),
      q( -^- ),
      q(   o ),
      q(     ) ] },
  # }}}
# }}}
# {{{ Row 4
  # {{{ Flying Cat
  fc => {
    name => 'Flying Cat',
    promote => 'r',
    neighborhood => [
      q(x x x),
      q( 333 ),
      q(x3^3x),
      q( ooo ),
      q(     ) ] },
  # }}}
  # {{{ Mountain Falcon
  mf => {
    name => 'Mountain Falcon',
    promote => 'hf',
    neighborhood => [
        q(  x  ),
        q( \|/ ),
        q( -^- ),
        q( o|o ),
        q(o   o) ] },
  # }}}
  # {{{ Vertical Tiger
  vt => {
    name => 'Vertical Tiger',
    promote => 'fti',
    neighborhood => [
      q(     ),
      q(  |  ),
      q(  ^  ),
      q(  o  ),
      q(  o  ) ] },
  # }}}
# }}}
# }}}
# {{{ Page 218
# {{{ 218
# Soldier			slides orthogonal
# Little Standard		steps 1 backward diagonal, steps 2 forward diagonal, slides orthogonal
# Cloud Dragon		steps 1 left orthogonal or right orthogonal or forward orthogonal, slides diagonal or backward orthogonal
# 
# Copper Chariot		steps 3 forward diagonal, slides backward orthogonal or forward orthogonal
# Running Chariot		slides orthogonal
# Ramshead Soldier	steps 1 backward orthogonal, slides forward diagonal
# 
# Violent Ox		steps 1 backward orthogonal or forward orthogonal, slides forward diagonal
# Great Dragon		steps 3 backward orthogonal or forward orthogonal, slides diagonal
# Golden Bird		steps 3 left orthogonal or right orthogonal or backward diagonal, slides backward orthogonal or forward orthogonal, hash-marked slides forward diagonal
# 
# Dark Spirit		steps 1 orthogonal or backward diagonal or right forward diagonal
# Deva			steps 1 orthogonal or backward diagonal or left forward diagonal
# Wood Chariot		steps 1 left forward diagonal or right backward diagonal, slides backward orthogonal or forward orthogonal
# 
# 				-218-
# }}}
# {{{ Row 1
  # {{{ Soldier
  so => {
    name => 'Soldier',
    promote => 'cav',
    neighborhood => [
      q(     ),
      q(  |  ),
      q( -^- ),
      q(  |  ),
      q(     ) ] },
  # }}}
  # {{{ Little Standard
  lst => {
    name => 'Little Standard',
    promote => 'rst',
    neighborhood => [
      q(o   o),
      q( o|o ),
      q( -^- ),
      q( o|o ),
      q(  |  ) ] },
  # }}}
  # {{{ Cloud Dragon
  cdr => {
    name => 'Cloud Dragon',
    promote => 'gdr',
    neighborhood => [
      q(     ),
      q( \o/ ),
      q( o^o ),
      q( /|\ ),
      q(     ) ] },
  # }}}
  # }}}
# {{{ Row 2
  # {{{ Copper Chariot
  cch => {
    name => 'Copper Chariot',
    promote => 'ce',
    neighborhood => [
      q(o   o),
      q( 3|3 ),
      q(  ^  ),
      q(  |  ),
      q(     ) ] },
  # }}}
  # {{{ Running Chariot
  ruch => {
    name => 'Running Chariot',
    promote => 'bch',
    neighborhood => [
      q(     ),
      q(  |  ),
      q( -^- ),
      q(  |  ),
      q(     ) ] },
  # }}}
  # {{{ Ramshead Soldier
  rs => {
    name => 'Ramshead Soldier',
    promote => 'tso',
    neighborhood => [
      q(     ),
      q( \ / ),
      q(  ^  ),
      q(  o  ),
      q(     ) ] },
  # }}}
# }}}
# {{{ Row 3
  # {{{ Violent Ox
  vo => {
    name => 'Violent Ox',
    romaji => 'mogyu',
    promote => 'fo',
    neighborhood => [
      q(     ),
      q( \o/ ),
      q(  ^  ),
      q(  o  ),
      q(     ) ] },
  # }}}
  # {{{ Great Dragon
  gdr => {
    name => 'Great Dragon',
    promote => 'adr',
    neighborhood => [
      q(  o  ),
      q( \3/ ),
      q(  ^  ),
      q( /3\ ),
      q(  o  ) ] },
  # }}}
  # {{{ Golden Bird
  gbd => {
    name => 'Golden Bird',
    promote => 'fbd',
    neighborhood => [
      q(\   /), # XXX 'X' is whatever notation the hash lines correspond to.
      q( X|X ),
      q(o3^3o),
      q( 3|3 ),
      q(o   o) ] },
  # }}}
# }}}
# {{{ Row 4
  # {{{ Dark Spirit
  dsp => {
    name => 'Dark Spirit',
    promote => 'bsp',
    neighborhood => [
      q(     ),
      q(  oo ),
      q( o^o ),
      q( ooo ),
      q(     ) ] },
  # }}}
  # {{{ Deva
  dv => {
    name => 'Deva',
    promote => 'tk',
    neighborhood => [
      q(     ),
      q( oo  ),
      q( o^o ),
      q( ooo ),
      q(     ) ] },
  # }}}
  # {{{ Wood Chariot
  wch => {
    name => 'Wood Chariot',
    promote => 'wst',
    neighborhood => [
      q(     ),
      q( o|  ),
      q(  ^  ),
      q(  |o ),
      q(     ) ] },
  # }}}
# }}}
# }}}
# {{{ Page 219
# {{{ 219
# White Horse		slides backward orthogonal or forward orthogonal or forward diagonal
# Howling Dog(Right)	steps 1 backward orthogonal, slides forward orthogonal
# Howling Dog(Left)	steps 1 backward orthogonal, slides forward orthogonal
# 
# Side Mover		steps 1 backward orthogonal or forward orthogonal, slide left orthogonal or right orthogonal
# Prancing Stag		steps 1 backward orthogonal or forward orthogonal or forward diagonal, steps 2 left orthogonal or right orthogonal
# Water Buffalo		steps 2 backward orthogonal or forward orthogonal, slides left orthogonal or right orthogonal or diagonal
# 
# Ferocious Leopard	steps 1 backward orthogonal or forward orthogonal or diagonal
# Fierce Eagle		steps 1 left orthogonal or right orthogonal or forward orthogonal, steps 2 diagonal
# Flying Dragon		leaps 2 diagonal
# 
# Poisonous Snake		steps 1 backward orthogonal or forward diagonal, steps 2 left orthogonal or right orthogonal or forward orthogonal
# Flying Goose		steps 1 backward orthogonal or forward orthogonal or forward diagonal
# Strutting Crow		steps 1 backward diagonal or forward orthogonal
# 
# 				-219-
# }}}
# {{{ Row 1
  # {{{ White Horse
  who => {
    name => 'White Horse',
    romaji => 'hakku',
    promote => 'gho',
    neighborhood => [
      q(     ),
      q( \|/ ),
      q(  ^  ),
      q(  |  ),
      q(     ) ] },
  # }}}
  # {{{ Howling Dog (Right)
  hdr => {
    name => 'Howling Dog (Right)',
    promote => 'rdo',
    neighborhood => [
      q(     ),
      q(  |  ),
      q(  ^  ),
      q(  o  ),
      q(     ) ] },
  # }}} 
  # {{{ Howling Dog (Left)
  hdl => {
    name => 'Howling Dog (Left)',
    promote => 'ldo',
    neighborhood => [
      q(     ),
      q(  |  ),
      q(  ^  ),
      q(  o  ),
      q(     ) ] },
  # }}}
# }}}
# {{{ Row 2
  # {{{ Side Mover
  sm => {
    name => 'Side Mover',
    romaji => 'ogyo',
    promote => 'fbo',
    neighborhood => [
      q(     ),
      q(  o  ),
      q( -^- ),
      q(  o  ),
      q(     ) ] },
  # }}}
  # {{{ Prancing Stag
  ps => {
    name => 'Prancing Stag',
    promote => 'sqm',
    neighborhood => [
      q(     ),
      q( ooo ),
      q(oo^oo),
      q(  o  ),
      q(     ) ] },
  # }}}
  # {{{ Water Buffalo
  wbf => {
    name => 'Water Buffalo',
    promote => 'gtp',
    neighborhood => [
      q(  o  ),
      q( \o/ ),
      q( -^- ),
      q( /o\ ),
      q(  o  ) ] },
  # }}}
# }}}
# {{{ Row 3
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
  # {{{ Fierce Eagle
  fe => {
    name => 'Fierce Eagle',
    promote => 'se',
    neighborhood => [
      q(o   o),
      q( ooo ),
      q( o^o ),
      q( o o ),
      q(o   o) ] },
  # }}}
  # {{{ Flying Dragon
  fdr => {
    name => 'Flying Dragon',
    romaji => 'hiryu',
    promote => 'dk',
    neighborhood => [
      q(x   x),
      q(     ),
      q(  ^  ),
      q(     ),
      q(x   x) ] },
  # }}}
# }}}
# {{{ Row 4
  # {{{ Poisonous Snake
  psn => {
    name => 'Poisonous Snake',
    promote => 'hm',
    neighborhood => [
      q(  o  ),
      q( ooo ),
      q(oo^oo),
      q(  o  ),
      q(     ) ] },
  # }}}
  # {{{ Flying Goose
  fg => {
    name => 'Flying Goose',
    promote => 'dk',
    neighborhood => [
      q(     ),
      q( ooo ),
      q(  ^  ),
      q(  o  ),
      q(     ) ] },
  # }}}
  # {{{ Strutting Crow
  sc => {
    name => 'Strutting Crow',
    promote => 'ffa',
    neighborhood => [
      q(     ),
      q(  o  ),
      q(  ^  ),
      q( o o ),
      q(     ) ] },
  # }}}
# }}}
# }}}
# {{{ Page 220
# {{{ 220
# Blind Dog		steps 1 backward orthogonal or left orthogonal or right orthogonal or forward diagonal
# Water General		steps 1 backward orthogonal or forward orthogonal, steps 3 forward diagonal
# Fire General		steps 1 forward diagonal, steps 3 backward orthogonal or forward orthogonal
# 
# Phoenix			steps 1 orthogonal, leaps 2 diagonal
# Kylin			steps 1 backward orthogonal or forward orthogonal or diagonal, leaps 2 left orthogonal or right orthogonal
# Hook Mover		orthogonal hook-move
# 
# Little Turtle		steps 2 left orthogonal or right orthogonal, leaps 2 backward orthogonal or forward orthogonal, slides backward orthogonal or forward orthogonal or diagonal
# Great Turtle		steps 3 left orthogonal or right orthogonal, leaps 3 bakcward orthogonal or forward orthogonal, slides backward orthogonal or forward orthogonal or diagonal
# Capricorn		diagonal hook-move
# 
# Tile Chariot		steps 1 left backward diagonal or right forward diagonal, slides backward orthogonal or forward orthogonal
# Vertical Wolf		steps 1 left orthogonal or right orthogonal, steps 3 backward orthogonal, slides forward orthogonal
# Side Ox			steps 1 left backward diagonal or right forward diagonal, slides left orthogonal or right orthogonal
# 
# 				-220-
# }}}
# {{{ Row 1
  # {{{ Blind Dog
  bld => {
    name => 'Blind Dog',
    romaji => 'moken',
    promote => 'vs',
    neighborhood => [
      q(     ),
      q( o o ),
      q( o^o ),
      q(  o  ),
      q(     ) ] },
  # }}}
  # {{{ Water General
  wg => {
    name => 'Water General',
    promote => 'v',
    neighborhood => [
      q(o   o),
      q( 3o3 ),
      q(  ^  ),
      q(  o  ),
      q(     ) ] },
  # }}}
  # {{{ Fire General
  f => {
    name => 'Fire General',
    promote => 'gg',
    neighborhood => [
      q(  o  ),
      q( o3o ),
      q(  ^  ),
      q(  3  ),
      q(  o  ) ] },
  # }}}
# }}}
# {{{ Row 2
  # {{{ Phoenix
  ph => {
    name => 'Phoenix',
    romaji => 'hoo',
    promote => 'gbd',
    neighborhood => [
      q(x   x),
      q(  o  ),
      q( o^o ),
      q(  o  ),
      q(x   x) ] },
  # }}}
  # {{{ Kirin
  ki => {
    name => 'Kirin',
    romaji => 'kylin',
    promote => 'gbd',
    neighborhood => [
      q(     ),
      q( ooo ),
      q(x ^ x),
      q( ooo ),
      q(     ) ] },
  # }}}
  # {{{ Hook Mover
  hm => {
    name => 'Hook Mover',
    neighborhood => [
      q(  +  ), # Horizontal hook mover
      q(  |  ),
      q(+-^-+),
      q(  |  ),
      q(  +  ) ] },
  # }}}
# }}}
# {{{ Row 3
  # {{{ Little Turtle
  lt => {
    name => 'Little Turtle',
    promote => 'tt',
    neighborhood => [
      q(  x  ),
      q( \|/ ),
      q(o2^2o),
      q( /|\ ),
      q(  x  ) ] },
  # }}}
  # {{{ Great Turtle
  gt => {
    name => 'Great Turtle',
    promote => 'spt',
    neighborhood => [ [
      q(     ),
      q( \|/ ),
      q(  ^  ),
      q( /|\ ),
      q(     ) ],
    [ q(  x  ),
      q(  3  ),
      q(o3^3o),
      q(  3  ),
      q(  x  ) ] ] },
  # }}}
  # {{{ Capricorn
  ca => {
    name => 'Capricorn',
    promote => 'hm',
    neighborhood => [
      q(X   X), # YA hook mover
      q( \ / ),
      q(  ^  ),
      q( / \ ),
      q(X   X) ] },
  # }}}
# }}}
# {{{ Row 4
  # {{{ Tile Chariot
  tch => {
    name => 'Tile Chariot',
    promote => 'rtl',
    neighborhood => [
      q(     ),
      q(  |o ),
      q(  ^  ),
      q( o|  ),
      q(     ) ] },
  # }}}
  # {{{ Vertical Wolf
  vew => {
    name => 'Vertical Wolf',
    promote => 'rw',
    neighborhood => [
      q(     ),
      q(  |  ),
      q( o^o ),
      q(  3  ),
      q(  o  ) ] },
  # }}}
  # {{{ Side Ox
  sox => {
    name => 'Side Ox',
    promote => 'fo',
    neighborhood => [
      q(     ),
      q(   o ),
      q( -^- ),
      q( o   ),
      q(     ) ] },
  # }}}
# }}}
# }}}
# {{{ Page 221
# {{{ 221
# Donkey			steps 2 orthogonal
# Flying Horse		steps 2 diagonal
# Angry Boar		steps 1 left orthogonal or right orthogonal or forward orthogonal, steps 2 forward diagonal
# 
# Violent Bear		steps 1 left orthogonal or right orthogonal or diagonal
# Evil Wolf		steps 1 left orthogonal or right orthogonal or forward orthogonal or forward diagonal
# Liberated Horse		steps 1 forward diagonal, steps 2 backward orthogonal, slides forward orthogonal
# 
# Flying Cock		steps 1 left orthogonal or right orthogonal or forward diagonal
# Old Monkey		steps 1 backward orthogonal or diagonal
# Chinese Cock		steps 1 backward orthogonal or left orthogonal or right orthogonal or forward diagonal
# 
# Northern Barbarian	steps 1 backward orthogonal or forward orthogonal or forward diagonal, steps 2 left orthogonal or right orthogonal
# Southern Barbarian	steps 1 backward orthogonal or forward orthogonal or forward diagonal, steps 2 left orthogonal or right orthogonal
# Western Barbarian	steps 1 left orthogonal or right orthogonal or forward diagonal, steps 2 backward orthogonal or forward orthogonal
# 
# 				-221-
# }}}
# {{{ Row 1
  # {{{ Donkey
  don => {
    name => 'Donkey',
    promote => 'cd',
    neighborhood => [
      q(  o  ),
      q(  o  ),
      q(oo^oo),
      q(  o  ),
      q(  o  ) ] },
  # }}}
  # {{{ Flying Horse
  flh => {
    name => 'Flying Horse',
    promote => 'fk',
    neighborhood => [
      q(o   o),
      q( o o ),
      q(  ^  ),
      q( o o ),
      q(o   o) ] },
  # }}}
  # {{{ Angry Boar
  ab => {
    name => 'Angry Boar',
    promote => 'fbo',
    neighborhood => [
      q(o   o),
      q( ooo ),
      q( o^o ),
      q(     ),
      q(     ) ] },
  # }}}
# }}}
# {{{ Row 2
  # {{{ Violent Bear
  vib => {
    name => 'Violent Bear',
    promote => 'gb',
    neighborhood => [
      q(     ),
      q( o o ),
      q( o^o ),
      q( o o ),
      q(     ) ] },
  # }}}
  # {{{ Evil Wolf
  ew => {
    name => 'Evil Wolf',
    romaji => 'akuro',
    promote => 'vwo',
    neighborhood => [
      q(     ),
      q( ooo ),
      q( o^o ),
      q(     ),
      q(     ) ] },
  # }}}
  # {{{ Liberated Horse
  lh => {
    name => 'Liberated Horse',
    promote => 'hh',
    neighborhood => [
      q(     ), # Horizontal hook mover # XXX ?
      q( o|o ),
      q(  ^  ),
      q(  o  ),
      q(  o  ) ] },
  # }}}
# }}}
# {{{ Row 3
  # {{{ Flying Cock
  fco => {
    name => 'Flying Cock',
    promote => 'rf',
    neighborhood => [
      q(     ),
      q( o o ),
      q( o^o ),
      q(     ),
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
# }}}
# {{{ Row 4
  # {{{ Northern Barbarian
  nba => {
    name => 'Northern Barbarian',
    promote => 'wd',
    neighborhood => [
      q(     ),
      q( ooo ),
      q(oo^oo),
      q(  o  ),
      q(     ) ] },
  # }}}
  # {{{ Southern Barbarian
  sba => {
    name => 'Southern Barbarian',
    promote => 'gbd',
    neighborhood => [
      q(     ),
      q( ooo ),
      q(oo^oo),
      q(  o  ),
      q(     ) ] },
  # }}}
  # {{{ Western Barbarian
  wba => {
    name => 'Western Barbarian',
    promote => 'ld',
    neighborhood => [
      q(  o  ),
      q( ooo ),
      q( o^o ),
      q(  o  ),
      q(  o  ) ] },
  # }}}
# }}}
# }}}
# {{{ Page 222
# {{{ 222
# Eastern Barbarian	steps 1 left orthogonal or right orthogonal or forward diagonal, steps 2 backward orthogonal or forward orthogonal
# Violent Stag		steps 1 forward orthogonal or diagonal
# Violent Wolf		steps 1 orthogonal or forward diagonal
# 
# Treacherous Fox		slides or leaps 2 or 3 then slides backward orthogonal or forward orthogonal or diagonal
# Center Master		steps 3 left orthogonal or right orthogonal or backward diagonal, slides or leaps 2 and slides backward orthogonal or forward orthogonal or forward diagonal
# Roc Master		steps 5 left orthogonal or right orthogonal or backward diagonal, slides backward orthogonal or forward orthogonal, slides or leaps 3 and slides forward diagonal
# 
# Earth Chariot		steps 1 left orthogonal or right orthogonal, slides backward orthogonal or forward orthogonal
# Vermillion Sparrow	steps 1 orthogonal or left backward diagonal or right forward diagonal, slides left forward diagonal or right backward diagonal
# Blue Dragon		steps 2 left orthogonal or right orthogonal, slides backward orthogonal or forward orthogonal or right forward diagonal
# 
# Enchanted Badger	steps 2 orthogonal
# Horseman		steps 2 left orthogonal or right orthogonal, slides backward orthogonal or forward orthogonal or forward diagonal
# Swooping Owl		steps 1 forward orthogonal or backward diagonal
# 
# 				-222-
# }}}
# {{{ Row 1
  # {{{ Eastern Barbarian
  eba => {
    name => 'Eastern Barbarian',
    promote => 'ln',
    neighborhood => [
      q(  o  ),
      q( ooo ),
      q( o^o ),
      q(  o  ),
      q(  o  ) ] },
  # }}}
  # {{{ Violent Stag
  vs => {
    name => 'Violent Stag',
    promote => 'rbo',
    neighborhood => [
      q(     ),
      q( ooo ),
      q(  ^  ),
      q( o o ),
      q(     ) ] },
  # }}}
  # {{{ Violent Wolf
  vw => {
    name => 'Violent Wolf',
    promote => 'be',
    neighborhood => [
      q(     ),
      q( ooo ),
      q( o^o ),
      q(  o  ),
      q(     ) ] },
  # }}}
# }}}
# {{{ Row 2
  # {{{ Treacherous Fox
  tf => {
    name => 'Treacherous Fox',
    promote => 'mcr',
    neighborhood => [ [
        q(     ),
        q( \|/ ),
        q(  ^  ),
        q( /|\ ),
        q(     ) ],
      [ q(o   o),
        q( o o ),
        q(  ^  ),
        q( o o ),
        q(o   o) ] ] },
  # }}}
  # {{{ Center Master
  cm => {
    name => 'Center Master',
    neighborhood => [
      q(x x x),
      q( \|/ ),
      q(o3^3o),
      q( 3|3 ),
      q(o x o) ] },
  # }}}
  # {{{ Roc Master
  rm => {
    name => 'Roc Master',
    neighborhood => [ [
        q(     ),
        q( \|/ ),
        q(  ^  ),
        q(  |  ),
        q(     ) ],
      [ q(x   x),
        q( 3 3 ),
        q(o5^5o),
        q( 5 5 ),
        q(o   o) ] ] },
  # }}}
# }}}
# {{{ Row 3
  # {{{ Earth Chariot
  ech => {
    name => 'Earth Chariot',
    promote => 'yb',
    neighborhood => [
      q(     ),
      q(  |  ),
      q( o^o ),
      q(  |  ),
      q(     ) ] },
  # }}}
  # {{{ Vermillion Sparrow
  vsp => {
    name => 'Vermillion Sparrow',
    promote => 'dis',
    neighborhood => [ 
      q(     ),
      q( \oo ),
      q( o^o ),
      q( oo\ ),
      q(     ) ] },
  # }}}
  # {{{ Blue Dragon
  bdr => {
    name => 'Blue Dragon',
    promote => 'dd',
    neighborhood => [
      q(     ),
      q(  |/ ),
      q(oo^oo),
      q(  |  ),
      q(     ) ] },
  # }}}
# }}}
# {{{ Row 4
  # {{{ Enchanted Badger
  enba => {
    name => 'Enchanted Badger',
    promote => 'cd',
    neighborhood => [
      q(  o  ),
      q(  o  ),
      q(oo^oo),
      q(  o  ),
      q(  o  ) ] },
  # }}}
  # {{{ Horseman
  hom => {
    name => 'Horseman',
    promote => 'cav',
    neighborhood => [
      q(     ),
      q( \|/ ),
      q(oo^oo),
      q(  |  ),
      q(     ) ] },
  # }}}
  # {{{ Swooping Owl
  swo => {
    name => 'Swooping Owl',
    promote => 'cle',
    neighborhood => [
      q(     ),
      q(  o  ),
      q(  ^  ),
      q( o o ),
      q(     ) ] },
  # }}}
# }}}
# }}}
# {{{ Page 223
# {{{ 223
# Climbing Monkey		steps 1 backward orthogonal or forward orthogonal or forward diagonal
# Cat Sword		steps 1 diagonal
# Swallow's Wings		steps 1 backward orthogonal or forward orthogonal, slides left orthogonal or right orthogonal
# 
# Blind Monkey		steps 1 left orthogonal or right orthogonal or diagonal
# Blind Tiger		steps 1 backward orthogonal or left orthogonal or right orthogonal or diagonal
# Ox Cart			slides forward orthogonal
# 
# Side Flyer		steps 1 diagonal, slides left orthogonal or right orthogonal
# Blind Bear		steps 1 left orthogonal or right orthogonal or diagonal
# Old Rat			steps 1 forward orthogonal or backward diagonal
# 
# Square Mover		slides orthogonal
# Coiled Serpent		steps 1 backward orthogonal or forward orthogonal or backward diagonal
# Reclining Dragon	steps 1 orthogonal
# 
# 				-223-
# }}}
# {{{ Row 1
  # {{{ Climbing Monkey
  cmo => {
    name => 'Climbing Monkey',
    promote => 'vs',
    neighborhood => [
      q(     ),
      q( ooo ),
      q(  ^  ),
      q(  o  ),
      q(     ) ] },
  # }}}
  # {{{ Cat Sword
  cs => {
    name => 'Cat Sword',
    romaji => 'myojin',
    promote => 'dh',
    neighborhood => [
      q(     ),
      q( o o ),
      q(  ^  ),
      q( o o ),
      q(     ) ] },
  # }}}
  # {{{ Swallow's Wings
  sww => {
    name => "Swallow's Wings",
    promote => 'gsw',
    neighborhood => [
      q(     ),
      q(  o  ),
      q( -^- ),
      q(  o  ),
      q(     ) ] },
  # }}}
# }}}
# {{{ Row 2
  # {{{ Blind Monkey
  bm => {
    name => 'Blind Monkey',
    promote => 'flst',
    neighborhood => [
      q(     ),
      q( o o ),
      q( o^o ),
      q( o o ),
      q(     ) ] },
  # }}}
  # {{{ Blind Tiger
  bt => {
    name => 'Blind Tiger',
    romaji => 'moko',
    promote => 'flst',
    neighborhood => [
      q(     ),
      q( o o ),
      q( o^o ),
      q( ooo ),
      q(     ) ] },
  # }}}
  # {{{ Ox Cart
  oc => {
    name => 'Ox Cart',
    promote => 'po',
    neighborhood => [
      q(     ),
      q(  |  ),
      q(  ^  ),
      q(     ),
      q(     ) ] },
  # }}}
# }}}
# {{{ Row 3
  # {{{ Side Flier
  sf => {
    name => 'Side Flier',
    promote => 'sdr',
    neighborhood => [
      q(     ),
      q( o o ),
      q( -^- ),
      q( o o ),
      q(     ) ] },
  # }}}
  # {{{ Blind Bear
  bb => {
    name => 'Blind Bear',
    promote => 'flst',
    neighborhood => [ 
      q(     ),
      q( o o ),
      q( o^o ),
      q( o o ),
      q(     ) ] },
  # }}}
  # {{{ Old Rat
  or => {
    name => 'Old Rat',
    promote => 'bop',
    neighborhood => [
      q(     ),
      q(  o  ),
      q(  ^  ),
      q( o o ),
      q(     ) ] },
  # }}}
# }}}
# {{{ Row 4
  # {{{ Square Mover
  sqm => {
    name => 'Square Mover',
    promote => 'stch',
    neighborhood => [
      q(     ),
      q(  |  ),
      q( -^- ),
      q(  |  ),
      q(     ) ] },
  # }}}
  # {{{ Coiled Serpent
  cse => {
    name => 'Coiled Serpent',
    promote => 'codr',
    neighborhood => [
      q(     ),
      q(  o  ),
      q(  ^  ),
      q( ooo ),
      q(     ) ] },
  # }}}
  # {{{ Reclining Dragon
  redr => {
    name => 'Reclining Dragon',
    promote => 'gdr',
    neighborhood => [
      q(     ),
      q(  o  ),
      q( o^o ),
      q(  o  ),
      q(     ) ] },
  # }}}
# }}}
# }}}
# {{{ Page 224
# {{{ 224
# Free Eagle		slides or leaps 2 or 3 and slides orthogonal or backward diagonal, slides or leaps 2 or 4 and slides forward diagonal
# Lion Hawk		leaps 2 orthogonal, slides or leaps 2 and slides diagonal
# Chariot Soldier		steps 2 left orthogonal or right orthogonal, slides backward orthogonal or forward orthogonal or diagonal
# 
# The Lion Hawk, as in Tenjiku Shogi, may move like the Lion or leap to any square which would be attacked by the Lion.
# 
# Side Soldier		steps 1 backward orthogonal, steps 2 forward orthogonal, slides left orthogonal or right orthogonal
# Vertical Soldier	steps 1 backward orthogonal, steps 2 left orthogonal or right orthogonal, slides forward orthogonal
# Wind General		steps 1 backward orthogonal or forward diagonal, steps 3 forward orthogonal
# 
# River General		steps 1 backward orthogonal or forward diagonal, steps 3 forward orthogonal
# Mountain General	steps 1 backward orthogonal or forward orthogonal, steps 3 forward diagonal
# Front Standard		steps 3 diagonal, slides orthogonal
# 
# Horse Soldier		steps 1 backward orthogonal, steps 3 left orthogonal or right orthogonal, slides forward orthogonal or forward diagonal
# Wood General		steps 2 forward diagonal
# Ox Soldier		steps 1 backward orthogonal, steps 3 left orthogonal or right orthogonal, slides forward orthogonal or forward diagonal
# 
# 				-224-
# }}}
# {{{ Row 1
# {{{ Free Eagle
  feg => {
    name => 'Free Eagle',
    neighborhood => [ [
      q(       ),
      q(       ),
      q(  \|/  ),
      q(  -^-  ),
      q(  /|\  ),
      q(       ),
      q(       ) ],
    [ q(3  3  3),
      q( 2 2 2 ),
      q(  111  ),
      q(321^123),
      q(  111  ),
      q( 2 2 2 ),
      q(3  3  3) ] ] },
# }}}
# {{{ Lion Hawk
  lhk => { 
    name => 'Lion Hawk',
    neighborhood => [ # Not hook-mover, this is LC 'x'
      q(x   x),
      q( \ / ),
      q(  ^  ),
      q( / \ ),
      q(x   x) ] },
# }}}
# {{{ Chariot Soldier
  cso => { 
    name => 'Chariot Soldier',
    promote => 'htk',
    neighborhood => [
      q(     ),
      q( \|/ ),
      q(oo^oo),
      q( /|\ ),
      q(     ) ] },
# }}}
# }}}
# {{{ Row 2
# {{{ Side Soldier
  sso => { 
    name => 'Side Soldier',
    promote => 'wbf',
    neighborhood => [
      q(  o  ),
      q(  o  ),
      q( -^- ),
      q(  o  ),
      q(     ) ] },
# }}}
# {{{ Vertical Soldier
  vso => { 
    name => 'Vertical Soldier',
    promote => 'cso',
    neighborhood => [
      q(     ),
      q(  |  ),
      q(oo^oo),
      q(  o  ),
      q(     ) ] },
# }}}
# {{{ Wind General
  wig => { 
    name => 'Wind General',
    promote => 'vwd',
    neighborhood => [
      q(  o  ),
      q( o3o ),
      q(  ^  ),
      q(  o  ),
      q(     ) ] },
 # }}}
# }}}
# {{{ Row 3
# {{{ River General
  rvg => {
    name => 'River General',
    promote => 'cr',
    neighborhood => [
      q(  o  ),
      q( o3o ),
      q(  ^  ),
      q(  o  ),
      q(     ) ] },
# }}}
# {{{ Mountain General
  m => { 
    name => 'Mountain General',
    promote => 'pm',
    neighborhood => [ 
      q(o   o),
      q( 3o3 ),
      q(  ^  ),
      q(  o  ),
      q(     ) ] },
# }}}
# {{{ Front Standard
  fst => {
    name => 'Front Standard',
    promote => 'gst',
    neighborhood => [
      q(o   o),
      q( 3|3 ),
      q( -^- ),
      q( 3|3 ),
      q(o   o) ] },
# }}}
# }}}
# {{{ Row 4
# {{{ Horse Soldier
  hso => { 
    name => 'Horse Soldier',
    promote => 'rh',
    neighborhood => [
      q(     ),
      q( \|/ ),
      q(o3^3o),
      q(  o  ),
      q(     ) ] },
# }}}
# {{{ Wood General
  w => {
    name => 'Wood General',
    promote => 'wel',
    neighborhood => [
      q(o   o),
      q( o o ),
      q(  ^  ),
      q(     ),
      q(     ) ] },
# }}}
# {{{ Ox Soldier
  oso => { 
    name => 'Ox Soldier',
    promote => 'rox',
    neighborhood => [
      q(     ),
      q( \|/ ),
      q(o3^3o),
      q(  o  ),
      q(     ) ] },
# }}}
# }}}
# }}}
# {{{ Page 225
# {{{ 225
# Earth General		steps 1 backward orthogonal or forward orthogonal
# Boar Soldier		steps 1 backward orthogonal, steps 2 left orthogonal or right orthogonal, slides forward orthogonal or forward diagonal
# Stone General		steps 1 forward diagonal
# 
# Leopard Soldier		steps 1 backward orthogonal, steps 2 left orthogonal or right orthogonal, slides forward orthogonal or forward diagonal
# Tile General		steps 1 backward orthogonal or forward diagonal
# Bear Soldier		steps 1 backward orthogonal, steps 2 left orthogonal or right orthogonal, slides forward orthogonal or forward diagonal
# 
# Iron General		steps 1 forward orthogonal or forward diagonal
# Great Standard		steps 3 backward diagonal, slides orthogonal or forward diagonal
# Great Master		steps 5 left orthogonal or right orthogonal or bacward diagonal, leaps 3 forward orthogonal or forward diagonal, slides forward orthogonal or forward diagonal
# 
# Right Chariot		steps 1 right orthogonal, slides forward orthogonal or left forward diagonal or right backward diagonal
# Left Chariot		steps 1 left orthogonal, slides forward orthogonal or right forward diagonal or lefr backward diagonal
# Side Monkey		steps 1 backward orthogonal or forward diagonal, slides left orthogonal or right orthogonal
# 
# 				-225-
# }}}
# {{{ Row 1
# {{{ Earth General
  e => { 
    name => 'Earth General',
    promote => 'wel',
    neighborhood => [
      q(     ),
      q(  o  ),
      q(  ^  ),
      q(  o  ),
      q(     ) ] },
# }}}
# {{{ Boar Soldier
  bso => { 
    name => 'Boar Soldier',
    promote => 'sb',
    neighborhood => [
      q(     ),
      q( \|/ ),
      q(oo^oo),
      q(  o  ),
      q(     ) ] },
# }}}
# {{{ Stone General
  st => {
    name => 'Stone General',
    romaji => 'sekisho',
    promote => 'wel',
    neighborhood => [
      q(     ),
      q( o o ),
      q(  ^  ),
      q(     ),
      q(     ) ] },
# }}}
# }}}
# {{{ Row 2
# {{{ Leopard Soldier
  lso => {
    name => 'Leopard Soldier',
    promote => 'rle',
    neighborhood => [
      q(     ),
      q( \|/ ),
      q(oo^oo),
      q(  o  ),
      q(     ) ] },
# }}}
# {{{ Tile General
  t => { 
    name => 'Tile General',
    promote => 'wel',
    neighborhood => [
      q(     ),
      q( o o ),
      q(  ^  ),
      q(  o  ),
      q(     ) ] },
# }}}
# {{{ Bear Soldier
  beso => { 
    name => 'Bear Soldier',
    promote => 'sb',
    neighborhood => [
      q(     ),
      q( \|/ ),
      q(oo^oo),
      q(  o  ),
      q(     ) ] },
 # }}}
# }}}
# {{{ Row 3
# {{{ Iron General
  i => { 
    name => 'Iron General',
    romaji => 'tessho',
    promote => 'wel',
    neighborhood => [
      q(     ),
      q( ooo ),
      q(  ^  ),
      q(     ),
      q(     ) ] },
# }}}
# {{{ Great Standard
  gst => { 
    name => 'Great Standard',
    neighborhood => [ 
      q(     ),
      q( \|/ ),
      q( -^- ),
      q( 3|3 ),
      q(o   o) ] },
# }}}
# {{{ Great Master
  gma => { 
    name => 'Great Master',
    neighborhood => [ [
      q(     ),
      q( \|/ ),
      q(  ^  ),
      q(  |  ),
      q(     ) ],
    [ q(x x x),
      q( 333 ),
      q(o5^5o),
      q( 5 5 ),
      q(o   o) ] ] },
# }}}
# }}}
# {{{ Row 4
# {{{ Right Chariot
  rch => { 
    name => 'Right Chariot',
    promote => 'rich',
    neighborhood => [
      q(     ),
      q( \|  ),
      q(  ^o ),
      q(   \ ),
      q(     ) ] },
# }}}
# {{{ Left Chariot
  lch => { 
    name => 'Left Chariot',
    promote => 'lich',
    neighborhood => [
      q(     ),
      q(  |/ ),
      q( o^  ),
      q( /   ),
      q(     ) ] },
# }}}
# {{{ Side Monkey
  smo => { 
    name => 'Side Monkey',
    promote => 'sso',
    neighborhood => [
      q(     ),
      q( o o ),
      q( -^- ),
      q(  o  ),
      q(     ) ] },
# }}}
# }}}
# }}}
# {{{ Page 226
# {{{ 226
# Vertical Mover		steps 1 left orthogonal or right orthogonal, slides backward orthogonal or forward orthogonal
# Flying Ox		slides backward orthogonal or forward orthogonal or diagonal
# Longbow Soldier		steps 1 backward orthogonal, steps 2 left orthogonal or right orthogonal, steps 5 forward diagonal, slides forward orthogonal
# 
# Vertical Pup		steps 1 backward orthogonal or backward diagonal, slides forward orthogonal
# Vertical Horse		steps 1 backward orthogonal or forward diagonal, slides forward orthogonal
# Burning Soldier		steps 1 backward orthogonal, steps 3 left orthogonal or right orthogonal, steps 5 forward diagonal, steps 7 forward orthogonal
# 
# Dragon Horse		steps 1 orthogonal, slides diagonal
# Dragon King		steps 1 diagonal, slides orthogonal
# Sword Soldier		steps 1 backward orthogonal or forward diagonal
# 
# Horned Falcon		leaps 2 forward orthogonal, slides orthogonal or diagonal
# Soaring Eagle		leaps 2 forward diagonal, slides orthogonal or diagonal
# Spear Soldier		steps 1 backward orthogonal or left orthogonal or right orthogonal, slides forward orthogonal
# 
# 				-226-
# }}}
# {{{ Row 1
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
# {{{ Flying Ox
  fo => { 
    name => 'Flying Ox',
    romaji => 'higyu',
    promote => 'fox',
    neighborhood => [
      q(     ),
      q( \|/ ),
      q(  ^  ),
      q( /|\ ),
      q(     ) ] },
# }}}
# {{{ Longbow Soldier
  lbso => { 
    name => 'Longbow Soldier',
    promote => 'lbg',
    neighborhood => [
      q(o   o),
      q( 5|5 ),
      q(oo^oo),
      q(  o  ),
      q(     ) ] },
# }}}
# }}}
# {{{ Row 2
# {{{ Vertical Pup
  vp => { 
    name => 'Vertical Pup',
    promote => 'lk',
    neighborhood => [
      q(     ),
      q(  |  ),
      q(  ^  ),
      q( ooo ),
      q(     ) ] },
# }}}
# {{{ Vertical Horse
  vho => { 
    name => 'Vertical Horse',
    promote => 'dh',
    neighborhood => [
      q(     ),
      q( o|o ),
      q(  ^  ),
      q(  o  ),
      q(     ) ] },
# }}}
# {{{ Burning Soldier
  buso => { 
    name => 'Burning Soldier',
    promote => 'bug',
    neighborhood => [
      q(o o o),
      q( 575 ),
      q(o3^3o),
      q(  o  ),
      q(     ) ] },
 # }}}
# }}}
# {{{ Row 3
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
# {{{ Sword Soldier
  swso => { 
    name => 'Sword Soldier',
    promote => 'swg',
    neighborhood => [
      q(     ),
      q( o o ),
      q(  ^  ),
      q(  o  ),
      q(     ) ] },
# }}}
# }}}
# {{{ Row 4
# {{{ Horned Falcon
  hf => { 
    name => 'Horned Falcon',
    romaji => 'kakuo',
    promote => 'gf',
    neighborhood => [
      q(  x  ),
      q( \|/ ),
      q( -^- ),
      q( /|\ ),
      q(     ) ] },
# }}}
# {{{ Soaring Eagle
  se => {
    name => 'Soaring Eagle',
    romaji => 'hiju',
    promote => 'gea',
    neighborhood => [
      q(x   x),
      q( \|/ ),
      q( -^- ),
      q( /|\ ),
      q(     ) ] },
# }}}
# {{{ Spear Soldier
  spso => {
    name => 'Spear Soldier',
    promote => 'spg',
    neighborhood => [
      q(     ),
      q(  |  ),
      q( o^o ),
      q(  o  ),
      q(     ) ] },
# }}}
# }}}
# }}}
# {{{ Page 227
# {{{ 227
# Vertical Leopard	steps 1 backward orthogonal or left orthogonal or right orthogonal or forward diagonal, slides forward orthogonal
# Savage Tiger		slides forward orthogonal
# Shortbow Soldier	steps 1 backward orthogonal, steps 3 left orthogonal or right orthogonal or forward diagonal, steps 5 forward orthogonal
# 
# Roaring Dog		steps 3 backward diagonal, leap 3 orthogonal or forward diagonal, slides orthogonal or forward diagonal
# Lion Dog		leaps 3 orthogonal or diagonal, slides orthogonal or diagonal
# Dog			steps 1 forward orthogonal or forward diagonal
# 
# Go-Between		steps 1 backward orthogonal or forward orthogonal
# Pawn			steps 1 forward orthogonal
# 
#   (Rules for promoted pieces)
# 
# Free Bird		steps 3 backward diagonal, slides orthogonal, hash-marked slides forward diagonal
# Great Tapir		leaps 3 left orthogonal or right orthogonal, slides orthogonal or diagonal
# Ancient Dragon		slides diagonal, hash-marked slides backward orthogonal or forward orthogonal 
# 
# 				-227-
# }}}
# {{{ Row 1
# {{{ Vertical Leopard
  vl => { 
    name => 'Vertical Leopard',
    promote => 'gle',
    neighborhood => [
      q(     ),
      q( o|o ),
      q( o^o ),
      q(  o  ),
      q(     ) ] },
# }}}
# {{{ Savage Tiger
  sti => { 
    name => 'Savage Tiger',
    promote => 'gti',
    neighborhood => [
      q(     ),
      q(  |  ),
      q(  ^  ),
      q(     ),
      q(     ) ] },
# }}}
# {{{ Shortbow Soldier
  sbso => { 
    name => 'Shortbow Soldier',
    promote => 'sbg',
    neighborhood => [
      q(o o o),
      q( 353 ),
      q(o3^3o),
      q(  o  ),
      q(     ) ] },
# }}}
# }}}
# {{{ Row 2
# {{{ Roaring Dog
  rdo => { 
    name => 'Roaring Dog',
    promote => 'ld',
    neighborhood => [ [
      q(     ),
      q( \|/ ),
      q( -^- ),
      q(  |  ),
      q(     ) ],
    [ q(x x x),
      q( 333 ),
      q(x3^3x),
      q( 333 ),
      q(o x o) ] ] },
# }}}
# {{{ Lion Dog
  ld => { 
    name => 'Lion Dog',
    promote => 'gel',
    neighborhood => [ [
      q(     ),
      q( \|/ ),
      q( -^- ),
      q( /|\ ),
      q(     ) ],
    [ q(x x x),
      q( 333 ),
      q(x3^3x),
      q( 333 ),
      q(x x x) ] ] },
# }}}
# {{{ Dog
  d => { 
    name => 'Dog',
    promote => 'mug',
    neighborhood => [
      q(     ),
      q( ooo ),
      q(  ^  ),
      q(     ),
      q(     ) ] },
 # }}}
# }}}
# {{{ Row 3
# {{{ Go-Between
  gb => { 
    name => 'Go-Between',
    romaji => 'chunin',
    promote => 'del',
    neighborhood => [
      q(     ),
      q(  o  ),
      q(  ^  ),
      q(  o  ),
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
# }}}
# {{{ Row 4
# {{{ Free Bird
  fbd => { 
    name => 'Free Bird',
    neighborhood => [ # XXX Hook mover?
      q(\   /),
      q( X|X ),
      q( -^- ),
      q( 3|3 ),
      q(o   o) ] },
# }}}
# {{{ Great Tapir
  gtp => { 
    name => 'Great Tapir',
    neighborhood => [ [
      q(     ),
      q( \|/ ),
      q( -^- ),
      q( /|\ ),
      q(     ) ],
    [ q(     ),
      q(     ),
      q(x3^3x),
      q(     ),
      q(     ) ] ] },
# }}}
# {{{ Ancient Dragon
  adr => { 
    name => 'Ancient Dragon',
    neighborhood => [ # XXX Hook mover?
      q(  |  ),
      q( \+/ ),
      q(  ^  ),
      q( /+\ ),
      q(  |  ) ] },
# }}}
# }}}
# }}}
# {{{ Page 228
# {{{ 228
# Heavenly Tetarch King	igui 1 orthogonal or diagonal, slides orthogonal or diagonal, leaps 1 and slides orthogonal or diagonal
# Great Falcon		slides orthogonal or diagonal, leaps 1 and slides forward orthogonal
# Great Elephant		steps 3 forward diagonal, hash-marked slides orthogonal or backward diagonal
# 
#   Heavenly Tetarch King is able to capture an adjacent square without moving(Igui), or preform its slide by leaping over an occupied adjacent square.
#   Great Falcon is able to preform its forward orthogonal slide by leaping over an occupied adjacent square.
# 
# Fire Ox			steps 1 left orthogonal or right orthogonal, slides backward orthogonal or forward orthogonal or diagonal
# Strong Bear		steps 2 backward orthogonal, slides left orthogonal or right orthogonal or forward orthogonal or diagonal
# Right Phoenix		steps 5 left orthogonal or right orthogonal, slides diagonal
# 
# Running Leopard		slides left orthogonal or right orthogonal or forward orthgonal or forward diagonal
# Thunder Runner		steps 4 backward orthogonal or left orthogonal or right orthogonal, slides forward orthogonal or forward diagonal
# Rain Demon		steps 2 backward diagonal or left orthogonal or right orthogonal, steps 3 forward orthogonal, slides forward diagonal, leaps 1 and slides forward diagonal
# 
#   Rain Demon is able to preform its forward diagonal slide by leaping over an occupied adjacent square.
# 
# Free Boar		steps 1 backward orthogonal, slides left orthogonal or right orthogonal or forward orthogonal or forward diagonal
# Free Dog		steps 2 backward diagonal or left orthogonal or right orthogonal, slides backward orthogonal or forward orthogonal or forward diagonal
# Running Ox		steps 2 backward diagonal, slides left orthogonal or right orthogonal or forward orthogonal or forward diagonal
# 
# 				-228-
# }}}
# {{{ Row 1
# {{{ Heavenly Tetrarch King
  htk => { 
    name => 'Heavenly Tetrarch King',
    neighborhood => [ [
      q(     ),
      q( \|/ ),
      q( -^- ),
      q( /|\ ),
      q(     ) ],
    [ q(     ),
      q( ooo ),
      q( o^o ),
      q( ooo ),
      q(     ) ] ] },
# }}}
# {{{ Great Falcon
  gf => { 
    name => 'Great Falcon',
    neighborhood => [ [
      q(     ),
      q( \|/ ),
      q( -^- ),
      q( /|\ ),
      q(     ) ],
    [ q(     ),
      q(  o  ),
      q(  ^  ),
      q(     ),
      q(     ) ] ] },
# }}}
# {{{ Great Elephant
  gel => { 
    name => 'Great Elephant',
    neighborhood => [ # Hook mover?
      q(o | o),
      q( 3+3 ),
      q(-+^+-),
      q( X+X ),
      q(/ | \\) ] },
# }}}
# }}}
# {{{ Row 2
# {{{ Fire Ox
  fox => {
    name => 'Fire Ox',
    neighborhood => [
      q(     ),
      q( \|/ ),
      q( o^o ),
      q( /|\ ),
      q(     ) ] },
# }}}
# {{{ Strong Bear
  sb => { 
    name => 'Strong Bear',
    neighborhood => [
      q(     ),
      q( \|/ ),
      q( -^- ),
      q( /o\ ),
      q(  o  ) ] },
# }}}
# {{{ Right Phoenix
  rph => { 
    name => 'Right Phoenix',
    neighborhood => [
      q(     ),
      q( \ / ),
      q(o5^5o),
      q( / \ ),
      q(     ) ] },
 # }}}
# }}}
# {{{ Row 3
# {{{ Running Leopard
  rle => { 
    name => 'Running Leopard',
    neighborhood => [
      q(     ),
      q( \|/ ),
      q( -^- ),
      q(     ),
      q(     ) ] },
# }}}
# {{{ Thunder Runner
  thr => { 
    name => 'Thunder Runner',
    neighborhood => [ 
      q(     ),
      q( \|/ ),
      q(o4^4o),
      q(  4  ),
      q(  o  ) ] },
# }}}
# {{{ Rain Demon
  rde => { 
    name => 'Rain Demon',
    neighborhood => [ [
      q(     ),
      q( \ / ),
      q(  ^  ),
      q(  |  ),
      q(     ) ],
    [ q(  o  ),
      q( o3o ),
      q(oo^oo),
      q( o o ),
      q(o   o) ] ] },
# }}}
# }}}
# {{{ Row 4
# {{{ Free Boar
  fbo => { 
    name => 'Free Boar',
    romaji => 'honcho',
    neighborhood => [
      q(     ),
      q( \|/ ),
      q( -^- ),
      q(  o  ),
      q(     ) ] },
# }}}
# {{{ Free Dog
  fdo => { 
    name => 'Free Dog',
    neighborhood => [
      q(     ),
      q( \|/ ),
      q(oo^oo),
      q( o|o ),
      q(o   o) ] },
# }}}
# {{{ Running Ox
  rox => { 
    name => 'Running Ox',
    neighborhood => [
      q(     ),
      q( \|/ ),
      q( -^- ),
      q(  o  ),
      q(  o  ) ] },
# }}}
# }}}
# }}}
# {{{ Page 229
# {{{ 229
# Great Horse		steps 2 left orthogonal or right orthogonal, slides backward orthogonal or forward orthogonal or forward diagonal
# Cavalier		slides orthogonal or forward diagonal
# Free Fire		steps 5 backward orthogonal or forward orthogonal, slides left orthogonal or right orthogonal or diagonal
# 
# Burning Chariot		steps 1 left orthogonal or right orthogonal, slides backward orthogonal or forward orthogonal or forward diagonal
# Free Stag		slides orthogonal or diagonal
# Free Dragon		slides backward orthogonal or left orthogonal or right orthogonal or diagonal
# 
# Flying Crocodile	steps 2 backward diagonal, steps 3 forward diagonal, range jump orthogonal(ranking noted at end of document)
# Strong Chariot		slides orthogonal or forward diagonal
# Divine Tiger		steps 2 backward orthogonal, slides left orthogonal or right orthogonal or forward orthogonal or left forward diagonal
# 
# Divine Dragon		steps 2 left orthogonal, slides backward orthogonal or right orthogonal or forward orthogonal or right forward diagonal
# Divine Turtle		steps 1 orthogonal or left forward diagonal, slides backward diagonal or right forward diagonal
# Divine Sparrow		steps 1 orthogonal or right forward diagonal, slides backward diagonal or left forward diagonal
# 
# 				-229-
# }}}
# {{{ Row 1
# {{{ Great Horse
  gho => { 
    name => 'Great Horse',
    neighborhood => [
      q(     ),
      q( \|/ ),
      q(oo^oo),
      q(  |  ),
      q(     ) ] },
# }}}
# {{{ Cavalier
  cav => { 
    name => 'Cavalier',
    neighborhood => [
      q(     ),
      q( \|/ ),
      q( -^- ),
      q(  |  ),
      q(     ) ] },
# }}}
# {{{ Free Fire
  ffi => { 
    name => 'Free Fire',
    neighborhood => [
      q(  o  ),
      q( \5/ ),
      q( -^- ),
      q( /5\ ),
      q(  o  ) ] },
# }}}
# }}}
# {{{ Row 2
# {{{ Burning Chariot
  bch => { 
    name => 'Burning Chariot',
    neighborhood => [
      q(     ),
      q( \|/ ),
      q( o^o ),
      q(  |  ),
      q(     ) ] },
# }}}
# {{{ Free Stag
  frst => { 
    name => 'Free Stag',
    neighborhood => [
      q(     ),
      q( \|/ ),
      q( -^- ),
      q( /|\ ),
      q(     ) ] },
# }}}
# {{{ Free Dragon
  frdr => { 
    name => 'Free Dragon',
    neighborhood => [
      q(     ),
      q( \ / ),
      q( -^- ),
      q( /|\ ),
      q(     ) ] },
 # }}}
# }}}
# {{{ Row 3
# {{{ Flying Crocodile
  fcr => { 
    name => 'Flying Crocodile',
    neighborhood => [
      q(o | o),
      q( 3|3 ),
      q(--^--),
      q( 3|3 ),
      q(o | o) ] },
# }}}
# {{{ Strong Chariot
  stch => { 
    name => 'Strong Chariot',
    neighborhood => [ 
      q(     ),
      q( \|/ ),
      q( -^- ),
      q(  |  ),
      q(     ) ] },
# }}}
# {{{ Divine Tiger
  dt => { 
    name => 'Divine Tiger',
    neighborhood => [
      q(     ),
      q( \|  ),
      q( -^- ),
      q(  o  ),
      q(  o  ) ] },
# }}}
# }}}
# {{{ Row 4
# {{{ Divine Dragon
  dd => { 
    name => 'Divine Dragon',
    neighborhood => [
      q(     ),
      q(  |/ ),
      q(oo^- ),
      q(  |  ),
      q(     ) ] },
# }}}
# {{{ Divine Turtle
  dtu => { 
    name => 'Divine Turtle',
    neighborhood => [
      q(     ),
      q( oo/ ),
      q( o^o ),
      q( /o\ ),
      q(     ) ] },
# }}}
# {{{ Divine Sparrow
  dis => { 
    name => 'Divine Sparrow',
    neighborhood => [
      q(     ),
      q( \oo ),
      q( o^o ),
      q( /o\ ),
      q(     ) ] },
# }}}
# }}}
# }}}
# {{{ Page 230
# {{{ 230
# Free Serpent		slides backward orthogonal or forward orthogonal or backward diagonal
# Free Wolf		slides left orthogonal or right orthogonal or forward orthogonal or forward diagonal
# Great Tiger		steps 1 forward orthogonal, slides backward orthogonal or left orthogonal or right orthogonal
# 
# Right Dog		steps 1 backward orthogonal, slides forward orthogonal or left backward diagonal
# Left Dog		steps 1 backward orthogonal, slides forward orthogonal or right backward diagonal
# Free Bear		slides backward orthogonal or forward orthogonal or diagonal
# 
# Free Tiger		slides backward orthogonal or left orthogonal or right orthogonal or diagonal
# Running Boar		steps 1 left orthogonal or right orthogonal, slides backward orthogonal or forward orthogonal
# Free Leopard		slides backward orthogonal or forward orthogonal or diagonal
# 
# Heavenly Horse		leaps 1 backward orthogonal then 1 backward diagonal, leaps 1 forward orthogonal then 1 forward orthogonal, slides forward orthogonal
# Spear General		steps 2 backward orthogonal, steps 3 left orthogonal or right orthogonal, slides forward orthogonal
# Great Leopard		steps 1 backward orthogonal, steps 2 left orthogonal or right orthogonal, steps 3 forward diagonal, slides forward orthogonal
# 
# 				-230-
# }}}
# {{{ Row 1
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
  # {{{ Free Wolf
  fwo => {
    name => 'Free Wolf',
    neighborhood => [
      q(     ),
      q( \|/ ),
      q( -^- ),
      q(     ),
      q(     ) ] },
  # }}}
  # {{{ Great Tiger
  gti => {
    name => 'Great Tiger',
    neighborhood => [
      q(     ),
      q(  o  ),
      q( -^- ),
      q(  |  ),
      q(     ) ] },
  # }}}
# }}}
# {{{ Row 2
  # {{{ Right Dog
  rdo => {
    name => 'Right Dog',
    neighborhood => [
      q(     ),
      q(  |  ),
      q(  ^  ),
      q( /o  ),
      q(     ) ] },
  # }}}
  # {{{ Left Dog
  ldo => {
    name => 'Left Dog',
    neighborhood => [
      q(     ),
      q(  |  ),
      q(  ^  ),
      q(  o\ ),
      q(     ) ] },
  # }}}
  # {{{ Free Bear
  fbe => {
    name => 'Free Bear',
    neighborhood => [
      q(     ),
      q( \|/ ),
      q(  ^  ),
      q( /|\ ),
      q(     ) ] },
 # }}}
# }}}
# {{{ Row 3
  # {{{ Free Tiger
  fti => {
    name => 'Free Tiger',
    neighborhood => [
      q(     ),
      q( \ / ),
      q( -^- ),
      q( /|\ ),
      q(     ) ] },
  # }}}
  # {{{ Running Boar
  rbo => {
    name => 'Running Boar',
    neighborhood => [ 
      q(     ),
      q(  |  ),
      q( o^o ),
      q(  |  ),
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
# }}}
# {{{ Row 4
  # {{{ Heavenly Horse
  hh => {
    name => 'Heavenly Horse',
    neighborhood => [
      q( x x ),
      q(  |  ),
      q(  ^  ),
      q(     ),
      q( x x ) ] },
  # }}}
  # {{{ Spear General
  spg => {
    name => 'Spear General',
    neighborhood => [
      q(     ),
      q(  |  ),
      q(o3^3o),
      q(  o  ),
      q(  o  ) ] },
  # }}}
  # {{{ Great Leopard
  gle => {
    name => 'Great Leopard',
    neighborhood => [
      q(o   o),
      q( 3|3 ),
      q(oo^oo),
      q(  o  ),
      q(     ) ] },
  # }}}
# }}}
# }}}
# {{{ Page 231
# {{{ 231
# Flying Stag		steps 1 left orthogonal or right orthogonal or diagonal, slides backward orthogonal or forward orthogonal
# Right Army		steps 1 backward orthogonal or left orthogonal or forward orthogonal or left diagonal, slides right orthogonal or right diagonal
# Left Army		steps 1 backward orthogonal or right orthogonal or forward orthogonal or right diagonal, slides left orthogonal or left diagonal
# 
# Beast Bird		steps 2 backward orthogonal, steps 3 left orthogonal or right orthogonal, slides forward orthogonal or diagonal
# Captive Bird		steps 2 backward orthogonal, steps 3 left orthogonal or right orthogonal, slides forward orthogonal or diagonal
# Gliding Swallow		slides orthogonal
# 
# Buddhist Spirit		2-space Lion move, slides orthogonal or diagonal
# Teaching King		hash-marked slides orthogonal or diagonal
# Shark			steps 2 backward diagonal, steps 5 forward diagonal, slides orthogonal
# 
# Buddhist Spirit, like in Maka-Dai-Dai Shogi, may slide orthogonal or diagonal or preform moves like the Lion.
# 
# Furious Fiend		2-space Lion move, steps 3 orthogonal or diagonal
# Leopard King		steps 5 orthogonal or diagonal
# Goose Wing		steps 1 diagonal, steps 3 left orthogonal or right orthogonal, slides backward orthogonal or forward orthogonal
# c2
# Furious Fiend, like in Dai-Dai Shogi and Maka-Dai-Dai Shogi, may step three spaces orthogonal or diagoanl or preform moves like the Lion.
# 
# 				-231-
# }}}
# {{{ Row 1
  # {{{ Flying Stag
  flst => {
    name => 'Flying Stag',
    romaji => 'hiroku',
    neighborhood => [
    q(     ),
    q( o|o ),
    q( o^o ),
    q( o|o ),
    q(     ) ] },
  # }}}
  # {{{ Right Army
  ra => {
    name => 'Right Army',
    neighborhood => [
      q(     ),
      q( oo/ ),
      q( o^- ),
      q( oo\ ),
      q(     ) ] },
  # }}}
  # {{{ Left Army
  la => {
    name => 'Left Army',
    neighborhood => [
      q(     ),
      q( \oo ),
      q( -^o ),
      q( /oo ),
      q(     ) ] },
  # }}}
# }}}
# {{{ Row 2
  # {{{ Beast Bird
  bbd => {
    name => 'Beast Bird',
    neighborhood => [
      q(     ),
      q( \|/ ),
      q(o3^3o),
      q( /o\ ),
      q(  o  ) ] },
  # }}}
  # {{{ Captive Bird
  cb => {
    name => 'Captive Bird',
    neighborhood => [
      q(     ),
      q( \|/ ),
      q(o3^3o),
      q( /o\ ),
      q(  o  ) ] },
  # }}}
  # {{{ Gliding Swallow
  gsw => {
    name => 'Gliding Swallow',
    neighborhood => [
      q(     ),
      q(  |  ),
      q( -^- ),
      q(  |  ),
      q(     ) ] },
 # }}}
# }}}
# {{{ Row 3
  # {{{ Buddhist Spirit
  bsp => {
    name => 'Buddhist Spirit',
    neighborhood => [ # XXX
      q(     ),
      q(     ),
      q(  ^  ),
      q(     ),
      q(     ) ] },
  # }}}
  # {{{ Teaching King
  tk => {
    name => 'Teaching King',
    neighborhood => [ 
      q(X + X), # Hash-marked, whatever that means
      q( \|/ ),
      q(+-^-+),
      q( /|\ ),
      q(X + X) ] },
  # }}}
  # {{{ Shark
  sh => {
    name => 'Shark',
    neighborhood => [
      q(o   o),
      q( 5|5 ),
      q( -^- ),
      q( 2|2 ),
      q(o   o) ] },
  # }}}
# }}}
# {{{ Row 4
  # {{{ Furious Fiend
  ff => {
    name => 'Furious Fiend',
    neighborhood => [ # XXX
      q(     ),
      q(     ),
      q(  ^  ),
      q(     ),
      q(     ) ] },
  # }}}
  # {{{ Leopard King
  lk => {
    name => 'Leopard King',
    neighborhood => [
      q(o o o),
      q( 555 ),
      q(o5^5o),
      q( 555 ),
      q(o o o) ] },
  # }}}
  # {{{ Goose Wing
  gw => {
    name => 'Goose Wing',
    neighborhood => [
      q(     ),
      q( o|o ),
      q(o3^3o),
      q( o|o ),
      q(     ) ] },
  # }}}
# }}}
# }}}
# {{{ Page 232
# {{{ 232
# Left Iron Chariot	steps 1 left orthogonal, slides backward diagonal or right forward diagonal
# Right Iron Chariot	steps 1 right orthogonal, slides backward diagonal or left forward diagonal
# Plodding Ox		steps 1 diagonal, slides backward orthogonal or forward orthogonal
# 
# Wind Snapping Turtle	steps 2 forward diagonal, slides backward orthogonal or forward orthogonal
# Running Tile		steps 2 left orthogonal or right orthogonal, slides backward orthogonal or forward orthogonal
# Young Bird		steps 2 left orthogonal or right orthogonal or backward diagonal, slides backward orthogonal or forward orthogonal
# 
# Playful Cockatoo	steps 2 backward diagonal, steps 3 forward diagonal, steps 5 left orthogonal or right orthogonal, slides backward orthogonal or forward orthogonal
# Copper Elephant		steps 1 left orthogonal or right orthogonal or diagonal, slides backward orthogonal or forward orthogonal
# Walking Heron		steps 2 left orthogonal or right orthogonal or forward diagonal, slides backward orthogonal or forward orthogonal
# 
# Tiger Soldier		steps 1 backward orthogonal, steps 2 forward orthogonal, slides forward diagonal
# Strong Eagle		slides orthogonal or diagonal
# Running Dragon		steps 5 backward orthogonal, slides left orthogonal or right orthogonal or forward orthogonal or diagonal
# 
# 				-232-
# }}}
# {{{ Row 1
  # {{{ Left Iron Chariot
  lich => {
    name => 'Left Iron Chariot',
    neighborhood => [
      q(     ),
      q(   / ),
      q( o^  ),
      q( / \ ),
      q(     ) ] },
  # }}}
  # {{{ Right Iron Chariot
  rich => {
    name => 'Right Iron Chariot',
    neighborhood => [
      q(     ),
      q( \   ),
      q(  ^o ),
      q( / \ ),
      q(     ) ] },
  # }}}
  # {{{ Plodding Ox
  po => {
    name => 'Plodding Ox',
    neighborhood => [
      q(     ),
      q( o|o ),
      q(  ^  ),
      q( o|o ),
      q(     ) ] },
  # }}}
# }}}
# {{{ Row 2
  # {{{ Wind Snapping Turtle
  wst => {
    name => 'Wind Snapping Turtle',
    neighborhood => [
      q(o   o),
      q( o|o ),
      q(  ^  ),
      q(  |  ),
      q(     ) ] },
  # }}}
  # {{{ Running Tile
  rtl => {
    name => 'Running Tile',
    neighborhood => [
      q(     ),
      q(  |  ),
      q(oo^oo),
      q(  |  ),
      q(     ) ] },
  # }}}
  # {{{ Young Bird
  yb => {
    name => 'Young Bird',
    neighborhood => [
      q(     ),
      q(  |  ),
      q(oo^oo),
      q( o|o ),
      q(o   o) ] },
 # }}}
# }}}
# {{{ Row 3
  # {{{ Playful Cockatoo
  plc => {
    name => 'Playful Cockatoo',
    neighborhood => [
      q(o   o),
      q( 3|3 ),
      q(o5^5o),
      q( o|o ),
      q(o   o) ] },
  # }}}
  # {{{ Copper Elephant
  ce => {
    name => 'Copper Elephant',
    neighborhood => [ 
      q(     ),
      q( o|o ),
      q( o^o ),
      q( o|o ),
      q(     ) ] },
  # }}}
  # {{{ Walking Heron
  whe => {
    name => 'Walking Heron',
    neighborhood => [
      q(o   o),
      q( o|o ),
      q(oo^oo),
      q(  |  ),
      q(     ) ] },
  # }}}
# }}}
# {{{ Row 4
  # {{{ Tiger Soldier
  tso => {
    name => 'Tiger Soldier',
    neighborhood => [
      q(  o  ),
      q( \o/ ),
      q(  ^  ),
      q(  o  ),
      q(     ) ] },
  # }}}
  # {{{ Strong Eagle
  seg => {
    name => 'Strong Eagle',
    neighborhood => [
      q(     ),
      q( \|/ ),
      q( -^- ),
      q( /|\ ),
      q(     ) ] },
  # }}}
  # {{{ Running Dragon
  rudr => {
    name => 'Running Dragon',
    neighborhood => [
      q(     ),
      q( \|/ ),
      q( -^- ),
      q( /5\ ),
      q(  o  ) ] },
  # }}}
# }}}
# }}}
# {{{ Page 233
# {{{ 233
# Heavenly Tetarch	steps 4 orthogonal or diagonal
# Elephant King		steps 2 orthogonal, slides diagonal
# Peaceful Mountain	steps 5 left orthogonal or right orthogonal or forward orthogonal, slides diagonal
# 
# Chinese River		steps 1 backward orthogonal or forward orthogonal, slides left orthogonal or right orthogonal or diagonal
# Violent Wind		steps 1 left orthogonal or right orthogonal, slides backward orthogonal or forward orthogonal or diagonal
# Free Chicken		steps 2 left orthogonal or right orthogonal or backward diagonal, slides backward orthogonal or forward orthogonal or forward diagonal
# 
# Free Ox			steps 1 backward diagonal, steps 2 left orthogonal or right orthogonal, slides backward orthogonal or forward orthogonal or forward diagonal
# Free Horse		steps 1 backward diagonal, steps 2 left orthogonal or right orthogonal, slides backward orthogonal or forward orthogonal or forward diagonal
# Great Whale		slides backward orthogonal or forward orthogonal or diagonal
# 
# Free Pig		steps 1 backward diagonal, steps 2 left orthogonal or right orthogonal, slides backward orthogonal or forward orthogonal or forward diagonal
# Longbow General		steps 5 left orthogonal or right orthogonal, slides backward orthogonal or forward orthogonal or forward diagonal
# Burning General		steps 2 backward orthogonal, steps 3 left orthogonal or right orthogonal, slides forward orthogonal or forward diagonal
# 
# 				-233-
# }}}
# {{{ Row 1
  # {{{ Heavenly Tetrarchs
  ht => {
    name => 'Heavenly Tetrarchs',
    neighborhood => [
      q(o o o),
      q( 444 ),
      q(o4^4o),
      q( 444 ),
      q(o o o) ] },
  # }}}
  # {{{ Elephant King
  ek => {
    name => 'Elephant King',
    neighborhood => [
      q(  o  ),
      q( \o/ ),
      q(oo^oo),
      q( /o\ ),
      q(  o  ) ] },
  # }}}
  # {{{ Peaceful Mountain
  pm => {
    name => 'Peaceful Mountain',
    neighborhood => [
      q(  o  ),
      q( \5/ ),
      q(o5^5o),
      q( / \ ),
      q(     ) ] },
  # }}}
# }}}
# {{{ Row 2
  # {{{ Chinese River
  cr => {
    name => 'Chinese River',
    neighborhood => [
      q(     ),
      q( \o/ ),
      q( -^- ),
      q( /o\ ),
      q(     ) ] },
  # }}}
  # {{{ Violent Wind
  vwd => {
    name => 'Violent Wind',
    neighborhood => [
      q(     ),
      q( \o/ ),
      q( -^- ),
      q( /o\ ),
      q(     ) ] },
  # }}}
  # {{{ Free Chicken
  fch => {
    name => 'Free Chicken',
    neighborhood => [
      q(     ),
      q( \|/ ),
      q(oo^oo),
      q( o|o ),
      q(o   o) ] },
 # }}}
# }}}
# {{{ Row 3
  # {{{ Free Ox
  fro => {
    name => 'Free Ox',
    neighborhood => [
      q(     ),
      q( \|/ ),
      q(oo^oo),
      q( o|o ),
      q(     ) ] },
  # }}}
  # {{{ Free Horse
  fh => {
    name => 'Free Horse',
    neighborhood => [ 
      q(     ),
      q( \|/ ),
      q(oo^oo),
      q( o|o ),
      q(     ) ] },
  # }}}
  # {{{ Great Whale
  gw => {
    name => 'Great Whale',
    neighborhood => [
      q(     ),
      q( \|/ ),
      q(  ^  ),
      q( /|\ ),
      q(     ) ] },
  # }}}
# }}}
# {{{ Row 4
  # {{{ Free Pig
  fpg => {
    name => 'Free Pig',
    neighborhood => [
      q(     ),
      q( \|/ ),
      q(oo^oo),
      q( o|o ),
      q(     ) ] },
  # }}}
  # {{{ Longbow General
  lbg => {
    name => 'Longbow General',
    neighborhood => [
      q(     ),
      q( \|/ ),
      q(o5^5o),
      q(  |  ),
      q(     ) ] },
  # }}}
  # {{{ Burning General
  bug => {
    name => 'Burning General',
    neighborhood => [
      q(     ),
      q( \|/ ),
      q(o3^3o),
      q(  o  ),
      q(  o  ) ] },
  # }}}
# }}}
# }}}
# {{{ Page 234
# {{{ 234
# Shortbow General	steps 2 backward orthogonal, steps 3 left orthogonal or right orthogonal, steps 5 forward diagonal, slides forward orthogonal
# Mountain Crane		slides orthogonal or diagonal, leaps 3 then slides orthogonal or diagonal
# Rushing Boar		steps 1 left orthogonal or right orthogonal or forward orthogonal or diagonal
# 
# Sword General		steps 1 backward orthogonal, steps 3 forward orthogonal or forward diagonal
# Bird of Paradise	slides backward orthogonal or forward orthogonal or forward diagonal
# Coiled Dragon		slides backward orthogonal or forward orthogonal or backward diagonal
# 
# Bear's Eyes		steps 1 orthogonal or diagonal
# Mountain Witch		slides backward orthogonal or diagonal
# Flying Falcon		steps 1 forward orthogonal, slides diagonal
# 
# Venomous Wolf		steps 1 orthogonal or diagonal
# Spirit Turtle		leaps 3 orthogonal, slides orthogonal or diagonal
# Treasure Turtle		leaps 2 orthogonal, slides orthogonal or diagonal
# 
# 				-234-
# }}}
# {{{ Row 1
  # {{{ Shortbow General
  sbg => {
    name => 'Shortbow General',
    neighborhood => [
      q(o   o),
      q( 5|5 ),
      q(o3^3o),
      q(  o  ),
      q(  o  ) ] },
  # }}}
  # {{{ Mountain Crane
  mcr => {
    name => 'Mountain Crane',
    neighborhood => [ # XXX There were also '3o' type things overlaid here, probably redundant
      q(     ),
      q( \|/ ),
      q( -^- ),
      q( /|\ ),
      q(     ) ] },
  # }}}
  # {{{ Rushing Boar
  rbo => {
    name => 'Rushing Boar',
    neighborhood => [
      q(     ),
      q( ooo ),
      q( o^o ),
      q( o o ),
      q(     ) ] },
  # }}}
# }}}
# {{{ Row 2
  # {{{ Sword General
  swg => {
    name => 'Sword General',
    neighborhood => [
      q(o o o),
      q( 333 ),
      q(  ^  ),
      q(  o  ),
      q(     ) ] },
  # }}}
  # {{{ Bird of Paradise
  bop => {
    name => 'Bird of Paradise',
    neighborhood => [
      q(     ),
      q( \|/ ),
      q(  ^  ),
      q(  |  ),
      q(     ) ] },
  # }}}
  # {{{ Coiled Dragon
  codr => {
    name => 'Coiled Dragon',
    neighborhood => [
      q(     ),
      q(  |  ),
      q(  ^  ),
      q( /|\ ),
      q(     ) ] },
 # }}}
# }}}
# {{{ Row 3
  # {{{ Bear's Eyes
  be => {
    name => "Bear's Eyes",
    neighborhood => [
      q(     ),
      q( ooo ),
      q( o^o ),
      q( ooo ),
      q(     ) ] },
  # }}}
  # {{{ Mountain Witch
  mw => {
    name => 'Mountain Witch', # XXX
    neighborhood => [
      q(     ),
      q(     ),
      q(  ^  ),
      q( /|\ ),
      q(     ) ] },
  # }}}
  # {{{ Flying Falcon
  ffa => {
    name => 'Flying Falcon',
    neighborhood => [
      q(     ),
      q( \o/ ),
      q(  ^  ),
      q( / \ ),
      q(     ) ] },
  # }}}
# }}}
# {{{ Row 4
  # {{{ Venomous Wolf
  vwo => {
    name => 'Venomous Wolf',
    neighborhood => [
      q(     ),
      q( ooo ),
      q( o^o ),
      q( ooo ),
      q(     ) ] },
  # }}}
  # {{{ Spirit Turtle
  spt => {
    name => 'Spirit Turtle',
    neighborhood => [ [
      q(     ),
      q( \|/ ),
      q( -^- ),
      q( /|\ ),
      q(     ) ],
    [ q(  x  ),
      q(  3  ),
      q(x3^3x),
      q(  3  ),
      q(  x  ) ] ] },
  # }}}
  # {{{ Treasure Turtle
  tt => {
    name => 'Treasure Turtle',
    neighborhood => [ [
      q(     ),
      q( \|/ ),
      q( -^- ),
      q( /|\ ),
      q(     ) ],
    [ q(  x  ),
      q(     ),
      q(x ^ x),
      q(     ),
      q(  x  ) ] ] },
  # }}}
# }}}
# }}}
# {{{ Page 235
# {{{ 235
# Great Bear		steps 1 backward orthogonal or left orthogonal or right orthogonal, slides forward orthogonal or forward diagonal
# Multi-General		slides backward orthogonal or forward orthogonal or forward diagonal
# Wizard Stork		slides backward orthogonal or left orthogonal or right orthogonal or forward diagonal
# 
# Raiding Falcon		steps 1 left orthogonal or right orthogonal or forward diagonal, slides forward orthogonal
# Great Eagle		slides orthogonal or diagonal, leaps 2 then slides forward diagonal
# 
# Great Eagle is able, if the adjacent forward diagonal are occupied,
# to leap over and continue its slide until it preforms a capture.
#  
# 				-234-
# }}}
# {{{ Row 1
  # {{{ Great Bear
  gb => {
    name => 'Great Bear',
    neighborhood => [
      q(     ),
      q( \|/ ),
      q( o^o ),
      q(  o  ),
      q(     ) ] },
  # }}}
  # {{{ Multi General
  mug => {
    name => 'Multi General',
    neighborhood => [
      qw(     ),
      qw( \|/ ),
      qw(  ^  ),
      qw(  |  ),
      qw(     ) ] },
  # }}}
  # {{{ Wizard Stork
  ws => {
    name => 'Wizard Stork',
    neighborhood => [
      q(     ),
      q( \ / ),
      q( -^- ),
      q(  |  ),
      q(     ) ] },
  # }}}
# }}}
# {{{ Row 2
  # {{{ Raiding Falcon
  rf => {
    name => 'Raiding Falcon',
    neighborhood => [
      qw(     ),
      qw( o|o ),
      qw( o^o ),
      qw(     ),
      qw(     ) ] },
  # }}}
  # {{{ Great Eagle
  gea => {
    name => 'Great Eagle',
    neighborhood => [ # XXX Two redundant 'o' diagonally in front of the piece
      qw(x   x), # And the 'x' at the end of the diagonal means something diff.
      qw( \|/ ),
      qw( -^- ),
      qw( /|\ ),
      qw(     ) ] },
  # }}}
# }}}
# }}}
};
# }}}

# {{{ 4. The remaining rules:
=pod

1) Pieces promote upon reaching any of the opponent's 11 ranks.

2) Captured pieces are removed from play.

3) Free Eagle is able to capture without moving(igui) an adjacent square. With the squares marked (1)(2)(3) there are several move options
   (including the forward diagonal squares marked 4), may leap to the squares (2)(3) (up tp the fourth forward diagonal) then continue until capturing
   is one option. Another, for the squares marked (1)(2)(3) may preform consecutive capturing moves (up tp the fourth forward diagonal)
   may also preform passing move(jitto) if vacant adjacent square.

4) -|-|-|->  The meaning of this symbol is not known.  There are no references to a line with three marks.
   It is believed that this may mean that a piece may jump up to three spaces and continue its slide.

5) Great General, Vice General, Rook General, Bishop General, Violent Dragon, Flying Crocodile are equal to their counterparts in Tenjiku Shogi.  The pieces are able to leap over
   others according to rank.   By jumping over any number of lower ranked pieces, including friend and foe, continuing until making a capture.
   What follows is the ranking of these pieces. *
   (1) King, Crown Prince (2) Great General (3) Vice General (4) Bishop General, Rook General, Violent Dragon, Flying Crocodile
   (5) the other pieces

[*Some sources note that the ranging move can involve the capture of each and every piece, both friend and foe, which the ranging piece leaps.]
=cut
# }}}

# {{{ Initial Set-up 
=pod
(Rank and position in relation to the lower left hand corner of the playing field.)

PIECE			RANK		POSITION(S)
------------------------------------------------------
# {{{ rank 1
King			1		18
Crown Prince		1		19
Gold General		1		17, 20
Right General		1		21
Left General		1		16
Rear Standard		1		15, 22
Free King		1		14, 23
Free Tapir		1		13, 24
Wooden Dove		1		25
Ceramic Dove		1		12
Earth Dragon		1		11, 26
Free Demon		1		10, 27
Running Horse		1		9, 28
Beast Cadet		1		8, 29
Long-Nosed Goblin	1		7, 30
Mountain Eagle		1		6, 31
Fire Demon		1		5, 32
Whale			1		4, 33
Running Rabbit		1		3, 34
White Tiger		1		35
Turtle Snake	 	1		2
Lance			1		1, 36
# }}}
# {{{ rank 2
Reverse Chariot		2		1, 36
Fragrant Elephant	2		35
White Elephant		2		2
Mountain Dove		2		3, 34
Flying Swallow		2		4, 33
Captive Officer		2		5, 32
Rain Dragon		2		6, 31
Forest Demon		2		7, 30
Mountain Stag		2		8, 29
Running Pup		2		9, 28
Running Serpent		2		10, 27
Side Serpent		2		11, 26
Great Dove		2		12, 25
Running Tiger		2		13, 24
Running Bear		2		14, 23
Night Sword		2		22
Buddhist Devil		2		15
Guardian of the Gods	2		21
Wrestler		2		16
Silver General		2		17, 20
Drunk Elephant		2		19
Neighboring King	2		18
# }}}
# {{{ rank 3
Gold Chariot		3		1, 36
Side Dragon		3		2, 35
Running Stag		3		3, 34
Running Wolf		3		4, 33
Bishop General		3		5, 32
Rook General		3		6, 31
Right Tiger		3		30
Left Tiger		3		7
Right Dragon		3		29
Left Dragon		3		8
Beast Officer		3		9, 28
Wind Dragon		3		10, 27
Free Pup		3		11, 26
Rushing Bird		3		12, 25
Old Kite Hawk		3		13, 24
Peacock			3		14, 23
Water Dragon		3		15, 22
Fire Dragon		3		16, 21
Copper General		3		17, 20
Phoenix Master		3		19
Kylin Master		3		18
# }}}
# {{{ rank 4
Silver Chariot		4		1, 36
Vertical Bear		4		2, 35
Knight			4		3, 34
Pig General		4		4, 33
Chicken General		4		5, 32
Pup General		4		6, 31
Horse General		4		7, 30
Ox General		4		8, 29
Center Standard		4		9, 28
Side Boar		4		10, 27
Silver Rabbit		4		11, 26
Golden Deer		4		12, 25
Lion			4		13, 24
Captive Cadet		4		14, 23
Great Stag		4		15, 22
Violent Dragon		4		16, 21
Woodland Demon		4		17, 20
Vice General		4		19
Great General		4		18
# }}}
# {{{ rank 5
Stone Chariot		5		1, 36
Cloud Eagle		5		2, 35
Bishop			5		3, 34
Rook			5		4, 33
Side Wolf		5		5, 32
Flying Cat		5		6, 31
Mountain Falcon		5		7, 30
Vertical Tiger		5		8, 29
Soldier			5		9, 28
Little Standard		5		10, 27
Cloud Dragon		5		11, 26
Copper Chariot		5		12, 25
Running Chariot		5		13, 24
Ramshead Soldier	5		14, 23
Violent Ox		5		15, 22
Great Dragon		5		16, 21
Golden Bird		5		17, 20
Dark Spirit		5		19
Deva			5		18
# }}}
# {{{ rank 6
Wood Chariot		6		1, 36
White Horse		6		2, 35
Howling Dog (Right)	6		34
Howling Dog (Left)	6		3
Side Mover		6		4, 33
Prancing Stag		6		5, 32
Water Buffalo		6		6, 31
Ferocious Leopard	6		7, 30
Fierce Eagle		6		8, 29
Flying Dragon		6		9, 28
Poisonous Snake		6		10, 27
Flying Goose		6		11, 26
Strutting Crow		6		12, 25
Blind Dog		6		13, 24
Water General		6		14, 23
Fire General		6		15, 22
Phoenix			6		21
Kylin			6		16
Hook Mover		6		20
Little Turtle		6		19
Great Turtle		6		18
Capricorn		6		17
# }}}
# {{{ rank 7
Tile Chariot		7		1, 36
Vertical Wolf		7		2, 35
Side Ox			7		3, 34
Donkey			7		4, 33
Flying Horse		7		5, 32
Violent Bear		7		6, 31
Angry Boar		7		7, 30
Evil Wolf		7		8, 29
Liberated Horse		7		9, 28
Flying Cock		7		10, 27
Old Monkey		7		11, 26
Chinese Cock		7		12, 25
Northern Barbarian	7		24
Southern Barbarian	7		23
Western Barbarian	7		13
Eastern Barbarian	7		14
Violent Stag		7		15, 22
Violent Wolf		7		16, 21
Treacherous Fox		7		17, 20
Center Master		7		19
Roc Master		7		18
# }}}
# {{{ rank 8
Earth Chariot		8		1, 36
Vermillion Sparrow	8		35
Blue Dragon		8		2
Enchanted Badger	8		3, 34
Horseman		8		4, 33
Swooping Owl		8		5, 32
Climbing Monkey		8		6, 31
Cat Sword		8		7, 30
Swallow's Wings		8		8, 29
Blind Monkey		8		9, 28
Blind Tiger		8		10, 27
Ox Cart			8		11, 26
Side Flier		8		12, 25
Blind Bear		8		13, 24
Old Rat			8		14, 23
Square Mover		8		15, 22
Coiled Serpent		8		16, 21
Reclining Dragon	8		17, 20
Free Eagle		8		19
Lion Hawk		8		18
# }}}
# {{{ rank 9
Chariot Soldier		9		1, 36
Side Soldier		9		2, 35
Vertical Soldier	9		3, 34
Wind General		9		4, 33
River General		9		5, 32
Mountain General	9		6, 31
Front Standard		9		7, 30
Horse Soldier		9		8, 29
Wood General		9		9, 28
Ox Soldier		9		10, 27
Earth General		9		11, 26
Boar Soldier		9		12, 25
Stone General		9		13, 24
Leopard Soldier		9		14, 23
Tile General		9		15, 22
Bear Soldier		9		16, 21
Iron General		9		17, 20
Great Master		9		18
Great Standard		9		19
# }}}
# {{{ rank 10
Right Chariot		10		36
Left Chariot		10		1
Side Monkey		10		2, 35
Vertical Mover		10		3, 34
Flying Ox		10		4, 33
Longbow Soldier		10		5, 32
Vertical Pup		10		6, 31
Vertical Horse		10		7, 30
Burning Soldier		10		8, 29
Dragon Horse		10		9, 28
Dragon King		10		10, 27
Sword Soldier		10		11, 26
Horned Falcon		10		12, 25
Soaring Eagle		10		13, 24
Spear Soldier		10		14, 23
Vertical Leopard	10		15, 22
Savage Tiger		10		16, 21
Shortbow Soldier	10		17, 20
Roaring Dog		10		19
Lion Dog		10		18
# }}}
# {{{ rank 11
Pawn			11		1 through 36
# }}}
# {{{ rank 12
Dog			12		6, 15, 22, 31, 
Go-Between		12		11, 26
# }}}
=cut
# }}}

# {{{ English transcription by L. Lynn Smith.
=pod

Special Thanks to Patrick Davin, whose work on these documents was of great assistance.

Also Thanks to Luke Merrit, Colin Paul Adams, Michael Vanier and others who contributed in
early discussion groups.

Send all comments to: llsmith@ev1.net
--------------------------------------------------------------------------------

Ultimate Shogi (Taikyoku Shogi)

An ancient shogi with even more pieces than Mujotai Shogi, Taikyoku Shogi is
thought to be the most recent of the large ancient shogis, although its
existence is not widely known.

# {{{ 1.	Board
	The board is a 36X36 grid, with 11 ranks for each player's position.    
# }}}

# {{{ 2.	Pieces
	The pieces are shaped like other Japanese Shogi pieces, five-sided with the Kanji characters of the names written on them. (The promoted value appears on the reverse side.)
	Each player starts the game with 402 pieces.  The various pieces are listed below.

King		each player receives	1 ea. does not promote.
Crown Prince		"		1 ea. promotes to King.
Gold General		" 		2 ea. promotes to Rook.
Right General		"		1 ea. promotes to Right Army.
Left General		"		1 ea. promotes to Left Army.
Rear Standard		"		2 ea. promotes to Center Standard.
Free King		"		2 ea. promotes to Great General.
Free Tapir		"		2 ea. promotes to Free King.
Wooden Dove		"		1 ea. does not promote.
Ceramic Dove		"		1 ea. does not promote.
Earth Dragon		"		2 ea. promotes to Rain Dragon.
Free Demon		"		2 ea. promotes to Free King.
Running Horse		"		2 ea. promotes to Free Demon.
Beast Cadet		"		2 ea. promotes to Beast Officer.
Long-Nosed Goblin	"		2 ea. does not promote.
Mountain Eagle		"		2 ea. promotes to Soaring Eagle.
Fire Demon		"		2 ea. promotes to Free Fire.
Whale			"		2 ea. promotes to Great Whale.
Running Rabbit		"		2 ea. promotes to Treacherous Fox.
White Tiger		"		1 ea. promotes to Divine Tiger.
Turtle Snake	 	"		1 ea. promotes to Divine Turtle.
Lance			"		2 ea. promotes to White Horse.

                                 -203-
--------------------------------------------------------------------------------

Reverse Chariot		"		2 ea. promotes to Whale.
Fragrant Elephant	"		1 ea. promotes to Elephant King.
White Elephant		"		1 ea. promotes to Elephant King.
Mountain Dove		"		2 ea. promotes to Great Dove.
Flying Swallow		"		2 ea. promotes to Rook.
Captive Officer		"		2 ea. promotes to Captive Bird.
Rain Dragon		"		2 ea. promotes to Great Dragon.
Forest Demon		"		2 ea. promotes to Thunder Runner.
Mountain Stag		"		2 ea. promotes to Great Stag.
Running Pup		"		2 ea. promotes to Free Leopard.
Running Serpent		"		2 ea. promotes to Free Serpent.
Side Serpent		"		2 ea. promotes to Shark.
Great Dove		"		2 ea. promotes to Wooden Dove.
Running Tiger		"		2 ea. promotes to Free Tiger.
Running Bear		"		2 ea. promotes to Free Bear.
Night Sword		"		1 ea. promotes to Heavenly Tetarch.
Buddhist Devil		"		1 ea. promotes to Heavenly Tetarch.
Guardian of the Gods	"		1 ea. promotes to Heavenly Tetarch.
Wrestler		"		1 ea. promotes to Heavenly Tetarch.
Silver General		"		2 ea. promotes to Vertical Mover.
Drunk Elephant		"		1 ea. promotes to Crown Prince.
Neighboring King	"		1 ea. promotes to Front Standard.
Gold Chariot		"		2 ea. promotes to Playful Cockatoo.
Side Dragon		"		2 ea. promotes to Running Dragon.
Running Stag		"		2 ea. promotes to Free Stag.
Running Wolf		"		2 ea. promotes to Free Wolf.
Bishop General		"		2 ea. promotes to Rain Demon.
Rook General		"		2 ea. promotes to Flying Crocodile.
Right Tiger		"		1 ea. promotes to White Tiger.
Left Tiger		"		1 ea. promotes to Turtle Snake.

                                 -204-
--------------------------------------------------------------------------------

Right Dragon		"		1 ea. promotes to Blue Dragon.
Left Dragon		"		1 ea. promotes to Vermillion Sparrow.
Beast Officer		"		2 ea. promotes to Beast Bird.
Wind Dragon		"		2 ea. promotes to Free Dragon.
Free Pup		"		2 ea. promotes to Free Dog.
Rushing Bird		"		2 ea. promotes to Free Demon.
Old Kite Hawk		"		2 ea. promotes to Long-Nosed Goblin.
Peacock			"		2 ea. promotes to Long-Nosed Goblin.
Water Dragon		"		2 ea. promotes to Phoenix Master.
Fire Dragon		"		2 ea. promotes to Kylin Master.
Copper General		"		2 ea. promotes to Side Mover.
Phoenix Master		"		1 ea. does not promote.
Kylin Master		"		1 ea. does not promote.
Silver Chariot		"		2 ea. promotes to Goose Wing.
Vertical Bear		"		2 ea. promotes to Free Bear.
Knight			"		2 ea. promotes to Side Soldier.
Pig General		"		2 ea. promotes to Free Pig.
Chicken General		"		2 ea. promotes to Free Chicken.
Pup General		"		2 ea. promotes to Free Pup.
Horse General		"		2 ea. promotes to Free Horse.
Ox General		"		2 ea. promotes to Free Ox.
Center Standard		"		2 ea. promotes to Front Standard.
Side Boar		"		2 ea. promotes to Free Boar.
Silver Rabbit		"		2 ea. promotes to Whale.
Golden Deer		"		2 ea. promotes to White Horse.
Lion			"		2 ea. promotes to Furious Fiend.
Captive Cadet		"		2 ea. promotes to Captive Officer.
Great Stag		"		2 ea. promotes to Free Stag.
Violent Dragon		"		2 ea. promotes to Great Dragon.
Woodland Demon		"		2 ea. promotes to Right Phoenix.

                                 -205-
--------------------------------------------------------------------------------

Vice General		"		1 ea. promotes to Great General.
Great General		"		1 ea. does not promote.
Stone Chariot		"		2 ea. promotes to Walking Heron.
Cloud Eagle		"		2 ea. promotes to Strong Eagle.
Bishop			"		2 ea. promotes to Dragon Horse.
Rook			"		2 ea. promotes to Dragon King.
Side Wolf		"		2 ea. promotes to Free Wolf.
Flying Cat		"		2 ea. promotes to Rook.
Mountain Falcon		"		2 ea. promotes to Horned Falcon.
Vertical Tiger		"		2 ea. promotes to Free Tiger.
Soldier			"		2 ea. promotes to Cavalier.
Little Standard		"		2 ea. promotes to Rear Standard.
Cloud Dragon		"		2 ea. promotes to Great Dragon.
Copper Chariot		"		2 ea. promotes to Copper Elephant.
Running Chariot		"		2 ea. promotes to Burning Chariot.
Ramshead Soldier	"		2 ea. promotes to Tiger Soldier.
Violent Ox		"		2 ea. promotes to Flying Ox.
Great Dragon		"		2 ea. promotes to Ancient Dragon.
Golden Bird		"		2 ea. promotes to Free Bird.
Dark Spirit		"		1 ea. promotes to Buddhist Spirit.
Deva			"		1 ea. promotes to Teaching King.
Wood Chariot		"		2 ea. promotes to Wind Snapping Turtle.
White Horse		"		2 ea. promotes to Great Horse.
Howling Dog (Right)	"		1 ea. promotes to Right Dog.
Howling Dog (Left)	"		1 ea. promotes to Left Dog.
Side Mover		"		2 ea. promotes to Free Boar.
Prancing Stag		"		2 ea. promotes to Square Mover.
Water Buffalo		"		2 ea. promotes to Great Tapir.
Ferocious Leopard	"		2 ea. promotes to Bishop.
Fierce Eagle		"		2 ea. promotes to Soaring Eagle.

                                 -206-
--------------------------------------------------------------------------------

Flying Dragon		"		2 ea. promotes to Dragon King.
Poisonous Snake		"		2 ea. promotes to Hook Mover.
Flying Goose		"		2 ea. promotes to Dragon King.
Strutting Crow		"		2 ea. promotes to Flying Falcon.
Blind Dog		"		2 ea. promotes to Violent Stag.
Water General		"		2 ea. promotes to Vice General.
Fire General		"		2 ea. promotes to Great General.
Phoenix			"		1 ea. promotes to Golden Bird.
Kylin			"		1 ea. promotes to Golden Bird.
Hook Mover		"		1 ea. does not promote.
Little Turtle		"		1 ea. promotes to Treasure Turtle.
Great Turtle		"		1 ea. promotes to Spirit Turtle.
Capricorn		"		1 ea. promotes to Hook Mover.
Tile Chariot		"		2 ea. promotes to Running Tile.
Vertical Wolf		"		2 ea. promotes to Running Wolf.
Side Ox			"		2 ea. promotes to Flying Ox.
Donkey			"		2 ea. promotes to Ceramic Dove
Flying Horse		"		2 ea. promotes to Free King.
Violent Bear		"		2 ea. promotes to Great Bear.
Angry Boar		"		2 ea. promotes to Free Boar.
Evil Wolf		"		2 ea. promotes to Venomous Wolf.
Liberated Horse		"		2 ea. promotes to Heavenly Horse.
Flying Cock		"		2 ea. promotes to Raiding Falcon.
Old Monkey		"		2 ea. promotes to Mountain Witch.
Chinese Cock		"		2 ea. promotes to Wizard Stork.
Northern Barbarian	"		1 ea. promotes to Wooden Dove.
Southern Barbarian	"		1 ea. promotes to Golden Bird.
Western Barbarian	"		1 ea. promotes to Lion Dog.
Eastern Barbarian	"		1 ea. promotes to Lion.
Violent Stag		"		2 ea. promotes to Rushing Boar.

                                 -207-
--------------------------------------------------------------------------------

Violent Wolf		"		2 ea. promotes to Bear's Eyes.
Treacherous Fox		"		2 ea. promotes to Mountain Crane.
Center Master		"		1 ea. does not promote.
Roc Master		"		1 ea. does not promote.
Earth Chariot		"		2 ea. promotes to Young Bird.
Vermillion Sparrow	"		1 ea. promotes to Divine Sparrow.
Blue Dragon		"		1 ea. promotes to Divine Dragon.
Enchanted Badger	"		2 ea. promotes to Ceramic Dove.
Horseman		"		2 ea. promotes to Cavalier.
Swooping Owl		"		2 ea. promotes to Cloud Eagle.
Climbing Monkey		"		2 ea. promotes to Violent Stag.
Cat Sword		"		2 ea. promotes to Dragon Horse.
Swallow's Wings		"		2 ea. promotes to Gliding Swallow.
Blind Monkey		"		2 ea. promotes to Flying Stag.
Blind Tiger		"		2 ea. promotes to Flying Stag.
Ox Cart			"		2 ea. promotes to Plodding Ox.
Side Flier		"		2 ea. promotes to Side Dragon.
Blind Bear		"		2 ea. promotes to Flying Stag.
Old Rat			"		2 ea. promotes to Bird of Paradise.
Square Mover		"		2 ea. promotes to Strong Chariot.
Coiled Serpent		"		2 ea. promotes to Coiled Dragon.
Reclining Dragon	"		2 ea. promotes to Great Dragon.
Free Eagle		"		1 ea. does not promote.
Lion Hawk		"		1 ea. does not promote.
Chariot Soldier		"		2 ea. promotes to Heavenly Tetarch King.
Side Soldier		"		2 ea. promotes to Water Buffalo.
Vertical Soldier	"		2 ea. promotes to Chariot Soldier.
Wind General		"		2 ea. promotes to Violent Wind.
River General		"		2 ea. promotes to Chinese River.
Mountain General	"		2 ea. promotes to Peaceful Mountain.

                                 -208-
--------------------------------------------------------------------------------

Front Standard		"		2 ea. promotes to Great Standard.
Horse Soldier		"		2 ea. promotes to Running Horse.
Wood General		"		2 ea. promotes to White Elephant.
Ox Soldier		"		2 ea. promotes to Running Ox.
Earth General		"		2 ea. promotes to White Elephant.
Boar Soldier		"		2 ea. promotes to Running Boar.
Stone General		"		2 ea. promotes to White Elephant.
Leopard Soldier		"		2 ea. promotes to Running Leopard.
Tile General		"		2 ea. promotes to White Elephant.
Bear Soldier		"		2 ea. promotes to Strong Bear.
Iron General		"		2 ea. promotes to White Elephant.
Great Standard		"		1 ea. does not promote.
Great Master		"		1 ea. does not promote.
Right Chariot		"		1 ea. promotes to Right Iron Chariot.
Left Chariot		"		1 ea. promotes to Left Iron Chariot.
Side Monkey		"		2 ea. promotes to Side Soldier.
Vertical Mover		"		2 ea. promotes to Flying Ox.
Flying Ox		"		2 ea. promotes to Fire Ox.
Longbow Soldier		"		2 ea. promotes to Longbow General.
Vertical Pup		"		2 ea. promotes to Leopard King.
Vertical Horse		"		2 ea. promotes to Dragon Horse.
Burning Soldier		"		2 ea. promotes to Burning General.
Dragon Horse		"		2 ea. promotes to Horned Falcon.
Dragon King		"		2 ea. promotes to Soaring Eagle.
Sword Soldier		"		2 ea. promotes to Sword General.
Horned Falcon		"		2 ea. promotes to Great Falcon.
Soaring Eagle		"		2 ea. promotes to Great Eagle.
Spear Soldier		"		2 ea. promotes to Spear General.
Vertical Leopard	"		2 ea. promotes to Great Leopard.
Savage Tiger		"		2 ea. promotes to Great Tiger.

                                 -209-
--------------------------------------------------------------------------------

Shortbow Soldier	"		2 ea. promotes to Shortbow General.
Roaring Dog		"		1 ea. promotes to Lion Dog.
Lion Dog		"		1 ea. promotes to Great Elephant.
Dog			"		4 ea. promotes to Multi-General.
Go-Between		"		2 ea. promotes to Drunk Elephant.
Pawn			"	       36 ea. promotes to Tokin.
# }}}

# {{{ 3.  The Moves of the Pieces.

    A 5 and a circle indicates that the piece may step up to five spaces in that direction.   An X indicates
    that the piece may jump in that direction.  3 X would mean that the piece may jump to the third space in that direction.   The solid arrow indicates a slide move.
    The dotted arrow indicates Ranging moves similar to Tenjiku Shogi, the ranking will be covered at the end of this document. 

King			steps 2 orthogonal or diagonal
Crown Prince		steps 1 orthogonal or diagonal
Gold General		steps 1 orthogonal or forward diagonal

Right General		steps 1 orthogonal or diagonal
Left General		steps 1 orthogonal or diagonal
Rear Standard		steps 2 diagonal, slides orthogonal

Free King		slides orthogonal or diagonal
Free Tapir		steps 5 left orthogonal or right orthogonal, slides forward orthogonal or backward orthogonal or diagonal
Wooden Dove		steps 2 orthogonal, slides diagonal

Wooden Dove, in addition to the normal diagonal slide, may leap 3 spaces (diagonally) then step 2 (diagonally).

				-210-
--------------------------------------------------------------------------------

Earth Dragon		steps 1 forward diagonal or backward orthogonal, steps 2 forward orthogonal, slides backward diagonal
Free Demon		steps 5 forward orthogonal or backward orthogonal, slides left orthogonal or right orthogonal or diagonal
Running Horse		steps 1 backward orthogonal, leaps to the second backward diagonal, slides forward orthogonal or forward diagonal

Beast Cadet		steps 2 forward orthogonal or left orthogonal or right orthogonal or diagonal
Long-Nosed Goblin	diagonal hook-move
Mountain Eagle(Right)	steps 2 left backward diagonal, leaps 2 right diagonal, slides orthogonal or right diagonal or left forward diagonal

Mountain Eagle(Left)	steps 2 right backward diagonal, leaps 2 left diagonal, slides orthogonal or left diagonal or right forward diagonal
Fire Demon		steps 2 forward orthogonal or backward orthogonal, slides left orthogonal or right orthogonal or diagonal
Whale			slides foward orthogonal or backward orthogonal or backward diagonal

Running Rabbit		steps 1 backward orthogonal or backward diagonal, slides forward orthogonal or forward diagonal
White Tiger		steps 2 forward orthogonal or backward orthgonal, slides left orthogonal or right orthogonal or left forward diagonal
Turtle Snake		steps 1 orthogonal or left forward diagonal or right backward diagonal, slides right forward diagonal or left backward diagonal

				-211-
--------------------------------------------------------------------------------

Ceramic Dove		steps 2 orthogonal, slides diagonal
Lance			slides forward orthogonal
Reverse Chariot		slides forward orthogonal or backward orthogonal

Fragrant Elephant	steps 2 orthogonal or diagonal
White Elephant		steps 2 orthogonal or diagonal
Mountain Dove		steps 1 left orthogonal or right orthogonal or backward orthogonal, steps 5 forward diagonal

Flying Swallow		steps 1 backward orthogonal, slides forward diagonal
Captive Officer		steps 2 forward orthogonal or left orthogonal or right orthogonal, steps 3 diagonal
Rain Dragon		steps 1 forward orthogonal or forward diagonal, slides left orthogonal or right orthogonal or backward orthogonal or backward diagonal

Forest Demon		steps 3 forward orthogonal or left orthogonal or right orthogonal, slides backward orthogonal or forward diagonal
Mountian Stag		steps 1 forward orthogonal, steps 2 left orthogonal or right orthogonal, steps 3 forward diagonal, step 4 backward orthogonal
Running Pup		steps 1 left orthogonal or right orthogonal, slides forward orthogonal or backward orthogonal

				-212-
--------------------------------------------------------------------------------

Running Serpent		steps 1 left orthogonal or right orthogonal, slides forward orthogonal or backward orthogonal
Side Serpent		steps 1 backward orthogonal, steps 3 forward orthogonal, slides left orthogonal or right orthogonal
Great Dove		steps 3 orthogonal, slides diagonal

Running Tiger		steps 2 left orthogonal or right orthogonal, slides backward orthogonal or forward orthogonal
Running Bear		steps 2 left orthogonal or right orthogonal, slides backward orthogonal or forward orthogonal
Night Sword		steps 1 backward orthogonal or forward diagonal, steps 3 left orthogonal or right orthogonal

Buddhist Devil		steps 1 backward orthogonal or left orthogonal or right orthogonal, steps 3 forward diagonal
Guardian of the Gods	steps 3 orthogonal
Wrestler		steps 3 diagonal

Silver General		steps 1 forward orthogonal or diagonal
Drunk Elephant		steps 1 forward orthogonal or left orthogonal or right orthogonal or diagonal
Neighboring King	steps 1 forward orthogonal or left orthogonal or right orthogonal or diagonal

				-213-
--------------------------------------------------------------------------------

Gold Chariot		steps 1 diagonal, steps 2 left orthogonal or right orthogonal, slides forward orthogonal or backward orthogonal
Side Dragon		slides forward orthogonal or left orthogonal or right orthogonal
Running Stag		steps 2 backward orthogonal, slides left orthogonal or right orthogonal or forward diagonal

Running Wolf		steps 1 forward orthogonal, slides left orthogonal or right orthogonal or forward diagonal
Bishop General		range jump diagonal(ranking noted at end of document)
Rook General		range jump orthogonal(ranking noted at end of document)

Right Tiger		steps 1 right diagonal, slides left orthogonal or left diagonal
Left Tiger		steps 1 left diagonal, slides right orthogonal or right diagonal
Right Dragon		steps 2 right orthogonal, slides left orthogonal or left diagonal

Left Dragon		steps 2 left orthogonal, slides right orthogonal or right diagonal
Beast Officer		steps 2 left orthogonal or right orthogonal, steps 3 forward orthogonal or diagonal
Wind Dragon		steps 1 left backward diagonal, slides left orthogonal or right orthogonal or right backward diagonal or forward diagonal

				-214-
--------------------------------------------------------------------------------

Free Pup		steps 1 backward diagonal, steps 2 left orthogonal or right orthogonal, slides backward orthogonal or forward orthogonal or forward diagonal
Rushing Bird		steps 1 left orthogonal or right orthogonal or diagonal, steps 2 forward orthogonal
Old Kite Hawk		steps 1 left orthogonal or right orthogonal, steps 2 diagonal

Peacock			steps 2 backward diagonal, forward diagonal hook-move
Water Dragon		steps 2 forward diagonal, steps 4 backward diagonal, slides orthogonal
Fire Dragon		steps 2 backward diagonal, steps 4 forward diagonal, slides orthogonal

Copper General		steps 1 backward orthogonal or forward orthogonal or forward diagonal
Phoenix Master		steps 3 left orthogonal or right orthogonal or forward diagonal, slides backward orthogonal or forward orthogonal or backward diagonal, leaps 3 then slides forward diagonal
Kylin Master		steps 3 backward orthogonal or forward orthogonal or left orthogonal or right orthogonal , slides diagonal, leaps 3 then slides backward orthogonal or forward orthogonal

Silver Chariot		steps 1 backward diagonal, steps 2 forward diagonal, slides backward orthogonal or forward orthogonal
Vertical Bear		steps 1 backward orthogonal, steps 2 left orthogonal or right orthogonal, slides forward orthogonal
Knight			leaps 1 forward orthogonal then 1 forward diagonal

				-215-
--------------------------------------------------------------------------------

Pig General		steps 2 backward orthogonal, steps 4 forward diagonal
Chicken General		steps 1 backward diagonal, steps 4 forward orthogonal
Pup General		steps 1 backward diagonal, steps 4 forward orthogonal

Horse General		steps 1 backward orthogonal or forward diagonal, steps 3 forward orthogonal
Ox General		steps 1 backward orthogonal or forward diagonal, steps 3 forward orthogonal
Center Standard		steps 3 diagonal, slides orthogonal

Side Boar		steps 1 backward orthogonal or forward orthogonal or diagonal, slides left orthogonal or right orthogonal
Silver Rabbit		steps 2 forward diagonal, slides backward diagonal
Golden Deer		steps 2 backward diagonal, slides forward diagonal

Lion			2-space Lion move
Captive Cadet		steps 3 left orthogonal or right orthogonal or forward orthogonal or diagonal
Great Stag		steps 2 backward diagonal, leaps 2 forward diagonal, slides orthogonal

	The Lion moves similar to its counterpart in Chu Shogi.

				-216-
--------------------------------------------------------------------------------

Violent Dragon		steps 2 orthogonal, range jump diagonal(ranking noted at end of document)
Woodland Demon		steps 2 left orthogonal or right orthogonal or backward diagonal, slides backward orthogonal or forward orthogonal or forward diagonal
Vice General		leaps 2 orthogonal, range jump diagonal(ranking noted at end of document)

Great General		range jump orthogonal or diagonal(ranking noted at end of document)
Stone Chariot		steps 1 forward diagonal, steps 2 left orthogonal or right orthogonal, slides backward orthogonal or forward orthogonal
Cloud Eagle		steps 1 left orthogonal or right orthogonal, steps 3 forward diagonal, slides backward orthogonal or forward orthogonal

Bishop			slides diagonal
Rook			slide orthogonal
Side Wolf		steps 1 left forward diagonal or right backward diagonal, slides left orthogonal or right orthogonal

Flying Cat		steps 1 backward orthogonal or backward diagonal, leaps 3 left orthogonal or right orthogonal or forward orthogonal or forward diagonal
Mountain Falcon		steps 2 forward orthogonal or backward diagonal, slides backward orthogonal or left orthogonal or right orthogonal or forward diagonal, leaps 2 then slides forward orthogonal
Vertical Tiger		steps 2 backward orthogonal, slides forward orthogonal

				-217-
--------------------------------------------------------------------------------

Soldier			slides orthogonal
Little Standard		steps 1 backward diagonal, steps 2 forward diagonal, slides orthogonal
Cloud Dragon		steps 1 left orthogonal or right orthogonal or forward orthogonal, slides diagonal or backward orthogonal

Copper Chariot		steps 3 forward diagonal, slides backward orthogonal or forward orthogonal
Running Chariot		slides orthogonal
Ramshead Soldier	steps 1 backward orthogonal, slides forward diagonal

Violent Ox		steps 1 backward orthogonal or forward orthogonal, slides forward diagonal
Great Dragon		steps 3 backward orthogonal or forward orthogonal, slides diagonal
Golden Bird		steps 3 left orthogonal or right orthogonal or backward diagonal, slides backward orthogonal or forward orthogonal, hash-marked slides forward diagonal

Dark Spirit		steps 1 orthogonal or backward diagonal or right forward diagonal
Deva			steps 1 orthogonal or backward diagonal or left forward diagonal
Wood Chariot		steps 1 left forward diagonal or right backward diagonal, slides backward orthogonal or forward orthogonal

				-218-
--------------------------------------------------------------------------------

White Horse		slides backward orthogonal or forward orthogonal or forward diagonal
Howling Dog(Right)	steps 1 backward orthogonal, slides forward orthogonal
Howling Dog(Left)	steps 1 backward orthogonal, slides forward orthogonal

Side Mover		steps 1 backward orthogonal or forward orthogonal, slide left orthogonal or right orthogonal
Prancing Stag		steps 1 backward orthogonal or forward orthogonal or forward diagonal, steps 2 left orthogonal or right orthogonal
Water Buffalo		steps 2 backward orthogonal or forward orthogonal, slides left orthogonal or right orthogonal or diagonal

Ferocious Leopard	steps 1 backward orthogonal or forward orthogonal or diagonal
Fierce Eagle		steps 1 left orthogonal or right orthogonal or forward orthogonal, steps 2 diagonal
Flying Dragon		leaps 2 diagonal

Poisonous Snake		steps 1 backward orthogonal or forward diagonal, steps 2 left orthogonal or right orthogonal or forward orthogonal
Flying Goose		steps 1 backward orthogonal or forward orthogonal or forward diagonal
Strutting Crow		steps 1 backward diagonal or forward orthogonal

				-219-
--------------------------------------------------------------------------------

Blind Dog		steps 1 backward orthogonal or left orthogonal or right orthogonal or forward diagonal
Water General		steps 1 backward orthogonal or forward orthogonal, steps 3 forward diagonal
Fire General		steps 1 forward diagonal, steps 3 backward orthogonal or forward orthogonal

Phoenix			steps 1 orthogonal, leaps 2 diagonal
Kylin			steps 1 backward orthogonal or forward orthogonal or diagonal, leaps 2 left orthogonal or right orthogonal
Hook Mover		orthogonal hook-move


Little Turtle		steps 2 left orthogonal or right orthogonal, leaps 2 backward orthogonal or forward orthogonal, slides backward orthogonal or forward orthogonal or diagonal
Great Turtle		steps 3 left orthogonal or right orthogonal, leaps 3 bakcward orthogonal or forward orthogonal, slides backward orthogonal or forward orthogonal or diagonal
Capricorn		diagonal hook-move


Tile Chariot		steps 1 left backward diagonal or right forward diagonal, slides backward orthogonal or forward orthogonal
Vertical Wolf		steps 1 left orthogonal or right orthogonal, steps 3 backward orthogonal, slides forward orthogonal
Side Ox			steps 1 left backward diagonal or right forward diagonal, slides left orthogonal or right orthogonal

				-220-
--------------------------------------------------------------------------------

Donkey			steps 2 orthogonal
Flying Horse		steps 2 diagonal
Angry Boar		steps 1 left orthogonal or right orthogonal or forward orthogonal, steps 2 forward diagonal

Violent Bear		steps 1 left orthogonal or right orthogonal or diagonal
Evil Wolf		steps 1 left orthogonal or right orthogonal or forward orthogonal or forward diagonal
Liberated Horse		steps 1 forward diagonal, steps 2 backward orthogonal, slides forward orthogonal

Flying Cock		steps 1 left orthogonal or right orthogonal or forward diagonal
Old Monkey		steps 1 backward orthogonal or diagonal
Chinese Cock		steps 1 backward orthogonal or left orthogonal or right orthogonal or forward diagonal

Northern Barbarian	steps 1 backward orthogonal or forward orthogonal or forward diagonal, steps 2 left orthogonal or right orthogonal
Southern Barbarian	steps 1 backward orthogonal or forward orthogonal or forward diagonal, steps 2 left orthogonal or right orthogonal
Western Barbarian	steps 1 left orthogonal or right orthogonal or forward diagonal, steps 2 backward orthogonal or forward orthogonal

				-221-
--------------------------------------------------------------------------------

Eastern Barbarian	steps 1 left orthogonal or right orthogonal or forward diagonal, steps 2 backward orthogonal or forward orthogonal
Violent Stag		steps 1 forward orthogonal or diagonal
Violent Wolf		steps 1 orthogonal or forward diagonal

Treacherous Fox		slides or leaps 2 or 3 then slides backward orthogonal or forward orthogonal or diagonal
Center Master		steps 3 left orthogonal or right orthogonal or backward diagonal, slides or leaps 2 and slides backward orthogonal or forward orthogonal or forward diagonal
Roc Master		steps 5 left orthogonal or right orthogonal or backward diagonal, slides backward orthogonal or forward orthogonal, slides or leaps 3 and slides forward diagonal

Earth Chariot		steps 1 left orthogonal or right orthogonal, slides backward orthogonal or forward orthogonal
Vermillion Sparrow	steps 1 orthogonal or left backward diagonal or right forward diagonal, slides left forward diagonal or right backward diagonal
Blue Dragon		steps 2 left orthogonal or right orthogonal, slides backward orthogonal or forward orthogonal or right forward diagonal

Enchanted Badger	steps 2 orthogonal
Horseman		steps 2 left orthogonal or right orthogonal, slides backward orthogonal or forward orthogonal or forward diagonal
Swooping Owl		steps 1 forward orthogonal or backward diagonal

				-222-
--------------------------------------------------------------------------------

Climbing Monkey		steps 1 backward orthogonal or forward orthogonal or forward diagonal
Cat Sword		steps 1 diagonal
Swallow's Wings		steps 1 backward orthogonal or forward orthogonal, slides left orthogonal or right orthogonal

Blind Monkey		steps 1 left orthogonal or right orthogonal or diagonal
Blind Tiger		steps 1 backward orthogonal or left orthogonal or right orthogonal or diagonal
Ox Cart			slides forward orthogonal

Side Flyer		steps 1 diagonal, slides left orthogonal or right orthogonal
Blind Bear		steps 1 left orthogonal or right orthogonal or diagonal
Old Rat			steps 1 forward orthogonal or backward diagonal

Square Mover		slides orthogonal
Coiled Serpent		steps 1 backward orthogonal or forward orthogonal or backward diagonal
Reclining Dragon	steps 1 orthogonal

				-223-
--------------------------------------------------------------------------------

Free Eagle		slides or leaps 2 or 3 and slides orthogonal or backward diagonal, slides or leaps 2 or 4 and slides forward diagonal
Lion Hawk		leaps 2 orthogonal, slides or leaps 2 and slides diagonal
Chariot Soldier		steps 2 left orthogonal or right orthogonal, slides backward orthogonal or forward orthogonal or diagonal

The Lion Hawk, as in Tenjiku Shogi, may move like the Lion or leap to any square which would be attacked by the Lion.

Side Soldier		steps 1 backward orthogonal, steps 2 forward orthogonal, slides left orthogonal or right orthogonal
Vertical Soldier	steps 1 backward orthogonal, steps 2 left orthogonal or right orthogonal, slides forward orthogonal
Wind General		steps 1 backward orthogonal or forward diagonal, steps 3 forward orthogonal

River General		steps 1 backward orthogonal or forward diagonal, steps 3 forward orthogonal
Mountain General	steps 1 backward orthogonal or forward orthogonal, steps 3 forward diagonal
Front Standard		steps 3 diagonal, slides orthogonal

Horse Soldier		steps 1 backward orthogonal, steps 3 left orthogonal or right orthogonal, slides forward orthogonal or forward diagonal
Wood General		steps 2 forward diagonal
Ox Soldier		steps 1 backward orthogonal, steps 3 left orthogonal or right orthogonal, slides forward orthogonal or forward diagonal

				-224-
--------------------------------------------------------------------------------

Earth General		steps 1 backward orthogonal or forward orthogonal
Boar Soldier		steps 1 backward orthogonal, steps 2 left orthogonal or right orthogonal, slides forward orthogonal or forward diagonal
Stone General		steps 1 forward diagonal

Leopard Soldier		steps 1 backward orthogonal, steps 2 left orthogonal or right orthogonal, slides forward orthogonal or forward diagonal
Tile General		steps 1 backward orthogonal or forward diagonal
Bear Soldier		steps 1 backward orthogonal, steps 2 left orthogonal or right orthogonal, slides forward orthogonal or forward diagonal

Iron General		steps 1 forward orthogonal or forward diagonal
Great Standard		steps 3 backward diagonal, slides orthogonal or forward diagonal
Great Master		steps 5 left orthogonal or right orthogonal or bacward diagonal, leaps 3 forward orthogonal or forward diagonal, slides forward orthogonal or forward diagonal

Right Chariot		steps 1 right orthogonal, slides forward orthogonal or left forward diagonal or right backward diagonal
Left Chariot		steps 1 left orthogonal, slides forward orthogonal or right forward diagonal or lefr backward diagonal
Side Monkey		steps 1 backward orthogonal or forward diagonal, slides left orthogonal or right orthogonal

				-225-
--------------------------------------------------------------------------------

Vertical Mover		steps 1 left orthogonal or right orthogonal, slides backward orthogonal or forward orthogonal
Flying Ox		slides backward orthogonal or forward orthogonal or diagonal
Longbow Soldier		steps 1 backward orthogonal, steps 2 left orthogonal or right orthogonal, steps 5 forward diagonal, slides forward orthogonal

Vertical Pup		steps 1 backward orthogonal or backward diagonal, slides forward orthogonal
Vertical Horse		steps 1 backward orthogonal or forward diagonal, slides forward orthogonal
Burning Soldier		steps 1 backward orthogonal, steps 3 left orthogonal or right orthogonal, steps 5 forward diagonal, steps 7 forward orthogonal

Dragon Horse		steps 1 orthogonal, slides diagonal
Dragon King		steps 1 diagonal, slides orthogonal
Sword Soldier		steps 1 backward orthogonal or forward diagonal

Horned Falcon		leaps 2 forward orthogonal, slides orthogonal or diagonal
Soaring Eagle		leaps 2 forward diagonal, slides orthogonal or diagonal
Spear Soldier		steps 1 backward orthogonal or left orthogonal or right orthogonal, slides forward orthogonal

				-226-
--------------------------------------------------------------------------------

Vertical Leopard	steps 1 backward orthogonal or left orthogonal or right orthogonal or forward diagonal, slides forward orthogonal
Savage Tiger		slides forward orthogonal
Shortbow Soldier	steps 1 backward orthogonal, steps 3 left orthogonal or right orthogonal or forward diagonal, steps 5 forward orthogonal

Roaring Dog		steps 3 backward diagonal, leap 3 orthogonal or forward diagonal, slides orthogonal or forward diagonal
Lion Dog		leaps 3 orthogonal or diagonal, slides orthogonal or diagonal
Dog			steps 1 forward orthogonal or forward diagonal

Go-Between		steps 1 backward orthogonal or forward orthogonal
Pawn			steps 1 forward orthogonal

  (Rules for promoted pieces)

Free Bird		steps 3 backward diagonal, slides orthogonal, hash-marked slides forward diagonal
Great Tapir		leaps 3 left orthogonal or right orthogonal, slides orthogonal or diagonal
Ancient Dragon		slides diagonal, hash-marked slides backward orthogonal or forward orthogonal 

				-227-
--------------------------------------------------------------------------------

Heavenly Tetarch King	igui 1 orthogonal or diagonal, slides orthogonal or diagonal, leaps 1 and slides orthogonal or diagonal
Great Falcon		slides orthogonal or diagonal, leaps 1 and slides forward orthogonal
Great Elephant		steps 3 forward diagonal, hash-marked slides orthogonal or backward diagonal

  Heavenly Tetarch King is able to capture an adjacent square without moving(Igui), or preform its slide by leaping over an occupied adjacent square.
  Great Falcon is able to preform its forward orthogonal slide by leaping over an occupied adjacent square.

Fire Ox			steps 1 left orthogonal or right orthogonal, slides backward orthogonal or forward orthogonal or diagonal
Strong Bear		steps 2 backward orthogonal, slides left orthogonal or right orthogonal or forward orthogonal or diagonal
Right Phoenix		steps 5 left orthogonal or right orthogonal, slides diagonal

Running Leopard		slides left orthogonal or right orthogonal or forward orthgonal or forward diagonal
Thunder Runner		steps 4 backward orthogonal or left orthogonal or right orthogonal, slides forward orthogonal or forward diagonal
Rain Demon		steps 2 backward diagonal or left orthogonal or right orthogonal, steps 3 forward orthogonal, slides forward diagonal, leaps 1 and slides forward diagonal

  Rain Demon is able to preform its forward diagonal slide by leaping over an occupied adjacent square.

Free Boar		steps 1 backward orthogonal, slides left orthogonal or right orthogonal or forward orthogonal or forward diagonal
Free Dog		steps 2 backward diagonal or left orthogonal or right orthogonal, slides backward orthogonal or forward orthogonal or forward diagonal
Running Ox		steps 2 backward diagonal, slides left orthogonal or right orthogonal or forward orthogonal or forward diagonal

				-228-
--------------------------------------------------------------------------------

Great Horse		steps 2 left orthogonal or right orthogonal, slides backward orthogonal or forward orthogonal or forward diagonal
Cavalier		slides orthogonal or forward diagonal
Free Fire		steps 5 backward orthogonal or forward orthogonal, slides left orthogonal or right orthogonal or diagonal

Burning Chariot		steps 1 left orthogonal or right orthogonal, slides backward orthogonal or forward orthogonal or forward diagonal
Free Stag		slides orthogonal or diagonal
Free Dragon		slides backward orthogonal or left orthogonal or right orthogonal or diagonal

Flying Crocodile	steps 2 backward diagonal, steps 3 forward diagonal, range jump orthogonal(ranking noted at end of document)
Strong Chariot		slides orthogonal or forward diagonal
Divine Tiger		steps 2 backward orthogonal, slides left orthogonal or right orthogonal or forward orthogonal or left forward diagonal

Divine Dragon		steps 2 left orthogonal, slides backward orthogonal or right orthogonal or forward orthogonal or right forward diagonal
Divine Turtle		steps 1 orthogonal or left forward diagonal, slides backward diagonal or right forward diagonal
Divine Sparrow		steps 1 orthogonal or right forward diagonal, slides backward diagonal or left forward diagonal

				-229-
--------------------------------------------------------------------------------

Free Serpent		slides backward orthogonal or forward orthogonal or backward diagonal
Free Wolf		slides left orthogonal or right orthogonal or forward orthogonal or forward diagonal
Great Tiger		steps 1 forward orthogonal, slides backward orthogonal or left orthogonal or right orthogonal

Right Dog		steps 1 backward orthogonal, slides forward orthogonal or left backward diagonal
Left Dog		steps 1 backward orthogonal, slides forward orthogonal or right backward diagonal
Free Bear		slides backward orthogonal or forward orthogonal or diagonal

Free Tiger		slides backward orthogonal or left orthogonal or right orthogonal or diagonal
Running Boar		steps 1 left orthogonal or right orthogonal, slides backward orthogonal or forward orthogonal
Free Leopard		slides backward orthogonal or forward orthogonal or diagonal

Heavenly Horse		leaps 1 backward orthogonal then 1 backward diagonal, leaps 1 forward orthogonal then 1 forward orthogonal, slides forward orthogonal
Spear General		steps 2 backward orthogonal, steps 3 left orthogonal or right orthogonal, slides forward orthogonal
Great Leopard		steps 1 backward orthogonal, steps 2 left orthogonal or right orthogonal, steps 3 forward diagonal, slides forward orthogonal

				-230-
--------------------------------------------------------------------------------

Flying Stag		steps 1 left orthogonal or right orthogonal or diagonal, slides backward orthogonal or forward orthogonal
Right Army		steps 1 backward orthogonal or left orthogonal or forward orthogonal or left diagonal, slides right orthogonal or right diagonal
Left Army		steps 1 backward orthogonal or right orthogonal or forward orthogonal or right diagonal, slides left orthogonal or left diagonal

Beast Bird		steps 2 backward orthogonal, steps 3 left orthogonal or right orthogonal, slides forward orthogonal or diagonal
Captive Bird		steps 2 backward orthogonal, steps 3 left orthogonal or right orthogonal, slides forward orthogonal or diagonal
Gliding Swallow		slides orthogonal

Buddhist Spirit		2-space Lion move, slides orthogonal or diagonal
Teaching King		hash-marked slides orthogonal or diagonal
Shark			steps 2 backward diagonal, steps 5 forward diagonal, slides orthogonal

Buddhist Spirit, like in Maka-Dai-Dai Shogi, may slide orthogonal or diagonal or preform moves like the Lion.

Furious Fiend		2-space Lion move, steps 3 orthogonal or diagonal
Leopard King		steps 5 orthogonal or diagonal
Goose Wing		steps 1 diagonal, steps 3 left orthogonal or right orthogonal, slides backward orthogonal or forward orthogonal

Furious Fiend, like in Dai-Dai Shogi and Maka-Dai-Dai Shogi, may step three spaces orthogonal or diagoanl or preform moves like the Lion.

				-231-
--------------------------------------------------------------------------------

Left Iron Chariot	steps 1 left orthogonal, slides backward diagonal or right forward diagonal
Right Iron Chariot	steps 1 right orthogonal, slides backward diagonal or left forward diagonal
Plodding Ox		steps 1 diagonal, slides backward orthogonal or forward orthogonal

Wind Snapping Turtle	steps 2 forward diagonal, slides backward orthogonal or forward orthogonal
Running Tile		steps 2 left orthogonal or right orthogonal, slides backward orthogonal or forward orthogonal
Young Bird		steps 2 left orthogonal or right orthogonal or backward diagonal, slides backward orthogonal or forward orthogonal

Playful Cockatoo	steps 2 backward diagonal, steps 3 forward diagonal, steps 5 left orthogonal or right orthogonal, slides backward orthogonal or forward orthogonal
Copper Elephant		steps 1 left orthogonal or right orthogonal or diagonal, slides backward orthogonal or forward orthogonal
Walking Heron		steps 2 left orthogonal or right orthogonal or forward diagonal, slides backward orthogonal or forward orthogonal

Tiger Soldier		steps 1 backward orthogonal, steps 2 forward orthogonal, slides forward diagonal
Strong Eagle		slides orthogonal or diagonal
Running Dragon		steps 5 backward orthogonal, slides left orthogonal or right orthogonal or forward orthogonal or diagonal

				-232-
--------------------------------------------------------------------------------

Heavenly Tetarch	steps 4 orthogonal or diagonal
Elephant King		steps 2 orthogonal, slides diagonal
Peaceful Mountain	steps 5 left orthogonal or right orthogonal or forward orthogonal, slides diagonal

Chinese River		steps 1 backward orthogonal or forward orthogonal, slides left orthogonal or right orthogonal or diagonal
Violent Wind		steps 1 left orthogonal or right orthogonal, slides backward orthogonal or forward orthogonal or diagonal
Free Chicken		steps 2 left orthogonal or right orthogonal or backward diagonal, slides backward orthogonal or forward orthogonal or forward diagonal

Free Ox			steps 1 backward diagonal, steps 2 left orthogonal or right orthogonal, slides backward orthogonal or forward orthogonal or forward diagonal
Free Horse		steps 1 backward diagonal, steps 2 left orthogonal or right orthogonal, slides backward orthogonal or forward orthogonal or forward diagonal
Great Whale		slides backward orthogonal or forward orthogonal or diagonal

Free Pig		steps 1 backward diagonal, steps 2 left orthogonal or right orthogonal, slides backward orthogonal or forward orthogonal or forward diagonal
Longbow General		steps 5 left orthogonal or right orthogonal, slides backward orthogonal or forward orthogonal or forward diagonal
Burning General		steps 2 backward orthogonal, steps 3 left orthogonal or right orthogonal, slides forward orthogonal or forward diagonal

				-233-
--------------------------------------------------------------------------------

Shortbow General	steps 2 backward orthogonal, steps 3 left orthogonal or right orthogonal, steps 5 forward diagonal, slides forward orthogonal
Mountain Crane		slides orthogonal or diagonal, leaps 3 then slides orthogonal or diagonal
Rushing Boar		steps 1 left orthogonal or right orthogonal or forward orthogonal or diagonal

Sword General		steps 1 backward orthogonal, steps 3 forward orthogonal or forward diagonal
Bird of Paradise	slides backward orthogonal or forward orthogonal or forward diagonal
Coiled Dragon		slides backward orthogonal or forward orthogonal or backward diagonal

Bear's Eyes		steps 1 orthogonal or diagonal
Mountain Witch		slides backward orthogonal or diagonal
Flying Falcon		steps 1 forward orthogonal, slides diagonal

Venomous Wolf		steps 1 orthogonal or diagonal
Spirit Turtle		leaps 3 orthogonal, slides orthogonal or diagonal
Treasure Turtle		leaps 2 orthogonal, slides orthogonal or diagonal

				-234-
--------------------------------------------------------------------------------

Great Bear		steps 1 backward orthogonal or left orthogonal or right orthogonal, slides forward orthogonal or forward diagonal
Multi-General		slides backward orthogonal or forward orthogonal or forward diagonal
Wizard Stork		slides backward orthogonal or left orthogonal or right orthogonal or forward diagonal

Raiding Falcon		steps 1 left orthogonal or right orthogonal or forward diagonal, slides forward orthogonal
Great Eagle		slides orthogonal or diagonal, leaps 2 then slides forward diagonal

Great Eagle is able, if the adjacent forward diagonal are occupied,
to leap over and continue its slide until it preforms a capture.
# }}}

# {{{ 4. The remaining rules:

1) Pieces promote upon reaching any of the opponent's 11 ranks.

2) Captured pieces are removed from play.

3) Free Eagle is able to capture without moving(igui) an adjacent square. With the squares marked (1)(2)(3) there are several move options
   (including the forward diagonal squares marked 4), may leap to the squares (2)(3) (up tp the fourth forward diagonal) then continue until capturing
   is one option. Another, for the squares marked (1)(2)(3) may preform consecutive capturing moves (up tp the fourth forward diagonal)
   may also preform passing move(jitto) if vacant adjacent square.

4) -|-|-|->  The meaning of this symbol is not known.  There are no references to a line with three marks.
   It is believed that this may mean that a piece may jump up to three spaces and continue its slide.

5) Great General, Vice General, Rook General, Bishop General, Violent Dragon, Flying Crocodile are equal to their counterparts in Tenjiku Shogi.  The pieces are able to leap over
   others according to rank.   By jumping over any number of lower ranked pieces, including friend and foe, continuing until making a capture.
   What follows is the ranking of these pieces. *
   (1) King, Crown Prince (2) Great General (3) Vice General (4) Bishop General, Rook General, Violent Dragon, Flying Crocodile
   (5) the other pieces

[*Some sources note that the ranging move can involve the capture of each and every piece, both friend and foe, which the ranging piece leaps.]
# }}}

# {{{ Initial Set-up 
(Rank and position in relation to the lower left hand corner of the playing field.)


PIECE			RANK		POSITION(S)
------------------------------------------------------
King			1		18
Crown Prince		1		19
Gold General		1		17, 20
Right General		1		21
Left General		1		16
Rear Standard		1		15, 22
Free King		1		14, 23
Free Tapir		1		13, 24
Wooden Dove		1		25
Ceramic Dove		1		12
Earth Dragon		1		11, 26
Free Demon		1		10, 27
Running Horse		1		9, 28
Beast Cadet		1		8, 29
Long-Nosed Goblin	1		7, 30
Mountain Eagle		1		6, 31
Fire Demon		1		5, 32
Whale			1		4, 33
Running Rabbit		1		3, 34
White Tiger		1		35
Turtle Snake	 	1		2
Lance			1		1, 36

Reverse Chariot		2		1, 36
Fragrant Elephant	2		35
White Elephant		2		2
Mountain Dove		2		3, 34
Flying Swallow		2		4, 33
Captive Officer		2		5, 32
Rain Dragon		2		6, 31
Forest Demon		2		7, 30
Mountain Stag		2		8, 29
Running Pup		2		9, 28
Running Serpent		2		10, 27
Side Serpent		2		11, 26
Great Dove		2		12, 25
Running Tiger		2		13, 24
Running Bear		2		14, 23
Night Sword		2		22
Buddhist Devil		2		15
Guardian of the Gods	2		21
Wrestler		2		16
Silver General		2		17, 20
Drunk Elephant		2		19
Neighboring King	2		18

Gold Chariot		3		1, 36
Side Dragon		3		2, 35
Running Stag		3		3, 34
Running Wolf		3		4, 33
Bishop General		3		5, 32
Rook General		3		6, 31
Right Tiger		3		30
Left Tiger		3		7
Right Dragon		3		29
Left Dragon		3		8
Beast Officer		3		9, 28
Wind Dragon		3		10, 27
Free Pup		3		11, 26
Rushing Bird		3		12, 25
Old Kite Hawk		3		13, 24
Peacock			3		14, 23
Water Dragon		3		15, 22
Fire Dragon		3		16, 21
Copper General		3		17, 20
Phoenix Master		3		19
Kylin Master		3		18

Silver Chariot		4		1, 36
Vertical Bear		4		2, 35
Knight			4		3, 34
Pig General		4		4, 33
Chicken General		4		5, 32
Pup General		4		6, 31
Horse General		4		7, 30
Ox General		4		8, 29
Center Standard		4		9, 28
Side Boar		4		10, 27
Silver Rabbit		4		11, 26
Golden Deer		4		12, 25
Lion			4		13, 24
Captive Cadet		4		14, 23
Great Stag		4		15, 22
Violent Dragon		4		16, 21
Woodland Demon		4		17, 20
Vice General		4		19
Great General		4		18

Stone Chariot		5		1, 36
Cloud Eagle		5		2, 35
Bishop			5		3, 34
Rook			5		4, 33
Side Wolf		5		5, 32
Flying Cat		5		6, 31
Mountain Falcon		5		7, 30
Vertical Tiger		5		8, 29
Soldier			5		9, 28
Little Standard		5		10, 27
Cloud Dragon		5		11, 26
Copper Chariot		5		12, 25
Running Chariot		5		13, 24
Ramshead Soldier	5		14, 23
Violent Ox		5		15, 22
Great Dragon		5		16, 21
Golden Bird		5		17, 20
Dark Spirit		5		19
Deva			5		18

Wood Chariot		6		1, 36
White Horse		6		2, 35
Howling Dog (Right)	6		34
Howling Dog (Left)	6		3
Side Mover		6		4, 33
Prancing Stag		6		5, 32
Water Buffalo		6		6, 31
Ferocious Leopard	6		7, 30
Fierce Eagle		6		8, 29
Flying Dragon		6		9, 28
Poisonous Snake		6		10, 27
Flying Goose		6		11, 26
Strutting Crow		6		12, 25
Blind Dog		6		13, 24
Water General		6		14, 23
Fire General		6		15, 22
Phoenix			6		21
Kylin			6		16
Hook Mover		6		20
Little Turtle		6		19
Great Turtle		6		18
Capricorn		6		17

Tile Chariot		7		1, 36
Vertical Wolf		7		2, 35
Side Ox			7		3, 34
Donkey			7		4, 33
Flying Horse		7		5, 32
Violent Bear		7		6, 31
Angry Boar		7		7, 30
Evil Wolf		7		8, 29
Liberated Horse		7		9, 28
Flying Cock		7		10, 27
Old Monkey		7		11, 26
Chinese Cock		7		12, 25
Northern Barbarian	7		24
Southern Barbarian	7		23
Western Barbarian	7		13
Eastern Barbarian	7		14
Violent Stag		7		15, 22
Violent Wolf		7		16, 21
Treacherous Fox		7		17, 20
Center Master		7		19
Roc Master		7		18

Earth Chariot		8		1, 36
Vermillion Sparrow	8		35
Blue Dragon		8		2
Enchanted Badger	8		3, 34
Horseman		8		4, 33
Swooping Owl		8		5, 32
Climbing Monkey		8		6, 31
Cat Sword		8		7, 30
Swallow's Wings		8		8, 29
Blind Monkey		8		9, 28
Blind Tiger		8		10, 27
Ox Cart			8		11, 26
Side Flier		8		12, 25
Blind Bear		8		13, 24
Old Rat			8		14, 23
Square Mover		8		15, 22
Coiled Serpent		8		16, 21
Reclining Dragon	8		17, 20
Free Eagle		8		19
Lion Hawk		8		18

Chariot Soldier		9		1, 36
Side Soldier		9		2, 35
Vertical Soldier	9		3, 34
Wind General		9		4, 33
River General		9		5, 32
Mountain General	9		6, 31
Front Standard		9		7, 30
Horse Soldier		9		8, 29
Wood General		9		9, 28
Ox Soldier		9		10, 27
Earth General		9		11, 26
Boar Soldier		9		12, 25
Stone General		9		13, 24
Leopard Soldier		9		14, 23
Tile General		9		15, 22
Bear Soldier		9		16, 21
Iron General		9		17, 20
Great Standard		9		19
Great Master		9		18

Right Chariot		10		36
Left Chariot		10		1
Side Monkey		10		2, 35
Vertical Mover		10		3, 34
Flying Ox		10		4, 33
Longbow Soldier		10		5, 32
Vertical Pup		10		6, 31
Vertical Horse		10		7, 30
Burning Soldier		10		8, 29
Dragon Horse		10		9, 28
Dragon King		10		10, 27
Sword Soldier		10		11, 26
Horned Falcon		10		12, 25
Soaring Eagle		10		13, 24
Spear Soldier		10		14, 23
Vertical Leopard	10		15, 22
Savage Tiger		10		16, 21
Shortbow Soldier	10		17, 20
Roaring Dog		10		19
Lion Dog		10		18

Dog			12		6, 15, 22, 31, 
Go-Between		12		11, 26
Pawn			11		1 through 36
# }}}

=cut
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

Games::Shogi::Taikyoku - Piece descriptions and initial configuration for Taikyoku Shogi

=head1 SYNOPSIS

  use Games::Shogi::Taikyoku;
  $Game = Games::Shogi::Taikyoku->new;
  $piece = $Game->board()->[3][7];
  print @{$Game->neighbor($tl_piece);
  print $Game->english_name('fidr'); # 'Fire Dragon'

=head1 DESCRIPTION

Taikyoku Shogi is thought to be the largest Shogi variant in existence, on a 36 x 36 grid with 402 pieces, 201 per side. This game contains such pieces as the Buddhist Spirit and an alternate version of the Fire Demon, which moves differently than the other games.

The embedded POD contains commentary including an English translation of the only known manual for the game, which may go some way to explaining the variety of pieces and movements.

=head1 SEE ALSO

L<perl>

=head1 AUTHOR

Jeffrey Goff, E<lt>jgoff@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2004 by Jeffrey Goff

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
