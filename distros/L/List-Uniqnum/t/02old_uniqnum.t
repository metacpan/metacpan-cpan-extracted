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

my $msc_ver = List::Uniqnum::_have_msc_ver(); 

if($msc_ver && $msc_ver < 1900 && $Config{nvsize} == 8 && $Config{ivsize} == 8) {

  print "1..6\n";

  # Create some UV-NV pairs of equivalent values.
  # Each of these values is exactly representable
  # as either a UV or an NV.

  my @in =  ( 9223372036854775808,  9.223372036854775808e+18,
              1152921504606846976,  1.152921504606846976e+18,
              5764607523034234880,  5.764607523034234880e+18,
              9223372036854774784,  9.223372036854774784e+18,
              18446744073709549568, 1.8446744073709549568e+19,
              18446744073709139968, 1.8446744073709139968e+19,
              100000000000262144,   1.00000000000262144e+17,
            # 100000000001310720,   1.00000000001310720e+17, # This one never needed the workaround
                                                             # because it's only 18-digits long and
                                                             # finishes with '0' - thus allowing "%.20g" 
                                                             # formatting to produce correct results.

              144115188075593728,   1.44115188075593728e+17 );


  my @correct =  ( 9223372036854775808,
                   1152921504606846976,
                   5764607523034234880,
                   9223372036854774784,
                   18446744073709549568,
                   18446744073709139968,
                   100000000000262144,
                 # 100000000001310720,
                   144115188075593728 );

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

  @u = List::Uniqnum::old_uniqnum(-100000000000000016, -100000000000000016.0);

  if(is_deeply(\@u, [-100000000000000016, -100000000000000016.0])) {
    # Test failed as expected
    print "ok 3\n";
  }
  else {
    # Test unexpectedly passed 
    warn "\nGot      @u\nExpected -100000000000000016 ", -100000000000000016.0, "\n";
    print "not ok 3\n";
  }

################################
################################

  @u = List::Uniqnum::old_uniqnum(99999999999999984, 99999999999999984.0);

  if(is_deeply(\@u, [99999999999999984])) {
    # Test passed as expected
    print "ok 4\n";
  }
  else {
    # Test unexpectedly failed 
    warn "\nGot      @u\nExpected 99999999999999984\n";
    print "not ok 4\n";
  }

  @u = List::Uniqnum::old_uniqnum(-99999999999999984, -99999999999999984.0);

  if(is_deeply(\@u, [-99999999999999984])) {
    # Test passed as expected
    print "ok 5\n";
  }
  else {
    # Test unexpectedly failed 
    warn "\nGot      @u\nExpected -99999999999999984\n";
    print "not ok 5\n";
  }

  if(List::Uniqnum::uv_fits_double(1073741825)) {
    print "ok 6\n";
  }
  else {
    warn "\n Expected 1 but got ", List::Uniqnum::uv_fits_double(1073741825), "\n";
    print "not ok 6\n";
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