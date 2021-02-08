# Converts a recurring (unsigned) decimal to a rational number.
#
# Expects 3 command line arguments - the leading (non-recurring part) of the
# decimal, and the recurring (trailing) part, and a third arg that specifies
# the location of the decimal point.
# If the decimal point lies between the first 2 args, then the 3rd arg is zero.
# Negative values indicate positions to the left, positive values indicate
# positions to the right.
# eg 2.414141... requires args 2, 41, 0
#    24.14141... requires args 2, 41, 1 (or 24, 14, 0)
#    241.4141... requires args 2, 41, 2 (or 241, 41, 0)
#
#    2.00414141... requires args 200, 41, -2
#    20.0414141... requires args 200, 41, -1
#    200.414141... requires args 200, 41, 0

# For decimals that terminate (ie that are not recurring, just specify a
# second arg of 0
# eg 0.02004 requires args 2004, 0, -5
#     2.004 requires args 2004, 0, -3
#     20.04 requires args 2004, 0, -2
#     200.4 requires args 2004, 0, -1


use strict;
use warnings;
use Math::GMPz qw(:mpz);
use Scalar::Util qw(looks_like_number);

die "Usage 'perl dec2rat.pl [leading] [recurring] [dp]'"
  if(@ARGV != 3);

die "1st arg must not be signed" if $ARGV[0] =~ /^[\-\+]/;
die "2nd arg must not be signed" if $ARGV[1] =~ /^[\-\+]/;

die "Non-numeric characters detected in one (or more) of the supplied args"
  if($ARGV[0] =~ /[^0-9]/ || $ARGV[1] =~ /[^0-9]/ || $ARGV[2] =~ /[^0-9\-\+]/);

die "looks_like_number returned false for one (or more) of the supplied args"
  if(!looks_like_number $ARGV[0] || !looks_like_number $ARGV[1] ||
     !looks_like_number $ARGV[2]);

my @rat = dec2rat(@ARGV);
print "$rat[0] / $rat[1]\n";


sub dec2rat {
  my $denominator = Math::GMPz->new(10) ** length $ARGV[1];
  $denominator--;
  my $numerator = Math::GMPz->new($ARGV[0] . $ARGV[1], 10) - $ARGV[0];

  $numerator   *= Math::GMPz->new(10) ** $ARGV[2] if $ARGV[2] > 0;
  $denominator *= Math::GMPz->new(10) ** ($ARGV[2] * -1) if $ARGV[2] < 0;

  reduce ($numerator, $denominator);
  return ($numerator, $denominator);
}

sub reduce {
  my $gcd = Math::GMPz->new();
  while(1) {
    Rmpz_gcd($gcd, $_[0], $_[1]);
    if($gcd > 1) {
      $_[0] /= $gcd;
      $_[1] /= $gcd;
    }
    else {last}
  }
}

__END__
