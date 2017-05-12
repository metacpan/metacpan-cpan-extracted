use strict;

BEGIN {
  $| = 1;
  use vars qw/$loaded/;
  $loaded = 0;
  print "Running tests\n";
}

END {
  print "not ok 1\n" unless $loaded;
}

use List::Intersperse qw/intersperse intersperseq/;
$main::loaded = 1;
print "ok 1\r";

my $test_nm = 1;
while (<DATA>) {
  chop;
  $test_nm++;
  my @olis = split; # original list
  $_ = <DATA>; chop;
  my @elis = split; # expected list
  my @ilis = intersperse @olis; # interspersed list
  if ("@elis" eq "@ilis") {
    print "ok $test_nm\r";
  } else {
    print "e: @elis\ni: @ilis";
    print "\nnot ok $test_nm\n";
  }

  $test_nm++;
  @ilis = intersperseq { $_[0] } @olis;
  if ("@elis" eq "@ilis") {
    print "ok $test_nm\r";
  } else {
    print "e: @elis\ni: @ilis";
    print "\nnot ok $test_nm\n";
  }
}

print "\n";

__DATA__
A A B B C C
A C B C B A
A A A A A A A A
A A A A A A A A
A A A B B B C C C D D D E E E F F F G G G H H H I I I
A I H G F E D C B I H G F E D C B A I H G F E D C B A
A A A B C C C D D E F F G G G G H I I J K K K L L L
J G L K A C I G F D L K A G C E I F L K G A C D H B
H H H H H H H H H H H H S S S S S S S S S S S S D D D D D D D D D D D D C C C C C C C C C C C C
C H D S H D S C H D S C H D S C H D S C H D S C H D S C H D S C H D S C H D S C H D S C H D S C
