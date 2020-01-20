# This test requires that nvtype is 'long double'.
# Ironically, this module is not particularly
# useful on a perl whose nvtype is 'long double'.

use strict;
use warnings;
use Config;
use Math::LongDouble qw(:all);

unless($Config{nvtype} eq 'long double') {
 print "1..1\n";
  warn "\n Skipping all tests - nvtype ('$Config{nvtype}') is not 'long double'\n";
  print "ok 1\n";
  exit 0;
}

if($] < 5.01) {
 print "1..1\n";
  warn "\n Skipping all tests - perl version is $], but 5.01 or greater is needed\n";
  print "ok 1\n";
  exit 0;
}

 print "1..1\n";

my $s = '9025.625';

my $ld = Math::LongDouble->new($s);

my $perl_bytes = scalar reverse unpack "h*", pack "F<", $s;
my $m_ld_bytes = ld_bytes($ld);

if($perl_bytes =~ /$m_ld_bytes$/) { print "ok 1\n" }
else {
  warn "\n$perl_bytes and $m_ld_bytes do not match as expected\n";
  print "not ok 1\n";
}


