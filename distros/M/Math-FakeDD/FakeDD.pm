package Math::FakeDD;

use strict;
use warnings;
use Math::MPFR qw(:mpfr);
use Config;

use 5.022; # for $Config{longdblkind}

use constant NV_IS_DOUBLE       => $Config{nvsize} == 8 ? 1 : 0;

use constant NV_IS_DOUBLEDOUBLE => $Config{nvsize} != 8 &&
                                   ($Config{longdblkind} >=5 && $Config{longdblkind} <= 8) ? 1 : 0;

use constant NV_IS_QUAD => $Config{nvtype} eq '__float128' ||
                           ($Config{nvtype} eq 'long double' && $Config{longdblkind} > 0
                              && $Config{longdblkind} < 3)                                 ? 1 : 0;

use constant NV_IS_80BIT_LD => $Config{nvtype} eq 'long double' &&
                               $Config{longdblkind} > 2 && $Config{longdblkind} < 5         ? 1 : 0;

use overload
'abs'   => \&dd_abs,
'atan2' => \&dd_atan2,
'bool'  => \&dd_true,
'cos'   => \&dd_cos,
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
'-'     => \&dd_sub,
'-='    => \&dd_sub_eq,
'!'     => \&dd_false,
;

require Exporter;
*import = \&Exporter::import;

@Math::FakeDD::EXPORT_OK = qw(
  NV_IS_DOUBLE NV_IS_DOUBLEDOUBLE NV_IS_QUAD NV_IS_80BIT_LD
  dd_abs dd_add dd_add_eq dd_assign dd_atan2 dd_cmp dd_cos dd_dec dd_div dd_div_eq dd_eq dd_exp
  dd_gt dd_gte dd_int dd_log dd_lt dd_lte
  dd_mul dd_mul_eq dd_neq dd_pow dd_pow_eq dd_repro dd_sin dd_spaceship dd_sqrt dd_stringify
  dd_sub dd_sub_eq
);

%Math::FakeDD::EXPORT_TAGS = (all =>[@Math::FakeDD::EXPORT_OK]);

$Math::FakeDD::VERSION =  0.01;

sub new {

  my %h = ('msd' => 0, 'lsd' => 0);
  return bless(\%h) unless @_;

  if(!ref($_[0]) && $_[0] eq "Math::FakeDD") {
    # 'new' has been called as a method
    shift;
    return bless(\%h) unless @_;
  }

  die "Too many args given to new()" if @_ > 1;

  # If the remaining argument is a Math::FakeDD
  # object then simply return a copy of it:
  return shift
    if ref($_[0]) eq "Math::FakeDD";

  return mpfr2dd(mpfr2098(shift));
}

sub dd_abs {
  my $obj;
  my $ret = Math::FakeDD->new();

  if(ref($_[0]) eq 'Math::FakeDD') {
    $obj = shift;
  }
  else {
    $obj = Math::FakeDD->new(shift);
  }

  if($obj->{msd} < 0) {
    $ret->{msd} = -$obj->{msd};
    $ret->{lsd} = -$obj->{lsd};
  }
  else {
    $ret->{msd} = $obj->{msd};
    $ret->{lsd} = $obj->{lsd};
  }

  return $ret;
}

sub dd_add {
  # When dd_add is called via overloading of '+' a
  # third argument (which we CAN ignore) will be provided
  die "Wrong number of arguments given to dd_add()"
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

  Rmpfr_add($rop1, $rop1, $rop2, MPFR_RNDN);
  return mpfr2dd($rop1);

}

sub dd_add_eq {
  # When dd_add_eq is called via overloading of '+=' a
  # third argument (which we CAN ignore) will be provided
  die "Wrong number of arguments given to dd_add_eq()"
    if @_ > 3;

  my ($rop1, $rop2);

  if(ref($_[0]) eq 'Math::FakeDD') {
    $rop1 = dd2mpfr($_[0]);
  }
  else {
    die "First arg to dd_add_eq must be a Math::FakeDD object";
  }

  if(ref($_[1]) eq 'Math::FakeDD') {
    $rop2 = dd2mpfr($_[1]);
  }
  else {
    $rop2 = mpfr2098($_[1]);
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
  }
  else {
    my $obj = mpfr2dd(mpfr2098($val));
    $_[0]->{msd} = $obj->{msd};
    $_[0]->{lsd} = $obj->{lsd};
  }
}

sub dd_atan2 {

  # When dd_atan2 is called via overloading of 'atan2' a
  # third argument (which we cannot ignore) will be provided
  die "Wrong number of arguments given to dd_add()"
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


sub dd_cmp {

  die "Wrong number of arguments given to dd_cmp()"
    unless @_ == 2;

  my ($rop1, $rop2);

  if(ref($_[0]) eq 'Math::FakeDD') {
    $rop1 = dd2mpfr(shift);
  }
  else {
    $rop1 = dd2mpfr(Math::FakeDD->new(shift));
  }

  if(ref($_[0]) eq 'Math::FakeDD') {
    $rop2 = dd2mpfr(shift);
  }
  else {
    $rop2 = dd2mpfr(Math::FakeDD->new(shift));
  }

  return $rop1 <=> $rop2; # "<=>" is "Math::MPFR::overload_spaceship"
}

sub dd_cos {
  my $obj;
  if(ref($_[0]) eq 'Math::FakeDD') { $obj = shift }
  else {
    $obj = Math::FakeDD->new(shift);
  }
  my $ret = Math::FakeDD->new();
  my $mpfr = Rmpfr_init2(2098);
  Rmpfr_cos($mpfr, dd2mpfr($obj), MPFR_RNDN);
  $obj = mpfr2dd($mpfr);
  $ret->{msd} = $obj->{msd};
  $ret->{lsd} = $obj->{lsd};
  return $ret;
}

sub dd_dec {
  die "Wrong arg given to dd_dec()"
    unless ref($_[0]) eq 'Math::FakeDD';
  return decimalize(dd2mpfr(shift));
}

sub dd_div {
  # When dd_div is called via overloading of '/' a
  # third argument (which we cannot ignore) will be provided
  die "Wrong number of arguments given to dd_div()"
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
    Rmpfr_div($rop2, $rop2, $rop1, MPFR_RNDN);
    return mpfr2dd($rop2);
  }
  Rmpfr_div($rop1, $rop1, $rop2, MPFR_RNDN);
  return mpfr2dd($rop1);

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

sub dd_eq {

  # When dd_eq is called via overloading of '==' a
  # third argument (which we CAN ignore) will be provided
  die "Wrong number of args passed to dd_eq()"
    if(@_ > 3);
  return 0 if dd_cmp(shift, shift); # unequal
  return 1;                         # equal
}

sub dd_exp {
  my $obj;
  if(ref($_[0]) eq 'Math::FakeDD') { $obj = shift }
  else {
    $obj = Math::FakeDD->new(shift);
  }
  my $ret = Math::FakeDD->new();
  my $mpfr = Rmpfr_init2(2098);
  Rmpfr_exp($mpfr, dd2mpfr($obj), MPFR_RNDN);
  $obj = mpfr2dd($mpfr);
  $ret->{msd} = $obj->{msd};
  $ret->{lsd} = $obj->{lsd};
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

sub dd_int {
  # Don't fall for the idea that we can just do int(msd), int(lsd)
  # when $_[0] is a Math::FakeDD object. I tried that and it doesn't
  # work when, eg, the Math::FakeDD object has been assigned a (string)
  # value of "0.59943243884210417e16".

  my $obj;
  if(ref($_[0]) eq 'Math::FakeDD') { $obj = shift }
  else {
    $obj = Math::FakeDD->new(shift);
  }
  my $ret = Math::FakeDD->new();
  my $mpfr = Rmpfr_init2(2098);
  Rmpfr_trunc($mpfr, dd2mpfr($obj));
  $obj = mpfr2dd($mpfr);
  $ret->{msd} = $obj->{msd};
  $ret->{lsd} = $obj->{lsd};
  return $ret;
}

sub dd_log {
  my $obj;
  if(ref($_[0]) eq 'Math::FakeDD') { $obj = shift }
  else {
    $obj = Math::FakeDD->new(shift);
  }
  my $ret = Math::FakeDD->new();
  my $mpfr = Rmpfr_init2(2098);
  Rmpfr_log($mpfr, dd2mpfr($obj), MPFR_RNDN);
  $obj = mpfr2dd($mpfr);
  $ret->{msd} = $obj->{msd};
  $ret->{lsd} = $obj->{lsd};
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

  Rmpfr_mul($rop1, $rop1, $rop2, MPFR_RNDN);
  return mpfr2dd($rop1);

}

sub dd_mul_eq {
  # When dd_mul_eq is called via overloading of '*=' a
  # third argument (which we CAN ignore) will be provided
  die "Wrong number of arguments given to dd_mul_eq()"
    if @_ > 3;

  my ($rop1, $rop2);

  if(ref($_[0]) eq 'Math::FakeDD') {
    $rop1 = dd2mpfr($_[0]);
  }
  else {
    die "First arg to dd_mul_eq must be a Math::FakeDD object";
  }

  if(ref($_[1]) eq 'Math::FakeDD') {
    $rop2 = dd2mpfr($_[1]);
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
  return 1 if dd_cmp(shift, shift); # unequal
  return 0;                         # equal
}

sub dd_pow {
  # When dd_pow is called via overloading of '**' a
  # third argument (which we cannot ignore) will be provided
  die "Wrong number of arguments given to dd_pow()"
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

  my ($rop1, $rop2);

  if(ref($_[0]) eq 'Math::FakeDD') {
    $rop1 = dd2mpfr($_[0]);
  }
  else {
    die "First arg to dd_pow_eq must be a Math::FakeDD object";
  }

  if(ref($_[1]) eq 'Math::FakeDD') {
    $rop2 = dd2mpfr($_[1]);
  }
  else {
    $rop2 = mpfr2098($_[1]);
  }

  Rmpfr_pow($rop1, $rop1, $rop2, MPFR_RNDN);

  if(@_ > 2) {
    # dd_pow_eq() has been called via
    # Math::FakeDD overloading of '**='.
    return mpfr2dd($rop1);
  }

  dd_assign($_[0], mpfr2dd($rop1));
}

sub dd_repro {
  die "Arg given to dd_repro() must be a Math::FakeDD object"
    unless ref($_[0]) eq 'Math::FakeDD';
  return mpfrtoa(dd2mpfr(shift));
}

sub dd_sin {
  my $obj;
  if(ref($_[0]) eq 'Math::FakeDD') { $obj = shift }
  else {
    $obj = Math::FakeDD->new(shift);
  }
  my $ret = Math::FakeDD->new();
  my $mpfr = Rmpfr_init2(2098);
  Rmpfr_sin($mpfr, dd2mpfr($obj), MPFR_RNDN);
  $obj = mpfr2dd($mpfr);
  $ret->{msd} = $obj->{msd};
  $ret->{lsd} = $obj->{lsd};
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

  return $correction * dd_cmp(shift, shift);
}

sub dd_sqrt {
  my $obj;
  if(ref($_[0]) eq 'Math::FakeDD') { $obj = shift }
  else {
    $obj = Math::FakeDD->new(shift);
  }
  my $ret = Math::FakeDD->new();
  my $mpfr = Rmpfr_init2(2098);
  Rmpfr_sqrt($mpfr, dd2mpfr($obj), MPFR_RNDN);

  $obj = mpfr2dd($mpfr);
  $ret->{msd} = $obj->{msd};
  $ret->{lsd} = $obj->{lsd};
  return $ret;
}

sub dd_stringify {
  die "Wrong arg given to dd_stringify()"
    unless ref($_[0]) eq 'Math::FakeDD';

  my $self = shift;
  my($mpfrm, $mpfrl) = (Rmpfr_init2(53), Rmpfr_init2(53));
  Rmpfr_set_d($mpfrm, $self->{msd}, MPFR_RNDN);
  Rmpfr_set_d($mpfrl, $self->{lsd}, MPFR_RNDN);
  return "[" . mpfrtoa($mpfrm) . " " . mpfrtoa($mpfrl) . "]";
}

sub dd_sub {
  # When dd_sub is called via overloading of '-' a
  # third argument (which we cannot ignore) will be provided
  die "Wrong number of arguments given to dd_sub()"
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
    Rmpfr_sub($rop2, $rop2, $rop1, MPFR_RNDN);
    return mpfr2dd($rop2);
  }

  Rmpfr_sub($rop1, $rop1, $rop2, MPFR_RNDN);
  return mpfr2dd($rop1);
}

sub dd_sub_eq {
  # When dd_sub_eq is called via overloading of '-=' a
  # third argument (which we CAN ignore) will be provided
  die "Wrong number of arguments given to dd_sub_eq()"
    if @_ > 3;

  my ($rop1, $rop2);

  if(ref($_[0]) eq 'Math::FakeDD') {
    $rop1 = dd2mpfr($_[0]);
  }
  else {
    die "First arg to dd_sub_eq must be a Math::FakeDD object";
  }

  if(ref($_[1]) eq 'Math::FakeDD') {
    $rop2 = dd2mpfr($_[1]);
  }
  else {
    $rop2 = mpfr2098($_[1]);
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
  my $ret = Rmpfr_init2(2098);
  Rmpfr_add($ret, mpfr2098($self->{msd}), mpfr2098($self->{lsd}), MPFR_RNDN);
  return $ret;
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
  if($msd == 0 || $msd != $msd || $msd / $msd != 1) { # $msd is zero, nan, or inf.
    $h{msd} = $msd;
    $h{lsd} = 0;
    return bless(\%h);
  }
  $mpfr -= $msd;
  my $lsd = Rmpfr_get_d($mpfr, MPFR_RNDN);
  $h{msd} = $msd;
  $h{lsd} = $lsd;
  return bless(\%h);
}

sub mpfr2098 {
  # Set the argument to a 2098-bit precision Math::MPFR object.
  my $ret = Rmpfr_init2(2098);
  my $itsa = Math::MPFR::_itsa($_[0]);

  # Arg must be one of PV (string), IV (integer), UV (unsigned integer),
  # NV (perl floating point type) or Math::MPFR object.

  die "Invalid arg passed internally to mpfr2098()"
    unless ($itsa > 0 && $itsa <= 4);

  my $arg = shift;

  if($itsa == 4) {                           # PV
    Rmpfr_set_str($ret, $arg, 0, MPFR_RNDN);
    return $ret;
  }

  if($itsa == 3) {                           # NV
    Rmpfr_set_NV($ret, $arg, MPFR_RNDN);
    return $ret;
  }

  Rmpfr_set_IV($ret, $arg, MPFR_RNDN);       # IV/UV
  return $ret;

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
    '-'     => 'dd_sub',
    '-='    => 'dd_sub_eq',
    '!'     => 'dd_false',
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


1;

