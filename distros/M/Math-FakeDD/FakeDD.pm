package Math::FakeDD;

use strict;
use warnings;
use Math::MPFR qw(:mpfr);

use Config;

use 5.022; # for $Config{longdblkind}

use constant MPFR_LIB_VERSION   => MPFR_VERSION;

use constant NAN_COMPARE_BUG    => $Math::MPFR::VERSION < 4.23  ? 1 : 0;

# The dd_repro() sub requires Math-MPFR-4.24
use constant M_MPFR_VER_OK      => $Math::MPFR::VERSION >= 4.24 ? 1 : 0;

use constant NV_IS_DOUBLE       => $Config{nvsize} == 8         ? 1 : 0;

use constant NV_IS_DOUBLEDOUBLE => $Config{nvsize} != 8 &&
                                   ($Config{longdblkind} >=5 && $Config{longdblkind} <= 8) ? 1 : 0;

use constant NV_IS_QUAD => $Config{nvtype} eq '__float128' ||
                           ($Config{nvtype} eq 'long double' && $Config{longdblkind} > 0
                              && $Config{longdblkind} < 3)                                 ? 1 : 0;

use constant NV_IS_80BIT_LD => $Config{nvtype} eq 'long double' &&
                               $Config{longdblkind} > 2 && $Config{longdblkind} < 5         ? 1 : 0;

use constant M_FDD_DBL_MAX  => Rmpfr_get_d(Math::MPFR->new('1.fffffffffffffp+1023', 16), 0);
use constant M_FDD_P2_970   => 2 ** 970;
use constant DBL_DENORM_MIN => 2 ** -1074;

use overload
'abs'   => \&dd_abs,
'atan2' => \&dd_atan2,
'bool'  => \&dd_true,
'cos'   => \&dd_cos,
'eq'    => \&dd_streq,
'ne'    => \&dd_strne,
'exp'   => \&dd_exp,
'int'   => \&dd_int,
'log'   => \&dd_log,
'sin'   => \&dd_sin,
'sqrt'  => \&dd_sqrt,
'+'     => \&dd_add,
'+='    => \&dd_add_eq,
'/'     => \&dd_div,
'/='    => \&dd_div_eq,
'=='    => \&dd_eq,
'>'     => \&dd_gt,
'>='    => \&dd_gte,
'<'     => \&dd_lt,
'<='    => \&dd_lte,
'*'     => \&dd_mul,
'*='    => \&dd_mul_eq,
'!='    => \&dd_neq,
'**'    => \&dd_pow,
'**='   => \&dd_pow_eq,
'<=>'   => \&dd_spaceship,
'""'    => \&dd_stringify,
'0+'    => \&dd_numify,
'-'     => \&dd_sub,
'-='    => \&dd_sub_eq,
'!'     => \&dd_false,
'='     => \&overload_copy,
'++'    => \&overload_inc,
'--'    => \&overload_dec,
;

require Exporter;
*import = \&Exporter::import;
require DynaLoader;

my $v = MPFR_VERSION_MAJOR;
if($v < 4) {
  $Math::FakeDD::MPFR_PREC_MIN = 2;
  warn "
  This module requires that Math::MPFR was built against version 4
  of the mpfr C library. You have only ", Rmpfr_get_version, ".\n",
  "  As a result, you will experience a fatal assertion error whenever
  the mpfr library needs to use a 1-bit precision value.
  Some test suite tests are skipped to avoid such an error.
  The need to use a 1-bit precision value is fairly limited, so
  we'll go ahead anyway. You have been warned !!\n";
}
else {   $Math::FakeDD::MPFR_PREC_MIN = 1 }

my @tags = qw(
  NV_IS_DOUBLE NV_IS_DOUBLEDOUBLE NV_IS_QUAD NV_IS_80BIT_LD MPFR_LIB_VERSION
  dd_abs dd_add dd_add_eq dd_assign dd_atan2 dd_catalan dd_cmp dd_clone dd_copy dd_cos dd_dec
  dd_div dd_div_eq dd_dump dd_eq dd_euler dd_exp dd_exp2 dd_exp10 dd_frexp
  dd_gt dd_gte dd_hex dd_inf dd_is_inf dd_is_nan dd_int dd_log dd_log2 dd_log10 dd_lt dd_lte
  dd_mul dd_mul_eq dd_nan dd_neq
  dd_nextup dd_nextdown dd_numify dd_pi dd_pow dd_pow_eq dd_repro dd_repro_test
  dd_sin dd_spaceship dd_sqrt dd_streq dd_stringify dd_strne
  dd_sub dd_sub_eq
  dd2mpfr mpfr2dd mpfr_any_prec2dd mpfr2098
  printx sprintx any2dd unpackx
  ulp_exponent is_subnormal
);

@Math::FakeDD::EXPORT_OK = (@tags);

%Math::FakeDD::EXPORT_TAGS = (all => [@tags]);

$Math::FakeDD::VERSION =  '1.03';
Math::FakeDD->DynaLoader::bootstrap($Math::FakeDD::VERSION);

sub dl_load_flags {0} # Prevent DynaLoader from complaining and croaking

# Whenever dd_repro($obj) returns its string representation of
# the value of $obj, $Math::FakeDD::REPRO_PREC is set to the
# bit-precision that was used to derive that returned value.
# This variable will be set to zero if an Inf, NaN or zero
# $obj is passed to dd_repro().The initial value of -1 indicates
# that dd_repro() has not been called at all.

$Math::FakeDD::REPRO_PREC = -1;
$Math::FakeDD::DD_MAX = Math::FakeDD->new(Rmpfr_get_d(Math::MPFR->new('1.fffffffffffffp+1023', 16), MPFR_RNDN))
                        + Rmpfr_get_d(Math::MPFR->new('1.fffffffffffffp+969', 16), MPFR_RNDN);



sub new {

  my %h = ('msd' => 0.0, 'lsd' => 0.0, 'mpfr' => Rmpfr_init2(2098));
  unless(@_) {
    Rmpfr_set_zero($h{mpfr}, 1);
    return bless(\%h);
  }

  if(!ref($_[0]) && $_[0] eq "Math::FakeDD") {
    # 'new' has been called as a method
    shift;
    unless(@_) {
      Rmpfr_set_zero($h{mpfr}, 1);
      return bless(\%h);
    }
  }

  die "Too many args given to new()" if @_ > 1;

  # If the remaining argument is a Math::FakeDD
  # object then simply return a copy of it:
  return shift
    if ref($_[0]) eq "Math::FakeDD";

  return mpfr2dd(mpfr2098(shift));
}

sub dd_repro {
  die "Arg given to dd_repro() must be a Math::FakeDD object"
    unless ref($_[0]) eq 'Math::FakeDD';

  unless(M_MPFR_VER_OK) {
    warn "dd_repro() needs Math-MPFR-4.24 or later, but you have only $Math::MPFR::VERSION\n";
    die "Please update Math::MPFR if you wish to call dd_repro()";
  }

  my $arg = mpfr2dd($_[0]->{mpfr});
  my $prec = 0;
  if(dd_is_nan($arg)) {
    $Math::FakeDD::REPRO_PREC = 0;
    return 'NaN';
  }

  if(dd_is_inf($arg)) {
    $Math::FakeDD::REPRO_PREC = 0;
    return'Inf' if $arg > 0;
    return'-Inf';
  }

  if($arg == 0) {
    $Math::FakeDD::REPRO_PREC = 0;
    return '0.0';
  }

  if(NV_IS_DOUBLEDOUBLE) {
    # A correction was made here in Math-FakeDD-0.09.
    # However, it relies on nvtoa() being correct, and
    # I don't have a machine on which I can verfiy that.
    # (The replaced code also relied on correctness of nvtoa.)
    $Math::FakeDD::REPRO_PREC = undef; # nvtoa() doesn't tell us the precision.
    my $ret = dd2mpfr($arg->{msd});
    Rmpfr_add($ret, $ret, dd2mpfr($arg->{lsd}), MPFR_RNDN);
    return nvtoa(dd2mpfr(Rmpfr_get_NV($ret, MPFR_RNDN)));
  }

  my $neg = 0;
  # my $mpfr = dd2mpfr($arg); # old code
  my $mpfr = $arg->{mpfr};

  if($mpfr < 0) {
    Rmpfr_neg($mpfr, $mpfr, MPFR_RNDN);
    $neg = 1;
  }

  my $exp = Rmpfr_get_exp($mpfr);

  if($arg->{lsd} == 0) {
    my $addon = 1074;
    if( MPFR_LIB_VERSION < 262146 ) { # 4.0.1 or earlier
      # Prior to mpfr-4.0.2, there are issues with precision < 2,
      # but DBL_DENORM_MIN calls for a precision of one bit.
      # We therefore return the hard coded value for this case.

      if($exp == -1073) {
        # $mpfr is 2 ** -1074
        my $ret = $neg ? '-5e-324' : '5e-324';
        $Math::FakeDD::REPRO_PREC = 1;
        return $ret;
      }
    }

    $prec = $addon + $exp;
    Rmpfr_prec_round($mpfr, $prec, MPFR_RNDN);
    $Math::FakeDD::REPRO_PREC = $prec;

    return '-' . mpfrtoa($mpfr, $prec + 1) if $neg;
    return mpfrtoa($mpfr, $prec + 1);

  } # close $arg->{lsd} == 0

  my $m_msd = Rmpfr_init2(53);
  my $m_lsd = Rmpfr_init2(53);

  Rmpfr_set_d($m_msd, $arg->{msd}, MPFR_RNDN);
  Rmpfr_set_d($m_lsd, $arg->{lsd}, MPFR_RNDN);

  my $different_signs = 0; # will be set to 1 if one double < 0,
                           # and the other double > 0.

  if(abs($arg->{lsd}) >= 2 ** -1022) {
    # lsd is not subnormal.
    $prec = Rmpfr_get_exp($m_msd) - Rmpfr_get_exp($m_lsd) + 53;
    if( ($arg->{lsd} < 0 && $arg->{msd} > 0) || ($arg->{msd} < 0 && $arg->{lsd} > 0) ) {
      # $prec--; # originally, an *unqualified* decrement.
      $prec-- if abs( (dd_frexp($arg->{msd}))[0] ) == 0.5;      # MSD is a power of 2
      $different_signs = 1; # one double < 0, the other > 0
    }
    my $mpfr_copy = Rmpfr_init2(2098);
    Rmpfr_set($mpfr_copy, $mpfr, MPFR_RNDN);
    Rmpfr_prec_round($mpfr_copy, $prec, MPFR_RNDN);
    my $trial_repro = mpfrtoa($mpfr_copy);
    my $trial_dd = Math::FakeDD->new($trial_repro);
    if($trial_dd == $arg || ($neg == 1 && $trial_dd == abs($arg)) ) {
      $Math::FakeDD::REPRO_PREC = $prec;
      return '-' . $trial_repro if $neg;
      return $trial_repro;
    }

    $prec++;
    # Might need to be incremented again if the 2 doubles have different sign.
  }
  else {
    $prec = Rmpfr_get_exp($m_msd) + 1073; # $prec should be > 0
    #$prec++ if $prec == 0;                # Ensure $prec > 0

    my $mpfr_copy = Rmpfr_init2(2098);
    Rmpfr_set($mpfr_copy, $mpfr, MPFR_RNDN);
    Rmpfr_prec_round($mpfr_copy, $prec, MPFR_RNDN);
    my $trial_repro = mpfrtoa($mpfr_copy);
    my $trial_dd = Math::FakeDD->new($trial_repro);
    if($trial_dd == $arg || ($neg == 1 && $trial_dd == abs($arg)) ) {
      $Math::FakeDD::REPRO_PREC = $prec;
      return '-' . $trial_repro if $neg;
      return $trial_repro;
    }

    $prec++;
  }

  my $mpfr_orig = Rmpfr_init2(2098);
  Rmpfr_set($mpfr_orig, $mpfr, MPFR_RNDN); # copy $mpfr to $mpfr_orig

  Rmpfr_prec_round($mpfr, $prec, MPFR_RNDN);

  if($different_signs) {
    my $candidate = mpfrtoa($mpfr); # was mpfrtoa($mpfr, 53) - apparently unnecessary

    # Might fail either the "chop" test or
    # the "round trip" test, but not both.

    if(abs($arg) != Math::FakeDD->new($candidate)) {
      # First check whether decrementing the mantissa
      # allows the round trip to succeed.

      my $ret = _decrement($candidate);

      if(abs($arg) == Math::FakeDD->new($ret)) {
        $Math::FakeDD::REPRO_PREC = "< $prec";
        return '-' . $ret if $neg;
        return $ret;
      }

      # Fails round trip - so we increment $prec. We then
      # can't use $mpfr again as its precision has already
      # been altered, so we use $mpfr_orig.

      $prec++;
      Rmpfr_prec_round($mpfr_orig, $prec, MPFR_RNDN);
      $Math::FakeDD::REPRO_PREC = $prec;
      return '-' . mpfrtoa($mpfr_orig) if $neg; # was mpfrtoa($mpfr_orig, 53) - apparently unnecessary
      return mpfrtoa($mpfr_orig);               # was mpfrtoa($mpfr_orig, 53) - apparently unnecessary
    }

    my $ret = _chop_test($candidate, $arg, 0);

    if($ret eq 'ok') {
      $Math::FakeDD::REPRO_PREC = $prec;
      return '-' . $candidate if $neg;
      return $candidate;
    }

    # The value we now return is the value calculated
    # for precision $prec, but with the least significant
    # mantissa digit removed.

    $Math::FakeDD::REPRO_PREC = "< $prec";
    return '-' . $ret if $neg;
    return $ret;

  } # close different signs

  # msd and lsd are either both >0, or both <0.
  # We need to detect the (rare) cases that a chopped and
  # then incremented mantissa passes the round trip.
  # AFAIK, this can happen only if the LSD is an integer power of 2.
  # Two examples: [0x1p+200 0x1p-549] & [0x1.ffffffffffff8p+999 0x1p-549].

  my $candidate = mpfrtoa($mpfr);
  #my @frexp = dd_frexp($arg->{lsd});
  if(abs( (dd_frexp($arg->{lsd}))[0]) == 0.5) { # LSD is an integer power of 2.

    my $ret = _chop_test($candidate, $arg, 1); # $ret will either be set to 'ok' (in which case
                                               # we return $candidate), or $ret will be set to
                                               # the correct value (in which case we return $ret).

    unless($ret eq 'ok') {
      $Math::FakeDD::REPRO_PREC = "> $prec";
      return '-' . $ret if $neg;
      return $ret;
    }
  }

  $Math::FakeDD::REPRO_PREC = $prec;
  return '-' . $candidate if $neg;
  return $candidate;
}

sub _decrement {
  my $shift = shift;
  my @r = split /e/i, $shift;

  # Remove all trailing zeroes from $r[0];

  if($r[0] =~ /\./) {
    chop($r[0]) while $r[0] =~ /0$/;
  }

  $r[0] =~ s/\.$//;
  $r[1] = defined $r[1] ? $r[1] : 0;
  while($r[0] =~ /0$/) {
    chop $r[0];
    $r[1]++;
  }

  return $shift if length($r[0]) < 2;

  my $substitute = substr($r[0], -1, 1) - 1;
  substr($r[0], -1, 1, "$substitute");

  my $ret = $r[1] ? $r[0] . 'e' . $r[1]
                  : $r[0];

  return $ret;
}

sub _chop_test {
  my @r = split /e/i, shift;
  my $op = shift;

  # If $do_increment is set, then we are not interested
  # in the result of the chop test. We are interested in the
  # result of the incrmentation - which requires that we
  # first perform the chop.

  my $do_increment = defined($_[0]) ? shift
                                    : 0;

  # We remove from $r[0] any trailing mantissa zeroes, and then
  # replace the least significant digit with zero.
  # IOW, we effectively chop off the least siginificant digit, thereby
  # rounding it down to the next lowest decimal precision.)
  # This altered string should assign to a DoubleDouble value that is
  # less than the given $op.

  chop($r[0]) while $r[0] =~ /0$/;
  $r[0] =~ s/\.$//;
  $r[1] = defined $r[1] ? $r[1] : 0;
  while($r[0] =~ /0$/) {
    chop $r[0];
    $r[1]++;
  }

  return 'ok' if length($r[0]) < 2; # chop test inapplicable.

  substr($r[0], -1, 1, '');

  $r[1]++ unless $r[0] =~ /\./;
  $r[0] =~ s/\.$/.0/
    unless $r[1];
  $r[0] =~ s/\.$//;

  if(!$do_increment) {
    # We are interested only in the chop test

    my $chopped = $r[1] ? $r[0] . 'e' . $r[1]
                        : $r[0];

    return 'ok' if Math::FakeDD->new($chopped) < abs($op); # chop test ok.
    return $chopped;
  }

  # We are not interested in the chop test - the "chop" was
  # done only as the first step in the incrementation, and
  # it's the result of the following  incrementation that
  # interests us. Now we want, in effect, to do:
  #  ++$r[0];
  # This value should then assign to a  DoubleDouble value
  # that is greater than the given $op.

  if($r[0] =~ /\./) {
    # We must remove the '.', do the string increment,
    # and then reinsert the '.' in the appropriate place.
    my @mantissa = split /\./, $r[0];
    my $point_pos = -(length($mantissa[1]));
    my $t = $mantissa[0] . $mantissa[1];
    $t++;
    substr($t, $point_pos, 0, '.');
    $r[0] = $t;
  }
  else {
    $r[0]++;
    $r[1]++ while $r[0] =~ s/0$//;
  }

  my $incremented = $r[1] ? $r[0] . 'e' . $r[1]
                          : $r[0];

  return $incremented if Math::FakeDD->new($incremented) == abs($op);
  return 'ok';
}

############################
############################

sub dd_repro_test {
  my ($repro, $op) = (shift, shift);
  my $ret = 0;

  my($debug, $examine) = (0, 0);

  if(defined $_[0]) {
    die "Too many args passed to dd_repro_test()"
      if @_ > 2;

    for(@_) {
      $debug   = 1 if $_ =~ /debug/i;
      $examine = 1 if $_ =~ /examine/i;
    }
  }

  print "OP: $op\nREPRO: $repro\n" if $debug;
  $Math::FakeDD::examine{repro} = $repro if $examine;

  # Handle Infs, Nan, and Zero.
  if(dd_is_nan($op)) {
    if($examine) {
      # Clear unset %Math::FakeDD::examine keys
      $Math::FakeDD::examine{chop} = '';
      $Math::FakeDD::examine{inc}  = '';
    }
    return 15 if $repro eq 'NaN';
    return 0;
  }

  if(dd_is_inf($op)) {
    if($examine) {
      # Clear unset %Math::FakeDD::examine keys
      $Math::FakeDD::examine{chop} = '';
      $Math::FakeDD::examine{inc}  = '';
    }
    return 15 if ($op > 0 && $repro eq 'Inf');
    return 15 if ($op < 0 && $repro eq '-Inf');
    return 0;
  }

  if($op == 0) {
    if($examine) {
      # Clear unset %Math::FakeDD::examine keys
      $Math::FakeDD::examine{chop} = '';
      $Math::FakeDD::examine{inc}  = '';
    }
    return 15 if ($repro eq '0.0' || $repro eq '-0.0');
    return 0;
  }

  $repro =~ s/^\-// if $op < 0; # TODO - remove this stipulation
  $op = abs($op);               # TODO - remove this stipulation

  $ret++ if Math::FakeDD->new($repro) == $op; # round trip ok

  my @r = split /e/i, $repro;

  # Increment $ret by 8 if and only if there are no errant trailing
  # zeroes in $r[0] .

  if(!defined($r[1])) {
    $ret += 8 if ($r[0] =~ /\.0$/ || $r[0] !~ /0$/);
    $r[1] = 0;       # define $r[1] by setting it to zero.
  }
  else {
   $ret += 8 unless $r[0] =~ /0$/;
  }

  # We remove from $repro any trailing mantissa zeroes, and then
  # replace the least significant digit with zero.
  # IOW, we effectively chop off the least siginificant digit, thereby
  # rounding it down to the next lowest decimal precision.
  # This altered string should assign to a DoubleDouble value that is
  # less than the given $op.

  chop($r[0]) while $r[0] =~ /0$/;
  $r[0] =~ s/\.$//;
  while($r[0] =~ /0$/) {
    chop $r[0];
    $r[1]++;
  }

  if(length($r[0]) < 2) { # chop test and increment test inapplicable.
    if($examine) {
      $Math::FakeDD::examine{chop} = '';
      $Math::FakeDD::examine{inc}  = '';
    }
    return $ret + 6;
  }

  substr($r[0], -1, 1, '0');


  my $chopped = $r[1] ? $r[0] . 'e' . $r[1]
                      : $r[0];

  print "CHOPPED:\n$chopped\n\n" if $debug;
  $Math::FakeDD::examine{chop} = $chopped if $examine;

  $ret += 2 if Math::FakeDD->new($chopped) < abs($op); # chop test ok.

  # Now we derive a value that is $repro rounded up to the next lowest
  # decimal representation.
  # This value should assign to a  DoubleDouble value that is greater
  # than the given $op.

  if($r[0] =~ /\./) {
   # We must remove the '.', do the string increment,
    # and then reinsert the '.' in the appropriate place.
    my @mantissa = split /\./, $r[0];
    my $point_pos = -(length($mantissa[1]));
    my $t = $mantissa[0] . $mantissa[1];
    $t++ for 1..10;
    substr($t, $point_pos, 0, '.');
    $r[0] = $t;
  }
  else {
    $r[0]++ for 1..10;
  }

  unless ($r[0] gt $chopped) {
    print "OP: $op\n" if $debug;
    my $substitute = substr($r[0], -1, 1) + 1;
    substr($r[0], -1, 1, "$substitute");
  }

  my $incremented = defined($r[1]) ? $r[0] . 'e' . $r[1]
                                   : $r[0];

  print "INCREMENTED:\n$incremented\n" if $debug;
  $Math::FakeDD::examine{inc} = $incremented if $examine;

  $ret += 4 if Math::FakeDD->new($incremented) > abs($op); # increment test ok
  return $ret;
}

############################
############################

sub dd_abs {
  my $obj;
  my $mpfr = Rmpfr_init2(2098);
  if(ref($_[0]) eq 'Math::FakeDD') {
    $obj = dd_copy($_[0]);
  }
  else {
    $obj = mpfr2dd(mpfr2098($_[0]));
  }

  if($obj->{msd} < 0) {
    $obj->{msd} *= -1;
    $obj->{lsd} *= -1;
    $obj->{mpfr} *= -1;
  }

  return $obj;
}

sub dd_add {
  # When dd_add is called via overloading of '+' a
  # third argument (which we CAN ignore) will be provided
  die "Wrong number of arguments given to dd_add()"
    if @_ > 3;

  my ($rop1, $rop2) = (Rmpfr_init2(2098), Rmpfr_init2(2098));

  if(ref($_[0]) eq 'Math::FakeDD') {
    Rmpfr_set($rop1, shift->{mpfr}, MPFR_RNDN);
  }
  else {
    Rmpfr_set($rop1, mpfr2098(shift), MPFR_RNDN);
  }

  if(ref($_[0]) eq 'Math::FakeDD') {
    Rmpfr_set($rop2, shift->{mpfr}, MPFR_RNDN);
  }
  else {
    Rmpfr_set($rop2, mpfr2098(shift), MPFR_RNDN);
  }

  Rmpfr_add($rop1, $rop1, $rop2, MPFR_RNDN);
  return mpfr2dd($rop1);
}

sub dd_add_4196 {
  # Used only in testing.
  die "Wrong number of arguments given to dd_add()"
    if @_ > 2;

  my ($rop1, $rop2) = (Rmpfr_init2(2098), Rmpfr_init2(2098));

  if(ref($_[0]) eq 'Math::FakeDD') {
    Rmpfr_set($rop1, shift->{mpfr}, MPFR_RNDN);
  }
  else {
    Rmpfr_set($rop1, mpfr2098(shift), MPFR_RNDN);
  }

  if(ref($_[0]) eq 'Math::FakeDD') {
    Rmpfr_set($rop2, shift->{mpfr}, MPFR_RNDN);
  }
  else {
    Rmpfr_set($rop2, mpfr2098(shift), MPFR_RNDN);
  }

  my $ret = Rmpfr_init2(4196);

  Rmpfr_add($ret, $rop1, $rop2, MPFR_RNDN);
  return mpfr_any_prec2dd($ret);

}

sub dd_add_eq {
  # When dd_add_eq is called via overloading of '+=' a
  # third argument (which we CAN ignore) will be provided
  die "Wrong number of arguments given to dd_add_eq()"
    if @_ > 3;

  my ($rop1, $rop2) = (Rmpfr_init2(2098), Rmpfr_init2(2098));

  if(ref($_[0]) eq 'Math::FakeDD') {
    Rmpfr_set($rop1, $_[0]->{mpfr}, MPFR_RNDN);
  }
  else {
    die "First arg to dd_add_eq must be a Math::FakeDD object";
  }

  if(ref($_[1]) eq 'Math::FakeDD') {
    Rmpfr_set($rop2, $_[1]->{mpfr}, MPFR_RNDN);
  }
  else {
    Rmpfr_set($rop2, mpfr2098($_[1]), MPFR_RNDN);
  }

  Rmpfr_add($rop1, $rop1, $rop2, MPFR_RNDN);

  if(@_ > 2) {
    # dd_add_eq() has been called via
    # Math::FakeDD overloading of '+='.
    return mpfr2dd($rop1);
  }

  dd_assign($_[0], mpfr2dd($rop1));
}

sub dd_assign {
  die "Wrong number of arguments given to dd_assign()"
    unless @_ == 2;

  die "First arg to dd_assign must be a Math::FakeDD object"
    unless ref($_[0]) eq 'Math::FakeDD';

  my $val = $_[1];
  if(ref($val) eq 'Math::FakeDD') {
    $_[0]->{msd} = $val->{msd};
    $_[0]->{lsd} = $val->{lsd};
    Rmpfr_set($_[0]->{mpfr}, $val->{mpfr}, MPFR_RNDN);
  }
  else {
    my $obj = mpfr2dd(mpfr2098($val));
    $_[0]->{msd} = $obj->{msd};
    $_[0]->{lsd} = $obj->{lsd};
    Rmpfr_set($_[0]->{mpfr}, $obj->{mpfr}, MPFR_RNDN);
  }

  Rmpfr_set_d($_[0]->{mpfr}, $_[0]->{msd}, MPFR_RNDN);
  Rmpfr_add_d($_[0]->{mpfr}, $_[0]->{mpfr}, $_[0]->{lsd}, MPFR_RNDN);
}

sub dd_atan2 {

  # When dd_atan2 is called via overloading of 'atan2' a
  # third argument (which we cannot ignore) will be provided
  die "Wrong number of arguments given to dd_atan2()"
    if @_ > 3;

  my ($rop1, $rop2);

  if(ref($_[0]) eq 'Math::FakeDD') {
    $rop1 = dd2mpfr(shift);
  }
  else {
    $rop1 = mpfr2098(shift);
  }

  if(ref($_[0]) eq 'Math::FakeDD') {
    $rop2 = dd2mpfr(shift);
  }
  else {
    $rop2 = mpfr2098(shift);
  }

  if(@_ && $_[0]) { # switch args
    Rmpfr_atan2($rop2, $rop2, $rop1, MPFR_RNDN);
    return mpfr2dd($rop2);
  }

  Rmpfr_atan2($rop1, $rop1, $rop2, MPFR_RNDN);
  return mpfr2dd($rop1);
}

sub dd_catalan {
  my $rop = Rmpfr_init2(2098);
  Rmpfr_const_catalan($rop, MPFR_RNDN);
  return mpfr2dd($rop);
}


sub dd_cmp {

  die "Wrong number of arguments given to dd_cmp()"
    unless @_ == 2;

  my ($rop1, $rop2) = (Rmpfr_init2(2098), Rmpfr_init2(2098));

  if(ref($_[0]) eq 'Math::FakeDD') {
    Rmpfr_set($rop1, shift->{mpfr}, MPFR_RNDN);
  }
  else {
    Rmpfr_set($rop1, mpfr2098(shift), MPFR_RNDN);
  }

  if(ref($_[0]) eq 'Math::FakeDD') {
    Rmpfr_set($rop2, shift->{mpfr}, MPFR_RNDN);
  }
  else {
    Rmpfr_set($rop2, mpfr2098(shift), MPFR_RNDN);
  }

  return $rop1 <=> $rop2; # "<=>" is "Math::MPFR::overload_spaceship"
                          # and will return undef if a NaN is involved.
}

*dd_clone = \&dd_copy;
sub dd_copy {
  die "Arg given to dd_clone or dd_copy must be a Math::FakeDD object"
    unless ref($_[0]) eq 'Math::FakeDD';

  my $ret = Math::FakeDD->new();
  dd_assign($ret, $_[0]);
  return $ret;
}

sub dd_cos {
  my $mpfr = Rmpfr_init2(2098);

  if(ref($_[0]) eq 'Math::FakeDD') {
    Rmpfr_set($mpfr, $_[0]->{mpfr}, MPFR_RNDN);
  }
  else {
    my $new_obj = mpfr2dd(mpfr2098($_[0]));
    Rmpfr_set($mpfr, $new_obj->{mpfr}, MPFR_RNDN);
  }

  Rmpfr_cos($mpfr, $mpfr, MPFR_RNDN);
  my $ret = mpfr2dd($mpfr);
  return $ret;
}

sub dd_dec {
  die "Wrong arg given to dd_dec()"
    unless ref($_[0]) eq 'Math::FakeDD';
  my $mpfr = dd2mpfr(shift);

  if(!Rmpfr_regular_p($mpfr)) {
    return '0.0'   if Rmpfr_zero_p($mpfr);
    return 'NaN' if Rmpfr_nan_p($mpfr);

    # must be an inf
    return 'Inf' if $mpfr > 0;
    return '-Inf';
  }

  return decimalize($mpfr);
}

sub dd_div {
  # When dd_div is called via overloading of '/' a
  # third argument (which we cannot ignore) will be provided
  die "Wrong number of arguments given to dd_div()"
    if @_ > 3;

  my ($rop1, $rop2) = (Rmpfr_init2(2098), Rmpfr_init2(2098));

  if(ref($_[0]) eq 'Math::FakeDD') {
    Rmpfr_set($rop1, shift->{mpfr}, MPFR_RNDN);
  }
  else {
    Rmpfr_set($rop1,mpfr2098(shift), MPFR_RNDN);
  }

  if(ref($_[0]) eq 'Math::FakeDD') {
    Rmpfr_set($rop2, shift->{mpfr}, MPFR_RNDN);
  }
  else {
    Rmpfr_set($rop2,mpfr2098(shift), MPFR_RNDN);
  }

  if(@_ && $_[0]) { # switch args
    Rmpfr_div($rop2, $rop2, $rop1, MPFR_RNDN);
    return mpfr2dd($rop2);
  }
  Rmpfr_div($rop1, $rop1, $rop2, MPFR_RNDN);
  return mpfr2dd($rop1);

}

sub dd_div_4196 {
  # Used only in testing.
  die "Wrong number of arguments given to dd_div()"
    if @_ > 2;

  my ($rop1, $rop2);

  if(ref($_[0]) eq 'Math::FakeDD') {
    $rop1 = dd2mpfr(shift);
  }
  else {
    $rop1 = mpfr2098(shift);
  }

  if(ref($_[0]) eq 'Math::FakeDD') {
    $rop2 = dd2mpfr(shift);
  }
  else {
    $rop2 = mpfr2098(shift);
  }

  my $ret = Rmpfr_init2(4196);

  Rmpfr_div($ret, $rop1, $rop2, MPFR_RNDN);
  return mpfr_any_prec2dd($ret);

}

sub dd_div_eq {
  # When dd_div_eq is called via overloading of '/=' a
  # third argument (which we CAN ignore) will be provided
  die "Wrong number of arguments given to dd_div_eq()"
    if @_ > 3;

  my ($rop1, $rop2);

  if(ref($_[0]) eq 'Math::FakeDD') {
    $rop1 = dd2mpfr($_[0]);
  }
  else {
    die "First arg to dd_div_eq must be a Math::FakeDD object";
  }

  if(ref($_[1]) eq 'Math::FakeDD') {
    $rop2 = dd2mpfr($_[1]);
  }
  else {
    $rop2 = mpfr2098($_[1]);
  }

  Rmpfr_div($rop1, $rop1, $rop2, MPFR_RNDN);

  if(@_ > 2) {
    # dd_div_eq() has been called via
    # Math::FakeDD overloading of '/='.
    return mpfr2dd($rop1);
  }
  dd_assign($_[0], mpfr2dd($rop1));

}

sub dd_dump {
  my $s1 = "[" . sprintf("%.17g", $_[0]->{msd}) . " " . sprintf("%.17g", $_[0]->{lsd}) . "]";
  my $s2 = sprintx($_[0]);
  my ($s3, $exp) = Rmpfr_deref2($_[0]->{mpfr}, 2, 0, MPFR_RNDN);
  if($s3 =~ /^1/)  {
    $s3 =~ s/0+$//;
    $s3 = "0." .  $s3 . "E$exp";
  }
  return "$s1\n$s2\n$s3\n";
}

sub dd_eq {

  # When dd_eq is called via overloading of '==' a
  # third argument (which we CAN ignore) will be provided
  die "Wrong number of args passed to dd_eq()"
    if(@_ > 3);
  my $cmp = dd_cmp(shift, shift);
  return 0 if $cmp || !defined $cmp; # not equal
  return 1;                          # equal
}

sub dd_euler {
  my $rop = Rmpfr_init2(2098);
  Rmpfr_const_euler($rop, MPFR_RNDN);
  return mpfr2dd($rop);
}

sub dd_exp {
  my $mpfr = Rmpfr_init2(2098);

  if(ref($_[0]) eq 'Math::FakeDD') {
    Rmpfr_set($mpfr, $_[0]->{mpfr}, MPFR_RNDN);
  }
  else {
    my $new_obj = mpfr2dd(mpfr2098($_[0]));
    Rmpfr_set($mpfr, $new_obj->{mpfr}, MPFR_RNDN);
  }

  Rmpfr_exp($mpfr, $mpfr, MPFR_RNDN);
  my $ret = mpfr2dd($mpfr);
  return $ret;
}

sub dd_exp2 {
  my $mpfr = Rmpfr_init2(2098);

  if(ref($_[0]) eq 'Math::FakeDD') {
    Rmpfr_set($mpfr, $_[0]->{mpfr}, MPFR_RNDN);
  }
  else {
    my $new_obj = mpfr2dd(mpfr2098($_[0]));
    Rmpfr_set($mpfr, $new_obj->{mpfr}, MPFR_RNDN);
  }

  Rmpfr_exp2($mpfr, $mpfr, MPFR_RNDN);
  my $ret = mpfr2dd($mpfr);
  return $ret;
}

sub dd_exp10 {
  my $mpfr = Rmpfr_init2(2098);

  if(ref($_[0]) eq 'Math::FakeDD') {
    Rmpfr_set($mpfr, $_[0]->{mpfr}, MPFR_RNDN);
  }
  else {
    my $new_obj = mpfr2dd(mpfr2098($_[0]));
    Rmpfr_set($mpfr, $new_obj->{mpfr}, MPFR_RNDN);
  }

  Rmpfr_exp10($mpfr, $mpfr, MPFR_RNDN);
  my $ret = mpfr2dd($mpfr);
  return $ret;
}

sub dd_gt {

  # When dd_gt is called via overloading of '>' a third
  # argument (which we cannot ignore) will be provided
  die "Wrong number of args passed to dd_gt()"
    if(@_ > 3);

  my $correction = 1;
  $correction = -1
    if (@_ == 3 && $_[2]);

  return 1 if $correction * dd_cmp(shift, shift) > 0; # greater than
  return 0;                                           # not greater than
}

sub dd_gte {

  # When dd_gte is called via overloading of '>=' a third
  # argument (which we cannot ignore) will be provided
  die "Wrong number of args passed to dd_gte()"
    if(@_ > 3);

  my $correction = 1;
  $correction = -1
    if (@_ == 3 && $_[2]);

  return 0 if $correction * dd_cmp(shift, shift) < 0; # less than
  return 1;                                           # greater than or equal
}

sub dd_hex {
  die "Wrong arg given to dd_dec()"
    unless ref($_[0]) eq 'Math::FakeDD';

  my $mpfr = dd2mpfr(shift);

  if(!Rmpfr_regular_p($mpfr)) {
    return '0x0p+0'   if Rmpfr_zero_p($mpfr);
    return 'NaN' if Rmpfr_nan_p($mpfr);

    # must be an inf
    return 'Inf' if $mpfr > 0;
    return '-Inf';
  }

  my $buffer;
  Rmpfr_sprintf($buffer, "%Ra", $mpfr, 528);

  return $buffer;
}

sub dd_int {
  my $mpfr = Rmpfr_init2(2098);
  if(ref($_[0]) eq 'Math::FakeDD') { Rmpfr_set($mpfr, $_[0]->{mpfr}, MPFR_RNDN) }
  else {
    Rmpfr_set($mpfr, mpfr2098($_[0]));
  }

  Rmpfr_trunc($mpfr, $mpfr);
  my $ret = mpfr2dd($mpfr);
  return $ret;
}

sub dd_log {
  my $mpfr = Rmpfr_init2(2098);

  if(ref($_[0]) eq 'Math::FakeDD') {
    Rmpfr_set($mpfr, $_[0]->{mpfr}, MPFR_RNDN);
  }
  else {
    my $new_obj = mpfr2dd(mpfr2098($_[0]));
    Rmpfr_set($mpfr, $new_obj->{mpfr}, MPFR_RNDN);
  }

  Rmpfr_log($mpfr, $mpfr, MPFR_RNDN);
  my $ret = mpfr2dd($mpfr);
  return $ret;
}

sub dd_log2 {
  my $mpfr = Rmpfr_init2(2098);

  if(ref($_[0]) eq 'Math::FakeDD') {
    Rmpfr_set($mpfr, $_[0]->{mpfr}, MPFR_RNDN);
  }
  else {
    my $new_obj = mpfr2dd(mpfr2098($_[0]));
    Rmpfr_set($mpfr, $new_obj->{mpfr}, MPFR_RNDN);
  }

  Rmpfr_log2($mpfr, $mpfr, MPFR_RNDN);
  my $ret = mpfr2dd($mpfr);
  return $ret;
}

sub dd_log10 {
  my $mpfr = Rmpfr_init2(2098);

  if(ref($_[0]) eq 'Math::FakeDD') {
    Rmpfr_set($mpfr, $_[0]->{mpfr}, MPFR_RNDN);
  }
  else {
    my $new_obj = mpfr2dd(mpfr2098($_[0]));
    Rmpfr_set($mpfr, $new_obj->{mpfr}, MPFR_RNDN);
  }

  Rmpfr_log10($mpfr, $mpfr, MPFR_RNDN);
  my $ret = mpfr2dd($mpfr);
  return $ret;
}

sub dd_lt {

  # When dd_gt is called via overloading of '<' a third
  # argument (which we cannot ignore) will be provided
  die "Wrong number of args passed to dd_lt()"
    if(@_ > 3);

  my $correction = 1;
  $correction = -1
    if (@_ == 3 && $_[2]);

  return 1 if $correction * dd_cmp(shift, shift) < 0; # less than
  return 0;                                           # not less than
}

sub dd_lte {

  # When dd_lte is called via overloading of '>=' a third
  # argument (which we cannot ignore) will be provided
  die "Wrong number of args passed to dd_lte()"
    if(@_ > 3);

  my $correction = 1;
  $correction = -1
    if (@_ == 3 && $_[2]);

  return 0 if $correction * dd_cmp(shift, shift) > 0; # greater than
  return 1;                                           # less than or equal
}

sub dd_mul {
  # When dd_mul is called via overloading of '*' a
  # third argument (which we CAN ignore) will be provided
  die "Wrong number of arguments given to dd_mul()"
    if @_ > 3;

  my ($rop1, $rop2) = (Rmpfr_init2(2098), Rmpfr_init2(2098));

  if(ref($_[0]) eq 'Math::FakeDD') {
    Rmpfr_set($rop1, shift->{mpfr}, MPFR_RNDN);
  }
  else {
    Rmpfr_set($rop1, mpfr2098(shift), MPFR_RNDN);
  }

  if(ref($_[0]) eq 'Math::FakeDD') {
    Rmpfr_set($rop2, shift->{mpfr}, MPFR_RNDN);
  }
  else {
    Rmpfr_set($rop2, mpfr2098(shift), MPFR_RNDN);
  }

  Rmpfr_mul($rop1, $rop1, $rop2, MPFR_RNDN);
  return mpfr2dd($rop1);

}

sub dd_mul_4196 {
  # Used only in testing.
  die "Wrong number of arguments given to dd_mul()"
    if @_ > 2;

  my ($rop1, $rop2) = (Rmpfr_init2(2098), Rmpfr_init2(2098));

  if(ref($_[0]) eq 'Math::FakeDD') {
    Rmpfr_set($rop1, shift->{mpfr}, MPFR_RNDN);
  }
  else {
    Rmpfr_set($rop1, mpfr2098(shift), MPFR_RNDN);
  }

  if(ref($_[0]) eq 'Math::FakeDD') {
    Rmpfr_set($rop2, shift->{mpfr}, MPFR_RNDN);
  }
  else {
    Rmpfr_set($rop2, mpfr2098(shift), MPFR_RNDN);
  }

  my $ret = Rmpfr_init2(4196);

  Rmpfr_mul($ret, $rop1, $rop2, MPFR_RNDN);
  return mpfr_any_prec2dd($ret);

}

sub dd_mul_eq {
  # When dd_mul_eq is called via overloading of '*=' a
  # third argument (which we CAN ignore) will be provided
  die "Wrong number of arguments given to dd_mul_eq()"
    if @_ > 3;

  my ($rop1, $rop2) = (Rmpfr_init2(2098), Rmpfr_init2(2098));

  if(ref($_[0]) eq 'Math::FakeDD') {
    Rmpfr_set($rop1, $_[0]->{mpfr}, MPFR_RNDN);
  }
  else {
    die "First arg to dd_mul_eq must be a Math::FakeDD object";
  }

  if(ref($_[1]) eq 'Math::FakeDD') {
    Rmpfr_set($rop2, $_[1]->{mpfr}, MPFR_RNDN);
  }
  else {
    $rop2 = mpfr2098($_[1]);
  }

  Rmpfr_mul($rop1, $rop1, $rop2, MPFR_RNDN);

  if(@_ > 2) {
    # dd_mul_eq() has been called via
    # Math::FakeDD overloading of '*='.
    return mpfr2dd($rop1);
  }

  dd_assign($_[0], mpfr2dd($rop1));
}

sub dd_neq {

  # When dd_neq is called via overloading of '!=' a
  # third argument (which we CAN ignore) will be provided
  die "Wrong number of args passed to dd_neq()"
    if(@_ > 3);
  my $cmp = dd_cmp(shift, shift);
  return 1 if $cmp || !defined $cmp; # not equal
  return 0;                          # equal
}

sub dd_numify {
  # Mainly for '0+' overloading.
  # So far, I've only ever seen '0+' overloading get invoked
  # by Test::More if (and only if) a test performing a
  # comparisons that involved a Math::FakeDD object failed.

  die "Argument passed to dd_numify must be a Math::FakeDD object"
    unless ref($_[0]) eq 'Math::FakeDD';

  my $ret = Rmpfr_init2(2098);
  Rmpfr_set($ret, $_[0]->{mpfr}, MPFR_RNDN);
  return $ret;
}

sub dd_pi {
  my $rop = Rmpfr_init2(2098);
  Rmpfr_const_pi($rop, MPFR_RNDN);
  return mpfr2dd($rop);
}

sub dd_pow {
  # When dd_pow is called via overloading of '**' a
  # third argument (which we cannot ignore) will be provided
  die "Wrong number of arguments given to dd_pow()"
    if @_ > 3;

  my ($rop1, $rop2) = (Rmpfr_init2(2098), Rmpfr_init2(2098));

  if(ref($_[0]) eq 'Math::FakeDD') {
    Rmpfr_set($rop1, shift->{mpfr}, MPFR_RNDN);
  }
  else {
    Rmpfr_set($rop1, mpfr2098(shift), MPFR_RNDN);
  }

  if(ref($_[0]) eq 'Math::FakeDD') {
    Rmpfr_set($rop2, shift->{mpfr}, MPFR_RNDN);
  }
  else {
    Rmpfr_set($rop2, mpfr2098(shift), MPFR_RNDN);
  }

  if(@_ && $_[0]) { # switch args
    Rmpfr_pow($rop2, $rop2, $rop1, MPFR_RNDN);
    return mpfr2dd($rop2);
  }
  Rmpfr_pow($rop1, $rop1, $rop2, MPFR_RNDN);
  return mpfr2dd($rop1);

}

sub dd_pow_eq {
  # When dd_pow_eq is called via overloading of '**=' a
  # third argument (which we CAN ignore) will be provided
  die "Wrong number of arguments given to dd_pow_eq()"
    if @_ > 3;

  my ($rop1, $rop2) = (Rmpfr_init2(2098), Rmpfr_init2(2098));

  if(ref($_[0]) eq 'Math::FakeDD') {
    Rmpfr_set($rop1, $_[0]->{mpfr}, MPFR_RNDN);
  }
  else {
    die "First arg to dd_pow_eq must be a Math::FakeDD object";
  }

  if(ref($_[1]) eq 'Math::FakeDD') {
    Rmpfr_set($rop2, $_[1]->{mpfr}, MPFR_RNDN);
  }
  else {
    Rmpfr_set($rop2, mpfr2098($_[1]), MPFR_RNDN);
  }

  Rmpfr_pow($rop1, $rop1, $rop2, MPFR_RNDN);

  if(@_ > 2) {
    # dd_pow_eq() has been called via
    # Math::FakeDD overloading of '**='.
    return mpfr2dd($rop1);
  }

  dd_assign($_[0], mpfr2dd($rop1));
}

sub dd_sin {
  my $mpfr = Rmpfr_init2(2098);

  if(ref($_[0]) eq 'Math::FakeDD') {
    Rmpfr_set($mpfr, $_[0]->{mpfr}, MPFR_RNDN);
  }
  else {
    my $new_obj = mpfr2dd(mpfr2098($_[0]));
    Rmpfr_set($mpfr, $new_obj->{mpfr}, MPFR_RNDN);
  }

  Rmpfr_sin($mpfr, $mpfr, MPFR_RNDN);
  my $ret = mpfr2dd($mpfr);
  return $ret;
}

sub dd_spaceship {

  # When dd_spaceship is called via overloading of '<=>' a
  # third argument (which we cannot ignore) will be provided
  die "Wrong number of args passed to dd_spaceship()"
    if(@_ > 3);

  my $correction = 1;
  $correction = -1
    if (@_ == 3 && $_[2]);

  my($arg1, $arg2) = (shift, shift);

  if(NAN_COMPARE_BUG) { # Fixed in Math-MPFR-4.23 and later.
    if(dd_is_nan(Math::FakeDD->new($arg1)) || dd_is_nan(Math::FakeDD->new($arg2))) {
      return undef;
    }
  }

  my $cmp = dd_cmp($arg1, $arg2);
  return $correction * $cmp if defined $cmp;
  return $cmp;
}

sub dd_sqrt {
my $mpfr = Rmpfr_init2(2098);
  if(ref($_[0]) eq 'Math::FakeDD') {
    Rmpfr_set($mpfr, $_[0]->{mpfr}, MPFR_RNDN);
  }
  else {
    Rmpfr_set($mpfr, mpfr2098(shift), MPFR_RNDN);
  }

  Rmpfr_sqrt($mpfr, $mpfr, MPFR_RNDN);
  my $ret = mpfr2dd($mpfr);
  return $ret;
}

sub dd_streq {
  # Provided only because Test::More can pull in code
  # that assumes that overloading of 'eq' exists.
  # This is the function that overloaded 'eq' calls.
  die "Wrong arg given to dd_streq()"
    unless ref($_[0]) eq 'Math::FakeDD';

  my($arg1, $arg2) = (shift, shift);
  return 1 if "$arg1" eq "$arg2";
  return 0;
}

sub dd_strne {
  # Provided only because dd_streq() is provided.
  die "Wrong arg given to dd_strne()"
    unless ref($_[0]) eq 'Math::FakeDD';

  my($arg1, $arg2) = (shift, shift);
  return 1 if "$arg1" ne "$arg2";
  return 0;
}

sub dd_stringify {
  die "Wrong arg given to dd_stringify()"
    unless ref($_[0]) eq 'Math::FakeDD';

  my $self = shift;

  return "[" . nvtoa($self->{msd}) . " " . nvtoa($self->{lsd}) . "]"
    if NV_IS_DOUBLE;

  return "[0.0 0.0]" if($self->{msd} == 0 && $self->{lsd} == 0); # Don't look at the exponent of a
                                                                 # Math::MPFR object whose value is 0.

  # If $Config{nvsize} != 8, an assertion failure was making
  # it difficult for this sub to work with infinities. So,
  # we now simply detect the inf and return the appropriate
  # string, irrespective of the value of $Config{nvsize}.
  if(dd_is_inf($self)) {
    return "[Inf 0.0]" if $self > 0;
    return "[-Inf 0.0]";
  }
  my($mpfrm, $mpfrl) = (Rmpfr_init2(53), Rmpfr_init2(53));
  Rmpfr_set_d($mpfrm, $self->{msd}, MPFR_RNDN);
  Rmpfr_set_d($mpfrl, $self->{lsd}, MPFR_RNDN);
  my $expm = Rmpfr_get_exp($mpfrm);

  # Deal with the possibility that the absolute value of one (and only
  # one) of the 2 doubles could be subnormal - ie less that 2 ** -1022.

  if($expm < -1021) {   # msd is subnormal
    Rmpfr_prec_round($mpfrm, 1074 + $expm, MPFR_RNDN);
    return "[" . mpfrtoa($mpfrm, 53) . " " . '0.0' . "]";
  }

  if($self->{lsd}) { # Avoid the case that lsd is 0 !!!
    my $expl = Rmpfr_get_exp($mpfrl);
    if($expl < -1021) { # lsd is subnormal
      Rmpfr_prec_round($mpfrl, 1074 + $expl, MPFR_RNDN);
      return "[" . mpfrtoa($mpfrm) . " " . mpfrtoa($mpfrl, 53) . "]";
    }
  }
  return "[" . mpfrtoa($mpfrm) . " " . mpfrtoa($mpfrl) . "]";
}

sub dd_sub {
  # When dd_sub is called via overloading of '-' a
  # third argument (which we cannot ignore) will be provided
  die "Wrong number of arguments given to dd_sub()"
    if @_ > 3;

  my ($rop1, $rop2) = (Rmpfr_init2(2098), Rmpfr_init2(2098));

  if(ref($_[0]) eq 'Math::FakeDD') {
    Rmpfr_set($rop1, shift->{mpfr}, MPFR_RNDN);
  }
  else {
    Rmpfr_set($rop1, mpfr2098(shift), MPFR_RNDN);
  }

  if(ref($_[0]) eq 'Math::FakeDD') {
    Rmpfr_set($rop2, shift->{mpfr}, MPFR_RNDN);
  }
  else {
    Rmpfr_set($rop2, mpfr2098(shift), MPFR_RNDN);
  }

  if(@_ && $_[0]) { # switch args
    Rmpfr_sub($rop2, $rop2, $rop1, MPFR_RNDN);
    return mpfr2dd($rop2);
  }

  Rmpfr_sub($rop1, $rop1, $rop2, MPFR_RNDN);
  return mpfr2dd($rop1);
}

sub dd_sub_4196 {
  # Used only in testing.
  die "Wrong number of arguments given to dd_sub()"
    if @_ > 2;

  my ($rop1, $rop2) = (Rmpfr_init2(2098), Rmpfr_init2(2098));

  if(ref($_[0]) eq 'Math::FakeDD') {
    Rmpfr_set($rop1, shift->{mpfr}, MPFR_RNDN);
  }
  else {
    Rmpfr_set($rop1, mpfr2098(shift), MPFR_RNDN);
  }

  if(ref($_[0]) eq 'Math::FakeDD') {
    Rmpfr_set($rop2, shift->{mpfr}, MPFR_RNDN);
  }
  else {
    Rmpfr_set($rop1, mpfr2098(shift), MPFR_RNDN);
  }

  my $ret = Rmpfr_init2(4196);

  Rmpfr_sub($ret, $rop1, $rop2, MPFR_RNDN);
  return mpfr_any_prec2dd($ret);
}

sub dd_sub_eq {
  # When dd_sub_eq is called via overloading of '-=' a
  # third argument (which we CAN ignore) will be provided
  die "Wrong number of arguments given to dd_sub_eq()"
    if @_ > 3;

  my ($rop1, $rop2) = (Rmpfr_init2(2098), Rmpfr_init2(2098));

  if(ref($_[0]) eq 'Math::FakeDD') {
    Rmpfr_set($rop1, $_[0]->{mpfr}, MPFR_RNDN);
  }
  else {
    die "First arg to dd_sub_eq must be a Math::FakeDD object";
  }

  if(ref($_[1]) eq 'Math::FakeDD') {
    Rmpfr_set($rop2, $_[1]->{mpfr}, MPFR_RNDN);
  }
  else {
    Rmpfr_set($rop2, mpfr2098($_[1]), MPFR_RNDN);
  }

  Rmpfr_sub($rop1, $rop1, $rop2, MPFR_RNDN);

  if(@_ > 2) {
    # dd_sub_eq() has been called via
    # Math::FakeDD overloading of '-='.
    return mpfr2dd($rop1);
  }

  dd_assign($_[0], mpfr2dd($rop1));

}

sub dd2mpfr {
  my $self = shift;
  #my $ret = Rmpfr_init2(2098);
  #Rmpfr_add($ret, mpfr2098($self->{msd}), mpfr2098($self->{lsd}), MPFR_RNDN);
  #return $ret;
  return $self->{mpfr};
}

sub mpfr2dd {
  my %h;

  die "Arg given to mpfr2dd() must be a Math::MPFR object"
    unless ref($_[0]) eq 'Math::MPFR';

  # mpfr2dd() will handle an argument of any precision - but if the
  # precision is not 2098, then it's probably a mistake. So let's
  # disallow it until it becomes evident that it should be permitted.

  die "Precision of Math::MPFR object passed to mpfr2dd() must be 2098"
    unless Rmpfr_get_prec($_[0]) == 2098;

  my $mpfr = Rmpfr_init2(2098);
  Rmpfr_set($mpfr, shift, MPFR_RNDN);
  my $msd = Rmpfr_get_d($mpfr, MPFR_RNDN);

  # $msd could be an Inf or Zero, even though $mpfr was not.
  # Also cater for the possibility that $msd is Nan - though
  # I don't think that can happen.
  if(!$msd || _is_nan($msd) || _is_inf($msd)) { # $msd is zero, nan, or inf.
    $h{msd} = $msd;
    $h{lsd} = 0.0;
    $h{mpfr} = Rmpfr_init2(2098);
    Rmpfr_set_d($h{mpfr}, $h{msd}, MPFR_RNDN);
    return bless(\%h);
  }

  Rmpfr_sub_d($mpfr, $mpfr, $msd, MPFR_RNDN);
  my $lsd = Rmpfr_get_d($mpfr, MPFR_RNDN);

  # If abs($msd) is DBL_MAX && abs($lsd) is 2**970
  # && $msd has the same sign as $lsd, then return
  # an Inf that has the same sign as $msd.
  # This is a bit murky. See:
  # https://gcc.gnu.org/bugzilla/show_bug.cgi?id=61399
  if(_return_inf($msd, $lsd)) {
    if($msd < 0 && $lsd < 0) { return dd_inf(-1) }
    if($msd > 0 && $lsd > 0) { return dd_inf()   }
  }

  $h{msd} = $msd;
  $h{lsd} = $lsd;
  $h{mpfr} = Rmpfr_init2(2098);
  Rmpfr_set_d($h{mpfr}, $h{msd}, MPFR_RNDN);
  Rmpfr_add_d($h{mpfr}, $h{mpfr}, $h{lsd}, MPFR_RNDN);
  return bless(\%h);
}

sub mpfr_any_prec2dd {
  # Converts a Math::MPFR object of any
  # precision to a Math::FakeDD object.
  my %h;

  die "Arg given to mpfr2dd() must be a Math::MPFR object"
    unless ref($_[0]) eq 'Math::MPFR';

  my $prec_in = Rmpfr_get_prec($_[0]);
  my $mpfr_prec = $prec_in <= 2098 ? 2098 : $prec_in;

  my $mpfr = Rmpfr_init2($mpfr_prec);
  Rmpfr_set($mpfr, shift, MPFR_RNDN);

  my $msd = Rmpfr_get_d($mpfr, MPFR_RNDN);
  if($msd == 0 || $msd != $msd || $msd / $msd != 1) { # $msd is zero, nan, or inf.
    $h{msd} = $msd;
    $h{lsd} = 0;
    $h{mpfr} = Rmpfr_init2(2098);
    Rmpfr_set_d($h{mpfr}, $h{msd}, MPFR_RNDN);
    return bless(\%h);
  }

  Rmpfr_sub_d($mpfr, $mpfr, $msd, MPFR_RNDN);
  my $lsd = Rmpfr_get_d($mpfr, MPFR_RNDN);
  $h{msd} = $msd;
  $h{lsd} = $lsd;
  $h{mpfr} = Rmpfr_init2(2098);
  Rmpfr_set_d($h{mpfr}, $h{msd}, MPFR_RNDN);
  Rmpfr_add_d($h{mpfr}, $h{mpfr}, $h{lsd}, MPFR_RNDN);
  return bless(\%h);
}

sub mpfr2098 {
  # Set the argument to a 2098-bit precision Math::MPFR object.
  my $ret = Rmpfr_init2(2098);
  my $itsa = Math::MPFR::_itsa($_[0]);

  # Arg must be one of PV (string), IV (integer), UV (unsigned integer),
  # NV (perl floating point type) or Math::MPFR object.

  die "Invalid arg ($itsa) passed internally to mpfr2098()"
    unless ($itsa > 0 && $itsa <= 5);

  if($itsa == 5) {                           # Math::MPFR object
    Rmpfr_set($ret, $_[0], MPFR_RNDN);
    return $ret;
  }

  my $arg = shift;

  if($itsa == 4) {                           # PV
    my $turnoff = 0;
    if(!$Math::MPFR::NNW) {
      $Math::MPFR::NNW = 1;  # warn if $arg contains non-numeric character(s).
      $turnoff = 1;
    }
    Rmpfr_set_str($ret, $arg, 0, MPFR_RNDN);
    $Math::MPFR::NNW = 0 if $turnoff;  # $Math::MPFR::NNW retains initial setting.
    return $ret;
  }

  if($itsa == 3) {                           # NV
    Rmpfr_set_NV($ret, $arg, MPFR_RNDN);
    return $ret;
  }

  Rmpfr_set_IV($ret, $arg, MPFR_RNDN);       # IV/UV
  return $ret;

}

sub overload_copy {
  # Not exported
  my $ret = Math::FakeDD->new();
  dd_assign($ret, $_[0]);
  return $ret;
}

sub overload_inc {
  # Not exported
  my $rop1 = dd2mpfr($_[0]);
  Rmpfr_add_ui($rop1, $rop1, 1, MPFR_RNDN);
  dd_assign($_[0], mpfr2dd($rop1));
}

sub overload_dec {
  # Not exported
  my $rop1 = dd2mpfr($_[0]);
  Rmpfr_sub_ui($rop1, $rop1, 1, MPFR_RNDN);
  dd_assign($_[0], mpfr2dd($rop1));
}

sub oload {
  # Not exported.
  # Return a list of the operator-function pairs for the overloaded
  # operators and the respective functions that they call.

  my %h = (
    'abs'   => 'dd_abs',
    'atan2' => 'dd_atan2',
    'bool'  => 'dd_true',
    'cos'   => 'dd_cos',
    'eq'    => 'dd_streq',
    'ne'    => 'dd_strne',
    'exp'   => 'dd_exp',
    'int'   => 'dd_int',
    'log'   => 'dd_log',
    'sin'   => 'dd_sin',
    'sqrt'  => 'dd_sqrt',
    '+'     => 'dd_add',
    '+='    => 'dd_add_eq',
    '/'     => 'dd_div',
    '/='    => 'dd_div_eq',
    '=='    => 'dd_eq',
    '>'     => 'dd_gt',
    '>='    => 'dd_gte',
    '<'     => 'dd_lt',
    '<='    => 'dd_lte',
    '*'     => 'dd_mul',
    '*='    => 'dd_mul_eq',
    '!='    => 'dd_neq',
    '**'    => 'dd_pow',
    '**='   => 'dd_pow_eq',
    '<=>'   => 'dd_spaceship',
    '""'    => 'dd_stringify',
    '0+'    => 'dd_numify',
    '-'     => 'dd_sub',
    '-='    => 'dd_sub_eq',
    '!'     => 'dd_false',
    '='     => 'overload_copy',
    '++'    => 'overload_inc',
    '--'    => 'overload_dec',
);

  return %h
}

sub dd_true {
  die "Not a Math::FakeDD object passed to dd_true()"
    unless ref($_[0]) eq 'Math::FakeDD';

  return 1 if(dd2mpfr(shift)); # Uses Math::MPFR overloading of 'bool'
  return 0;
}

sub dd_false {
  die "Not a Math::FakeDD object passed to dd_false()"
    unless ref($_[0]) eq 'Math::FakeDD';

  return 1 if !(dd2mpfr(shift)); # Uses Math::MPFR overloading of '!'
  return 0;
}

sub dd_is_inf {
  die "Not a Math::FakeDD object passed to dd_is_inf()"
    unless ref($_[0]) eq 'Math::FakeDD';

  return 1 if Rmpfr_inf_p(Math::MPFR->new($_[0]->{msd}));
  return 0;
}

sub dd_is_nan {
  die "Not a Math::FakeDD object passed to dd_is_nan()"
    unless ref($_[0]) eq 'Math::FakeDD';

  return 1 if Rmpfr_nan_p(Math::MPFR->new($_[0]->{msd}));
  return 0;
}

sub dd_inf {
  my $inf = Math::MPFR->new();
  Rmpfr_set_inf($inf, defined($_[0]) ?  shift : 0); # Will be -Inf only if $_[0] < 0
  my %h = (msd => Rmpfr_get_d($inf, MPFR_RNDN), lsd => 0.0);
  $h{mpfr} = Rmpfr_init2(2098);
  Rmpfr_set_d($h{mpfr}, $h{msd}, MPFR_RNDN);
  return bless \%h;
}

sub dd_nan {
  my %h = (msd => Rmpfr_get_d(Math::MPFR->new(), MPFR_RNDN), lsd => 0.0);
  $h{mpfr} = Rmpfr_init2(2098);
  return bless \%h;
}

sub printx {
  print sprintx(shift);
}

sub sprintx {
  if(ref($_[0]) eq 'Math::FakeDD') {
    my $self = shift;
    return "[" . sprintf("%a", $self->{msd}) . " " . sprintf("%a", $self->{lsd}) . "]";
  }
  die "Wrong arg given to sprintx()";
}

sub any2dd {
  my $mpfr = Rmpfr_init2(2098);
  Rmpfr_set_ui($mpfr, 0, MPFR_RNDN);
  for(@_) {
    $mpfr += $_;
  }
  return mpfr2dd($mpfr);
}

sub unpackx {
  if(ref($_[0]) eq 'Math::FakeDD') {
    my $self = shift;
    return "[" . unpack("H*", pack("d>", $self->{msd})) . " " . unpack("H*", pack("d>", $self->{lsd})) . "]";
  }
  die "Wrong arg given to unpackx()";
}

#sub tz_test {
#  # Detect any unwanted trailing zeroes
#  # in values returned by nvtoa().
#
#  my $s = shift;
#  my @r = split /e/i, $s;
#
#  if(!defined($r[1])) {
#    return 1 if $r[0] =~ /\.0$/; # pass
#    return 0 if $r[0] =~ /0$/;   # fail
#  }
#
#  return 0 if $r[0] =~ /0$/;     # fail (for our formatting convention)
#  return 1;                      # pass
#}

sub dd_nextup {
  die "Arg given to dd_nextup() must be a Math::FakeDD object"
    unless ref($_[0]) eq 'Math::FakeDD';
  my $dd = shift;
  return Math::FakeDD->new(2 ** -1074) if $dd == 0;
  return dd_nan() if dd_is_nan($dd);
  if(dd_is_inf($dd)) {
    return dd_inf() if $dd > 0;
    return -$Math::FakeDD::DD_MAX;
  }

  # We now need to check the first 12 bits of the lsd
  my $is_neg = 0;
  my $leading_12_bits = hex(substr(unpack("H*", pack("d>", $dd->{lsd})), 0, 3));
  $is_neg = 1 if $leading_12_bits > 2048; # ignore signed zero
  my $raw_exponent = $leading_12_bits & 2047;
  unless($raw_exponent) {
    # The lsd can never be an inf or a nan
    # Therefore must be a subnormal (or zero),
    # so we return $dd plus DBL_DENORM_MIN
    return $dd + DBL_DENORM_MIN;
  }

  my $exp = $raw_exponent - 1023 - 52;
  my $pow = 2 ** $exp;

  # Check that $dd + $pow > $dd.
  while($dd + $pow == $dd) {
    $pow *= 2;
  }

  my $keep = $pow;

  while($dd + $pow > $dd) {
    $keep = $pow;
    die "Error (bug) in dd_nextup(" . sprintx($dd) . ")" unless $keep;
    $pow /= 2;
  }

return $dd + $keep;
}

sub dd_nextdown {
  die "Arg given to dd_nextdown() must be a Math::FakeDD object"
    unless ref($_[0]) eq 'Math::FakeDD';
  my $dd = shift;
  return Math::FakeDD->new(-(2 ** -1074)) if $dd == 0;
  return dd_nan() if dd_is_nan($dd);
  if(dd_is_inf($dd)) {
    return dd_inf(-1) if $dd < 0;
    return $Math::FakeDD::DD_MAX;
  }

  # We now need to check the first 12 bits of the lsd
  my $is_neg = 0;
  my $leading_12_bits = hex(substr(unpack("H*", pack("d>", $dd->{lsd})), 0, 3));
  $is_neg = 1 if $leading_12_bits > 2048; # ignore signed zero
  my $raw_exponent = $leading_12_bits & 2047;
  unless($raw_exponent) {
    # The lsd can never be an inf or a nan.
    # Therefore must be a subnormal (or zero),
    # so we return $dd minus DBL_DENORM_MIN
    return $dd - DBL_DENORM_MIN;
  }

  my $exp = $raw_exponent - 1023 - 52;
  my $pow = 2 ** $exp;

  # Check that $dd - $pow < $dd.
  while($dd - $pow == $dd) {
    $pow *= 2;
  }

  my $keep = $pow;

  while($dd - $pow < $dd) {
    $keep = $pow;
    die "Error (bug) in dd_nextup(" . sprintx($dd) . ")" unless $keep;
    $pow /= 2;
  }

return $dd - $keep;
}

sub ulp_exponent {
  my $dd = shift;
  my $exp;
  if($_[0]) {
    # If a second (and true) argument was provided
    $exp = hex(substr(unpack("H*", pack("d>", $dd->{msd})), 0, 3)) & 2047;
  }
  else {
    $exp = hex(substr(unpack("H*", pack("d>", $dd->{lsd})), 0, 3)) & 2047;
  }
  return $exp - 1075 if $exp;
  return -1074;
}

sub is_subnormal {
  # Takes an NV as its argument.
  my $d = shift;
  die "Bad argument passed to is_subnormal()"
    unless Math::MPFR::_itsa($d) == 3;
  # NOTE:  # We return 1 if $d == 0.
  return 1 if((hex(substr(unpack("H*", pack("d>", $d)), 0, 3)) & 2047) == 0);
  return 0;
}

sub _is_nan {
  # Test with a copy of the arg  to
  # avoid altering the arg's numeric flags
  my $t = shift;
  return 1 if $t != $t;
  return 0;
}

sub _is_inf {
  # Test with a copy of the arg  to
  # avoid altering the arg's numeric flags
  my $t = shift;
  return 1 if $t && $t / $t != 1;
  return 0;
}

sub _return_inf {
  my ($msd, $lsd) = (shift, shift);
  return 1 if(abs($msd) == M_FDD_DBL_MAX && abs($lsd) == M_FDD_P2_970);
  return 0;
}

1;
