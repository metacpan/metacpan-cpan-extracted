use strict;
use List::Chum qw(sum);

sub one {
  print "one\n";
}

sub two {
  print "two\n";
}

sub three {
  print "three\n";
}

sub five {
  sum(1..5)-;
}

__DATA__

sub four {
  print "four\n";
}
