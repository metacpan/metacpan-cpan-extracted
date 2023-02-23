# Provide floating point values on the command line (@ARGV) and see those
# values represented in doubledouble big endian format.
# The subs dd_str() and dd_obj() return both doubles ($msd, $lsd) - where $msd is the most
# significant double and $lsd the least significant double. The actual value represented by
# the double is the sum of the two doubles.

# As an example, try:
# perl doubledouble.p 2.3 1e+127 0x17.fe99991f9999999999999888888888888888888

use warnings;
use strict;

use Math::MPFR qw(:mpfr);
use POSIX; # Needed by dd_str() and dd_obj() to deal
           # with 2 specific cases.

die "Must provide at least one command line argument" if !@ARGV;

for my $float(@ARGV) {
  my($msd, $lsd) = dd_str($float);
  print "$float\n";
  printf "%.17g %.17g\n", $msd, $lsd;
  print internal_hex($msd) .  " ";
  print internal_hex($lsd) .  "\n";

  my $test = Rmpfr_init2(2098);
  Rmpfr_set_str($test, $float, 0, MPFR_RNDN);

  my @check = dd_obj($test);

  if($check[0] == $msd && $check[1] == $lsd) {
    print "dd_obj() checks out correctly\n";
  }
  else {print "dd_obj() failed\n"}

  @check = dd2dd($msd, $lsd);

  if($check[0] == $msd && $check[1] == $lsd) {
    print  "dd2dd() checks out correctly\n\n";
  }
  else {print "dd2dd() failed\n\n"}
}

################################################
################################################

sub dd_str {
  my $val = Rmpfr_init2(2098); # Max precision that can be encapsulated in doubledouble
  Rmpfr_set_str($val, $_[0], 0, MPFR_RNDN);
  my $msd = Rmpfr_get_d($val, MPFR_RNDN);
  if($msd == 0 || $msd != $msd || $msd / $msd != 1) {return ($msd, 0.0)} # it's  inf, nan or zero.
  $val -= $msd;
  my $lsd = Rmpfr_get_d($val, MPFR_RNDN);

  # At this point, we could simply return ($msd, $lsd)
  # if not for the possibility that $msd and $lsd have
  # the same sign && abs($msd) == POSIX::DBL_MAX &&
  # abs($lsd) == 2 ** 970

  return ($msd, $lsd)
    unless ($msd ==  POSIX::DBL_MAX && $lsd ==   2 ** 970) ||
           ($msd == -POSIX::DBL_MAX && $lsd == -(2 ** 970));

  return ($msd + $lsd, 0); # ie return (Inf, 0) or (-Inf, 0) as appropriate
}

# sub dd_obj takes a Math::MPFR object (with 2098-bit precision) as its arg
sub dd_obj {
  my $obj = shift;
  die "arg to dd_obj() is not a Math::MPFR object" if Math::MPFR::_itsa($obj) != 5;
  my $prec = Rmpfr_get_prec($obj);
  die "arg to dd_obj() has $prec bits of precision - but needs to have 2098 bits" if $prec != 2098;
  my $msd = Rmpfr_get_d($obj, MPFR_RNDN);
  if($msd == 0 || $msd != $msd || $msd / $msd != 1) {return ($msd, 0.0)} # $msd is zero, nan, or inf.
  $obj -= $msd;
  my $lsd = Rmpfr_get_d($obj, MPFR_RNDN);

  # At this point, we could simply return ($msd, $lsd)
  # if not for the possibility that $msd and $lsd have
  # the same sign && abs($msd) == POSIX::DBL_MAX &&
  # abs($lsd) == 2 ** 970

  return ($msd, $lsd)
    unless ($msd ==  POSIX::DBL_MAX && $lsd ==   2 ** 970) ||
           ($msd == -POSIX::DBL_MAX && $lsd == -(2 ** 970));

  return ($msd + $lsd, 0); # ie return (Inf, 0) or (-Inf, 0) as appropriate
}

# sub dd2dd takes 2 doubles as arguments. It returns the 2 doubles (msd, lsd) that form the
# double-double representation of the sum of the 2 arguments. We can therefore use this function
# to question whether the 2 arguments are a valid double-double pair - the answer being "yes" if
# and only if dd2dd() returns the identical 2 values that it received as arguments.
# In the process, it prints out the internal hex representations of both arguments, and the
# internal hex representations of the 2 doubles that it returns.

sub dd2dd {
  my $val = Rmpfr_init2(2098);
  Rmpfr_set_ui($val, 0, MPFR_RNDN);
  print " HEX_INPUT :  ", internal_hex($_[0]), " ", internal_hex($_[1]), "\n";
  Rmpfr_add_d($val, $val, $_[0], MPFR_RNDN);
  Rmpfr_add_d($val, $val, $_[1], MPFR_RNDN);
  my @ret = dd_obj($val);
  print " HEX_OUTPUT:  ", internal_hex($ret[0]), " ", internal_hex($ret[1]), "\n";
  return @ret;
}

# sub internal_hex returns the internal hex format (byte structure) of the double precision
# argument it received.
sub internal_hex {
  return unpack("H*", (pack "d>", $_[0]));
}

# sub internal_hex2dec does the reverse of internal_hex() - ie returns the value, derived from
# the internal hex argument.
sub internal_hex2dec {
  return unpack "d>", pack "H*", $_[0];
}

__END__

