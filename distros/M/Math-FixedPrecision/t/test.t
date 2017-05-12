#!/bin/perl
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

use Test;
#use strict;

BEGIN
  {
  $| = 1;
  unshift @INC, '../lib'; # for running manually
  unshift @INC, './t'; # to locate the testing files
  # chdir 't' if -d 't';
  plan tests => 40;
  }

use Math::FixedPrecision;
ok ( 1 ); # we loaded correctly

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

my ($number, $newnumber, $thirdnbr);

ok ( $number = Math::FixedPrecision->new(12.346) );

$number = 2.95 + $number;
ok ( "$number", "15.30" );	# has to have that trailing 0

$newnumber = Math::FixedPrecision->new(1.253);
$thirdnbr = $number - $newnumber;
ok ( $thirdnbr, 14.05 );

$number *= 100.125;
ok ( $number == 1531.91 );

$number = Math::FixedPrecision->new(1000.1);
$number /= 99.1234;
ok ( $number == 10.1 );

$number = Math::FixedPrecision->new(1000.1234);
$number /= 99.4;
ok ( $number ==  10.1 );

$number = Math::FixedPrecision->new(9.95);
$number /= 2;	# 2 is internally promoted to 2.00
ok ( $number == 4.98 );	# note the even rounding!
ok ( $number < 5.0 );
ok ( 1.1 < $newnumber );
ok ( $newnumber < $number );
ok ( $number );

$number = Math::FixedPrecision->new("10.");
$newnumber = $number * 2;
ok ( $newnumber == 20 );

$newnumber = $number / 3;
ok ( $newnumber == 3 );

$number = Math::FixedPrecision->new("0.10");
$newnumber = $number * 200;
ok ( $newnumber == 20 );

ok ( "$number" eq "0.10" );

$number = Math::FixedPrecision->new("0.0");
ok ( "$number" eq "0.0" );

$number = Math::FixedPrecision->new(12.345,2);
ok ( $number == 12.34 );

$number= new Math::FixedPrecision(1.0,100);
$newnumber= new Math::FixedPrecision(0.0,100);
ok ( $newnumber < $number );
ok ( $newnumber < 2.0 );

$number= new Math::FixedPrecision(7500);
$newnumber= new Math::FixedPrecision(16.95);

ok ( $newnumber < $number );

$number= new Math::FixedPrecision(14.673);
$newnumber= new Math::FixedPrecision(2.6);

ok ( ! ($newnumber > $number) );

ok ( $number == 14.673 );

$newnumber= new Math::FixedPrecision(2);
ok ( "$newnumber" eq "2" );

$newnumber= new Math::FixedPrecision(.2);
ok ( "$newnumber" eq "0.2" );

$newnumber= new Math::FixedPrecision(12345.6789,0);
ok ( "$newnumber" eq "12346" );

# let's make sure that all of the examples in the pod's work
my ( $height, $width, $area, $length, $section );
$height  = Math::FixedPrecision->new(12.362);   # 3 decimal places
$width   = Math::FixedPrecision->new(9.65);     # 2 decimal places
$area    = $height * $width; # area is now 119.29 not 119.2933
ok ( $area == 119.29 );

$length  = Math::FixedPrecision->new("100.00"); # 2 decimal places
$section = $length / 9; # section is now 11.11 not 11.1111111...
ok ( $section == 11.11 );


$var1 = Math::FixedPrecision->new(10); 		# 10 to infinite decimals
ok (not defined $var1->{_p});
ok ( "$var1" eq "10" );

$var2 = Math::FixedPrecision->new(10,2);	# 10.00 to 2 decimals
ok ( defined $var2->{_p} and $var2->{_p} = -2 );
ok ( "$var2" eq "10.00" );

$var3 = Math::FixedPrecision->new("10.000");	# 10.000 to 3 decimals
ok ( defined $var3->{_p} and $var3->{_p} = -3 );
ok ( "$var3" eq "10.000" );

$var4 = $var3 * 2; 				# 20.000 to 3 decimals
ok ( defined $var4->{_p} and $var4->{_p} = -3 );
ok ( "$var4" eq "20.000" );

$var5 = Math::FixedPrecision->new("2.00");	# 2.00 to 2 decimals
ok ( defined $var5->{_p} and $var5->{_p} = -2 );
ok ( "$var5" eq "2.00" );

$var6 = $var3 * $var5;				# 20.00 to 2 decimals, not 3
ok ( defined $var6->{_p} and $var6->{_p} = -2 );
ok ( "$var6" eq "20.00" );








