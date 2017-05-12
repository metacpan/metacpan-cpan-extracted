#!perl

sub xx { }

sub yy {
  eval { xx() };
}

yy();

# The expected output
__DATA__
ENTRY(yy, t/scripts/eval.pl, 9)
ENTRY(xx, t/scripts/eval.pl, 6)
RETURN(xx, t/scripts/eval.pl, 6)
RETURN(yy, t/scripts/eval.pl, 9)
