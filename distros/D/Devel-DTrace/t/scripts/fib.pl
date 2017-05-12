#!perl

sub fib {
  my $n = shift;
  return 1 if $n < 2;
  return fib( $n - 1 ) + fib( $n - 2 );
}

fib( 4 );

# The expected output
__DATA__
ENTRY(fib, t/scripts/fib.pl, 9)
ENTRY(fib, t/scripts/fib.pl, 6)
ENTRY(fib, t/scripts/fib.pl, 6)
ENTRY(fib, t/scripts/fib.pl, 6)
RETURN(fib, t/scripts/fib.pl, 6)
ENTRY(fib, t/scripts/fib.pl, 6)
RETURN(fib, t/scripts/fib.pl, 6)
RETURN(fib, t/scripts/fib.pl, 6)
ENTRY(fib, t/scripts/fib.pl, 6)
RETURN(fib, t/scripts/fib.pl, 6)
RETURN(fib, t/scripts/fib.pl, 6)
ENTRY(fib, t/scripts/fib.pl, 6)
ENTRY(fib, t/scripts/fib.pl, 6)
RETURN(fib, t/scripts/fib.pl, 6)
ENTRY(fib, t/scripts/fib.pl, 6)
RETURN(fib, t/scripts/fib.pl, 6)
RETURN(fib, t/scripts/fib.pl, 6)
RETURN(fib, t/scripts/fib.pl, 9)
