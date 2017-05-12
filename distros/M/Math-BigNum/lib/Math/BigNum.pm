package Math::BigNum;

use 5.014;
use strict;
use warnings;

no warnings 'numeric';

use Math::GMPq qw();
use Math::GMPz qw();
use Math::MPFR qw();

use Class::Multimethods qw();
use POSIX qw(ULONG_MAX LONG_MIN);

our $VERSION = '0.20';

=encoding utf8

=head1 NAME

Math::BigNum - Arbitrary size precision for integers, rationals and floating-point numbers.

=head1 VERSION

Version 0.20

=head1 SYNOPSIS

    use 5.014;
    use Math::BigNum qw(:constant);

    # Big numbers
    say ((100->fac + 1) / 2);
      # => 466631077219720763408496194281333502453579841321908107 \
      #    342964819476087999966149578044707319880782591431268489 \
      #    60413611879125592605458432000000000000000000000000.5

    # Small numbers
    say sqrt(1 / 100->fac);     # => 1.03513781117562647132049[...]e-79

    # Rational numbers
    my $x = 2/3;
    say $x*3;                   # => 2
    say 2/$x;                   # => 3
    say $x->as_frac;            # => "2/3"

    # Floating-point numbers
    say "equal" if (1.1 + 2.2 == 3.3);     # => "equal"

=head1 DESCRIPTION

Math::BigNum provides a transparent interface to Math::GMPz, Math::GMPq and Math::MPFR, focusing
on performance and easy-to-use. In most cases, it can be used as a drop-in replacement for the
L<bignum> and L<bigrat> pragmas.

=head1 MOTIVATION

This module came into existence as a response to Dana Jacobsen's request for a transparent
interface to L<Math::GMPz> and L<Math::MPFR>, which he talked about at the YAPC NA, in 2015.

See his great presentation at: L<https://www.youtube.com/watch?v=Dhl4_Chvm_g>.

The main aim of this module is to provide a fast and correct alternative to L<Math::BigInt>,
L<Maht::BigFloat> and L<Math::BigRat>, as well as to L<bigint>, L<bignum> and L<bigrat> pragmas.

=head1 HOW IT WORKS

Math::BigNum tries really hard to do the right thing and as efficiently as possible.
For example, when computing C<pow(x, y)>, it first checks to see if C<x> and C<y> are integers,
so it can optimize the operation to integer exponentiation, by calling the corresponding
I<mpz> function. When only C<y> is an integer, it does rational exponentiation based on the
identity: I<(a/b)^n = a^n / b^n>. Otherwise, it will fallback to floating-point exponentiation,
using the corresponding I<mpfr> function.

All numbers in Math::BigNum are stored as rational L<Math::GMPq> objects. Each operation,
outside the functions provided by L<Math::GMPq>, is done by converting the internal objects to
L<Math::GMPz> or L<Math::MPFR> objects and calling the corresponding functions, converting
the results back to L<Math::GMPq> objects, without loosing any precision in the process.

=head1 IMPORT / EXPORT

Math::BigNum does not export anything by default, but it recognizes the followings:

    :constant       # will make any number a Math::BigNum object
                    # it will also export the "Inf" and "NaN" constants,
                    # which represent +Infinity and NaN special values

    :all            # export everything that is exportable
    PREC n          # set the global precision to the value of `n`

B<Numerical constants:>

    e               # "e" constant (2.7182...)
    pi              # "pi" constant (3.1415...)
    tau             # "tau" constant (which is: 2*pi)
    phi             # Golden ratio constant (1.618...)
    G               # Catalan's constant (0.91596...)
    Y               # Euler-Mascheroni constant (0.57721...)
    Inf             # +Infinity constant
    NaN             # Not-a-Number constant

B<Special functions:>

    factorial(n)       # product of first n integers: n!
    primorial(n)       # product of primes <= n
    binomial(n,k)      # binomial coefficient
    fibonacci(n)       # nth-Fibonacci number
    lucas(n)           # nth-Lucas number
    ipow(a,k)          # integer exponentiation: a^k

B<NOTE:> this functions are designed and optimized for native Perl integers as input.

The syntax for importing something, is:

    use Math::BigNum qw(:constant pi factorial);
    say cos(2*pi);          # => 1
    say factorial(5);       # => 120

B<NOTE:> C<:constant> is lexical to the current scope only.

The syntax for disabling the C<:constant> behavior in the current scope, is:

    no Math::BigNum;        # :constant will be disabled in the current scope

=head1 PRECISION

The default precision for floating-point numbers is 200 bits, which is equivalent with about
50 digits of precision in base 10.

The precision can be changed by modifying the C<$Math::BigNum::PREC> variable, such as:

    local $Math::BigNum::PREC = 1024;

or by specifying the precision at import (this sets the precision globally):

    use Math::BigNum PREC => 1024;

However, an important thing to take into account, unlike the L<Math::MPFR> objects, Math::BigNum
objects do not have a fixed precision stored inside. Rather, they can grow or shrink dynamically,
regardless of the global precision.

The global precision controls only the precision of the floating-point functions and the
stringification of floating-point numbers.

For example, if we change the precision to 3 decimal digits (where C<4> is the conversion factor),
we get the following results:

    local $Math::BigNum::PREC = 3*4;
    say sqrt(2);                   # => 1.414
    say 98**7;                     # => 86812553324672
    say 1 / 98**7                  # => 1.15e-14

As shown above, integers do not obey the global precision, because they can grow or shrink
dynamically, without a specific limit. This is true for rational numbers as well.

A rational number never losses precision in rational operations, therefore if we say:

    my $x = 1 / 3;
    say $x * 3;                    # => 1
    say 1 / $x;                    # => 3
    say 3 / $x;                    # => 9

...the results are 100% exact.

=head1 NOTATIONS

Methods that begin with a B<b> followed by the actual name (e.g.: C<bsqrt>), are mutable
methods that change the self object in-place, while their counter-parts (e.g.: C<sqrt>)
do not. Instead, they will create and return a new object.

In addition, Math::BigNum features another kind of methods that begin with an B<i> followed by
the actual name (e.g.: C<isqrt>). This methods do integer operations, by first
truncating their arguments to integers, whenever needed.

Lastly, Math::BigNum implements another kind of methods that begin with an B<f> followed by the actual name (e.g.: C<fdiv>).
This methods do floating-point operations and are usually faster than their rational counterparts when invoked on very large or very small real-numbers.

The returned types are noted as follows:

    BigNum      # a "Math::BigNum" object
    Inf         # a "Math::BigNum::Inf" object
    Nan         # a "Math::BigNum::Nan" object
    Scalar      # a Perl number or string
    Bool        # true or false (actually: 1 or 0)

When two or more types are separated with pipe characters (B<|>), it means that the
corresponding function can return any of the specified types.

=head1 PERFORMANCE

The performance varies greatly, but, in most cases, Math::BigNum is between 2x up to 10x
faster than L<Math::BigFloat> with the B<GMP> backend, and about 100x faster than L<Math::BigFloat>
without the B<GMP> backend (to be modest).

Math::BigNum is fast because of the following facts:

=over 4

=item *

minimal overhead in object creation.

=item *

minimal Perl code is executed per operation.

=item *

the B<GMP> and B<MPFR> libraries are extremely efficient.

=back

To achieve the best performance, try to follow this rules:

=over 4

=item *

use the B<b*> methods whenever you can.

=item *

use the B<i*> methods wherever applicable.

=item *

use the B<f*> methods when accuracy is not important.

=item *

pass Perl numbers as arguments to methods, if you can.

=item *

avoid the stringification of non-integer Math::BigNum objects.

=item *

don't use B<copy> followed by a B<b*> method! Just leave out the B<b>.

=back

=cut

our ($ROUND, $PREC);

BEGIN {
    $ROUND = Math::MPFR::MPFR_RNDN();
    $PREC  = 200;                       # too little?
}

use Math::BigNum::Inf qw();
use Math::BigNum::Nan qw();

state $MONE = do {
    my $r = Math::GMPq::Rmpq_init_nobless();
    Math::GMPq::Rmpq_set_si($r, -1, 1);
    $r;
};

state $ZERO = do {
    my $r = Math::GMPq::Rmpq_init_nobless();
    Math::GMPq::Rmpq_set_ui($r, 0, 1);
    $r;
};

state $ONE = do {
    my $r = Math::GMPq::Rmpq_init_nobless();
    Math::GMPq::Rmpq_set_ui($r, 1, 1);
    $r;
};

state $ONE_Z = Math::GMPz::Rmpz_init_set_ui_nobless(1);

use overload
  '""' => \&stringify,
  '0+' => \&numify,
  bool => \&boolify,

  '=' => \&copy,

  # Some shortcuts for speed
  '+='  => sub { $_[0]->badd($_[1]) },
  '-='  => sub { $_[0]->bsub($_[1]) },
  '*='  => sub { $_[0]->bmul($_[1]) },
  '/='  => sub { $_[0]->bdiv($_[1]) },
  '%='  => sub { $_[0]->bmod($_[1]) },
  '**=' => sub { $_[0]->bpow($_[1]) },

  '^='  => sub { $_[0]->bxor($_[1]) },
  '&='  => sub { $_[0]->band($_[1]) },
  '|='  => sub { $_[0]->bior($_[1]) },
  '<<=' => sub { $_[0]->blsft($_[1]) },
  '>>=' => sub { $_[0]->brsft($_[1]) },

  '+' => sub { $_[0]->add($_[1]) },
  '*' => sub { $_[0]->mul($_[1]) },

  '==' => sub { $_[0]->eq($_[1]) },
  '!=' => sub { $_[0]->ne($_[1]) },
  '&'  => sub { $_[0]->and($_[1]) },
  '|'  => sub { $_[0]->ior($_[1]) },
  '^'  => sub { $_[0]->xor($_[1]) },
  '~'  => \&not,

  '++' => \&binc,
  '--' => \&bdec,

  '>'   => sub { Math::BigNum::gt($_[2]  ? ($_[1], $_[0]) : ($_[0], $_[1])) },
  '>='  => sub { Math::BigNum::ge($_[2]  ? ($_[1], $_[0]) : ($_[0], $_[1])) },
  '<'   => sub { Math::BigNum::lt($_[2]  ? ($_[1], $_[0]) : ($_[0], $_[1])) },
  '<='  => sub { Math::BigNum::le($_[2]  ? ($_[1], $_[0]) : ($_[0], $_[1])) },
  '<=>' => sub { Math::BigNum::cmp($_[2] ? ($_[1], $_[0]) : ($_[0], $_[1])) },

  '>>' => sub { Math::BigNum::rsft($_[2] ? ($_[1], $_[0]) : ($_[0], $_[1])) },
  '<<' => sub { Math::BigNum::lsft($_[2] ? ($_[1], $_[0]) : ($_[0], $_[1])) },

  '**' => sub { Math::BigNum::pow($_[2] ? ($_[1], $_[0]) : ($_[0], $_[1])) },
  '-'  => sub { Math::BigNum::sub($_[2] ? ($_[1], $_[0]) : ($_[0], $_[1])) },
  '/'  => sub { Math::BigNum::div($_[2] ? ($_[1], $_[0]) : ($_[0], $_[1])) },
  '%'  => sub { Math::BigNum::mod($_[2] ? ($_[1], $_[0]) : ($_[0], $_[1])) },

  atan2 => sub { Math::BigNum::atan2($_[2] ? ($_[1], $_[0]) : ($_[0], $_[1])) },

  eq => sub { "$_[0]" eq "$_[1]" },
  ne => sub { "$_[0]" ne "$_[1]" },

  cmp => sub { $_[2] ? "$_[1]" cmp $_[0]->stringify : $_[0]->stringify cmp "$_[1]" },

  neg  => \&neg,
  sin  => \&sin,
  cos  => \&cos,
  exp  => \&exp,
  log  => \&ln,
  int  => \&int,
  abs  => \&abs,
  sqrt => \&sqrt;

{
    my $binomial = sub {
        my ($n, $k) = @_;

        (defined($n) and defined($k)) or return nan();
        ref($n) eq __PACKAGE__ and return $n->binomial($k);

        (CORE::int($k) eq $k and $k >= LONG_MIN and $k <= ULONG_MAX)
          || return Math::BigNum->new($n)->binomial(Math::BigNum->new($k));

        my $n_ui = (CORE::int($n) eq $n and $n >= 0 and $n <= ULONG_MAX);
        my $k_ui = $k >= 0;

        my $z = Math::GMPz::Rmpz_init();

        if ($n_ui and $k_ui) {
            Math::GMPz::Rmpz_bin_uiui($z, $n, $k);
        }
        else {
            eval { Math::GMPz::Rmpz_set_str($z, "$n", 10); 1 } // return Math::BigNum->new($n)->binomial($k);
            $k_ui
              ? Math::GMPz::Rmpz_bin_ui($z, $z, $k)
              : Math::GMPz::Rmpz_bin_si($z, $z, $k);
        }

        _mpz2big($z);
    };

    my $factorial = sub {
        my ($n) = @_;
        $n // return nan();
        ref($n) eq __PACKAGE__ and return $n->fac;
        if (CORE::int($n) eq $n and $n >= 0 and $n <= ULONG_MAX) {
            my $z = Math::GMPz::Rmpz_init();
            Math::GMPz::Rmpz_fac_ui($z, $n);
            _mpz2big($z);
        }
        else {
            Math::BigNum->new($n)->fac;
        }
    };

    my $primorial = sub {
        my ($n) = @_;
        $n // return nan();
        ref($n) eq __PACKAGE__ and return $n->primorial;
        if (CORE::int($n) eq $n and $n >= 0 and $n <= ULONG_MAX) {
            my $z = Math::GMPz::Rmpz_init();
            Math::GMPz::Rmpz_primorial_ui($z, $n);
            _mpz2big($z);
        }
        else {
            Math::BigNum->new($n)->primorial;
        }
    };

    my $fibonacci = sub {
        my ($n) = @_;
        $n // return nan();
        ref($n) eq __PACKAGE__ and return $n->fib;
        if (CORE::int($n) eq $n and $n >= 0 and $n <= ULONG_MAX) {
            my $z = Math::GMPz::Rmpz_init();
            Math::GMPz::Rmpz_fib_ui($z, $n);
            _mpz2big($z);
        }
        else {
            Math::BigNum->new($n)->fib;
        }
    };

    my $lucas = sub {
        my ($n) = @_;
        $n // return nan();
        ref($n) eq __PACKAGE__ and return $n->lucas;
        if (CORE::int($n) eq $n and $n >= 0 and $n <= ULONG_MAX) {
            my $z = Math::GMPz::Rmpz_init();
            Math::GMPz::Rmpz_lucnum_ui($z, $n);
            _mpz2big($z);
        }
        else {
            Math::BigNum->new($n)->lucas;
        }
    };

    my $ipow = sub {
        my ($n, $k) = @_;

        (defined($n) and defined($k)) or return nan();
        ref($n) eq __PACKAGE__ and return $n->ipow($k);

        (CORE::int($n) eq $n and CORE::int($k) eq $k and $n <= ULONG_MAX and $k <= ULONG_MAX and $n >= LONG_MIN and $k >= 0)
          || return Math::BigNum->new($n)->ipow($k);

        my $z = Math::GMPz::Rmpz_init();
        Math::GMPz::Rmpz_ui_pow_ui($z, CORE::abs($n), $k);
        Math::GMPz::Rmpz_neg($z, $z) if ($n < 0 and $k % 2);
        _mpz2big($z);
    };

    my %constants = (
                     e   => \&e,
                     phi => \&phi,
                     tau => \&tau,
                     pi  => \&pi,
                     Y   => \&Y,
                     G   => \&G,
                     Inf => \&inf,
                     NaN => \&nan,
                    );

    my %functions = (
                     binomial  => $binomial,
                     factorial => $factorial,
                     primorial => $primorial,
                     fibonacci => $fibonacci,
                     lucas     => $lucas,
                     ipow      => $ipow,
                    );

    sub import {
        shift;

        my $caller = caller(0);

        while (@_) {
            my $name = shift(@_);

            if ($name eq ':constant') {
                overload::constant
                  integer => sub { Math::BigNum->new_uint($_[0]) },
                  float   => sub { Math::BigNum->new($_[0], 10) },
                  binary => sub {
                    my ($const) = @_;
                    my $prefix = substr($const, 0, 2);
                        $prefix eq '0x' ? Math::BigNum->new(substr($const, 2), 16)
                      : $prefix eq '0b' ? Math::BigNum->new(substr($const, 2), 2)
                      :                   Math::BigNum->new(substr($const, 1), 8);
                  },
                  ;

                # Export 'Inf' and 'NaN' as constants
                no strict 'refs';

                my $inf_sub = $caller . '::' . 'Inf';
                if (!defined &$inf_sub) {
                    my $inf = inf();
                    *$inf_sub = sub () { $inf };
                }

                my $nan_sub = $caller . '::' . 'NaN';
                if (!defined &$nan_sub) {
                    my $nan = nan();
                    *$nan_sub = sub () { $nan };
                }
            }
            elsif (exists $constants{$name}) {
                no strict 'refs';
                my $caller_sub = $caller . '::' . $name;
                if (!defined &$caller_sub) {
                    my $sub   = $constants{$name};
                    my $value = Math::BigNum->$sub;
                    *$caller_sub = sub() { $value }
                }
            }
            elsif (exists $functions{$name}) {
                no strict 'refs';
                my $caller_sub = $caller . '::' . $name;
                if (!defined &$caller_sub) {
                    *$caller_sub = $functions{$name};
                }
            }
            elsif ($name eq ':all') {
                push @_, keys(%constants), keys(%functions);
            }
            elsif ($name eq 'PREC') {
                my $prec = CORE::int(shift(@_));
                if (   $prec < Math::MPFR::RMPFR_PREC_MIN()
                    or $prec > Math::MPFR::RMPFR_PREC_MAX()) {
                    die "invalid value for <<PREC>>: must be between "
                      . Math::MPFR::RMPFR_PREC_MIN() . " and "
                      . Math::MPFR::RMPFR_PREC_MAX();
                }
                $Math::BigNum::PREC = $prec;
            }
            else {
                die "unknown import: <<$name>>";
            }
        }
        return;
    }

    sub unimport {
        overload::remove_constant('binary', '', 'float', '', 'integer');
    }
}

# Converts a string representing a floating-point number into a rational representation
# Example: "1.234" is converted into "1234/1000"
# TODO: find a better solution (maybe)
# This solution is very slow for literals with absolute big exponents, such as: "1e-10000000"
sub _str2rat {
    my $str = lc($_[0] || "0");

    my $sign = substr($str, 0, 1);
    if ($sign eq '-') {
        substr($str, 0, 1, '');
        $sign = '-';
    }
    else {
        substr($str, 0, 1, '') if ($sign eq '+');
        $sign = '';
    }

    my $i;
    if (($i = index($str, 'e')) != -1) {

        my $exp = substr($str, $i + 1);

        # Handle specially numbers with very big exponents
        # (it's not a very good solution, but I hope it's only temporarily)
        if (CORE::abs($exp) >= 1000000) {
            my $mpfr = Math::MPFR::Rmpfr_init2($PREC);
            Math::MPFR::Rmpfr_set_str($mpfr, "$sign$str", 10, $ROUND);
            my $mpq = Math::GMPq::Rmpq_init();
            Math::MPFR::Rmpfr_get_q($mpq, $mpfr);
            return Math::GMPq::Rmpq_get_str($mpq, 10);
        }

        my ($before, $after) = split(/\./, substr($str, 0, $i));

        if (!defined($after)) {    # return faster for numbers like "13e2"
            if ($exp >= 0) {
                return ("$sign$before" . ('0' x $exp));
            }
            else {
                $after = '';
            }
        }

        my $numerator   = "$before$after";
        my $denominator = "1";

        if ($exp < 1) {
            $denominator .= '0' x (CORE::abs($exp) + CORE::length($after));
        }
        else {
            my $diff = ($exp - CORE::length($after));
            if ($diff >= 0) {
                $numerator .= '0' x $diff;
            }
            else {
                my $s = "$before$after";
                substr($s, $exp + CORE::length($before), 0, '.');
                return _str2rat("$sign$s");
            }
        }

        "$sign$numerator/$denominator";
    }
    elsif (($i = index($str, '.')) != -1) {
        my ($before, $after) = (substr($str, 0, $i), substr($str, $i + 1));
        if ($after =~ tr/0// == CORE::length($after)) {
            return "$sign$before";
        }
        $sign . ("$before$after/1" =~ s/^0+//r) . ('0' x CORE::length($after));
    }
    else {
        "$sign$str";
    }
}

# Converts a string into an mpfr object
sub _str2mpfr {
    my $r = Math::MPFR::Rmpfr_init2($PREC);

    if (CORE::int($_[0]) eq $_[0] and $_[0] >= LONG_MIN and $_[0] <= ULONG_MAX) {
        $_[0] >= 0
          ? Math::MPFR::Rmpfr_set_ui($r, $_[0], $ROUND)
          : Math::MPFR::Rmpfr_set_si($r, $_[0], $ROUND);
    }
    else {
        Math::MPFR::Rmpfr_set_str($r, $_[0], 10, $ROUND) && return;
    }

    $r;
}

# Converts a string into an mpq object
sub _str2mpq {
    my $r = Math::GMPq::Rmpq_init();

    $_[0] || do {
        Math::GMPq::Rmpq_set($r, $ZERO);
        return $r;
    };

    # Performance improvement for Perl integers
    if (CORE::int($_[0]) eq $_[0] and $_[0] >= LONG_MIN and $_[0] <= ULONG_MAX) {
        if ($_[0] >= 0) {
            Math::GMPq::Rmpq_set_ui($r, $_[0], 1);
        }
        else {
            Math::GMPq::Rmpq_set_si($r, $_[0], 1);
        }
    }

    # Otherwise, it's a string or a float (this is slightly slower)
    else {
        my $rat = $_[0] =~ tr/.Ee// ? _str2rat($_[0] =~ tr/_//dr) : ($_[0] =~ tr/_+//dr);
        if ($rat !~ m{^\s*[-+]?[0-9]+(?>\s*/\s*[-+]?[1-9]+[0-9]*)?\s*\z}) {
            return;
        }
        Math::GMPq::Rmpq_set_str($r, $rat, 10);
        Math::GMPq::Rmpq_canonicalize($r) if (index($rat, '/') != -1);
    }

    $r;
}

# Converts a string into an mpz object
sub _str2mpz {
    (CORE::int($_[0]) eq $_[0] and $_[0] <= ULONG_MAX and $_[0] >= LONG_MIN)
      ? (
         ($_[0] >= 0)
         ? Math::GMPz::Rmpz_init_set_ui($_[0])
         : Math::GMPz::Rmpz_init_set_si($_[0])
        )
      : eval { Math::GMPz::Rmpz_init_set_str($_[0], 10) };
}

# Converts a BigNum object to mpfr
sub _big2mpfr {

    $PREC = CORE::int($PREC) if ref($PREC);

    my $r = Math::MPFR::Rmpfr_init2($PREC);
    Math::MPFR::Rmpfr_set_q($r, ${$_[0]}, $ROUND);
    $r;
}

# Converts a BigNum object to mpz
sub _big2mpz {
    my $z = Math::GMPz::Rmpz_init();
    Math::GMPz::Rmpz_set_q($z, ${$_[0]});
    $z;
}

# Converts an integer BigNum object to mpz
sub _int2mpz {
    my $z = Math::GMPz::Rmpz_init();
    Math::GMPq::Rmpq_numref($z, ${$_[0]});
    $z;
}

# Converts an mpfr object to BigNum
sub _mpfr2big {

    if (!Math::MPFR::Rmpfr_number_p($_[0])) {

        if (Math::MPFR::Rmpfr_inf_p($_[0])) {
            if (Math::MPFR::Rmpfr_sgn($_[0]) > 0) {
                return inf();
            }
            else {
                return ninf();
            }
        }

        if (Math::MPFR::Rmpfr_nan_p($_[0])) {
            return nan();
        }
    }

    my $r = Math::GMPq::Rmpq_init();
    Math::MPFR::Rmpfr_get_q($r, $_[0]);
    bless \$r, __PACKAGE__;
}

# Converts an mpfr object to mpq and puts it in $x
sub _mpfr2x {

    if (!Math::MPFR::Rmpfr_number_p($_[1])) {

        if (Math::MPFR::Rmpfr_inf_p($_[1])) {
            if (Math::MPFR::Rmpfr_sgn($_[1]) > 0) {
                return $_[0]->binf;
            }
            else {
                return $_[0]->bninf;
            }
        }

        if (Math::MPFR::Rmpfr_nan_p($_[1])) {
            return $_[0]->bnan;
        }
    }

    Math::MPFR::Rmpfr_get_q(${$_[0]}, $_[1]);
    $_[0];
}

# Converts an mpz object to BigNum
sub _mpz2big {
    my $r = Math::GMPq::Rmpq_init();
    Math::GMPq::Rmpq_set_z($r, $_[0]);
    bless \$r, __PACKAGE__;
}

*_big2inf  = \&Math::BigNum::Inf::_big2inf;
*_big2ninf = \&Math::BigNum::Inf::_big2ninf;

#*_big2cplx = \&Math::BigNum::Complex::_big2cplx;

=head1 INITIALIZATION / CONSTANTS

This section includes methods for creating new B<Math::BigNum> objects
and some useful mathematical constants.

=cut

=head2 new

    BigNum->new(Scalar)            # => BigNum
    BigNum->new(Scalar, Scalar)    # => BigNum

Returns a new BigNum object with the value specified in the first argument,
which can be a Perl numerical value, a string representing a number in a
rational form, such as C<"1/2">, a string holding a floating-point number,
such as C<"0.5">, or a string holding an integer, such as C<"255">.

The second argument specifies the base of the number, which can range from 2
to 36 inclusive and defaults to 10.

For setting an hexadecimal number, we can say:

    my $x = Math::BigNum->new("deadbeef", 16);

B<NOTE:> no prefix, such as C<"0x"> or C<"0b">, is allowed as part of the number.

=cut

sub new {
    my ($class, $num, $base) = @_;

    my $ref = ref($num);

    # Be forgetful about undefined values or empty strings
    if ($ref eq '' and !$num) {
        return zero();
    }

    # Special string values
    elsif (!defined($base) and $ref eq '') {
        my $lc = lc($num);
        if ($lc eq 'inf' or $lc eq '+inf') {
            return inf();
        }
        elsif ($lc eq '-inf') {
            return ninf();
        }
        elsif ($lc eq 'nan') {
            return nan();
        }
    }

    # Special objects
    elsif (   $ref eq 'Math::BigNum'
           or $ref eq 'Math::BigNum::Inf'
           or $ref eq 'Math::BigNum::Nan') {
        return $num->copy;
    }

    # Special values as Big{Int,Float,Rat}
    elsif (   $ref eq 'Math::BigInt'
           or $ref eq 'Math::BigFloat'
           or $ref eq 'Math::BigRat') {
        if ($num->is_nan) {
            return nan();
        }
        elsif ($num->is_inf('-')) {
            return ninf();
        }
        elsif ($num->is_inf('+')) {
            return inf();
        }
    }

    # GMPz
    elsif ($ref eq 'Math::GMPz') {
        return _mpz2big($num);
    }

    # MPFR
    elsif ($ref eq 'Math::MPFR') {
        return _mpfr2big($num);
    }

    # Plain scalar
    if ($ref eq '' and (!defined($base) or $base == 10)) {    # it's a base 10 scalar
        return bless \(_str2mpq($num) // return nan()), $class;    # so we can return faster
    }

    # Create a new GMPq object
    my $r = Math::GMPq::Rmpq_init();

    # BigInt
    if ($ref eq 'Math::BigInt') {
        Math::GMPq::Rmpq_set_str($r, $num->bstr, 10);
    }

    # BigFloat
    elsif ($ref eq 'Math::BigFloat') {
        my $rat = _str2rat($num->bstr);
        Math::GMPq::Rmpq_set_str($r, $rat, 10);
        Math::GMPq::Rmpq_canonicalize($r) if (index($rat, '/') != -1);
    }

    # BigRat
    elsif ($ref eq 'Math::BigRat') {
        Math::GMPq::Rmpq_set_str($r, $num->bstr, 10);
    }

    # GMPq
    elsif ($ref eq 'Math::GMPq') {
        Math::GMPq::Rmpq_set($r, $num);
    }

    # Number with base
    elsif (defined($base) and $ref eq '') {

        if ($base < 2 or $base > 36) {
            require Carp;
            Carp::croak("base must be between 2 and 36, got $base");
        }

        Math::GMPq::Rmpq_set_str($r, $num, $base);
        Math::GMPq::Rmpq_canonicalize($r) if (index($num, '/') != -1);
    }

    # Other reference (which may support stringification)
    else {
        Math::GMPq::Rmpq_set($r, _str2mpq("$num") // return nan());
    }

    # Return a blessed BigNum object
    bless \$r, $class;
}

=head2 new_int

    BigNum->new_int(Scalar)        # => BigNum

A faster version of the method C<new()> for setting a I<signed> native integer.

Example:

    my $x = Math::BigNum->new_int(-42);

=cut

sub new_int {
    my $r = Math::GMPq::Rmpq_init();
    Math::GMPq::Rmpq_set_si($r, $_[1], 1);
    bless \$r, __PACKAGE__;
}

=head2 new_uint

    BigNum->new_uint(Scalar)       # => BigNum

A faster version of the method C<new()> for setting an I<unsigned> native integer.

Example:

    my $x = Math::BigNum->new_uint(42);

=cut

sub new_uint {
    my $r = Math::GMPq::Rmpq_init();
    Math::GMPq::Rmpq_set_ui($r, $_[1], 1);
    bless \$r, __PACKAGE__;
}

#
## Constants
#

=head2 nan

    BigNum->nan                    # => Nan

Returns a new Nan object.

=cut

BEGIN { *nan = \&Math::BigNum::Nan::nan }

=head2 inf

    BigNum->inf                    # => Inf

Returns a new Inf object to represent positive Infinity.

=cut

BEGIN { *inf = \&Math::BigNum::Inf::inf }

=head2 ninf

    BigNum->ninf                   # => -Inf

Returns an Inf object to represent negative Infinity.

=cut

BEGIN { *ninf = \&Math::BigNum::Inf::ninf }

=head2 one

    BigNum->one                    # => BigNum

Returns a BigNum object containing the value C<1>.

=cut

sub one {
    my $r = Math::GMPq::Rmpq_init();
    Math::GMPq::Rmpq_set($r, $ONE);
    bless \$r, __PACKAGE__;
}

=head2 zero

    BigNum->zero                   # => BigNum

Returns a BigNum object containing the value C<0>.

=cut

sub zero {
    my $r = Math::GMPq::Rmpq_init();
    Math::GMPq::Rmpq_set($r, $ZERO);
    bless \$r, __PACKAGE__;
}

=head2 mone

    BigNum->mone                   # => BigNum

Returns a BigNum object containing the value C<-1>.

=cut

sub mone {
    my $r = Math::GMPq::Rmpq_init();
    Math::GMPq::Rmpq_set($r, $MONE);
    bless \$r, __PACKAGE__;
}

=head2 bzero

    $x->bzero                      # => BigNum

Changes C<x> in-place to hold the value 0.

=cut

sub bzero {
    my ($x) = @_;
    Math::GMPq::Rmpq_set($$x, $ZERO);
    if (ref($x) ne __PACKAGE__) {
        bless $x, __PACKAGE__;
    }
    $x;
}

=head2 bone

    $x->bone                       # => BigNum

Changes C<x> in-place to hold the value +1.

=cut

sub bone {
    my ($x) = @_;
    Math::GMPq::Rmpq_set($$x, $ONE);
    if (ref($x) ne __PACKAGE__) {
        bless $x, __PACKAGE__;
    }
    $x;
}

=head2 bmone

    $x->bmone                      # => BigNum

Changes C<x> in-place to hold the value -1.

=cut

sub bmone {
    my ($x) = @_;
    Math::GMPq::Rmpq_set($$x, $MONE);
    if (ref($x) ne __PACKAGE__) {
        bless $x, __PACKAGE__;
    }
    $x;
}

=head2 binf

    $x->binf                       # => Inf

Changes C<x> in-place to positive Infinity.

=cut

*binf = \&Math::BigNum::Inf::binf;

=head2 bninf

    $x->bninf                      # => -Inf

Changes C<x> in-place to negative Infinity.

=cut

*bninf = \&Math::BigNum::Inf::bninf;

=head2 bnan

    $x->bnan                       # => Nan

Changes C<x> in-place to the special Not-a-Number value.

=cut

*bnan = \&Math::BigNum::Nan::bnan;

=head2 pi

    BigNum->pi                     # => BigNum

Returns the number PI, which is C<3.1415...>.

=cut

sub pi {
    my $pi = Math::MPFR::Rmpfr_init2($PREC);
    Math::MPFR::Rmpfr_const_pi($pi, $ROUND);
    _mpfr2big($pi);
}

=head2 tau

    BigNum->tau                    # => BigNum

Returns the number TAU, which is C<2*PI>.

=cut

sub tau {
    my $tau = Math::MPFR::Rmpfr_init2($PREC);
    Math::MPFR::Rmpfr_const_pi($tau, $ROUND);
    Math::MPFR::Rmpfr_mul_ui($tau, $tau, 2, $ROUND);
    _mpfr2big($tau);
}

=head2 ln2

    BigNum->ln2                    # => BigNum

Returns the natural logarithm of C<2>.

=cut

sub ln2 {
    my $ln2 = Math::MPFR::Rmpfr_init2($PREC);
    Math::MPFR::Rmpfr_const_log2($ln2, $ROUND);
    _mpfr2big($ln2);
}

=head2 Y

    BigNum->Y                      # => BigNum

Returns the Euler-Mascheroni constant, which is C<0.57721...>.

=cut

sub Y {
    my $euler = Math::MPFR::Rmpfr_init2($PREC);
    Math::MPFR::Rmpfr_const_euler($euler, $ROUND);
    _mpfr2big($euler);
}

=head2 G

    BigNum->G                      # => BigNum

Returns the value of Catalan's constant, also known
as Beta(2) or G, and starts as: C<0.91596...>.

=cut

sub G {
    my $catalan = Math::MPFR::Rmpfr_init2($PREC);
    Math::MPFR::Rmpfr_const_catalan($catalan, $ROUND);
    _mpfr2big($catalan);
}

=head2 e

    BigNum->e                      # => BigNum

Returns the e mathematical constant, which is C<2.718...>.

=cut

sub e {
    state $one_f = (Math::MPFR::Rmpfr_init_set_ui_nobless(1, $ROUND))[0];
    my $e = Math::MPFR::Rmpfr_init2($PREC);
    Math::MPFR::Rmpfr_exp($e, $one_f, $ROUND);
    _mpfr2big($e);
}

=head2 phi

    BigNum->phi                    # => BigNum

Returns the value of the golden ratio, which is C<1.61803...>.

=cut

sub phi {
    state $five4_f = (Math::MPFR::Rmpfr_init_set_str_nobless("1.25", 10, $ROUND))[0];
    state $half_f  = (Math::MPFR::Rmpfr_init_set_str_nobless("0.5",  10, $ROUND))[0];

    my $phi = Math::MPFR::Rmpfr_init2($PREC);
    Math::MPFR::Rmpfr_sqrt($phi, $five4_f, $ROUND);
    Math::MPFR::Rmpfr_add($phi, $phi, $half_f, $ROUND);

    _mpfr2big($phi);
}

############################ RATIONAL OPERATIONS ############################

=head1 RATIONAL OPERATIONS

All operations in this section are done rationally, which means that the
returned results are 100% exact (unless otherwise stated in some special cases).

=cut

=head2 add

    $x->add(BigNum)                # => BigNum
    $x->add(Scalar)                # => BigNum

    BigNum + BigNum                # => BigNum
    BigNum + Scalar                # => BigNum
    Scalar + BigNum                # => BigNum

Adds C<y> to C<x> and returns the result.

=cut

Class::Multimethods::multimethod add => qw(Math::BigNum Math::BigNum) => sub {
    my ($x, $y) = @_;
    my $r = Math::GMPq::Rmpq_init();
    Math::GMPq::Rmpq_add($r, $$x, $$y);
    bless \$r, __PACKAGE__;
};

Class::Multimethods::multimethod add => qw(Math::BigNum $) => sub {
    my ($x, $y) = @_;
    my $r = _str2mpq($y) // return Math::BigNum->new($y)->badd($x);
    Math::GMPq::Rmpq_add($r, $r, $$x);
    bless \$r, __PACKAGE__;
};

=for comment
Class::Multimethods::multimethod add => qw(Math::BigNum Math::BigNum::Complex) => sub {
    Math::BigNum::Complex->new($_[0])->add($_[1]);
};
=cut

Class::Multimethods::multimethod add => qw(Math::BigNum *) => sub {
    Math::BigNum->new($_[1])->badd($_[0]);
};

Class::Multimethods::multimethod add => qw(Math::BigNum Math::BigNum::Inf) => sub { $_[1]->copy };
Class::Multimethods::multimethod add => qw(Math::BigNum Math::BigNum::Nan) => \&nan;

=head2 badd

    $x->badd(BigNum)               # => BigNum
    $x->badd(Scalar)               # => BigNum

    BigNum += BigNum               # => BigNum
    BigNum += Scalar               # => BigNum

Adds C<y> to C<x>, changing C<x> in-place.

=cut

Class::Multimethods::multimethod badd => qw(Math::BigNum Math::BigNum) => sub {
    my ($x, $y) = @_;
    Math::GMPq::Rmpq_add($$x, $$x, $$y);
    $x;
};

Class::Multimethods::multimethod badd => qw(Math::BigNum $) => sub {
    my ($x, $y) = @_;
    Math::GMPq::Rmpq_add($$x, $$x, _str2mpq($y) // return $x->badd(Math::BigNum->new($y)));
    $x;
};

Class::Multimethods::multimethod badd => qw(Math::BigNum *) => sub {
    $_[0]->badd(Math::BigNum->new($_[1]));
};

Class::Multimethods::multimethod badd => qw(Math::BigNum Math::BigNum::Inf) => \&_big2inf;
Class::Multimethods::multimethod badd => qw(Math::BigNum Math::BigNum::Nan) => \&bnan;

=head2 sub

    $x->sub(BigNum)                # => BigNum
    $x->sub(Scalar)                # => BigNum

    BigNum - BigNum                # => BigNum
    BigNum - Scalar                # => BigNum
    Scalar - BigNum                # => BigNum

Subtracts C<y> from C<x> and returns the result.

=cut

Class::Multimethods::multimethod sub => qw(Math::BigNum Math::BigNum) => sub {
    my ($x, $y) = @_;
    my $r = Math::GMPq::Rmpq_init();
    Math::GMPq::Rmpq_sub($r, $$x, $$y);
    bless \$r, __PACKAGE__;
};

Class::Multimethods::multimethod sub => qw(Math::BigNum $) => sub {
    my ($x, $y) = @_;
    my $r = _str2mpq($y) // return Math::BigNum->new($y)->bneg->badd($x);
    Math::GMPq::Rmpq_sub($r, $$x, $r);
    bless \$r, __PACKAGE__;
};

Class::Multimethods::multimethod sub => qw($ Math::BigNum) => sub {
    my ($x, $y) = @_;
    my $r = _str2mpq($x) // return Math::BigNum->new($x)->bsub($y);
    Math::GMPq::Rmpq_sub($r, $r, $$y);
    bless \$r, __PACKAGE__;
};

=for comment
Class::Multimethods::multimethod sub => qw(Math::BigNum Math::BigNum::Complex) => sub {
    Math::BigNum::Complex->new($_[0])->sub($_[1]);
};
=cut

Class::Multimethods::multimethod sub => qw(* Math::BigNum) => sub {
    Math::BigNum->new($_[0])->bsub($_[1]);
};

Class::Multimethods::multimethod sub => qw(Math::BigNum *) => sub {
    Math::BigNum->new($_[1])->bneg->badd($_[0]);
};

Class::Multimethods::multimethod sub => qw(Math::BigNum Math::BigNum::Inf) => sub { $_[1]->neg };
Class::Multimethods::multimethod sub => qw(Math::BigNum Math::BigNum::Nan) => \&nan;

=head2 bsub

    $x->bsub(BigNum)               # => BigNum
    $x->bsub(Scalar)               # => BigNum

    BigNum -= BigNum               # => BigNum
    BigNum -= Scalar               # => BigNum

Subtracts C<y> from C<x> by changing C<x> in-place.

=cut

Class::Multimethods::multimethod bsub => qw(Math::BigNum Math::BigNum) => sub {
    my ($x, $y) = @_;
    Math::GMPq::Rmpq_sub($$x, $$x, $$y);
    $x;
};

Class::Multimethods::multimethod bsub => qw(Math::BigNum $) => sub {
    my ($x, $y) = @_;
    Math::GMPq::Rmpq_sub($$x, $$x, _str2mpq($y) // return $x->bsub(Math::BigNum->new($y)));
    $x;
};

Class::Multimethods::multimethod bsub => qw(Math::BigNum *) => sub {
    $_[0]->bsub(Math::BigNum->new($_[1]));
};

Class::Multimethods::multimethod bsub => qw(Math::BigNum Math::BigNum::Inf) => \&_big2ninf;
Class::Multimethods::multimethod bsub => qw(Math::BigNum Math::BigNum::Nan) => \&bnan;

=head2 mul

    $x->mul(BigNum)                # => BigNum
    $x->mul(Scalar)                # => BigNum

    BigNum * BigNum                # => BigNum
    BigNum * Scalar                # => BigNum
    Scalar * BigNum                # => BigNum

Multiplies C<x> by C<y> and returns the result.

=cut

Class::Multimethods::multimethod mul => qw(Math::BigNum Math::BigNum) => sub {
    my ($x, $y) = @_;
    my $r = Math::GMPq::Rmpq_init();
    Math::GMPq::Rmpq_mul($r, $$x, $$y);
    bless \$r, __PACKAGE__;
};

Class::Multimethods::multimethod mul => qw(Math::BigNum $) => sub {
    my ($x, $y) = @_;
    my $r = _str2mpq($y) // return Math::BigNum->new($y)->bmul($x);
    Math::GMPq::Rmpq_mul($r, $$x, $r);
    bless \$r, __PACKAGE__;
};

=for comment
Class::Multimethods::multimethod mul => qw(Math::BigNum Math::BigNum::Complex) => sub {
    $_[1]->mul($_[0]);
};
=cut

Class::Multimethods::multimethod mul => qw(Math::BigNum *) => sub {
    Math::BigNum->new($_[1])->bmul($_[0]);
};

Class::Multimethods::multimethod mul => qw(Math::BigNum Math::BigNum::Inf) => sub {
    my $sign = Math::GMPq::Rmpq_sgn(${$_[0]});
    $sign < 0 ? $_[1]->neg : $sign > 0 ? $_[1]->copy : nan;
};

Class::Multimethods::multimethod mul => qw(Math::BigNum Math::BigNum::Nan) => \&nan;

=head2 bmul

    $x->bmul(BigNum)               # => BigNum
    $x->bmul(Scalar)               # => BigNum

    BigNum *= BigNum               # => BigNum
    BigNum *= Scalar               # => BigNum

Multiply C<x> by C<y>, changing C<x> in-place.

=cut

Class::Multimethods::multimethod bmul => qw(Math::BigNum Math::BigNum) => sub {
    my ($x, $y) = @_;
    Math::GMPq::Rmpq_mul($$x, $$x, $$y);
    $x;
};

Class::Multimethods::multimethod bmul => qw(Math::BigNum $) => sub {
    my ($x, $y) = @_;
    Math::GMPq::Rmpq_mul($$x, $$x, _str2mpq($y) // return $x->bmul(Math::BigNum->new($y)));
    $x;
};

Class::Multimethods::multimethod bmul => qw(Math::BigNum *) => sub {
    $_[0]->bmul(Math::BigNum->new($_[1]));
};

Class::Multimethods::multimethod bmul => qw(Math::BigNum Math::BigNum::Inf) => sub {
    my ($x) = @_;
    my $sign = Math::GMPq::Rmpq_sgn($$x);

        $sign < 0 ? _big2ninf(@_)
      : $sign > 0 ? _big2inf(@_)
      :             $x->bnan;
};

Class::Multimethods::multimethod bmul => qw(Math::BigNum Math::BigNum::Nan) => \&bnan;

=head2 div

    $x->div(BigNum)                # => BigNum | Inf | Nan
    $x->div(Scalar)                # => BigNum | Inf | Nan

    BigNum / BigNum                # => BigNum | Inf | Nan
    BigNum / Scalar                # => BigNum | Inf | Nan
    Scalar / BigNum                # => BigNum | Inf | Nan

Divides C<x> by C<y> and returns the result. Returns Nan when C<x> and C<y> are 0,
Inf when C<y> is 0 and C<x> is positive, -Inf when C<y> is zero and C<x> is negative.

=cut

Class::Multimethods::multimethod div => qw(Math::BigNum Math::BigNum) => sub {
    my ($x, $y) = @_;

    Math::GMPq::Rmpq_sgn($$y) || do {
        my $sign = Math::GMPq::Rmpq_sgn($$x);
        return (!$sign ? nan : $sign > 0 ? inf : ninf);
    };

    my $r = Math::GMPq::Rmpq_init();
    Math::GMPq::Rmpq_div($r, $$x, $$y);
    bless \$r, __PACKAGE__;
};

Class::Multimethods::multimethod div => qw(Math::BigNum $) => sub {
    my ($x, $y) = @_;

    $y || do {
        my $sign = Math::GMPq::Rmpq_sgn($$x);
        return (!$sign ? nan : $sign > 0 ? inf : ninf);
    };

    my $r = _str2mpq($y) // return $x->div(Math::BigNum->new($y));
    Math::GMPq::Rmpq_div($r, $$x, $r);
    bless \$r, __PACKAGE__;
};

Class::Multimethods::multimethod div => qw($ Math::BigNum) => sub {
    my ($x, $y) = @_;

    Math::GMPq::Rmpq_sgn($$y)
      || return (!$x ? nan : $x > 0 ? inf : ninf);

    my $r = _str2mpq($x) // return Math::BigNum->new($x)->bdiv($y);
    Math::GMPq::Rmpq_div($r, $r, $$y);
    bless \$r, __PACKAGE__;
};

=for comment
Class::Multimethods::multimethod div => qw(Math::BigNum Math::BigNum::Complex) => sub {
    Math::BigNum::Complex->new($_[0])->div($_[1]);
};
=cut

Class::Multimethods::multimethod div => qw(* Math::BigNum) => sub {
    Math::BigNum->new($_[0])->bdiv($_[1]);
};

Class::Multimethods::multimethod div => qw(Math::BigNum *) => sub {
    Math::BigNum->new($_[1])->binv->bmul($_[0]);
};

Class::Multimethods::multimethod div => qw(Math::BigNum Math::BigNum::Inf) => \&zero;
Class::Multimethods::multimethod div => qw(Math::BigNum Math::BigNum::Nan) => \&nan;

=head2 bdiv

    $x->bdiv(BigNum)               # => BigNum | Nan | Inf
    $x->bdiv(Scalar)               # => BigNum | Nan | Inf

    BigNum /= BigNum               # => BigNum | Nan | Inf
    BigNum /= Scalar               # => BigNum | Nan | Inf

Divide C<x> by C<y>, changing C<x> in-place. The return values are the same as for C<div()>.

=cut

Class::Multimethods::multimethod bdiv => qw(Math::BigNum Math::BigNum) => sub {
    my ($x, $y) = @_;

    Math::GMPq::Rmpq_sgn($$y) || do {
        my $sign = Math::GMPq::Rmpq_sgn($$x);
        return
            $sign > 0 ? $x->binf
          : $sign < 0 ? $x->bninf
          :             $x->bnan;
    };

    Math::GMPq::Rmpq_div($$x, $$x, $$y);
    $x;
};

Class::Multimethods::multimethod bdiv => qw(Math::BigNum $) => sub {
    my ($x, $y) = @_;

    $y || do {
        my $sign = Math::GMPq::Rmpq_sgn($$x);
        return
            $sign > 0 ? $x->binf
          : $sign < 0 ? $x->bninf
          :             $x->bnan;
    };

    Math::GMPq::Rmpq_div($$x, $$x, _str2mpq($y) // return $x->bdiv(Math::BigNum->new($y)));
    $x;
};

Class::Multimethods::multimethod bdiv => qw(Math::BigNum *) => sub {
    $_[0]->bdiv(Math::BigNum->new($_[1]));
};

Class::Multimethods::multimethod bdiv => qw(Math::BigNum Math::BigNum::Inf) => \&bzero;
Class::Multimethods::multimethod bdiv => qw(Math::BigNum Math::BigNum::Nan) => \&bnan;

=head2 mod

    $x->mod(BigNum)                # => BigNum | Nan
    $x->mod(Scalar)                # => BigNum | Nan

    BigNum % BigNum                # => BigNum | Nan
    BigNum % Scalar                # => BigNum | Nan
    Scalar % BigNum                # => BigNum | Nan

Remainder of C<x> when is divided by C<y>. Returns Nan when C<y> is zero.

Implemented as:

    x % y = x - y*floor(x/y)

=cut

Class::Multimethods::multimethod mod => qw(Math::BigNum Math::BigNum) => sub {
    my ($x, $y) = @_;

    $x = $$x;
    $y = $$y;

    Math::GMPq::Rmpq_sgn($y)
      || return nan();

    my $quo = Math::GMPq::Rmpq_init();
    Math::GMPq::Rmpq_set($quo, $x);
    Math::GMPq::Rmpq_div($quo, $quo, $y);

    # Floor
    if (!Math::GMPq::Rmpq_integer_p($quo)) {
        my $z = Math::GMPz::Rmpz_init();
        Math::GMPz::Rmpz_set_q($z, $quo);
        Math::GMPz::Rmpz_sub_ui($z, $z, 1) if Math::GMPq::Rmpq_sgn($quo) < 0;
        Math::GMPq::Rmpq_set_z($quo, $z);
    }

    Math::GMPq::Rmpq_mul($quo, $quo, $y);
    Math::GMPq::Rmpq_neg($quo, $quo);
    Math::GMPq::Rmpq_add($quo, $quo, $x);
    bless \$quo, __PACKAGE__;
};

Class::Multimethods::multimethod mod => qw(Math::BigNum $) => sub {
    my ($x, $y) = @_;

    CORE::int($y)
      || return nan();

    if (    CORE::int($y) eq $y
        and $y >= LONG_MIN
        and $y <= ULONG_MAX
        and Math::GMPq::Rmpq_integer_p($$x)) {
        my $r     = _int2mpz($x);
        my $neg_y = $y < 0;
        $y = -$y if $neg_y;
        Math::GMPz::Rmpz_mod_ui($r, $r, $y);
        if (!Math::GMPz::Rmpz_sgn($r)) {
            return (zero);    # return faster
        }
        elsif ($neg_y) {
            Math::GMPz::Rmpz_sub_ui($r, $r, $y);
        }
        return _mpz2big($r);
    }

    $x->mod(Math::BigNum->new($y));
};

Class::Multimethods::multimethod mod => qw(* Math::BigNum) => sub {
    Math::BigNum->new($_[0])->bmod($_[1]);
};

Class::Multimethods::multimethod mod => qw(Math::BigNum *) => sub {
    $_[0]->mod(Math::BigNum->new($_[1]));
};

Class::Multimethods::multimethod mod => qw(Math::BigNum Math::BigNum::Inf) => sub {
    $_[0]->copy->bmod($_[1]);
};

Class::Multimethods::multimethod mod => qw(Math::BigNum Math::BigNum::Nan) => \&nan;

=head2 bmod

    $x->bmod(BigNum)               # => BigNum | Nan
    $x->bmod(Scalar)               # => BigNum | Nan

    BigNum %= BigNum               # => BigNum | Nan
    BigNum %= Scalar               # => BigNum | Nan

Sets C<x> to the remainder of C<x> when is divided by C<y>. Sets C<x> to Nan when C<y> is zero.

=cut

Class::Multimethods::multimethod bmod => qw(Math::BigNum Math::BigNum) => sub {
    my ($x, $y) = @_;

    $x = $$x;
    $y = $$y;

    Math::GMPq::Rmpq_sgn($y)
      || return $_[0]->bnan();

    my $quo = Math::GMPq::Rmpq_init();
    Math::GMPq::Rmpq_set($quo, $x);
    Math::GMPq::Rmpq_div($quo, $quo, $y);

    # Floor
    if (!Math::GMPq::Rmpq_integer_p($quo)) {
        my $z = Math::GMPz::Rmpz_init();
        Math::GMPz::Rmpz_set_q($z, $quo);
        Math::GMPz::Rmpz_sub_ui($z, $z, 1) if Math::GMPq::Rmpq_sgn($quo) < 0;
        Math::GMPq::Rmpq_set_z($quo, $z);
    }

    Math::GMPq::Rmpq_mul($quo, $quo, $y);
    Math::GMPq::Rmpq_sub($x, $x, $quo);

    $_[0];
};

Class::Multimethods::multimethod bmod => qw(Math::BigNum $) => sub {
    my ($x, $y) = @_;

    CORE::int($y)
      || return $x->bnan;

    if (    CORE::int($y) eq $y
        and $y >= LONG_MIN
        and $y <= ULONG_MAX
        and Math::GMPq::Rmpq_integer_p($$x)) {
        my $r     = _int2mpz($x);
        my $neg_y = $y < 0;
        $y = -$y if $neg_y;
        Math::GMPz::Rmpz_mod_ui($r, $r, $y);
        if ($neg_y and Math::GMPz::Rmpz_sgn($r)) {
            Math::GMPz::Rmpz_sub_ui($r, $r, $y);
        }
        Math::GMPq::Rmpq_set_z($$x, $r);
        return $x;
    }

    $x->bmod(Math::BigNum->new($y));
};

Class::Multimethods::multimethod bmod => qw(Math::BigNum *) => sub {
    $_[0]->bmod(Math::BigNum->new($_[1]));
};

# +x mod +Inf = x
# +x mod -Inf = -Inf
# -x mod +Inf = +Inf
# -x mod -Inf = x
Class::Multimethods::multimethod bmod => qw(Math::BigNum Math::BigNum::Inf) => sub {
    my ($x, $y) = @_;
    Math::GMPq::Rmpq_sgn($$x) == Math::GMPq::Rmpq_sgn($$y) ? $x : _big2inf($x, $y);
};

Class::Multimethods::multimethod bmod => qw(Math::BigNum Math::BigNum::Nan) => \&bnan;

=head2 pow

    $x->pow(BigNum)                # => BigNum | Nan
    $x->pow(Scalar)                # => BigNum | Nan

    BigNum ** BigNum               # => BigNum | Nan
    BigNum ** Scalar               # => BigNum | Nan
    Scalar ** BigNum               # => BigNum | Nan

Raises C<x> to power C<y>. Returns Nan when C<x> is negative
and C<y> is not an integer.

When both C<x> and C<y> are integers, it does integer exponentiation and returns the exact result.

When only C<y> is an integer, it does rational exponentiation based on the identity: C<(a/b)^n = a^n / b^n>,
which computes the exact result.

When C<x> and C<y> are rationals, it does floating-point exponentiation, which is, in most cases, equivalent
with: C<x^y = exp(log(x) * y)>, in which the returned result may not be exact.

=cut

Class::Multimethods::multimethod pow => qw(Math::BigNum Math::BigNum) => sub {
    my ($x, $y) = @_;

    # Integer power
    if (Math::GMPq::Rmpq_integer_p($$y)) {

        my $q   = Math::GMPq::Rmpq_init();
        my $pow = Math::GMPq::Rmpq_get_d($$y);

        if (Math::GMPq::Rmpq_integer_p($$x)) {

            my $z = _int2mpz($x);
            Math::GMPz::Rmpz_pow_ui($z, $z, CORE::abs($pow));
            Math::GMPq::Rmpq_set_z($q, $z);

            if ($pow < 0) {
                if (!Math::GMPq::Rmpq_sgn($q)) {
                    return inf();
                }
                Math::GMPq::Rmpq_inv($q, $q);
            }
        }
        else {
            my $z = Math::GMPz::Rmpz_init();
            Math::GMPq::Rmpq_numref($z, $$x);
            Math::GMPz::Rmpz_pow_ui($z, $z, CORE::abs($pow));

            Math::GMPq::Rmpq_set_num($q, $z);

            Math::GMPq::Rmpq_denref($z, $$x);
            Math::GMPz::Rmpz_pow_ui($z, $z, CORE::abs($pow));

            Math::GMPq::Rmpq_set_den($q, $z);

            Math::GMPq::Rmpq_inv($q, $q) if $pow < 0;
        }

        return bless \$q, __PACKAGE__;
    }

    # Floating-point exponentiation otherwise
    my $r = _big2mpfr($x);
    Math::MPFR::Rmpfr_pow($r, $r, _big2mpfr($y), $ROUND);
    _mpfr2big($r);
};

=for comment
Class::Multimethods::multimethod pow => qw(Math::BigNum Math::BigNum::Complex) => sub {
    Math::BigNum::Complex->new($_[0])->pow($_[1]);
};
=cut

Class::Multimethods::multimethod pow => qw(Math::BigNum $) => sub {
    my ($x, $pow) = @_;

    # Integer power
    if (CORE::int($pow) eq $pow and $pow >= LONG_MIN and $pow <= ULONG_MAX) {

        my $q = Math::GMPq::Rmpq_init();

        if (Math::GMPq::Rmpq_integer_p($$x)) {

            my $z = _int2mpz($x);
            Math::GMPz::Rmpz_pow_ui($z, $z, CORE::abs($pow));
            Math::GMPq::Rmpq_set_z($q, $z);

            if ($pow < 0) {
                if (!Math::GMPq::Rmpq_sgn($q)) {
                    return inf();
                }
                Math::GMPq::Rmpq_inv($q, $q);
            }
        }
        else {
            my $z = Math::GMPz::Rmpz_init();
            Math::GMPq::Rmpq_numref($z, $$x);
            Math::GMPz::Rmpz_pow_ui($z, $z, CORE::abs($pow));

            Math::GMPq::Rmpq_set_num($q, $z);

            Math::GMPq::Rmpq_denref($z, $$x);
            Math::GMPz::Rmpz_pow_ui($z, $z, CORE::abs($pow));

            Math::GMPq::Rmpq_set_den($q, $z);

            Math::GMPq::Rmpq_inv($q, $q) if $pow < 0;
        }

        return bless \$q, __PACKAGE__;
    }

    $x->pow(Math::BigNum->new($pow));
};

Class::Multimethods::multimethod pow => qw(* Math::BigNum) => sub {
    Math::BigNum->new($_[0])->bpow($_[1]);
};

Class::Multimethods::multimethod pow => qw(Math::BigNum *) => sub {
    $_[0]->pow(Math::BigNum->new($_[1]));
};

# 0 ** Inf = 0
# 0 ** -Inf = Inf
# (+/-1) ** (+/-Inf) = 1
# x ** (-Inf) = 0
# x ** Inf = Inf

Class::Multimethods::multimethod pow => qw(Math::BigNum Math::BigNum::Inf) => sub {
    $_[0]->is_zero
      ? $_[1]->is_neg
          ? inf
          : zero
      : $_[0]->is_one || $_[0]->is_mone ? one
      : $_[1]->is_neg ? zero
      :                 inf;
};

Class::Multimethods::multimethod pow => qw(Math::BigNum Math::BigNum::Nan) => \&nan;

=head2 bpow

    $x->bpow(BigNum)               # => BigNum | Nan
    $x->bpow(Scalar)               # => BigNum | Nan

    BigNum **= BigNum              # => BigNum | Nan
    BigNum **= Scalar              # => BigNum | Nan
    Scalar **= BigNum              # => BigNum | Nan

Raises C<x> to power C<y>, changing C<x> in-place.

=cut

Class::Multimethods::multimethod bpow => qw(Math::BigNum Math::BigNum) => sub {
    my ($x, $y) = @_;

    # Integer power
    if (Math::GMPq::Rmpq_integer_p($$y)) {

        my $q   = $$x;
        my $pow = Math::GMPq::Rmpq_get_d($$y);

        if (Math::GMPq::Rmpq_integer_p($q)) {
            my $z = Math::GMPz::Rmpz_init();
            Math::GMPz::Rmpz_set_q($z, $q);
            Math::GMPz::Rmpz_pow_ui($z, $z, CORE::abs($pow));
            Math::GMPq::Rmpq_set_z($q, $z);

            if ($pow < 0) {
                if (!Math::GMPq::Rmpq_sgn($q)) {
                    return $x->binf;
                }
                Math::GMPq::Rmpq_inv($q, $q);
            }
        }
        else {
            my $z = Math::GMPz::Rmpz_init();
            Math::GMPq::Rmpq_numref($z, $q);
            Math::GMPz::Rmpz_pow_ui($z, $z, CORE::abs($pow));

            Math::GMPq::Rmpq_set_num($q, $z);

            Math::GMPq::Rmpq_denref($z, $q);
            Math::GMPz::Rmpz_pow_ui($z, $z, CORE::abs($pow));

            Math::GMPq::Rmpq_set_den($q, $z);

            Math::GMPq::Rmpq_inv($q, $q) if $pow < 0;
        }

        return $x;
    }

    # A floating-point otherwise
    my $r = _big2mpfr($x);
    Math::MPFR::Rmpfr_pow($r, $r, _big2mpfr($y), $ROUND);
    _mpfr2x($x, $r);
};

Class::Multimethods::multimethod bpow => qw(Math::BigNum $) => sub {
    my ($x, $pow) = @_;

    my $pow_is_int = (CORE::int($pow) eq $pow and $pow >= LONG_MIN and $pow <= ULONG_MAX);

    # Integer power
    if ($pow_is_int) {

        my $q = $$x;

        if (Math::GMPq::Rmpq_integer_p($q)) {
            my $z = Math::GMPz::Rmpz_init();
            Math::GMPz::Rmpz_set_q($z, $q);
            Math::GMPz::Rmpz_pow_ui($z, $z, CORE::abs($pow));
            Math::GMPq::Rmpq_set_z($q, $z);

            if ($pow < 0) {
                if (!Math::GMPq::Rmpq_sgn($q)) {
                    return $x->binf;
                }
                Math::GMPq::Rmpq_inv($q, $q);
            }
        }
        else {
            my $z = Math::GMPz::Rmpz_init();
            Math::GMPq::Rmpq_numref($z, $$x);
            Math::GMPz::Rmpz_pow_ui($z, $z, CORE::abs($pow));

            Math::GMPq::Rmpq_set_num($q, $z);

            Math::GMPq::Rmpq_denref($z, $$x);
            Math::GMPz::Rmpz_pow_ui($z, $z, CORE::abs($pow));

            Math::GMPq::Rmpq_set_den($q, $z);

            Math::GMPq::Rmpq_inv($q, $q) if $pow < 0;
        }

        return $x;
    }

    # A floating-point otherwise
    my $r = _big2mpfr($x);
    if ($pow_is_int) {
        if ($pow >= 0) {
            Math::MPFR::Rmpfr_pow_ui($r, $r, $pow, $ROUND);
        }
        else {
            Math::MPFR::Rmpfr_pow_si($r, $r, $pow, $ROUND);
        }
    }
    else {
        Math::MPFR::Rmpfr_pow($r, $r, _str2mpfr($pow) // (return $x->bpow(Math::BigNum->new($pow))), $ROUND);
    }

    _mpfr2x($x, $r);
};

Class::Multimethods::multimethod bpow => qw(Math::BigNum *) => sub {
    $_[0]->bpow(Math::BigNum->new($_[1]));
};

# 0 ** Inf = 0
# 0 ** -Inf = Inf
# (+/-1) ** (+/-Inf) = 1
# x ** (-Inf) = 0
# x ** Inf = Inf

Class::Multimethods::multimethod bpow => qw(Math::BigNum Math::BigNum::Inf) => sub {
    $_[0]->is_zero
      ? $_[1]->is_neg
          ? $_[0]->binf
          : $_[0]->bzero
      : $_[0]->is_one || $_[0]->is_mone ? $_[0]->bone
      : $_[1]->is_neg ? $_[0]->bzero
      :                 $_[0]->binf;
};

Class::Multimethods::multimethod bpow => qw(Math::BigNum Math::BigNum::Nan) => \&bnan;

=head2 inv

    $x->inv                        # => BigNum | Inf

Inverse value of C<x>. Return Inf when C<x> is zero. (C<1/x>)

=cut

sub inv {
    my ($x) = @_;

    # Return Inf when $x is zero.
    Math::GMPq::Rmpq_sgn($$x)
      || return inf();

    my $r = Math::GMPq::Rmpq_init();
    Math::GMPq::Rmpq_inv($r, $$x);
    bless \$r, __PACKAGE__;
}

=head2 binv

    $x->binv                       # => BigNum | Inf

Set C<x> to its inverse value. (C<1/x>)

=cut

sub binv {
    my ($x) = @_;

    # Return Inf when $x is zero.
    Math::GMPq::Rmpq_sgn($$x)
      || return $x->binf;

    Math::GMPq::Rmpq_inv($$x, $$x);
    $x;
}

=head2 sqr

    $x->sqr                        # => BigNum

Raise C<x> to the power of 2 and return the result. (C<x*x>)

=cut

sub sqr {
    my ($x) = @_;
    my $r = Math::GMPq::Rmpq_init();
    Math::GMPq::Rmpq_mul($r, $$x, $$x);
    bless \$r, __PACKAGE__;
}

=head2 bsqr

    $x->bsqr                       # => BigNum

Set C<x> to its multiplicative double. (C<x*x>)

=cut

sub bsqr {
    my ($x) = @_;
    Math::GMPq::Rmpq_mul($$x, $$x, $$x);
    $x;
}

=head2 bernfrac

    $n->bernfrac                   # => BigNum | Nan

Returns the nth-Bernoulli number C<B_n> as an exact fraction, computed with an
improved version of Seidel's algorithm, starting with C<bernfrac(0) = 1>.

For n >= 50, a more efficient algorithm is used, based on Zeta(n).

For negative values of C<n>, Nan is returned.

=cut

sub bernfrac {
    my ($n) = @_;

    $n = CORE::int(Math::GMPq::Rmpq_get_d($$n));

    $n == 0 and return one();
    $n > 1 and $n % 2 and return zero();    # Bn=0 for odd n>1
    $n < 0 and return nan();

    # Use a faster algorithm based on values of the Zeta function.
    # B(n) = (-1)^(n/2 + 1) * zeta(n)*2*n! / (2*pi)^n
    if ($n >= 50) {

        my $prec = (
            $n <= 156
            ? CORE::int($n * CORE::log($n) + 1)
            : CORE::int($n * CORE::log($n) / CORE::log(2) - 3 * $n)    # TODO: optimize for large n (>50_000)
        );

        my $f = Math::MPFR::Rmpfr_init2($prec);
        Math::MPFR::Rmpfr_zeta_ui($f, $n, $ROUND);                     # f = zeta(n)

        my $z = Math::GMPz::Rmpz_init();
        Math::GMPz::Rmpz_fac_ui($z, $n);                               # z = n!
        Math::GMPz::Rmpz_div_2exp($z, $z, $n - 1);                     # z = z / 2^(n-1)
        Math::MPFR::Rmpfr_mul_z($f, $f, $z, $ROUND);                   # f = f*z

        my $p = Math::MPFR::Rmpfr_init2($prec);
        Math::MPFR::Rmpfr_const_pi($p, $ROUND);                        # p = PI
        Math::MPFR::Rmpfr_pow_ui($p, $p, $n, $ROUND);                  # p = p^n
        Math::MPFR::Rmpfr_div($f, $f, $p, $ROUND);                     # f = f/p

        Math::GMPz::Rmpz_set_ui($z, 1);                                # z = 1
        Math::GMPz::Rmpz_mul_2exp($z, $z, $n + 1);                     # z = 2^(n+1)
        Math::GMPz::Rmpz_sub_ui($z, $z, 2);                            # z = z-2

        Math::MPFR::Rmpfr_mul_z($f, $f, $z, $ROUND);                   # f = f*z
        Math::MPFR::Rmpfr_round($f, $f);                               # f = [f]

        my $q = Math::GMPq::Rmpq_init();
        Math::MPFR::Rmpfr_get_q($q, $f);                               # q = f
        Math::GMPq::Rmpq_set_den($q, $z);                              # q = q/z
        Math::GMPq::Rmpq_canonicalize($q);                             # remove common factors

        Math::GMPq::Rmpq_neg($q, $q) if $n % 4 == 0;                   # q = -q    (iff 4|n)
        return bless \$q, __PACKAGE__;
    }

#<<<
    my @D = (
        Math::GMPz::Rmpz_init_set_ui(0),
        Math::GMPz::Rmpz_init_set_ui(1),
        map { Math::GMPz::Rmpz_init_set_ui(0) } (1 .. $n/2 - 1)
    );
#>>>

    my ($h, $w) = (1, 1);
    foreach my $i (0 .. $n - 1) {
        if ($w ^= 1) {
            Math::GMPz::Rmpz_add($D[$_], $D[$_], $D[$_ - 1]) for (1 .. $h - 1);
        }
        else {
            $w = $h++;
            Math::GMPz::Rmpz_add($D[$w], $D[$w], $D[$w + 1]) while --$w;
        }
    }

    my $den = Math::GMPz::Rmpz_init_set($ONE_Z);
    Math::GMPz::Rmpz_mul_2exp($den, $den, $n + 1);
    Math::GMPz::Rmpz_sub_ui($den, $den, 2);
    Math::GMPz::Rmpz_neg($den, $den) if $n % 4 == 0;

    my $r = Math::GMPq::Rmpq_init();
    Math::GMPq::Rmpq_set_num($r, $D[$h - 1]);
    Math::GMPq::Rmpq_set_den($r, $den);
    Math::GMPq::Rmpq_canonicalize($r);

    bless \$r, __PACKAGE__;
}

=head2 harmfrac

    $n->harmfrac                   # => BigNum | Nan

Returns the nth-Harmonic number C<H_n>. The harmonic numbers are the sum of
reciprocals of the first C<n> natural numbers: C<1 + 1/2 + 1/3 + ... + 1/n>.

For values greater than 7000, binary splitting (Fredrik Johansson's elegant formulation) is used.

=cut

sub harmfrac {
    my ($n) = @_;

    my $ui = CORE::int(Math::GMPq::Rmpq_get_d($$n));

    $ui || return zero();
    $ui < 0 and return nan();

    # Use binary splitting for large values of n. (by Fredrik Johansson)
    # http://fredrik-j.blogspot.ro/2009/02/how-not-to-compute-harmonic-numbers.html
    if ($ui > 7000) {

        my $num = Math::GMPz::Rmpz_init_set_ui(1);

        my $den = Math::GMPz::Rmpz_init();
        Math::GMPz::Rmpz_set_q($den, $$n);
        Math::GMPz::Rmpz_add_ui($den, $den, 1);

        my $temp = Math::GMPz::Rmpz_init();

        # Inspired by Dana Jacobsen's code from Math::Prime::Util::{PP,GMP}.
        #   https://metacpan.org/pod/Math::Prime::Util::PP
        #   https://metacpan.org/pod/Math::Prime::Util::GMP
        my $sub;
        $sub = sub {
            my ($num, $den) = @_;
            Math::GMPz::Rmpz_sub($temp, $den, $num);

            if (Math::GMPz::Rmpz_cmp_ui($temp, 1) == 0) {
                Math::GMPz::Rmpz_set($den, $num);
                Math::GMPz::Rmpz_set_ui($num, 1);
            }
            elsif (Math::GMPz::Rmpz_cmp_ui($temp, 2) == 0) {
                Math::GMPz::Rmpz_set($den, $num);
                Math::GMPz::Rmpz_mul_2exp($num, $num, 1);
                Math::GMPz::Rmpz_add_ui($num, $num, 1);
                Math::GMPz::Rmpz_addmul($den, $den, $den);
            }
            else {
                Math::GMPz::Rmpz_add($temp, $num, $den);
                Math::GMPz::Rmpz_tdiv_q_2exp($temp, $temp, 1);
                my $q = Math::GMPz::Rmpz_init_set($temp);
                my $r = Math::GMPz::Rmpz_init_set($temp);
                $sub->($num, $q);
                $sub->($r,   $den);
                Math::GMPz::Rmpz_mul($num,  $num, $den);
                Math::GMPz::Rmpz_mul($temp, $q,   $r);
                Math::GMPz::Rmpz_add($num, $num, $temp);
                Math::GMPz::Rmpz_mul($den, $den, $q);
            }
        };

        $sub->($num, $den);

        my $q = Math::GMPq::Rmpq_init();
        Math::GMPq::Rmpq_set_num($q, $num);
        Math::GMPq::Rmpq_set_den($q, $den);
        Math::GMPq::Rmpq_canonicalize($q);

        return bless \$q, __PACKAGE__;
    }

    my $num = Math::GMPz::Rmpz_init_set_ui(1);
    my $den = Math::GMPz::Rmpz_init_set_ui(1);

    for (my $k = 2 ; $k <= $ui ; ++$k) {
        Math::GMPz::Rmpz_mul_ui($num, $num, $k);    # num = num * k
        Math::GMPz::Rmpz_add($num, $num, $den);     # num = num + den
        Math::GMPz::Rmpz_mul_ui($den, $den, $k);    # den = den * k
    }

    my $r = Math::GMPq::Rmpq_init();
    Math::GMPq::Rmpq_set_num($r, $num);
    Math::GMPq::Rmpq_set_den($r, $den);
    Math::GMPq::Rmpq_canonicalize($r);

    bless \$r, __PACKAGE__;
}

############################ FLOATING-POINT OPERATIONS ############################

=head1 FLOATING-POINT OPERATIONS

All the operations in this section are done with floating-point approximations,
which are, in the end, converted to fraction-approximations.
In some cases, the results are 100% exact, but this is not guaranteed.

=cut

=head2 fadd

    $x->fadd(BigNum)               # => BigNum
    $x->fadd(Scalar)               # => BigNum

Floating-point addition of C<x> and C<y>.

=cut

Class::Multimethods::multimethod fadd => qw(Math::BigNum Math::BigNum) => sub {
    my ($x, $y) = @_;
    $x = _big2mpfr($x);
    Math::MPFR::Rmpfr_add_q($x, $x, $$y, $ROUND);
    _mpfr2big($x);
};

Class::Multimethods::multimethod fadd => qw(Math::BigNum $) => sub {
    my ($x, $y) = @_;

    my $r = _big2mpfr($x);
    if (CORE::int($y) eq $y and $y >= LONG_MIN and $y <= ULONG_MAX) {
        $y >= 0
          ? Math::MPFR::Rmpfr_add_ui($r, $r, $y, $ROUND)
          : Math::MPFR::Rmpfr_add_si($r, $r, $y, $ROUND);
    }
    else {
        Math::MPFR::Rmpfr_add($r, $r, _str2mpfr($y) // (return Math::BigNum->new($y)->bfadd($x)), $ROUND);
    }
    _mpfr2big($r);
};

Class::Multimethods::multimethod fadd => qw(Math::BigNum *) => sub {
    Math::BigNum->new($_[1])->bfadd($_[0]);
};

Class::Multimethods::multimethod fadd => qw(Math::BigNum Math::BigNum::Inf) => sub { $_[1] };
Class::Multimethods::multimethod fadd => qw(Math::BigNum Math::BigNum::Nan) => \&nan;

=head2 bfadd

    $x->bfadd(BigNum)              # => BigNum
    $x->bfadd(Scalar)              # => BigNum

Floating-point addition of C<x> and C<y>, changing C<x> in-place.

=cut

Class::Multimethods::multimethod bfadd => qw(Math::BigNum Math::BigNum) => sub {
    my ($x, $y) = @_;
    my $r = _big2mpfr($x);
    Math::MPFR::Rmpfr_add_q($r, $r, $$y, $ROUND);
    _mpfr2x($x, $r);
};

Class::Multimethods::multimethod bfadd => qw(Math::BigNum $) => sub {
    my ($x, $y) = @_;

    my $r = _big2mpfr($x);
    if (CORE::int($y) eq $y and $y >= LONG_MIN and $y <= ULONG_MAX) {
        $y >= 0
          ? Math::MPFR::Rmpfr_add_ui($r, $r, $y, $ROUND)
          : Math::MPFR::Rmpfr_add_si($r, $r, $y, $ROUND);
    }
    else {
        Math::MPFR::Rmpfr_add($r, $r, _str2mpfr($y) // (return $x->bfadd(Math::BigNum->new($y))), $ROUND);
    }
    _mpfr2x($x, $r);
};

Class::Multimethods::multimethod bfadd => qw(Math::BigNum *) => sub {
    $_[0]->bfadd(Math::BigNum->new($_[1]));
};

Class::Multimethods::multimethod bfadd => qw(Math::BigNum Math::BigNum::Inf) => \&_big2inf;
Class::Multimethods::multimethod bfadd => qw(Math::BigNum Math::BigNum::Nan) => \&bnan;

=head2 fsub

    $x->fsub(BigNum)               # => BigNum
    $x->fsub(Scalar)               # => BigNum

Floating-point subtraction of C<x> and C<y>.

=cut

Class::Multimethods::multimethod fsub => qw(Math::BigNum Math::BigNum) => sub {
    my ($x, $y) = @_;
    $x = _big2mpfr($x);
    Math::MPFR::Rmpfr_sub_q($x, $x, $$y, $ROUND);
    _mpfr2big($x);
};

Class::Multimethods::multimethod fsub => qw(Math::BigNum $) => sub {
    my ($x, $y) = @_;

    my $r = _big2mpfr($x);
    if (CORE::int($y) eq $y and $y >= LONG_MIN and $y <= ULONG_MAX) {
        $y >= 0
          ? Math::MPFR::Rmpfr_sub_ui($r, $r, $y, $ROUND)
          : Math::MPFR::Rmpfr_sub_si($r, $r, $y, $ROUND);
    }
    else {
        Math::MPFR::Rmpfr_sub($r, $r, _str2mpfr($y) // (return Math::BigNum->new($y)->bneg->bfadd($x)), $ROUND);
    }
    _mpfr2big($r);
};

Class::Multimethods::multimethod fsub => qw(Math::BigNum *) => sub {
    Math::BigNum->new($_[1])->bneg->bfadd($_[0]);
};

Class::Multimethods::multimethod fsub => qw(Math::BigNum Math::BigNum::Inf) => sub { $_[1]->neg };
Class::Multimethods::multimethod fsub => qw(Math::BigNum Math::BigNum::Nan) => \&nan;

=head2 bfsub

    $x->bfsub(BigNum)              # => BigNum
    $x->bfsub(Scalar)              # => BigNum

Floating-point subtraction of C<x> and C<y>, changing C<x> in-place.

=cut

Class::Multimethods::multimethod bfsub => qw(Math::BigNum Math::BigNum) => sub {
    my ($x, $y) = @_;
    my $r = _big2mpfr($x);
    Math::MPFR::Rmpfr_sub_q($r, $r, $$y, $ROUND);
    _mpfr2x($x, $r);
};

Class::Multimethods::multimethod bfsub => qw(Math::BigNum $) => sub {
    my ($x, $y) = @_;

    my $r = _big2mpfr($x);
    if (CORE::int($y) eq $y and $y >= LONG_MIN and $y <= ULONG_MAX) {
        $y >= 0
          ? Math::MPFR::Rmpfr_sub_ui($r, $r, $y, $ROUND)
          : Math::MPFR::Rmpfr_sub_si($r, $r, $y, $ROUND);
    }
    else {
        Math::MPFR::Rmpfr_sub($r, $r, _str2mpfr($y) // (return $x->bfsub(Math::BigNum->new($y))), $ROUND);
    }
    _mpfr2x($x, $r);
};

Class::Multimethods::multimethod bfsub => qw(Math::BigNum *) => sub {
    $_[0]->bfsub(Math::BigNum->new($_[1]));
};

Class::Multimethods::multimethod bfsub => qw(Math::BigNum Math::BigNum::Inf) => \&_big2ninf;
Class::Multimethods::multimethod bfsub => qw(Math::BigNum Math::BigNum::Nan) => \&bnan;

=head2 fmul

    $x->fmul(BigNum)               # => BigNum
    $x->fmul(Scalar)               # => BigNum

Floating-point multiplication of C<x> by C<y>.

=cut

Class::Multimethods::multimethod fmul => qw(Math::BigNum Math::BigNum) => sub {
    my ($x, $y) = @_;
    $x = _big2mpfr($x);
    Math::MPFR::Rmpfr_mul_q($x, $x, $$y, $ROUND);
    _mpfr2big($x);
};

Class::Multimethods::multimethod fmul => qw(Math::BigNum $) => sub {
    my ($x, $y) = @_;

    my $r = _big2mpfr($x);
    if (CORE::int($y) eq $y and $y >= LONG_MIN and $y <= ULONG_MAX) {
        $y >= 0
          ? Math::MPFR::Rmpfr_mul_ui($r, $r, $y, $ROUND)
          : Math::MPFR::Rmpfr_mul_si($r, $r, $y, $ROUND);
    }
    else {
        Math::MPFR::Rmpfr_mul($r, $r, _str2mpfr($y) // (return Math::BigNum->new($y)->bfmul($x)), $ROUND);
    }
    _mpfr2big($r);
};

Class::Multimethods::multimethod fmul => qw(Math::BigNum *) => sub {
    Math::BigNum->new($_[1])->bfmul($_[0]);
};

Class::Multimethods::multimethod fmul => qw(Math::BigNum Math::BigNum::Inf) => sub {
    my $sign = Math::GMPq::Rmpq_sgn(${$_[0]});
    $sign < 0 ? $_[1]->neg : $sign > 0 ? $_[1]->copy : nan;
};

Class::Multimethods::multimethod fmul => qw(Math::BigNum Math::BigNum::Nan) => \&nan;

=head2 bfmul

    $x->bfmul(BigNum)              # => BigNum
    $x->bfmul(Scalar)              # => BigNum

Floating-point multiplication of C<x> by C<y>, changing C<x> in-place.

=cut

Class::Multimethods::multimethod bfmul => qw(Math::BigNum Math::BigNum) => sub {
    my ($x, $y) = @_;
    my $r = _big2mpfr($x);
    Math::MPFR::Rmpfr_mul_q($r, $r, $$y, $ROUND);
    _mpfr2x($x, $r);
};

Class::Multimethods::multimethod bfmul => qw(Math::BigNum $) => sub {
    my ($x, $y) = @_;

    my $r = _big2mpfr($x);
    if (CORE::int($y) eq $y and $y >= LONG_MIN and $y <= ULONG_MAX) {
        $y >= 0
          ? Math::MPFR::Rmpfr_mul_ui($r, $r, $y, $ROUND)
          : Math::MPFR::Rmpfr_mul_si($r, $r, $y, $ROUND);
    }
    else {
        Math::MPFR::Rmpfr_mul($r, $r, _str2mpfr($y) // (return $x->bfmul(Math::BigNum->new($y))), $ROUND);
    }
    _mpfr2x($x, $r);
};

Class::Multimethods::multimethod bfmul => qw(Math::BigNum *) => sub {
    $_[0]->bfmul(Math::BigNum->new($_[1]));
};

Class::Multimethods::multimethod bfmul => qw(Math::BigNum Math::BigNum::Inf) => sub {
    my ($x) = @_;
    my $sign = Math::GMPq::Rmpq_sgn($$x);
    $sign < 0 ? _big2ninf(@_) : $sign > 0 ? _big2inf(@_) : $x->bnan;
};

Class::Multimethods::multimethod bfmul => qw(Math::BigNum Math::BigNum::Nan) => \&bnan;

=head2 fdiv

    $x->fdiv(BigNum)               # => BigNum | Nan | Inf
    $x->fdiv(Scalar)               # => BigNum | Nan | Inf

Floating-point division of C<x> by C<y>.

=cut

Class::Multimethods::multimethod fdiv => qw(Math::BigNum Math::BigNum) => sub {
    my ($x, $y) = @_;
    $x = _big2mpfr($x);
    Math::MPFR::Rmpfr_div_q($x, $x, $$y, $ROUND);
    _mpfr2big($x);
};

Class::Multimethods::multimethod fdiv => qw(Math::BigNum $) => sub {
    my ($x, $y) = @_;

    my $r = _big2mpfr($x);
    if (CORE::int($y) eq $y and $y >= LONG_MIN and $y <= ULONG_MAX) {
        $y >= 0
          ? Math::MPFR::Rmpfr_div_ui($r, $r, $y, $ROUND)
          : Math::MPFR::Rmpfr_div_si($r, $r, $y, $ROUND);
    }
    else {
        Math::MPFR::Rmpfr_div($r, $r, _str2mpfr($y) // (return Math::BigNum->new($y)->bfdiv($x)->binv), $ROUND);
    }
    _mpfr2big($r);
};

Class::Multimethods::multimethod fdiv => qw(Math::BigNum *) => sub {
    Math::BigNum->new($_[1])->bfdiv($_[0])->binv;
};

Class::Multimethods::multimethod fdiv => qw(Math::BigNum Math::BigNum::Inf) => \&zero;
Class::Multimethods::multimethod fdiv => qw(Math::BigNum Math::BigNum::Nan) => \&nan;

=head2 bfdiv

    $x->bfdiv(BigNum)              # => BigNum | Nan | Inf
    $x->bfdiv(Scalar)              # => BigNum | Nan | Inf

Floating-point division of C<x> by C<y>, changing C<x> in-place.

=cut

Class::Multimethods::multimethod bfdiv => qw(Math::BigNum Math::BigNum) => sub {
    my ($x, $y) = @_;
    my $r = _big2mpfr($x);
    Math::MPFR::Rmpfr_div_q($r, $r, $$y, $ROUND);
    _mpfr2x($x, $r);
};

Class::Multimethods::multimethod bfdiv => qw(Math::BigNum $) => sub {
    my ($x, $y) = @_;

    my $r = _big2mpfr($x);
    if (CORE::int($y) eq $y and $y >= LONG_MIN and $y <= ULONG_MAX) {
        $y >= 0
          ? Math::MPFR::Rmpfr_div_ui($r, $r, $y, $ROUND)
          : Math::MPFR::Rmpfr_div_si($r, $r, $y, $ROUND);
    }
    else {
        Math::MPFR::Rmpfr_div($r, $r, _str2mpfr($y) // (return $x->bfdiv(Math::BigNum->new($y))), $ROUND);
    }
    _mpfr2x($x, $r);
};

Class::Multimethods::multimethod bfdiv => qw(Math::BigNum *) => sub {
    $_[0]->bfdiv(Math::BigNum->new($_[1]));
};

Class::Multimethods::multimethod bfdiv => qw(Math::BigNum Math::BigNum::Inf) => \&bzero;
Class::Multimethods::multimethod bfdiv => qw(Math::BigNum Math::BigNum::Nan) => \&bnan;

=head2 fpow

    $x->fpow(BigNum)               # => BigNum | Inf | Nan
    $x->fpow(Scalar)               # => BigNum | Inf | Nan

Raises C<x> to power C<y>. Returns Nan when C<x> is negative
and C<y> is not an integer.

=cut

Class::Multimethods::multimethod fpow => qw(Math::BigNum Math::BigNum) => sub {
    my ($x, $y) = @_;
    my $r = _big2mpfr($x);
    Math::MPFR::Rmpfr_pow($r, $r, _big2mpfr($y), $ROUND);
    _mpfr2big($r);
};

Class::Multimethods::multimethod fpow => qw(Math::BigNum $) => sub {
    my ($x, $y) = @_;
    my $r = _big2mpfr($x);
    if (CORE::int($y) eq $y and $y >= LONG_MIN and $y <= ULONG_MAX) {
        $y >= 0
          ? Math::MPFR::Rmpfr_pow_ui($r, $r, $y, $ROUND)
          : Math::MPFR::Rmpfr_pow_si($r, $r, $y, $ROUND);
    }
    else {
        Math::MPFR::Rmpfr_pow($r, $r, _str2mpfr($y) // (return $x->fpow(Math::BigNum->new($y))), $ROUND);
    }
    _mpfr2big($r);
};

Class::Multimethods::multimethod fpow => qw(Math::BigNum *) => sub {
    $_[0]->fpow(Math::BigNum->new($_[1]));
};

Class::Multimethods::multimethod fpow => qw(Math::BigNum Math::BigNum::Inf) => sub {
    $_[0]->pow($_[1]);
};

Class::Multimethods::multimethod fpow => qw(Math::BigNum Math::BigNum::Nan) => \&nan;

=head2 bfpow

    $x->bfpow(BigNum)              # => BigNum | Inf | Nan
    $x->bfpow(Scalar)              # => BigNum | Inf | Nan

Raises C<x> to power C<y>, changing C<x> in-place. Promotes C<x> to Nan when C<x> is negative
and C<y> is not an integer.

=cut

Class::Multimethods::multimethod bfpow => qw(Math::BigNum Math::BigNum) => sub {
    my ($x, $y) = @_;
    my $r = _big2mpfr($x);
    Math::MPFR::Rmpfr_pow($r, $r, _big2mpfr($y), $ROUND);
    _mpfr2x($x, $r);
};

Class::Multimethods::multimethod bfpow => qw(Math::BigNum $) => sub {
    my ($x, $y) = @_;
    my $r = _big2mpfr($x);
    if (CORE::int($y) eq $y and $y >= LONG_MIN and $y <= ULONG_MAX) {
        $y >= 0
          ? Math::MPFR::Rmpfr_pow_ui($r, $r, $y, $ROUND)
          : Math::MPFR::Rmpfr_pow_si($r, $r, $y, $ROUND);
    }
    else {
        Math::MPFR::Rmpfr_pow($r, $r, _str2mpfr($y) // (return $x->bfpow(Math::BigNum->new($y))), $ROUND);
    }
    _mpfr2x($x, $r);
};

Class::Multimethods::multimethod bfpow => qw(Math::BigNum *) => sub {
    $_[0]->bfpow(Math::BigNum->new($_[1]));
};

Class::Multimethods::multimethod bfpow => qw(Math::BigNum Math::BigNum::Inf) => sub {
    $_[0]->bpow($_[1]);
};

Class::Multimethods::multimethod bfpow => qw(Math::BigNum Math::BigNum::Nan) => \&bnan;

=head2 fmod

    $x->fmod(BigNum)               # => BigNum | Nan
    $x->fmod(Scalar)               # => BigNum | Nan

The remainder of C<x> when is divided by C<y>. Nan is returned when C<y> is zero.

=cut

Class::Multimethods::multimethod fmod => qw(Math::BigNum Math::BigNum) => sub {
    my ($x, $y) = @_;

    $x = _big2mpfr($x);
    $y = _big2mpfr($y);

    Math::MPFR::Rmpfr_fmod($x, $x, $y, $ROUND);

    my $sign_r = Math::MPFR::Rmpfr_sgn($x);
    if (!$sign_r) {
        return (zero);    # return faster
    }
    elsif ($sign_r > 0 xor Math::MPFR::Rmpfr_sgn($y) > 0) {
        Math::MPFR::Rmpfr_add($x, $x, $y, $ROUND);
    }

    _mpfr2big($x);
};

Class::Multimethods::multimethod fmod => qw(Math::BigNum $) => sub {
    my ($x, $y) = @_;

    my $m = _str2mpfr($y) // return $x->fmod(Math::BigNum->new($y));
    my $r = _big2mpfr($x);

    Math::MPFR::Rmpfr_fmod($r, $r, $m, $ROUND);

    my $sign_r = Math::MPFR::Rmpfr_sgn($r);
    if (!$sign_r) {
        return (zero);    # return faster
    }
    elsif ($sign_r > 0 xor Math::MPFR::Rmpfr_sgn($m) > 0) {
        Math::MPFR::Rmpfr_add($r, $r, $m, $ROUND);
    }

    _mpfr2big($r);
};

Class::Multimethods::multimethod fmod => qw(Math::BigNum *) => sub {
    $_[0]->fmod(Math::BigNum->new($_[1]));
};

Class::Multimethods::multimethod fmod => qw(Math::BigNum Math::BigNum::Inf) => sub {
    $_[0]->copy->bmod($_[1]);
};

Class::Multimethods::multimethod fmod => qw(Math::BigNum Math::BigNum::Nan) => \&nan;

=head2 bfmod

    $x->bfmod(BigNum)              # => BigNum | Nan
    $x->bfmod(Scalar)              # => BigNum | Nan

The remainder of C<x> when is divided by C<y>, changing C<x> in-place.
Promotes C<x> to Nan when C<y> is zero.

=cut

Class::Multimethods::multimethod bfmod => qw(Math::BigNum Math::BigNum) => sub {
    my ($x, $y) = @_;

    my $r = _big2mpfr($x);
    my $m = _big2mpfr($y);

    Math::MPFR::Rmpfr_fmod($r, $r, $m, $ROUND);

    my $sign_r = Math::MPFR::Rmpfr_sgn($r);
    if (!$sign_r) {
        return $x->bzero;    # return faster
    }
    elsif ($sign_r > 0 xor Math::MPFR::Rmpfr_sgn($m) > 0) {
        Math::MPFR::Rmpfr_add($r, $r, $m, $ROUND);
    }

    _mpfr2x($x, $r);
};

Class::Multimethods::multimethod bfmod => qw(Math::BigNum $) => sub {
    my ($x, $y) = @_;

    my $m = _str2mpfr($y) // return $x->bfmod(Math::BigNum->new($y));
    my $r = _big2mpfr($x);

    Math::MPFR::Rmpfr_fmod($r, $r, $m, $ROUND);

    my $sign_r = Math::MPFR::Rmpfr_sgn($r);
    if (!$sign_r) {
        return $x->bzero;    # return faster
    }
    elsif ($sign_r > 0 xor Math::MPFR::Rmpfr_sgn($m) > 0) {
        Math::MPFR::Rmpfr_add($r, $r, $m, $ROUND);
    }

    _mpfr2x($x, $r);
};

Class::Multimethods::multimethod bfmod => qw(Math::BigNum *) => sub {
    $_[0]->bfmod(Math::BigNum->new($_[1]));
};

Class::Multimethods::multimethod bfmod => qw(Math::BigNum Math::BigNum::Inf) => sub {
    $_[0]->bmod($_[1]);
};

Class::Multimethods::multimethod bfmod => qw(Math::BigNum Math::BigNum::Nan) => \&bnan;

=head2 sqrt

    $x->sqrt                       # => BigNum | Nan
    sqrt($x)                       # => BigNum | Nan

Square root of C<x>. Returns Nan when C<x> is negative.

=cut

sub sqrt {
    my ($x) = @_;
    my $r = _big2mpfr($x);
    Math::MPFR::Rmpfr_sqrt($r, $r, $ROUND);
    _mpfr2big($r);
}

=head2 bsqrt

    $x->bsqrt                      # => BigNum | Nan

Square root of C<x>, changing C<x> in-place. Promotes C<x> to Nan when C<x> is negative.

=cut

sub bsqrt {
    my ($x) = @_;
    my $r = _big2mpfr($x);
    Math::MPFR::Rmpfr_sqrt($r, $r, $ROUND);
    _mpfr2x($x, $r);
}

=head2 cbrt

    $x->cbrt                       # => BigNum | Nan

Cube root of C<x>. Returns Nan when C<x> is negative.

=cut

sub cbrt {
    my ($x) = @_;
    my $r = _big2mpfr($x);
    Math::MPFR::Rmpfr_cbrt($r, $r, $ROUND);
    _mpfr2big($r);
}

=head2 root

    $x->root(BigNum)               # => BigNum | Nan
    $x->root(Scalar)               # => BigNum | Nan

Nth root of C<x>. Returns Nan when C<x> is negative.

=cut

Class::Multimethods::multimethod root => qw(Math::BigNum Math::BigNum) => sub {
    my ($x, $y) = @_;

    if (Math::GMPq::Rmpq_sgn($$y) > 0 and Math::GMPq::Rmpq_integer_p($$y)) {
        $x = _big2mpfr($x);
        Math::MPFR::Rmpfr_root($x, $x, Math::GMPq::Rmpq_get_d($$y), $ROUND);
        _mpfr2big($x);
    }
    else {
        $x->pow($y->inv);
    }
};

=for comment
Class::Multimethods::multimethod root => qw(Math::BigNum Math::BigNum::Complex) => sub {
    Math::BigNum::Complex->new($_[0])->pow($_[1]->inv);
};
=cut

Class::Multimethods::multimethod root => qw(Math::BigNum $) => sub {
    my ($x, $y) = @_;

    if (CORE::int($y) eq $y and $y > 0 and $y <= ULONG_MAX) {
        $x = _big2mpfr($x);
        Math::MPFR::Rmpfr_root($x, $x, $y, $ROUND);
        _mpfr2big($x);
    }
    else {
        $x->pow(Math::BigNum->new($y)->binv);
    }
};

Class::Multimethods::multimethod root => qw(Math::BigNum *) => sub {
    $_[0]->root(Math::BigNum->new($_[1]));
};

Class::Multimethods::multimethod root => qw(Math::BigNum Math::BigNum::Inf) => \&one;
Class::Multimethods::multimethod root => qw(Math::BigNum Math::BigNum::Nan) => \&nan;

=head2 broot

    $x->broot(BigNum)              # => BigNum | Nan
    $x->broot(Scalar)              # => BigNum(1)

Nth root of C<x>, changing C<x> in-place. Promotes
C<x> to Nan when C<x> is negative.

=cut

Class::Multimethods::multimethod broot => qw(Math::BigNum Math::BigNum) => sub {
    my ($x, $y) = @_;

    if (Math::GMPq::Rmpq_sgn($$y) > 0 and Math::GMPq::Rmpq_integer_p($$y)) {
        my $f = _big2mpfr($x);
        Math::MPFR::Rmpfr_root($f, $f, Math::GMPq::Rmpq_get_d($$y), $ROUND);
        _mpfr2x($x, $f);
    }
    else {
        $x->bpow($y->inv);
    }
};

Class::Multimethods::multimethod broot => qw(Math::BigNum $) => sub {
    my ($x, $y) = @_;

    if (CORE::int($y) eq $y and $y > 0 and $y <= ULONG_MAX) {
        my $f = _big2mpfr($x);
        Math::MPFR::Rmpfr_root($f, $f, $y, $ROUND);
        _mpfr2x($x, $f);
    }
    else {
        $x->bpow(Math::BigNum->new($y)->binv);
    }
};

Class::Multimethods::multimethod broot => qw(Math::BigNum *) => sub {
    $_[0]->broot(Math::BigNum->new($_[1]));
};

=for comment
Class::Multimethods::multimethod broot => qw(Math::BigNum Math::BigNum::Complex) => sub {
    my $complex = Math::BigNum::Complex->new($_[0])->bpow($_[1]->inv);
    _big2cplx($_[0], $complex);
};
=cut

Class::Multimethods::multimethod broot => qw(Math::BigNum Math::BigNum::Inf) => \&bone;
Class::Multimethods::multimethod broot => qw(Math::BigNum Math::BigNum::Nan) => \&bnan;

=head2 ln

    $x->ln                         # => BigNum | Nan

Logarithm of C<x> in base I<e>. Returns Nan when C<x> is negative.

=cut

sub ln {
    my ($x) = @_;
    my $r = _big2mpfr($x);
    Math::MPFR::Rmpfr_log($r, $r, $ROUND);
    _mpfr2big($r);
}

=head2 bln

    $x->bln                        # => BigNum | Nan

Logarithm of C<x> in base I<e>, changing the C<x> in-place.
Promotes C<x> to Nan when C<x> is negative.

=cut

sub bln {
    my ($x) = @_;
    my $r = _big2mpfr($x);
    Math::MPFR::Rmpfr_log($r, $r, $ROUND);
    _mpfr2x($x, $r);
}

=head2 log

    $x->log                        # => BigNum | Nan
    $x->log(BigNum)                # => BigNum | Nan
    $x->log(Scalar)                # => BigNum | Nan
    log(BigNum)                    # => BigNum | Nan

Logarithm of C<x> in base C<y>. When C<y> is not specified, it defaults to base e.
Returns Nan when C<x> is negative and -Inf when C<x> is zero.

=cut

# Probably we should add cases when the base equals zero.

# Example:
#   log(+42) / log(0) = 0
#   log(-42) / log(0) = 0
#   log( 0 ) / log(0) = undefined

Class::Multimethods::multimethod log => qw(Math::BigNum Math::BigNum) => sub {
    my ($x, $y) = @_;

    # log(x,base) = log(x)/log(base)
    my $r = _big2mpfr($x);
    Math::MPFR::Rmpfr_log($r, $r, $ROUND);
    my $baseln = _big2mpfr($y);
    Math::MPFR::Rmpfr_log($baseln, $baseln, $ROUND);
    Math::MPFR::Rmpfr_div($r, $r, $baseln, $ROUND);

    _mpfr2big($r);
};

Class::Multimethods::multimethod log => qw(Math::BigNum $) => sub {
    my ($x, $y) = @_;

    if (CORE::int($y) eq $y and $y == 2) {
        my $r = _big2mpfr($x);
        Math::MPFR::Rmpfr_log2($r, $r, $ROUND);
        _mpfr2big($r);
    }
    elsif (CORE::int($y) eq $y and $y == 10) {
        my $r = _big2mpfr($x);
        Math::MPFR::Rmpfr_log10($r, $r, $ROUND);
        _mpfr2big($r);
    }
    else {
        my $baseln = _str2mpfr($y) // return $x->log(Math::BigNum->new($y));
        my $r = _big2mpfr($x);
        Math::MPFR::Rmpfr_log($r,      $r,      $ROUND);
        Math::MPFR::Rmpfr_log($baseln, $baseln, $ROUND);
        Math::MPFR::Rmpfr_div($r, $r, $baseln, $ROUND);
        _mpfr2big($r);
    }
};

Class::Multimethods::multimethod log => qw(Math::BigNum) => \&ln;

Class::Multimethods::multimethod log => qw(Math::BigNum *) => sub {
    $_[0]->log(Math::BigNum->new($_[1]));
};

Class::Multimethods::multimethod log => qw(Math::BigNum Math::BigNum::Nan) => \&nan;

# log(+/-Inf) = +Inf
# log(-42) / log(+/-Inf) = 0
# log(+42) / log(+/-Inf) = 0
# log(0)   / log(+/-Inf) = NaN

Class::Multimethods::multimethod log => qw(Math::BigNum Math::BigNum::Inf) => sub {
    Math::GMPq::Rmpq_sgn(${$_[0]}) == 0 ? nan() : zero();
};

=head2 blog

    $x->blog                       # => BigNum | Nan
    $x->blog(BigNum)               # => BigNum | Nan
    $x->log(Scalar)                # => BigNum | Nan

Logarithm of C<x> in base C<y>, changing the C<x> in-place.
When C<y> is not specified, it defaults to base I<e>.

=cut

Class::Multimethods::multimethod blog => qw(Math::BigNum $) => sub {
    my ($x, $y) = @_;

    if (CORE::int($y) eq $y and $y == 2) {
        my $r = _big2mpfr($x);
        Math::MPFR::Rmpfr_log2($r, $r, $ROUND);
        _mpfr2x($x, $r);

    }
    elsif (CORE::int($y) eq $y and $y == 10) {
        my $r = _big2mpfr($x);
        Math::MPFR::Rmpfr_log10($r, $r, $ROUND);
        _mpfr2x($x, $r);
    }
    else {
        my $baseln = _str2mpfr($y) // return $x->blog(Math::BigNum->new($y));
        my $r = _big2mpfr($x);
        Math::MPFR::Rmpfr_log($r,      $r,      $ROUND);
        Math::MPFR::Rmpfr_log($baseln, $baseln, $ROUND);
        Math::MPFR::Rmpfr_div($r, $r, $baseln, $ROUND);
        _mpfr2x($x, $r);
    }
};

Class::Multimethods::multimethod blog => qw(Math::BigNum Math::BigNum) => sub {
    $_[0]->blog(Math::GMPq::Rmpq_get_d(${$_[1]}));
};

Class::Multimethods::multimethod blog => qw(Math::BigNum) => \&bln;

Class::Multimethods::multimethod blog => qw(Math::BigNum *) => sub {
    $_[0]->blog(Math::BigNum->new($_[1]));
};

Class::Multimethods::multimethod blog => qw(Math::BigNum Math::BigNum::Nan) => \&bnan;

Class::Multimethods::multimethod blog => qw(Math::BigNum Math::BigNum::Inf) => sub {
    Math::GMPq::Rmpq_sgn(${$_[0]}) == 0 ? $_[0]->bnan : $_[0]->bzero;
};

=head2 log2

    $x->log2                       # => BigNum | Nan

Logarithm of C<x> in base 2. Returns Nan when C<x> is negative.

=cut

sub log2 {
    my ($x) = @_;
    my $r = _big2mpfr($x);
    Math::MPFR::Rmpfr_log2($r, $r, $ROUND);
    _mpfr2big($r);
}

=head2 log10

    $x->log10                      # => BigNum | Nan

Logarithm of C<x> in base 10. Returns Nan when C<x> is negative.

=cut

sub log10 {
    my ($x) = @_;
    my $r = _big2mpfr($x);
    Math::MPFR::Rmpfr_log10($r, $r, $ROUND);
    _mpfr2big($r);
}

=head2 lgrt

    $x->lgrt                       # => BigNum | Nan

Logarithmic-root of C<x>, which is the largest solution to C<a^a = b>, where C<b> is known.
The value of C<x> should not be less than C<e^(-1/e)>.

Example:

     100->lgrt   # solves for x in `x^x = 100` and returns: `3.59728...`

=cut

sub lgrt {
    my ($x) = @_;

    my $d = _big2mpfr($x);
    Math::MPFR::Rmpfr_log($d, $d, $ROUND);

    my $p = Math::MPFR::Rmpfr_init2($PREC);
    Math::MPFR::Rmpfr_ui_pow_ui($p, 10, CORE::int($PREC / 4), $ROUND);
    Math::MPFR::Rmpfr_ui_div($p, 1, $p, $ROUND);

    $x = Math::MPFR::Rmpfr_init2($PREC);
    Math::MPFR::Rmpfr_set_ui($x, 1, $ROUND);

    my $y = Math::MPFR::Rmpfr_init2($PREC);
    Math::MPFR::Rmpfr_set_ui($y, 0, $ROUND);

    my $count = 0;
    my $tmp   = Math::MPFR::Rmpfr_init2($PREC);

    while (1) {
        Math::MPFR::Rmpfr_sub($tmp, $x, $y, $ROUND);
        Math::MPFR::Rmpfr_cmpabs($tmp, $p) <= 0 and last;

        Math::MPFR::Rmpfr_set($y, $x, $ROUND);

        Math::MPFR::Rmpfr_log($tmp, $x, $ROUND);
        Math::MPFR::Rmpfr_add_ui($tmp, $tmp, 1, $ROUND);

        Math::MPFR::Rmpfr_add($x, $x, $d, $ROUND);
        Math::MPFR::Rmpfr_div($x, $x, $tmp, $ROUND);
        last if ++$count > $PREC;
    }

    _mpfr2big($x);
}

=head2 lambert_w

    $x->lambert_w                  # => BigNum | Nan

The Lambert-W function, defined in real numbers. The value of C<x> should not be less than C<-1/e>.

Example:

     100->log->lambert_w->exp   # solves for x in `x^x = 100` and returns: `3.59728...`

=cut

sub lambert_w {
    my ($x) = @_;

    Math::GMPq::Rmpq_equal($$x, $MONE) && return nan();

    my $d = _big2mpfr($x);

    $PREC = CORE::int($PREC);
    Math::MPFR::Rmpfr_ui_pow_ui((my $p = Math::MPFR::Rmpfr_init2($PREC)), 10, CORE::int($PREC / 4), $ROUND);
    Math::MPFR::Rmpfr_ui_div($p, 1, $p, $ROUND);

    Math::MPFR::Rmpfr_set_ui(($x = Math::MPFR::Rmpfr_init2($PREC)), 1, $ROUND);
    Math::MPFR::Rmpfr_set_ui((my $y = Math::MPFR::Rmpfr_init2($PREC)), 0, $ROUND);

    my $count = 0;
    my $tmp   = Math::MPFR::Rmpfr_init2($PREC);

    while (1) {
        Math::MPFR::Rmpfr_sub($tmp, $x, $y, $ROUND);
        Math::MPFR::Rmpfr_cmpabs($tmp, $p) <= 0 and last;

        Math::MPFR::Rmpfr_set($y, $x, $ROUND);

        Math::MPFR::Rmpfr_log($tmp, $x, $ROUND);
        Math::MPFR::Rmpfr_add_ui($tmp, $tmp, 1, $ROUND);

        Math::MPFR::Rmpfr_add($x, $x, $d, $ROUND);
        Math::MPFR::Rmpfr_div($x, $x, $tmp, $ROUND);
        last if ++$count > $PREC;
    }

    Math::MPFR::Rmpfr_log($x, $x, $ROUND);
    _mpfr2big($x);
}

=head2 exp

    $x->exp                        # => BigNum

Exponential of C<x> in base e. (C<e^x>)

=cut

sub exp {
    my $r = _big2mpfr($_[0]);
    Math::MPFR::Rmpfr_exp($r, $r, $ROUND);
    _mpfr2big($r);
}

=head2 bexp

    $x->bexp                       # => BigNum

Exponential of C<x> in base e, changing C<x> in-place.

=cut

sub bexp {
    my ($x) = @_;
    my $r = _big2mpfr($x);
    Math::MPFR::Rmpfr_exp($r, $r, $ROUND);
    _mpfr2x($x, $r);
}

=head2 exp2

    $x->exp2                       # => BigNum

Exponential of C<x> in base 2. (C<2^x>)

=cut

sub exp2 {
    my $r = _big2mpfr($_[0]);
    Math::MPFR::Rmpfr_exp2($r, $r, $ROUND);
    _mpfr2big($r);
}

=head2 exp10

    $x->exp10                      # => BigNum

Exponential of C<x> in base 10. (C<10^x>)

=cut

sub exp10 {
    my $r = _big2mpfr($_[0]);
    Math::MPFR::Rmpfr_exp10($r, $r, $ROUND);
    _mpfr2big($r);
}

=head1 * Trigonometry

=cut

=head2 sin

    $x->sin                        # => BigNum

Returns the sine of C<x>.

=cut

sub sin {
    my $r = _big2mpfr($_[0]);
    Math::MPFR::Rmpfr_sin($r, $r, $ROUND);
    _mpfr2big($r);
}

=head2 asin

    $x->asin                       # => BigNum | Nan

Returns the inverse sine of C<x>.
Returns Nan for x < -1 or x > 1.

=cut

sub asin {
    my ($x) = @_;
    my $r = _big2mpfr($x);
    Math::MPFR::Rmpfr_asin($r, $r, $ROUND);
    _mpfr2big($r);
}

=head2 sinh

    $x->sinh                       # => BigNum

Returns the hyperbolic sine of C<x>.

=cut

sub sinh {
    my $r = _big2mpfr($_[0]);
    Math::MPFR::Rmpfr_sinh($r, $r, $ROUND);
    _mpfr2big($r);
}

=head2 asinh

    $x->asinh                      # => BigNum

Returns the inverse hyperbolic sine of C<x>.

=cut

sub asinh {
    my $r = _big2mpfr($_[0]);
    Math::MPFR::Rmpfr_asinh($r, $r, $ROUND);
    _mpfr2big($r);
}

=head2 cos

    $x->cos                        # => BigNum

Returns the cosine of C<x>.

=cut

sub cos {
    my $r = _big2mpfr($_[0]);
    Math::MPFR::Rmpfr_cos($r, $r, $ROUND);
    _mpfr2big($r);
}

=head2 acos

    $x->acos                       # => BigNum | Nan

Returns the inverse cosine of C<x>.
Returns Nan for x < -1 or x > 1.

=cut

sub acos {
    my ($x) = @_;
    my $r = _big2mpfr($x);
    Math::MPFR::Rmpfr_acos($r, $r, $ROUND);
    _mpfr2big($r);
}

=head2 cosh

    $x->cosh                       # => BigNum

Returns the hyperbolic cosine of C<x>.

=cut

sub cosh {
    my $r = _big2mpfr($_[0]);
    Math::MPFR::Rmpfr_cosh($r, $r, $ROUND);
    _mpfr2big($r);
}

=head2 acosh

    $x->acosh                      # => BigNum | Nan

Returns the inverse hyperbolic cosine of C<x>.
Returns Nan for x < 1.

=cut

sub acosh {
    my ($x) = @_;
    my $r = _big2mpfr($x);
    Math::MPFR::Rmpfr_acosh($r, $r, $ROUND);
    _mpfr2big($r);
}

=head2 tan

    $x->tan                        # => BigNum

Returns the tangent of C<x>.

=cut

sub tan {
    my $r = _big2mpfr($_[0]);
    Math::MPFR::Rmpfr_tan($r, $r, $ROUND);
    _mpfr2big($r);
}

=head2 atan

    $x->atan                       # => BigNum

Returns the inverse tangent of C<x>.

=cut

sub atan {
    my $r = _big2mpfr($_[0]);
    Math::MPFR::Rmpfr_atan($r, $r, $ROUND);
    _mpfr2big($r);
}

=head2 tanh

    $x->tanh                       # => BigNum

Returns the hyperbolic tangent of C<x>.

=cut

sub tanh {
    my $r = _big2mpfr($_[0]);
    Math::MPFR::Rmpfr_tanh($r, $r, $ROUND);
    _mpfr2big($r);
}

=head2 atanh

    $x->atanh                      # => BigNum | Nan

Returns the inverse hyperbolic tangent of C<x>.
Returns Nan for x <= -1 or x >= 1.

=cut

sub atanh {
    my ($x) = @_;
    my $r = _big2mpfr($x);
    Math::MPFR::Rmpfr_atanh($r, $r, $ROUND);
    _mpfr2big($r);
}

=head2 sec

    $x->sec                        # => BigNum

Returns the secant of C<x>.

=cut

sub sec {
    my $r = _big2mpfr($_[0]);
    Math::MPFR::Rmpfr_sec($r, $r, $ROUND);
    _mpfr2big($r);
}

=head2 asec

    $x->asec                       # => BigNum | Nan

Returns the inverse secant of C<x>.
Returns Nan for x > -1 and x < 1.

Defined as:

    asec(x) = acos(1/x)

=cut

#
## asec(x) = acos(1/x)
#
sub asec {
    my ($x) = @_;
    my $r = _big2mpfr($x);
    Math::MPFR::Rmpfr_ui_div($r, 1, $r, $ROUND);
    Math::MPFR::Rmpfr_acos($r, $r, $ROUND);
    _mpfr2big($r);
}

=head2 sech

    $x->sech                       # => BigNum

Returns the hyperbolic secant of C<x>.

=cut

sub sech {
    my $r = _big2mpfr($_[0]);
    Math::MPFR::Rmpfr_sech($r, $r, $ROUND);
    _mpfr2big($r);
}

=head2 asech

    $x->asech                      # => BigNum | Nan

Returns the inverse hyperbolic secant of C<x>.
Returns a Nan for x < 0 or x > 1.

Defined as:

    asech(x) = acosh(1/x)

=cut

#
## asech(x) = acosh(1/x)
#
sub asech {
    my ($x) = @_;
    my $r = _big2mpfr($x);
    Math::MPFR::Rmpfr_ui_div($r, 1, $r, $ROUND);
    Math::MPFR::Rmpfr_acosh($r, $r, $ROUND);
    _mpfr2big($r);
}

=head2 csc

    $x->csc                        # => BigNum

Returns the cosecant of C<x>.

=cut

sub csc {
    my $r = _big2mpfr($_[0]);
    Math::MPFR::Rmpfr_csc($r, $r, $ROUND);
    _mpfr2big($r);
}

=head2 acsc

    $x->acsc                       # => BigNum | Nan

Returns the inverse cosecant of C<x>.
Returns Nan for x > -1 and x < 1.

Defined as:

    acsc(x) = asin(1/x)

=cut

#
## acsc(x) = asin(1/x)
#
sub acsc {
    my ($x) = @_;
    my $r = _big2mpfr($x);
    Math::MPFR::Rmpfr_ui_div($r, 1, $r, $ROUND);
    Math::MPFR::Rmpfr_asin($r, $r, $ROUND);
    _mpfr2big($r);
}

=head2 csch

    $x->csch                       # => BigNum

Returns the hyperbolic cosecant of C<x>.

=cut

sub csch {
    my $r = _big2mpfr($_[0]);
    Math::MPFR::Rmpfr_csch($r, $r, $ROUND);
    _mpfr2big($r);
}

=head2 acsch

    $x->acsch                      # => BigNum

Returns the inverse hyperbolic cosecant of C<x>.

Defined as:

    acsch(x) = asinh(1/x)

=cut

#
## acsch(x) = asinh(1/x)
#
sub acsch {
    my ($x) = @_;
    my $r = _big2mpfr($x);
    Math::MPFR::Rmpfr_ui_div($r, 1, $r, $ROUND);
    Math::MPFR::Rmpfr_asinh($r, $r, $ROUND);
    _mpfr2big($r);
}

=head2 cot

    $x->cot                        # => BigNum

Returns the cotangent of C<x>.

=cut

sub cot {
    my $r = _big2mpfr($_[0]);
    Math::MPFR::Rmpfr_cot($r, $r, $ROUND);
    _mpfr2big($r);
}

=head2 acot

    $x->acot                       # => BigNum

Returns the inverse cotangent of C<x>.

Defined as:

    acot(x) = atan(1/x)

=cut

#
## acot(x) = atan(1/x)
#
sub acot {
    my ($x) = @_;
    my $r = _big2mpfr($x);
    Math::MPFR::Rmpfr_ui_div($r, 1, $r, $ROUND);
    Math::MPFR::Rmpfr_atan($r, $r, $ROUND);
    _mpfr2big($r);
}

=head2 coth

    $x->coth                       # => BigNum

Returns the hyperbolic cotangent of C<x>.

=cut

sub coth {
    my $r = _big2mpfr($_[0]);
    Math::MPFR::Rmpfr_coth($r, $r, $ROUND);
    _mpfr2big($r);
}

=head2 acoth

    $x->acoth                      # => BigNum

Returns the inverse hyperbolic cotangent of C<x>.

Defined as:

    acoth(x) = atanh(1/x)

=cut

#
## acoth(x) = atanh(1/x)
#
sub acoth {
    my $r = _big2mpfr($_[0]);
    Math::MPFR::Rmpfr_ui_div($r, 1, $r, $ROUND);
    Math::MPFR::Rmpfr_atanh($r, $r, $ROUND);
    _mpfr2big($r);
}

=head2 atan2

    $x->atan2(BigNum)              # => BigNum
    $x->atan2(Scalar)              # => BigNum

    atan2(BigNum, BigNum)          # => BigNum
    atan2(BigNum, Scalar)          # => BigNum
    atan2(Scalar, BigNum)          # => BigNum

Arctangent of C<x> and C<y>. When C<y> is -Inf returns PI when x >= 0, or C<-PI> when x < 0.

=cut

Class::Multimethods::multimethod atan2 => qw(Math::BigNum Math::BigNum) => sub {
    my $r = _big2mpfr($_[0]);
    Math::MPFR::Rmpfr_atan2($r, $r, _big2mpfr($_[1]), $ROUND);
    _mpfr2big($r);
};

Class::Multimethods::multimethod atan2 => qw(Math::BigNum $) => sub {
    my $f = _str2mpfr($_[1]) // return $_[0]->atan2(Math::BigNum->new($_[1]));
    my $r = _big2mpfr($_[0]);
    Math::MPFR::Rmpfr_atan2($r, $r, $f, $ROUND);
    _mpfr2big($r);
};

Class::Multimethods::multimethod atan2 => qw($ Math::BigNum) => sub {
    my $r = _str2mpfr($_[0]) // return Math::BigNum->new($_[0])->atan2($_[1]);
    Math::MPFR::Rmpfr_atan2($r, $r, _big2mpfr($_[1]), $ROUND);
    _mpfr2big($r);
};

Class::Multimethods::multimethod atan2 => qw(* Math::BigNum) => sub {
    Math::BigNum->new($_[0])->atan2($_[1]);
};

Class::Multimethods::multimethod atan2 => qw(Math::BigNum *) => sub {
    $_[0]->atan2(Math::BigNum->new($_[1]));
};

Class::Multimethods::multimethod atan2 => qw(Math::BigNum Math::BigNum::Inf) => sub {
    $_[1]->is_neg
      ? ((Math::GMPq::Rmpq_sgn(${$_[0]}) >= 0) ? pi() : (pi()->neg))
      : zero;
};

Class::Multimethods::multimethod atan2 => qw(Math::BigNum Math::BigNum::Nan) => \&nan;

=head1 * Special methods

=cut

=head2 agm

    $x->agm(BigNum)                # => BigNum
    $x->agm(Scalar)                # => BigNum

Arithmetic-geometric mean of C<x> and C<y>.

=cut

Class::Multimethods::multimethod agm => qw(Math::BigNum Math::BigNum) => sub {
    my $r = _big2mpfr($_[0]);
    Math::MPFR::Rmpfr_agm($r, $r, _big2mpfr($_[1]), $ROUND);
    _mpfr2big($r);
};

Class::Multimethods::multimethod agm => qw(Math::BigNum $) => sub {
    my $f = _str2mpfr($_[1]) // return $_[0]->agm(Math::BigNum->new($_[1]));
    my $r = _big2mpfr($_[0]);
    Math::MPFR::Rmpfr_agm($r, $r, $f, $ROUND);
    _mpfr2big($r);
};

Class::Multimethods::multimethod agm => qw(Math::BigNum *) => sub {
    $_[0]->agm(Math::BigNum->new($_[1]));
};

Class::Multimethods::multimethod agm => qw(Math::BigNum Math::BigNum::Inf) => sub {
    $_[1]->is_pos ? $_[1]->copy : nan();
};

Class::Multimethods::multimethod agm => qw(Math::BigNum Math::BigNum::Nan) => \&nan;

=head2 hypot

    $x->hypot(BigNum)              # => BigNum
    $x->hypot(Scalar)              # => BigNum

The value of the hypotenuse for catheti C<x> and C<y>. (C<sqrt(x^2 + y^2)>)

=cut

Class::Multimethods::multimethod hypot => qw(Math::BigNum Math::BigNum) => sub {
    my $r = _big2mpfr($_[0]);
    Math::MPFR::Rmpfr_hypot($r, $r, _big2mpfr($_[1]), $ROUND);
    _mpfr2big($r);
};

Class::Multimethods::multimethod hypot => qw(Math::BigNum $) => sub {
    my $f = _str2mpfr($_[1]) // return $_[0]->hypot(Math::BigNum->new($_[1]));
    my $r = _big2mpfr($_[0]);
    Math::MPFR::Rmpfr_hypot($r, $r, $f, $ROUND);
    _mpfr2big($r);
};

Class::Multimethods::multimethod hypot => qw(Math::BigNum *) => sub {
    $_[0]->hypot(Math::BigNum->new($_[1]));
};

Class::Multimethods::multimethod hypot => qw(Math::BigNum Math::BigNum::Inf) => \&inf;
Class::Multimethods::multimethod hypot => qw(Math::BigNum Math::BigNum::Nan) => \&nan;

=head2 gamma

    $x->gamma                      # => BigNum | Inf | Nan

The Gamma function on C<x>. Returns Inf when C<x> is zero, and Nan when C<x> is negative.

=cut

sub gamma {
    my $r = _big2mpfr($_[0]);
    Math::MPFR::Rmpfr_gamma($r, $r, $ROUND);
    _mpfr2big($r);
}

=head2 lngamma

    $x->lngamma                    # => BigNum | Inf

The natural logarithm of the Gamma function on C<x>.
Returns Inf when C<x> is negative or equal to zero.

=cut

sub lngamma {
    my $r = _big2mpfr($_[0]);
    Math::MPFR::Rmpfr_lngamma($r, $r, $ROUND);
    _mpfr2big($r);
}

=head2 lgamma

    $x->lgamma                     # => BigNum | Inf

The logarithm of the absolute value of the Gamma function.
Returns Inf when C<x> is negative or equal to zero.

=cut

sub lgamma {
    my $r = _big2mpfr($_[0]);
    Math::MPFR::Rmpfr_lgamma($r, $r, $ROUND);
    _mpfr2big($r);
}

=head2 digamma

    $x->digamma                    # => BigNum | Inf | Nan

The Digamma function (sometimes also called Psi).
Returns Nan when C<x> is negative, and -Inf when C<x> is 0.

=cut

sub digamma {
    my $r = _big2mpfr($_[0]);
    Math::MPFR::Rmpfr_digamma($r, $r, $ROUND);
    _mpfr2big($r);
}

=head2 beta

    $x->beta(BigNum)               # => BigNum | Inf | Nan

The beta function (also called the Euler integral of the first kind).

Defined as:

    beta(x,y) = gamma(x)*gamma(y) / gamma(x+y)

for x > 0 and y > 0.

=cut

Class::Multimethods::multimethod beta => qw(Math::BigNum Math::BigNum) => sub {
    my ($x, $y) = @_;

    $x = _big2mpfr($x);
    $y = _big2mpfr($y);

    my $t = Math::MPFR::Rmpfr_init2($PREC);
    Math::MPFR::Rmpfr_add($t, $x, $y, $ROUND);
    Math::MPFR::Rmpfr_gamma($t, $t, $ROUND);
    Math::MPFR::Rmpfr_gamma($x, $x, $ROUND);
    Math::MPFR::Rmpfr_gamma($y, $y, $ROUND);
    Math::MPFR::Rmpfr_mul($x, $x, $y, $ROUND);
    Math::MPFR::Rmpfr_div($x, $x, $t, $ROUND);

    _mpfr2big($x);
};

Class::Multimethods::multimethod beta => qw(Math::BigNum *) => sub {
    Math::BigNum->new($_[1])->beta($_[0]);
};

Class::Multimethods::multimethod beta => qw(Math::BigNum Math::BigNum::Inf) => \&nan;
Class::Multimethods::multimethod beta => qw(Math::BigNum Math::BigNum::Nan) => \&nan;

=head2 zeta

    $x->zeta                       # => BigNum | Inf

The Riemann zeta function at C<x>. Returns Inf when C<x> is 1.

=cut

sub zeta {
    my $r = _big2mpfr($_[0]);
    Math::MPFR::Rmpfr_zeta($r, $r, $ROUND);
    _mpfr2big($r);
}

=head2 eta

    $x->eta                        # => BigNum

The Dirichlet eta function at C<x>.

Defined as:

    eta(1) = ln(2)
    eta(x) = (1 - 2**(1-x)) * zeta(x)

=cut

sub eta {
    my $r = _big2mpfr($_[0]);

    # Special case for eta(1) = log(2)
    if (!Math::MPFR::Rmpfr_cmp_ui($r, 1)) {
        Math::MPFR::Rmpfr_add_ui($r, $r, 1, $ROUND);
        Math::MPFR::Rmpfr_log($r, $r, $ROUND);
        return _mpfr2big($r);
    }

    my $p = Math::MPFR::Rmpfr_init2($PREC);
    Math::MPFR::Rmpfr_set($p, $r, $ROUND);
    Math::MPFR::Rmpfr_ui_sub($p, 1, $p, $ROUND);
    Math::MPFR::Rmpfr_ui_pow($p, 2, $p, $ROUND);
    Math::MPFR::Rmpfr_ui_sub($p, 1, $p, $ROUND);

    Math::MPFR::Rmpfr_zeta($r, $r, $ROUND);
    Math::MPFR::Rmpfr_mul($r, $r, $p, $ROUND);

    _mpfr2big($r);
}

=head2 bessel_j

    $x->bessel_j(BigNum)           # => BigNum
    $x->bessel_j(Scalar)           # => BigNum

The first order Bessel function, C<J_n(x)>, where C<n> is a signed integer.

Example:

    $x->bessel_j($n)               # represents J_n(x)

=cut

Class::Multimethods::multimethod bessel_j => qw(Math::BigNum Math::BigNum) => sub {
    my ($x, $n) = @_;

    $n = Math::GMPq::Rmpq_get_d($$n);

    if ($n < LONG_MIN or $n > ULONG_MAX) {
        return zero();
    }

    $n = CORE::int($n);
    $x = _big2mpfr($x);

    if ($n == 0) {
        Math::MPFR::Rmpfr_j0($x, $x, $ROUND);
    }
    elsif ($n == 1) {
        Math::MPFR::Rmpfr_j1($x, $x, $ROUND);
    }
    else {
        Math::MPFR::Rmpfr_jn($x, $n, $x, $ROUND);
    }

    _mpfr2big($x);
};

Class::Multimethods::multimethod bessel_j => qw(Math::BigNum $) => sub {
    my ($x, $n) = @_;

    if (CORE::int($n) eq $n) {

        if ($n < LONG_MIN or $n > ULONG_MAX) {
            return zero();
        }

        $x = _big2mpfr($x);

        if ($n == 0) {
            Math::MPFR::Rmpfr_j0($x, $x, $ROUND);
        }
        elsif ($n == 1) {
            Math::MPFR::Rmpfr_j1($x, $x, $ROUND);
        }
        else {
            Math::MPFR::Rmpfr_jn($x, $n, $x, $ROUND);
        }
        _mpfr2big($x);
    }
    else {
        $x->bessel_j(Math::BigNum->new($n));
    }
};

Class::Multimethods::multimethod bessel_j => qw(Math::BigNum *) => sub {
    $_[0]->bessel_j(Math::BigNum->new($_[1]));
};

Class::Multimethods::multimethod bessel_j => qw(Math::BigNum Math::BigNum::Inf) => \&zero;
Class::Multimethods::multimethod bessel_j => qw(Math::BigNum Math::BigNum::Nan) => \&nan;

=head2 bessel_y

    $x->bessel_y(BigNum)           # => BigNum | Inf | Nan
    $x->bessel_y(Scalar)           # => BigNum | Inf | Nan

The second order Bessel function, C<Y_n(x)>, where C<n> is a signed integer. Returns Nan for negative values of C<x>.

Example:

    $x->bessel_y($n)               # represents Y_n(x)

=cut

Class::Multimethods::multimethod bessel_y => qw(Math::BigNum Math::BigNum) => sub {
    my ($x, $n) = @_;

    $n = Math::GMPq::Rmpq_get_d($$n);

    if ($n < LONG_MIN or $n > ULONG_MAX) {

        if (Math::GMPq::Rmpq_sgn($$x) < 0) {
            return nan();
        }

        return ($n < 0 ? inf() : ninf());
    }

    $x = _big2mpfr($x);
    $n = CORE::int($n);

    if ($n == 0) {
        Math::MPFR::Rmpfr_y0($x, $x, $ROUND);
    }
    elsif ($n == 1) {
        Math::MPFR::Rmpfr_y1($x, $x, $ROUND);
    }
    else {
        Math::MPFR::Rmpfr_yn($x, $n, $x, $ROUND);
    }

    _mpfr2big($x);
};

Class::Multimethods::multimethod bessel_y => qw(Math::BigNum $) => sub {
    my ($x, $n) = @_;

    if (CORE::int($n) eq $n) {

        if ($n < LONG_MIN or $n > ULONG_MAX) {

            if (Math::GMPq::Rmpq_sgn($$x) < 0) {
                return nan();
            }

            return ($n < 0 ? inf() : ninf());
        }

        $x = _big2mpfr($x);

        if ($n == 0) {
            Math::MPFR::Rmpfr_y0($x, $x, $ROUND);
        }
        elsif ($n == 1) {
            Math::MPFR::Rmpfr_y1($x, $x, $ROUND);
        }
        else {
            Math::MPFR::Rmpfr_yn($x, $n, $x, $ROUND);
        }
        _mpfr2big($x);
    }
    else {
        $x->bessel_y(Math::BigNum->new($n));
    }
};

Class::Multimethods::multimethod bessel_y => qw(Math::BigNum *) => sub {
    $_[0]->bessel_y(Math::BigNum->new($_[1]));
};

Class::Multimethods::multimethod bessel_y => qw(Math::BigNum Math::BigNum::Inf) => sub {
    Math::GMPq::Rmpq_sgn(${$_[0]}) < 0 ? nan() : $_[1]->neg;
};

Class::Multimethods::multimethod bessel_y => qw(Math::BigNum Math::BigNum::Nan) => \&nan;

=head2 bernreal

    $n->bernreal                   # => BigNum | Nan

Returns the nth-Bernoulli number, as a floating-point approximation, with C<bernreal(0) = 1>.

Returns Nan for negative values of C<n>.

=cut

sub bernreal {
    my $n = CORE::int(Math::GMPq::Rmpq_get_d(${$_[0]}));

    # |B(n)| = zeta(n) * n! / 2^(n-1) / pi^n

    $n < 0  and return nan();
    $n == 0 and return one();
    $n == 1 and return Math::BigNum->new('1/2');
    $n % 2  and return zero();                     # Bn = 0 for odd n>1

    #local $PREC = CORE::int($n*CORE::log($n)+1);

    my $f = Math::MPFR::Rmpfr_init2($PREC);
    my $p = Math::MPFR::Rmpfr_init2($PREC);

    Math::MPFR::Rmpfr_zeta_ui($f, $n, $ROUND);     # f = zeta(n)
    Math::MPFR::Rmpfr_const_pi($p, $ROUND);        # p = PI
    Math::MPFR::Rmpfr_pow_ui($p, $p, $n, $ROUND);  # p = p^n

    my $z = Math::GMPz::Rmpz_init();
    Math::GMPz::Rmpz_fac_ui($z, $n);               # z = n!
    Math::MPFR::Rmpfr_mul_z($f, $f, $z, $ROUND);   # f = f * z
    Math::MPFR::Rmpfr_div_2exp($f, $f, $n - 1, $ROUND);    # f = f / 2^(n-1)

    Math::MPFR::Rmpfr_div($f, $f, $p, $ROUND);             # f = f/p
    Math::MPFR::Rmpfr_neg($f, $f, $ROUND) if $n % 4 == 0;

    _mpfr2big($f);
}

=head2 harmreal

    $n->harmreal                   # => BigNum | Nan

Returns the nth-Harmonic number, as a floating-point approximation, for any real value of C<n> >= 0.

Defined as:

    harmreal(n) = digamma(n+1) + gamma

where C<gamma> is the Euler-Mascheroni constant.

=cut

sub harmreal {
    my ($n) = @_;

    $n = _big2mpfr($n);
    Math::MPFR::Rmpfr_add_ui($n, $n, 1, $ROUND);
    Math::MPFR::Rmpfr_digamma($n, $n, $ROUND);

    my $y = Math::MPFR::Rmpfr_init2($PREC);
    Math::MPFR::Rmpfr_const_euler($y, $ROUND);
    Math::MPFR::Rmpfr_add($n, $n, $y, $ROUND);

    _mpfr2big($n);
}

=head2 erf

    $x->erf                        # => BigNum

The error function on C<x>.

=cut

sub erf {
    my $r = _big2mpfr($_[0]);
    Math::MPFR::Rmpfr_erf($r, $r, $ROUND);
    _mpfr2big($r);
}

=head2 erfc

    $x->erfc                       # => BigNum

Complementary error function on C<x>.

=cut

sub erfc {
    my $r = _big2mpfr($_[0]);
    Math::MPFR::Rmpfr_erfc($r, $r, $ROUND);
    _mpfr2big($r);
}

=head2 eint

    $x->eint                       # => BigNum | Inf | Nan

Exponential integral of C<x>. Returns -Inf when C<x> is zero, and Nan when C<x> is negative.

=cut

sub eint {
    my $r = _big2mpfr($_[0]);
    Math::MPFR::Rmpfr_eint($r, $r, $ROUND);
    _mpfr2big($r);
}

=head2 li

    $x->li                         # => BigNum | Inf | Nan

The logarithmic integral of C<x>, defined as: C<Ei(ln(x))>.
Returns -Inf when C<x> is 1, and Nan when C<x> is less than or equal to 0.

=cut

sub li {
    my $r = _big2mpfr($_[0]);
    Math::MPFR::Rmpfr_log($r, $r, $ROUND);
    Math::MPFR::Rmpfr_eint($r, $r, $ROUND);
    _mpfr2big($r);
}

=head2 li2

    $x->li2                        # => BigNum

The dilogarithm function, defined as the integral of C<-log(1-t)/t> from 0 to C<x>.

=cut

sub li2 {
    my $r = _big2mpfr($_[0]);
    Math::MPFR::Rmpfr_li2($r, $r, $ROUND);
    _mpfr2big($r);
}

############################ INTEGER OPERATIONS ############################

=head1 INTEGER OPERATIONS

All the operations in this section are done with integers.

=cut

=head2 iadd

    $x->iadd(BigNum)               # => BigNum
    $x->iadd(Scalar)               # => BigNum

Integer addition of C<y> to C<x>. Both values
are truncated to integers before addition.

=cut

Class::Multimethods::multimethod iadd => qw(Math::BigNum Math::BigNum) => sub {
    my $r = _big2mpz($_[0]);
    Math::GMPz::Rmpz_add($r, $r, _big2mpz($_[1]));
    _mpz2big($r);
};

Class::Multimethods::multimethod iadd => qw(Math::BigNum $) => sub {
    my ($x, $y) = @_;

    if (CORE::int($y) eq $y and $y >= LONG_MIN and $y <= ULONG_MAX) {
        my $r = _big2mpz($x);
        $y < 0
          ? Math::GMPz::Rmpz_sub_ui($r, $r, -$y)
          : Math::GMPz::Rmpz_add_ui($r, $r, $y);
        _mpz2big($r);
    }
    else {
        Math::BigNum->new($y)->biadd($x);
    }
};

Class::Multimethods::multimethod iadd => qw(Math::BigNum *) => sub {
    Math::BigNum->new($_[1])->biadd($_[0]);
};

Class::Multimethods::multimethod iadd => qw(Math::BigNum Math::BigNum::Inf) => sub { $_[1] };
Class::Multimethods::multimethod iadd => qw(Math::BigNum Math::BigNum::Nan) => \&nan;

=head2 biadd

    $x->biadd(BigNum)              # => BigNum
    $x->biadd(Scalar)              # => BigNum

Integer addition of C<y> from C<x>, changing C<x> in-place.
Both values are truncated to integers before addition.

=cut

Class::Multimethods::multimethod biadd => qw(Math::BigNum Math::BigNum) => sub {
    my $r = _big2mpz($_[0]);
    Math::GMPz::Rmpz_add($r, $r, _big2mpz($_[1]));
    Math::GMPq::Rmpq_set_z(${$_[0]}, $r);
    $_[0];
};

Class::Multimethods::multimethod biadd => qw(Math::BigNum $) => sub {
    my ($x, $y) = @_;

    if (CORE::int($y) eq $y and $y >= LONG_MIN and $y <= ULONG_MAX) {
        my $r = _big2mpz($x);
        $y < 0
          ? Math::GMPz::Rmpz_sub_ui($r, $r, -$y)
          : Math::GMPz::Rmpz_add_ui($r, $r, $y);
        Math::GMPq::Rmpq_set_z(${$x}, $r);
        $x;
    }
    else {
        $x->biadd(Math::BigNum->new($y));
    }
};

Class::Multimethods::multimethod biadd => qw(Math::BigNum *) => sub {
    $_[0]->biadd(Math::BigNum->new($_[1]));
};

Class::Multimethods::multimethod biadd => qw(Math::BigNum Math::BigNum::Inf) => \&_big2inf;
Class::Multimethods::multimethod biadd => qw(Math::BigNum Math::BigNum::Nan) => \&bnan;

=head2 isub

    $x->isub(BigNum)               # => BigNum
    $x->isub(Scalar)               # => BigNum

Integer subtraction of C<y> from C<x>. Both values
are truncated to integers before subtraction.

=cut

Class::Multimethods::multimethod isub => qw(Math::BigNum Math::BigNum) => sub {
    my $r = _big2mpz($_[0]);
    Math::GMPz::Rmpz_sub($r, $r, _big2mpz($_[1]));
    _mpz2big($r);
};

Class::Multimethods::multimethod isub => qw(Math::BigNum $) => sub {
    my ($x, $y) = @_;

    if (CORE::int($y) eq $y and $y >= LONG_MIN and $y <= ULONG_MAX) {
        my $r = _big2mpz($x);
        $y < 0
          ? Math::GMPz::Rmpz_add_ui($r, $r, -$y)
          : Math::GMPz::Rmpz_sub_ui($r, $r, $y);
        _mpz2big($r);
    }
    else {
        Math::BigNum->new($y)->bneg->biadd($x);
    }
};

Class::Multimethods::multimethod isub => qw(Math::BigNum *) => sub {
    Math::BigNum->new($_[1])->bneg->biadd($_[0]);
};

Class::Multimethods::multimethod isub => qw(Math::BigNum Math::BigNum::Inf) => sub { $_[1]->neg };
Class::Multimethods::multimethod isub => qw(Math::BigNum Math::BigNum::Nan) => \&nan;

=head2 bisub

    $x->bisub(BigNum)              # => BigNum
    $x->bisub(Scalar)              # => BigNum

Integer subtraction of C<y> from x, changing C<x> in-place.
Both values are truncated to integers before subtraction.

=cut

Class::Multimethods::multimethod bisub => qw(Math::BigNum Math::BigNum) => sub {
    my $r = _big2mpz($_[0]);
    Math::GMPz::Rmpz_sub($r, $r, _big2mpz($_[1]));
    Math::GMPq::Rmpq_set_z(${$_[0]}, $r);
    $_[0];
};

Class::Multimethods::multimethod bisub => qw(Math::BigNum $) => sub {
    my ($x, $y) = @_;

    if (CORE::int($y) eq $y and $y >= LONG_MIN and $y <= ULONG_MAX) {
        my $r = _big2mpz($x);
        $y < 0
          ? Math::GMPz::Rmpz_add_ui($r, $r, -$y)
          : Math::GMPz::Rmpz_sub_ui($r, $r, $y);
        Math::GMPq::Rmpq_set_z(${$x}, $r);
        $x;
    }
    else {
        $x->bisub(Math::BigNum->new($y));
    }
};

Class::Multimethods::multimethod bisub => qw(Math::BigNum *) => sub {
    $_[0]->bisub(Math::BigNum->new($_[1]));
};

Class::Multimethods::multimethod bisub => qw(Math::BigNum Math::BigNum::Inf) => \&_big2ninf;
Class::Multimethods::multimethod bisub => qw(Math::BigNum Math::BigNum::Nan) => \&bnan;

=head2 imul

    $x->imul(BigNum)               # => BigNum
    $x->imul(Scalar)               # => BigNum

Integer multiplication of C<x> by C<y>. Both values
are truncated to integers before multiplication.

=cut

Class::Multimethods::multimethod imul => qw(Math::BigNum Math::BigNum) => sub {
    my $r = _big2mpz($_[0]);
    Math::GMPz::Rmpz_mul($r, $r, _big2mpz($_[1]));
    _mpz2big($r);
};

Class::Multimethods::multimethod imul => qw(Math::BigNum $) => sub {
    my ($x, $y) = @_;

    if (CORE::int($y) eq $y and $y >= LONG_MIN and $y <= ULONG_MAX) {
        my $r = _big2mpz($x);
        $y < 0
          ? Math::GMPz::Rmpz_mul_si($r, $r, $y)
          : Math::GMPz::Rmpz_mul_ui($r, $r, $y);
        _mpz2big($r);
    }
    else {
        Math::BigNum->new($y)->bimul($x);
    }
};

Class::Multimethods::multimethod imul => qw(Math::BigNum *) => sub {
    Math::BigNum->new($_[1])->bimul($_[0]);
};

Class::Multimethods::multimethod imul => qw(Math::BigNum Math::BigNum::Inf) => sub {
    my $sign = Math::GMPq::Rmpq_sgn(${$_[0]});
    $sign < 0 ? $_[1]->neg : $sign > 0 ? $_[1]->copy : nan;
};

Class::Multimethods::multimethod imul => qw(Math::BigNum Math::BigNum::Nan) => \&nan;

=head2 bimul

    $x->bimul(BigNum)              # => BigNum
    $x->bimul(Scalar)              # => BigNum

Integer multiplication of C<x> by C<y>, changing C<x> in-place.
Both values are truncated to integers before multiplication.

=cut

Class::Multimethods::multimethod bimul => qw(Math::BigNum Math::BigNum) => sub {
    my $r = _big2mpz($_[0]);
    Math::GMPz::Rmpz_mul($r, $r, _big2mpz($_[1]));
    Math::GMPq::Rmpq_set_z(${$_[0]}, $r);
    $_[0];
};

Class::Multimethods::multimethod bimul => qw(Math::BigNum $) => sub {
    my ($x, $y) = @_;

    if (CORE::int($y) eq $y and $y >= LONG_MIN and $y <= ULONG_MAX) {
        my $r = _big2mpz($x);
        $y < 0
          ? Math::GMPz::Rmpz_mul_si($r, $r, $y)
          : Math::GMPz::Rmpz_mul_ui($r, $r, $y);
        Math::GMPq::Rmpq_set_z(${$x}, $r);
        $x;
    }
    else {
        $x->bimul(Math::BigNum->new($y));
    }
};

Class::Multimethods::multimethod bimul => qw(Math::BigNum *) => sub {
    $_[0]->bimul(Math::BigNum->new($_[1]));
};

Class::Multimethods::multimethod bimul => qw(Math::BigNum Math::BigNum::Inf) => sub {
    my ($x) = @_;
    my $sign = Math::GMPq::Rmpq_sgn($$x);
    $sign < 0 ? _big2ninf(@_) : $sign > 0 ? _big2inf(@_) : $x->bnan;
};

Class::Multimethods::multimethod bimul => qw(Math::BigNum Math::BigNum::Nan) => \&bnan;

=head2 idiv

    $x->idiv(BigNum)               # => BigNum | Nan | Inf
    $x->idiv(Scalar)               # => BigNum | Nan | Inf

Integer division of C<x> by C<y>.

=cut

Class::Multimethods::multimethod idiv => qw(Math::BigNum Math::BigNum) => sub {
    my ($x, $y) = @_;

    $y = _big2mpz($y);
    my $r = _big2mpz($x);

    if (!Math::GMPz::Rmpz_sgn($y)) {
        my $sign = Math::GMPz::Rmpz_sgn($r);
        return (!$sign ? nan : $sign > 0 ? inf : ninf);
    }

    Math::GMPz::Rmpz_div($r, $r, $y);
    _mpz2big($r);
};

Class::Multimethods::multimethod idiv => qw(Math::BigNum $) => sub {
    my ($x, $y) = @_;

    if (CORE::int($y) eq $y and $y >= LONG_MIN and $y <= ULONG_MAX) {

        my $r = _big2mpz($x);

        # When `y` is zero, return +/-Inf or NaN
        $y || do {
            my $sign = Math::GMPz::Rmpz_sgn($r);
            return (
                      $sign > 0 ? inf
                    : $sign < 0 ? ninf
                    :             nan
                   );
        };

        Math::GMPz::Rmpz_div_ui($r, $r, CORE::abs($y));
        Math::GMPz::Rmpz_neg($r, $r) if $y < 0;
        _mpz2big($r);
    }
    else {
        $x->idiv(Math::BigNum->new($y));
    }
};

Class::Multimethods::multimethod idiv => qw(Math::BigNum *) => sub {
    $_[0]->idiv(Math::BigNum->new($_[1]));
};

Class::Multimethods::multimethod idiv => qw(Math::BigNum Math::BigNum::Inf) => \&zero;
Class::Multimethods::multimethod idiv => qw(Math::BigNum Math::BigNum::Nan) => \&nan;

=head2 bidiv

    $x->bidiv(BigNum)              # => BigNum | Nan | Inf
    $x->bidiv(Scalar)              # => BigNum | Nan | Inf

Integer division of C<x> by C<y>, changing C<x> in-place.

=cut

Class::Multimethods::multimethod bidiv => qw(Math::BigNum Math::BigNum) => sub {
    my ($x, $y) = @_;

    $y = _big2mpz($y);
    my $r = _big2mpz($x);

    if (!Math::GMPz::Rmpz_sgn($y)) {
        my $sign = Math::GMPz::Rmpz_sgn($r);
        return
            $sign > 0 ? $x->binf
          : $sign < 0 ? $x->bninf
          :             $x->bnan;
    }

    Math::GMPz::Rmpz_div($r, $r, $y);
    Math::GMPq::Rmpq_set_z($$x, $r);
    $x;
};

Class::Multimethods::multimethod bidiv => qw(Math::BigNum $) => sub {
    my ($x, $y) = @_;

    if (CORE::int($y) eq $y and $y >= LONG_MIN and $y <= ULONG_MAX) {

        my $r = _big2mpz($x);

        # When `y` is zero, return +/-Inf or NaN
        $y || do {
            my $sign = Math::GMPz::Rmpz_sgn($r);
            return
                $sign > 0 ? $x->binf
              : $sign < 0 ? $x->bninf
              :             $x->bnan;
        };

        Math::GMPz::Rmpz_div_ui($r, $r, CORE::abs($y));
        Math::GMPq::Rmpq_set_z($$x, $r);
        Math::GMPq::Rmpq_neg($$x, $$x) if $y < 0;
        $x;
    }
    else {
        $x->bidiv(Math::BigNum->new($y));
    }
};

Class::Multimethods::multimethod bidiv => qw(Math::BigNum *) => sub {
    $_[0]->bidiv(Math::BigNum->new($_[1]));
};

Class::Multimethods::multimethod bidiv => qw(Math::BigNum Math::BigNum::Inf) => \&bzero;
Class::Multimethods::multimethod bidiv => qw(Math::BigNum Math::BigNum::Nan) => \&bnan;

=head2 ipow

    $x->ipow(BigNum)               # => BigNum
    $x->ipow(Scalar)               # => BigNum

Raises C<x> to power C<y>, truncating C<x> and C<y> to integers, if necessarily.

=cut

Class::Multimethods::multimethod ipow => qw(Math::BigNum Math::BigNum) => sub {
    my ($x, $y) = @_;

    my $pow = CORE::int(Math::GMPq::Rmpq_get_d($$y));

    my $z = _big2mpz($x);
    Math::GMPz::Rmpz_pow_ui($z, $z, CORE::abs($pow));

    if ($pow < 0) {
        return inf() if !Math::GMPz::Rmpz_sgn($z);
        Math::GMPz::Rmpz_tdiv_q($z, $ONE_Z, $z);
    }

    _mpz2big($z);
};

Class::Multimethods::multimethod ipow => qw(Math::BigNum $) => sub {
    my ($x, $y) = @_;

    if (CORE::int($y) eq $y and $y >= LONG_MIN and $y <= ULONG_MAX) {

        my $z = _big2mpz($x);
        Math::GMPz::Rmpz_pow_ui($z, $z, CORE::abs($y));

        if ($y < 0) {
            return inf() if !Math::GMPz::Rmpz_sgn($z);
            Math::GMPz::Rmpz_tdiv_q($z, $ONE_Z, $z);
        }

        _mpz2big($z);
    }
    else {
        $x->ipow(Math::BigNum->new($y));
    }
};

Class::Multimethods::multimethod ipow => qw(Math::BigNum *) => sub {
    $_[0]->ipow(Math::BigNum->new($_[1]));
};

Class::Multimethods::multimethod ipow => qw(Math::BigNum Math::BigNum::Inf) => sub {
    $_[0]->int->pow($_[1]);
};

Class::Multimethods::multimethod ipow => qw(Math::BigNum Math::BigNum::Nan) => \&nan;

=head2 bipow

    $x->bipow(BigNum)              # => BigNum
    $x->bipow(Scalar)              # => BigNum

Raises C<x> to power C<y>, changing C<x> in-place.

=cut

Class::Multimethods::multimethod bipow => qw(Math::BigNum Math::BigNum) => sub {
    my ($x, $y) = @_;

    my $pow = CORE::int(Math::GMPq::Rmpq_get_d($$y));

    my $z = Math::GMPz::Rmpz_init();
    Math::GMPz::Rmpz_set_q($z, $$x);
    Math::GMPz::Rmpz_pow_ui($z, $z, CORE::abs($pow));

    if ($pow < 0) {
        return $x->binf if !Math::GMPz::Rmpz_sgn($z);
        Math::GMPz::Rmpz_tdiv_q($z, $ONE_Z, $z);
    }

    Math::GMPq::Rmpq_set_z($$x, $z);
    return $x;
};

Class::Multimethods::multimethod bipow => qw(Math::BigNum $) => sub {
    my ($x, $y) = @_;

    if (CORE::int($y) eq $y and $y >= LONG_MIN and $y <= ULONG_MAX) {

        my $z = Math::GMPz::Rmpz_init();
        Math::GMPz::Rmpz_set_q($z, $$x);
        Math::GMPz::Rmpz_pow_ui($z, $z, CORE::abs($y));

        if ($y < 0) {
            return $x->binf if !Math::GMPz::Rmpz_sgn($z);
            Math::GMPz::Rmpz_tdiv_q($z, $ONE_Z, $z);
        }

        Math::GMPq::Rmpq_set_z($$x, $z);
        $x;
    }
    else {
        $x->bipow(Math::BigNum->new($y));
    }
};

Class::Multimethods::multimethod bipow => qw(Math::BigNum *) => sub {
    $_[0]->bipow(Math::BigNum->new($_[1]));
};

Class::Multimethods::multimethod bipow => qw(Math::BigNum Math::BigNum::Inf) => sub {
    $_[0]->bint->bpow($_[1]);
};

Class::Multimethods::multimethod bipow => qw(Math::BigNum Math::BigNum::Nan) => \&bnan;

=head2 isqrt

    $x->isqrt                      # => BigNum | Nan

Integer square root of C<x>. Returns Nan when C<x> is negative.

=cut

sub isqrt {
    my $r = _big2mpz($_[0]);
    return nan() if Math::GMPz::Rmpz_sgn($r) < 0;
    Math::GMPz::Rmpz_sqrt($r, $r);
    _mpz2big($r);
}

=head2 bisqrt

    $x->bisqrt                     # => BigNum | Nan

Integer square root of C<x>, changing C<x> in-place. Promotes C<x> to Nan when C<x> is negative.

=cut

sub bisqrt {
    my ($x) = @_;
    my $r = _big2mpz($x);
    return $x->bnan() if Math::GMPz::Rmpz_sgn($r) < 0;
    Math::GMPz::Rmpz_sqrt($r, $r);
    Math::GMPq::Rmpq_set_z($$x, $r);
    $x;
}

=head2 isqrtrem

    $x->isqrtrem                   # => (BigNum, BigNum) | (Nan, Nan)

The integer part of the square root of C<x> and the remainder C<x - isqrt(x)**2>, which will be zero when <x> is a perfect square.

Returns (Nan,Nan) when C<x> is negative.

=cut

sub isqrtrem {
    my ($x) = @_;
    $x = _big2mpz($x);
    Math::GMPz::Rmpz_sgn($x) < 0 && return (nan(), nan());
    my $r = Math::GMPz::Rmpz_init();
    Math::GMPz::Rmpz_sqrtrem($x, $r, $x);
    (_mpz2big($x), _mpz2big($r));
}

=head2 iroot

    $x->iroot(BigNum)              # => BigNum | Nan
    $x->iroot(Scalar)              # => BigNum | Nan

Nth integer root of C<x>.

Returns Nan when C<x> is negative and C<y> is even.

=cut

Class::Multimethods::multimethod iroot => qw(Math::BigNum Math::BigNum) => sub {
    my ($x, $y) = @_;

    my $z = _big2mpz($x);

    my $root = CORE::int(Math::GMPq::Rmpq_get_d($$y));

    if ($root == 0) {
        Math::GMPz::Rmpz_sgn($z) || return zero();    # 0^Inf = 0
        Math::GMPz::Rmpz_cmpabs($z, $ONE_Z) == 0 and return one();    # 1^Inf = 1 ; (-1)^Inf = 1
        return inf();
    }
    elsif ($root < 0) {
        my $sign = Math::GMPz::Rmpz_sgn($z) || return inf();          # 1 / 0^k = Inf
        Math::GMPz::Rmpz_cmp($z, $ONE_Z) == 0 and return one();       # 1 / 1^k = 1
        return $sign < 0 ? nan() : zero();
    }
    elsif ($root % 2 == 0 and Math::GMPz::Rmpz_sgn($z) < 0) {
        return nan();
    }

    Math::GMPz::Rmpz_root($z, $z, $root);
    _mpz2big($z);
};

Class::Multimethods::multimethod iroot => qw(Math::BigNum $) => sub {
    my ($x, $y) = @_;

    if (CORE::int($y) eq $y and $y >= LONG_MIN and $y <= ULONG_MAX) {

        my $z = _big2mpz($x);

        my $root = $y;
        if ($root == 0) {
            Math::GMPz::Rmpz_sgn($z) || return zero();    # 0^Inf = 0
            Math::GMPz::Rmpz_cmpabs($z, $ONE_Z) == 0 and return one();    # 1^Inf = 1 ; (-1)^Inf = 1
            return inf();
        }
        elsif ($root < 0) {
            my $sign = Math::GMPz::Rmpz_sgn($z) || return inf();          # 1 / 0^k = Inf
            Math::GMPz::Rmpz_cmp($z, $ONE_Z) == 0 and return one();       # 1 / 1^k = 1
            return $sign < 0 ? nan() : zero();
        }
        elsif ($root % 2 == 0 and Math::GMPz::Rmpz_sgn($z) < 0) {
            return nan();
        }

        Math::GMPz::Rmpz_root($z, $z, $root);
        _mpz2big($z);
    }
    else {
        $x->iroot(Math::BigNum->new($y));
    }
};

Class::Multimethods::multimethod iroot => qw(Math::BigNum *) => sub {
    $_[0]->iroot(Math::BigNum->new($_[1]));
};

Class::Multimethods::multimethod iroot => qw(Math::BigNum Math::BigNum::Inf) => \&one;
Class::Multimethods::multimethod iroot => qw(Math::BigNum Math::BigNum::Nan) => \&nan;

=head2 biroot

    $x->biroot(BigNum)             # => BigNum | Nan
    $x->biroot(Scalar)             # => BigNum | Nan

Nth integer root of C<x>, changing C<x> in-place. Promotes
C<x> to Nan when C<x> is negative and C<y> is even.

=cut

Class::Multimethods::multimethod biroot => qw(Math::BigNum Math::BigNum) => sub {
    my ($x, $y) = @_;

    my $z = _big2mpz($x);

    my $root = CORE::int(Math::GMPq::Rmpq_get_d($$y));

    if ($root == 0) {
        Math::GMPz::Rmpz_sgn($z) || return $x->bzero();    # 0^Inf = 0
        Math::GMPz::Rmpz_cmpabs($z, $ONE_Z) == 0 and return $x->bone();    # 1^Inf = 1 ; (-1)^Inf = 1
        return $x->binf();
    }
    elsif ($root < 0) {
        my $sign = Math::GMPz::Rmpz_sgn($z) || return $x->binf();          # 1 / 0^k = Inf
        Math::GMPz::Rmpz_cmp($z, $ONE_Z) == 0 and return $x->bone();       # 1 / 1^k = 1
        return $sign < 0 ? $x->bnan() : $x->bzero();
    }
    elsif ($root % 2 == 0 and Math::GMPz::Rmpz_sgn($z) < 0) {
        return $x->bnan();
    }

    Math::GMPz::Rmpz_root($z, $z, $root);
    Math::GMPq::Rmpq_set_z($$x, $z);
    $x;
};

Class::Multimethods::multimethod biroot => qw(Math::BigNum $) => sub {
    my ($x, $y) = @_;

    if (CORE::int($y) eq $y and $y >= LONG_MIN and $y <= ULONG_MAX) {

        my $z = _big2mpz($x);

        my $root = $y;
        if ($root == 0) {
            Math::GMPz::Rmpz_sgn($z) || return $x->bzero();    # 0^Inf = 0
            Math::GMPz::Rmpz_cmpabs($z, $ONE_Z) == 0 and return $x->bone();    # 1^Inf = 1 ; (-1)^Inf = 1
            return $x->binf();
        }
        elsif ($root < 0) {
            my $sign = Math::GMPz::Rmpz_sgn($z) || return $x->binf();          # 1 / 0^k = Inf
            Math::GMPz::Rmpz_cmp($z, $ONE_Z) == 0 and return $x->bone();       # 1 / 1^k = 1
            return $sign < 0 ? $x->bnan() : $x->bzero();
        }
        elsif ($root % 2 == 0 and Math::GMPz::Rmpz_sgn($z) < 0) {
            return $x->bnan();
        }

        Math::GMPz::Rmpz_root($z, $z, $root);
        Math::GMPq::Rmpq_set_z($$x, $z);
        $x;
    }
    else {
        $x->biroot(Math::BigNum->new($y));
    }
};

Class::Multimethods::multimethod biroot => qw(Math::BigNum *) => sub {
    $_[0]->biroot(Math::BigNum->new($_[1]));
};

Class::Multimethods::multimethod biroot => qw(Math::BigNum Math::BigNum::Inf) => \&bone;
Class::Multimethods::multimethod biroot => qw(Math::BigNum Math::BigNum::Nan) => \&bnan;

=head2 irootrem

    $x->irootrem(BigNum)           # => (BigNum, BigNum) | (Nan, Nan)
    $x->irootrem(Scalar)           # => (BigNum, BigNum) | (Nan, Nan)

The nth integer part of the root of C<x> and the remainder C<x - iroot(x,y)**y>.

Returns (Nan,Nan) when C<x> is negative.

=cut

Class::Multimethods::multimethod irootrem => qw(Math::BigNum Math::BigNum) => sub {
    my ($x, $y) = @_;
    $x = _big2mpz($x);
    my $root = CORE::int(Math::GMPq::Rmpq_get_d($$y));

    if ($root == 0) {
        Math::GMPz::Rmpz_sgn($x) || return (zero(), mone());    # 0^Inf = 0
        Math::GMPz::Rmpz_cmpabs_ui($x, 1) == 0 and return (one(), _mpz2big($x)->bdec);    # 1^Inf = 1 ; (-1)^Inf = 1
        return (inf(), _mpz2big($x)->bdec);
    }
    elsif ($root < 0) {
        my $sign = Math::GMPz::Rmpz_sgn($x) || return (inf(), zero());                    # 1 / 0^k = Inf
        Math::GMPz::Rmpz_cmp_ui($x, 1) == 0 and return (one(), zero());                   # 1 / 1^k = 1
        return ($sign < 0 ? (nan(), nan()) : (zero(), ninf()));
    }
    elsif ($root % 2 == 0 and Math::GMPz::Rmpz_sgn($x) < 0) {
        return (nan(), nan());
    }

    my $r = Math::GMPz::Rmpz_init();
    Math::GMPz::Rmpz_rootrem($x, $r, $x, $root);
    (_mpz2big($x), _mpz2big($r));
};

Class::Multimethods::multimethod irootrem => qw(Math::BigNum $) => sub {
    my ($x, $y) = @_;

    if (CORE::int($y) eq $y and $y >= LONG_MIN and $y <= ULONG_MAX) {
        $x = _big2mpz($x);

        if ($y == 0) {
            Math::GMPz::Rmpz_sgn($x) || return (zero(), mone());    # 0^Inf = 0
            Math::GMPz::Rmpz_cmpabs_ui($x, 1) == 0 and return (one(), _mpz2big($x)->bdec);    # 1^Inf = 1 ; (-1)^Inf = 1
            return (inf(), _mpz2big($x)->bdec);
        }
        elsif ($y < 0) {
            my $sign = Math::GMPz::Rmpz_sgn($x) || return (inf(), zero());                    # 1 / 0^k = Inf
            Math::GMPz::Rmpz_cmp_ui($x, 1) == 0 and return (one(), zero());                   # 1 / 1^k = 1
            return ($sign < 0 ? (nan(), nan()) : (zero(), ninf()));
        }
        elsif ($y % 2 == 0 and Math::GMPz::Rmpz_sgn($x) < 0) {
            return (nan(), nan());
        }

        my $r = Math::GMPz::Rmpz_init();
        Math::GMPz::Rmpz_rootrem($x, $r, $x, $y);
        (_mpz2big($x), _mpz2big($r));
    }
    else {
        $x->irootrem(Math::BigNum->new($y));
    }
};

# Equivalent with the following definition:
#   irootrem(x, +/-Inf) = (1, x-1)
Class::Multimethods::multimethod irootrem => qw(Math::BigNum Math::BigNum::Inf) => sub {
    my ($x, $y) = @_;
    my $root = $x->iroot($y);
    ($root, $x->isub($root->bipow($y)));
};

Class::Multimethods::multimethod irootrem => qw(Math::BigNum Math::BigNum::Nan) => sub {
    (nan(), nan());
};

Class::Multimethods::multimethod irootrem => qw(Math::BigNum *) => sub {
    $_[0]->irootrem(Math::BigNum->new($_[1]));
};

=head2 imod

    $x->imod(BigNum)               # => BigNum | Nan
    $x->imod(Scalar)               # => BigNum | Nan

Integer remainder of C<x> when is divided by C<y>. If necessary, C<x> and C<y>
are implicitly truncated to integers. Nan is returned when C<y> is zero.

=cut

Class::Multimethods::multimethod imod => qw(Math::BigNum Math::BigNum) => sub {
    my ($x, $y) = @_;

    my $yz     = _big2mpz($y);
    my $sign_y = Math::GMPz::Rmpz_sgn($yz);
    return nan if !$sign_y;

    my $r = _big2mpz($x);
    Math::GMPz::Rmpz_mod($r, $r, $yz);
    if (!Math::GMPz::Rmpz_sgn($r)) {
        return (zero);    # return faster
    }
    elsif ($sign_y < 0) {
        Math::GMPz::Rmpz_add($r, $r, $yz);
    }
    _mpz2big($r);
};

Class::Multimethods::multimethod imod => qw(Math::BigNum $) => sub {
    my ($x, $y) = @_;

    if (CORE::int($y) eq $y and $y >= LONG_MIN and $y <= ULONG_MAX) {

        $y || return nan();

        my $r     = _big2mpz($x);
        my $neg_y = $y < 0;
        $y = -$y if $neg_y;
        Math::GMPz::Rmpz_mod_ui($r, $r, $y);
        if (!Math::GMPz::Rmpz_sgn($r)) {
            return (zero);    # return faster
        }
        elsif ($neg_y) {
            Math::GMPz::Rmpz_sub_ui($r, $r, $y);
        }
        _mpz2big($r);
    }
    else {
        $x->imod(Math::BigNum->new($y));
    }
};

Class::Multimethods::multimethod imod => qw(Math::BigNum *) => sub {
    $_[0]->imod(Math::BigNum->new($_[1]));
};

Class::Multimethods::multimethod imod => qw(Math::BigNum Math::BigNum::Inf) => sub {
    $_[0]->copy->bimod($_[1]);
};

Class::Multimethods::multimethod imod => qw(Math::BigNum Math::BigNum::Nan) => \&nan;

=head2 bimod

    $x->bimod(BigNum)              # => BigNum | Nan
    $x->bimod(Scalar)              # => BigNum | Nan

Sets C<x> to the remainder of C<x> divided by C<y>. If necessary, C<x> and C<y>
are implicitly truncated to integers. Sets C<x> to Nan when C<y> is zero.

=cut

Class::Multimethods::multimethod bimod => qw(Math::BigNum Math::BigNum) => sub {
    my ($x, $y) = @_;

    my $yz     = _big2mpz($y);
    my $sign_y = Math::GMPz::Rmpz_sgn($yz);
    return $x->bnan if !$sign_y;

    my $r = _big2mpz($x);
    Math::GMPz::Rmpz_mod($r, $r, $yz);
    if ($sign_y < 0 and Math::GMPz::Rmpz_sgn($r)) {
        Math::GMPz::Rmpz_add($r, $r, $yz);
    }
    Math::GMPq::Rmpq_set_z($$x, $r);
    $x;
};

Class::Multimethods::multimethod bimod => qw(Math::BigNum $) => sub {
    my ($x, $y) = @_;

    if (CORE::int($y) eq $y and $y >= LONG_MIN and $y <= ULONG_MAX) {

        $y || return $x->bnan;

        my $r     = _big2mpz($x);
        my $neg_y = $y < 0;
        $y = -$y if $neg_y;
        Math::GMPz::Rmpz_mod_ui($r, $r, $y);
        if ($neg_y and Math::GMPz::Rmpz_sgn($r)) {
            Math::GMPz::Rmpz_sub_ui($r, $r, $y);
        }
        Math::GMPq::Rmpq_set_z($$x, $r);

        $x;
    }
    else {
        $x->bimod(Math::BigNum->new($y));
    }
};

Class::Multimethods::multimethod bimod => qw(Math::BigNum *) => sub {
    $_[0]->bimod(Math::BigNum->new($_[1]));
};

# +x mod +Inf = x
# +x mod -Inf = -Inf
# -x mod +Inf = +Inf
# -x mod -Inf = x
Class::Multimethods::multimethod bimod => qw(Math::BigNum Math::BigNum::Inf) => sub {
    $_[0]->int->bmod($_[1]);
};

Class::Multimethods::multimethod bimod => qw(Math::BigNum Math::BigNum::Nan) => \&bnan;

=head2 divmod

    $x->divmod(BigNum)             # => (BigNum, BigNum) | (Nan, Nan)
    $x->divmod(Scalar)             # => (BigNum, BigNum) | (Nan, Nan)

Returns the quotient and the remainder from division of C<x> by C<y>,
where both are integers. When C<y> is zero, it returns two Nan values.

=cut

Class::Multimethods::multimethod divmod => qw(Math::BigNum Math::BigNum) => sub {
    my ($x, $y) = @_;

    my $r1 = _big2mpz($x);
    my $r2 = _big2mpz($y);

    Math::GMPz::Rmpz_sgn($$y) || return (nan, nan);

    Math::GMPz::Rmpz_divmod($r1, $r2, $r1, $r2);
    (_mpz2big($r1), _mpz2big($r2));
};

Class::Multimethods::multimethod divmod => qw(Math::BigNum $) => sub {
    my ($x, $y) = @_;

    if (CORE::int($y) eq $y and $y >= LONG_MIN and $y <= ULONG_MAX) {

        $y || return (nan, nan);

        my $r1 = _big2mpz($x);
        my $r2 = Math::GMPz::Rmpz_init();

        Math::GMPz::Rmpz_divmod_ui($r1, $r2, $r1, $y);
        (_mpz2big($r1), _mpz2big($r2));
    }
    else {
        $x->divmod(Math::BigNum->new($y));
    }
};

Class::Multimethods::multimethod divmod => qw(Math::BigNum *) => sub {
    $_[0]->divmod(Math::BigNum->new($_[1]));
};

Class::Multimethods::multimethod divmod => qw(Math::BigNum Math::BigNum::Inf) => sub { (zero, $_[0]->mod($_[1])) };
Class::Multimethods::multimethod divmod => qw(Math::BigNum Math::BigNum::Nan) => sub { (nan, nan) };

=head1 * Number theory

=cut

=head2 modinv

    $x->modinv(BigNum)             # => BigNum | Nan
    $x->modinv(Scalar)             # => BigNum | Nan

Computes the inverse of C<x> modulo C<y> and returns the result.
If an inverse does not exists, the Nan value is returned.

=cut

Class::Multimethods::multimethod modinv => qw(Math::BigNum Math::BigNum) => sub {
    my ($x, $y) = @_;
    my $r = _big2mpz($x);
    Math::GMPz::Rmpz_invert($r, $r, _big2mpz($y)) || return nan;
    _mpz2big($r);
};

Class::Multimethods::multimethod modinv => qw(Math::BigNum $) => sub {
    my ($x, $y) = @_;
    my $z = _str2mpz($y) // return $x->modinv(Math::BigNum->new($y));
    my $r = _big2mpz($x);
    Math::GMPz::Rmpz_invert($r, $r, $z) || return nan;
    _mpz2big($r);
};

Class::Multimethods::multimethod modinv => qw(Math::BigNum *) => sub {
    $_[0]->modinv(Math::BigNum->new($_[1]));
};

Class::Multimethods::multimethod modinv => qw(Math::BigNum Math::BigNum::Inf) => \&nan;
Class::Multimethods::multimethod modinv => qw(Math::BigNum Math::BigNum::Nan) => \&nan;

=head2 modpow

    $x->modpow(BigNum, BigNum)     # => BigNum | Nan
    $x->modpow(Scalar, Scalar)     # => BigNum | Nan
    $x->modpow(BigNum, Scalar)     # => BigNum | Nan
    $x->modpow(Scalar, BigNum)     # => BigNum | Nan

Calculates C<(x ^ y) mod z>, where all three values are integers.

Returns Nan when the third argument is 0.

=cut

Class::Multimethods::multimethod modpow => qw(Math::BigNum Math::BigNum Math::BigNum) => sub {
    my ($x, $y, $z) = @_;

    $z = _big2mpz($z);
    Math::GMPz::Rmpz_sgn($z) || return nan();

    $x = _big2mpz($x);
    $y = _big2mpz($y);

    if (Math::GMPz::Rmpz_sgn($y) < 0) {
        my $t = Math::GMPz::Rmpz_init();
        Math::GMPz::Rmpz_gcd($t, $x, $z);
        Math::GMPz::Rmpz_cmp_ui($t, 1) == 0 or return nan();
    }

    Math::GMPz::Rmpz_powm($x, $x, $y, $z);
    _mpz2big($x);
};

Class::Multimethods::multimethod modpow => qw(Math::BigNum Math::BigNum $) => sub {
    my ($x, $y, $z) = @_;

    $z = _str2mpz($z) // return $x->modpow($y, Math::BigNum->new($z));
    Math::GMPz::Rmpz_sgn($z) || return nan();

    $x = _big2mpz($x);
    $y = _big2mpz($y);

    if (Math::GMPz::Rmpz_sgn($y) < 0) {
        my $t = Math::GMPz::Rmpz_init();
        Math::GMPz::Rmpz_gcd($t, $x, $z);
        Math::GMPz::Rmpz_cmp_ui($t, 1) == 0 or return nan();
    }

    Math::GMPz::Rmpz_powm($x, $x, $y, $z);
    _mpz2big($x);
};

Class::Multimethods::multimethod modpow => qw(Math::BigNum $ $) => sub {
    my ($x, $y, $z) = @_;

    if (CORE::int($y) eq $y and $y >= LONG_MIN and $y <= ULONG_MAX) {

        $z = _str2mpz($z) // return $x->modpow($y, Math::BigNum->new($z));
        Math::GMPz::Rmpz_sgn($z) || return nan();
        $x = _big2mpz($x);

        if ($y >= 0) {
            Math::GMPz::Rmpz_powm_ui($x, $x, $y, $z);
        }
        else {
            $y = _str2mpz($y) // return $x->modpow(Math::BigNum->new($y), $z);

            my $t = Math::GMPz::Rmpz_init();
            Math::GMPz::Rmpz_gcd($t, $x, $z);
            Math::GMPz::Rmpz_cmp_ui($t, 1) == 0 or return nan();

            Math::GMPz::Rmpz_powm($x, $x, $y, $z);
        }

        _mpz2big($x);
    }
    else {
        $x->modpow(Math::BigNum->new($y), Math::BigNum->new($z));
    }
};

Class::Multimethods::multimethod modpow => qw(Math::BigNum $ Math::BigNum) => sub {
    my ($x, $y, $z) = @_;

    if (CORE::int($y) eq $y and $y >= LONG_MIN and $y <= ULONG_MAX) {

        $z = _big2mpz($z);
        Math::GMPz::Rmpz_sgn($z) || return nan();
        $x = _big2mpz($x);

        if ($y >= 0) {
            Math::GMPz::Rmpz_powm_ui($x, $x, $y, $z);
        }
        else {
            $y = _str2mpz($y) // return $x->modpow(Math::BigNum->new($y), $z);

            my $t = Math::GMPz::Rmpz_init();
            Math::GMPz::Rmpz_gcd($t, $x, $z);
            Math::GMPz::Rmpz_cmp_ui($t, 1) == 0 or return nan();

            Math::GMPz::Rmpz_powm($x, $x, $y, $z);
        }

        _mpz2big($x);
    }
    else {
        $x->modpow(Math::BigNum->new($y), $z);
    }
};

Class::Multimethods::multimethod modpow => qw(Math::BigNum Math::BigNum *) => sub {
    $_[0]->modpow($_[1], Math::BigNum->new($_[2]));
};

Class::Multimethods::multimethod modpow => qw(Math::BigNum * Math::BigNum) => sub {
    $_[0]->modpow(Math::BigNum->new($_[1]), $_[2]);
};

Class::Multimethods::multimethod modpow => qw(Math::BigNum * *) => sub {
    $_[0]->modpow(Math::BigNum->new($_[1]), Math::BigNum->new($_[2]));
};

Class::Multimethods::multimethod modpow => qw(Math::BigNum Math::BigNum::Inf *) => sub {
    $_[0]->pow($_[1])->bmod($_[3]);
};

Class::Multimethods::multimethod modpow => qw(Math::BigNum * Math::BigNum::Inf) => sub {
    $_[0]->pow($_[1])->bmod($_[3]);
};

Class::Multimethods::multimethod modpow => qw(Math::BigNum Math::BigNum::Nan *) => \&nan;
Class::Multimethods::multimethod modpow => qw(Math::BigNum * Math::BigNum::Nan) => \&nan;

=head2 gcd

    $x->gcd(BigNum)                # => BigNum
    $x->gcd(Scalar)                # => BigNum

The greatest common divisor of C<x> and C<y>.

=cut

Class::Multimethods::multimethod gcd => qw(Math::BigNum Math::BigNum) => sub {
    my ($x, $y) = @_;
    my $r = _big2mpz($x);
    Math::GMPz::Rmpz_gcd($r, $r, _big2mpz($y));
    _mpz2big($r);
};

Class::Multimethods::multimethod gcd => qw(Math::BigNum $) => sub {
    my ($x, $y) = @_;
    my $r = _big2mpz($x);
    Math::GMPz::Rmpz_gcd($r, $r, _str2mpz($y) // (return $x->gcd(Math::BigNum->new($y))));
    _mpz2big($r);
};

Class::Multimethods::multimethod gcd => qw(Math::BigNum *) => sub {
    $_[0]->gcd(Math::BigNum->new($_[1]));
};

Class::Multimethods::multimethod gcd => qw(Math::BigNum Math::BigNum::Inf) => \&nan;
Class::Multimethods::multimethod gcd => qw(Math::BigNum Math::BigNum::Nan) => \&nan;

=head2 lcm

    $x->lcd(BigNum)                # => BigNum
    $x->lcd(Scalar)                # => BigNum

The least common multiple of C<x> and C<y>.

=cut

Class::Multimethods::multimethod lcm => qw(Math::BigNum Math::BigNum) => sub {
    my ($x, $y) = @_;
    my $r = _big2mpz($x);
    Math::GMPz::Rmpz_lcm($r, $r, _big2mpz($y));
    _mpz2big($r);
};

Class::Multimethods::multimethod lcm => qw(Math::BigNum $) => sub {
    my ($x, $y) = @_;

    my $r = _big2mpz($x);

    if (CORE::int($y) eq $y and $y >= LONG_MIN and $y <= ULONG_MAX) {
        Math::GMPz::Rmpz_lcm_ui($r, $r, CORE::abs($y));
    }
    else {
        my $z = _str2mpz($y) // return $x->lcm(Math::BigNum->new($y));
        Math::GMPz::Rmpz_lcm($r, $r, $z);
    }

    _mpz2big($r);
};

Class::Multimethods::multimethod lcm => qw(Math::BigNum *) => sub {
    $_[0]->lcm(Math::BigNum->new($_[1]));
};

Class::Multimethods::multimethod lcm => qw(Math::BigNum Math::BigNum::Inf) => \&nan;
Class::Multimethods::multimethod lcm => qw(Math::BigNum Math::BigNum::Nan) => \&nan;

=head2 valuation

    $n->valuation(BigNum)          # => Scalar
    $n->valuation(Scalar)          # => Scalar

Returns the number of times n is divisible by k.

=cut

Class::Multimethods::multimethod valuation => qw(Math::BigNum Math::BigNum) => sub {
    my ($x, $y) = @_;

    my $z = _big2mpz($y);
    my $sgn = Math::GMPz::Rmpz_sgn($z) || return 0;
    Math::GMPz::Rmpz_abs($z, $z) if $sgn < 0;

    my $r = _big2mpz($x);
    Math::GMPz::Rmpz_remove($r, $r, $z);
};

Class::Multimethods::multimethod valuation => qw(Math::BigNum $) => sub {
    my ($x, $y) = @_;

    my $z = _str2mpz($y) // return $x->valuation(Math::BigNum->new($y));
    my $sgn = Math::GMPz::Rmpz_sgn($z) || return 0;
    Math::GMPz::Rmpz_abs($z, $z) if $sgn < 0;

    my $r = _big2mpz($x);
    Math::GMPz::Rmpz_remove($r, $r, $z);
};

Class::Multimethods::multimethod valuation => qw(Math::BigNum *) => sub {
    $_[0]->valuation(Math::BigNum->new($_[1]));
};

Class::Multimethods::multimethod valuation => qw(Math::BigNum Math::BigNum::Inf) => sub { 0 };
Class::Multimethods::multimethod valuation => qw(Math::BigNum Math::BigNum::Nan) => \&nan;

=head2 remove

    $n->remove(BigNum)             # => BigNum
    $n->remove(Scalar)             # => BigNum

Removes all occurrences of the factor k from integer n, without changing n in-place.

In general, the following statement holds true:

    $n->remove($k) == $n / $k**$n->valuation($k)

=cut

Class::Multimethods::multimethod remove => qw(Math::BigNum Math::BigNum) => sub {
    my ($x, $y) = @_;

    my $z = _big2mpz($y);
    Math::GMPz::Rmpz_sgn($z) || return $x->copy;

    my $r = _big2mpz($x);
    Math::GMPz::Rmpz_remove($r, $r, $z);
    _mpz2big($r);
};

Class::Multimethods::multimethod remove => qw(Math::BigNum $) => sub {
    my ($x, $y) = @_;

    my $z = _str2mpz($y) // return $x->remove(Math::BigNum->new($y));
    Math::GMPz::Rmpz_sgn($z) || return $x->copy;

    my $r = _big2mpz($x);
    Math::GMPz::Rmpz_remove($r, $r, $z);
    _mpz2big($r);
};

Class::Multimethods::multimethod remove => qw(Math::BigNum *) => sub {
    $_[0]->remove(Math::BigNum->new($_[1]));
};

Class::Multimethods::multimethod remove => qw(Math::BigNum Math::BigNum::Inf) => \&copy;
Class::Multimethods::multimethod remove => qw(Math::BigNum Math::BigNum::Nan) => \&nan;

=head2 bremove

    $n->bremove(BigNum)            # => BigNum
    $n->bremove(Scalar)            # => BigNum

Removes all occurrences of the factor k from integer n, changing n in-place.

=cut

Class::Multimethods::multimethod bremove => qw(Math::BigNum Math::BigNum) => sub {
    my ($x, $y) = @_;

    my $z = _big2mpz($y);
    Math::GMPz::Rmpz_sgn($z) || return $x;

    my $r = _big2mpz($x);
    Math::GMPz::Rmpz_remove($r, $r, $z);
    Math::GMPq::Rmpq_set_z($$x, $r);
    $x;
};

Class::Multimethods::multimethod bremove => qw(Math::BigNum $) => sub {
    my ($x, $y) = @_;

    my $z = _str2mpz($y) // return $x->bremove(Math::BigNum->new($y));
    Math::GMPz::Rmpz_sgn($z) || return $x;

    my $r = _big2mpz($x);
    Math::GMPz::Rmpz_remove($r, $r, $z);
    Math::GMPq::Rmpq_set_z($$x, $r);
    $x;
};

Class::Multimethods::multimethod bremove => qw(Math::BigNum *) => sub {
    $_[0]->bremove(Math::BigNum->new($_[1]));
};

Class::Multimethods::multimethod bremove => qw(Math::BigNum Math::BigNum::Inf) => sub { $_[0] };
Class::Multimethods::multimethod bremove => qw(Math::BigNum Math::BigNum::Nan) => \&bnan;

=head2 kronecker

    $n->kronecker(BigNum)          # => Scalar
    $n->kronecker(Scalar)          # => Scalar

Returns the Kronecker symbol I<(n|m)>, which is a generalization of the Jacobi symbol for all integers I<m>.

=cut

Class::Multimethods::multimethod kronecker => qw(Math::BigNum Math::BigNum) => sub {
    Math::GMPz::Rmpz_kronecker(_big2mpz($_[0]), _big2mpz($_[1]));
};

Class::Multimethods::multimethod kronecker => qw(Math::BigNum $) => sub {
    my ($x, $y) = @_;
    if (CORE::int($y) eq $y and $y >= LONG_MIN and $y <= ULONG_MAX) {
        $y >= 0
          ? Math::GMPz::Rmpz_kronecker_ui(_big2mpz($x), $y)
          : Math::GMPz::Rmpz_kronecker_si(_big2mpz($x), $y);
    }
    else {
        $x->kronecker(Math::BigNum->new($y));
    }
};

Class::Multimethods::multimethod kronecker => qw(Math::BigNum *) => sub {
    $_[0]->kronecker(Math::BigNum->new($_[1]));
};

Class::Multimethods::multimethod kronecker => qw(Math::BigNum Math::BigNum::Inf) => \&nan;
Class::Multimethods::multimethod kronecker => qw(Math::BigNum Math::BigNum::Nan) => \&nan;

=head2 is_psqr

    $n->is_psqr                    # => Bool

Returns a true value when C<n> is a perfect square.
When C<n> is not an integer, returns C<0>.

=cut

sub is_psqr {
    my ($x) = @_;
    Math::GMPq::Rmpq_integer_p($$x) || return 0;
    my $z = Math::GMPz::Rmpz_init();
    Math::GMPq::Rmpq_numref($z, $$x);
    Math::GMPz::Rmpz_perfect_square_p($z);
}

=head2 is_ppow

    $n->is_ppow                    # => Bool

Returns a true value when C<n> is a perfect power of some integer C<k>.
When C<n> is not an integer, returns C<0>.

=cut

sub is_ppow {
    my ($x) = @_;
    Math::GMPq::Rmpq_integer_p($$x) || return 0;
    my $z = Math::GMPz::Rmpz_init();
    Math::GMPq::Rmpq_numref($z, $$x);
    Math::GMPz::Rmpz_perfect_power_p($z);
}

=head2 is_pow

    $n->is_pow(BigNum)             # => Bool
    $n->is_pow(Scalar)             # => Bool

Return a true value when C<n> is a perfect power of a given integer C<k>.
When C<n> is not an integer, returns C<0>. On the other hand, when C<k> is not an integer,
it will be truncated implicitly to an integer. If C<k> is not positive after truncation, C<0> is returned.

A true value is returned iff there exists some integer I<a> satisfying the equation: I<a^k = n>.

Example:

    100->is_pow(2)       # true: 100 is a square (10^2)
    125->is_pow(3)       # true: 125 is a cube   ( 5^3)

=cut

Class::Multimethods::multimethod is_pow => qw(Math::BigNum Math::BigNum) => sub {
    my ($x, $y) = @_;

    Math::GMPq::Rmpq_integer_p($$x) || return 0;
    Math::GMPq::Rmpq_equal($$x, $ONE) && return 1;

    $x = $$x;
    $y = CORE::int(Math::GMPq::Rmpq_get_d($$y));

    # Everything is a first power
    $y == 1 and return 1;

    # Return a true value when $x=-1 and $y is odd
    $y % 2 and Math::GMPq::Rmpq_equal($x, $MONE) and return 1;

    # Don't accept a non-positive power
    # Also, when $x is negative and $y is even, return faster
    if ($y <= 0 or ($y % 2 == 0 and Math::GMPq::Rmpq_sgn($x) < 0)) {
        return 0;
    }

    my $z = Math::GMPz::Rmpz_init_set($x);

    # Optimization for perfect squares
    $y == 2 and return Math::GMPz::Rmpz_perfect_square_p($z);

    Math::GMPz::Rmpz_perfect_power_p($z) || return 0;
    Math::GMPz::Rmpz_root($z, $z, $y);
};

Class::Multimethods::multimethod is_pow => qw(Math::BigNum $) => sub {
    my ($x, $y) = @_;

    Math::GMPq::Rmpq_integer_p($$x) || return 0;
    Math::GMPq::Rmpq_equal($$x, $ONE) && return 1;

    if (CORE::int($y) eq $y and $y <= ULONG_MAX) {

        # Everything is a first power
        $y == 1 and return 1;

        # Deref $x
        $x = $$x;

        # Return a true value when $x=-1 and $y is odd
        $y % 2 and Math::GMPq::Rmpq_equal($x, $MONE) and return 1;

        # Don't accept a non-positive power
        # Also, when $x is negative and $y is even, return faster
        if ($y <= 0 or ($y % 2 == 0 and Math::GMPq::Rmpq_sgn($x) < 0)) {
            return 0;
        }

        my $z = Math::GMPz::Rmpz_init_set($x);

        # Optimization for perfect squares
        $y == 2 and return Math::GMPz::Rmpz_perfect_square_p($z);

        Math::GMPz::Rmpz_perfect_power_p($z) || return 0;
        Math::GMPz::Rmpz_root($z, $z, $y);
    }
    else {
        $x->is_pow(Math::BigNum->new($y));
    }
};

Class::Multimethods::multimethod is_pow => qw(Math::BigNum *) => sub {
    $_[0]->is_pow(Math::BigNum->new($_[1]));
};

Class::Multimethods::multimethod is_pow => qw(Math::BigNum Math::BigNum::Inf) => sub { 0 };
Class::Multimethods::multimethod is_pow => qw(Math::BigNum Math::BigNum::Nan) => sub { 0 };

=head2 is_prime

    $n->is_prime                   # => Scalar
    $x->is_prime(BigNum)           # => Scalar
    $n->is_prime(Scalar)           # => Scalar

Returns 2 if C<n> is definitely prime, 1 if C<n> is probably prime (without
being certain), or 0 if C<n> is definitely composite. This method does some
trial divisions, then some Miller-Rabin probabilistic primality tests. It
also accepts an optional argument for specifying the accuracy of the test.
By default, it uses an accuracy value of 20.

Reasonable accuracy values are between 15 and 50.

See also:

    https://en.wikipedia.org/wiki/Miller–Rabin_primality_test
    https://gmplib.org/manual/Number-Theoretic-Functions.html

=cut

Class::Multimethods::multimethod is_prime => qw(Math::BigNum) => sub {
    Math::GMPz::Rmpz_probab_prime_p(_big2mpz($_[0]), 20);
};

Class::Multimethods::multimethod is_prime => qw(Math::BigNum $) => sub {
    Math::GMPz::Rmpz_probab_prime_p(_big2mpz($_[0]), CORE::abs(CORE::int($_[1])));
};

Class::Multimethods::multimethod is_prime => qw(Math::BigNum Math::BigNum) => sub {
    Math::GMPz::Rmpz_probab_prime_p(_big2mpz($_[0]), CORE::abs(CORE::int(Math::GMPq::Rmpq_get_d(${$_[1]}))));
};

=head2 next_prime

    $n->next_prime                 # => BigNum

Returns the next prime after C<n>.

=cut

sub next_prime {
    my ($x) = @_;
    my $r = _big2mpz($x);
    Math::GMPz::Rmpz_nextprime($r, $r);
    _mpz2big($r);
}

=head2 fac

    $n->fac                        # => BigNum | Nan

Factorial of C<n>. Returns Nan when C<n> is negative. (C<1*2*3*...*n>)

=cut

sub fac {
    my ($n) = @_;
    $n = CORE::int(Math::GMPq::Rmpq_get_d($$n));
    return nan() if $n < 0;
    my $r = Math::GMPz::Rmpz_init();
    Math::GMPz::Rmpz_fac_ui($r, $n);
    _mpz2big($r);
}

=head2 bfac

    $n->bfac                       # => BigNum | Nan

Factorial of C<n>, modifying C<n> in-place.

=cut

sub bfac {
    my ($x) = @_;
    my $n = CORE::int(Math::GMPq::Rmpq_get_d($$x));
    return $x->bnan() if $n < 0;
    my $r = Math::GMPz::Rmpz_init();
    Math::GMPz::Rmpz_fac_ui($r, $n);
    Math::GMPq::Rmpq_set_z($$x, $r);
    $x;
}

=head2 dfac

    $n->dfac                       # => BigNum | Nan

Double factorial of C<n>. Returns Nan when C<n> is negative.

Example:

    7->dfac       # 1*3*5*7 = 105
    8->dfac       # 2*4*6*8 = 384

=cut

sub dfac {
    my ($n) = @_;
    $n = CORE::int(Math::GMPq::Rmpq_get_d($$n));
    return nan() if $n < 0;
    my $r = Math::GMPz::Rmpz_init();
    Math::GMPz::Rmpz_2fac_ui($r, $n);
    _mpz2big($r);
}

=head2 primorial

    $n->primorial                  # => BigNum | Nan

Returns the product of all the primes less than or equal to C<n>.

=cut

sub primorial {
    my ($n) = @_;
    $n = CORE::int(Math::GMPq::Rmpq_get_d($$n));
    return nan() if $n < 0;
    my $r = Math::GMPz::Rmpz_init();
    Math::GMPz::Rmpz_primorial_ui($r, $n);
    _mpz2big($r);
}

=head2 fib

    $n->fib                        # => BigNum | Nan

The n-th Fibonacci number. Returns Nan when C<n> is negative.

Defined as:

    fib(0) = 0
    fib(1) = 1
    fib(n) = fib(n-1) + fib(n-2)

=cut

sub fib {
    my ($n) = @_;
    $n = CORE::int(Math::GMPq::Rmpq_get_d($$n));
    return nan() if $n < 0;
    my $r = Math::GMPz::Rmpz_init();
    Math::GMPz::Rmpz_fib_ui($r, $n);
    _mpz2big($r);
}

=head2 lucas

    $n->lucas                      # => BigNum | Nan

The n-th Lucas number. Returns Nan when C<n> is negative.

Defined as:

    lucas(0) = 2
    lucas(1) = 1
    lucas(n) = lucas(n-1) + lucas(n-2)

=cut

sub lucas {
    my ($n) = @_;
    $n = CORE::int(Math::GMPq::Rmpq_get_d($$n));
    return nan() if $n < 0;
    my $r = Math::GMPz::Rmpz_init();
    Math::GMPz::Rmpz_lucnum_ui($r, $n);
    _mpz2big($r);
}

=head2 binomial

    $n->binomial(BigNum)           # => BigNum
    $n->binomial(Scalar)           # => BigNum

Calculates the binomial coefficient n over k, also called the
"choose" function. The result is equivalent to:

           ( n )       n!
           |   |  = -------
           ( k )    k!(n-k)!

=cut

Class::Multimethods::multimethod binomial => qw(Math::BigNum Math::BigNum) => sub {
    my ($x, $y) = @_;
    my $r = _big2mpz($x);
    $y = CORE::int(Math::GMPq::Rmpq_get_d($$y));
    $y >= 0
      ? Math::GMPz::Rmpz_bin_ui($r, $r, $y)
      : Math::GMPz::Rmpz_bin_si($r, $r, $y);
    _mpz2big($r);
};

Class::Multimethods::multimethod binomial => qw(Math::BigNum $) => sub {
    my ($x, $y) = @_;
    if (CORE::int($y) eq $y and $y >= LONG_MIN and $y <= ULONG_MAX) {
        my $r = _big2mpz($x);
        $y >= 0
          ? Math::GMPz::Rmpz_bin_ui($r, $r, $y)
          : Math::GMPz::Rmpz_bin_si($r, $r, $y);
        _mpz2big($r);
    }
    else {
        $x->binomial(Math::BigNum->new($y));
    }
};

Class::Multimethods::multimethod binomial => qw(Math::BigNum *) => sub {
    $_[0]->binomial(Math::BigNum->new($_[1]));
};

Class::Multimethods::multimethod binomial => qw(Math::BigNum Math::BigNum::Inf) => \&nan;
Class::Multimethods::multimethod binomial => qw(Math::BigNum Math::BigNum::Nan) => \&nan;

=head1 * Bitwise operations

=cut

=head2 and

    $x->and(BigNum)                # => BigNum
    $x->and(Scalar)                # => BigNum

    BigNum & BigNum                # => BigNum
    BigNum & Scalar                # => BigNum
    Scalar & BigNum                # => BigNum

Integer logical-and operation.

=cut

Class::Multimethods::multimethod and => qw(Math::BigNum Math::BigNum) => sub {
    my $r = _big2mpz($_[0]);
    Math::GMPz::Rmpz_and($r, $r, _big2mpz($_[1]));
    _mpz2big($r);
};

Class::Multimethods::multimethod and => qw(Math::BigNum $) => sub {
    my $r = _str2mpz($_[1]) // return Math::BigNum->new($_[1])->band($_[0]);
    Math::GMPz::Rmpz_and($r, $r, _big2mpz($_[0]));
    _mpz2big($r);
};

Class::Multimethods::multimethod and => qw($ Math::BigNum) => sub {
    my $r = _str2mpz($_[0]) // return Math::BigNum->new($_[0])->band($_[1]);
    Math::GMPz::Rmpz_and($r, $r, _big2mpz($_[1]));
    _mpz2big($r);
};

Class::Multimethods::multimethod and => qw(* Math::BigNum) => sub {
    Math::BigNum->new($_[0])->band($_[1]);
};

Class::Multimethods::multimethod and => qw(Math::BigNum *) => sub {
    Math::BigNum->new($_[1])->band($_[0]);
};

Class::Multimethods::multimethod and => qw(Math::BigNum Math::BigNum::Inf) => \&nan;
Class::Multimethods::multimethod and => qw(Math::BigNum Math::BigNum::Nan) => \&nan;

=head2 band

    $x->band(BigNum)               # => BigNum
    $x->band(Scalar)               # => BigNum

    BigNum &= BigNum               # => BigNum
    BigNum &= Scalar               # => BigNum

Integer logical-and operation, changing C<x> in-place.

=cut

Class::Multimethods::multimethod band => qw(Math::BigNum Math::BigNum) => sub {
    my $r = _big2mpz($_[0]);
    Math::GMPz::Rmpz_and($r, $r, _big2mpz($_[1]));
    Math::GMPq::Rmpq_set_z(${$_[0]}, $r);
    $_[0];
};

Class::Multimethods::multimethod band => qw(Math::BigNum $) => sub {
    my ($x, $y) = @_;
    my $r = _str2mpz($y) // return $x->band(Math::BigNum->new($y));
    Math::GMPz::Rmpz_and($r, $r, _big2mpz($x));
    Math::GMPq::Rmpq_set_z($$x, $r);
    $x;
};

Class::Multimethods::multimethod band => qw(Math::BigNum *) => sub {
    $_[0]->band(Math::BigNum->new($_[1]));
};

Class::Multimethods::multimethod band => qw(Math::BigNum Math::BigNum::Inf) => \&bnan;
Class::Multimethods::multimethod band => qw(Math::BigNum Math::BigNum::Nan) => \&bnan;

=head2 ior

    $x->ior(BigNum)                # => BigNum
    $x->ior(Scalar)                # => BigNum

    BigNum | BigNum                # => BigNum
    BigNum | Scalar                # => BigNum
    Scalar | BigNum                # => BigNum

Integer logical inclusive-or operation.

=cut

Class::Multimethods::multimethod ior => qw(Math::BigNum Math::BigNum) => sub {
    my $r = _big2mpz($_[0]);
    Math::GMPz::Rmpz_ior($r, $r, _big2mpz($_[1]));
    _mpz2big($r);
};

Class::Multimethods::multimethod ior => qw(Math::BigNum $) => sub {
    my $r = _str2mpz($_[1]) // return Math::BigNum->new($_[1])->bior($_[0]);
    Math::GMPz::Rmpz_ior($r, $r, _big2mpz($_[0]));
    _mpz2big($r);
};

Class::Multimethods::multimethod ior => qw($ Math::BigNum) => sub {
    my $r = _str2mpz($_[0]) // return Math::BigNum->new($_[0])->bior($_[1]);
    Math::GMPz::Rmpz_ior($r, $r, _big2mpz($_[1]));
    _mpz2big($r);
};

Class::Multimethods::multimethod ior => qw(* Math::BigNum) => sub {
    Math::BigNum->new($_[0])->bior($_[1]);
};

Class::Multimethods::multimethod ior => qw(Math::BigNum *) => sub {
    $_[0]->ior(Math::BigNum->new($_[1]));
};

Class::Multimethods::multimethod ior => qw(Math::BigNum Math::BigNum::Inf) => \&nan;
Class::Multimethods::multimethod ior => qw(Math::BigNum Math::BigNum::Nan) => \&nan;

=head2 bior

    $x->bior(BigNum)               # => BigNum
    $x->bior(Scalar)               # => BigNum

    BigNum |= BigNum               # => BigNum
    BigNum |= Scalar               # => BigNum

Integer logical inclusive-or operation, changing C<x> in-place.

=cut

Class::Multimethods::multimethod bior => qw(Math::BigNum Math::BigNum) => sub {
    my ($x, $y) = @_;
    my $r = _big2mpz($x);
    Math::GMPz::Rmpz_ior($r, $r, _big2mpz($y));
    Math::GMPq::Rmpq_set_z($$x, $r);
    $x;
};

Class::Multimethods::multimethod bior => qw(Math::BigNum $) => sub {
    my ($x, $y) = @_;
    my $r = _str2mpz($y) // return $x->bior(Math::BigNum->new($y));
    Math::GMPz::Rmpz_ior($r, $r, _big2mpz($x));
    Math::GMPq::Rmpq_set_z($$x, $r);
    $x;
};

Class::Multimethods::multimethod bior => qw(Math::BigNum *) => sub {
    $_[0]->bior(Math::BigNum->new($_[1]));
};

Class::Multimethods::multimethod bior => qw(Math::BigNum Math::BigNum::Inf) => \&bnan;
Class::Multimethods::multimethod bior => qw(Math::BigNum Math::BigNum::Nan) => \&bnan;

=head2 xor

    $x->xor(BigNum)                # => BigNum
    $x->xor(Scalar)                # => BigNum

    BigNum ^ BigNum                # => BigNum
    BigNum ^ Scalar                # => BigNum
    Scalar ^ BigNum                # => BigNum

Integer logical exclusive-or operation.

=cut

Class::Multimethods::multimethod xor => qw(Math::BigNum Math::BigNum) => sub {
    my $r = _big2mpz($_[0]);
    Math::GMPz::Rmpz_xor($r, $r, _big2mpz($_[1]));
    _mpz2big($r);
};

Class::Multimethods::multimethod xor => qw(Math::BigNum $) => sub {
    my $r = _str2mpz($_[1]) // return $_[0]->xor(Math::BigNum->new($_[1]));
    Math::GMPz::Rmpz_xor($r, $r, _big2mpz($_[0]));
    _mpz2big($r);
};

Class::Multimethods::multimethod xor => qw($ Math::BigNum) => sub {
    my $r = _str2mpz($_[0]) // return Math::BigNum->new($_[0])->bxor($_[1]);
    Math::GMPz::Rmpz_xor($r, $r, _big2mpz($_[1]));
    _mpz2big($r);
};

Class::Multimethods::multimethod xor => qw(* Math::BigNum) => sub {
    Math::BigNum->new($_[0])->bxor($_[1]);
};

Class::Multimethods::multimethod xor => qw(Math::BigNum *) => sub {
    $_[0]->xor(Math::BigNum->new($_[1]));
};

Class::Multimethods::multimethod xor => qw(Math::BigNum Math::BigNum::Inf) => \&nan;
Class::Multimethods::multimethod xor => qw(Math::BigNum Math::BigNum::Nan) => \&nan;

=head2 bxor

    $x->bxor(BigNum)               # => BigNum
    $x->bxor(Scalar)               # => BigNum

    BigNum ^= BigNum               # => BigNum
    BigNum ^= Scalar               # => BigNum

Integer logical exclusive-or operation, changing C<x> in-place.

=cut

Class::Multimethods::multimethod bxor => qw(Math::BigNum Math::BigNum) => sub {
    my ($x, $y) = @_;
    my $r = _big2mpz($x);
    Math::GMPz::Rmpz_xor($r, $r, _big2mpz($y));
    Math::GMPq::Rmpq_set_z($$x, $r);
    $x;
};

Class::Multimethods::multimethod bxor => qw(Math::BigNum $) => sub {
    my ($x, $y) = @_;
    my $r = _str2mpz($y) // return $x->bxor(Math::BigNum->new($y));
    Math::GMPz::Rmpz_xor($r, $r, _big2mpz($x));
    Math::GMPq::Rmpq_set_z($$x, $r);
    $x;
};

Class::Multimethods::multimethod bxor => qw(Math::BigNum *) => sub {
    $_[0]->bxor(Math::BigNum->new($_[1]));
};

Class::Multimethods::multimethod bxor => qw(Math::BigNum Math::BigNum::Inf) => \&bnan;
Class::Multimethods::multimethod bxor => qw(Math::BigNum Math::BigNum::Nan) => \&bnan;

=head2 not

    $x->not                        # => BigNum
    ~BigNum                        # => BigNum

Integer logical-not operation. (The one's complement of C<x>).

=cut

sub not {
    my $r = _big2mpz($_[0]);
    Math::GMPz::Rmpz_com($r, $r);
    _mpz2big($r);
}

=head2 bnot

    $x->bnot                       # => BigNum

Integer logical-not operation, changing C<x> in-place.

=cut

sub bnot {
    my $r = _big2mpz($_[0]);
    Math::GMPz::Rmpz_com($r, $r);
    Math::GMPq::Rmpq_set_z(${$_[0]}, $r);
    $_[0];
}

=head2 lsft

    $x->lsft(BigNum)               # => BigNum
    $x->lsft(Scalar)               # => BigNum

    BigNum << BigNum               # => BigNum
    BigNum << Scalar               # => BigNum
    Scalar << BigNum               # => BigNum

Integer left-shift operation. (C<x * (2 ^ y)>)

=cut

Class::Multimethods::multimethod lsft => qw(Math::BigNum Math::BigNum) => sub {
    my $r = _big2mpz($_[0]);
    my $i = CORE::int(Math::GMPq::Rmpq_get_d(${$_[1]}));
    $i < 0
      ? Math::GMPz::Rmpz_div_2exp($r, $r, -$i)
      : Math::GMPz::Rmpz_mul_2exp($r, $r, $i);
    _mpz2big($r);
};

Class::Multimethods::multimethod lsft => qw(Math::BigNum $) => sub {
    my ($x, $y) = @_;

    if (CORE::int($y) eq $y and $y >= LONG_MIN and $y <= ULONG_MAX) {
        my $r = _big2mpz($x);
        $y < 0
          ? Math::GMPz::Rmpz_div_2exp($r, $r, -$y)
          : Math::GMPz::Rmpz_mul_2exp($r, $r, $y);
        _mpz2big($r);
    }
    else {
        $x->lsft(Math::BigNum->new($y));
    }
};

Class::Multimethods::multimethod lsft => qw($ Math::BigNum) => sub {
    my ($x, $y) = @_;

    my $r = _str2mpz($_[0]) // return Math::BigNum->new($x)->blsft($y);
    my $i = CORE::int(Math::GMPq::Rmpq_get_d(${$_[1]}));
    $i < 0
      ? Math::GMPz::Rmpz_div_2exp($r, $r, -$i)
      : Math::GMPz::Rmpz_mul_2exp($r, $r, $i);
    _mpz2big($r);
};

Class::Multimethods::multimethod lsft => qw(* Math::BigNum) => sub {
    Math::BigNum->new($_[0])->blsft($_[1]);
};

Class::Multimethods::multimethod lsft => qw(Math::BigNum *) => sub {
    $_[0]->lsft(Math::BigNum->new($_[1]));
};

Class::Multimethods::multimethod lsft => qw(Math::BigNum Math::BigNum::Inf) => sub {
        $_[1]->is_neg || $_[0]->int->is_zero ? zero()
      : $_[0]->is_neg ? ninf()
      :                 inf();
};

Class::Multimethods::multimethod lsft => qw(Math::BigNum Math::BigNum::Nan) => \&nan;

=head2 blsft

    $x->blsft(BigNum)              # => BigNum
    $x->blsft(Scalar)              # => BigNum

    BigNum <<= BigNum              # => BigNum
    BigNum <<= Scalar              # => BigNum

Integer left-shift operation, changing C<x> in-place. Promotes C<x> to Nan when C<y> is negative.
(C<x * (2 ^ y)>)

=cut

Class::Multimethods::multimethod blsft => qw(Math::BigNum Math::BigNum) => sub {
    my $r = _big2mpz($_[0]);
    my $i = CORE::int(Math::GMPq::Rmpq_get_d(${$_[1]}));
    $i < 0
      ? Math::GMPz::Rmpz_div_2exp($r, $r, -$i)
      : Math::GMPz::Rmpz_mul_2exp($r, $r, $i);
    Math::GMPq::Rmpq_set_z(${$_[0]}, $r);
    $_[0];
};

Class::Multimethods::multimethod blsft => qw(Math::BigNum $) => sub {
    my ($x, $y) = @_;

    if (CORE::int($y) eq $y and $y >= LONG_MIN and $y <= ULONG_MAX) {
        my $r = _big2mpz($x);
        $y < 0
          ? Math::GMPz::Rmpz_div_2exp($r, $r, -$y)
          : Math::GMPz::Rmpz_mul_2exp($r, $r, $y);
        Math::GMPq::Rmpq_set_z($$x, $r);
        $x;
    }
    else {
        $x->blsft(Math::BigNum->new($y));
    }
};

Class::Multimethods::multimethod blsft => qw(Math::BigNum *) => sub {
    $_[0]->blsft(Math::BigNum->new($_[1]));
};

Class::Multimethods::multimethod blsft => qw(Math::BigNum Math::BigNum::Inf) => sub {
        $_[1]->is_neg || $_[0]->int->is_zero ? $_[0]->bzero()
      : $_[0]->is_neg ? $_[0]->bninf()
      :                 $_[0]->binf();
};

Class::Multimethods::multimethod blsft => qw(Math::BigNum Math::BigNum::Nan) => \&bnan;

=head2 rsft

    $x->rsft(BigNum)               # => BigNum
    $x->rsft(Scalar)               # => BigNum

    BigNum >> BigNum               # => BigNum
    BigNum >> Scalar               # => BigNum
    Scalar >> BigNum               # => BigNum

Integer right-shift operation. (C<x / (2 ^ y)>)

=cut

Class::Multimethods::multimethod rsft => qw(Math::BigNum Math::BigNum) => sub {
    my $r = _big2mpz($_[0]);
    my $i = CORE::int(Math::GMPq::Rmpq_get_d(${$_[1]}));
    $i < 0
      ? Math::GMPz::Rmpz_mul_2exp($r, $r, -$i)
      : Math::GMPz::Rmpz_div_2exp($r, $r, $i);
    _mpz2big($r);
};

Class::Multimethods::multimethod rsft => qw(Math::BigNum $) => sub {
    my ($x, $y) = @_;

    if (CORE::int($y) eq $y and $y >= LONG_MIN and $y <= ULONG_MAX) {
        my $r = _big2mpz($x);
        $y < 0
          ? Math::GMPz::Rmpz_mul_2exp($r, $r, -$y)
          : Math::GMPz::Rmpz_div_2exp($r, $r, $y);
        _mpz2big($r);
    }
    else {
        $x->rsft(Math::BigNum->new($y));
    }
};

Class::Multimethods::multimethod rsft => qw($ Math::BigNum) => sub {
    my $r = _str2mpz($_[0]) // return Math::BigNum->new($_[0])->brsft($_[1]);
    my $i = CORE::int(Math::GMPq::Rmpq_get_d(${$_[1]}));
    $i < 0
      ? Math::GMPz::Rmpz_mul_2exp($r, $r, -$i)
      : Math::GMPz::Rmpz_div_2exp($r, $r, $i);
    _mpz2big($r);
};

Class::Multimethods::multimethod rsft => qw(* Math::BigNum) => sub {
    Math::BigNum->new($_[0])->brsft($_[1]);
};

Class::Multimethods::multimethod rsft => qw(Math::BigNum *) => sub {
    $_[0]->rsft(Math::BigNum->new($_[1]));
};

Class::Multimethods::multimethod rsft => qw(Math::BigNum Math::BigNum::Inf) => sub {
        $_[1]->is_pos || $_[0]->int->is_zero ? zero()
      : $_[0]->is_neg ? ninf()
      :                 inf();
};

Class::Multimethods::multimethod rsft => qw(Math::BigNum Math::BigNum::Nan) => \&nan;

=head2 brsft

    $x->brsft(BigNum)              # => BigNum
    $x->brsft(Scalar)              # => BigNum

    BigNum >>= BigNum              # => BigNum
    BigNum >>= Scalar              # => BigNum

Integer right-shift operation, changing C<x> in-place. (C<x / (2 ^ y)>)

=cut

Class::Multimethods::multimethod brsft => qw(Math::BigNum Math::BigNum) => sub {
    my $r = _big2mpz($_[0]);
    my $i = CORE::int(Math::GMPq::Rmpq_get_d(${$_[1]}));
    $i < 0
      ? Math::GMPz::Rmpz_mul_2exp($r, $r, -$i)
      : Math::GMPz::Rmpz_div_2exp($r, $r, $i);
    Math::GMPq::Rmpq_set_z(${$_[0]}, $r);
    $_[0];
};

Class::Multimethods::multimethod brsft => qw(Math::BigNum $) => sub {
    my ($x, $y) = @_;

    if (CORE::int($y) eq $y and $y >= LONG_MIN and $y <= ULONG_MAX) {
        my $r = _big2mpz($x);
        $y < 0
          ? Math::GMPz::Rmpz_mul_2exp($r, $r, -$y)
          : Math::GMPz::Rmpz_div_2exp($r, $r, $y);
        Math::GMPq::Rmpq_set_z($$x, $r);
        $x;
    }
    else {
        $x->brsft(Math::BigNum->new($y));
    }
};

Class::Multimethods::multimethod brsft => qw(Math::BigNum *) => sub {
    $_[0]->brsft(Math::BigNum->new($_[1]));
};

Class::Multimethods::multimethod brsft => qw(Math::BigNum Math::BigNum::Inf) => sub {
        $_[1]->is_pos || $_[0]->int->is_zero ? $_[0]->bzero()
      : $_[0]->is_neg ? $_[0]->bninf()
      :                 $_[0]->binf();
};

Class::Multimethods::multimethod brsft => qw(Math::BigNum Math::BigNum::Nan) => \&bnan;

=head2 popcount

    $x->popcount                   # => Scalar

Returns the population count of C<x>, which is the number of 1 bits in the binary representation.
When C<x> is negative, the population count of its absolute value is returned.

This method is also known as the Hamming weight value.

=cut

sub popcount {
    my $z = _big2mpz($_[0]);
    Math::GMPz::Rmpz_neg($z, $z) if Math::GMPz::Rmpz_sgn($z) < 0;
    Math::GMPz::Rmpz_popcount($z);
}

############################ MISCELLANEOUS ############################

=head1 MISCELLANEOUS

This section includes various useful methods.

=cut

=head2 rand

    $x->rand                       # => BigNum
    $x->rand(BigNum)               # => BigNum
    $x->rand(Scalar)               # => BigNum

Returns a pseudorandom floating-point value. When an additional argument is provided,
it returns a number between C<x> and C<y>, otherwise, a number between C<0> (inclusive) and
C<x> (exclusive) is returned.

The PRNG behind this method is called the "Mersenne Twister". Although it generates pseudorandom
numbers of very good quality, it is B<NOT> cryptographically secure!

Example:

    10->rand       # a random number between 0 and 10 (exclusive)
    10->rand(20)   # a random number between 10 and 20 (exclusive)

=cut

{
    my $srand = srand();

    {
        state $state = Math::MPFR::Rmpfr_randinit_mt_nobless();
        Math::MPFR::Rmpfr_randseed_ui($state, $srand);

        Class::Multimethods::multimethod rand => qw(Math::BigNum) => sub {
            my ($x) = @_;

            my $rand = Math::MPFR::Rmpfr_init2($PREC);
            Math::MPFR::Rmpfr_urandom($rand, $state, $ROUND);

            my $q = Math::GMPq::Rmpq_init();
            Math::MPFR::Rmpfr_get_q($q, $rand);

            Math::GMPq::Rmpq_mul($q, $q, $$x);
            bless \$q, __PACKAGE__;
        };

        Class::Multimethods::multimethod rand => qw(Math::BigNum Math::BigNum) => sub {
            my ($x, $y) = @_;

            my $rand = Math::MPFR::Rmpfr_init2($PREC);
            Math::MPFR::Rmpfr_urandom($rand, $state, $ROUND);

            my $q = Math::GMPq::Rmpq_init();
            Math::MPFR::Rmpfr_get_q($q, $rand);

            my $diff = Math::GMPq::Rmpq_init();
            Math::GMPq::Rmpq_sub($diff, $$y, $$x);
            Math::GMPq::Rmpq_mul($q, $q, $diff);
            Math::GMPq::Rmpq_add($q, $q, $$x);

            bless \$q, __PACKAGE__;
        };

        Class::Multimethods::multimethod rand => qw(Math::BigNum *) => sub {
            $_[0]->rand(Math::BigNum->new($_[1]));
        };

        Class::Multimethods::multimethod rand => qw(Math::BigNum Math::BigNum::Inf) => sub { $_[1]->copy };
        Class::Multimethods::multimethod rand => qw(Math::BigNum Math::BigNum::Nan) => \&nan;

=head2 seed

    $n->seed                       # => BigNum

Reseeds the C<rand()> method with the value of C<n>, where C<n> can be any arbitrary large integer.

Returns back the original value of C<n>.

=cut

        sub seed {
            Math::MPFR::Rmpfr_randseed($state, _big2mpz($_[0]));
            $_[0];
        }
    }

=head2 irand

    $x->irand                      # => BigNum
    $x->irand(BigNum)              # => BigNum
    $x->irand(Scalar)              # => BigNum

Returns a pseudorandom integer. When an additional argument is provided, it returns
an integer between C<x> and C<y-1>, otherwise, an integer between C<0> (inclusive)
and C<x> (exclusive) is returned.

The PRNG behind this method is called the "Mersenne Twister".
Although it generates high-quality pseudorandom integers, it is B<NOT> cryptographically secure!

Example:

    10->irand        # a random integer between 0 and 10 (exclusive)
    10->irand(20)    # a random integer between 10 and 20 (exclusive)

=cut

    {
        state $state = Math::GMPz::zgmp_randinit_mt_nobless();
        Math::GMPz::zgmp_randseed_ui($state, $srand);

        Class::Multimethods::multimethod irand => qw(Math::BigNum) => sub {
            my ($x) = @_;

            $x = _big2mpz($x);

            my $sgn = Math::GMPz::Rmpz_sgn($x) || return zero();
            Math::GMPz::Rmpz_urandomm($x, $state, $x, 1);
            Math::GMPz::Rmpz_neg($x, $x) if $sgn < 0;
            _mpz2big($x);
        };

        Class::Multimethods::multimethod irand => qw(Math::BigNum Math::BigNum) => sub {
            my ($x, $y) = @_;

            $x = _big2mpz($x);

            my $rand = _big2mpz($y);
            my $cmp = Math::GMPz::Rmpz_cmp($rand, $x);

            if ($cmp == 0) {
                return _mpz2big($rand);
            }
            elsif ($cmp < 0) {
                ($x, $rand) = ($rand, $x);
            }

            Math::GMPz::Rmpz_sub($rand, $rand, $x);
            Math::GMPz::Rmpz_urandomm($rand, $state, $rand, 1);
            Math::GMPz::Rmpz_add($rand, $rand, $x);

            _mpz2big($rand);
        };

        Class::Multimethods::multimethod irand => qw(Math::BigNum *) => sub {
            $_[0]->irand(Math::BigNum->new($_[1]));
        };

        Class::Multimethods::multimethod irand => qw(Math::BigNum Math::BigNum::Inf) => sub { $_[1]->copy };
        Class::Multimethods::multimethod irand => qw(Math::BigNum Math::BigNum::Nan) => \&nan;

=head2 iseed

    $n->iseed                      # => BigNum

Reseeds the C<irand()> method with the value of C<n>, where C<n> can be any arbitrary large integer.

Returns back the original value of C<n>.

=cut

        sub iseed {
            Math::GMPz::zgmp_randseed($state, _big2mpz($_[0]));
            $_[0];
        }
    }
}

=head2 copy

    $x->copy                       # => BigNum

Returns a deep copy of C<x>.

=cut

sub copy {
    my $r = Math::GMPq::Rmpq_init();
    Math::GMPq::Rmpq_set($r, ${$_[0]});
    bless \$r, ref($_[0]);
}

=head2 floor

    $x->floor                      # => BigNum

Returns C<x> if C<x> is an integer, otherwise it rounds C<x> towards -Infinity.

Example:

    floor( 2.5) =  2
    floor(-2.5) = -3

=cut

sub floor {
    my ($x) = @_;
    Math::GMPq::Rmpq_integer_p($$x) && return $x->copy;

    if (Math::GMPq::Rmpq_sgn($$x) > 0) {
        my $z = Math::GMPz::Rmpz_init();
        Math::GMPz::Rmpz_set_q($z, $$x);
        _mpz2big($z);
    }
    else {
        my $z = Math::GMPz::Rmpz_init();
        Math::GMPz::Rmpz_set_q($z, $$x);
        Math::GMPz::Rmpz_sub_ui($z, $z, 1);
        _mpz2big($z);
    }
}

=head2 ceil

    $x->ceil                       # => BigNum

Returns C<x> if C<x> is an integer, otherwise it rounds C<x> towards +Infinity.

Example:

    ceil( 2.5) =  3
    ceil(-2.5) = -2

=cut

sub ceil {
    my ($x) = @_;
    Math::GMPq::Rmpq_integer_p($$x) && return $x->copy;

    if (Math::GMPq::Rmpq_sgn($$x) > 0) {
        my $z = Math::GMPz::Rmpz_init();
        Math::GMPz::Rmpz_set_q($z, $$x);
        Math::GMPz::Rmpz_add_ui($z, $z, 1);
        _mpz2big($z);
    }
    else {
        my $z = Math::GMPz::Rmpz_init();
        Math::GMPz::Rmpz_set_q($z, $$x);
        _mpz2big($z);
    }
}

=head2 int

    $x->int                        # => BigNum
    int($x)                        # => BigNum

Returns a truncated integer from the value of C<x>.

Example:

    int( 2.5) =  2
    int(-2.5) = -2

=cut

sub int {
    my $q = ${$_[0]};
    Math::GMPq::Rmpq_integer_p($q) && return $_[0]->copy;
    my $z = Math::GMPz::Rmpz_init();
    Math::GMPz::Rmpz_set_q($z, $q);
    _mpz2big($z);
}

=head2 bint

    $x->bint                       # => BigNum

Truncates C<x> to an integer in-place.

=cut

sub bint {
    my $q = ${$_[0]};
    Math::GMPq::Rmpq_integer_p($q) && return $_[0];
    my $z = Math::GMPz::Rmpz_init();
    Math::GMPz::Rmpz_set_q($z, $q);
    Math::GMPq::Rmpq_set_z($q, $z);
    $_[0];
}

=head2 float

    $x->float                      # => BigNum
    $x->float(Scalar)              # => BigNum

Returns a truncated number that fits inside number of bits specified
as an argument. When no argument is specified or when the argument is
undefined, the value of C<$Math::BigNum::PREC> will be used instead.

=cut

sub float {
    my ($x, $prec) = @_;
    my $f = Math::MPFR::Rmpfr_init2(CORE::int($prec // $PREC));
    Math::MPFR::Rmpfr_set_q($f, $$x, $ROUND);
    _mpfr2big($f);
}

=head2 bfloat

    $x->bfloat                     # => BigNum
    $x->bfloat(Scalar)             # => BigNum

Same as the method C<float>, except that C<x> is truncated in-place.

=cut

sub bfloat {
    my ($x, $prec) = @_;
    my $f = Math::MPFR::Rmpfr_init2(CORE::int($prec // $PREC));
    Math::MPFR::Rmpfr_set_q($f, $$x, $ROUND);
    Math::MPFR::Rmpfr_get_q($$x, $f);
    $x;
}

=head2 round

    $x->round(BigNum)              # => BigNum
    $x->round(Scalar)              # => BigNum

Rounds C<x> to the nth place. A negative argument rounds that many digits
after the decimal point, while a positive argument rounds before the decimal
point. This method uses the "round half to even" algorithm, which is the
default rounding mode used in IEEE 754 computing functions and operators.

=cut

Class::Multimethods::multimethod round => qw(Math::BigNum $) => sub {
    $_[0]->copy->bround($_[1]);
};

Class::Multimethods::multimethod round => qw(Math::BigNum Math::BigNum) => sub {
    $_[0]->copy->bround(Math::GMPq::Rmpq_get_d(${$_[1]}));
};

=head2 bround

    $x->bround(BigNum)             # => BigNum
    $x->bround(Scalar)             # => BigNum

Rounds C<x> in-place to nth places.

=cut

Class::Multimethods::multimethod bround => qw(Math::BigNum $) => sub {
    my ($x, $prec) = @_;

    my $n   = $$x;
    my $nth = -CORE::int($prec);
    my $sgn = Math::GMPq::Rmpq_sgn($n);

    Math::GMPq::Rmpq_abs($n, $n) if $sgn < 0;

    my $p = Math::GMPq::Rmpq_init();
    Math::GMPq::Rmpq_set_str($p, '1' . ('0' x CORE::abs($nth)), 10);

    if ($nth < 0) {
        Math::GMPq::Rmpq_div($n, $n, $p);
    }
    else {
        Math::GMPq::Rmpq_mul($n, $n, $p);
    }

    state $half = do {
        my $q = Math::GMPq::Rmpq_init_nobless();
        Math::GMPq::Rmpq_set_ui($q, 1, 2);
        $q;
    };

    Math::GMPq::Rmpq_add($n, $n, $half);

    my $z = Math::GMPz::Rmpz_init();
    Math::GMPz::Rmpz_set_q($z, $n);

    if (Math::GMPz::Rmpz_odd_p($z) and Math::GMPq::Rmpq_integer_p($n)) {
        Math::GMPz::Rmpz_sub_ui($z, $z, 1);
    }

    Math::GMPq::Rmpq_set_z($n, $z);

    if ($nth < 0) {
        Math::GMPq::Rmpq_mul($n, $n, $p);
    }
    else {
        Math::GMPq::Rmpq_div($n, $n, $p);
    }

    if ($sgn < 0) {
        Math::GMPq::Rmpq_neg($n, $n);
    }

    $x;
};

Class::Multimethods::multimethod bround => qw(Math::BigNum Math::BigNum) => sub {
    $_[0]->bround(Math::GMPq::Rmpq_get_d(${$_[1]}));
};

=head2 neg

    $x->neg                        # => BigNum
    -$x                            # => BigNum

Negative value of C<x>.

=cut

sub neg {
    my ($x) = @_;
    my $r = Math::GMPq::Rmpq_init();
    Math::GMPq::Rmpq_neg($r, $$x);
    bless \$r, __PACKAGE__;
}

=head2 bneg

    $x->bneg                       # => BigNum

Negative value of C<x>, changing C<x> in-place.

=cut

sub bneg {
    Math::GMPq::Rmpq_neg(${$_[0]}, ${$_[0]});
    $_[0];
}

=head2 abs

    $x->abs                        # => BigNum
    abs($x)                        # => BigNum

Absolute value of C<x>.

Example:

    abs(-42) = 42
    abs( 42) = 42

=cut

sub abs {
    my ($x) = @_;
    my $r = Math::GMPq::Rmpq_init();
    Math::GMPq::Rmpq_abs($r, $$x);
    bless \$r, __PACKAGE__;
}

=head2 babs

    $x->babs                       # => BigNum

Absolute value of C<x>, changing C<x> in-place.

=cut

sub babs {
    Math::GMPq::Rmpq_abs(${$_[0]}, ${$_[0]});
    $_[0];
}

=head2 inc

    $x->inc                        # => BigNum

Returns C<x + 1>.

=cut

sub inc {
    my ($x) = @_;
    my $r = Math::GMPq::Rmpq_init();
    Math::GMPq::Rmpq_add($r, $$x, $ONE);
    bless \$r, __PACKAGE__;
}

=head2 binc

    $x->binc                       # => BigNum
    ++$x                           # => BigNum
    $x++                           # => BigNum

Increments C<x> in-place by 1.

=cut

sub binc {
    my ($x) = @_;
    Math::GMPq::Rmpq_add($$x, $$x, $ONE);
    $x;
}

=head2 dec

    $x->dec                        # => BigNum

Returns C<x - 1>.

=cut

sub dec {
    my ($x) = @_;
    my $r = Math::GMPq::Rmpq_init();
    Math::GMPq::Rmpq_sub($r, $$x, $ONE);
    bless \$r, __PACKAGE__;
}

=head2 bdec

    $x->bdec                       # => BigNum
    --$x                           # => BigNum
    $x--                           # => BigNum

Decrements C<x> in-place by 1.

=cut

sub bdec {
    my ($x) = @_;
    Math::GMPq::Rmpq_sub($$x, $$x, $ONE);
    $x;
}

=head1 * Introspection

=cut

=head2 is_zero

    $x->is_zero                    # => Bool

Returns a true value when C<x> is 0.

=cut

sub is_zero {
    !Math::GMPq::Rmpq_sgn(${$_[0]});
}

=head2 is_one

    $x->is_one                     # => Bool

Returns a true value when C<x> is +1.

=cut

sub is_one {
    Math::GMPq::Rmpq_equal(${$_[0]}, $ONE);
}

=head2 is_mone

    $x->is_mone                    # => Bool

Returns a true value when C<x> is -1.

=cut

sub is_mone {
    Math::GMPq::Rmpq_equal(${$_[0]}, $MONE);
}

=head2 is_pos

    $x->is_pos                     # => Bool

Returns a true value when C<x> is greater than zero.

=cut

sub is_pos {
    Math::GMPq::Rmpq_sgn(${$_[0]}) > 0;
}

=head2 is_neg

    $x->is_neg                     # => Bool

Returns a true value when C<x> is less than zero.

=cut

sub is_neg {
    Math::GMPq::Rmpq_sgn(${$_[0]}) < 0;
}

=head2 is_int

    $x->is_int                     # => Bool

Returns a true value when C<x> is an integer.

=cut

sub is_int {
    Math::GMPq::Rmpq_integer_p(${$_[0]});
}

=head2 is_real

    $x->is_real                    # => Bool

Always returns a true value when invoked on a Math::BigNum object.

=cut

sub is_real { 1 }

=head2 is_inf

    $x->is_inf                     # => Bool

Always returns a false value when invoked on a Math::BigNum object.

=cut

sub is_inf { 0 }

=head2 is_nan

    $x->is_nan                     # => Bool

Always returns a false value when invoked on a Math::BigNum object.

=cut

sub is_nan { 0 }

=head2 is_ninf

    $x->is_ninf                    # => Bool

Always returns a false value when invoked on a Math::BigNum object.

=cut

sub is_ninf { 0 }

=head2 is_odd

    $x->is_odd                     # => Bool

Returns a true value when C<x> is NOT divisible by 2. Returns C<0> if C<x> is NOT an integer.

=cut

sub is_odd {
    my ($x) = @_;
    Math::GMPq::Rmpq_integer_p($$x) || return 0;
    my $nz = Math::GMPz::Rmpz_init();
    Math::GMPq::Rmpq_numref($nz, $$x);
    Math::GMPz::Rmpz_odd_p($nz);
}

=head2 is_even

    $x->is_even                    # => Bool

Returns a true value when C<x> is divisible by 2. Returns C<0> if C<x> is NOT an integer.

=cut

sub is_even {
    my ($x) = @_;
    Math::GMPq::Rmpq_integer_p($$x) || return 0;
    my $nz = Math::GMPz::Rmpz_init();
    Math::GMPq::Rmpq_numref($nz, $$x);
    Math::GMPz::Rmpz_even_p($nz);
}

=head2 is_div

    $x->is_div(BigNum)             # => Bool
    $x->is_div(Scalar)             # => Bool

Returns a true value if C<x> is divisible by C<y> (i.e. when the
result of division of C<x> by C<y> is an integer). False otherwise.

Example:

    is_div(15, 3) = true
    is_div(15, 4) = false

It is also defined for rational numbers, returning a true value when the quotient of division is an integer:

    is_div(17, 3.4) = true       # because: 17/3.4 = 5

This method is very efficient when the first argument is an integer and the second argument is a I<Perl> integer.

=cut

Class::Multimethods::multimethod is_div => qw(Math::BigNum Math::BigNum) => sub {
    my ($x, $y) = @_;

    Math::GMPq::Rmpq_sgn($$y) || return 0;

#<<<
    #---------------------------------------------------------------------------------
    ## Optimization for integers, but it turned out to be slower for small integers...
    #---------------------------------------------------------------------------------
    #~ if (Math::GMPq::Rmpq_integer_p($$y) and Math::GMPq::Rmpq_integer_p($$x)) {
        #~ my $d = CORE::int(CORE::abs(Math::GMPq::Rmpq_get_d($$y)));
        #~ if ($d <= ULONG_MAX) {
            #~ Math::GMPz::Rmpz_set_q((my $z = Math::GMPz::Rmpz_init()), $$x);
            #~ return Math::GMPz::Rmpz_divisible_ui_p($z, $d);
        #~ }
        #~ else {
            #~ return Math::GMPz::Rmpz_divisible_p(_int2mpz($x), _int2mpz($y));
        #~ }
    #~ }
#>>>

    my $q = Math::GMPq::Rmpq_init();
    Math::GMPq::Rmpq_div($q, $$x, $$y);
    Math::GMPq::Rmpq_integer_p($q);
};

Class::Multimethods::multimethod is_div => qw(Math::BigNum $) => sub {
    my ($x, $y) = @_;

    $y || return 0;

    # Use a faster method when both $x and $y are integers
    if (CORE::int($y) eq $y and CORE::abs($y) <= ULONG_MAX and Math::GMPq::Rmpq_integer_p($$x)) {
        Math::GMPz::Rmpz_divisible_ui_p(_int2mpz($x), CORE::abs($y));
    }

    # Otherwise, do the division and check the result
    else {
        my $q = _str2mpq($y) // return $x->is_div(Math::BigNum->new($y));
        Math::GMPq::Rmpq_div($q, $$x, $q);
        Math::GMPq::Rmpq_integer_p($q);
    }
};

Class::Multimethods::multimethod is_div => qw(Math::BigNum *) => sub {
    $_[0]->is_div(Math::BigNum->new($_[1]));
};

Class::Multimethods::multimethod is_div => qw(Math::BigNum Math::BigNum::Inf) => sub { 0 };
Class::Multimethods::multimethod is_div => qw(Math::BigNum Math::BigNum::Nan) => sub { 0 };

=head2 sign

    $x->sign                       # => Scalar

Returns C<-1> when C<x> is negative, C<1> when C<x> is positive, and C<0> when C<x> is zero.

=cut

sub sign {
    Math::GMPq::Rmpq_sgn(${$_[0]});
}

=head2 length

    $x->length                     # => Scalar

Returns the number of digits of C<x> in base 10 before the decimal point.

For C<x=-1234.56>, it returns C<4>.

=cut

sub length {
    my $z = Math::GMPz::Rmpz_init();
    Math::GMPz::Rmpz_set_q($z, ${$_[0]});
    Math::GMPz::Rmpz_abs($z, $z);
    CORE::length(Math::GMPz::Rmpz_get_str($z, 10));
}

=head1 * Conversions

=cut

=head2 stringify

    $x->stringify                  # => Scalar

Returns a string representing the value of C<x>, either as a base-10 integer,
or a decimal expansion.

Example:

    stringify(1/2) = "0.5"
    stringify(100) = "100"

=cut

sub stringify {
    my $x = ${$_[0]};
    Math::GMPq::Rmpq_integer_p($x)
      ? Math::GMPq::Rmpq_get_str($x, 10)
      : do {
        $PREC = CORE::int($PREC) if ref($PREC);

        my $prec = CORE::int($PREC / 4);
        my $sgn  = Math::GMPq::Rmpq_sgn($x);

        my $n = Math::GMPq::Rmpq_init();
        Math::GMPq::Rmpq_set($n, $x);
        Math::GMPq::Rmpq_abs($n, $n) if $sgn < 0;

        my $p = Math::GMPq::Rmpq_init();
        Math::GMPq::Rmpq_set_str($p, '1' . ('0' x CORE::abs($prec)), 10);

        if ($prec < 0) {
            Math::GMPq::Rmpq_div($n, $n, $p);
        }
        else {
            Math::GMPq::Rmpq_mul($n, $n, $p);
        }

        state $half = do {
            my $q = Math::GMPq::Rmpq_init_nobless();
            Math::GMPq::Rmpq_set_ui($q, 1, 2);
            $q;
        };

        my $z = Math::GMPz::Rmpz_init();
        Math::GMPq::Rmpq_add($n, $n, $half);
        Math::GMPz::Rmpz_set_q($z, $n);

        # Too much rounding... Give up and return an MPFR stringified number.
        !Math::GMPz::Rmpz_sgn($z) && $PREC >= 2 && do {
            my $mpfr = Math::MPFR::Rmpfr_init2($PREC);
            Math::MPFR::Rmpfr_set_q($mpfr, $x, $ROUND);
            return Math::MPFR::Rmpfr_get_str($mpfr, 10, $prec, $ROUND);
        };

        if (Math::GMPz::Rmpz_odd_p($z) and Math::GMPq::Rmpq_integer_p($n)) {
            Math::GMPz::Rmpz_sub_ui($z, $z, 1);
        }

        Math::GMPq::Rmpq_set_z($n, $z);

        if ($prec < 0) {
            Math::GMPq::Rmpq_mul($n, $n, $p);
        }
        else {
            Math::GMPq::Rmpq_div($n, $n, $p);
        }

        my $num = Math::GMPz::Rmpz_init();
        my $den = Math::GMPz::Rmpz_init();

        Math::GMPq::Rmpq_numref($num, $n);
        Math::GMPq::Rmpq_denref($den, $n);

        my @r;
        while (1) {
            Math::GMPz::Rmpz_div($z, $num, $den);
            push @r, Math::GMPz::Rmpz_get_str($z, 10);

            Math::GMPz::Rmpz_mul($z, $z, $den);
            Math::GMPz::Rmpz_sub($num, $num, $z);
            last if !Math::GMPz::Rmpz_sgn($num);

            my $s = -1;
            while (Math::GMPz::Rmpz_cmp($den, $num) > 0) {
                Math::GMPz::Rmpz_mul_ui($num, $num, 10);
                ++$s;
            }

            push(@r, '0' x $s) if ($s > 0);
        }

        ($sgn < 0 ? "-" : '') . shift(@r) . (('.' . join('', @r)) =~ s/0+\z//r =~ s/\.\z//r);
      }
}

=head2 numify

    $x->numify                     # => Scalar

Returns a Perl numerical scalar with the value of C<x>, truncated if needed.

=cut

sub numify {
    Math::GMPq::Rmpq_get_d(${$_[0]});
}

=head2 boolify

    $x->boolify                    # => Bool

Returns a true value when the number is not zero. False otherwise.

=cut

sub boolify {
    !!Math::GMPq::Rmpq_sgn(${$_[0]});
}

=head2 as_frac

    $x->as_frac                    # => Scalar

Returns a string representing the number as a base-10 fraction.

Example:

    as_frac(3.5) = "7/2"
    as_frac(3.0) = "3/1"

=cut

sub as_frac {
    my $rat = Math::GMPq::Rmpq_get_str(${$_[0]}, 10);
    index($rat, '/') == -1 ? "$rat/1" : $rat;
}

=head2 as_rat

    $x->as_rat                     # => Scalar

Almost the same as C<as_frac()>, except that integers are returned as they are,
without adding a denominator of 1.

Example:

    as_rat(3.5) = "7/2"
    as_rat(3.0) = "3"

=cut

sub as_rat {
    Math::GMPq::Rmpq_get_str(${$_[0]}, 10);
}

=head2 as_float

    $x->as_float                   # => Scalar
    $x->as_float(Scalar)           # => Scalar
    $x->as_float(BigNum)           # => Scalar

Returns the self-number as a floating-point scalar. The method also accepts
an optional argument for precision after the decimal point. When no argument
is provided, it uses the default precision.

Example:

    as_float(1/3, 4) = "0.3333"

If the self number is an integer, it will be returned as it is.

=cut

Class::Multimethods::multimethod as_float => qw(Math::BigNum) => sub {
    $_[0]->stringify;
};

Class::Multimethods::multimethod as_float => qw(Math::BigNum $) => sub {
    local $Math::BigNum::PREC = 4 * $_[1];
    $_[0]->stringify;
};

Class::Multimethods::multimethod as_float => qw(Math::BigNum Math::BigNum) => sub {
    local $Math::BigNum::PREC = 4 * Math::GMPq::Rmpq_get_d(${$_[1]});
    $_[0]->stringify;
};

=head2 as_int

    $x->as_int                     # => Scalar
    $x->as_int(Scalar)             # => Scalar
    $x->as_int(BigNum)             # => Scalar

Returns the self-number as an integer in a given base. When the base is omitted, it
defaults to 10.

Example:

    as_int(255)     = "255"
    as_int(255, 16) = "ff"

=cut

Class::Multimethods::multimethod as_int => qw(Math::BigNum) => sub {
    my $z = Math::GMPz::Rmpz_init();
    Math::GMPz::Rmpz_set_q($z, ${$_[0]});
    Math::GMPz::Rmpz_get_str($z, 10);
};

Class::Multimethods::multimethod as_int => qw(Math::BigNum $) => sub {
    my $z = Math::GMPz::Rmpz_init();
    Math::GMPz::Rmpz_set_q($z, ${$_[0]});

    my $base = CORE::int($_[1]);
    if ($base < 2 or $base > 36) {
        require Carp;
        Carp::croak("base must be between 2 and 36, got $base");
    }

    Math::GMPz::Rmpz_get_str($z, $base);
};

Class::Multimethods::multimethod as_int => qw(Math::BigNum Math::BigNum) => sub {
    $_[0]->as_int(Math::GMPq::Rmpq_get_d(${$_[1]}));
};

=head2 as_bin

    $x->as_bin                     # => Scalar

Returns a string representing the value of C<x> in binary.

Example:

    as_bin(42) = "101010"

=cut

sub as_bin {
    my $z = Math::GMPz::Rmpz_init();
    Math::GMPz::Rmpz_set_q($z, ${$_[0]});
    Math::GMPz::Rmpz_get_str($z, 2);
}

=head2 as_oct

    $x->as_oct                     # => Scalar

Returns a string representing the value of C<x> in octal.

Example:

    as_oct(42) = "52"

=cut

sub as_oct {
    my $z = Math::GMPz::Rmpz_init();
    Math::GMPz::Rmpz_set_q($z, ${$_[0]});
    Math::GMPz::Rmpz_get_str($z, 8);
}

=head2 as_hex

    $x->as_hex                     # => Scalar

Returns a string representing the value of C<x> in hexadecimal.

Example:

    as_hex(42) = "2a"

=cut

sub as_hex {
    my $z = Math::GMPz::Rmpz_init();
    Math::GMPz::Rmpz_set_q($z, ${$_[0]});
    Math::GMPz::Rmpz_get_str($z, 16);
}

=head2 in_base

    $x->in_base(Scalar)            # => Scalar

Returns a string with the value of C<x> in a given base,
where the base can range from 2 to 36 inclusive. If C<x>
is not an integer, the result is returned in rationalized
form.

Example:

    in_base(42,     3) = "1120"
    in_base(12.34, 36) = "h5/1e"

=cut

Class::Multimethods::multimethod in_base => qw(Math::BigNum $) => sub {
    my ($x, $y) = @_;

    if ($y < 2 or $y > 36) {
        require Carp;
        Carp::croak("base must be between 2 and 36, got $y");
    }

    Math::GMPq::Rmpq_get_str($$x, $y);
};

Class::Multimethods::multimethod in_base => qw(Math::BigNum Math::BigNum) => sub {
    $_[0]->in_base(CORE::int(Math::GMPq::Rmpq_get_d(${$_[1]})));
};

=head2 deg2rad

    $x->deg2rad                    # => BigNum

Returns the value of C<x> converted from degrees to radians.

Example:

    deg2rad(180) = pi

=cut

sub deg2rad {
    Math::MPFR::Rmpfr_const_pi((my $pi = Math::MPFR::Rmpfr_init2($PREC)), $ROUND);
    Math::MPFR::Rmpfr_div_ui((my $fr = Math::MPFR::Rmpfr_init2($PREC)), $pi, 180, $ROUND);

    ## Version 1
    #~ my $q = Math::GMPq::Rmpq_init();
    #~ Math::MPFR::Rmpfr_get_q($q, $fr);
    #~ Math::GMPq::Rmpq_mul($q, $q, ${$_[0]});
    #~ bless \$q, __PACKAGE__;

    ## Version 2
    Math::MPFR::Rmpfr_mul_q($fr, $fr, ${$_[0]}, $ROUND);
    _mpfr2big($fr);
}

=head2 rad2deg

    $x->rad2deg                    # => BigNum

Returns the value of C<x> converted from radians to degrees.

Example:

    rad2deg(pi) = 180

=cut

sub rad2deg {
    Math::MPFR::Rmpfr_const_pi((my $pi = Math::MPFR::Rmpfr_init2($PREC)), $ROUND);
    Math::MPFR::Rmpfr_ui_div((my $fr = Math::MPFR::Rmpfr_init2($PREC)), 180, $pi, $ROUND);

    ## Version 1
    #~ my $q = Math::GMPq::Rmpq_init();
    #~ Math::MPFR::Rmpfr_get_q($q, $fr);
    #~ Math::GMPq::Rmpq_mul($q, $q, ${$_[0]});
    #~ bless \$q, __PACKAGE__;

    ## Version 2
    Math::MPFR::Rmpfr_mul_q($fr, $fr, ${$_[0]}, $ROUND);
    _mpfr2big($fr);
}

=head1 * Dissections

=cut

=head2 digits

    $x->digits                     # => (Scalar, Scalar, ...)
    $x->digits(Scalar)             # => (Scalar, Scalar, ...)

Returns a list with the digits of C<x> in a given base. When no base is specified, it defaults to base 10.

Only the absolute integer part of C<x> is considered.

Example:

    digits(-1234.56) = (1,2,3,4)
    digits(4095, 16) = ('f','f','f')

=cut

Class::Multimethods::multimethod digits => qw(Math::BigNum) => sub {
    my $z = Math::GMPz::Rmpz_init();
    Math::GMPz::Rmpz_set_q($z, ${$_[0]});
    Math::GMPz::Rmpz_abs($z, $z);
    split(//, Math::GMPz::Rmpz_get_str($z, 10));
};

Class::Multimethods::multimethod digits => qw(Math::BigNum $) => sub {
    my ($x, $y) = @_;

    if ($y < 2 or $y > 36) {
        require Carp;
        Carp::croak("base must be between 2 and 36, got $y");
    }

    my $z = Math::GMPz::Rmpz_init();
    Math::GMPz::Rmpz_set_q($z, $$x);
    Math::GMPz::Rmpz_abs($z, $z);
    split(//, Math::GMPz::Rmpz_get_str($z, $y));
};

Class::Multimethods::multimethod digits => qw(Math::BigNum Math::BigNum) => sub {
    $_[0]->digits(CORE::int(Math::GMPq::Rmpq_get_d(${$_[1]})));
};

=head2 numerator

    $x->numerator                  # => BigNum

Returns a copy of the numerator as signed BigNum.

=cut

sub numerator {
    my ($x) = @_;
    my $z = Math::GMPz::Rmpz_init();
    Math::GMPq::Rmpq_numref($z, $$x);
    _mpz2big($z);
}

=head2 denominator

    $x->denominator                # => BigNum

Returns a copy of the denominator as positive BigNum.

=cut

sub denominator {
    my ($x) = @_;
    my $z = Math::GMPz::Rmpz_init();
    Math::GMPq::Rmpq_denref($z, $$x);
    _mpz2big($z);
}

=head2 parts

    $x->parts                      # => (BigNum, BigNum)

Returns a copy of the numerator (signed) and a copy of the denominator (unsigned) as BigNum objects.

Example:

    parts(-0.75) = (-3, 4)

=cut

sub parts {
    my ($x)   = @_;
    my $num_z = Math::GMPz::Rmpz_init();
    my $den_z = Math::GMPz::Rmpz_init();
    Math::GMPq::Rmpq_numref($num_z, $$x);
    Math::GMPq::Rmpq_denref($den_z, $$x);
    (_mpz2big($num_z), _mpz2big($den_z));
}

=head1 * Comparisons

=cut

=head2 eq

    $x->eq(BigNum)                 # => Bool
    $x->eq(Scalar)                 # => Bool

    $x == $y                       # => Bool

Equality check: returns a true value when C<x> and C<y> are equal.

=cut

Class::Multimethods::multimethod eq => qw(Math::BigNum Math::BigNum) => sub {
    Math::GMPq::Rmpq_equal(${$_[0]}, ${$_[1]});
};

Class::Multimethods::multimethod eq => qw(Math::BigNum $) => sub {
    Math::GMPq::Rmpq_equal(${$_[0]}, _str2mpq($_[1]) // return $_[0]->eq(Math::BigNum->new($_[1])));
};

=for comment
Class::Multimethods::multimethod eq => qw(Math::BigNum Math::BigNum::Complex) => sub {
    my ($x, $y) = @_;
    $y->im->is_zero && Math::GMPq::Rmpq_equal($$x, ${$y->re});
};
=cut

Class::Multimethods::multimethod eq => qw(Math::BigNum *) => sub {
    $_[0]->eq(Math::BigNum->new($_[1]));
};

Class::Multimethods::multimethod eq => qw(Math::BigNum Math::BigNum::Inf) => sub { 0 };
Class::Multimethods::multimethod eq => qw(Math::BigNum Math::BigNum::Nan) => sub { 0 };

=head2 ne

    $x->ne(BigNum)                 # => Bool
    $x->ne(Scalar)                 # => Bool

    $x != $y                       # => Bool

Inequality check: returns a true value when C<x> and C<y> are not equal.

=cut

Class::Multimethods::multimethod ne => qw(Math::BigNum Math::BigNum) => sub {
    !Math::GMPq::Rmpq_equal(${$_[0]}, ${$_[1]});
};

Class::Multimethods::multimethod ne => qw(Math::BigNum $) => sub {
    !Math::GMPq::Rmpq_equal(${$_[0]}, _str2mpq($_[1]) // return $_[0]->ne(Math::BigNum->new($_[1])));
};

=for comment
Class::Multimethods::multimethod ne => qw(Math::BigNum Math::BigNum::Complex) => sub {
    my ($x, $y) = @_;
    !($y->im->is_zero && Math::GMPq::Rmpq_equal($$x, ${$y->re}));
};
=cut

Class::Multimethods::multimethod ne => qw(Math::BigNum *) => sub {
    $_[0]->ne(Math::BigNum->new($_[1]));
};

Class::Multimethods::multimethod ne => qw(Math::BigNum Math::BigNum::Inf) => sub { 1 };
Class::Multimethods::multimethod ne => qw(Math::BigNum Math::BigNum::Nan) => sub { 1 };

=head2 gt

    $x->gt(BigNum)                 # => Bool
    $x->gt(Scalar)                 # => Bool

    BigNum > BigNum                # => Bool
    BigNum > Scalar                # => Bool
    Scalar > BigNum                # => Bool

Returns a true value when C<x> is greater than C<y>.

=cut

Class::Multimethods::multimethod gt => qw(Math::BigNum Math::BigNum) => sub {
    Math::GMPq::Rmpq_cmp(${$_[0]}, ${$_[1]}) > 0;
};

Class::Multimethods::multimethod gt => qw(Math::BigNum $) => sub {
    $_[0]->cmp($_[1]) > 0;
};

Class::Multimethods::multimethod gt => qw($ Math::BigNum) => sub {
    $_[1]->cmp($_[0]) < 0;
};

=for comment
Class::Multimethods::multimethod gt => qw(Math::BigNum Math::BigNum::Complex) => sub {
    $_[1]->lt($_[0]);
};
=cut

Class::Multimethods::multimethod gt => qw(* Math::BigNum) => sub {
    Math::BigNum->new($_[0])->gt($_[1]);
};

Class::Multimethods::multimethod gt => qw(Math::BigNum *) => sub {
    $_[0]->gt(Math::BigNum->new($_[1]));
};

Class::Multimethods::multimethod gt => qw(Math::BigNum Math::BigNum::Inf) => sub { $_[1]->is_neg };
Class::Multimethods::multimethod gt => qw(Math::BigNum Math::BigNum::Nan) => sub { 0 };

=head2 ge

    $x->ge(BigNum)                 # => Bool
    $x->ge(Scalar)                 # => Bool

    BigNum >= BigNum               # => Bool
    BigNum >= Scalar               # => Bool
    Scalar >= BigNum               # => Bool

Returns a true value when C<x> is equal or greater than C<y>.

=cut

Class::Multimethods::multimethod ge => qw(Math::BigNum Math::BigNum) => sub {
    Math::GMPq::Rmpq_cmp(${$_[0]}, ${$_[1]}) >= 0;
};

Class::Multimethods::multimethod ge => qw(Math::BigNum $) => sub {
    $_[0]->cmp($_[1]) >= 0;
};

Class::Multimethods::multimethod ge => qw($ Math::BigNum) => sub {
    $_[1]->cmp($_[0]) <= 0;
};

=for comment
Class::Multimethods::multimethod ge => qw(Math::BigNum Math::BigNum::Complex) => sub {
    $_[1]->le($_[0]);
};
=cut

Class::Multimethods::multimethod ge => qw(* Math::BigNum) => sub {
    Math::BigNum->new($_[0])->ge($_[1]);
};

Class::Multimethods::multimethod ge => qw(Math::BigNum *) => sub {
    $_[0]->ge(Math::BigNum->new($_[1]));
};

Class::Multimethods::multimethod ge => qw(Math::BigNum Math::BigNum::Inf) => sub { $_[1]->is_neg };
Class::Multimethods::multimethod ge => qw(Math::BigNum Math::BigNum::Nan) => sub { 0 };

=head2 lt

    $x->lt(BigNum)                 # => Bool
    $x->lt(Scalar)                 # => Bool

    BigNum < BigNum                # => Bool
    BigNum < Scalar                # => Bool
    Scalar < BigNum                # => Bool

Returns a true value when C<x> is less than C<y>.

=cut

Class::Multimethods::multimethod lt => qw(Math::BigNum Math::BigNum) => sub {
    Math::GMPq::Rmpq_cmp(${$_[0]}, ${$_[1]}) < 0;
};

Class::Multimethods::multimethod lt => qw(Math::BigNum $) => sub {
    $_[0]->cmp($_[1]) < 0;
};

Class::Multimethods::multimethod lt => qw($ Math::BigNum) => sub {
    $_[1]->cmp($_[0]) > 0;
};

=for comment
Class::Multimethods::multimethod lt => qw(Math::BigNum Math::BigNum::Complex) => sub {
    $_[1]->gt($_[0]);
};
=cut

Class::Multimethods::multimethod lt => qw(* Math::BigNum) => sub {
    Math::BigNum->new($_[0])->lt($_[1]);
};

Class::Multimethods::multimethod lt => qw(Math::BigNum *) => sub {
    $_[0]->lt(Math::BigNum->new($_[1]));
};

Class::Multimethods::multimethod lt => qw(Math::BigNum Math::BigNum::Inf) => sub { $_[1]->is_pos };
Class::Multimethods::multimethod lt => qw(Math::BigNum Math::BigNum::Nan) => sub { 0 };

=head2 le

    $x->le(BigNum)                 # => Bool
    $x->le(Scalar)                 # => Bool

    BigNum <= BigNum               # => Bool
    BigNum <= Scalar               # => Bool
    Scalar <= BigNum               # => Bool

Returns a true value when C<x> is equal or less than C<y>.

=cut

Class::Multimethods::multimethod le => qw(Math::BigNum Math::BigNum) => sub {
    Math::GMPq::Rmpq_cmp(${$_[0]}, ${$_[1]}) <= 0;
};

Class::Multimethods::multimethod le => qw(Math::BigNum $) => sub {
    $_[0]->cmp($_[1]) <= 0;
};

Class::Multimethods::multimethod le => qw($ Math::BigNum) => sub {
    $_[1]->cmp($_[0]) >= 0;
};

=for comment
Class::Multimethods::multimethod le => qw(Math::BigNum Math::BigNum::Complex) => sub {
    $_[1]->ge($_[0]);
};
=cut

Class::Multimethods::multimethod le => qw(* Math::BigNum) => sub {
    Math::BigNum->new($_[0])->le($_[1]);
};

Class::Multimethods::multimethod le => qw(Math::BigNum *) => sub {
    $_[0]->le(Math::BigNum->new($_[1]));
};

Class::Multimethods::multimethod le => qw(Math::BigNum Math::BigNum::Inf) => sub { $_[1]->is_pos };
Class::Multimethods::multimethod le => qw(Math::BigNum Math::BigNum::Nan) => sub { 0 };

=head2 cmp

    $x->cmp(BigNum)                # => Scalar
    $x->cmp(Scalar)                # => Scalar

    BigNum <=> BigNum              # => Scalar
    BigNum <=> Scalar              # => Scalar
    Scalar <=> BigNum              # => Scalar

Compares C<x> to C<y> and returns a negative value when C<x> is less than C<y>,
0 when C<x> and C<y> are equal, and a positive value when C<x> is greater than C<y>.

=cut

Class::Multimethods::multimethod cmp => qw(Math::BigNum Math::BigNum) => sub {
    Math::GMPq::Rmpq_cmp(${$_[0]}, ${$_[1]});
};

Class::Multimethods::multimethod cmp => qw(Math::BigNum $) => sub {
    my ($x, $y) = @_;

    if (CORE::int($y) eq $y and $y >= LONG_MIN and $y <= ULONG_MAX) {
        $y >= 0
          ? Math::GMPq::Rmpq_cmp_ui($$x, $y, 1)
          : Math::GMPq::Rmpq_cmp_si($$x, $y, 1);
    }
    else {
        Math::GMPq::Rmpq_cmp($$x, _str2mpq($y) // return $x->cmp(Math::BigNum->new($y)));
    }
};

Class::Multimethods::multimethod cmp => qw($ Math::BigNum) => sub {
    my ($x, $y) = @_;

    if (CORE::int($x) eq $x and $x >= LONG_MIN and $x <= ULONG_MAX) {
        -(
           $x >= 0
           ? Math::GMPq::Rmpq_cmp_ui($$y, $x, 1)
           : Math::GMPq::Rmpq_cmp_si($$y, $x, 1)
         );
    }
    else {
        Math::GMPq::Rmpq_cmp(_str2mpq($x) // (return Math::BigNum->new($x)->cmp($y)), $$y);
    }
};

Class::Multimethods::multimethod cmp => qw(* Math::BigNum) => sub {
    Math::BigNum->new($_[0])->cmp($_[1]);
};

Class::Multimethods::multimethod cmp => qw(Math::BigNum *) => sub {
    $_[0]->cmp(Math::BigNum->new($_[1]));
};

Class::Multimethods::multimethod cmp => qw(Math::BigNum Math::BigNum::Inf) => sub { $_[1]->is_pos ? -1 : 1 };
Class::Multimethods::multimethod cmp => qw(Math::BigNum Math::BigNum::Nan) => sub { };

=head2 acmp

    $x->acmp(BigNum)               # => Scalar
    cmp(Scalar, BigNum)            # => Scalar

Compares the absolute values of C<x> and C<y>. Returns a negative value
when the absolute value of C<x> is less than the absolute value of C<y>,
0 when the absolute value of C<x> is equal to the absolute value of C<y>,
and a positive value when the absolute value of C<x> is greater than the
absolute value of C<y>.

=cut

Class::Multimethods::multimethod acmp => qw(Math::BigNum Math::BigNum) => sub {
    my ($x, $y) = @_;

    my $xn = $$x;
    my $yn = $$y;

    if (Math::GMPq::Rmpq_sgn($xn) < 0) {
        my $r = Math::GMPq::Rmpq_init();
        Math::GMPq::Rmpq_abs($r, $xn);
        $xn = $r;
    }

    if (Math::GMPq::Rmpq_sgn($yn) < 0) {
        my $r = Math::GMPq::Rmpq_init();
        Math::GMPq::Rmpq_abs($r, $yn);
        $yn = $r;
    }

    Math::GMPq::Rmpq_cmp($xn, $yn);
};

Class::Multimethods::multimethod acmp => qw(Math::BigNum $) => sub {
    my ($x, $y) = @_;

    my $xn = $$x;

    if (Math::GMPq::Rmpq_sgn($xn) < 0) {
        my $r = Math::GMPq::Rmpq_init();
        Math::GMPq::Rmpq_abs($r, $xn);
        $xn = $r;
    }

    if (CORE::int($y) eq $y and $y >= LONG_MIN and $y <= ULONG_MAX) {
        Math::GMPq::Rmpq_cmp_ui($xn, CORE::abs($y), 1);
    }
    else {
        my $q = _str2mpq($y) // return $x->acmp(Math::BigNum->new($y));
        Math::GMPq::Rmpq_abs($q, $q);
        Math::GMPq::Rmpq_cmp($xn, $q);
    }
};

Class::Multimethods::multimethod acmp => qw(Math::BigNum *) => sub {
    $_[0]->acmp(Math::BigNum->new($_[1]));
};

Class::Multimethods::multimethod acmp => qw(Math::BigNum Math::BigNum::Inf) => sub { -1 };
Class::Multimethods::multimethod acmp => qw(Math::BigNum Math::BigNum::Nan) => sub { };

=head2 min

    $x->min(BigNum)                # => BigNum

Returns C<x> if C<x> is lower than C<y>. Returns C<y> otherwise.

=cut

Class::Multimethods::multimethod min => qw(Math::BigNum Math::BigNum) => sub {
    my ($x, $y) = @_;
    Math::GMPq::Rmpq_cmp($$x, $$y) < 0 ? $x : $y;
};

Class::Multimethods::multimethod min => qw(Math::BigNum *) => sub {
    $_[0]->min(Math::BigNum->new($_[1]));
};

Class::Multimethods::multimethod min => qw(Math::BigNum Math::BigNum::Inf) => sub { $_[1]->is_pos ? $_[0] : $_[1] };
Class::Multimethods::multimethod min => qw(Math::BigNum Math::BigNum::Nan) => sub { $_[1] };

=head2 max

    $x->max(BigNum)                # => BigNum

Returns C<x> if C<x> is greater than C<y>. Returns C<y> otherwise.

=cut

Class::Multimethods::multimethod max => qw(Math::BigNum Math::BigNum) => sub {
    my ($x, $y) = @_;
    Math::GMPq::Rmpq_cmp($$x, $$y) > 0 ? $x : $y;
};

Class::Multimethods::multimethod max => qw(Math::BigNum *) => sub {
    $_[0]->max(Math::BigNum->new($_[1]));
};

Class::Multimethods::multimethod max => qw(Math::BigNum Math::BigNum::Inf) => sub { $_[1]->is_pos ? $_[1] : $_[0] };
Class::Multimethods::multimethod max => qw(Math::BigNum Math::BigNum::Nan) => sub { $_[1] };

=head1 AUTHOR

Daniel Șuteu, C<< <trizenx at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-math-bignum at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Math-BigNum>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Math::BigNum


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Math-BigNum>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Math-BigNum>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Math-BigNum>

=item * Search CPAN

L<http://search.cpan.org/dist/Math-BigNum/>

=item * GitHub

L<https://github.com/trizen/Math-BigNum>

=back

=head1 ACKNOWLEDGEMENTS

=over 4

=item * Rounding

L<https://en.wikipedia.org/wiki/Rounding>

=item * Special cases and NaN

L<https://en.wikipedia.org/wiki/NaN>

=item * What Every Computer Scientist Should Know About FloatingPoint Arithmetic

L<http://www.cl.cam.ac.uk/teaching/1011/FPComp/floatingmath.pdf>

=item * Wolfram|Alpha

L<http://www.wolframalpha.com/>

=back

=head1 SEE ALSO

=over 4

=item * Fast math libraries

L<Math::GMP> - High speed arbitrary size integer math.

L<Math::GMPz> - perl interface to the GMP library's integer (mpz) functions.

L<Math::GMPq> - perl interface to the GMP library's rational (mpq) functions.

L<Math::MPFR> - perl interface to the MPFR (floating point) library.

=item * Portable math libraries

L<Math::BigInt> - Arbitrary size integer/float math package.

L<Math::BigFloat> - Arbitrary size floating point math package.

L<Math::BigRat> - Arbitrary big rational numbers.

=item * Math utilities

L<Math::Prime::Util> - Utilities related to prime numbers, including fast sieves and factoring.

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2016-2017 Daniel Șuteu.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut

1;    # End of Math::BigNum
