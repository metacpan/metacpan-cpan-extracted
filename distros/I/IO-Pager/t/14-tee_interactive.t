use strict;
use warnings;
use Test::More 0.88;
require './t/TestUtils.pm';
t::TestUtils->import();

use bignum;
use IO::Pager;


SKIP: {
  skip_interactive();

  local $STDOUT = new IO::Pager *STDOUT;
  eval{ require PerlIO::Util };
  skip("Could not load PerlIO::Tee") if $@;

  binmode(*STDOUT, ":tee($$.log)");
  #Equivalent to
  #$STDOUT->binmode(":tee($$.log)");

  $a=2308; $b=4261;
  print my $LOG ="Exit your pager after a bit\n";
  eval{
    $LOG .= "$a\n";
    print $a, "\n";

    #Brady numbers also the golden ratio
    ($a,$b)=($b,$a+$b);

    select(undef, undef, undef, 0.15);
  } until( eof(*STDOUT));  
  print "Pager closed, checking log.\n";
  open(LOG, "$$.log") or die "Missing $$.log: $!";
  my $TEE = join('', <LOG>);
  cmp_ok($LOG, 'eq', $TEE, 'PerlIO::tee test passed');
}

done_testing;

END{ unlink("$$.log") }
