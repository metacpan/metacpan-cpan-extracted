# The aim here is to check that old_uniqnum fails a specific test with MS compilers.
# This test fails with my Platform SDK (Microsoft Compiler) but I don't know
# whether all other MS compilers are afflicted.
# The problem is specific to builds of perl whose $Config{nvsize} == $Config{ivsize},
# so we test only if the compiler is a Microsoft one && $Config{nvsize} == $Config{ivsize}.
# Otherwise, the test is skipped.

use strict;
use warnings;
use Config;
use List::Uniqnum;

if(List::Uniqnum::_have_msc_ver() && $Config{nvsize} == 8 && $Config{ivsize} == 8) {

  print "1..3\n";

  my $ls = 63;
  
  my @in = (1 << $ls, 2 ** $ls,
            1 << ($ls - 3), 2 ** ($ls - 3),
            5 << ($ls - 3), 5 * (2 ** ($ls - 3)));

  my $p_53 = (1 << 53) - 1; # 9007199254740991

  # To obtain an NV, we need to first divide $p_53 by 2
  push @in, ($p_53 * 1024, $p_53/ 2 * 2048.0,
             $p_53 * 2048, $p_53 / 2 * 4096.0,
             ($p_53 -200) * 2048, ($p_53 - 200) / 2 * 4096.0,
              100000000000262144, 1.00000000000262144e17,
              144115188075593728, 1.44115188075593728e17);

  my @u = List::Uniqnum::old_uniqnum(@in);

  if(is_deeply(\@u, \@in)) {
    # Test failed as expected
    print "ok 1\n";
  }
  else {
    # Test unexpectedly passed 
    warn "\nGot      @u\nExpected @in\n";
    print "not ok 1\n";
  }

################################
################################

  @u = List::Uniqnum::old_uniqnum(100000000000000016, 100000000000000016.0);

  if(is_deeply(\@u, [100000000000000016, 100000000000000016.0])) {
    # Test failed as expected
    print "ok 2\n";
  }
  else {
    # Test unexpectedly passed 
    warn "\nGot      @u\nExpected 100000000000000016 ", 100000000000000016.0, "\n";
    print "not ok 2\n";
  }

################################
################################

  @u = List::Uniqnum::old_uniqnum(99999999999999984, 99999999999999984.0);

  if(is_deeply(\@u, [99999999999999984])) {
    # Test passed as expected
    print "ok 3\n";
  }
  else {
    # Test unexpectedly failed 
    warn "\nGot      @u\nExpected @in\n";
    print "not ok 3\n";
  }

################################
################################
}

else {
  print "1..1\n";
  if(List::Uniqnum::uv_fits_double(1073741825)) {
    print "ok 1\n";
  }
  else {
    warn "\n Expected 1 but got ", List::Uniqnum::uv_fits_double(1073741825), "\n";
    print "not ok 1\n";
  }
}   

sub is_deeply {
  my @one = @{$_[0]};
  my @two = @{$_[1]};
  my $items = scalar @one;
  return 0 if $items != @two;
  
  for(my $i = 0; $i < $items; $i++) {
    if($one[$i] != $two[$i]) {
      warn "\n$one[$i] != $two[$i]\n";
      return 0;
    }

    if($one[$i] ne $two[$i]) {
      warn "\n'$one[$i]' ne '$two[$i]'\n";
      return 0;
    }
  }

  return 1;
}