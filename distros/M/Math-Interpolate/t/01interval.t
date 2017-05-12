# Before `make' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'
 
use strict;
use vars qw($loaded $NumberTests $ArraySize);

BEGIN {
  $| = 1;
  $NumberTests = 500;
  $ArraySize   = 500;
  print "1..", 2*$NumberTests+6, "\n";
}
END   {print "not ok 1\n" unless $loaded; }

my $ok_count = 1;
sub ok {
  my $ok = shift;
  $ok or print "not ";
  print "ok $ok_count\n";
  ++$ok_count;
  $ok;
}

use Math::IntervalSearch qw(interval_search);

# If we got here, then the package being tested was loaded.
$loaded = 1;
ok(1);									#  1

sub FakeLessThan {
  $_[0] > $_[1];
}
 
sub FakeLessThanEqualTo {
  $_[0] >= $_[1];
}
 
srand();

# Check for illegal parameters.
ok( !interval_search() );						#  2
ok( !interval_search(2) );						#  3
ok( !interval_search(2, 3) );						#  4

# Check that -1 is returned for an empty array.
ok( interval_search(10, []) == -1 );					#  5

# Try to create a properly sorted array by placing new values in the
# correct location in the array.
my @array = ();
for (my $i=0; $i<$ArraySize; ++$i) {
  my $value = rand(100);
  my $location = interval_search($value, \@array) + 1;
  splice(@array, $location, 0, $value);
}

my @array1 = sort {$a <=> $b} @array;
ok( "@array" eq "@array1" );						#  6

# Check a random test.
@array = (0 .. $ArraySize-1);
for (1 .. $NumberTests) {
  my $ok = 1;
  my $number = 1.5 * $ArraySize * rand() - $ArraySize/3;
  my $answer = interval_search($number, \@array);
  if ( $number < 0 ) {
    $ok = 0 unless $answer == -1;
  }
  elsif ( $number >= $ArraySize-1 ) {
    $ok = 0 unless $answer == $ArraySize-1;
  }
  elsif ( int($number) != $answer ) {
    $ok = 0;
  }
  ok( $ok );								#  7
}

# Reverse the array and use some different comparision routines.
@array = reverse @array;

# Check a random test.
for (1 .. $NumberTests) {
  my $ok = 1;
  my $number = 1.5 * $ArraySize * rand() - $ArraySize/3;
  my $answer = interval_search($number, \@array,
                               \&FakeLessThan, \&FakeLessThanEqualTo);
  if ( $number < 0 ) {
    $ok = 0 unless $answer == @array-1;
  }
  elsif ( $number >= $ArraySize-1 ) {
    $ok = 0 unless $answer == -1;
  }
  elsif ( (int(@array - $number)-1) != $answer ) {
    $ok = 0;
  }

  ok( $ok );								#  8
}
