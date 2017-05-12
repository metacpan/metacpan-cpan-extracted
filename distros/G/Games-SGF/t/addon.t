use Test::More tests => 46;                      # last test to print
use Games::SGF;
require 't/sgf_test.pl';
my $sgf_in = <<SGF;
(;KM[5.00];W[df];B[aa];AW[ab][ac];CR[aa][ac:cd]AE[aa:cc])
SGF
#TODO make a test check and write callback
# create Parsers
my $p = Games::SGF->new(Fatal => 0, Warn => 0, Debug => 0);
my $parser = $p->new(Fatal => 0, Warn => 0, Debug => 0);

ok( $parser, "Create Parser Object" );
diag( $parser->Fatal ) if $parser->Fatal;

# add tags to parsers
ok($parser->addTag('KM', $parser->T_GAME_INFO, $parser->V_REAL, $parser->VF_EMPTY, $parser->A_INHERIT ), "addTag"); #new tag
diag( $parser->Fatal ) if $parser->Fatal;
ok( not( $parser->redefineTag('something', $parser->T_GAME_INFO ) ), 'attempt to redefine nonexistant tag "something"'); # redefine nonexist
ok(  $parser->redefineTag('KM', $parser->T_GAME_INFO, $parser->V_DOUBLE, $parser->VF_LIST, $parser->A_NONE ), # redefine exist
   'attempt to redefine custom tag');
ok(  $parser->redefineTag('KM',,,,), # redefine exist
   'attempt to redefine custom tag again');
ok($parser->redefineTag('KM', $parser->T_GAME_INFO, $parser->V_REAL, $parser->VF_NONE, $parser->A_NONE ), "fix tag"); #new tag
diag( $parser->Fatal ) if $parser->Fatal;
diag( $parser->Fatal ) if $parser->Fatal;
ok( $parser->redefineTag("BR",,,,$parser->A_NONE ), "redefine ff4 tag" );
diag( $parser->Fatal ) if $parser->Fatal;
ok(not( $parser->addTag("WR", $parser->T_ROOT, $parser->V_REAL )), "try adding ff4 tag" );

# try adding non CODE callbacks
ok( not( $parser->setStoneRead("something")), "Add Bad Read Stone");
ok( not( $parser->setMoveRead("Something")), "Add Bad Read Move");
ok( not( $parser->setPointRead("Something")), "Add Bad Read Point");

ok( not( $parser->setStoneCheck("something")), "Add Bad Check Stone");
ok( not( $parser->setMoveCheck("Something")), "Add Bad Check Move");
ok( not( $parser->setPointCheck("Something")), "Add Bad Check Point");

ok( not( $parser->setStoneWrite("something")), "Add Bad Write Stone");
ok( not( $parser->setMoveWrite("Something")), "Add Bad Write Move");
ok( not( $parser->setPointWrite("Something")), "Add Bad Write Point");

# add point, stone, move callbacks
ok( $parser->setStoneRead(\&parsepoint), "Add Read Stone");
diag( $parser->Fatal ) if $parser->Fatal;
ok( $parser->setMoveRead(\&parsepoint), "Add Read Move");
diag( $parser->Fatal ) if $parser->Fatal;
ok( $parser->setPointRead(\&parsepoint), "Add Read Point");
diag( $parser->Fatal ) if $parser->Fatal;

ok( $parser->setStoneCheck(\&checkpoint), "Add Check Stone");
diag( $parser->Fatal ) if $parser->Fatal;
ok( $parser->setMoveCheck(\&checkpoint), "Add Check Move");
diag( $parser->Fatal ) if $parser->Fatal;
ok( $parser->setPointCheck(\&checkpoint), "Add Check Point");
diag( $parser->Fatal ) if $parser->Fatal;

ok( $parser->setStoneWrite(\&writepoint), "Add Write Stone");
diag( $parser->Fatal ) if $parser->Fatal;
ok( $parser->setMoveWrite(\&writepoint), "Add Write Move");
diag( $parser->Fatal ) if $parser->Fatal;
ok( $parser->setPointWrite(\&writepoint), "Add Write Point");
diag( $parser->Fatal ) if $parser->Fatal;

# redefining subroutines
ok( not($parser->setStoneRead(\&parsepoint)), "redefine reading Stone");
ok( not($parser->setMoveRead(\&parsepoint)), "redefine reading Move");
ok( not($parser->setPointRead(\&parsepoint)), "redefine reading Point");

ok( not($parser->setStoneRead(\&checkpoint)), "redefine checking Stone");
ok( not($parser->setMoveRead(\&checkpoint)), "redefine checking Move");
ok( not($parser->setPointRead(\&checkpoint)), "redefine checking Point");

ok( not($parser->setStoneRead(\&writepoint)), "redefine writing Stone");
ok( not($parser->setMoveRead(\&writepoint)), "redefine writing Move");
ok( not($parser->setPointRead(\&writepoint)), "redefine writing Point");

# read in $sgf_in
ok( $parser->readText($sgf_in), "Read SGF");
diag( $parser->Fatal ) if $parser->Fatal;
test_nav( $parser, "parse");

sub parsepoint {
   my $value = shift;
   my( $x, $y) = split //, $value;
   return [ ord($x) - ord('a'), ord($y) - ord('a') ];
}
sub checkpoint {
   my $ref = shift;
   if( ref $ref && $ref->[1] >= 0 && $ref->[0] >= 0 ) {
      return 1;
   }
   return 0;
}
sub writepoint {
   my $ref = shift;
   return chr( $ref->[0] + ord('a')) . chr( $ref->[1] + ord('a'));

}


sub test_nav {
   my $sgf = shift;
   my $name = shift;

   tag_eq( $sgf, $name,
      KM => [5] );
   ok($sgf->next, "next $name");
   diag($sgf->Fatal) if $sgf->Fatal;
   tag_eq( $sgf, $name, W => [[3,5]] );

   ok($sgf->next, "next1 $name");
   diag($sgf->Fatal) if $sgf->Fatal;
   tag_eq( $sgf, $name, B => [[0,0]] );

   ok($sgf->next, "next2 $name");
   diag($sgf->Fatal) if $sgf->Fatal;
   tag_eq( $sgf, $name, AW => [[0,1],[0,2]] );

   ok($sgf->next, "next3 $name");
   diag($sgf->Fatal) if $sgf->Fatal;
   tag_eq( $sgf, $name, CR => [[0,0],$sgf->compose([0,2],[2,3])], AE => $sgf->compose([0,0], [2,2]));
}
