use strict;
use warnings;
use File::Temp;
use Test::More 0.88;
require './t/TestUtils.pm';
t::TestUtils->import();

use bignum;
use IO::Pager::Page;

SKIP: {
  skip_interactive();

  $a=1; $b=1;
  eval{
    print $a, "\n";

    #Fibonacci is the golden ratio
    ($a,$b)=($b,$a+$b);
  } until( eof(*STDOUT) );

  print "Pager closed, wrapping up.\n";
  my $A = prompt("\nWere things wrapped up after you quit the pager? [Yn]");
  ok is_yes($A), 'Signal handling EOF';
}

done_testing;
