use Test::More tests => 28;                      # last test to print
use Games::SGF;
use Data::Dumper;
require 't/sgf_test.pl';
my $sgf_in = <<SGF;
(;KM[5.00];W[df];B[aa];AW[ab][ac];CR[aa][ac:cd])
SGF

# create Parsers
my $parser = new Games::SGF(Warn => 0, Debug => 0);

ok( $parser, "Create Parser Object" );
diag( $parser->Fatal ) if $parser->Fatal;

# add tags to parsers
ok($parser->addTag('KM', $parser->T_GAME_INFO, $parser->V_REAL ), "addTag");
diag( $parser->Fatal ) if $parser->Fatal;

# read in $sgf_in
ok( $parser->readText($sgf_in), "Read SGF");
diag( $parser->Fatal ) if $parser->Fatal;
test_nav( $parser, "parse");

$parser->gotoRoot;

ok($parser->next, "moving up a node");
   diag($parser->Fatal) if $parser->Fatal;
ok($parser->next, "moving up a node");
   diag($parser->Fatal) if $parser->Fatal;
ok($parser->addNode, "splitting");
   diag($parser->Fatal) if $parser->Fatal;
ok($parser->property("W", $parser->move("ab")), "adding prop");
   diag($parser->Fatal) if $parser->Fatal;


$parser->gotoRoot;
test_nav($parser, "pass-2", 1);


sub test_nav {
   my $sgf = shift;
   my $name = shift;
   my $passTwo = shift;

   tag_eq( $sgf, $name,
      KM => [5] );
   ok($sgf->next, "next $name");
   diag($sgf->Fatal) if $sgf->Fatal;
   tag_eq( $sgf, $name, W => $sgf->move("df") );

   ok($sgf->next, "next1 $name");
   diag($sgf->Fatal) if $sgf->Fatal;
   tag_eq( $sgf, $name, B => $sgf->move("aa") );

   if($passTwo) {
      ok($sgf->gotoBranch(1), "goto new var");
      tag_eq( $sgf, "new-$name", W => $sgf->move("ab") );
      ok($sgf->removeNode, "remove node");
   }
      ok($sgf->next, "next2 $name");
      diag($sgf->Fatal) if $sgf->Fatal;
   tag_eq( $sgf, $name, AW => [$sgf->stone("ab"),$sgf->stone("ac")] );

   ok($sgf->next, "next3 $name");
   diag($sgf->Fatal) if $sgf->Fatal;
   tag_eq( $sgf, $name, CR => [
                  $sgf->point("aa"),
                  $sgf->compose($sgf->point("ac"),
                        $sgf->point("cd"))] );
}
