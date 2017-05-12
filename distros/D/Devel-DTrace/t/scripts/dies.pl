#!perl

sub deep {
  my $n = shift;
  die "Too deep" if $n == 0;
  deep( $n - 1 );
}

eval { deep( 10 ) };

# The expected output
__DATA__
ENTRY(deep, t/scripts/dies.pl, 9)
ENTRY(deep, t/scripts/dies.pl, 6)
ENTRY(deep, t/scripts/dies.pl, 6)
ENTRY(deep, t/scripts/dies.pl, 6)
ENTRY(deep, t/scripts/dies.pl, 6)
ENTRY(deep, t/scripts/dies.pl, 6)
ENTRY(deep, t/scripts/dies.pl, 6)
ENTRY(deep, t/scripts/dies.pl, 6)
ENTRY(deep, t/scripts/dies.pl, 6)
ENTRY(deep, t/scripts/dies.pl, 6)
ENTRY(deep, t/scripts/dies.pl, 6)
RETURN(deep, t/scripts/dies.pl, 9)
RETURN(deep, t/scripts/dies.pl, 9)
RETURN(deep, t/scripts/dies.pl, 9)
RETURN(deep, t/scripts/dies.pl, 9)
RETURN(deep, t/scripts/dies.pl, 9)
RETURN(deep, t/scripts/dies.pl, 9)
RETURN(deep, t/scripts/dies.pl, 9)
RETURN(deep, t/scripts/dies.pl, 9)
RETURN(deep, t/scripts/dies.pl, 9)
RETURN(deep, t/scripts/dies.pl, 9)
RETURN(deep, t/scripts/dies.pl, 9)
