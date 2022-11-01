# Show the byte-structure of the NVs 1e+127 and
# sqrt(2) for various Nv types, in both big-endian
# and little-endian order.

use strict;
use warnings;
use Config;
use Math::NV qw(:all);

if($] < 5.022) {
  die "This script needs at least version 5.22 of perl";
}

if($Math::MPFR::VERSION < 4.02) {
  die "This script needs at least version 4.02 of Math::MPFR";
}

my %h = (53 => 'double', '2098' => 'double-double');

my @types = (53, 2098);

if($Config{longdblkind} < 0) {
  print "Unrecognized long double\n";
}

elsif($Config{longdblkind} == 0) {
  $h{53} = 'double and long double';
}

elsif($Config{longdblkind} < 3) {
  $h{113} = '128-bit long double';
  push @types, 113;
}

elsif($Config{longdblkind} < 5){
  $h{64} = '80-bit long double';
  push @types, 64;
}

else {
  $h{2098} = 'double-double (long double)';
}

if(Math::MPFR::Rmpfr_buildopt_float128_p() && !$h{113}) {
  $h{113} = '__float128';
  push @types, 113;
}

my $v = '1e+127';

print "\nFor $v:\n";

for my $bits(@types) {
  my $hex = nv_mpfr($v, $bits);

  if($bits == 2098) {
    print " double-double:\n";
    print "   big-endian   :\n";
    print "     ", $hex->[0], " ", $hex->[1], "\n";
    print "   little-endian:\n";
    print "     ", scalar(reverse($hex->[0])), " ",
                   scalar(reverse($hex->[1])), "\n\n";

  }
  else {
    print " $h{$bits}:\n";
    print "   big-endian   :\n";
    print "     $hex\n";
    print "   little-endian:\n";
    print "     ", scalar(reverse($hex)), "\n\n";
  }
}

print "\nFor sqrt(2):\n";

for my $bits(@types) {
  Math::MPFR::Rmpfr_set_default_prec($bits);
  my $v = Math::MPFR->new(2) ** 0.5;
  my $hex = nv_mpfr("$v", $bits);

  if($bits == 2098) {
    print " double-double:\n";
    print "   big-endian   :\n";
    print "     ", $hex->[0], " ", $hex->[1], "\n";
    print "   little-endian:\n";
    print "     ", scalar(reverse($hex->[0])), " ",
                   scalar(reverse($hex->[1])), "\n\n";

  }
  else {
    print " $h{$bits}:\n";
    print "   big-endian   :\n";
    print "     $hex\n";
    print "   little-endian:\n";
    print "     ", scalar(reverse($hex)), "\n\n";
  }
}
