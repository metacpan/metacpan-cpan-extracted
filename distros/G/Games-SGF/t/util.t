use Test::More tests => 35;
use Games::SGF;
use Games::SGF::Util;
use Data::Dumper;
require "t/sgf_test.pl";

my $sgf_in = <<SGF;
(;B[aa]C[Keep]PW[Somebody]
 ;W[ab]C[Some]
 (;B[ac]C[body])
 (;W[dd]C[Keep];B[dd])
)
SGF
my $u = new Games::SGF::Util();
ok( not( $u), "Correctly failed to create util object");

my $sgf = Games::SGF->new(Debug => 0, Warn => 0);

ok( $sgf->readText($sgf_in), "Read File");

# test gameInfo

nav( $sgf, "Keep", "Some","body","Keep");

my $util = Games::SGF::Util->new($sgf);
$u = Games::SGF::Util->new($sgf);

my(@games) = $util->gameInfo;
if((@games == 1 and $games[0]->{'PW'}->[0] eq "Somebody")) {
  pass( "Game Util");
} else {
   fail( "Game Util");
   diag( "returned ${@games} games.\n expected 'Somebody' got " 
      . $games[0]->{'PW'}->[0] );
}

$util->filter( "C" , sub { $_[0] =~ s/ee//g; return $_[0];} );
nav( $util->sgf(), "Kp", "Some","body","Kp");

$u->sgf($util->sgf);
$u->filter( "C" , sub { return $_[0] eq "body" ? undef : $_[0];} );
nav( $u->sgf(), "Kp", "Some",undef,"Kp");

$u->filter( "C" , undef );
nav( $u->sgf());

sub nav {
   my $sgf = shift;
   $sgf->gotoRoot;
   my( @c ) = @_;

   tag_eq( $sgf, "Root Node",
      B => $sgf->move("aa"),
      C => shift @c
   );
   $sgf->next;

   tag_eq( $sgf, "Second Node",
      W => $sgf->move("ab"),
      C => shift @c
   );
   $sgf->gotoBranch(0);

   tag_eq( $sgf, "Third Node",
      B => $sgf->move("ac"),
      C => shift @c
   );
   $sgf->prev;
   $sgf->gotoBranch(1);

   tag_eq( $sgf, "Forth Node",
      W => $sgf->move("dd"),
      C => shift @c
   );
}
