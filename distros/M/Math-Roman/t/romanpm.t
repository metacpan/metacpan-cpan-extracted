#!/usr/bin/perl -w

use strict;
use Test;

BEGIN
  {
  $| = 1;
  # chdir 't' if -d 't';
  unshift @INC, '../lib'; # for running manually
  plan tests => 1097;
  }

use Math::Roman qw/roman/;

my (@args,$try,$rc,$x,$i,$y);
$| = 1;
while (<DATA>)
  {
  chop;
  @args = split(/:/,$_,99);

  # test Roman => Arabic
  $try = "\$x = Math::Roman->new('$args[0]')";
  $try .= "->as_number(); ";

  $rc = eval $try;

  print "# For '$try'\n" if (!ok "$rc" , $args[1]);

  # test Arabic => Roman
  next if $args[1] eq 'NaN'; # dont test NaNs reverse
  $try = "\$x = Math::Roman->new('$args[1]');";

  $rc = eval $try;
  print "# For '$try'\n" if (!ok "$rc" , $args[2] || $args[0]);

  }
close DATA;

# check if negative numbers give same output as positives
  $try =  "\$x = Math::Roman->new(-12);";
  $rc = eval $try;
  print "# For '$try'\n" if (!ok "$rc" , "XII" );

# roman('1234') should work

$x = roman('M'); ok ($x,'M');
$x = roman('1000'); ok ($x,'M');

###############################################################################
# check if output of bstr is again a valid Roman number

for ($i = 1; $i < 1004; $i++)
  {
  $try = "\$x = Math::Roman->new($i);";
  $try .= "\$y = Math::Roman->new(\"\$x\")->as_number(); # ";
  $rc = eval $try;
  # not worth the effort to eliminate eval
  print "# For '$try'\n" if (!ok "$rc" , $i );
  }

# test wether + works
  $try =  '$x = Math::Roman->new("MXI");';
  $try .=  '$x += "M";';

  $rc = eval $try;
  print "# For '$try'\n" if (!ok "$rc" , 'MMXI');

# test wether ++ and -- work correctly
  $try =  '$x = Math::Roman->new("MCMLXII");';
  $try .=  '$y = $x; $y++; "true" if $x < $y';

  $rc = eval $try;
  print "# For '$try'\n" if (!ok "$rc" , 'true');

  $try =  '$x = Math::Roman->new("MCMLXII");';
  $try =  '$y = $x; $y++; $y--; "true" if $x == $y;';
  $rc = eval $try;
  print "# For '$try'\n" if (!ok "$rc" , 'true');

# test wether tokens works correctly

  $try = 'use Math::Roman; Math::Roman::tokens ( qw( I 1  V 5  X 10  L 50  C 100  D 500  M 1000) );';
  $try .= '$x = new Math::Roman "XIIII"; $x = $x->as_number();';
  $rc = eval $try;
  print "# For '$try'\n" if (!ok "$rc" , "14" );

############ watch out - changed tokens from now on! ###########

1;

__END__
abc:NaN
mcmlx:NaN
:0
I:1
V:5
X:10
L:50
C:100
D:500
M:1000
III:3
XXX:30
CCC:300
II:2
XX:20
CC:200
IV:4
IX:9
XL:40
XC:90
CD:400
CM:900
XII:12
MCMXCIX:1999
MM:2000
MMM:3000
MMMM:4000
MCMLXI:1961
MCMLXXIII:1973
VX:NaN
VX:NaN
VL:NaN
VC:NaN
VD:NaN
LM:NaN
LC:NaN
LD:NaN
LM:NaN
IL:NaN
IC:NaN
ID:NaN
IM:NaN
XD:NaN
XM:NaN
CMC:NaN
CMD:NaN
CDC:NaN
XCD:NaN
IIII:NaN
XXXX:NaN
CCCC:NaN
DD:NaN
LL:NaN
VV:NaN
XCXL:NaN
CXXX:130
LXL:NaN
IM:NaN
ID:NaN
