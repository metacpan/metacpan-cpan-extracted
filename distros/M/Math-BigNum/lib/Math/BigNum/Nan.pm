package Math::BigNum::Nan;

use 5.010;
use strict;
use warnings;

use Math::GMPq qw();
use Math::BigNum qw();

our $VERSION = '0.20';

=encoding utf8

=head1 NAME

Math::BigNum::Nan - Represents the Not-a-Number value.

=head1 VERSION

Version 0.20

=head1 SYNOPSIS

    use Math::BigNum;
    say Math::BigNum->nan;         # => "NaN"

    my $nan = Math::BigNum::Nan->new;
    say $nan != 0;                 # => 1

=head1 DESCRIPTION

Math::BigNum::Nan is an abstract type that represents the C<NaN> value.

=head1 SUBROUTINES/METHODS

=cut

sub _self { $_[0] }

use overload
  q{""} => \&stringify,
  q{0+} => \&numify,
  bool  => \&boolify,

  '=' => \&copy,

  # Some shortcuts for speed
  '+='  => \&_self,
  '-='  => \&_self,
  '*='  => \&_self,
  '/='  => \&_self,
  '%='  => \&_self,
  '^='  => \&_self,
  '&='  => \&_self,
  '|='  => \&_self,
  '**=' => \&_self,
  '<<=' => \&_self,
  '>>=' => \&_self,

  '+'  => \&nan,
  '*'  => \&nan,
  '&'  => \&nan,
  '|'  => \&nan,
  '^'  => \&nan,
  '~'  => \&nan,
  '>>' => \&nan,
  '<<' => \&nan,

  '++' => \&_self,
  '--' => \&_self,

  eq  => sub { "$_[0]" eq "$_[1]" },
  ne  => sub { "$_[0]" ne "$_[1]" },
  cmp => sub {
    $_[2]
      ? "$_[1]" cmp $_[0]->stringify
      : $_[0]->stringify cmp "$_[1]";
  },

  '!='  => sub { 1 },
  '=='  => sub { 0 },
  '>'   => sub { 0 },
  '>='  => sub { 0 },
  '<'   => sub { 0 },
  '<='  => sub { 0 },
  '<=>' => sub { 0 },

  '**'  => \&nan,
  '-'   => \&nan,
  '/'   => \&nan,
  '%'   => \&nan,
  atan2 => \&nan,

  sin  => \&nan,
  cos  => \&nan,
  exp  => \&nan,
  log  => \&nan,
  int  => \&nan,
  abs  => \&nan,
  sqrt => \&nan;

sub new {
    my $r = Math::GMPq::Rmpq_init();
    Math::GMPq::Rmpq_set_ui($r, 0, 0);
    bless \$r, 'Math::BigNum::Nan';
}

BEGIN { *nan = \&new }

sub boolify   { 0 }
sub stringify { 'NaN' }
sub numify    { 'NaN' + 0 }

*copy = \&Math::BigNum::copy;

*inf   = \&Math::BigNum::Inf::inf;
*binf  = \&Math::BigNum::Inf::binf;
*bninf = \&Math::BigNum::Inf::bninf;

*bone  = \&Math::BigNum::bone;
*bzero = \&Math::BigNum::bzero;
*bmone = \&Math::BigNum::bmone;

sub bnan {
    my ($x) = @_;
    Math::GMPq::Rmpq_set_ui($$x, 0, 0);
    if (ref($x) ne __PACKAGE__) {
        bless $x, __PACKAGE__;
    }
    $x;
}

sub in_base { 'NaN' }

=head2 eq

    $x->eq($y)                     # => Bool
    $x == $y                       # => Bool

Equality test: always returns a false value.

=cut

sub eq { 0 }

=head2 ne

    $x->ne($y)                     # => Bool
    $x != $y                       # => Bool

Inequality test: always returns a true value.

=cut

sub ne { 1 }

=head2 neg / bneg

    $x->neg                        # => Nan
    $x->bneg                       # => Nan

Always returns Nan.

=cut

*neg  = \&nan;
*bneg = \&_self;

=head2 abs / babs

    $x->abs                        # => Nan
    $x->babs                       # => Nan

Always returns Nan.

=cut

*abs  = \&nan;
*babs = \&_self;

=head2 add / badd

    $x->add(Any)                   # => Nan
    $x->badd(Any)                  # => Nan

Always returns Nan.

=cut

*add   = \&nan;
*iadd  = \&nan;
*fadd  = \&nan;
*badd  = \&_self;
*biadd = \&_self;
*bfadd = \&_self;

=head2 sub / bsub

    $x->sub(Any)                   # => Nan
    $x->bsub(Any)                  # => Nan

Always returns Nan.

=cut

*sub   = \&nan;
*isub  = \&nan;
*fsub  = \&nan;
*bsub  = \&_self;
*bisub = \&_self;
*bfadd = \&_self;

=head2 mul / bmul

    $x->mul(Any)                   # => Nan
    $x->bmul(Any)                  # => Nan

Always returns Nan.

=cut

*mul   = \&nan;
*imul  = \&nan;
*fmul  = \&nan;
*bmul  = \&_self;
*bimul = \&_self;
*bfmul = \&_self;

=head2 div / bdiv

    $x->div(Any)                   # => Nan
    $x->bdiv(Any)                  # => Nan

Always returns Nan.

=cut

*div   = \&nan;
*idiv  = \&nan;
*fdiv  = \&nan;
*bdiv  = \&_self;
*bidiv = \&_self;
*bfdiv = \&_self;

=head2 pow / ipow / bpow / bipow

    $x->pow(Any)                   # => Nan
    $x->bpow(Any)                  # => Nan

Always returns Nan.

=cut

*pow   = \&nan;
*ipow  = \&nan;
*fpow  = \&nan;
*bpow  = \&_self;
*bipow = \&_self;
*bfpow = \&_self;

=head2 mod / imod / bmod / bimod

    $x->mod(Any)                   # => Nan
    $x->bmod(Any)                  # => Nan

Always returns Nan.

=cut

*mod   = \&nan;
*imod  = \&nan;
*fmod  = \&nan;
*bmod  = \&_self;
*bimod = \&_self;
*bfmod = \&_self;

=head2 fac / bfac

    $x->fac                        # => Nan
    $x->bfac                       # => Nan

Always returns Nan.

=cut

*fac  = \&nan;
*bfac = \&_self;

=head2 primorial

    $x->primorial                  # => Nan

Always returns Nan.

=cut

*primorial = \&nan;

=head2 cmp

    $x->cmp(Any)                   # => undef

Always returns C<undef>.

=cut

sub cmp { }

*acmp = \&cmp;

*gt = \&cmp;
*ge = \&cmp;
*lt = \&cmp;
*le = \&cmp;

*popcount = \&cmp;
*sign     = \&cmp;

# Other methods

*sqrt  = \&nan;
*bsqrt = \&_self;

*sqr  = \&nan;
*bsqr = \&_self;

*isqrt  = \&nan;
*bisqrt = \&_self;
*cbrt   = \&nan;

*root  = \&nan;
*broot = \&_self;

*iroot  = \&nan;
*biroot = \&_self;

*ln    = \&nan;
*log   = \&nan;
*log2  = \&nan;
*log10 = \&nan;
*blog  = \&_self;
*bln   = \&_self;

*exp   = \&nan;
*exp2  = \&nan;
*exp10 = \&nan;
*bexp  = \&_self;

*sin   = \&nan;
*asin  = \&nan;
*sinh  = \&nan;
*asinh = \&nan;
*cos   = \&nan;
*acos  = \&nan;
*cosh  = \&nan;
*acosh = \&nan;
*tan   = \&nan;
*atan  = \&nan;
*tanh  = \&nan;
*atanh = \&nan;
*sec   = \&nan;
*asec  = \&nan;
*sech  = \&nan;
*asech = \&nan;
*csc   = \&nan;
*acsc  = \&nan;
*csch  = \&nan;
*acsch = \&nan;
*cot   = \&nan;
*acot  = \&nan;
*coth  = \&nan;
*acoth = \&nan;
*atan2 = \&nan;

*lgrt      = \&nan;
*lambert_w = \&nan;

*rand   = \&nan;
*irand  = \&nan;
*modinv = \&nan;
*inv    = \&nan;
*binv   = \&_self;

sub is_nan { 1 }

sub is_zero { 0 }

*is_one   = \&is_zero;
*is_mone  = \&is_zero;
*is_pos   = \&is_zero;
*is_neg   = \&is_zero;
*is_int   = \&is_zero;
*is_real  = \&is_zero;
*is_inf   = \&is_zero;
*is_ninf  = \&is_zero;
*is_even  = \&is_zero;
*is_odd   = \&is_zero;
*is_div   = \&is_zero;
*is_psqr  = \&is_zero;
*is_ppow  = \&is_zero;
*is_pow   = \&is_zero;
*is_prime = \&is_zero;

*max = \&_self;
*min = \&_self;

*gcd  = \&nan;
*lcm  = \&nan;
*int  = \&nan;
*bint = \&_self;

*float  = \&nan;
*bfloat = \&_self;

sub as_frac  { '0/0' }
sub as_rat   { '0/0' }
sub as_float { 'NaN' }
sub as_int   { 'NaN' }
sub as_bin   { 'NaN' }
sub as_hex   { 'NaN' }
sub as_oct   { 'NaN' }

sub digits { () }
sub length { 0 }

*floor  = \&nan;
*ceil   = \&nan;
*round  = \&nan;
*bround = \&_self;

*inc  = \&nan;
*binc = \&_self;
*dec  = \&nan;
*bdec = \&_self;

*modpow = \&nan;

*and  = \&nan;
*band = \&_self;

*ior  = \&nan;
*bior = \&_self;

*xor  = \&nan;
*bxor = \&_self;

*not  = \&nan;
*bnot = \&_self;

*lsft  = \&nan;
*blsft = \&_self;

*rsft  = \&nan;
*brsft = \&_self;

*dfac      = \&nan;
*lucas     = \&nan;
*binomial  = \&nan;
*bernfrac  = \&nan;
*bernreal  = \&nan;
*harmfrac  = \&nan;
*harmreal  = \&nan;
*kronecker = \&nan;
*valuation = \&nan;

*remove  = \&nan;
*bremove = \&_self;

*next_prime = \&nan;    # next prime after NaN? Hmm...
*agm        = \&nan;
*hypot      = \&nan;
*gamma      = \&nan;
*lngamma    = \&nan;
*lgamma     = \&nan;
*digamma    = \&nan;
*beta       = \&nan;
*zeta       = \&nan;
*eta        = \&nan;
*erf        = \&nan;
*erfc       = \&nan;
*eint       = \&nan;
*li         = \&nan;
*li2        = \&nan;

*bessel_j = \&nan;
*bessel_y = \&nan;

*rad2deg = \&nan;
*deg2rad = \&nan;

*numerator   = \&nan;
*denominator = \&nan;

sub divmod { (nan(), nan()) }

*parts    = \&divmod;
*isqrtrem = \&divmod;
*irootrem = \&divmod;

sub seed { }
*iseed = \&seed;

1;
