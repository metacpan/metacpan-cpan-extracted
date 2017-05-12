use Test::More tests => 70;
use Games::SGF::Go;
use Data::Dumper;
require "t/sgf_test.pl";

my $sgf_in = <<SGF;
(;GM[1]FF[4]AP[qGo:1.5.4]ST[1]
SZ[19]HA[0]KM[6.5]OT[20 per move]
PW[GNU Go 3.6]PB[Unknown]RE[Void]
CA[UTF-8]AW[aa][AA]AW[ac]AE[ab][cc:dd]
;B[pd]BL[20]OB[1]
;W[dp]WL[20]OW[1]
;B[pp]BL[20]OB[1]
;W[dc]WL[20]OW[1]
;B[cj]BL[20]OB[1]
;W[qn]WL[20]OW[1]
;B[QL]BL[20]OB[1]DO[]
;W[];B[])
SGF
my $s = new Games::SGF::Go(Warn => 0, Debug => 0);
my $sgf = $s->new(Warn => 0, Debug => 0);


### Test point code ###
#
#######################

my $pt = $sgf->point(5,5);
my(@c) = $sgf->point($pt);
ok($c[0] == 5 && $c[1] == 5, "Point converage test");

$pt = $sgf->move(5,5);
(@c) = $sgf->move($pt);
ok($c[0] == 5 && $c[1] == 5, "Move converage test");

$pt = $sgf->stone(5,5);
(@c) = $sgf->stone($pt);
ok($c[0] == 5 && $c[1] == 5, "Stone converage test");


ok( $sgf->readText($sgf_in), "Read SGF");
nav($sgf);
my $sgf_out;
ok($sgf_out = $sgf->writeText, "writing SGF");
$sgf = new Games::SGF::Go(Warn => 0,Debug => 0);
ok( $sgf->readText($sgf_out), "Read SGF Out");
nav($sgf);

sub nav {
   my $sgf = shift;
   tag_eq( $sgf, "Root Node",
      GM => 1,
      FF => 4,
      AP => [$sgf->compose("qGo","1.5.4")],
      ST => 1,
      SZ => 19,
      HA => 0,
      KM => 6.5,
      OT => "20 per move",
      PW => "GNU Go 3.6",
      PB => "Unknown",
      RE => "Void",
      CA => "UTF-8",
      AW => [  $sgf->point(0,0),
               $sgf->point(26,26),
               $sgf->point(0,2) ],
      AE => [  $sgf->point(0,1),
               $sgf->compose($sgf->point(2,2),$sgf->point(3,3)) ],
   );
   #print Dumper $sgf;
   test_moves( $sgf, "Move",
      $sgf->move(15,3),
      $sgf->move(3,15),
      $sgf->move(15,15),
      $sgf->move(3,2),
      $sgf->move(2,9),
      $sgf->move(16,13),
      $sgf->move(26+16,26+11),
      $sgf->pass,
      $sgf->pass
   );
}
