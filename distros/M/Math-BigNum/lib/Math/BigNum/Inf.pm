package Math::BigNum::Inf;

use 5.010;
use strict;
use warnings;

use Math::GMPq qw();
use Math::BigNum qw();

use Class::Multimethods qw();

our $VERSION = '0.20';

=encoding utf8

=head1 NAME

Math::BigNum::Inf - Represents the +/-Infinity value.

=head1 VERSION

Version 0.20

=head1 SYNOPSIS

    use Math::BigNum;
    say Math::BigNum->inf;         # => "inf"

    my $inf = Math::BigNum::Inf->new;
    say $inf->atan;                # => 1.57079632679489661923132169163975

=head1 DESCRIPTION

Math::BigNum::Inf is an abstract type that represents +/-Infinity.

=head1 SUBROUTINES/METHODS

=cut

sub _self { $_[0] }

use overload
  q{""} => \&stringify,
  q{0+} => \&numify,
  bool  => \&boolify,

  '=' => \&copy,

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
  '~'  => \&not,

  '++' => \&_self,
  '--' => \&_self,

  '>'   => sub { Math::BigNum::Inf::gt($_[2]  ? ($_[1], $_[0]) : ($_[0], $_[1])) },
  '>='  => sub { Math::BigNum::Inf::ge($_[2]  ? ($_[1], $_[0]) : ($_[0], $_[1])) },
  '<'   => sub { Math::BigNum::Inf::lt($_[2]  ? ($_[1], $_[0]) : ($_[0], $_[1])) },
  '<='  => sub { Math::BigNum::Inf::le($_[2]  ? ($_[1], $_[0]) : ($_[0], $_[1])) },
  '<=>' => sub { Math::BigNum::Inf::cmp($_[2] ? ($_[1], $_[0]) : ($_[0], $_[1])) },

  '>>' => sub { Math::BigNum::Inf::rsft($_[2] ? ($_[1], $_[0]) : ($_[0], $_[1])) },
  '<<' => sub { Math::BigNum::Inf::lsft($_[2] ? ($_[1], $_[0]) : ($_[0], $_[1])) },

  '**'  => sub { Math::BigNum::Inf::pow($_[2]   ? ($_[1], $_[0]) : ($_[0], $_[1])) },
  '-'   => sub { Math::BigNum::Inf::sub($_[2]   ? ($_[1], $_[0]) : ($_[0], $_[1])) },
  '/'   => sub { Math::BigNum::Inf::div($_[2]   ? ($_[1], $_[0]) : ($_[0], $_[1])) },
  '%'   => sub { Math::BigNum::Inf::mod($_[2]   ? ($_[1], $_[0]) : ($_[0], $_[1])) },
  atan2 => sub { Math::BigNum::Inf::atan2($_[2] ? ($_[1], $_[0]) : ($_[0], $_[1])) },

  eq  => sub { "$_[0]" eq "$_[1]" },
  ne  => sub { "$_[0]" ne "$_[1]" },
  cmp => sub { $_[2] ? "$_[1]" cmp $_[0]->stringify : $_[0]->stringify cmp "$_[1]" },

  neg  => \&neg,
  sin  => \&sin,
  cos  => \&cos,
  exp  => \&exp,
  log  => \&ln,
  int  => \&int,
  abs  => \&abs,
  sqrt => \&sqrt;

=head2 new

    Inf->new                       # => Inf
    Inf->new('-')                  # => -Inf

Returns on objects representing the +/-Infinity abstract value.

=cut

sub new {
    my ($class, $sign) = @_;

    my $r = Math::GMPq::Rmpq_init();
    if (defined($sign)) {
        if ($sign eq '+') {
            Math::GMPq::Rmpq_set_ui($r, 1, 0);
        }
        elsif ($sign eq '-') {
            Math::GMPq::Rmpq_set_si($r, -1, 0);
        }
    }
    else {
        Math::GMPq::Rmpq_set_ui($r, 1, 0);
    }

    bless \$r, __PACKAGE__;
}

sub stringify {
    (Math::GMPq::Rmpq_sgn(${$_[0]}) > 0) ? 'Inf' : '-Inf';
}

sub numify {
    (Math::GMPq::Rmpq_sgn(${$_[0]}) > 0) ? +'inf' : -'inf';
}

sub boolify { 1 }

# Sets x to the value of Infinity that is given.

# Example:
#   _big2ninf(x, +Inf)       # sets `x` to `+Inf`
#   _big2ninf(x, -Inf)       # sets `x` to `-Inf`

sub _big2inf {
    my ($x, $y) = @_;
    Math::GMPq::Rmpq_set($$x, $$y);
    bless $x, __PACKAGE__;
    $x;
}

# Sets x to the negated value of Infinity that is given.

# Example:
#   _big2ninf(x, +Inf)       # sets `x` to `-Inf`
#   _big2ninf(x, -Inf)       # sets `x` to `+Inf`

sub _big2ninf {
    my ($x, $y) = @_;
    Math::GMPq::Rmpq_set($$x, $$y);
    Math::GMPq::Rmpq_neg($$x, $$x);
    bless $x, __PACKAGE__;
    $x;
}

=head2 neg

    $x->neg                        # => BigNum
    -$x                            # => BigNum

Negative value of C<$x>. Returns C<abs($x)> when C<$x> is negative,
otherwise returns C<-$x>.

=cut

sub neg {
    my $r = Math::GMPq::Rmpq_init();
    Math::GMPq::Rmpq_neg($r, ${$_[0]});
    bless \$r, __PACKAGE__;
}

=head2 bneg

    $x->bneg                       # => BigNum

Negative value of C<$x>, changing C<$x> in-place.

=cut

sub bneg {
    Math::GMPq::Rmpq_neg(${$_[0]}, ${$_[0]});
    $_[0];
}

=head2 abs

    $x->abs                        # => Inf

Absolute value of C<$x>.

=cut

sub abs {
    my $r = Math::GMPq::Rmpq_init();
    Math::GMPq::Rmpq_abs($r, ${$_[0]});
    bless \$r, __PACKAGE__;
}

=head2 babs

    $x->babs                       # => Inf

Sets C<$x> in-place to its absolute value.

=cut

sub babs {
    Math::GMPq::Rmpq_abs(${$_[0]}, ${$_[0]});
    $_[0];
}

=head2 copy

    $x->copy                       # => Inf

Returns a deep copy of the self object.

=cut

*copy = \&Math::BigNum::copy;

=head2 mone

    $x->mone                       # => BigNum

Returns a BigNum object which stores the value C<-1>.

=cut

*mone = \&Math::BigNum::mone;

=head2 zero

    $x->zero                       # => BigNum

Returns a BigNum object which stores the value C<0>.

=cut

*zero = \&Math::BigNum::zero;

=head2 one

    $x->one                        # => BigNum

Returns a BigNum object which stores the value C<+1>.

=cut

*one = \&Math::BigNum::one;

=head2 bmone

    $x->bmone                      # => BigNum

Promotes C<$x> to a BigNum object which stores the value C<-1>.

=cut

*bmone = \&Math::BigNum::bmone;

=head2 bzero

    $x->bzero                      # => BigNum

Promotes C<$x> to a BigNum object which stores the value C<0>.

=cut

*bzero = \&Math::BigNum::bzero;

=head2 bone

    $x->bone                       # => BigNum

Promotes C<$x> to a BigNum object which stores the value C<+1>.

=cut

*bone = \&Math::BigNum::bone;

=head2 nan

    $x->nan                        # => Nan

Returns a Nan object, which stores the Not-a-Number value.

=cut

*nan = \&Math::BigNum::Nan::nan;

=head2 bnan

    $x->bnan                       # => Nan

Promotes C<$x> to a Nan object.

=cut

*bnan = \&Math::BigNum::Nan::bnan;

=head2 inf

    $x->inf                        # => Inf

Returns an Inf object, which stores the +Infinity value.

=cut

sub inf {
    my $r = Math::GMPq::Rmpq_init();
    Math::GMPq::Rmpq_set_ui($r, 1, 0);
    bless \$r, __PACKAGE__;
}

=head2 ninf

    $x->ninf                       # => Inf

Returns an Inf object, which stores the -Infinity value.

=cut

sub ninf {
    my $r = Math::GMPq::Rmpq_init();
    Math::GMPq::Rmpq_set_si($r, -1, 0);
    bless \$r, __PACKAGE__;
}

=head2 binf

    $x->binf                       # => Inf

Changes C<$x> in-place to +Infinity.

=cut

sub binf {
    my ($x) = @_;
    Math::GMPq::Rmpq_set_ui($$x, 1, 0);
    if (ref($x) ne __PACKAGE__) {
        bless $x, __PACKAGE__;
    }
    $x;
}

=head2 bninf

    $x->bninf                      # => Inf

Changes C<$x> in-place to -Infinity.

=cut

sub bninf {
    my ($x) = @_;
    Math::GMPq::Rmpq_set_si($$x, -1, 0);
    if (ref($x) ne __PACKAGE__) {
        bless $x, __PACKAGE__;
    }
    $x;
}

sub is_inf {
    my ($self, $sign) = @_;
    if (defined $sign) {
        if ($sign eq '+') {
            return $self->is_pos;
        }
        elsif ($sign eq '-') {
            return $self->is_neg;
        }
    }

    $self->is_pos;
}

sub is_ninf {
    Math::GMPq::Rmpq_sgn(${$_[0]}) < 0;
}

sub is_neg {
    Math::GMPq::Rmpq_sgn(${$_[0]}) < 0;
}

sub is_pos {
    Math::GMPq::Rmpq_sgn(${$_[0]}) > 0;
}

sub is_nan { 0 }

*is_zero  = \&is_nan;
*is_one   = \&is_nan;
*is_mone  = \&is_nan;
*is_prime = \&is_nan;
*is_psqr  = \&is_nan;
*is_ppow  = \&is_nan;
*is_pow   = \&is_nan;
*is_div   = \&is_nan;
*is_even  = \&is_nan;
*is_odd   = \&is_nan;
*is_real  = \&is_nan;
*is_int   = \&is_nan;

sub sign { $_[0]->is_pos ? 1 : -1 }

sub popcount { -1 }

=head2 add / iadd

    $x->add(BigNum)                # => Inf
    $x->add(Scalar)                # => Inf
    $x->add(Inf)                   # => Inf | Nan

    Scalar + Inf                   # => Inf
    Inf + BigNum                   # => Inf
    Inf + Scalar                   # => Inf
    Inf + Inf                      # => Inf | Nan

Addition of C<$x> and C<$y>.

=cut

Class::Multimethods::multimethod add => qw(Math::BigNum::Inf Math::BigNum::Inf) => sub {
    $_[0]->eq($_[1]) ? $_[0]->copy : nan();
};

Class::Multimethods::multimethod add => qw(Math::BigNum::Inf *) => sub {
    $_[0]->add(Math::BigNum->new($_[1]));
};

Class::Multimethods::multimethod add => qw(* Math::BigNum::Inf) => sub {
    Math::BigNum->new($_[0])->add($_[1]);
};

Class::Multimethods::multimethod add => qw(Math::BigNum::Inf Math::BigNum)      => \&copy;
Class::Multimethods::multimethod add => qw(Math::BigNum::Inf Math::BigNum::Nan) => \&nan;

*iadd = \&add;
*fadd = \&add;

=head2 badd / biadd

    $x->badd(BigNum)               # => Inf
    $x->badd(Scalar)               # => Inf
    $x->badd(Inf)                  # => Inf | Nan

    Inf += BigNum                  # => Inf
    Inf += Scalar                  # => Inf
    Inf += Inf                     # => Inf | Nan

Addition of C<$x> and C<$y>, changing C<$x> in-place.

=cut

Class::Multimethods::multimethod badd => qw(Math::BigNum::Inf Math::BigNum::Inf) => sub {
    $_[0]->eq($_[1]) ? $_[0] : $_[0]->bnan;
};

Class::Multimethods::multimethod badd => qw(Math::BigNum::Inf *) => sub {
    $_[0]->badd(Math::BigNum->new($_[1]));
};

Class::Multimethods::multimethod badd => qw(Math::BigNum::Inf Math::BigNum)      => \&_self;
Class::Multimethods::multimethod badd => qw(Math::BigNum::Inf Math::BigNum::Nan) => \&bnan;

*biadd = \&badd;
*bfadd = \&badd;

=head2 sub / isub

    $x->sub(BigNum)                # => Inf
    $x->sub(Scalar)                # => Inf
    $x->sub(Inf)                   # => Inf | Nan

    Scalar - Inf                   # => Inf
    Inf - BigNum                   # => Inf
    Inf - Scalar                   # => Inf
    Inf - Inf                      # => Inf | Nan

Subtraction of C<$x> and C<$y>.

=cut

Class::Multimethods::multimethod sub => qw(Math::BigNum::Inf *) => sub {
    $_[0]->sub(Math::BigNum->new($_[1]));
};

Class::Multimethods::multimethod sub => qw(* Math::BigNum::Inf) => sub {
    Math::BigNum->new($_[0])->sub($_[1]);
};

Class::Multimethods::multimethod sub => qw(Math::BigNum::Inf Math::BigNum) => \&copy;

Class::Multimethods::multimethod sub => qw(Math::BigNum::Inf Math::BigNum::Inf) => sub {
    $_[0]->eq($_[1]) ? nan() : $_[0]->copy;
};

Class::Multimethods::multimethod sub => qw(Math::BigNum::Inf Math::BigNum::Nan) => \&nan;

*isub = \&sub;
*fsub = \&sub;

=head2 bsub / bisub

    $x->bsub(BigNum)               # => Inf
    $x->bsub(Scalar)               # => Inf
    $x->bsub(Inf)                  # => Inf | Nan

    Inf -= BigNum                  # => Inf
    Inf -= Scalar                  # => Inf
    Inf -= Inf                     # => Inf | Nan

Subtraction of C<$x> and C<$y>, changing C<$x> in-place.

=cut

Class::Multimethods::multimethod bsub => qw(Math::BigNum::Inf Math::BigNum) => \&_self;

Class::Multimethods::multimethod bsub => qw(Math::BigNum::Inf Math::BigNum::Inf) => sub {
    $_[0]->eq($_[1]) ? $_[0]->bnan : $_[0];
};

Class::Multimethods::multimethod bsub => qw(Math::BigNum::Inf *) => sub {
    $_[0]->bsub(Math::BigNum->new($_[1]));
};

Class::Multimethods::multimethod bsub => qw(Math::BigNum::Inf Math::BigNum::Nan) => \&bnan;

*bisub = \&bsub;
*bfsub = \&bsub;

=head2 mul / imul

    $x->mul(BigNum)                # => Inf | Nan
    $x->mul(Scalar)                # => Inf | Nan
    $x->mul(Inf)                   # => Inf

    Scalar * Inf                   # => Inf | Nan
    Inf * BigNum                   # => Inf | Nan
    Inf * Scalar                   # => Inf | Nan
    Inf * Inf                      # => Inf

Multiplication of C<$x> and C<$y>.

=cut

Class::Multimethods::multimethod mul => qw(Math::BigNum::Inf Math::BigNum::Inf) => sub {
    $_[0]->copy->bmul($_[1]);
};

Class::Multimethods::multimethod mul => qw(Math::BigNum::Inf Math::BigNum) => sub {
    $_[0]->copy->bmul($_[1]);
};

Class::Multimethods::multimethod mul => qw(Math::BigNum::Inf *) => sub {
    $_[0]->copy->bmul(Math::BigNum->new($_[1]));
};

Class::Multimethods::multimethod mul => qw(* Math::BigNum::Inf) => sub {
    $_[1]->copy->bmul(Math::BigNum->new($_[0]));
};

Class::Multimethods::multimethod mul => qw(Math::BigNum::Inf Math::BigNum::Nan) => \&nan;

*imul = \&mul;
*fmul = \&mul;

=head2 bmul / bimul

    $x->bmul(BigNum)               # => Inf | Nan
    $x->bmul(Scalar)               # => Inf | Nan
    $x->bmul(Inf)                  # => Inf

    Inf *= BigNum                  # => Inf | Nan
    Inf *= Scalar                  # => Inf | Nan
    Inf *= Inf                     # => Inf

Multiplication of C<$x> and C<$y>, changing C<$x> in-place.

=cut

Class::Multimethods::multimethod bmul => qw(Math::BigNum::Inf Math::BigNum) => sub {
    my ($x, $y) = @_;
    my $sgn = Math::GMPq::Rmpq_sgn($$y);
    $sgn < 0 ? $x->bneg : $sgn > 0 ? $x : $x->bnan;
};

Class::Multimethods::multimethod bmul => qw(Math::BigNum::Inf Math::BigNum::Inf) => sub {
    my ($x, $y) = @_;
    my $xsgn = Math::GMPq::Rmpq_sgn($$x);
    my $ysgn = Math::GMPq::Rmpq_sgn($$y);

    # Inf * Inf = Inf
    if ($xsgn > 0 and $ysgn > 0) {
        $x;
    }

    # Inf * -Inf = -Inf
    elsif ($xsgn > 0 and $ysgn < 0) {
        $x->bneg;
    }

    # -Inf * Inf = -Inf
    elsif ($xsgn < 0 and $ysgn > 0) {
        $x;
    }

    # -Inf * -Inf = Inf
    else {
        $x->bneg;
    }
};

Class::Multimethods::multimethod bmul => qw(Math::BigNum::Inf *) => sub {
    $_[0]->bmul(Math::BigNum->new($_[1]));
};

Class::Multimethods::multimethod bmul => qw(Math::BigNum::Inf Math::BigNum::Nan) => \&bnan;

*bimul = \&bmul;
*bfmul = \&bmul;

=head2 div / idiv

    $x->div(BigNum)                # => Inf
    $x->div(Scalar)                # => Inf
    $x->div(Inf)                   # => Nan

    Scalar / Inf                   # => BigNum(0)
    Inf / BigNum                   # => Inf
    Inf / Scalar                   # => Inf
    Inf / Inf                      # => Nan

Division of C<$x> and C<$y>.

=cut

Class::Multimethods::multimethod div => qw(Math::BigNum::Inf Math::BigNum) => sub {
    $_[1]->is_neg ? $_[0]->neg : $_[0]->copy;
};

Class::Multimethods::multimethod div => qw(Math::BigNum::Inf *) => sub {
    $_[0]->div(Math::BigNum->new($_[1]));
};

Class::Multimethods::multimethod div => qw(* Math::BigNum::Inf) => sub {
    Math::BigNum->new($_[0])->div($_[1]);
};

Class::Multimethods::multimethod div => qw(Math::BigNum::Inf Math::BigNum::Inf) => \&nan;
Class::Multimethods::multimethod div => qw(Math::BigNum::Inf Math::BigNum::Nan) => \&nan;

*idiv = \&div;
*fdiv = \&div;

=head2 bdiv / bidiv

    $x->bdiv(BigNum)               # => Inf
    $x->bdiv(Scalar)               # => Inf
    $x->bdiv(Inf)                  # => Nan

    Inf /= BigNum                  # => Inf
    Inf /= Scalar                  # => Inf
    Inf /= Inf                     # => Nan

Division of C<$x> and C<$y>, changing C<$x> in-place.

=cut

Class::Multimethods::multimethod bdiv => qw(Math::BigNum::Inf Math::BigNum) => sub {
    $_[1]->is_neg ? $_[0]->bneg : $_[0];
};

Class::Multimethods::multimethod bdiv => qw(Math::BigNum::Inf *) => sub {
    $_[0]->bdiv(Math::BigNum->new($_[1]));
};

Class::Multimethods::multimethod bdiv => qw(Math::BigNum::Inf Math::BigNum::Inf) => \&bnan;
Class::Multimethods::multimethod bdiv => qw(Math::BigNum::Inf Math::BigNum::Nan) => \&bnan;

*bidiv = \&bdiv;
*bfdiv = \&bdiv;

#
## Comparisons
#

=head2 eq

    $x->eq(Inf)                    # => Bool
    $x->eq(Nan)                    # => Bool
    $x->eq(BigNum)                 # => Bool

    $x == $y                       # => Bool


Equality test:

    Inf == Inf      # true
    Inf == -Inf     # false
    Inf == 0        # false
    Inf == MaN      # false

=cut

Class::Multimethods::multimethod eq => qw(Math::BigNum::Inf Math::BigNum::Inf) => sub {
    Math::GMPq::Rmpq_sgn(${$_[0]}) == Math::GMPq::Rmpq_sgn(${$_[1]});
};

Class::Multimethods::multimethod eq => qw(Math::BigNum::Inf Math::BigNum)      => sub { 0 };
Class::Multimethods::multimethod eq => qw(Math::BigNum::Inf Math::BigNum::Nan) => sub { 0 };

Class::Multimethods::multimethod eq => qw(Math::BigNum::Inf *) => sub {
    $_[0]->eq(Math::BigNum->new($_[1]));
};

=head2 ne

    $x->ne(Inf)                    # => Bool
    $x->ne(Nan)                    # => Bool
    $x->ne(BigNum)                 # => Bool

    $x != $y                       # => Bool

Inequality test:

    Inf != Inf      # false
    Inf != -Inf     # true
    Inf != 0        # true
    Inf != MaN      # true

=cut

Class::Multimethods::multimethod ne => qw(Math::BigNum::Inf Math::BigNum::Inf) => sub {
    Math::GMPq::Rmpq_sgn(${$_[0]}) != Math::GMPq::Rmpq_sgn(${$_[1]});
};

Class::Multimethods::multimethod ne => qw(Math::BigNum::Inf Math::BigNum)      => sub { 1 };
Class::Multimethods::multimethod ne => qw(Math::BigNum::Inf Math::BigNum::Nan) => sub { 1 };

Class::Multimethods::multimethod ne => qw(Math::BigNum::Inf *) => sub {
    $_[0]->ne(Math::BigNum->new($_[1]));
};

=head2 cmp

    $x->cmp(Inf)                   # => Scalar
    $x->cmp(BigNum)                # => Scalar
    $x->cmp(Nan)                   # => undef

    Inf <=> Any                    # => Scalar
    Any <=> Inf                    # => Scalar
    Inf <=> Nan                    # => undef

Compares C<$x> to C<$y> and returns a positive value when C<$x> is greater than C<$y>,
a negative value when C<$x> is lower than C<$y>, or zero when C<$x> and C<$y> are equal.

=cut

Class::Multimethods::multimethod cmp => qw(Math::BigNum::Inf Math::BigNum::Inf) => sub {
    Math::GMPq::Rmpq_sgn(${$_[0]}) <=> Math::GMPq::Rmpq_sgn(${$_[1]});
};

Class::Multimethods::multimethod cmp => qw(Math::BigNum::Inf Math::BigNum) => sub {
    (Math::GMPq::Rmpq_sgn(${$_[0]}) > 0) ? 1 : -1;
};

Class::Multimethods::multimethod cmp => qw(Math::BigNum::Inf *) => sub {
    $_[0]->cmp(Math::BigNum->new($_[1]));
};

Class::Multimethods::multimethod cmp => qw(* Math::BigNum::Inf) => sub {
    Math::BigNum->new($_[0])->cmp($_[1]);
};

Class::Multimethods::multimethod cmp => qw(Math::BigNum::Inf Math::BigNum::Nan) => sub { };

=head2 acmp

    $x->acmp(Inf)                  # => Scalar
    $x->acmp(BigNum)               # => Scalar
    $x->acmp(Nan)                  # => undef

Compares the absolute values of C<$x> and C<$y>.

=cut

Class::Multimethods::multimethod acmp => qw(Math::BigNum::Inf Math::BigNum::Inf) => sub {
    $_[0]->abs->cmp($_[1]->abs);
};

Class::Multimethods::multimethod acmp => qw(Math::BigNum::Inf Math::BigNum) => sub {
    $_[0]->abs->cmp($_[1]->abs);
};

Class::Multimethods::multimethod acmp => qw(Math::BigNum::Inf *) => sub {
    $_[0]->acmp(Math::BigNum->new($_[1]));
};

Class::Multimethods::multimethod acmp => qw(Math::BigNum::Inf Math::BigNum::Nan) => sub { };

=head2 gt

    $x->gt(Any)                    # => Bool
    Inf > Any                      # => Bool
    Any > Inf                      # => Bool

Returns true if C<$x> is greater than C<$y>.

=cut

Class::Multimethods::multimethod gt => qw(Math::BigNum::Inf Math::BigNum::Inf) => sub {
    Math::GMPq::Rmpq_sgn(${$_[0]}) > Math::GMPq::Rmpq_sgn(${$_[1]});
};

Class::Multimethods::multimethod gt => qw(Math::BigNum::Inf Math::BigNum) => sub {
    Math::GMPq::Rmpq_sgn(${$_[0]}) > 0;
};

Class::Multimethods::multimethod gt => qw(Math::BigNum::Inf *) => sub {
    $_[0]->gt(Math::BigNum->new($_[1]));
};

Class::Multimethods::multimethod gt => qw(* Math::BigNum::Inf) => sub {
    Math::BigNum->new($_[0])->gt($_[1]);
};

=for comment
Class::Multimethods::multimethod gt => qw(Math::BigNum::Inf Math::BigNum::Complex) => sub {
    Math::GMPq::Rmpq_sgn(${$_[0]}) > 0;
};
=cut

Class::Multimethods::multimethod gt => qw(Math::BigNum::Inf Math::BigNum::Nan) => sub { 0 };

=head2 ge

    $x->ge(Any)                    # => Bool
    Inf >= Any                     # => Bool
    Any >= Inf                     # => Bool

Returns true if C<$x> is greater or equal to C<$y>.

=cut

Class::Multimethods::multimethod ge => qw(Math::BigNum::Inf Math::BigNum::Inf) => sub {
    Math::GMPq::Rmpq_sgn(${$_[0]}) >= Math::GMPq::Rmpq_sgn(${$_[1]});
};

Class::Multimethods::multimethod ge => qw(Math::BigNum::Inf Math::BigNum) => sub {
    Math::GMPq::Rmpq_sgn(${$_[0]}) > 0;
};

Class::Multimethods::multimethod ge => qw(Math::BigNum::Inf *) => sub {
    $_[0]->ge(Math::BigNum->new($_[1]));
};

Class::Multimethods::multimethod ge => qw(* Math::BigNum::Inf) => sub {
    Math::BigNum->new($_[0])->ge($_[1]);
};

=for comment
Class::Multimethods::multimethod ge => qw(Math::BigNum::Inf Math::BigNum::Complex) => sub {
    Math::GMPq::Rmpq_sgn(${$_[0]}) > 0;
};
=cut

Class::Multimethods::multimethod ge => qw(Math::BigNum::Inf Math::BigNum::Nan) => sub { 0 };

=head2 lt

    $x->lt(Any)                    # => Bool
    Inf < Any                      # => Bool
    Any > Inf                      # => Bool

Returns true if C<$x> is less than C<$y>.

=cut

Class::Multimethods::multimethod lt => qw(Math::BigNum::Inf Math::BigNum::Inf) => sub {
    Math::GMPq::Rmpq_sgn(${$_[0]}) < Math::GMPq::Rmpq_sgn(${$_[1]});
};

Class::Multimethods::multimethod lt => qw(Math::BigNum::Inf Math::BigNum) => sub {
    Math::GMPq::Rmpq_sgn(${$_[0]}) < 0;
};

Class::Multimethods::multimethod lt => qw(Math::BigNum::Inf *) => sub {
    $_[0]->lt(Math::BigNum->new($_[1]));
};

Class::Multimethods::multimethod lt => qw(* Math::BigNum::Inf) => sub {
    Math::BigNum->new($_[0])->lt($_[1]);
};

=for comment
Class::Multimethods::multimethod lt => qw(Math::BigNum::Inf Math::BigNum::Complex) => sub {
    Math::GMPq::Rmpq_sgn(${$_[0]}) < 0;
};
=cut

Class::Multimethods::multimethod lt => qw(Math::BigNum::Inf Math::BigNum::Nan) => sub { 0 };

=head2 le

    $x->le(Any)                    # => Bool
    Inf <= Any                     # => Bool
    Any <= Inf                     # => Bool

Returns true if C<$x> is less than or equal to C<$y>.

=cut

Class::Multimethods::multimethod le => qw(Math::BigNum::Inf Math::BigNum::Inf) => sub {
    Math::GMPq::Rmpq_sgn(${$_[0]}) <= Math::GMPq::Rmpq_sgn(${$_[1]});
};

Class::Multimethods::multimethod le => qw(Math::BigNum::Inf Math::BigNum) => sub {
    Math::GMPq::Rmpq_sgn(${$_[0]}) < 0;
};

Class::Multimethods::multimethod le => qw(Math::BigNum::Inf *) => sub {
    $_[0]->le(Math::BigNum->new($_[1]));
};

Class::Multimethods::multimethod le => qw(* Math::BigNum::Inf) => sub {
    Math::BigNum->new($_[0])->le($_[1]);
};

=for comment
Class::Multimethods::multimethod le => qw(Math::BigNum::Inf Math::BigNum::Complex) => sub {
    Math::GMPq::Rmpq_sgn(${$_[0]}) < 0;
};
=cut

Class::Multimethods::multimethod le => qw(Math::BigNum::Inf Math::BigNum::Nan) => sub { 0 };

=head2 min

    $x->min(BigNum)                # => Inf | BigNum
    $x->min(Inf)                   # => Inf

Returns C<$x> if C<$x> is lower than C<$y>. Returns C<$y> otherwise.

=cut

Class::Multimethods::multimethod min => qw(Math::BigNum::Inf *) => sub {
    $_[0]->is_neg ? $_[0] : $_[1];
};

Class::Multimethods::multimethod min => qw(Math::BigNum::Inf Math::BigNum::Nan) => sub {
    $_[1];
};

=head2 max

    $x->max(BigNum)                # => Inf | BigNum
    $x->max(Inf)                   # => Inf

Returns C<$x> if C<$x> is greater than C<$y>. Returns C<$y> otherwise.

=cut

Class::Multimethods::multimethod max => qw(Math::BigNum::Inf *) => sub {
    $_[0]->is_pos ? $_[0] : $_[1];
};

Class::Multimethods::multimethod max => qw(Math::BigNum::Inf Math::BigNum::Nan) => sub {
    $_[1];
};

#
## Trigonometric functions
#

=head2 atan

    $x->atan                       # => BigNum

Returns the inverse tangent of C<$x>.

=cut

#
## atan(+inf) = +pi/2
## atan(-inf) = -pi/2
#
sub atan {
    (Math::GMPq::Rmpq_sgn(${$_[0]}) > 0)
      ? Math::BigNum->pi->div(2)
      : Math::BigNum->pi->div(-2);
}

*atan2 = \&atan;

=for comment
#
## atanh(+inf) = -pi/2*i
## atanh(-inf) = +pi/2*i
#
sub atanh {
    (
     (Math::GMPq::Rmpq_sgn(${$_[0]}) > 0)
     ? Math::BigNum->pi->div(-2)
     : Math::BigNum->pi->div(2)
      ) *
      Math::BigNum::i();
}
=cut

*atanh = \&nan;

#
## asec(+inf) = pi/2
## asec(-inf) = pi/2
#
sub asec {
    Math::BigNum->pi->div(2);
}

=for comment
#
## asech(+inf) = pi/2*i
## asech(-inf) = pi/2*i
#
sub asech {
    Math::BigNum->pi->div(2) * Math::BigNum::i();
}
=cut

*asech = \&nan;

=for comment
#
## asin(+inf) = -inf*i
## asin(-inf) = inf*i
#
sub asin {
    (Math::GMPq::Rmpq_sgn(${$_[0]}) > 0)
      ? Math::BigNum::Complex->new(0, '-@Inf@')
      : Math::BigNum::Complex->new(0, '@Inf@');
}
=cut

*asin = \&nan;

=for comment
#
## acos(+inf) = inf*i
## acos(-inf) = -inf*i
#
sub acos {
    (Math::GMPq::Rmpq_sgn(${$_[0]}) > 0)
      ? Math::BigNum::Complex->new(0, '@Inf@')
      : Math::BigNum::Complex->new(0, '-@Inf@');
}
=cut

*acos = \&nan;

#
## tanh(+inf) = coth(+inf) = erf(+inf) = +1
## tanh(-inf) = coth(-inf) = erf(-inf) = -1
#
sub tanh {
    (Math::GMPq::Rmpq_sgn(${$_[0]}) > 0)
      ? one()
      : mone();
}

*coth = \&tanh;
*erf  = \&tanh;

#
## tan(+/-Inf) = < +inf
#
*tan = \&nan;

#
## cot(+/-Inf) = < +inf
#

*cot = \&nan;

#
## sec(+/-inf) = {< -1, > 1}
#

*sec = \&nan;

#
## sin(+inf) = sin(-inf) = NaN
## cos(+inf) = cos(-inf) = NaN
#

*sin = \&nan;
*cos = \&nan;

#
## sech(+inf) = sech(-inf) = 0
#

*sech  = \&zero;
*csch  = \&zero;
*acsc  = \&zero;
*acsch = \&zero;
*acot  = \&zero;
*acoth = \&zero;

#
## csc(+/-inf) = { < -1, > 1 }
#

*csc = \&nan;

#
## acosh(+/-inf) = cosh(+/-inf) = +inf
#

*cosh  = \&inf;
*acosh = \&inf;

#
## sinh(+inf) = asinh(+inf) = +inf
## sinh(-inf) = asinh(-inf) = -inf
#

*sinh  = \&copy;
*asinh = \&copy;

#
## Other functions
#

=head2 sqr

    $x->sqr                        # => Inf

Returns the result of C<$x**2>.

=cut

sub sqr  { $_[0]->mul($_[0]) }
sub bsqr { $_[0]->bmul($_[0]) }

=head2 sqrt / isqrt

    $x->sqrt           => Inf

Square root of C<$x>.

=cut

*sqrt  = \&inf;
*isqrt = \&sqrt;

sub isqrtrem {
    my ($x) = @_;
    my $sqrt = $x->isqrt;
    ($sqrt, $x->isub($sqrt->bimul($sqrt)));
}

sub irootrem {
    my ($x, $y) = @_;
    my $root = $x->iroot($y);
    ($root, $x->isub($root->bipow($y)));
}

=head2 bsqrt / bisqrt

Square root of C<$x>, changing C<$x> in-place.

=cut

*bsqrt  = \&binf;
*bisqrt = \&bsqrt;

=head2 pow / ipow

    $x->pow(BigNum)                # => Inf | BigNum
    $x->pow(Scalar)                # => Inf | BigNum
    $x->pow(Inf)                   # => Inf | BigNum

    Scalar ** Inf                  # => Inf | BigNum(0)
    Inf ** BigNum                  # => Inf | BigNum
    Inf ** Scalar                  # => Inf | BigNum

Raises C<$x> to the power C<$y>.

=cut

Class::Multimethods::multimethod pow => qw(Math::BigNum::Inf Math::BigNum::Inf) => sub {
    $_[0]->copy->bpow($_[1]);
};

Class::Multimethods::multimethod pow => qw(Math::BigNum::Inf Math::BigNum) => sub {
    $_[0]->copy->bpow($_[1]);
};

Class::Multimethods::multimethod pow => qw(Math::BigNum::Inf *) => sub {
    $_[0]->copy->bpow(Math::BigNum->new($_[1]));
};

Class::Multimethods::multimethod pow => qw(* Math::BigNum::Inf) => sub {
    Math::BigNum->new($_[0])->pow($_[1]);
};

Class::Multimethods::multimethod pow => qw(Math::BigNum::Inf Math::BigNum::Nan) => \&nan;

*ipow = \&pow;    # probably, truncate first?
*fpow = \&pow;

=head2 bpow / bipow

    $x->bpow(BigNum)               # => Inf | BigNum
    $x->bpow(Scalar)               # => Inf | BigNum
    $x->bpow(Inf)                  # => Inf | BigNum

    Inf **= BigNum                 # => Inf | BigNum
    Inf **= Scalar                 # => Inf | BigNum

Same C<pow()>, except that it changes C<$x> in-place.

=cut

Class::Multimethods::multimethod bpow => qw(Math::BigNum::Inf Math::BigNum) => sub {
    my ($x, $y) = @_;
    $y->is_neg      ? $x->bzero
      : $y->is_zero ? $x->bone
      : $x->is_neg  ? $y->is_odd
          ? $x
          : $x->bneg
      : $x;
};

Class::Multimethods::multimethod bpow => qw(Math::BigNum::Inf *) => sub {
    $_[0]->bpow(Math::BigNum->new($_[1]));
};

# (+/-Inf) ** (-Inf) = 0
# (+/-Inf) ** (+Inf) = +Inf

Class::Multimethods::multimethod bpow => qw(Math::BigNum::Inf Math::BigNum::Inf) => sub {
    $_[1]->is_neg ? $_[0]->bzero : $_[0]->binf;
};

Class::Multimethods::multimethod bpow => qw(Math::BigNum::Inf Math::BigNum::Nan) => \&bnan;

*bipow = \&bpow;    # probably, truncate first?
*bfpow = \&bpow;

=head2 root / iroot

    $x->root(BigNum)               # => BigNum | Inf | Nan
    $x->root(Scalar)               # => BigNum | Inf | Nan

Nth root of C<$x>. Same as C<$x ** (1/$y)>.

=cut

Class::Multimethods::multimethod root => qw(Math::BigNum::Inf Math::BigNum) => sub {
    $_[0]->pow($_[1]->inv);
};

Class::Multimethods::multimethod root => qw(Math::BigNum::Inf *) => sub {
    $_[0]->pow(Math::BigNum->new($_[1])->inv);
};

Class::Multimethods::multimethod root => qw(Math::BigNum::Inf Math::BigNum::Inf) => \&one;
Class::Multimethods::multimethod root => qw(Math::BigNum::Inf Math::BigNum::Nan) => \&nan;

*iroot = \&root;    # probably, truncate first?

=head2 broot / biroot

    $x->broot(BigNum)              # => BigNum | Inf | Nan
    $x->broot(Scalar)              # => BigNum | Inf | Nan

Nth root of C<$x>, changing C<$x> in-place.

=cut

Class::Multimethods::multimethod broot => qw(Math::BigNum::Inf Math::BigNum) => sub {
    $_[0]->bpow($_[1]->inv);
};

Class::Multimethods::multimethod broot => qw(Math::BigNum::Inf *) => sub {
    $_[0]->bpow(Math::BigNum->new($_[1])->inv);
};

Class::Multimethods::multimethod broot => qw(Math::BigNum::Inf Math::BigNum::Inf) => \&bone;
Class::Multimethods::multimethod broot => qw(Math::BigNum::Inf Math::BigNum::Nan) => \&bnan;

*biroot = \&broot;    # probably, truncate first?

=head2 binomial

    $x->binomial(BigNum)           # => BigNum | Inf
    $x->binomial(Scalar)           # => BigNum | Inf
    $x->binomial(Inf)              # => BigNum | Inf

Binomial coefficient of C<$x> and C<$y>.

=cut

#
## binomial(+/-inf, x) = 0       | for x < 0
## binomial(+/-inf, 0) = 1
## binomial(+/-inf, inf) = 1
## binomial(+inf, x) = inf       | for x > 0
## binomial(-inf, x) = -inf      | for x > 0
##
#

Class::Multimethods::multimethod binomial => qw(Math::BigNum::Inf Math::BigNum) => sub {
        $_[1]->is_neg  ? zero()
      : $_[1]->is_zero ? one()
      :                  $_[0]->copy;
};

Class::Multimethods::multimethod binomial => qw(Math::BigNum::Inf Math::BigNum::Inf) => \&one;

=head2 exp

    $x->exp                        # => BigNum | Inf

Returns the following values:

    exp(+Inf) = Inf
    exp(-Inf) = 0

=cut

sub exp {
    $_[0]->is_neg ? zero() : $_[0]->copy;
}

*exp2  = \&exp;
*exp10 = \&exp;
*eint  = \&exp;

=head2 bexp

    $x->bexp                       # => BigNum | Inf

Same as C<exp()>, except that it changes C<$x> in-place.

=cut

sub bexp {
    $_[0]->is_neg ? $_[0]->bzero : $_[0];
}

=head2 inv

    $x->inv                        # => BigNum

Inverse value of +/-Infinity. Always returns zero.

=cut

*inv  = \&zero;
*binv = \&bzero;

=head2 mod / imod

    $x->mod(BigNum)                # => Nan
    $x->mod(Inf)                   # => Nan

    Scalar % Inf                   # => BigNum | Inf

Returns the remained of C<$x> divided by C<$y>.

=cut

# +x mod +Inf = x
# +x mod -Inf = -Inf
# -x mod +Inf = +Inf
# -x mod -Inf = x

Class::Multimethods::multimethod mod => qw(* Math::BigNum::Inf) => sub {
    Math::BigNum->new($_[0])->mod($_[1]);
};

Class::Multimethods::multimethod mod => qw(Math::BigNum::Inf *) => sub {
    $_[0]->mod(Math::BigNum->new($_[1]));
};

Class::Multimethods::multimethod mod => qw(Math::BigNum::Inf Math::BigNum)      => \&nan;
Class::Multimethods::multimethod mod => qw(Math::BigNum::Inf Math::BigNum::Inf) => \&nan;
Class::Multimethods::multimethod mod => qw(Math::BigNum::Inf Math::BigNum::Nan) => \&nan;

*imod = \&mod;

=head2 bmod / bimod

    $x->bmod(Any)                  # => NaN

Sets C<$x> to the reminder of C<$x> divided by <$y>, which
is always Nan.

=cut

*bmod  = \&bnan;
*bimod = \&bnan;

#
## Other methods
#

*modpow     = \&nan;
*modinv     = \&nan;
*next_prime = \&nan;

*agm   = \&nan;    # or copy?
*hypot = \&copy;

*and  = \&nan;
*band = \&band;
*ior  = \&nan;
*bior = \&bnan;
*xor  = \&nan;
*bxor = \&bnan;
*not  = \&nan;
*bnot = \&bnan;

*beta     = \&nan;
*bessel_j = \&nan;
*bessel_y = \&nan;

=head2 lsft

    $x->lsft(BigNum)               # => Inf
    $x->lsft(Scalar)               # => Inf
    $x->lsft(Inf)                  # => Inf | Nan

    Inf << BigNum                  # => Inf
    Inf << Scalar                  # => Inf
    Inf << Inf                     # => Inf | Nan

Left-shift operation. (C<$x * (2 ** $y)>)

=cut

# +Inf * (2 ** +Inf) = +Inf
# +Inf * (2 ** -Inf) = NaN
# -Inf * (2 ** -Inf) = NaN
# -Inf * (2 ** +Inf) = -Inf

Class::Multimethods::multimethod lsft => qw(Math::BigNum::Inf Math::BigNum::Inf) => sub {
    my ($x, $y) = @_;
    my $xn = $x->is_neg;
    my $yn = $y->is_neg;
    $xn ? ($yn ? nan() : $x->copy) : ($yn ? nan() : $x->copy);
};

Class::Multimethods::multimethod lsft => qw(Math::BigNum::Inf Math::BigNum)      => \&copy;
Class::Multimethods::multimethod lsft => qw(Math::BigNum::Inf Math::BigNum::Nan) => \&nan;

#  x * (2 ** -Inf) = 0
# +x * (2 ** +Inf) = +Inf
# -x * (2 ** +Inf) = -Inf
#  0 * (2 ** +Inf) = NaN

Class::Multimethods::multimethod lsft => qw(Math::BigNum::Inf *) => sub {
    $_[0]->lsft(Math::BigNum->new($_[1]));
};

Class::Multimethods::multimethod lsft => qw(* Math::BigNum::Inf) => sub {
    Math::BigNum->new($_[0])->lsft($_[1]);
};

=head2 blsft

    $x->blsft(BigNum)              # => Inf
    $x->blsft(Scalar)              # => Inf
    $x->blsft(Inf)                 # => Inf | Nan

    Inf <<= BigNum                 # => Inf
    Inf <<= Scalar                 # => Inf
    Inf <<= Inf                    # => Inf | Nan

Left-shift operation, changing C<$x> in-place. (C<$x * (2 ** $y)>)

=cut

Class::Multimethods::multimethod blsft => qw(Math::BigNum::Inf Math::BigNum::Inf) => sub {
    my ($x, $y) = @_;
    my $xn = $x->is_neg;
    my $yn = $y->is_neg;
    $xn ? ($yn ? $x->bnan() : $x) : ($yn ? $x->bnan() : $x);
};

Class::Multimethods::multimethod blsft => qw(Math::BigNum::Inf *) => sub {
    $_[0]->blsft(Math::BigNum->new($_[1]));
};

Class::Multimethods::multimethod blsft => qw(Math::BigNum::Inf Math::BigNum)      => \&_self;
Class::Multimethods::multimethod blsft => qw(Math::BigNum::Inf Math::BigNum::Nan) => \&bnan;

=head2 rsft

    $x->rsft(BigNum)               # => Inf
    $x->rsft(Scalar)               # => Inf

    Inf >> BigNum                  # => Inf
    Inf >> Scalar                  # => Inf
    Inf >> BigNum                  # => Inf

Right-shift operation. (C<$x / (2 ** $y)>)

=cut

# +Inf / (2 ** +Inf) = NaN
# +Inf / (2 ** -Inf) = +Inf
# -Inf / (2 ** -Inf) = +Inf
# -Inf / (2 ** +Inf) = NaN

Class::Multimethods::multimethod rsft => qw(Math::BigNum::Inf Math::BigNum::Inf) => sub {
    my ($x, $y) = @_;
    my $xn = $x->is_neg;
    my $yn = $y->is_neg;
    $xn ? ($yn ? $x->neg : nan()) : ($yn ? $x->copy : nan());
};

Class::Multimethods::multimethod rsft => qw(Math::BigNum::Inf Math::BigNum)      => \&copy;
Class::Multimethods::multimethod rsft => qw(Math::BigNum::Inf Math::BigNum::Nan) => \&nan;

#  x / (2 ** +Inf) = 0
# +x / (2 ** -Inf) = +Inf
# -x / (2 ** -Inf) = -Inf
#  0 / (2 ** -Inf) = NaN

Class::Multimethods::multimethod rsft => qw(Math::BigNum::Inf *) => sub {
    $_[0]->rsft(Math::BigNum->new($_[1]));
};

Class::Multimethods::multimethod rsft => qw(* Math::BigNum::Inf) => sub {
    Math::BigNum->new($_[0])->rsft($_[1]);
};

=head2 brsft

    $x->brsft(BigNum)              # => Inf
    $x->brsft(Scalar)              # => Inf

    Inf >>= BigNum                 # => Inf
    Inf >>= Scalar                 # => Inf

Integer right-shift operation. (C<$x / (2 ** $y)>)

=cut

Class::Multimethods::multimethod brsft => qw(Math::BigNum::Inf Math::BigNum::Inf) => sub {
    my ($x, $y) = @_;
    my $xn = $x->is_neg;
    my $yn = $y->is_neg;
    $xn ? ($yn ? $x->bneg : $x->bnan()) : ($yn ? $x : $x->bnan());
};

Class::Multimethods::multimethod brsft => qw(Math::BigNum::Inf *) => sub {
    $_[0]->brsft(Math::BigNum->new($_[1]));
};

Class::Multimethods::multimethod brsft => qw(Math::BigNum::Inf Math::BigNum)      => \&_self;
Class::Multimethods::multimethod brsft => qw(Math::BigNum::Inf Math::BigNum::Nan) => \&bnan;

*gcd = \&nan;
*lcm = \&nan;

*rand  = \&copy;
*irand = \&copy;

*int  = \&copy;
*bint = \&_self;

*round  = \&copy;
*bround = \&_self;

*float  = \&copy;
*bfloat = \&_self;

*floor = \&copy;
*ceil  = \&copy;

*inc  = \&copy;
*binc = \&_self;

*dec  = \&copy;
*bdec = \&_self;

*li        = \&inf;
*li2       = \&ninf;
*lgrt      = \&inf;
*lambert_w = \&inf;
*ln        = \&inf;
*bln       = \&binf;

*rad2deg = \&copy;
*deg2rad = \&copy;

*bernreal  = \&nan;
*bernfrac  = \&nan;
*harmfrac  = \&nan;
*harmreal  = \&nan;
*kronecker = \&nan;
*valuation = \&nan;
*remove    = \&nan;
*bremove   = \&bnan;

# log(+/-Inf) = +Inf
Class::Multimethods::multimethod log => qw(Math::BigNum::Inf) => \&inf;

# log(+/-Inf) / log(42) = +Inf
# log(+/-Inf) / log(-1) = (-i)*Inf       --> NaN in our case
# log(+/-Inf) / log(0)  = undefined      --> NaN

Class::Multimethods::multimethod log => qw(Math::BigNum::Inf Math::BigNum) => sub {
    Math::GMPq::Rmpq_sgn(${$_[1]}) <= 0 ? nan() : inf();
};

Class::Multimethods::multimethod log => qw(Math::BigNum::Inf Math::BigNum::Inf) => \&nan;
Class::Multimethods::multimethod log => qw(Math::BigNum::Inf Math::BigNum::Nan) => \&nan;

Class::Multimethods::multimethod log => qw(Math::BigNum::Inf *) => sub {
    $_[0]->log(Math::BigNum->new($_[1]));
};

Class::Multimethods::multimethod blog => qw(Math::BigNum::Inf) => \&binf;

Class::Multimethods::multimethod blog => qw(Math::BigNum::Inf Math::BigNum) => sub {
    Math::GMPq::Rmpq_sgn(${$_[1]}) <= 0 ? $_[0]->bnan : $_[0]->binf;
};

Class::Multimethods::multimethod blog => qw(Math::BigNum::Inf Math::BigNum::Inf) => \&bnan;
Class::Multimethods::multimethod blog => qw(Math::BigNum::Inf Math::BigNum::Nan) => \&bnan;

Class::Multimethods::multimethod blog => qw(Math::BigNum::Inf *) => sub {
    $_[0]->blog(Math::BigNum->new($_[1]));
};

sub gamma {
    $_[0]->is_neg ? nan() : $_[0]->copy;
}

sub lngamma {
    $_[0]->is_neg ? nan() : $_[0]->copy;
}

sub lgamma {
    $_[0]->is_neg ? nan() : $_[0]->copy;
}

sub digamma {
    $_[0]->is_neg ? nan() : $_[0]->copy;
}

sub zeta {
    $_[0]->is_neg ? nan() : one();
}

*eta = \&zeta;

sub erfc {
    $_[0]->is_pos ? zero() : one()->blsft(1);
}

sub fac {
    $_[0]->is_neg ? nan() : $_[0]->copy;
}

sub bfac {
    $_[0]->is_neg ? $_[0]->bnan : $_[0];
}

sub dfac {
    $_[0]->is_neg ? nan() : $_[0]->copy;
}

sub primorial {
    $_[0]->is_neg ? nan() : $_[0]->copy;
}

sub fib {
    $_[0]->is_neg ? nan() : $_[0]->copy;
}

sub lucas {
    $_[0]->is_neg ? nan() : $_[0]->copy;
}

sub divmod { (nan(), nan()) }

sub as_frac {
    $_[0]->is_pos ? 'Inf/1' : '-Inf/1';
}

*numerator   = \&copy;
*denominator = \&one;

sub parts {
    ($_[0]->copy, one());
}

sub as_bin { $_[0]->is_pos ? 'Inf' : '-Inf' }

*as_oct   = \&as_bin;
*as_hex   = \&as_bin;
*in_base  = \&as_bin;
*as_float = \&as_bin;
*as_int   = \&as_bin;
*as_rat   = \&as_bin;

sub digits { () }
sub length { 0 }

sub seed { }
*iseed = \&seed;

1;
