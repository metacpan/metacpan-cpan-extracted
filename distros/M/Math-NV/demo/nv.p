# Test a range of values for
# correctness of assignment

use strict;
use warnings;
use Math::MPFR qw(:mpfr);
use Math::NV qw(:all);

die "Upgrade to Math-MPFR-4.02"
  unless $Math::MPFR::VERSION >= 4.02;

die "Upgrade to Math-NV-2.0 or later"
  unless $Math::NV::VERSION >= 2.0;

die "Usage: perl nv2.pl maximum_exponent how_many_values"
  unless @ARGV == 2;

$|++;

my $display = 0;

while($display !~ /^y/i && $display !~ /^n/i) {
  print("Do you want mismatched values to be displayed ? [y|n]: \n");
  $display = <STDIN>;
}

$Math::NV::no_warn = 2 if $display =~ /^n/i;

my($mant, $exp);
my $count = 0;
my $max_exp = $ARGV[0];

$max_exp++;
my $failed = 0;

for(;;) {
  $count++;
  $mant = int(rand(10))
           . '.'
           . int(rand(10))
           . int(rand(10))
           . int(rand(10))
           . int(rand(10))
           . int(rand(10));
  $mant = '-' . $mant unless $count % 2;
  $exp = int(rand($max_exp));
  $exp = '-' . $exp if $count % 2;
  $exp = 'e' . $exp;
  $mant .= $exp;

  $failed++ unless is_eq_mpfr($mant);

  # die if the value that perl assigns differs
  # from that assigned by strtod/strtold/strtoflt128
  #die "$count: $mant\n" unless is_eq($mant);
  last if $count == $ARGV[1];
}

END {
print "Count: $count\n";
print "Failed: $failed\n";
};
