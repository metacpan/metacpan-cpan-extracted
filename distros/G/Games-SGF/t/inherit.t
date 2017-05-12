use Test::More tests => 38;
use Games::SGF;
use Data::Dumper;
require "t/sgf_test.pl";

my $sgf_in = <<SGF;
(;C[Some Prop]PM[2];B[ab]
   (;W[fg])
   (;W[ad]PM[1];B[de])
)
SGF

my $sgf = new Games::SGF(Warn => 0, Debug => 0);

ok( $sgf->readText($sgf_in), "Read SGF_IN");
testNav($sgf, 2);
$sgf->gotoRoot;
ok( $sgf->setProperty("PM"), "unset PM" );
if( $sgf->Fatal ) {
   diag($sgf->Fatal);
}
ok( not( $sgf->property("PM")), "should not fetch");
ok( $sgf->setProperty("PM", 3), "PM to 3" );
if( $sgf->Fatal ) {
   diag($sgf->Fatal);
}

my $sgf_out;
ok( $sgf_out = $sgf->writeText, "Writing Text");
$sgf = new Games::SGF(Warn => 0, Debug => 0);
ok( $sgf->readText($sgf_out), "Read SGF_OUT");
testNav($sgf, 3);


sub testNav {
   my $sgf = shift;
   my $pm = shift;
   my( %tags );
   %tags = map { $_ => 1 } $sgf->property;
   ok( $tags{"C"} && $tags{"PM"}, "property no prams");
   tag_eq( $sgf, "Root Node",
      C => "Some Prop",
      PM => $pm
   );
   ok($sgf->next, "goto second node");
   tag_eq( $sgf, "Second Node",
      B => $sgf->move('ab'),
      PM => $pm
   );
   ok($sgf->gotoBranch(0), "First Branch");
   tag_eq( $sgf, "First Branch First Node",
      W => $sgf->move('fg'),
      PM => $pm
   );
   ok($sgf->prev, "Going to Parent");
   ok($sgf->gotoBranch(1), "Second Branch");
   tag_eq( $sgf, "Second Branch First Node",
      W => $sgf->move('ad'),
      PM => 1
   );
   ok($sgf->next, "goto second branch second node");
   tag_eq( $sgf, "Second Branch Second Node",
      B => $sgf->move('de'),
      PM => 1
   );
}
