# Test Games::Chess::Position representation (-*- cperl -*-)

BEGIN { $| = 1; print "1..7\n" }
END { print "not ok 1\n" unless $loaded }
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

# Position->new when given no arguments.

do_test {
  my $init_pos = 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1';
  my $p = Games::Chess::Position->new;
  $p or fail("Position->new returned undefined.");
  $p->to_FEN eq $init_pos or fail("Position->new->to_FEN is @{[$p->to_FEN]}.");
};

my %tests =
  ( 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1' =>
    <<END,
r n b q k b n r
p p p p p p p p
  .   .   .   .
.   .   .   .  
  .   .   .   .
.   .   .   .  
P P P P P P P P
R N B Q K B N R
END
    # The following three problems are from "The Chess Mysteries of
    # Sherlock Holmes" by Raymond Smullyan; they appear on pages 148, 78
    # and 145 respectively.
    '2b1k2r/1p1pppbp/pp3n2/8/3NB3/2P2P1P/P1PPP2P/RNB1K2R w Kk - 5 20' =>
    <<END,
  . b . k .   r
. p . p p p b p
p p   .   n   .
.   .   .   .  
  .   N B .   .
.   P   . P . P
P . P P P .   P
R N B   K   . R
END
    '2B5/8/6P1/6Pk/3P2qb/3p4/3PB3/2NrNKQR b - - 1 45' =>
    <<END,
  . B .   .   .
.   .   .   .  
  .   .   . P .
.   .   .   P k
  .   P   . q b
.   . p .   .  
  .   P B .   .
.   N r N K Q R
END
    'r3k3/8/8/8/8/8/5PP1/6bK w q - 4 65' =>
    <<END,
r .   . k .   .
.   .   .   .  
  .   .   .   .
.   .   .   .  
  .   .   .   .
.   .   .   .  
  .   .   P P .
.   .   .   b K
END
  );

# Test new, to_FEN, to_text and validate.
  
do_test {
  foreach my $c (keys %tests) {
    my $p = Games::Chess::Position->new($c);
    unless ($p) {
      fail("Piece->new($c) returned undefined.");
      next;
    }
    unless (isa($p,'Games::Chess::Position')) {
      fail("Position->new($c) didn't return a Games::Chess::Position");
      next;
    }
    next unless $p->validate;
    my ($FEN,$DIAGRAM) = ($c,$tests{$c});
    my ($fen,$diagram) = ($p->to_FEN, $p->to_text . "\n");
    $fen eq $FEN or fail("Position($FEN)->to_FEN is $fen");
    $diagram eq $DIAGRAM or fail("Position($FEN)->to_text is:\n$diagram");
  }
};

# Check Position->at and Position->sq against each other.

do_test {
  foreach my $c (keys %tests) {
    my $p = Games::Chess::Position->new($c);
    unless ($p) {
      fail("Position->new($c) returned undefined.");
      next;
    }
    unless (isa($p,'Games::Chess::Position')) {
      fail("Position->new($c) didn't return a Games::Chess::Position");
      next;
    }
    next unless $p->validate;
    my @pieces = (split '', $tests{$c})[map {2*$_} 0 .. 63];
    foreach my $x (0 .. 7) {
      foreach my $y (0 .. 7) {
	my $at = $p->at($x,$y);
	isa($at,'Games::Chess::Piece') or fail("$at not a chess piece");
	my $code = $pieces[8*(7-$y)+$x];
	$code = ' ' if $code eq '.';
	my $CODE = $at->code;
	$CODE eq $code 
          or fail("Position->new($c)->at($x,$y)->code=$CODE (should be $code)");
      }
    }
  }
};

# Test can_castle, en_passant, halfmove_clock, move_number, player_to_move.

do_test {
  my %tests = 
    ( 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1'
      => [ 1, 1, 1, 1, [], 0, 1, WHITE ],
      'rnbqkbnr/pppppppp/8/8/4P3/8/PPPP1PPP/RNBQKBNR b KQkq e3 0 1'
      => [ 1, 1, 1, 1, [ 4, 2 ], 0, 1, BLACK ],
      'r3k2r/8/pppppppp/8/8/PPPPPPPP/8/R3K2R w Kk h7 0 25'
      => [ 1, 0, 1, 0, [ 7, 6 ], 0, 25, WHITE ],
      'r3k2r/8/pppppppp/8/8/PPPPPPPP/8/R3K2R b Qq - 15 52'
      => [ 0, 1, 0, 1, [], 15, 52, BLACK ],
    );

  foreach (keys %tests) {
    my $p = Games::Chess::Position->new($_);
    my $v = $tests{$_};
    unless ($p) {
      fail("Position->new('$_') returned undefined.");
      next;
    }
    unless (isa($p,'Games::Chess::Position')) {
      fail("Position->new('$_') didn't return a Games::Chess::Position");
      next;
    }

  my @castles = ( [WHITE,KING], [WHITE,QUEEN], [BLACK,KING], [BLACK,QUEEN] );
    for (my $i = 0; $i < 4; ++$i) {
      my $CASTLE = $p->can_castle(@{$castles[$i]});
      $CASTLE == $v->[$i]
	or fail("Position->new('$_')->can_castle(@{$castles[$i]}) returned $CASTLE - should be $v->[$i]");
      for (my $j = 0; $j < 2; ++$j) {
	$p->can_castle(@{$castles[$i]},$j);
	$CASTLE = $p->can_castle(@{$castles[$i]});
	$CASTLE == $j
	  or fail("After can_castle(@{$castles[$i]},$j) can_castle returned $CASTLE - should be $j");
      }
    }

    my @EP = $p->en_passant;
    @EP == @{$v->[4]}
      and (@EP == 0 or $EP[0] == $v->[4][0] and $EP[1] == $v->[4][1])
	or fail("Position->new('$_')->en_passant returned (@EP) - should be (@{$v->[4]})");
    for (my $i = 0; $i < 8; ++$i) {
      for (my $j = 0; $j < 8; ++$j) {
	$p->en_passant($i,$j);
	@EP = $p->en_passant;
	$#EP == 1 and $EP[0] == $i and $EP[1] == $j
	    or fail("After en_passant($i,$j) en_passant returned (@EP) - should be ($i,$j)");
      }
    }

    my $HALFMOVE = $p->halfmove_clock;
    $HALFMOVE == $v->[5]
      or fail("Position->new('$_')->halfmove_clock returned $HALFMOVE - should be $v->[5]");
    for (my $i = 0; $i < 50; ++$i) {
      $p->halfmove_clock($i);
      $HALFMOVE = $p->halfmove_clock;
      $HALFMOVE == $i
	or fail("After halfmove_clock($i) halfmove_clock returned $HALFMOVE - should be $i");
    }

    my $FULLMOVE = $p->move_number;
    $FULLMOVE == $v->[6]
      or fail("Position->new('$_')->move_number returned $FULLMOVE - should be $v->[6]");
    for (my $i = 1; $i <= 100; ++$i) {
      $p->move_number($i);
      $FULLMOVE = $p->move_number;
      $FULLMOVE == $i
	or fail("After move_number($i) move_number returned $FULLMOVE - should be $i");
    }

    my $PLAYER = $p->player_to_move;
    $PLAYER == $v->[7]
      or fail("Position->new('$_')->player_to_move returned $PLAYER - should be $v->[7]");
    foreach my $player ( BLACK, WHITE ) {
      $p->player_to_move($player);
      $PLAYER = $p->player_to_move;
      $PLAYER == $player
	or fail("After player_to_move($player) player_to_move returned $PLAYER - should be $player");
    }
  }
};

# Test board adjustment methods: at, clear.

do_test {
  my $p = Games::Chess::Position->new;
  foreach my $colour ( BLACK, WHITE ) {
    foreach my $type ( PAWN, KNIGHT, BISHOP, ROOK, QUEEN, KING ) {
      foreach (1..10) {
        my $x = int rand 8;
        my $y = int rand 8;

        $p->clear($x,$y) == 1
	  or fail("clear($x,$y) did not return 1");
        my $piece = $p->at($x,$y);
        my $COLOUR = $piece->colour;
        my $TYPE = $piece->piece;
        $COLOUR == EMPTY
          or fail("After clear($x,$y), at($x,$y)->colour returned $COLOUR - should be @{[EMPTY]}");
        $TYPE == EMPTY
          or fail("After clear($x,$y), at($x,$y)->piece returned $TYPE - should be @{[EMPTY]}");

        $p->at($x,$y,$colour,$type) == 1
	  or fail("at($x,$y,$colour,$type) did not return 1");
        $piece = $p->at($x,$y);
        $COLOUR = $piece->colour;
        $TYPE = $piece->piece;
        $COLOUR == $colour
          or fail("After at($x,$y,$colour,$type), at($x,$y)->colour returned $COLOUR - should be $colour (@{[ord $$piece]})");
        $TYPE == $type
          or fail("After at($x,$y,$colour,$type), at($x,$y)->piece returned $TYPE - should be $type (@{[ord $$piece]})");
      }
    }
  }

};

# Check that the validate method can detect infelicities.

do_test {
  my %tests =
    ( 'K1k5/pppppppp/8/8/8/8/p7/8 w - - 0 5'	    => 'Black has 9 pawns',
      'K1k5/P7/8/8/8/8/PPPPPPPP/8 w - - 0 5'	    => 'White has 9 pawns',
      'nbbbK2k/qqqrrrnn/8/8/8/8/ppppp3/8 w - - 0 5' => 'Black has more than 8',
      'NBBBK2k/QQQRRRNN/8/8/8/8/PPPPP3/8 w - - 0 5' => 'White has more than 8',
      'K7/8/8/8/8/8/8/8 w - - 0 50'		    => 'Black has 0 kings',
      '8/8/8/8/8/8/8/k7 w - - 0 50'		    => 'White has 0 kings',
      'P7/8/8/8/8/8/8/K1k5 w - - 0 50'		    => 'pawn on rank',
      'p7/8/8/8/8/8/8/K1k5 w - - 0 50'		    => 'pawn on rank',
      '8/8/8/8/8/8/8/K1k4P w - - 0 50'		    => 'pawn on rank',
      '8/8/8/8/8/8/8/K1k4p w - - 0 50'		    => 'pawn on rank',
    );
  foreach (keys %tests) {
    my $p = Games::Chess::Position->new($_);
    unless ($p) {
      fail("Position->new('$_') returned undefined.");
      next;
    }
    unless (isa($p,'Games::Chess::Position')) {
      fail("Position->new('$_') didn't return a Games::Chess::Position");
      next;
    }
    my $v = do {
      local $Games::Chess::DEBUG = 0;
      $p->validate;
    };
    not defined $v
      or fail("Position->new('$_')->validate returned $v (should be undef)");
    my $e = Games::Chess::errmsg();
    0 <= index($e, $tests{$_})
      or fail("Position->new('$_')->validate gave error $e");
  }
};
