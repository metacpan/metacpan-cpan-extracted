# Test Games::Chess::Position::to_GIF (-*- cperl -*-)

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

my $gif = 0;

# Check Position->to_GIF on each position:

do_test {
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
  foreach my $c (keys %tests) {
    my $p = Games::Chess::Position->new($c);
    next unless $p->validate;
    #++$gif;
    #open(GIF, "> /tmp/chess$gif.gif")
    #  or die "Couldn't open /tmp/chess$gif.gif: $!";
    #print GIF
      $p->to_GIF;
    #close(GIF);
  }
};

# Now check it for various combinations of input parameters:

do_test {
  require GD;
  my @inputs = ( [ letters => 0 ],
		 [ font => GD::Font->Tiny ],
		 [ lmargin => 50, bmargin => 60, border => 20 ] );
  foreach (@inputs) {
    my $p = Games::Chess::Position->new;
    next unless $p->validate;
    #++$gif;
    #open(GIF, "> /tmp/chess$gif.gif")
    #  or die "Couldn't open /tmp/chess$gif.gif: $!";
    #print GIF
      $p->to_GIF(@$_);
    #close(GIF);
  }
};
