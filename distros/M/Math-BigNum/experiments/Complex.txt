package Math::BigNum::Complex;

use 5.010;
use strict;
use warnings;

no warnings qw(qw);

use Math::MPC qw();
use Math::MPFR qw();
use Math::BigNum qw();

use Class::Multimethods qw(multimethod);

=encoding utf8

=head1 NAME

Math::BigNum::Complex - Arbitrary size precision for complex numbers.

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

    use Math::BigNum qw(:constant i);
    say 3 + 4*i;        # => "3+4i"

    my $z = Math::BigNum::Complex->new(3, 4);
    say sqrt($z);       # => "2+i"

=head1 DESCRIPTION

Math::BigNum::Complex provides a transparent interface to Math::MPC.

=head1 SUBROUTINES/METHODS

=cut

our $ROUND = Math::MPC::MPC_RNDNN();

our ($PREC);
*PREC = \$Math::BigNum::PREC;

use overload
  '""' => \&stringify,
  '0+' => \&numify,
  bool => \&boolify,

  '=' => sub { $_[0]->copy },

  # Some shortcuts for speed
  '+='  => sub { $_[0]->badd($_[1]) },
  '-='  => sub { $_[0]->bsub($_[1]) },
  '*='  => sub { $_[0]->bmul($_[1]) },
  '/='  => sub { $_[0]->bdiv($_[1]) },
  '%='  => sub { $_[0]->bmod($_[1]) },
  '^='  => sub { $_[0]->bxor($_[1]) },
  '&='  => sub { $_[0]->band($_[1]) },
  '|='  => sub { $_[0]->bior($_[1]) },
  '**=' => sub { $_[0]->bpow($_[1]) },
  '<<=' => sub { $_[0]->blsft($_[1]) },
  '>>=' => sub { $_[0]->brsft($_[1]) },

  '+'  => sub { $_[0]->add($_[1]) },
  '*'  => sub { $_[0]->mul($_[1]) },
  '==' => sub { $_[0]->eq($_[1]) },
  '!=' => sub { $_[0]->ne($_[1]) },
  '&'  => sub { $_[0]->and($_[1]) },
  '|'  => sub { $_[0]->ior($_[1]) },
  '^'  => sub { $_[0]->xor($_[1]) },
  '~'  => sub { $_[0]->not },

  '++' => sub { $_[0]->binc },
  '--' => sub { $_[0]->bdec },

  '>'   => sub { Math::BigNum::Complex::gt($_[2]  ? ($_[1], $_[0]) : ($_[0], $_[1])) },
  '>='  => sub { Math::BigNum::Complex::ge($_[2]  ? ($_[1], $_[0]) : ($_[0], $_[1])) },
  '<'   => sub { Math::BigNum::Complex::lt($_[2]  ? ($_[1], $_[0]) : ($_[0], $_[1])) },
  '<='  => sub { Math::BigNum::Complex::le($_[2]  ? ($_[1], $_[0]) : ($_[0], $_[1])) },
  '<=>' => sub { Math::BigNum::Complex::cmp($_[2] ? ($_[1], $_[0]) : ($_[0], $_[1])) },

  '>>' => sub { Math::BigNum::Complex::rsft($_[2] ? ($_[1], $_[0]) : ($_[0], $_[1])) },
  '<<' => sub { Math::BigNum::Complex::lsft($_[2] ? ($_[1], $_[0]) : ($_[0], $_[1])) },

  '**'  => sub { Math::BigNum::Complex::pow($_[2]   ? ($_[1], $_[0]) : ($_[0], $_[1])) },
  '-'   => sub { Math::BigNum::Complex::sub($_[2]   ? ($_[1], $_[0]) : ($_[0], $_[1])) },
  '/'   => sub { Math::BigNum::Complex::div($_[2]   ? ($_[1], $_[0]) : ($_[0], $_[1])) },
  '%'   => sub { Math::BigNum::Complex::mod($_[2]   ? ($_[1], $_[0]) : ($_[0], $_[1])) },
  atan2 => sub { Math::BigNum::Complex::atan2($_[2] ? ($_[1], $_[0]) : ($_[0], $_[1])) },

  eq  => sub { "$_[0]" eq "$_[1]" },
  ne  => sub { "$_[0]" ne "$_[1]" },
  cmp => sub { $_[2] ? "$_[1]" cmp $_[0]->stringify : $_[0]->stringify cmp "$_[1]" },

  neg  => sub { $_[0]->neg },
  sin  => sub { $_[0]->sin },
  cos  => sub { $_[0]->cos },
  exp  => sub { $_[0]->exp },
  log  => sub { $_[0]->ln },
  int  => sub { $_[0]->int },
  abs  => sub { $_[0]->abs },
  sqrt => sub { $_[0]->sqrt };

*nan   = \&Math::BigNum::Nan::nan;
*bnan  = \&Math::BigNum::Nan::bnan;
*inf   = \&Math::BigNum::Inf::inf;
*binf  = \&Math::BigNum::Inf::binf;
*ninf  = \&Math::BigNum::Inf::ninf;
*bninf = \&Math::BigNum::Inf::bninf;

*_str2mpfr = \&Math::BigNum::_str2mpfr;
*_mpfr2big = \&Math::BigNum::_mpfr2big;

# Needed by boolify()
my $ZERO = do {
    my $r = Math::MPC::Rmpc_init2($PREC);
    Math::MPC::Rmpc_set_ui($r, 0, $ROUND);
    $r;
};

=head2 new

    Complex->new(Scalar)              # => Complex
    Complex->new(Scalar, Scalar)      # => Complex

Returns a new Complex object with the value specified in the first argument,
which can be a Perl numerical value, a string representing a complex number in
a standard form, such as C<"2+3i">, one or two strings holding a floating-point
number, such as C<"0.5">, or one or two strings holding an integer, such as C<"255">.

If the second argument is omitted, the imaginary part will be set to zero.

Example for creating a complex number:

    my $z = Math::BigNum::Complex->new(2, 3);

which is equivalent with:

    my $z = Math::BigNum::Complex->new("2+3i");

B<NOTE:> no space is allowed as part of a string provided to C<new()>.

=cut

sub new {
    my (undef, $x, $y) = @_;

    if (ref($x) eq 'Math::BigNum') {
        $x = $$x;
    }
    elsif (ref($x) eq __PACKAGE__) {
        return $x if not defined $y;
        if (ref($y) eq __PACKAGE__) {
            return $x->add($y);
        }
        else {
            return $x->add(__PACKAGE__->new($y));
        }
    }
    elsif (ref($x) eq '') {
        if ($x eq 'i' or $x eq '+i') {
            return __PACKAGE__->new(__PACKAGE__->new(0, 1), $y);
        }
        elsif ($x eq '-i') {
            return __PACKAGE__->new(__PACKAGE__->new(0, -1), $y);
        }
        elsif (substr($x, -1) eq 'i') {
            if ($x =~ /^(.+?)([+-].*?)i\z/) {
                my ($re, $im) = ($1, $2);
                if ($im eq '+') {
                    $im = 1;
                }
                elsif ($im eq '-') {
                    $im = -1;
                }
                return __PACKAGE__->new(__PACKAGE__->new($re, $im), $y);
            }
            else {
                return __PACKAGE__->new(__PACKAGE__->new(0, $x), $y);
            }
        }
    }

    if (not defined($y)) {
        my $r = Math::MPC::Rmpc_init2($PREC);
        if (ref($x) eq 'Math::GMPq') {
            Math::MPC::Rmpc_set_q($r, $x, $ROUND);
        }
        else {
            Math::MPC::Rmpc_set_str($r, $x, 10, $ROUND);
        }

        return (bless \$r, __PACKAGE__);
    }
    elsif (ref($y) eq 'Math::BigNum') {
        $y = $$y;
    }
    elsif (ref($y) eq __PACKAGE__) {
        return $y->add(__PACKAGE__->new($x));
    }
    elsif (ref($y) eq '') {
        if ($y eq 'i' or $y eq '+i') {
            return __PACKAGE__->new($x, __PACKAGE__->new(0, 1));
        }
        elsif ($y eq '-i') {
            return __PACKAGE__->new($x, __PACKAGE__->new(0, -1));
        }
        elsif (substr($y, -1) eq 'i') {
            if ($y =~ /^(.+?)([+-].*?)i\z/) {
                my ($re, $im) = ($1, $2);
                if ($im eq '+') {
                    $im = 1;
                }
                elsif ($im eq '-') {
                    $im = -1;
                }
                return __PACKAGE__->new($x, __PACKAGE__->new($re, $im));
            }
            else {
                return __PACKAGE__->new($x, __PACKAGE__->new(0, substr($y, 0, -1)));
            }
        }
    }

    my $r = Math::MPC::Rmpc_init2($PREC);

    if (ref($x) eq 'Math::GMPq') {
        if (ref($y) eq 'Math::GMPq') {
            Math::MPC::Rmpc_set_q_q($r, $x, $y, $ROUND);
        }
        else {
            my $y_fr = Math::MPFR::Rmpfr_init2($PREC);
            Math::MPFR::Rmpfr_set_str($y_fr, $y, 10, $Math::BigNum::ROUND);
            Math::MPC::Rmpc_set_q_fr($r, $x, $y_fr, $ROUND);
        }
    }
    elsif (ref($y) eq 'Math::GMPq') {
        my $x_fr = Math::MPFR::Rmpfr_init2($PREC);
        Math::MPFR::Rmpfr_set_str($x_fr, $x, 10, $Math::BigNum::ROUND);
        Math::MPC::Rmpc_set_fr_q($r, $x_fr, $y, $ROUND);
    }
    else {
        my $x_fr = Math::MPFR::Rmpfr_init2($PREC);
        Math::MPFR::Rmpfr_set_str($x_fr, $x, 10, $Math::BigNum::ROUND);

        my $y_fr = Math::MPFR::Rmpfr_init2($PREC);
        Math::MPFR::Rmpfr_set_str($y_fr, $y, 10, $Math::BigNum::ROUND);

        Math::MPC::Rmpc_set_fr_fr($r, $x_fr, $y_fr, $ROUND);

        #my $x_q = Math::GMPq->new(Math::BigNum::_str2rat($x), 10);
        #my $y_q = Math::GMPq->new(Math::BigNum::_str2rat($y), 10);
        #Math::MPC::Rmpc_set_q_q($r, $x_q, $y_q, $ROUND);
    }

    bless \$r, __PACKAGE__;
}

# Promotes a BigNum object to a Complex number
sub _big2cplx {
    my ($x, $z) = @_;
    $$x = $$z;
    bless $x, __PACKAGE__;
    $x;
}

=head2 stringify

    $z->stringify       # => Scalar

Returns a string representing the value of $z, either as an integer,
a floating-point, or a complex number.

=cut

sub stringify {
    my $re = $_[0]->re;
    my $im = $_[0]->im;

    $re = "$re";
    $im = "$im";

    return $re if $im eq '0';
    my $sign = '+';

    if (substr($im, 0, 1) eq '-') {
        $sign = '-';
        substr($im, 0, 1, '');
    }

    $im = '' if $im eq '1';
    $re eq '0' ? $sign eq '+' ? "${im}i" : "$sign${im}i" : "$re$sign${im}i";
}

=head2 boolify

    $z->boolify         # => Bool

Returns true when the real part or the imaginary part is non-zero.

=cut

sub boolify {
    Math::MPC::Rmpc_cmp(${$_[0]}, $ZERO) != 0;
}

=head2 numify

    $z->numify      # => Scalar

Returns a Perl numerical scalar with the absolute value of C<$z>, truncated if needed.

=cut

sub numify {
    my ($x) = @_;
    my $r = Math::MPFR::Rmpfr_init2($PREC);
    Math::MPC::Rmpc_abs($r, $$x, $ROUND);
    Math::MPFR::Rmpfr_get_d($r, $ROUND);
}

=head2 copy

    $z->copy        # => Complex

Returns a copy of the self-object.

=cut

sub copy {
    my $r = Math::MPC::Rmpc_init2($PREC);
    Math::MPC::Rmpc_set($r, ${$_[0]}, $ROUND);
    bless \$r, __PACKAGE__;
}

=head2 re

    $z->re      # => BigNum | Inf | Nan

Returns the real part of C<$z>.

=cut

sub re {
    my $mpfr = Math::MPFR::Rmpfr_init2($PREC);
    Math::MPC::RMPC_RE($mpfr, ${$_[0]});
    _mpfr2big($mpfr);
}

=head2 im

    $z->im      # => BigNum | Inf | Nan

Returns the imaginary part of C<$z>.

=cut

sub im {
    my $mpfr = Math::MPFR::Rmpfr_init2($PREC);
    Math::MPC::RMPC_IM($mpfr, ${$_[0]});
    _mpfr2big($mpfr);
}

=head2 abs

    $z->abs     # => BigNum | Inf | Nan

Absolute value of C<$z>.

=cut

sub abs {
    my $mpfr = Math::MPFR::Rmpfr_init2($PREC);
    Math::MPC::Rmpc_abs($mpfr, ${$_[0]}, $ROUND);
    _mpfr2big($mpfr);
}

=head2 norm

    $z->norm        # => BigNum | Inf | Nan

Reciprocal value of C<$z>.

=cut

sub norm {
    my $mpfr = Math::MPFR::Rmpfr_init2($PREC);
    Math::MPC::Rmpc_norm($mpfr, ${$_[0]}, $ROUND);
    _mpfr2big($mpfr);
}

=head2 neg

    $z->neg         # => Complex

Negative value of C<$z>.

=cut

sub neg {
    my ($x) = @_;
    my $r = Math::MPC::Rmpc_init2($PREC);
    Math::MPC::Rmpc_neg($r, $$x, $ROUND);
    bless(\$r, __PACKAGE__);
}

=head2 conj

    $z->conj        # => Complex

Conjugate value of C<$z>.

=cut

sub conj {
    my ($x) = @_;
    my $r = Math::MPC::Rmpc_init2($PREC);
    Math::MPC::Rmpc_conj($r, $$x, $ROUND);
    bless(\$r, __PACKAGE__);
}

#
## Arithmetic
#

=head2 add

    $x->add(Complex)        # => Complex
    $x->add(BigNum)         # => Complex
    $x + $y                 # => Complex

Addition: C<$x + $y>.

=cut

multimethod add => qw(Math::BigNum::Complex Math::BigNum::Complex) => sub {
    my ($x, $y) = @_;

    my $r = Math::MPC::Rmpc_init2($PREC);
    Math::MPC::Rmpc_add($r, $$x, $$y, $ROUND);

    bless \$r, __PACKAGE__;
};

multimethod add => qw(Math::BigNum::Complex Math::BigNum) => sub {
    my ($x, $y) = @_;

    my $r = Math::MPC::Rmpc_init2($PREC);
    Math::MPC::Rmpc_add_fr($r, $$x, $y->_big2mpfr(), $ROUND);

    bless \$r, __PACKAGE__;
};

multimethod add => qw(Math::BigNum::Complex $) => sub {
    $_[0]->add(Math::BigNum::Complex->new($_[1]));
};

multimethod add => qw($ Math::BigNum::Complex) => sub {
    Math::BigNum::Complex->new($_[0])->add($_[1]);
};

=head2 badd

    $x->badd(Complex)        # => Complex
    $x->badd(BigNum)         # => Complex
    $x += $y                 # => Complex

Addition: C<$x + $y>, changing C<$x> in place.

=cut

multimethod badd => qw(Math::BigNum::Complex Math::BigNum::Complex) => sub {
    my ($x, $y) = @_;
    Math::MPC::Rmpc_add($$x, $$x, $$y, $ROUND);
    $x;
};

multimethod badd => qw(Math::BigNum::Complex Math::BigNum) => sub {
    my ($x, $y) = @_;
    Math::MPC::Rmpc_add_fr($$x, $$x, $y->_big2mpfr(), $ROUND);
    $x;
};

multimethod badd => qw(Math::BigNum::Complex $) => sub {
    $_[0]->badd(Math::BigNum::Complex->new($_[1]));
};

=head2 sub

    $x->sub(Complex)        # => Complex
    $x->sub(BigNum)         # => Complex
    $x - $y                 # => Complex

Subtraction: C<$x - $y>.

=cut

multimethod sub => qw(Math::BigNum::Complex Math::BigNum::Complex) => sub {
    my ($x, $y) = @_;

    my $r = Math::MPC::Rmpc_init2($PREC);
    Math::MPC::Rmpc_sub($r, $$x, $$y, $ROUND);

    bless \$r, __PACKAGE__;
};

multimethod sub => qw(Math::BigNum::Complex Math::BigNum) => sub {
    my ($x, $y) = @_;

    my $r = Math::MPC::Rmpc_init2($PREC);

    my $fr = $y->_big2mpfr();
    Math::MPFR::Rmpfr_neg($fr, $fr, $Math::BigNum::ROUND);
    Math::MPC::Rmpc_add_fr($r, $$x, $fr, $ROUND);

    bless \$r, __PACKAGE__;
};

multimethod sub => qw(Math::BigNum::Complex $) => sub {
    $_[0]->sub(Math::BigNum::Complex->new($_[1]));
};

multimethod sub => qw($ Math::BigNum::Complex) => sub {
    Math::BigNum::Complex->new($_[0])->sub($_[1]);
};

=head2 bsub

    $x->bsub(Complex)        # => Complex
    $x->bsub(BigNum)         # => Complex
    $x -= $y                 # => Complex

Subtraction: C<$x - $y>, changing C<$x> in-place.

=cut

multimethod bsub => qw(Math::BigNum::Complex Math::BigNum::Complex) => sub {
    my ($x, $y) = @_;
    Math::MPC::Rmpc_sub($$x, $$x, $$y, $ROUND);
    $x;
};

multimethod bsub => qw(Math::BigNum::Complex Math::BigNum) => sub {
    my ($x, $y) = @_;
    my $fr = $y->_big2mpfr();
    Math::MPFR::Rmpfr_neg($fr, $fr, $Math::BigNum::ROUND);
    Math::MPC::Rmpc_add_fr($$x, $$x, $fr, $ROUND);
    $x;
};

multimethod bsub => qw(Math::BigNum::Complex $) => sub {
    $_[0]->bsub(Math::BigNum::Complex->new($_[1]));
};

=head2 mul

    $x->mul(Complex)        # => Complex
    $x->mul(BigNum)         # => Complex
    $x->mul(Scalar)         # => Complex
    $x * $y                 # => Complex

Multiplication C<$x * $y>.

=cut

multimethod mul => qw(Math::BigNum::Complex Math::BigNum::Complex) => sub {
    my ($x, $y) = @_;

    my $r = Math::MPC::Rmpc_init2($PREC);
    Math::MPC::Rmpc_mul($r, $$x, $$y, $ROUND);

    bless \$r, __PACKAGE__;
};

multimethod mul => qw(Math::BigNum::Complex Math::BigNum) => sub {
    my ($x, $y) = @_;

    my $r = Math::MPC::Rmpc_init2($PREC);
    Math::MPC::Rmpc_mul_fr($r, $$x, $y->_big2mpfr(), $ROUND);

    bless \$r, __PACKAGE__;
};

multimethod mul => qw(Math::BigNum::Complex $) => sub {
    $_[0]->mul(Math::BigNum::Complex->new($_[1]));
};

multimethod mul => qw($ Math::BigNum::Complex) => sub {
    Math::BigNum::Complex->new($_[0])->mul($_[1]);
};

=head2 bmul

    $x->bmul(Complex)        # => Complex
    $x->bmul(BigNum)         # => Complex
    $x->bmul(Scalar)         # => Complex
    $x *= $y                 # => Complex

Multiplication C<$x * $y>, changing C<$x> in-place.

=cut

multimethod bmul => qw(Math::BigNum::Complex Math::BigNum::Complex) => sub {
    my ($x, $y) = @_;
    Math::MPC::Rmpc_mul($$x, $$x, $$y, $ROUND);
    $x;
};

multimethod bmul => qw(Math::BigNum::Complex Math::BigNum) => sub {
    my ($x, $y) = @_;
    Math::MPC::Rmpc_mul_fr($$x, $$x, $y->_big2mpfr(), $ROUND);
    $x;
};

multimethod bmul => qw(Math::BigNum::Complex $) => sub {
    $_[0]->bmul(Math::BigNum::Complex->new($_[1]));
};

=head2 div

    $x->div(Complex)        # => Complex
    $x->div(BigNum)         # => Complex
    $x->div(Scalar)         # => Complex
    $x / $y                 # => Complex

Division: C<$x / $y>.

=cut

multimethod div => qw(Math::BigNum::Complex Math::BigNum::Complex) => sub {
    my ($x, $y) = @_;

    my $r = Math::MPC::Rmpc_init2($PREC);
    Math::MPC::Rmpc_div($r, $$x, $$y, $ROUND);

    bless \$r, __PACKAGE__;
};

multimethod div => qw(Math::BigNum::Complex Math::BigNum) => sub {
    my ($x, $y) = @_;

    my $r = Math::MPC::Rmpc_init2($PREC);
    Math::MPC::Rmpc_div_fr($r, $$x, $y->_big2mpfr(), $ROUND);

    bless \$r, __PACKAGE__;
};

multimethod div => qw(Math::BigNum::Complex $) => sub {
    $_[0]->div(Math::BigNum::Complex->new($_[1]));
};

multimethod div => qw($ Math::BigNum::Complex) => sub {
    Math::BigNum::Complex->new($_[0])->div($_[1]);
};

=head2 bdiv

    $x->bdiv(Complex)        # => Complex
    $x->bdiv(BigNum)         # => Complex
    $x->bdiv(Scalar)         # => Complex
    $x /= $y                 # => Complex

Division: C<$x / $y>, changing C<$x> in-place.

=cut

multimethod bdiv => qw(Math::BigNum::Complex Math::BigNum::Complex) => sub {
    my ($x, $y) = @_;
    Math::MPC::Rmpc_div($$x, $$x, $$y, $ROUND);
    $x;
};

multimethod bdiv => qw(Math::BigNum::Complex Math::BigNum) => sub {
    my ($x, $y) = @_;
    Math::MPC::Rmpc_div_fr($$x, $$x, $y->_big2mpfr(), $ROUND);
    $x;
};

multimethod bdiv => qw(Math::BigNum::Complex $) => sub {
    $_[0]->bdiv(Math::BigNum::Complex->new($_[1]));
};

=head2 inv

    $x->inv         # => Complex

Returns C<1/$x>.

=cut

sub inv {
    my ($x) = @_;
    my $r = Math::MPC::Rmpc_init2($PREC);
    Math::MPC::Rmpc_ui_div($r, 1, $$x, $ROUND);
    bless(\$r, __PACKAGE__);
}

=head2 binv

    $x->binv         # => Complex

Does C<1/$x>, changing C<$x> in-place.

=cut

sub binv {
    my ($x) = @_;
    Math::MPC::Rmpc_ui_div($$x, 1, $$x, $ROUND);
    $x;
}

=head2 pow

    $x->pow(Complex)    # => Complex
    $x->pow(BigNum)     # => Complex
    $x->pow(Scalar)     # => Complex

Raise C<$x> to power C<$y>.

=cut

multimethod pow => qw(Math::BigNum::Complex $) => sub {
    my ($x, $y) = @_;
    $x->pow(Math::BigNum::Complex->new($y));
};

multimethod pow => qw(Math::BigNum::Complex Math::BigNum) => sub {
    my ($x, $y) = @_;
    my $r = Math::MPC::Rmpc_init2($PREC);
    Math::MPC::Rmpc_pow_fr($r, $$x, $y->_big2mpfr(), $ROUND);
    bless \$r, __PACKAGE__;
};

multimethod pow => qw(Math::BigNum::Complex Math::BigNum::Complex) => sub {
    my ($x, $y) = @_;
    my $r = Math::MPC::Rmpc_init2($PREC);
    Math::MPC::Rmpc_pow($r, $$x, $$y, $ROUND);
    bless \$r, __PACKAGE__;
};

=head2 root

    $z->root(Complex)      # => Complex
    $z->root(BigNum)       # => Complex
    $z->root(Scalar)       # => Complex

Nth root of $z. (C<$z**(1/n)>)

=cut

multimethod root => qw(Math::BigNum::Complex $) => sub {
    my ($x, $y) = @_;
    $x->pow(Math::BigNum::Complex->new($y)->inv);
};

multimethod root => qw(Math::BigNum::Complex Math::BigNum) => sub {
    my ($x, $y) = @_;
    $x->pow($y->inv);
};

multimethod root => qw(Math::BigNum::Complex Math::BigNum::Complex) => sub {
    my ($x, $y) = @_;
    $x->pow($y->inv);
};

=head2 sqrt

    $z->sqrt        # => Complex

Square root of C<$z>. (C<$z**(1/2)>)

=cut

sub sqrt {
    my ($x) = @_;
    my $r = Math::MPC::Rmpc_init2($PREC);
    Math::MPC::Rmpc_sqrt($r, $$x, $ROUND);
    bless(\$r, __PACKAGE__);
}

=head2 cbrt

    $x->cbrt        # => Complex

Cube root of $x. ($x**(1/3))

=cut

sub cbrt {
    my ($x) = @_;
    my $r = Math::MPC::Rmpc_init2($PREC);
    state $three_inv = do {
        my $r = Math::MPC::Rmpc_init2($PREC);
        Math::MPC::Rmpc_set_ui($r, 3, $ROUND);
        Math::MPC::Rmpc_ui_div($r, 1, $r, $ROUND);
        $r;
    };
    Math::MPC::Rmpc_pow($r, $$x, $three_inv, $ROUND);
    bless(\$r, __PACKAGE__);
}

=head2 log

    $x->log                 # => Complex
    $x->log(Complex)        # => Complex
    $x->log(BigNum)         # => Complex
    $x->log(Scalar)         # => Complex

Logarithm of C<$x> in base C<$y>. When C<$y> is not specified, it defaults to base e.

=cut

multimethod log => qw(Math::BigNum::Complex Math::BigNum) => sub {
    my ($x, $y) = @_;

    my $r = Math::MPC::Rmpc_init2($PREC);
    Math::MPC::Rmpc_log($r, $$x, $ROUND);

    my $baseln = $y->_big2mpfr();
    Math::MPFR::Rmpfr_log($baseln, $baseln, $Math::BigNum::ROUND);
    Math::MPC::Rmpc_div_fr($r, $r, $baseln, $ROUND);

    bless \$r, __PACKAGE__;
};

multimethod log => qw(Math::BigNum::Complex Math::BigNum::Complex) => sub {
    my ($x, $y) = @_;

    my $r = Math::MPC::Rmpc_init2($PREC);
    Math::MPC::Rmpc_log($r, $$x, $ROUND);

    my $baseln = Math::MPC::Rmpc_init2($PREC);
    Math::MPC::Rmpc_log($baseln, $$y, $ROUND);
    Math::MPC::Rmpc_div($r, $r, $baseln, $ROUND);

    bless \$r, __PACKAGE__;
};

=head2 ln

    $x->ln       # => Complex

Natural logarithm of $x.

=cut

sub ln {
    my ($x) = @_;
    my $r = Math::MPC::Rmpc_init2($PREC);
    Math::MPC::Rmpc_log($r, $$x, $ROUND);
    bless(\$r, __PACKAGE__);
}

=head2 log2

    $x->log2     # => Complex

Logarithm to the base 2 of $x.

=cut

sub log2 {
    my ($x) = @_;
    my $r = Math::MPC::Rmpc_init2($PREC);
    Math::MPC::Rmpc_log($r, $$x, $ROUND);

    state $two = (Math::MPFR::Rmpfr_init_set_ui(2, $Math::BigNum::ROUND))[0];

    my $baseln = Math::MPFR::Rmpfr_init2($PREC);
    Math::MPFR::Rmpfr_log($baseln, $two, $Math::BigNum::ROUND);
    Math::MPC::Rmpc_div_fr($r, $r, $baseln, $ROUND);

    bless(\$r, __PACKAGE__);
}

=head2 log10

    $x->log10     # => Complex

Logarithm to the base 10 of $x.

=cut

sub log10 {
    my ($x) = @_;
    my $r = Math::MPC::Rmpc_init2($PREC);
    Math::MPC::Rmpc_log10($r, $$x, $ROUND);
    bless(\$r, __PACKAGE__);
}

=head2 exp

    $x->exp     # => Complex

Exponential of $x in base e. (e**$x)

=cut

sub exp {
    my ($x) = @_;
    my $r = Math::MPC::Rmpc_init2($PREC);
    Math::MPC::Rmpc_exp($r, $$x, $ROUND);
    bless(\$r, __PACKAGE__);
}

=head2 exp2

    $x->exp2     # => Complex

Exponential of $x in base 2. (2**$x)

=cut

sub exp2 {
    my ($x) = @_;
    state $two = Math::MPC->new(2);
    my $r = Math::MPC::Rmpc_init2($PREC);
    Math::MPC::Rmpc_pow($r, $two, $$x, $ROUND);
    bless(\$r, __PACKAGE__);
}

=head2 exp10

    $x->exp10     # => Complex

Exponential of $x in base 10. (10**$x)

=cut

sub exp10 {
    my ($x) = @_;
    state $ten = Math::MPC->new(10);
    my $r = Math::MPC::Rmpc_init2($PREC);
    Math::MPC::Rmpc_pow($r, $ten, $$x, $ROUND);
    bless(\$r, __PACKAGE__);
}

=head2 dec

    $x->dec     # => Complex

Subtract one from the real part of $x. ($x - 1)

=cut

sub dec {
    my ($x) = @_;
    state $one = Math::MPC->new(1);
    my $r = Math::MPC::Rmpc_init2($PREC);
    Math::MPC::Rmpc_sub($r, $$x, $one, $ROUND);
    bless(\$r, __PACKAGE__);
}

=head2 inc

    $x->inc     # => Complex

Add one to the real part of $x. ($x + 1)

=cut

sub inc {
    my ($x) = @_;
    state $one = Math::MPC->new(1);
    my $r = Math::MPC::Rmpc_init2($PREC);
    Math::MPC::Rmpc_add($r, $$x, $one, $ROUND);
    bless(\$r, __PACKAGE__);
}

#
## Trigonometric
#

=head2 sin

    $z->sin       # => Complex

Returns the sine of C<$z>.

=cut

sub sin {
    my ($x) = @_;
    my $r = Math::MPC::Rmpc_init2($PREC);
    Math::MPC::Rmpc_sin($r, $$x, $ROUND);
    bless(\$r, __PACKAGE__);
}

=head2 asin

    $z->asin       # => Complex

Returns the inverse sine of C<$z>.

=cut

sub asin {
    my ($x) = @_;
    my $r = Math::MPC::Rmpc_init2($PREC);
    Math::MPC::Rmpc_asin($r, $$x, $ROUND);
    bless(\$r, __PACKAGE__);
}

=head2 sinh

    $z->sinh       # => Complex

Returns the hyperbolic sine of C<$z>.

=cut

sub sinh {
    my ($x) = @_;
    my $r = Math::MPC::Rmpc_init2($PREC);
    Math::MPC::Rmpc_sinh($r, $$x, $ROUND);
    bless(\$r, __PACKAGE__);
}

=head2 asinh

    $z->asinh       # => Complex

Returns the inverse hyperbolic sine of C<$z>.

=cut

sub asinh {
    my ($x) = @_;
    my $r = Math::MPC::Rmpc_init2($PREC);
    Math::MPC::Rmpc_asinh($r, $$x, $ROUND);
    bless(\$r, __PACKAGE__);
}

=head2 cos

    $z->cos       # => Complex

Returns the cosine of C<$z>.

=cut

sub cos {
    my ($x) = @_;
    my $r = Math::MPC::Rmpc_init2($PREC);
    Math::MPC::Rmpc_cos($r, $$x, $ROUND);
    bless(\$r, __PACKAGE__);
}

=head2 acos

    $z->acos       # => Complex

Returns the inverse cosine of C<$z>.

=cut

sub acos {
    my ($x) = @_;
    my $r = Math::MPC::Rmpc_init2($PREC);
    Math::MPC::Rmpc_acos($r, $$x, $ROUND);
    bless(\$r, __PACKAGE__);
}

=head2 cosh

    $z->cosh       # => Complex

Returns the hyperbolic cosine of C<$z>.

=cut

sub cosh {
    my ($x) = @_;
    my $r = Math::MPC::Rmpc_init2($PREC);
    Math::MPC::Rmpc_cosh($r, $$x, $ROUND);
    bless(\$r, __PACKAGE__);
}

=head2 acosh

    $z->acosh       # => Complex

Returns the inverse hyperbolic cosine of C<$z>.

=cut

sub acosh {
    my ($x) = @_;
    my $r = Math::MPC::Rmpc_init2($PREC);
    Math::MPC::Rmpc_acosh($r, $$x, $ROUND);
    bless(\$r, __PACKAGE__);
}

=head2 tan

    $z->tan       # => Complex

Returns the tangent of C<$z>.

=cut

sub tan {
    my ($x) = @_;
    my $r = Math::MPC::Rmpc_init2($PREC);
    Math::MPC::Rmpc_tan($r, $$x, $ROUND);
    bless(\$r, __PACKAGE__);
}

=head2 atan

    $z->atan       # => Complex

Returns the inverse tangent of C<$z>.

=cut

sub atan {
    my ($x) = @_;
    my $r = Math::MPC::Rmpc_init2($PREC);
    Math::MPC::Rmpc_atan($r, $$x, $ROUND);
    bless(\$r, __PACKAGE__);
}

=head2 tanh

    $z->tanh       # => Complex

Returns the hyperbolic tangent of C<$z>.

=cut

sub tanh {
    my ($x) = @_;
    my $r = Math::MPC::Rmpc_init2($PREC);
    Math::MPC::Rmpc_tanh($r, $$x, $ROUND);
    bless(\$r, __PACKAGE__);
}

=head2 atanh

    $z->atanh       # => Complex

Returns the inverse hyperbolic tangent of C<$z>.

=cut

sub atanh {
    my ($x) = @_;
    my $r = Math::MPC::Rmpc_init2($PREC);
    Math::MPC::Rmpc_atanh($r, $$x, $ROUND);
    bless(\$r, __PACKAGE__);
}

=head2 sec

    $z->sec       # => Complex

Returns the secant of C<$z>, which is 1/cos(z).

=cut

#
## sec(x) = 1/cos(x)
#
sub sec {
    my ($x) = @_;
    state $one = Math::MPC->new(1);
    my $r = Math::MPC::Rmpc_init2($PREC);
    Math::MPC::Rmpc_cos($r, $$x, $ROUND);
    Math::MPC::Rmpc_div($r, $one, $r, $ROUND);
    bless(\$r, __PACKAGE__);
}

=head2 asec

    $z->asec       # => Complex

Returns the inverse secant of C<$z>, which is acos(1/z).

=cut

#
## asec(x) = acos(1/x)
#
sub asec {
    my ($x) = @_;
    state $one = Math::MPC->new(1);
    my $r = Math::MPC::Rmpc_init2($PREC);
    Math::MPC::Rmpc_div($r, $one, $$x, $ROUND);
    Math::MPC::Rmpc_acos($r, $r, $ROUND);
    bless(\$r, __PACKAGE__);
}

=head2 sech

    $z->sech       # => Complex

Returns the hyperbolic secant of C<$z>, which is 1/cosh(z).

=cut

#
## sech(x) = 1/cosh(x)
#
sub sech {
    my ($x) = @_;
    state $one = Math::MPC->new(1);
    my $r = Math::MPC::Rmpc_init2($PREC);
    Math::MPC::Rmpc_cosh($r, $$x, $ROUND);
    Math::MPC::Rmpc_div($r, $one, $r, $ROUND);
    bless(\$r, __PACKAGE__);
}

=head2 asech

    $z->asech       # => Complex

Returns the inverse hyperbolic secant of C<$x>, which is acosh(1/z).

=cut

#
## asech(x) = acosh(1/x)
#
sub asech {
    my ($x) = @_;
    state $one = Math::MPC->new(1);
    my $r = Math::MPC::Rmpc_init2($PREC);
    Math::MPC::Rmpc_div($r, $one, $$x, $ROUND);
    Math::MPC::Rmpc_acosh($r, $r, $ROUND);
    bless(\$r, __PACKAGE__);
}

=head2 csc

    $z->csc       # => Complex

Returns the cosecant of C<$z>, which is 1/sin(z).

=cut

#
## csc(x) = 1/sin(x)
#
sub csc {
    my ($x) = @_;
    state $one = Math::MPC->new(1);
    my $r = Math::MPC::Rmpc_init2($PREC);
    Math::MPC::Rmpc_sin($r, $$x, $ROUND);
    Math::MPC::Rmpc_div($r, $one, $r, $ROUND);
    bless(\$r, __PACKAGE__);
}

=head2 acsc

    $z->acsc       # => Complex

Returns the inverse cosecant of C<$z>, which is asin(1/z).

=cut

#
## acsc(x) = asin(1/x)
#
sub acsc {
    my ($x) = @_;
    state $one = Math::MPC->new(1);
    my $r = Math::MPC::Rmpc_init2($PREC);
    Math::MPC::Rmpc_div($r, $one, $$x, $ROUND);
    Math::MPC::Rmpc_asin($r, $r, $ROUND);
    bless(\$r, __PACKAGE__);
}

=head2 csch

    $z->csch       # => Complex

Returns the hyperbolic cosecant of C<$z>, which is 1/sinh(z).

=cut

#
## csch(x) = 1/sinh(x)
#
sub csch {
    my ($x) = @_;
    state $one = Math::MPC->new(1);
    my $r = Math::MPC::Rmpc_init2($PREC);
    Math::MPC::Rmpc_sinh($r, $$x, $ROUND);
    Math::MPC::Rmpc_div($r, $one, $r, $ROUND);
    bless(\$r, __PACKAGE__);
}

=head2 acsch

    $z->acsch       # => Complex

Returns the inverse hyperbolic cosecant of C<$z>, which is asinh(1/x).

=cut

#
## acsch(x) = asinh(1/x)
#
sub acsch {
    my ($x) = @_;
    state $one = Math::MPC->new(1);
    my $r = Math::MPC::Rmpc_init2($PREC);
    Math::MPC::Rmpc_div($r, $one, $$x, $ROUND);
    Math::MPC::Rmpc_asinh($r, $r, $ROUND);
    bless(\$r, __PACKAGE__);
}

=head2 cot

    $z->cot       # => Complex

Returns the cotangent of C<$z>, which is 1/tan(z).

=cut

#
## cot(x) = 1/tan(x)
#
sub cot {
    my ($x) = @_;
    state $one = Math::MPC->new(1);
    my $r = Math::MPC::Rmpc_init2($PREC);
    Math::MPC::Rmpc_tan($r, $$x, $ROUND);
    Math::MPC::Rmpc_div($r, $one, $r, $ROUND);
    bless(\$r, __PACKAGE__);
}

=head2 acot

    $z->acot       # => Complex

Returns the inverse cotangent of C<$z>, which is atan(1/z).

=cut

#
## acot(x) = atan(1/x)
#
sub acot {
    my ($x) = @_;
    state $one = Math::MPC->new(1);
    my $r = Math::MPC::Rmpc_init2($PREC);
    Math::MPC::Rmpc_div($r, $one, $$x, $ROUND);
    Math::MPC::Rmpc_atan($r, $r, $ROUND);
    bless(\$r, __PACKAGE__);
}

=head2 coth

    $z->coth       # => Complex

Returns the hyperbolic cotangent of C<$z>, which is 1/tanh(z).

=cut

#
## coth(x) = 1/tanh(x)
#
sub coth {
    my ($x) = @_;
    state $one = Math::MPC->new(1);
    my $r = Math::MPC::Rmpc_init2($PREC);
    Math::MPC::Rmpc_tanh($r, $$x, $ROUND);
    Math::MPC::Rmpc_div($r, $one, $r, $ROUND);
    bless(\$r, __PACKAGE__);
}

=head2 acoth

    $z->acoth       # => Complex

Returns the inverse hyperbolic cotangent of C<$z>, which is atanh(1/z).

=cut

#
## acoth(x) = atanh(1/x)
#
sub acoth {
    my ($x) = @_;
    state $one = Math::MPC->new(1);
    my $r = Math::MPC::Rmpc_init2($PREC);
    Math::MPC::Rmpc_div($r, $one, $$x, $ROUND);
    Math::MPC::Rmpc_atanh($r, $r, $ROUND);
    bless(\$r, __PACKAGE__);
}

=head2 atan2

    $z->atan2(Complex)          # => Complex
    $z->atan2(BigNum)           # => Complex
    $z->atan2(Inf)              # => Complex(0)
    $z->atan2(Scalar)           # => Complex

    atan2(Complex, Complex)     # => Complex
    atan2(Complex, BigNum)      # => Complex
    atan2(Complex, Scalar)      # => Complex
    atan2(Scalar, Complex)      # => Complex

Arctangent of C<$z> and C<$z'>. If C<$z'> is -Inf returns PI when C<<$z >= 0>>, or -PI when C<<$z < 0>>.

=cut

#
## atan2(x, y) = atan(x/y)
#

multimethod atan2 => qw(Math::BigNum::Complex Math::BigNum::Complex) => sub {
    my ($x, $y) = @_;
    my $r = Math::MPC::Rmpc_init2($PREC);
    Math::MPC::Rmpc_div($r, $$x, $$y, $ROUND);
    Math::MPC::Rmpc_atan($r, $r, $ROUND);
    bless(\$r, __PACKAGE__);
};

multimethod atan2 => qw(Math::BigNum::Complex Math::BigNum) => sub {
    my ($x, $y) = @_;
    $y = $y->_big2mpfr();
    my $r = Math::MPC::Rmpc_init2($PREC);
    Math::MPC::Rmpc_div_fr($r, $$x, $y, $ROUND);
    Math::MPC::Rmpc_atan($r, $r, $ROUND);
    bless(\$r, __PACKAGE__);
};

# TODO: add more multimethods for atan2()

#
## Comparisons
#

=head2 eq

    $z->eq(Complex)   # => Bool
    $z1 == $z2        # => Bool

Equality check: returns a true value when C<$z1> and C<$z2> are equal.

=cut

multimethod eq => qw(Math::BigNum::Complex Math::BigNum::Complex) => sub {
    my ($x, $y) = @_;
    Math::MPC::Rmpc_cmp($$x, $$y) == 0;
};

# TODO: add more multimethods for eq()

=head2 ne

    $z->ne(Complex)      # => Bool
    $z1 != $z2           # => Bool

Inequality check: returns a true value C<$z1> and C<$z2> are not equal.

=cut

multimethod ne => qw(Math::BigNum::Complex Math::BigNum::Complex) => sub {
    my ($x, $y) = @_;
    Math::MPC::Rmpc_cmp($$x, $$y) != 0;
};

# TODO: add more multimethods for ne()

=head2 cmp

    $z->cmp(BigNum)              # => Scalar
    $z->cmp(Complex)             # => Scalar
    $z->cmp(Scalar)              # => Scalar

    BigNum <=> BigNum            # => Scalar
    BigNum <=> Scalar            # => Scalar
    Scalar <=> BigNum            # => Scalar

Compares C<$z1> to C<$z2> and returns a negative value when the real part of
C<$z1> is less than the real part of C<$z2>. When the real parts are equal,
it check the imaginary part and returns a negative value when the imaginary
part of C<$z1> is less than the imaginary part of C<$z2>.

For C<Math::BigNum> objects, the imaginary part is considered to be zero.

=cut

multimethod cmp => qw(Math::BigNum::Complex Math::BigNum::Complex) => sub {
    my ($x, $y) = @_;

    my $x_re = Math::MPFR::Rmpfr_init2($PREC);
    my $y_re = Math::MPFR::Rmpfr_init2($PREC);

    Math::MPC::RMPC_RE($x_re, $$x);
    Math::MPC::RMPC_RE($y_re, $$y);

    my $cmp_re = Math::MPFR::Rmpfr_cmp($x_re, $y_re);
    return $cmp_re if $cmp_re != 0;

    my $x_im = Math::MPFR::Rmpfr_init2($PREC);
    my $y_im = Math::MPFR::Rmpfr_init2($PREC);

    Math::MPC::RMPC_IM($x_im, $$x);
    Math::MPC::RMPC_IM($y_im, $$y);

    Math::MPFR::Rmpfr_cmp($x_re, $y_re);
};

# TODO: add more multimethods for cmp()

=head2 round

    $x->round(Scalar)       # => BigNum
    $x->round(BigNum)       # => BigNum

Rounds the absolute value of C<$x> to the nth place.

=cut

sub round {
    my ($x, $prec) = @_;
    $x->abs->round($prec);
}

1;
