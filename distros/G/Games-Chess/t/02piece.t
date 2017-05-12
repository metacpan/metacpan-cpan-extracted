# Test Games::Chess::Piece representaton ( -*- cperl -*-)

BEGIN { $| = 1; print "1..3\n"; }
END {print "not ok 1\n" unless $loaded;}
use Games::Chess qw(:constants :functions debug);
debug(1);
$loaded = 1;
print "ok 1\n";

use strict;
use UNIVERSAL 'isa';
$^W = 1;
my $n = 1;
my $success;

sub do_test (&) {
  my ($test) = @_;
  ++ $n;
  $success = 1;
  &$test;
  print 'not ' unless $success;
  print "ok $n\n";
}

sub fail {
  my ($mesg) = @_;
  print STDERR $mesg, "\n";
  $success = 0;
}

# Check Piece->new when given no arguments.

do_test {
  my $p = Games::Chess::Piece->new;
  $p or fail("Piece->new returned undefined.");
  ord($$p) == 0 or fail("Piece->new should be 0.");
};

# Check Piece->new($arg) produces the correct representation in all three 
# cases: $arg a number, $arg a character or $arg a Piece.

my %tests =
  (
   ' ' => [ &EMPTY, &EMPTY,  'empty square',  0 ],
   'p' => [ &BLACK, &PAWN,   'black pawn',   17 ],
   'n' => [ &BLACK, &KNIGHT, 'black knight', 18 ],
   'b' => [ &BLACK, &BISHOP, 'black bishop', 19 ],
   'r' => [ &BLACK, &ROOK,   'black rook',   20 ],
   'q' => [ &BLACK, &QUEEN,  'black queen',  21 ],
   'k' => [ &BLACK, &KING,   'black king',   22 ],
   'P' => [ &WHITE, &PAWN,   'white pawn',    9 ],
   'N' => [ &WHITE, &KNIGHT, 'white knight', 10 ],
   'B' => [ &WHITE, &BISHOP, 'white bishop', 11 ],
   'R' => [ &WHITE, &ROOK,   'white rook',   12 ],
   'Q' => [ &WHITE, &QUEEN,  'white queen',  13 ],
   'K' => [ &WHITE, &KING,   'white king',   14 ],
  );

do_test {
  foreach my $k (keys %tests) {
    my $p = Games::Chess::Piece->new($k);
    my $q = Games::Chess::Piece->new($p);
    my $r = ($k eq ' ' ? $q
	     : Games::Chess::Piece->new($tests{$k}[0], $tests{$k}[1]));
    my @p = ($p,$q,$r);
    my @args = map { "Piece->new($_)" } 
      ("$k", "$p", "$tests{$k}[0], $tests{$k}[1]");
    foreach (0 .. 2) {
      unless ($p[$_]) {
	fail(0,"$args[$_] returned undefined.");
	next;
      }
      my ($CODE,$COLO,$PIEC,$NAME,$NUMB,$CN,$PN) =
	($k,@{$tests{$k}},split(' ',$tests{$k}[2]));
      my ($code,$colo,$piec,$name,$numb,$cn,$pn) =
	($p[$_]->code, $p[$_]->colour, $p[$_]->piece, $p[$_]->name,
	 ord($ {$p[$_]}), $p[$_]->colour_name, $p[$_]->piece_name);
      $code eq $CODE or fail("$args[$_]\->code is $code (should be $CODE).");
      $colo eq $COLO or fail("$args[$_]\->colour is $colo (should be $COLO).");
      $piec eq $PIEC or fail("$args[$_]\->piece is $piec (should be $PIEC).");
      $name eq $NAME or fail("$args[$_]\->name is $name (should be $NAME).");
      $numb == $NUMB or fail("$args[$_] is $numb (should be $NUMB).");
      $cn eq $CN or fail("$args[$_]\->colour_name is $cn (should be $CN).");
      $pn eq $PN or fail("$args[$_]\->piece_name is $pn (should be $PN).");
    }
  }
};
