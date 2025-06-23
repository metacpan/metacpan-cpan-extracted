package Math::AnyNum;

use 5.016;
use strict;
use warnings;

no warnings qw(numeric uninitialized);

use List::Util qw();
use Math::MPFR qw();
use Math::GMPq qw();
use Math::GMPz qw();
use Math::MPC  qw();

use constant {
              ULONG_MAX => Math::GMPq::_ulong_max(),
              LONG_MIN  => Math::GMPq::_long_min(),
             };

our $VERSION = '0.41';
our ($ROUND, $PREC);

BEGIN {
    $ROUND = Math::MPFR::MPFR_RNDN();
    $PREC  = 192;
}

use overload
  '""' => \&stringify,
  '0+' => \&numify,
  bool => \&boolify,

  '+' => \&add,
  '*' => \&mul,

  '==' => \&eq,
  '!=' => \&ne,

  '&' => \&and,
  '|' => \&or,
  '^' => \&xor,
  '~' => \&not,

  '>'  => sub { $_[2] ? (goto &lt) : (goto &gt) },
  '>=' => sub { $_[2] ? (goto &le) : (goto &ge) },
  '<'  => sub { $_[2] ? (goto &gt) : (goto &lt) },
  '<=' => sub { $_[2] ? (goto &ge) : (goto &le) },

  '<=>' => sub { $_[2] ? -(&cmp($_[0], $_[1]) // return undef) : &cmp($_[0], $_[1]) },

  '>>' => sub { @_ = ($_[1], $_[0]) if $_[2]; goto &rsft },
  '<<' => sub { @_ = ($_[1], $_[0]) if $_[2]; goto &lsft },
  '/'  => sub { @_ = ($_[1], $_[0]) if $_[2]; goto &div },
  '-'  => sub { @_ = ($_[1], $_[0]) if $_[2]; goto &sub },

  '**' => sub { @_ = $_[2] ? @_[1, 0] : @_[0, 1]; goto &pow },
  '%'  => sub { @_ = $_[2] ? @_[1, 0] : @_[0, 1]; goto &mod },

  atan2 => sub { @_ = $_[2] ? @_[1, 0] : @_[0, 1]; goto &atan2 },

  eq => sub { "$_[0]" eq "$_[1]" },
  ne => sub { "$_[0]" ne "$_[1]" },

  cmp => sub { $_[2] ? ("$_[1]" cmp $_[0]->stringify) : ($_[0]->stringify cmp "$_[1]") },

  neg  => \&neg,
  sin  => \&sin,
  cos  => \&cos,
  exp  => \&exp,
  log  => \&ln,
  int  => \&int,
  abs  => \&abs,
  sqrt => \&sqrt;

{

    my %const = (    # prototypes are assigned in import()
                  e          => \&e,
                  phi        => \&phi,
                  tau        => \&tau,
                  pi         => \&pi,
                  ln2        => \&ln2,
                  i          => \&i,
                  CatalanG   => \&CatalanG,
                  EulerGamma => \&EulerGamma,
                  Inf        => \&inf,
                  NaN        => \&nan,
                );

    my %trig = (
        sin   => sub (_) { goto &sin },    # built-in function
        sinh  => \&sinh,
        asin  => \&asin,
        asinh => \&asinh,

        cos   => sub (_) { goto &cos },    # built-in function
        cosh  => \&cosh,
        acos  => \&acos,
        acosh => \&acosh,

        tan   => \&tan,
        tanh  => \&tanh,
        atan  => \&atan,
        atanh => \&atanh,

        cot   => \&cot,
        coth  => \&coth,
        acot  => \&acot,
        acoth => \&acoth,

        sec   => \&sec,
        sech  => \&sech,
        asec  => \&asec,
        asech => \&asech,

        csc   => \&csc,
        csch  => \&csch,
        acsc  => \&acsc,
        acsch => \&acsch,

        atan2   => \&atan2,
        deg2rad => \&deg2rad,
        rad2deg => \&rad2deg,
    );

    my %special = (
        beta => \&beta,
        zeta => \&zeta,
        eta  => \&eta,

        gamma   => \&gamma,
        lgamma  => \&lgamma,
        lngamma => \&lngamma,
        digamma => \&digamma,

        Ai  => \&Ai,
        Ei  => \&Ei,
        Li  => \&Li,
        Li2 => \&Li2,

        lgrt     => \&lgrt,
        LambertW => \&LambertW,

        BesselJ => \&BesselJ,
        BesselY => \&BesselY,

        pow  => \&pow,
        sqr  => \&sqr,
        norm => \&norm,
        sqrt => sub (_) { goto &sqrt },    # built-in function
        cbrt => \&cbrt,
        root => \&root,

        exp   => sub (_) { goto &exp },    # built-in function
        exp2  => \&exp2,
        exp10 => \&exp10,

        ln    => sub ($) { goto &ln },     # used in overloading
        log   => \&log,                    # built-in function
        log2  => \&log2,
        log10 => \&log10,

        mod     => \&mod,
        polymod => \&polymod,

        abs => sub (_) { goto &abs },      # built-in function

        erf  => \&erf,
        erfc => \&erfc,

        hypot => \&hypot,
        agm   => \&agm,

        lnbern   => \&lnbern,
        bernreal => \&bernreal,
        harmreal => \&harmreal,

        lnsuperfactorial => \&lnsuperfactorial,
        lnhyperfactorial => \&lnhyperfactorial,

        polygonal_root  => \&polygonal_root,
        polygonal_root2 => \&polygonal_root2,
    );

    my %ntheory = (
        factorial    => \&factorial,
        dfactorial   => \&dfactorial,
        mfactorial   => \&mfactorial,
        subfactorial => \&subfactorial,
        primorial    => \&primorial,
        bell         => \&bell,
        catalan      => \&catalan,
        binomial     => \&binomial,
        multinomial  => \&multinomial,

        superfactorial => \&superfactorial,
        hyperfactorial => \&hyperfactorial,

        rising_factorial  => \&rising_factorial,
        falling_factorial => \&falling_factorial,

        lucas     => \&lucas,
        fibonacci => \&fibonacci,

        lucasU => \&lucasU,
        lucasV => \&lucasV,

        lucasUmod => \&lucasUmod,
        lucasVmod => \&lucasVmod,

        fibmod   => \&fibmod,
        lucasmod => \&lucasmod,

        chebyshevT => \&chebyshevT,
        chebyshevU => \&chebyshevU,

        chebyshevTmod => \&chebyshevTmod,
        chebyshevUmod => \&chebyshevUmod,

        laguerreL => \&laguerreL,
        legendreP => \&legendreP,

        hermiteH  => \&hermiteH,
        hermiteHe => \&hermiteHe,

        faulhaber_sum => \&faulhaber_sum,
        geometric_sum => \&geometric_sum,
        dirichlet_sum => \&dirichlet_sum,

        bernfrac => \&bernfrac,
        harmfrac => \&harmfrac,
        harmonic => \&harmfrac,

        secant_number  => \&secant_number,
        tangent_number => \&tangent_number,

        euler     => \&euler,
        bernoulli => \&bernfrac,
        faulhaber => \&faulhaber_polynomial,

        euler_polynomial     => \&euler_polynomial,
        bernoulli_polynomial => \&bernoulli_polynomial,
        faulhaber_polynomial => \&faulhaber_polynomial,

        lcm    => \&lcm,
        gcd    => \&gcd,
        gcdext => \&gcdext,

        valuation => \&valuation,
        kronecker => \&kronecker,

        remdiv => \&remdiv,

        addmod => \&addmod,
        submod => \&submod,
        mulmod => \&mulmod,
        divmod => \&divmod,

        iadd => \&iadd,
        isub => \&isub,
        imul => \&imul,
        imod => \&imod,

        idiv       => \&idiv,
        idiv_ceil  => \&idiv_ceil,
        idiv_round => \&idiv_round,
        idiv_trunc => \&idiv_trunc,

        ipow   => \&ipow,
        ipow2  => \&ipow2,
        ipow10 => \&ipow10,

        iroot => \&iroot,
        isqrt => \&isqrt,
        icbrt => \&icbrt,

        ilog   => \&ilog,
        ilog2  => \&ilog2,
        ilog10 => \&ilog10,

        isqrtrem => \&isqrtrem,
        irootrem => \&irootrem,

        polygonal        => \&polygonal,
        ipolygonal_root  => \&ipolygonal_root,
        ipolygonal_root2 => \&ipolygonal_root2,

        powmod => \&powmod,
        invmod => \&invmod,

        quadratic_powmod => \&quadratic_powmod,

        is_power      => \&is_power,
        is_power_of   => \&is_power_of,
        is_square     => \&is_square,
        is_polygonal  => \&is_polygonal,
        is_polygonal2 => \&is_polygonal2,

        is_prime   => \&is_prime,
        is_coprime => \&is_coprime,
        next_prime => \&next_prime,

        is_smooth           => \&is_smooth,
        is_rough            => \&is_rough,
        is_smooth_over_prod => \&is_smooth_over_prod,

        smooth_part => \&smooth_part,
        rough_part  => \&rough_part,

        make_coprime => \&make_coprime,
    );

    my %misc = (
        rand  => \&rand,
        irand => \&irand,

        min => \&min,
        max => \&max,

        sum  => \&sum,
        prod => \&prod,

        seed  => \&seed,
        iseed => \&iseed,

        floor => \&floor,
        ceil  => \&ceil,
        round => \&round,
        sgn   => \&sgn,

        acmp       => \&acmp,
        approx_cmp => \&approx_cmp,

        popcount => \&popcount,
        hamdist  => \&hamdist,

        neg   => sub ($) { goto &neg },    # used in overloading
        inv   => \&inv,
        conj  => \&conj,
        real  => \&real,
        imag  => \&imag,
        reals => \&reals,

        int     => sub (_) { goto &int },    # built-in function
        rat     => \&rat,
        float   => \&float,
        complex => \&complex,

        numerator   => \&numerator,
        denominator => \&denominator,
        nude        => \&nude,

        digits     => \&digits,
        digits2num => \&digits2num,
        sumdigits  => \&sumdigits,

        bsearch    => \&bsearch,
        bsearch_le => \&bsearch_le,
        bsearch_ge => \&bsearch_ge,

        base    => \&base,
        as_bin  => \&as_bin,
        as_hex  => \&as_hex,
        as_oct  => \&as_oct,
        as_int  => \&as_int,
        as_rat  => \&as_rat,
        as_frac => \&as_frac,
        as_dec  => \&as_dec,

        setbit   => \&setbit,
        getbit   => \&getbit,
        flipbit  => \&flipbit,
        clearbit => \&clearbit,

        bit_scan0 => \&bit_scan0,
        bit_scan1 => \&bit_scan1,

        rat_approx => \&rat_approx,
        ratmod     => \&ratmod,

        is_inf     => \&is_inf,
        is_ninf    => \&is_ninf,
        is_neg     => \&is_neg,
        is_pos     => \&is_pos,
        is_nan     => \&is_nan,
        is_rat     => \&is_rat,
        is_real    => \&is_real,
        is_imag    => \&is_imag,
        is_int     => \&is_int,
        is_complex => \&is_complex,
        is_zero    => \&is_zero,
        is_one     => \&is_one,
        is_mone    => \&is_mone,

        is_odd       => \&is_odd,
        is_even      => \&is_even,
        is_div       => \&is_div,
        is_congruent => \&is_congruent,
    );

    sub import {
        shift;

        my $caller = caller(0);

        while (@_) {
            my $name = shift(@_);

            if ($name eq ':overload') {
                overload::constant integer => sub {
                    ($_[0] < ULONG_MAX)
                      ? (bless \Math::GMPz::Rmpz_init_set_ui($_[0]))
                      : (bless \Math::GMPz::Rmpz_init_set_str("$_[0]", 10));
                  },
                  float  => sub { bless \_str2obj($_[0]) },
                  binary => sub {
                    my $const  = ($_[0] =~ tr/_//dr);
                    my $prefix = substr($const, 0, 2);
                    bless \(
                              $prefix eq '0x' ? Math::GMPz::Rmpz_init_set_str(substr($const, 2) || 0, 16)
                            : $prefix eq '0b' ? Math::GMPz::Rmpz_init_set_str(substr($const, 2) || 0, 2)
                            :                   Math::GMPz::Rmpz_init_set_str(substr($const, 1) || 0, 8)
                           );
                  };

                # Export 'Inf', 'NaN' and 'i' as constants
                foreach my $pair (['Inf', inf()], ['NaN', nan()], ['i', i()]) {
                    my $sub = $caller . '::' . $pair->[0];
                    no strict 'refs';
                    no warnings 'redefine';
                    my $value = $pair->[1];
                    *$sub = sub () { $value };
                }
            }
            elsif (exists $const{$name}) {
                no strict 'refs';
                no warnings 'redefine';
                my $caller_sub = $caller . '::' . $name;
                my $sub        = $const{$name};
                my $value      = $sub->();
                *$caller_sub = sub() { $value }
            }
            elsif (   exists($special{$name})
                   or exists($trig{$name})
                   or exists($ntheory{$name})
                   or exists($misc{$name})) {
                no strict 'refs';
                no warnings 'redefine';
                my $caller_sub = $caller . '::' . $name;
                *$caller_sub = $ntheory{$name} // $special{$name} // $trig{$name} // $misc{$name};
            }
            elsif ($name eq ':trig') {
                push @_, keys(%trig);
            }
            elsif ($name eq ':ntheory') {
                push @_, keys(%ntheory);
            }
            elsif ($name eq ':special') {
                push @_, keys(%special);
            }
            elsif ($name eq ':misc') {
                push @_, keys(%misc);
            }
            elsif ($name eq ':all') {
                push @_, keys(%const), keys(%trig), keys(%special), keys(%ntheory), keys(%misc);
            }
            elsif ($name eq 'PREC') {
                my $prec = CORE::int(shift(@_));
                if (   $prec < Math::MPFR::RMPFR_PREC_MIN()
                    or $prec > Math::MPFR::RMPFR_PREC_MAX()) {
                    die "invalid value for <<PREC>>: must be between "
                      . Math::MPFR::RMPFR_PREC_MIN() . " and "
                      . Math::MPFR::RMPFR_PREC_MAX()
                      . ", but got <<$prec>>";
                }
                $PREC = $prec;
            }
            else {
                die "unknown import: <<$name>>";
            }
        }
        return;
    }

    sub unimport {
        overload::remove_constant(
                                  binary  => '',
                                  float   => '',
                                  integer => '',
                                 );
    }
}

# Convert a given pair (real, imag) into an MPC object
sub _reals2mpc {
    my ($re, $im) = @_;

    my $r = Math::MPC::Rmpc_init2($PREC);

    $re = ref($re) ? _star2obj($re) : _str2obj($re);
    $im = ref($im) ? _star2obj($im) : _str2obj($im);

    my $sig = join(' ', ref($re), ref($im));

    if ($sig eq q{Math::MPFR Math::MPFR}) {
        Math::MPC::Rmpc_set_fr_fr($r, $re, $im, $ROUND);
    }
    elsif ($sig eq q{Math::GMPz Math::GMPz}) {
        Math::MPC::Rmpc_set_z_z($r, $re, $im, $ROUND);
    }
    elsif ($sig eq q{Math::GMPz Math::MPFR}) {
        Math::MPC::Rmpc_set_z_fr($r, $re, $im, $ROUND);
    }
    elsif ($sig eq q{Math::MPFR Math::GMPz}) {
        Math::MPC::Rmpc_set_fr_z($r, $re, $im, $ROUND);
    }
    elsif ($sig eq q{Math::GMPz Math::GMPq}) {
        Math::MPC::Rmpc_set_z_q($r, $re, $im, $ROUND);
    }
    elsif ($sig eq q{Math::GMPq Math::GMPz}) {
        Math::MPC::Rmpc_set_q_z($r, $re, $im, $ROUND);
    }
    elsif ($sig eq q{Math::GMPq Math::GMPq}) {
        Math::MPC::Rmpc_set_q_q($r, $re, $im, $ROUND);
    }
    elsif ($sig eq q{Math::GMPq Math::MPFR}) {
        Math::MPC::Rmpc_set_q_fr($r, $re, $im, $ROUND);
    }
    elsif ($sig eq q{Math::MPFR Math::GMPq}) {
        Math::MPC::Rmpc_set_fr_q($r, $re, $im, $ROUND);
    }
    elsif (ref($re) eq 'Math::MPC') {
        Math::MPC::Rmpc_set($r, _any2mpc($im), $ROUND);
        Math::MPC::Rmpc_mul_i($r, $r, 1, $ROUND);
        Math::MPC::Rmpc_add($r, $r, $re, $ROUND);
    }
    elsif (ref($im) eq 'Math::MPC') {
        Math::MPC::Rmpc_set($r, $im, $ROUND);
        Math::MPC::Rmpc_mul_i($r, $r, 1, $ROUND);
        Math::MPC::Rmpc_add($r, $r, _any2mpc($re), $ROUND);
    }
    else {    # this should never happen
        $re = _any2mpfr($re);
        $im = _any2mpfr($im);
        Math::MPC::Rmpc_set_fr_fr($r, $re, $im, $ROUND);
    }

    return $r;
}

# Create and return a new {GMP*, MPFR, MPC} object, given a base-10 numerical string
sub _str2obj {
    my ($s) = @_;

#<<<
    #~ $s // do {
        #~ require Carp;
        #~ Carp::carp("Use of uninitialized value");
    #~ };
#>>>

    $s || goto &_zero;

    $s = lc($s);

    if ($s eq 'inf' or $s eq '+inf') {
        goto &_inf;
    }
    elsif ($s eq '-inf') {
        goto &_ninf;
    }
    elsif ($s eq 'nan') {
        goto &_nan;
    }

    # Remove underscores
    $s =~ tr/_//d;

    # Performance improvement for Perl integers
    if (CORE::int($s) eq $s and $s > LONG_MIN and $s < ULONG_MAX) {
        return (
                ($s < 0)
                ? Math::GMPz::Rmpz_init_set_si($s)
                : Math::GMPz::Rmpz_init_set_ui($s)
               );
    }

    # Complex number (form: "(3 4)")
    if (substr($s, 0, 1) eq '(' and substr($s, -1) eq ')') {
        my ($re, $im) = split(' ', substr($s, 1, -1));

        if (defined($re) and defined($im)) {
            return _reals2mpc($re, $im);
        }
    }

    # Complex number (form: "3+4i")
    if (substr($s, -1) eq 'i') {

        if ($s eq 'i' or $s eq '+i') {
            my $r = Math::MPC::Rmpc_init2($PREC);
            Math::MPC::Rmpc_set_ui_ui($r, 0, 1, $ROUND);
            return $r;
        }
        elsif ($s eq '-i') {
            my $r = Math::MPC::Rmpc_init2($PREC);
            Math::MPC::Rmpc_set_si_si($r, 0, -1, $ROUND);
            return $r;
        }

        my ($re, $im);

        state $numeric_re  = qr/[+-]?+(?=\.?[0-9])[0-9]*+(?:\.[0-9]++)?(?:[Ee](?:[+-]?+[0-9]+))?/;
        state $unsigned_re = qr/(?=\.?[0-9])[0-9]*+(?:\.[0-9]++)?(?:[Ee](?:[+-]?+[0-9]+))?/;

        if ($s =~ /^($numeric_re)\s*([-+])\s*($unsigned_re)i\z/o) {
            ($re, $im) = ($1, $3);
            $im = "-$im" if $2 eq '-';
        }
        elsif ($s =~ /^($numeric_re)i\z/o) {
            ($re, $im) = (0, $1);
        }
        elsif ($s =~ /^($numeric_re)\s*([-+])\s*i\z/o) {
            ($re, $im) = ($1, 1);
            $im = -1 if $2 eq '-';
        }

        if (defined($re) and defined($im)) {
            return _reals2mpc($re, $im);
        }
    }

    # Floating-point
    if ($s =~ tr/e.//) {
        my $r = Math::MPFR::Rmpfr_init2($PREC);
        if (Math::MPFR::Rmpfr_set_str($r, "$s", 10, $ROUND)) {
            Math::MPFR::Rmpfr_set_nan($r);
        }
        return $r;
    }

    # Remove the leading plus sign (if any)
    $s =~ s/^\+// if substr($s, 0, 1) eq '+';

    # Fraction
    if (index($s, '/') != -1) {

        if ($s =~ m{^\s*-?[0-9]+\s*/\s*-?[1-9]+[0-9]*\s*\z}) {
            my $r = Math::GMPq::Rmpq_init();
            Math::GMPq::Rmpq_set_str($r, $s, 10);
            Math::GMPq::Rmpq_canonicalize($r);
            return $r;
        }

        return ${Math::AnyNum->new($s, 10)};
    }

    # Integer
    eval { Math::GMPz::Rmpz_init_set_str("$s", 10) } // goto &_nan;
}

# Parse a given decimal expansion string as a base-10 fraction
sub _str2frac {
    my ($str) = @_;

    my $sign = substr($str, 0, 1);
    if ($sign eq '-') {
        substr($str, 0, 1, '');
        $sign = '-';
    }
    else {
        substr($str, 0, 1, '') if ($sign eq '+');
        $sign = '';
    }

    if ((my $i = index($str, 'e')) != -1) {

        my $exp = substr($str, $i + 1);

        my ($before, $after) = split(/\./, substr($str, 0, $i));

        if (!defined($after)) {    # return faster for numbers like "13e2"
            if ($exp >= 0) {
                return ("$sign$before" . ('0' x $exp));
            }
            else {
                $after = '';
            }
        }

        my $numerator = "$sign$before$after";

        if ($exp < 0) {
            return ("$numerator/1" . ('0' x (CORE::abs($exp) + CORE::length($after))));
        }

        my $diff = ($exp - CORE::length($after));

        if ($diff >= 0) {
            return ($numerator . ('0' x $diff));
        }

        my $s = "$before$after";
        substr($s, $exp + CORE::length($before), 0, '.');
        return _str2frac("$sign$s");
    }

    if ((my $i = index($str, '.')) != -1) {
        my ($before, $after) = (substr($str, 0, $i), substr($str, $i + 1));

        if ($after == 0) {
            return "$sign$before";
        }

        return ($sign . "$before$after/1" . ('0' x CORE::length($after)));
    }

    return "$sign$str";
}

#
## MPZ
#

sub _mpz2mpq {
    my $r = Math::GMPq::Rmpq_init();
    Math::GMPq::Rmpq_set_z($r, $_[0]);
    $r;
}

sub _mpz2mpfr {
    my $r = Math::MPFR::Rmpfr_init2($PREC);
    Math::MPFR::Rmpfr_set_z($r, $_[0], $ROUND);
    $r;
}

sub _mpz2mpc {
    my $r = Math::MPC::Rmpc_init2($PREC);
    Math::MPC::Rmpc_set_z($r, $_[0], $ROUND);
    $r;
}

#
## MPQ
#

sub _mpq2mpz {
    my $z = Math::GMPz::Rmpz_init();
    Math::GMPz::Rmpz_set_q($z, $_[0]);
    $z;
}

sub _mpq2mpfr {
    my $r = Math::MPFR::Rmpfr_init2($PREC);
    Math::MPFR::Rmpfr_set_q($r, $_[0], $ROUND);
    $r;
}

sub _mpq2mpc {
    my $r = Math::MPC::Rmpc_init2($PREC);
    Math::MPC::Rmpc_set_q($r, $_[0], $ROUND);
    $r;
}

#
## MPFR
#

sub _mpfr2mpc {
    my $r = Math::MPC::Rmpc_init2($PREC);
    Math::MPC::Rmpc_set_fr($r, $_[0], $ROUND);
    $r;
}

#
## Any
#

sub _any2mpc {
    my ($x) = @_;

    ref($x) eq 'Math::MPC'  && return $x;
    ref($x) eq 'Math::GMPq' && goto &_mpq2mpc;
    ref($x) eq 'Math::GMPz' && goto &_mpz2mpc;

    goto &_mpfr2mpc;
}

sub _any2mpfr {
    my ($x) = @_;

    ref($x) eq 'Math::MPFR' && return $x;
    ref($x) eq 'Math::GMPq' && goto &_mpq2mpfr;
    ref($x) eq 'Math::GMPz' && goto &_mpz2mpfr;

    my $fr = Math::MPFR::Rmpfr_init2($PREC);
    Math::MPC::RMPC_IM($fr, $x);

    Math::MPFR::Rmpfr_zero_p($fr)
      ? Math::MPC::RMPC_RE($fr, $x)
      : Math::MPFR::Rmpfr_set_nan($fr);

    $fr;
}

sub _any2mpz {
    my ($x) = @_;

    ref($x) eq 'Math::GMPz' && return $x;
    ref($x) eq 'Math::GMPq' && goto &_mpq2mpz;

    if (ref($x) eq 'Math::MPFR') {
        if (Math::MPFR::Rmpfr_number_p($x)) {
            my $z = Math::GMPz::Rmpz_init();
            Math::MPFR::Rmpfr_get_z($z, $x, Math::MPFR::MPFR_RNDZ);
            return $z;
        }
        return;
    }

    @_ = _any2mpfr($x);
    goto &_any2mpz;
}

sub _any2mpq {
    my ($x) = @_;

    ref($x) eq 'Math::GMPq' && return $x;
    ref($x) eq 'Math::GMPz' && goto &_mpz2mpq;

    if (ref($x) eq 'Math::MPFR') {
        if (Math::MPFR::Rmpfr_number_p($x)) {
            my $q = Math::GMPq::Rmpq_init();
            Math::MPFR::Rmpfr_get_q($q, $x);
            return $q;
        }
        return;
    }

    @_ = _any2mpfr($x);
    goto &_any2mpq;
}

sub _any2ui {
    my ($x) = @_;
    goto(ref($x) =~ tr/:/_/rs);

  Math_GMPz: {

        if (Math::GMPz::Rmpz_fits_ulong_p($x)) {
            return Math::GMPz::Rmpz_get_ui($x);
        }

        return;
    }

  Math_GMPq: {

        if (Math::GMPq::Rmpq_integer_p($x)) {
            $x = _mpq2mpz($x);
            goto Math_GMPz;
        }

        my $d = CORE::int(Math::GMPq::Rmpq_get_d($x));
        return (($d < 0 or $d > ULONG_MAX) ? undef : $d);
    }

  Math_MPFR: {

        if (Math::MPFR::Rmpfr_integer_p($x) and Math::MPFR::Rmpfr_fits_ulong_p($x, $ROUND)) {
            return Math::MPFR::Rmpfr_get_ui($x, $ROUND);
        }

        if (Math::MPFR::Rmpfr_number_p($x)) {
            my $d = CORE::int(Math::MPFR::Rmpfr_get_d($x, $ROUND));
            return (($d < 0 or $d > ULONG_MAX) ? undef : $d);
        }

        return;
    }

  Math_MPC: {
        $x = _any2mpfr($x);
        goto Math_MPFR;
    }
}

sub _any2si {
    my ($x) = @_;
    goto(ref($x) =~ tr/:/_/rs);

  Math_GMPz: {

        if (Math::GMPz::Rmpz_fits_slong_p($x)) {
            return Math::GMPz::Rmpz_get_si($x);
        }

        if (Math::GMPz::Rmpz_fits_ulong_p($x)) {
            return Math::GMPz::Rmpz_get_ui($x);
        }

        return;
    }

  Math_GMPq: {

        if (Math::GMPq::Rmpq_integer_p($x)) {
            $x = _mpq2mpz($x);
            goto Math_GMPz;
        }

        my $d = CORE::int(Math::GMPq::Rmpq_get_d($x));
        return (($d < LONG_MIN or $d > ULONG_MAX) ? undef : $d);
    }

  Math_MPFR: {

        if (Math::MPFR::Rmpfr_integer_p($x)) {
            if (Math::MPFR::Rmpfr_fits_slong_p($x, $ROUND)) {
                return Math::MPFR::Rmpfr_get_si($x, $ROUND);
            }

            if (Math::MPFR::Rmpfr_fits_ulong_p($x, $ROUND)) {
                return Math::MPFR::Rmpfr_get_ui($x, $ROUND);
            }
        }

        if (Math::MPFR::Rmpfr_number_p($x)) {
            my $d = CORE::int(Math::MPFR::Rmpfr_get_d($x, $ROUND));
            return (($d < LONG_MIN or $d > ULONG_MAX) ? undef : $d);
        }

        return;
    }

  Math_MPC: {
        $x = _any2mpfr($x);
        goto Math_MPFR;
    }
}

#
## Anything to MPFR (including strings)
#
sub _star2mpfr {
    my ($x) = @_;

    $x =
        ref($x) eq __PACKAGE__ ? $$x
      : ref($x)                ? _star2obj($x)
      :                          _str2obj($x);

    ref($x) eq 'Math::MPFR' and return $x;

    @_ = $x;
    ref($x) eq 'Math::GMPz' && goto &_mpz2mpfr;
    ref($x) eq 'Math::GMPq' && goto &_mpq2mpfr;
    goto &_any2mpfr;
}

#
## Anything to GMPz (including strings)
#
sub _star2mpz {
    my ($x) = @_;

    # Performance improvement for Perl integers
    if (!ref($x) and CORE::int($x) eq $x and $x > LONG_MIN and $x < ULONG_MAX) {
        return (
                ($x < 0)
                ? Math::GMPz::Rmpz_init_set_si($x)
                : Math::GMPz::Rmpz_init_set_ui($x)
               );
    }

    $x =
        ref($x) eq __PACKAGE__ ? $$x
      : ref($x)                ? _star2obj($x)
      :                          _str2obj($x);

    ref($x) eq 'Math::GMPz' and return $x;

    @_ = $x;
    ref($x) eq 'Math::GMPq' and goto &_mpq2mpz;
    goto &_any2mpz;
}

#
## Anything to a native unsigned integer (including strings)
#

sub _star2ui {
    my ($k) = @_;

    if (ref($k) eq __PACKAGE__) {

        $k = $$k;

        if (ref($k) eq 'Math::GMPz' and Math::GMPz::Rmpz_fits_ulong_p($k)) {
            $k = Math::GMPz::Rmpz_get_ui($k);
        }
        else {
            $k = _any2ui($k) // return;
        }
    }
    elsif (!ref($k) and CORE::int($k) eq $k and $k >= 0 and $k < ULONG_MAX) {
        $k = CORE::int($k);
    }
    else {
        $k = _any2ui(_star2obj($k)) // return;
    }

    $k;
}

#
## Anything to a native signed integer (including strings)
#

sub _star2si {
    my ($k) = @_;

    if (ref($k) eq __PACKAGE__) {

        $k = $$k;

        if (ref($k) eq 'Math::GMPz' and Math::GMPz::Rmpz_fits_ulong_p($k)) {
            $k = Math::GMPz::Rmpz_get_ui($k);
        }
        else {
            $k = _any2si($k) // return;
        }
    }
    elsif (!ref($k) and CORE::int($k) eq $k and $k > LONG_MIN and $k < ULONG_MAX) {
        $k = CORE::int($k);
    }
    else {
        $k = _any2si(_star2obj($k)) // return;
    }

    $k;
}

#
## Anything to MPFR or MPC, in this order (including strings)
#
sub _star2mpfr_mpc {
    my ($x) = @_;

    $x =
        ref($x) eq __PACKAGE__ ? $$x
      : ref($x)                ? _star2obj($x)
      :                          _str2obj($x);

    if (   ref($x) eq 'Math::MPFR'
        or ref($x) eq 'Math::MPC') {
        return $x;
    }

    @_ = $x;
    ref($x) eq 'Math::GMPz' && goto &_mpz2mpfr;
    ref($x) eq 'Math::GMPq' && goto &_mpq2mpfr;
    goto &_any2mpfr;    # this should not happen
}

#
## Anything to a {GMP*, MPFR or MPC} object
#
sub _star2obj {
    my ($x) = @_;

    # Performance improvement for Perl integers
    if (!ref($x)) {
        if (CORE::int($x) eq $x and $x > LONG_MIN and $x < ULONG_MAX) {
            return (
                    ($x < 0)
                    ? Math::GMPz::Rmpz_init_set_si($x)
                    : Math::GMPz::Rmpz_init_set_ui($x)
                   );
        }
        goto &_str2obj;
    }

    if (ref($x) eq __PACKAGE__) {
        $$x;
    }
    elsif (   ref($x) eq 'Math::GMPz'
           or ref($x) eq 'Math::GMPq'
           or ref($x) eq 'Math::MPFR'
           or ref($x) eq 'Math::MPC') {
        $x;
    }
    elsif (ref($x) eq 'Math::GComplex') {
        _reals2mpc($x->reals);
    }
    else {
        @_ = "$x";
        goto &_str2obj;
    }
}

#
## Binary splitting
#

sub _binsplit {
    my ($arr, $func) = @_;

    while ($#$arr > 0) {
        push(@$arr, $func->(shift(@$arr), shift(@$arr)));
    }

    $arr->[0];
}

# Cached primorial of k
sub _cached_primorial {
    my ($k, $limit) = @_;

    state %cache;

    if (exists $cache{$k}) {
        return $cache{$k};
    }

    $limit //= 100;

    # Clear the cache when there are too many values cached
    if (scalar(keys(%cache)) > $limit) {
        Math::GMPz::Rmpz_clear($_) for values(%cache);
        undef %cache;
    }

    $cache{$k} //= do {

        state $GMP_V_MAJOR = Math::GMPz::__GNU_MP_VERSION();
        state $GMP_V_MINOR = Math::GMPz::__GNU_MP_VERSION_MINOR();
        state $OLD_GMP     = ($GMP_V_MAJOR < 5 or ($GMP_V_MAJOR == 5 and $GMP_V_MINOR < 1));

        my $t = Math::GMPz::Rmpz_init_nobless();

        if ($OLD_GMP) {
            Math::GMPz::Rmpz_set_ui($t, 1);
            for (my $p = Math::GMPz::Rmpz_init_set_ui(2) ; Math::GMPz::Rmpz_cmp_ui($p, $k) <= 0 ; Math::GMPz::Rmpz_nextprime($p, $p)) {
                Math::GMPz::Rmpz_mul($t, $t, $p);
            }
        }
        else {
            Math::GMPz::Rmpz_primorial_ui($t, $k);
        }

        $t;
    };
}

sub new {
    my ($class, $num, $base) = @_;

    if (ref($base)) {
        if (ref($base) eq __PACKAGE__) {
            $base = _any2ui($$base) // 0;
        }
        else {
            $base = CORE::int($base);
        }
    }

#<<<
    #~ $num // do {
        #~ require Carp;
        #~ Carp::carp("Use of uninitialized value");
    #~ };
#>>>

    my $ref = ref($num);

    # Number with base
    if (defined($base)) {

        my $int_base = CORE::int($base);

        if ($int_base < 2 or $int_base > 62) {
            require Carp;
            Carp::croak("base must be between 2 and 62, got $base");
        }

        $num = defined($num) ? "$num" : '0';

        # Remove the leading plus sign (if any)
        $num =~ s/^\+// if substr($num, 0, 1) eq '+';

        if (index($num, '/') != -1) {

            my ($nu, $de) = split(/\//, $num);

            my $nu_obj = $class->new($nu, $base);
            my $de_obj = $class->new($de, $base);

            if (ref($$nu_obj) ne 'Math::GMPz') {
                goto &nan;
            }

            if (ref($$de_obj) ne 'Math::GMPz') {
                goto &nan;
            }

            if (Math::GMPz::Rmpz_sgn($$de_obj) == 0) {
                if (Math::GMPz::Rmpz_sgn($$nu_obj) == 0) {
                    goto &nan;    # 0/0
                }

                if (Math::GMPz::Rmpz_sgn($$nu_obj) < 0) {
                    goto &ninf;    # -x/0
                }
                else {
                    goto &inf;     # +x/0
                }
            }

            my $r = Math::GMPq::Rmpq_init();

            Math::GMPq::Rmpq_set_num($r, $$nu_obj);
            Math::GMPq::Rmpq_set_den($r, $$de_obj);

            Math::GMPq::Rmpq_canonicalize($r);

            return bless(\$r, $class);
        }
        elsif (substr($num, 0, 1) eq '(' and substr($num, -1) eq ')') {
            my $r = Math::MPC::Rmpc_init2($PREC);
            eval { Math::MPC::Rmpc_set_str($r, $num, $int_base, $ROUND); 1 } // goto &nan;
            return bless \$r;
        }
        elsif (index($num, '.') != -1) {
            my $r = Math::MPFR::Rmpfr_init2($PREC);
            if (Math::MPFR::Rmpfr_set_str($r, $num, $int_base, $ROUND) < 0) {
                goto &nan;
            }
            return bless \$r, $class;
        }
        else {
            return bless \(eval { Math::GMPz::Rmpz_init_set_str($num, $int_base) } // goto &nan), $class;
        }
    }

    # Special string values
    if (!$ref) {
        return bless \_str2obj($num), $class;
    }

    # Already a __PACKAGE__ object
    if ($ref eq __PACKAGE__) {
        return $num;
    }

    # GMPz
    if ($ref eq 'Math::GMPz') {
        return bless \Math::GMPz::Rmpz_init_set($num);
    }

    # MPFR
    if ($ref eq 'Math::MPFR') {
        my $r = Math::MPFR::Rmpfr_init2(CORE::int($PREC));
        Math::MPFR::Rmpfr_set($r, $num, $ROUND);
        return bless \$r;
    }

    # MPC
    if ($ref eq 'Math::MPC') {
        my $r = Math::MPC::Rmpc_init2(CORE::int($PREC));
        Math::MPC::Rmpc_set($r, $num, $ROUND);
        return bless \$r;
    }

    # GMPq
    if ($ref eq 'Math::GMPq') {
        my $r = Math::GMPq::Rmpq_init();
        Math::GMPq::Rmpq_set($r, $num);
        return bless \$r;
    }

    bless \_star2obj($num), $class;
}

sub new_si {
    my ($class, $si) = @_;
    bless \Math::GMPz::Rmpz_init_set_si($si), $class;
}

sub new_ui {
    my ($class, $ui) = @_;
    bless \Math::GMPz::Rmpz_init_set_ui($ui), $class;
}

sub new_z {
    my ($class, $str, $base) = @_;
    bless \Math::GMPz::Rmpz_init_set_str("$str", $base // 10), $class;
}

sub new_q {
    my ($class, $num, $den, $base) = @_;
    my $r = Math::GMPq::Rmpq_init();

    if (defined($den)) {
        Math::GMPq::Rmpq_set_str($r, "$num/$den", $base // 10);
    }
    else {
        Math::GMPq::Rmpq_set_str($r, "$num", $base // 10);
    }

    Math::GMPq::Rmpq_canonicalize($r);
    bless \$r, $class;
}

sub new_f {
    my ($class, $str, $base) = @_;
    my $r = Math::MPFR::Rmpfr_init2($PREC);
    Math::MPFR::Rmpfr_set_str($r, "$str", $base // 10, $ROUND);
    bless \$r, $class;
}

sub new_c {
    my ($class, $real, $imag, $base) = @_;

    my $c = Math::MPC::Rmpc_init2($PREC);

    if (defined($imag)) {
        my $re = Math::MPFR::Rmpfr_init2($PREC);
        my $im = Math::MPFR::Rmpfr_init2($PREC);

        Math::MPFR::Rmpfr_set_str($re, "$real", $base // 10, $ROUND);
        Math::MPFR::Rmpfr_set_str($im, "$imag", $base // 10, $ROUND);

        Math::MPC::Rmpc_set_fr_fr($c, $re, $im, $ROUND);
    }
    else {
        Math::MPC::Rmpc_set_str($c, "$real", $base // 10, $ROUND);
    }

    bless \$c, $class;
}

sub _nan {
    state $nan = do {
        my $r = Math::MPFR::Rmpfr_init2($PREC);
        Math::MPFR::Rmpfr_set_nan($r);
        $r;
    };
}

sub nan {
    state $nan = do {
        my $r = Math::MPFR::Rmpfr_init2($PREC);
        Math::MPFR::Rmpfr_set_nan($r);
        bless \$r;
    };
}

sub _inf {
    state $inf = do {
        my $r = Math::MPFR::Rmpfr_init2($PREC);
        Math::MPFR::Rmpfr_set_inf($r, 1);
        $r;
    };
}

sub inf {
    state $inf = do {
        my $r = Math::MPFR::Rmpfr_init2($PREC);
        Math::MPFR::Rmpfr_set_inf($r, 1);
        bless \$r;
    };
}

sub _ninf {
    state $ninf = do {
        my $r = Math::MPFR::Rmpfr_init2($PREC);
        Math::MPFR::Rmpfr_set_inf($r, -1);
        $r;
    };
}

sub ninf {
    state $ninf = do {
        my $r = Math::MPFR::Rmpfr_init2($PREC);
        Math::MPFR::Rmpfr_set_inf($r, -1);
        bless \$r;
    };
}

sub _zero {
    state $zero = Math::GMPz::Rmpz_init_set_ui(0);
}

sub zero {
    state $zero = do {
        my $r = Math::GMPz::Rmpz_init_set_ui(0);
        bless \$r;
    };
}

sub _one {
    state $one = Math::GMPz::Rmpz_init_set_ui(1);
}

sub one {
    state $one = do {
        my $r = Math::GMPz::Rmpz_init_set_ui(1);
        bless \$r;
    };
}

sub _mone {
    state $mone = Math::GMPz::Rmpz_init_set_si(-1);
}

sub mone {
    state $mone = do {
        my $r = Math::GMPz::Rmpz_init_set_si(-1);
        bless \$r;
    };
}

#
## CONSTANTS
#

sub pi {
    my $pi = Math::MPFR::Rmpfr_init2($PREC);
    Math::MPFR::Rmpfr_const_pi($pi, $ROUND);
    bless \$pi;
}

sub tau {
    my $tau = Math::MPFR::Rmpfr_init2($PREC);
    Math::MPFR::Rmpfr_const_pi($tau, $ROUND);
    Math::MPFR::Rmpfr_mul_2ui($tau, $tau, 1, $ROUND);
    bless \$tau;
}

sub ln2 {
    my $ln2 = Math::MPFR::Rmpfr_init2($PREC);
    Math::MPFR::Rmpfr_const_log2($ln2, $ROUND);
    bless \$ln2;
}

sub EulerGamma {
    my $euler = Math::MPFR::Rmpfr_init2($PREC);
    Math::MPFR::Rmpfr_const_euler($euler, $ROUND);
    bless \$euler;
}

sub CatalanG {
    my $catalan = Math::MPFR::Rmpfr_init2($PREC);
    Math::MPFR::Rmpfr_const_catalan($catalan, $ROUND);
    bless \$catalan;
}

sub i {
    my $i = Math::MPC::Rmpc_init2($PREC);
    Math::MPC::Rmpc_set_ui_ui($i, 0, 1, $ROUND);
    bless \$i;
}

sub e {
    state $one_f = (Math::MPFR::Rmpfr_init_set_ui_nobless(1, $ROUND))[0];
    my $e = Math::MPFR::Rmpfr_init2($PREC);
    Math::MPFR::Rmpfr_exp($e, $one_f, $ROUND);
    bless \$e;
}

sub phi {
    state $five4_f = (Math::MPFR::Rmpfr_init_set_d_nobless(1.25, $ROUND))[0];

    my $phi = Math::MPFR::Rmpfr_init2($PREC);
    Math::MPFR::Rmpfr_sqrt($phi, $five4_f, $ROUND);
    Math::MPFR::Rmpfr_add_d($phi, $phi, 0.5, $ROUND);

    bless \$phi;
}

#
## Stringification
#

sub __stringify__ {
    my ($x) = @_;
    goto(ref($x) =~ tr/:/_/rs);

  Math_GMPz: {
        return Math::GMPz::Rmpz_get_str($x, 10);
    }

  Math_GMPq: {
        return Math::GMPq::Rmpq_get_str($x, 10);
    }

  Math_MPFR: {

        Math::MPFR::Rmpfr_number_p($x)
          || return (
                       Math::MPFR::Rmpfr_nan_p($x)   ? 'NaN'
                     : Math::MPFR::Rmpfr_sgn($x) < 0 ? '-Inf'
                     :                                 'Inf'
                    );

        # log(10)/log(2) =~ 3.3219280948873623
        my $digits = $PREC >> 2;
        my ($mantissa, $exponent) = Math::MPFR::Rmpfr_deref2($x, 10, $digits, $ROUND);

        my $sgn = '';
        if (substr($mantissa, 0, 1) eq '-') {
            $sgn = substr($mantissa, 0, 1, '');
        }

        $mantissa == 0 and return '0';

        if (CORE::abs($exponent) < CORE::length($mantissa)) {

            if ($exponent > 0) {
                substr($mantissa, $exponent, 0, '.');
            }
            else {
                substr($mantissa, 0, 0, '0.' . ('0' x CORE::abs($exponent)));
            }

            $mantissa = reverse($mantissa);
            $mantissa =~ s/^0+//;
            $mantissa =~ s/^\.//;
            $mantissa = reverse($mantissa);

            return ($sgn . $mantissa);
        }

        substr($mantissa, 1, 0, '.');
        return ($sgn . $mantissa . 'e' . ($exponent - 1));
    }

  Math_MPC: {
        my $fr = Math::MPFR::Rmpfr_init2($PREC);

        Math::MPC::RMPC_RE($fr, $x);
        my $re = __stringify__($fr);

        Math::MPC::RMPC_IM($fr, $x);
        my $im = __stringify__($fr);

        if ($im eq '0' or $im eq '-0') {
            return $re;
        }

        my $sign = '+';

        if (substr($im, 0, 1) eq '-') {
            $sign = '-';
            substr($im, 0, 1, '');
        }

        $im = '' if $im eq '1';
        return ($re eq '0' ? $sign eq '+' ? "${im}i" : "$sign${im}i" : "$re$sign${im}i");
    }
}

sub stringify {    # used in overloading
    @_ = (${$_[0]});
    goto &__stringify__;
}

#
## Numification (object to a native integer or a double)
#

sub numify {    # used in overloading
    my $x = ${$_[0]};

    goto(ref($x) =~ tr/:/_/rs);

  Math_MPFR: {
        if (Math::MPFR::Rmpfr_integer_p($x)) {

            if (Math::MPFR::Rmpfr_fits_ulong_p($x, $ROUND)) {
                return Math::MPFR::Rmpfr_get_ui($x, $ROUND);
            }

            if (Math::MPFR::Rmpfr_fits_slong_p($x, $ROUND)) {
                return Math::MPFR::Rmpfr_get_si($x, $ROUND);
            }
        }

        return Math::MPFR::Rmpfr_get_d($x, $ROUND);
    }

  Math_GMPq: {

        if (Math::GMPq::Rmpq_integer_p($x)) {
            $x = _mpq2mpz($x);
            goto Math_GMPz;
        }

        return Math::GMPq::Rmpq_get_d($x);
    }

  Math_GMPz: {

        if (Math::GMPz::Rmpz_fits_ulong_p($x)) {
            return Math::GMPz::Rmpz_get_ui($x);
        }

        if (Math::GMPz::Rmpz_fits_slong_p($x)) {
            return Math::GMPz::Rmpz_get_si($x);
        }

        return Math::GMPz::Rmpz_get_str($x, 10);
    }

  Math_MPC: {
        my $r = Math::MPFR::Rmpfr_init2($PREC);
        Math::MPC::RMPC_RE($r, $x);
        $x = $r;
        goto Math_MPFR;
    }
}

sub boolify {    # used in overloading
    my $x = ${$_[0]};

    goto(ref($x) =~ tr/:/_/rs);

  Math_MPFR: {
        return !!Math::MPFR::Rmpfr_sgn($x);
    }

  Math_GMPq: {
        return !!Math::GMPq::Rmpq_sgn($x);
    }

  Math_GMPz: {
        return !!Math::GMPz::Rmpz_sgn($x);
    }

  Math_MPC: {
        my $r = Math::MPFR::Rmpfr_init2($PREC);
        Math::MPC::RMPC_RE($r, $x);
        Math::MPFR::Rmpfr_sgn($r)   && return 1;
        Math::MPFR::Rmpfr_nan_p($r) && return 0;
        Math::MPC::RMPC_IM($r, $x);
        return !!Math::MPFR::Rmpfr_sgn($r);
    }
}

#
## EQUALITY
#

sub __eq__ {
    my ($x, $y) = @_;
    goto(join('__', ref($x), ref($y) || 'Scalar') =~ tr/:/_/rs);

    #
    ## MPFR
    #
  Math_MPFR__Math_MPFR: {
        return Math::MPFR::Rmpfr_equal_p($x, $y);
    }

  Math_MPFR__Math_GMPz: {
        return (Math::MPFR::Rmpfr_integer_p($x) and Math::MPFR::Rmpfr_cmp_z($x, $y) == 0);
    }

  Math_MPFR__Math_GMPq: {
        return (Math::MPFR::Rmpfr_number_p($x) and Math::MPFR::Rmpfr_cmp_q($x, $y) == 0);
    }

  Math_MPFR__Math_MPC: {
        $x = _mpfr2mpc($x);
        goto Math_MPC__Math_MPC;
    }

  Math_MPFR__Scalar: {
        return (
                Math::MPFR::Rmpfr_integer_p($x)
                  and (
                       ($y || return !Math::MPFR::Rmpfr_sgn($x)) < 0
                       ? Math::MPFR::Rmpfr_cmp_si($x, $y)
                       : Math::MPFR::Rmpfr_cmp_ui($x, $y)
                  ) == 0
               );
    }

    #
    ## GMPq
    #
  Math_GMPq__Math_GMPq: {
        return Math::GMPq::Rmpq_equal($x, $y);
    }

  Math_GMPq__Math_GMPz: {
        return (Math::GMPq::Rmpq_integer_p($x) and Math::GMPq::Rmpq_cmp_z($x, $y) == 0);
    }

  Math_GMPq__Math_MPFR: {
        return (Math::MPFR::Rmpfr_number_p($y) and Math::MPFR::Rmpfr_cmp_q($y, $x) == 0);
    }

  Math_GMPq__Math_MPC: {
        $x = _mpq2mpc($x);
        goto Math_MPC__Math_MPC;
    }

  Math_GMPq__Scalar: {
        return (
                Math::GMPq::Rmpq_integer_p($x)
                  and (
                       ($y || return !Math::GMPq::Rmpq_sgn($x)) < 0
                       ? Math::GMPq::Rmpq_cmp_si($x, $y, 1)
                       : Math::GMPq::Rmpq_cmp_ui($x, $y, 1)
                  ) == 0
               );
    }

    #
    ## GMPz
    #
  Math_GMPz__Math_GMPz: {
        return (Math::GMPz::Rmpz_cmp($x, $y) == 0);
    }

  Math_GMPz__Math_GMPq: {
        return (Math::GMPq::Rmpq_integer_p($y) and Math::GMPq::Rmpq_cmp_z($y, $x) == 0);
    }

  Math_GMPz__Math_MPFR: {
        return (Math::MPFR::Rmpfr_integer_p($y) and Math::MPFR::Rmpfr_cmp_z($y, $x) == 0);
    }

  Math_GMPz__Math_MPC: {
        $x = _mpz2mpc($x);
        goto Math_MPC__Math_MPC;
    }

  Math_GMPz__Scalar: {
        return (
                (
                 ($y || return !Math::GMPz::Rmpz_sgn($x)) < 0
                 ? Math::GMPz::Rmpz_cmp_si($x, $y)
                 : Math::GMPz::Rmpz_cmp_ui($x, $y)
                ) == 0
               );
    }

    #
    ## MPC
    #
  Math_MPC__Math_MPC: {

        my $f1 = Math::MPFR::Rmpfr_init2($PREC);
        my $f2 = Math::MPFR::Rmpfr_init2($PREC);

        Math::MPC::RMPC_RE($f1, $x);
        Math::MPC::RMPC_RE($f2, $y);

        Math::MPFR::Rmpfr_equal_p($f1, $f2) || return 0;

        Math::MPC::RMPC_IM($f1, $x);
        Math::MPC::RMPC_IM($f2, $y);

        return Math::MPFR::Rmpfr_equal_p($f1, $f2);
    }

  Math_MPC__Math_GMPz: {
        $y = _mpz2mpc($y);
        goto Math_MPC__Math_MPC;
    }

  Math_MPC__Math_GMPq: {
        $y = _mpq2mpc($y);
        goto Math_MPC__Math_MPC;
    }

  Math_MPC__Math_MPFR: {
        $y = _mpfr2mpc($y);
        goto Math_MPC__Math_MPC;
    }

  Math_MPC__Scalar: {
        my $f = Math::MPFR::Rmpfr_init2($PREC);
        Math::MPC::RMPC_IM($f, $x);
        Math::MPFR::Rmpfr_zero_p($f) || return 0;
        Math::MPC::RMPC_RE($f, $x);
        $x = $f;
        goto Math_MPFR__Scalar;
    }
}

sub eq {    # used in overloading
    my ($x, $y) = @_;

    if (ref($y) eq __PACKAGE__) {
        @_ = ($$x, $$y);
        goto &__eq__;
    }

    if (!ref($y)) {
        if (CORE::int($y) eq $y and $y < ULONG_MAX and $y > LONG_MIN) {
            @_ = ($$x, $y);
        }
        else {
            @_ = ($$x, _str2obj($y));
        }
        goto &__eq__;
    }

    @_ = ($$x, _star2obj($y));
    goto &__eq__;
}

#
## INEQUALITY
#

sub __ne__ {
    my ($x, $y) = @_;
    goto(join('__', ref($x), ref($y) || 'Scalar') =~ tr/:/_/rs);

    #
    ## MPFR
    #
  Math_MPFR__Math_MPFR: {
        return !Math::MPFR::Rmpfr_equal_p($x, $y);
    }

  Math_MPFR__Math_GMPz: {
        return (!Math::MPFR::Rmpfr_integer_p($x) or Math::MPFR::Rmpfr_cmp_z($x, $y) != 0);
    }

  Math_MPFR__Math_GMPq: {
        return (!Math::MPFR::Rmpfr_number_p($x) or Math::MPFR::Rmpfr_cmp_q($x, $y) != 0);
    }

  Math_MPFR__Math_MPC: {
        $x = _mpfr2mpc($x);
        goto Math_MPC__Math_MPC;
    }

  Math_MPFR__Scalar: {
        return (
                !Math::MPFR::Rmpfr_integer_p($x)
                  or (
                      ($y || return !!Math::MPFR::Rmpfr_sgn($x)) < 0
                      ? Math::MPFR::Rmpfr_cmp_si($x, $y)
                      : Math::MPFR::Rmpfr_cmp_ui($x, $y)
                  ) != 0
               );
    }

    #
    ## GMPq
    #
  Math_GMPq__Math_GMPq: {
        return !Math::GMPq::Rmpq_equal($x, $y);
    }

  Math_GMPq__Math_GMPz: {
        return (!Math::GMPq::Rmpq_integer_p($x) or Math::GMPq::Rmpq_cmp_z($x, $y) != 0);
    }

  Math_GMPq__Math_MPFR: {
        return (!Math::MPFR::Rmpfr_number_p($y) or Math::MPFR::Rmpfr_cmp_q($y, $x) != 0);
    }

  Math_GMPq__Math_MPC: {
        $x = _mpq2mpc($x);
        goto Math_MPC__Math_MPC;
    }

  Math_GMPq__Scalar: {
        return (
                !Math::GMPq::Rmpq_integer_p($x)
                  or (
                      ($y || return !!Math::GMPq::Rmpq_sgn($x)) < 0
                      ? Math::GMPq::Rmpq_cmp_si($x, $y, 1)
                      : Math::GMPq::Rmpq_cmp_ui($x, $y, 1)
                  ) != 0
               );
    }

    #
    ## GMPz
    #
  Math_GMPz__Math_GMPz: {
        return (Math::GMPz::Rmpz_cmp($x, $y) != 0);
    }

  Math_GMPz__Math_GMPq: {
        return (!Math::GMPq::Rmpq_integer_p($y) or Math::GMPq::Rmpq_cmp_z($y, $x) != 0);
    }

  Math_GMPz__Math_MPFR: {
        return (!Math::MPFR::Rmpfr_integer_p($y) or Math::MPFR::Rmpfr_cmp_z($y, $x) != 0);
    }

  Math_GMPz__Math_MPC: {
        $x = _mpz2mpc($x);
        goto Math_MPC__Math_MPC;
    }

  Math_GMPz__Scalar: {
        return (
                (
                 ($y || return !!Math::GMPz::Rmpz_sgn($x)) < 0
                 ? Math::GMPz::Rmpz_cmp_si($x, $y)
                 : Math::GMPz::Rmpz_cmp_ui($x, $y)
                ) != 0
               );
    }

    #
    ## MPC
    #
  Math_MPC__Math_MPC: {

        my $f1 = Math::MPFR::Rmpfr_init2($PREC);
        my $f2 = Math::MPFR::Rmpfr_init2($PREC);

        Math::MPC::RMPC_RE($f1, $x);
        Math::MPC::RMPC_RE($f2, $y);

        Math::MPFR::Rmpfr_equal_p($f1, $f2) || return 1;

        Math::MPC::RMPC_IM($f1, $x);
        Math::MPC::RMPC_IM($f2, $y);

        return !Math::MPFR::Rmpfr_equal_p($f1, $f2);
    }

  Math_MPC__Math_GMPz: {
        $y = _mpz2mpc($y);
        goto Math_MPC__Math_MPC;
    }

  Math_MPC__Math_GMPq: {
        $y = _mpq2mpc($y);
        goto Math_MPC__Math_MPC;
    }

  Math_MPC__Math_MPFR: {
        $y = _mpfr2mpc($y);
        goto Math_MPC__Math_MPC;
    }

  Math_MPC__Scalar: {
        my $f = Math::MPFR::Rmpfr_init2($PREC);
        Math::MPC::RMPC_IM($f, $x);
        Math::MPFR::Rmpfr_zero_p($f) || return 1;
        Math::MPC::RMPC_RE($f, $x);
        $x = $f;
        goto Math_MPFR__Scalar;
    }
}

sub ne {    # used in overloading
    my ($x, $y) = @_;

    if (ref($y) eq __PACKAGE__) {
        @_ = ($$x, $$y);
        goto &__ne__;
    }

    if (!ref($y)) {
        if (CORE::int($y) eq $y and $y < ULONG_MAX and $y > LONG_MIN) {
            @_ = ($$x, $y);
        }
        else {
            @_ = ($$x, _str2obj($y));
        }
        goto &__ne__;
    }

    @_ = ($$x, _star2obj($y));
    goto &__ne__;
}

#
## COMPARISON
#

sub __cmp__ {
    my ($x, $y) = @_;
    goto(join('__', ref($x), ref($y) || 'Scalar') =~ tr/:/_/rs);

    #
    ## MPFR
    #
  Math_MPFR__Math_MPFR: {

        if (   Math::MPFR::Rmpfr_nan_p($x)
            or Math::MPFR::Rmpfr_nan_p($y)) {
            return undef;
        }

        return Math::MPFR::Rmpfr_cmp($x, $y);
    }

  Math_MPFR__Math_GMPz: {
        return (
                Math::MPFR::Rmpfr_nan_p($x)
                ? undef
                : Math::MPFR::Rmpfr_cmp_z($x, $y)
               );
    }

  Math_MPFR__Math_GMPq: {
        return (
                Math::MPFR::Rmpfr_nan_p($x)
                ? undef
                : Math::MPFR::Rmpfr_cmp_q($x, $y)
               );
    }

  Math_MPFR__Math_MPC: {
        $x = _mpfr2mpc($x);
        goto Math_MPC__Math_MPC;
    }

  Math_MPFR__Scalar: {
        return (
                  Math::MPFR::Rmpfr_nan_p($x)                  ? undef
                : ($y || return Math::MPFR::Rmpfr_sgn($x)) < 0 ? Math::MPFR::Rmpfr_cmp_si($x, $y)
                :                                                Math::MPFR::Rmpfr_cmp_ui($x, $y)
               );
    }

    #
    ## GMPq
    #
  Math_GMPq__Math_GMPq: {
        return Math::GMPq::Rmpq_cmp($x, $y);
    }

  Math_GMPq__Math_GMPz: {
        return Math::GMPq::Rmpq_cmp_z($x, $y);
    }

  Math_GMPq__Math_MPFR: {
        return (
                Math::MPFR::Rmpfr_nan_p($y)
                ? undef
                : -Math::MPFR::Rmpfr_cmp_q($y, $x)
               );
    }

  Math_GMPq__Math_MPC: {
        $x = _mpq2mpc($x);
        goto Math_MPC__Math_MPC;
    }

  Math_GMPq__Scalar: {
        return (
                ($y || return Math::GMPq::Rmpq_sgn($x)) < 0
                ? Math::GMPq::Rmpq_cmp_si($x, $y, 1)
                : Math::GMPq::Rmpq_cmp_ui($x, $y, 1)
               );
    }

    #
    ## GMPz
    #
  Math_GMPz__Math_GMPz: {
        return Math::GMPz::Rmpz_cmp($x, $y);
    }

  Math_GMPz__Math_GMPq: {
        return -Math::GMPq::Rmpq_cmp_z($y, $x);
    }

  Math_GMPz__Math_MPFR: {
        return (
                Math::MPFR::Rmpfr_nan_p($y)
                ? undef
                : -Math::MPFR::Rmpfr_cmp_z($y, $x)
               );
    }

  Math_GMPz__Math_MPC: {
        $x = _mpz2mpc($x);
        goto Math_MPC__Math_MPC;
    }

  Math_GMPz__Scalar: {
        return (
                ($y || return Math::GMPz::Rmpz_sgn($x)) < 0
                ? Math::GMPz::Rmpz_cmp_si($x, $y)
                : Math::GMPz::Rmpz_cmp_ui($x, $y)
               );
    }

    #
    ## MPC
    #
  Math_MPC__Math_MPC: {
        my $f = Math::MPFR::Rmpfr_init2($PREC);

        Math::MPC::RMPC_RE($f, $x);
        Math::MPFR::Rmpfr_nan_p($f) && return undef;

        Math::MPC::RMPC_RE($f, $y);
        Math::MPFR::Rmpfr_nan_p($f) && return undef;

        Math::MPC::RMPC_IM($f, $x);
        Math::MPFR::Rmpfr_nan_p($f) && return undef;

        Math::MPC::RMPC_IM($f, $y);
        Math::MPFR::Rmpfr_nan_p($f) && return undef;

        my $si     = Math::MPC::Rmpc_cmp($x, $y);
        my $re_cmp = Math::MPC::RMPC_INEX_RE($si);

        return (
                ($re_cmp == 0)
                ? Math::MPC::RMPC_INEX_IM($si)
                : $re_cmp
               );
    }

  Math_MPC__Math_GMPz: {
        $y = _mpz2mpc($y);
        goto Math_MPC__Math_MPC;
    }

  Math_MPC__Math_GMPq: {
        $y = _mpq2mpc($y);
        goto Math_MPC__Math_MPC;
    }

  Math_MPC__Math_MPFR: {
        $y = _mpfr2mpc($y);
        goto Math_MPC__Math_MPC;
    }

  Math_MPC__Scalar: {
        $y = _any2mpc(_str2obj($y));
        goto Math_MPC__Math_MPC;
    }
}

sub cmp ($$) {
    my ($x, $y) = @_;

    if (ref($y) eq __PACKAGE__) {
        @_ = ($$x, $$y);
        goto &__cmp__;
    }

    if (!ref($y)) {
        if (CORE::int($y) eq $y and $y < ULONG_MAX and $y > LONG_MIN) {
            @_ = ($$x, $y);
        }
        else {
            @_ = ($$x, _str2obj($y));
        }
        goto &__cmp__;
    }

    @_ = ($$x, _star2obj($y));
    goto &__cmp__;
}

# Absolute comparison

sub acmp ($$) {
    my ($x, $y) = @_;

    if (!ref($y) and CORE::int($y) eq $y and $y >= 0 and $y < ULONG_MAX) {
        ## `y` is a native unsigned integer
    }
    else {
        $y = __abs__(ref($y) eq __PACKAGE__ ? $$y : _star2obj($y));
    }

    __cmp__(__abs__(ref($x) eq __PACKAGE__ ? $$x : _star2obj($x)), $y);
}

# Approximate comparison

sub approx_cmp ($$;$) {
    my ($x, $y, $places) = @_;

    if (defined($places)) {
        if (!ref($places) and CORE::int($places) eq $places and $places > LONG_MIN and $places < ULONG_MAX) {
            ## places is a native integer
        }
        else {
            $places = _any2si(_star2obj($places)) // return undef;
        }
    }
    else {
        $places = -(($PREC >> 2) - 1);
    }

    $x = _star2obj($x);
    $y = _star2obj($y);

    if (   ref($x) eq 'Math::MPFR'
        or ref($y) eq 'Math::MPFR'
        or ref($x) eq 'Math::MPC'
        or ref($y) eq 'Math::MPC') {
        $x = _star2mpfr_mpc($x);
        $y = _star2mpfr_mpc($y);
    }

    $x = __round__($x, $places);
    $y = __round__($y, $places);

    __cmp__($x, $y);
}

#
## GREATER THAN
#

sub gt {    # used in overloading
    my ($x, $y) = @_;

    if (ref($y) eq __PACKAGE__) {
        return ((__cmp__($$x, $$y) // return undef) > 0);
    }

    if (!ref($y)) {
        if (CORE::int($y) eq $y and $y < ULONG_MAX and $y > LONG_MIN) {
            return ((__cmp__($$x, $y) // return undef) > 0);
        }
        return ((__cmp__($$x, _str2obj($y)) // return undef) > 0);
    }

    (__cmp__($$x, _star2obj($y)) // return undef) > 0;
}

#
## EQUAL OR GREATER THAN
#

sub ge {    # used in overloading
    my ($x, $y) = @_;

    if (ref($y) eq __PACKAGE__) {
        return ((__cmp__($$x, $$y) // return undef) >= 0);
    }

    if (!ref($y)) {
        if (CORE::int($y) eq $y and $y < ULONG_MAX and $y > LONG_MIN) {
            return ((__cmp__($$x, $y) // return undef) >= 0);
        }
        return ((__cmp__($$x, _str2obj($y)) // return undef) >= 0);
    }

    (__cmp__($$x, _star2obj($y)) // return undef) >= 0;
}

#
## LESS THAN
#

sub lt {    # used in overloading
    my ($x, $y) = @_;

    if (ref($y) eq __PACKAGE__) {
        return ((__cmp__($$x, $$y) // return undef) < 0);
    }

    if (!ref($y)) {
        if (CORE::int($y) eq $y and $y < ULONG_MAX and $y > LONG_MIN) {
            return ((__cmp__($$x, $y) // return undef) < 0);
        }
        return ((__cmp__($$x, _str2obj($y)) // return undef) < 0);
    }

    (__cmp__($$x, _star2obj($y)) // return undef) < 0;
}

#
## EQUAL OR LESS THAN
#

sub le {    # used in overloading
    my ($x, $y) = @_;

    if (ref($y) eq __PACKAGE__) {
        return ((__cmp__($$x, $$y) // return undef) <= 0);
    }

    if (!ref($y)) {
        if (CORE::int($y) eq $y and $y < ULONG_MAX and $y > LONG_MIN) {
            return ((__cmp__($$x, $y) // return undef) <= 0);
        }
        return ((__cmp__($$x, _str2obj($y)) // return undef) <= 0);
    }

    (__cmp__($$x, _star2obj($y)) // return undef) <= 0;
}

#
## COPY
#

sub _copy {
    my ($x) = @_;
    my $ref = ref($x);

    if ($ref eq 'Math::GMPz') {
        Math::GMPz::Rmpz_init_set($x);
    }
    elsif ($ref eq 'Math::MPFR') {
        my $r = Math::MPFR::Rmpfr_init2($PREC);
        Math::MPFR::Rmpfr_set($r, $x, $ROUND);
        $r;
    }
    elsif ($ref eq 'Math::GMPq') {
        my $r = Math::GMPq::Rmpq_init();
        Math::GMPq::Rmpq_set($r, $x);
        $r;
    }
    elsif ($ref eq 'Math::MPC') {
        my $r = Math::MPC::Rmpc_init2($PREC);
        Math::MPC::Rmpc_set($r, $x, $ROUND);
        $r;
    }
    else {
        _str2obj("$x");    # this should not happen
    }
}

sub copy ($) {
    my ($x) = @_;
    bless \_copy($$x);
}

#
## CONVERSION TO INTEGER
#

sub int {    # used in overloading
    my ($x) = @_;

    bless \(
            (
               ref($x) eq __PACKAGE__
             ? ref($$x) eq 'Math::GMPz'
                   ? (return $x)
                   : _any2mpz($$x)
             : _star2mpz($x)
            ) // goto &nan
           );
}

#
## CONVERSION TO RATIONAL
#

sub rat ($) {
    my ($x) = @_;

    if (ref($x) eq __PACKAGE__) {
        ref($$x) eq 'Math::GMPq' && return $x;
        return bless \(_any2mpq($$x) // (goto &nan));
    }

    # Parse a decimal number as an exact fraction
    if ("$x" =~ /^([+-]?+(?=\.?[0-9])[0-9_]*+(?:\.[0-9_]++)?(?:[Ee](?:[+-]?+[0-9_]+))?)\z/) {
        my $frac = _str2frac(lc($1) =~ tr/_//dr);
        my $q    = Math::GMPq::Rmpq_init();
        Math::GMPq::Rmpq_set_str($q, $frac, 10);
        Math::GMPq::Rmpq_canonicalize($q) if (index($frac, '/') != -1);
        return bless \$q;
    }

    my $r = _star2obj($x);
    ref($r) eq 'Math::GMPq' && return bless \$r;
    bless \(_any2mpq($r) // (goto &nan));
}

#
## CONVERSION TO FLOATING-POINT
#

sub float ($) {
    my ($x) = @_;

    ref($x) eq __PACKAGE__
      && (ref($$x) eq 'Math::MPFR' || ref($$x) eq 'Math::MPC')
      && return $x;

    bless \_star2mpfr_mpc($x);
}

#
## CONVERSION TO COMPLEX
#

sub complex ($;$) {
    my ($x, $y) = @_;

    if (defined $y) {
        return bless \_reals2mpc($x, $y);
    }

    bless \(
              ref($x) eq __PACKAGE__
            ? ref($$x) eq 'Math::MPC'
                  ? (return $x)
                  : _any2mpc($$x)
            : _any2mpc(_star2obj($x))
           );
}

#
## ABSOLUTE VALUE
#

sub __abs__ {
    my ($x) = @_;
    goto(ref($x) =~ tr/:/_/rs);

  Math_MPFR: {
        Math::MPFR::Rmpfr_sgn($x) >= 0 and return $x;
        my $r = Math::MPFR::Rmpfr_init2($PREC);
        Math::MPFR::Rmpfr_abs($r, $x, $ROUND);
        return $r;
    }

  Math_GMPq: {
        Math::GMPq::Rmpq_sgn($x) >= 0 and return $x;
        my $r = Math::GMPq::Rmpq_init();
        Math::GMPq::Rmpq_abs($r, $x);
        return $r;
    }

  Math_GMPz: {
        Math::GMPz::Rmpz_sgn($x) >= 0 and return $x;
        my $r = Math::GMPz::Rmpz_init();
        Math::GMPz::Rmpz_abs($r, $x);
        return $r;
    }

  Math_MPC: {
        my $r = Math::MPFR::Rmpfr_init2($PREC);
        Math::MPC::Rmpc_abs($r, $x, $ROUND);
        return $r;
    }
}

sub abs {    # used in overloading
    my ($x) = @_;
    bless \__abs__(ref($x) eq __PACKAGE__ ? $$x : _star2obj($x));
}

#
## ADDITIVE INVERSE (-x)
#

sub __neg__ {
    my ($x) = @_;
    goto(ref($x) =~ tr/:/_/rs);

  Math_MPFR: {
        my $r = Math::MPFR::Rmpfr_init2($PREC);
        Math::MPFR::Rmpfr_neg($r, $x, $ROUND);
        return $r;
    }

  Math_GMPq: {
        my $r = Math::GMPq::Rmpq_init();
        Math::GMPq::Rmpq_neg($r, $x);
        return $r;
    }

  Math_GMPz: {
        my $r = Math::GMPz::Rmpz_init();
        Math::GMPz::Rmpz_neg($r, $x);
        return $r;
    }

  Math_MPC: {
        my $r = Math::MPC::Rmpc_init2($PREC);
        Math::MPC::Rmpc_neg($r, $x, $ROUND);
        return $r;
    }
}

sub neg {    # used in overloading
    my ($x) = @_;
    bless \__neg__(ref($x) eq __PACKAGE__ ? $$x : _star2obj($x));
}

#
## MULTIPLICATIVE INVERSE (1/x)
#

sub __inv__ {
    my ($x) = @_;
    goto(ref($x) =~ tr/:/_/rs);

  Math_MPFR: {
        my $r = Math::MPFR::Rmpfr_init2($PREC);
        Math::MPFR::Rmpfr_ui_div($r, 1, $x, $ROUND);
        return $r;
    }

  Math_GMPq: {

        # Check for division by zero
        Math::GMPq::Rmpq_sgn($x) || do {
            $x = _mpq2mpfr($x);
            goto Math_MPFR;
        };

        my $r = Math::GMPq::Rmpq_init();
        Math::GMPq::Rmpq_inv($r, $x);
        return $r;
    }

  Math_GMPz: {

        # Check for division by zero
        Math::GMPz::Rmpz_sgn($x) || do {
            $x = _mpz2mpfr($x);
            goto Math_MPFR;
        };

        my $r = Math::GMPq::Rmpq_init();
        Math::GMPq::Rmpq_set_z($r, $x);
        Math::GMPq::Rmpq_inv($r, $r);
        return $r;
    }

  Math_MPC: {
        my $r = Math::MPC::Rmpc_init2($PREC);
        Math::MPC::Rmpc_ui_div($r, 1, $x, $ROUND);
        return $r;
    }
}

sub inv ($) {
    my ($x) = @_;
    bless \__inv__(ref($x) eq __PACKAGE__ ? $$x : _star2obj($x));
}

#
## INCREMENTATION BY ONE
#

sub __inc__ {
    my ($x) = @_;
    goto(ref($x) =~ tr/:/_/rs);

  Math_MPFR: {
        my $r = Math::MPFR::Rmpfr_init2($PREC);
        Math::MPFR::Rmpfr_add_ui($r, $x, 1, $ROUND);
        return $r;
    }

  Math_GMPq: {
        state $one = Math::GMPz::Rmpz_init_set_ui_nobless(1);
        my $r = Math::GMPq::Rmpq_init();
        Math::GMPq::Rmpq_add_z($r, $x, $one);
        return $r;
    }

  Math_GMPz: {
        my $r = Math::GMPz::Rmpz_init();
        Math::GMPz::Rmpz_add_ui($r, $x, 1);
        return $r;
    }

  Math_MPC: {
        my $r = Math::MPC::Rmpc_init2($PREC);
        Math::MPC::Rmpc_add_ui($r, $x, 1, $ROUND);
        return $r;
    }
}

sub inc ($) {
    my ($x) = @_;
    bless \__inc__($$x);
}

#
## DECREMENTATION BY ONE
#

sub __dec__ {
    my ($x) = @_;
    goto(ref($x) =~ tr/:/_/rs);

  Math_MPFR: {
        my $r = Math::MPFR::Rmpfr_init2($PREC);
        Math::MPFR::Rmpfr_sub_ui($r, $x, 1, $ROUND);
        return $r;
    }

  Math_GMPq: {
        state $mone = Math::GMPz::Rmpz_init_set_si_nobless(-1);
        my $r = Math::GMPq::Rmpq_init();
        Math::GMPq::Rmpq_add_z($r, $x, $mone);
        return $r;
    }

  Math_GMPz: {
        my $r = Math::GMPz::Rmpz_init();
        Math::GMPz::Rmpz_sub_ui($r, $x, 1);
        return $r;
    }

  Math_MPC: {
        my $r = Math::MPC::Rmpc_init2($PREC);
        Math::MPC::Rmpc_sub_ui($r, $x, 1, $ROUND);
        return $r;
    }
}

sub dec ($) {
    my ($x) = @_;
    bless \__dec__($$x);
}

sub conj ($) {
    my ($x) = @_;

    if (ref($x) ne __PACKAGE__) {
        $x = __PACKAGE__->new($x);
    }

    if (ref($$x) eq 'Math::MPC') {
        my $r = Math::MPC::Rmpc_init2($PREC);
        Math::MPC::Rmpc_conj($r, $$x, $ROUND);
        bless \$r;
    }
    else {
        $x;
    }
}

sub real ($) {
    my ($x) = @_;

    if (ref($x) ne __PACKAGE__) {
        $x = __PACKAGE__->new($x);
    }

    if (ref($$x) eq 'Math::MPC') {
        my $r = Math::MPFR::Rmpfr_init2($PREC);
        Math::MPC::RMPC_RE($r, $$x);
        bless \$r;
    }
    else {
        $x;
    }
}

sub imag ($) {
    my ($x) = @_;

    if (ref($x) ne __PACKAGE__) {
        $x = __PACKAGE__->new($x);
    }

    if (ref($$x) eq 'Math::MPC') {
        my $r = Math::MPFR::Rmpfr_init2($PREC);
        Math::MPC::RMPC_IM($r, $$x);
        bless \$r;
    }
    else {
        goto &zero;
    }
}

sub reals ($) {
    my ($x) = @_;

    if (ref($x) ne __PACKAGE__) {
        $x = __PACKAGE__->new($x);
    }

    ($x->real, $x->imag);
}

#
## ADDITION
#

sub __add__ {
    my ($x, $y) = @_;
    goto(join('__', ref($x), ref($y) || 'Scalar') =~ tr/:/_/rs);

    #
    ## GMPq
    #
  Math_GMPq__Math_GMPq: {
        my $r = Math::GMPq::Rmpq_init();
        Math::GMPq::Rmpq_add($r, $x, $y);
        return $r;
    }

  Math_GMPq__Math_GMPz: {
        my $r = Math::GMPq::Rmpq_init();
        Math::GMPq::Rmpq_add_z($r, $x, $y);
        return $r;
    }

  Math_GMPq__Math_MPFR: {
        my $r = Math::MPFR::Rmpfr_init2($PREC);
        Math::MPFR::Rmpfr_add_q($r, $y, $x, $ROUND);
        return $r;
    }

  Math_GMPq__Math_MPC: {
        my $c = Math::MPC::Rmpc_init2($PREC);
        Math::MPC::Rmpc_set_q($c, $x, $ROUND);
        Math::MPC::Rmpc_add($c, $c, $y, $ROUND);
        return $c;
    }

  Math_GMPq__Scalar: {
        my $r = Math::GMPq::Rmpq_init();
        $y < 0
          ? Math::GMPq::Rmpq_set_si($r, $y, 1)
          : Math::GMPq::Rmpq_set_ui($r, $y, 1);
        Math::GMPq::Rmpq_add($r, $r, $x);
        return $r;
    }

    #
    ## GMPz
    #
  Math_GMPz__Math_GMPz: {
        my $r = Math::GMPz::Rmpz_init();
        Math::GMPz::Rmpz_add($r, $x, $y);
        return $r;
    }

  Math_GMPz__Scalar: {
        my $r = Math::GMPz::Rmpz_init();
        $y < 0
          ? Math::GMPz::Rmpz_sub_ui($r, $x, -$y)
          : Math::GMPz::Rmpz_add_ui($r, $x, $y);
        return $r;
    }

  Math_GMPz__Math_GMPq: {
        my $r = Math::GMPq::Rmpq_init();
        Math::GMPq::Rmpq_add_z($r, $y, $x);
        return $r;
    }

  Math_GMPz__Math_MPFR: {
        my $f = Math::MPFR::Rmpfr_init2($PREC);
        Math::MPFR::Rmpfr_add_z($f, $y, $x, $ROUND);
        return $f;
    }

  Math_GMPz__Math_MPC: {
        my $c = Math::MPC::Rmpc_init2($PREC);
        Math::MPC::Rmpc_set_z($c, $x, $ROUND);
        Math::MPC::Rmpc_add($c, $c, $y, $ROUND);
        return $c;
    }

    #
    ## MPFR
    #
  Math_MPFR__Math_MPFR: {
        my $r = Math::MPFR::Rmpfr_init2($PREC);
        Math::MPFR::Rmpfr_add($r, $x, $y, $ROUND);
        return $r;
    }

  Math_MPFR__Scalar: {
        my $r = Math::MPFR::Rmpfr_init2($PREC);
        $y < 0
          ? Math::MPFR::Rmpfr_sub_ui($r, $x, -$y, $ROUND)
          : Math::MPFR::Rmpfr_add_ui($r, $x, $y, $ROUND);
        return $r;
    }

  Math_MPFR__Math_GMPq: {
        my $r = Math::MPFR::Rmpfr_init2($PREC);
        Math::MPFR::Rmpfr_add_q($r, $x, $y, $ROUND);
        return $r;
    }

  Math_MPFR__Math_GMPz: {
        my $r = Math::MPFR::Rmpfr_init2($PREC);
        Math::MPFR::Rmpfr_add_z($r, $x, $y, $ROUND);
        return $r;
    }

  Math_MPFR__Math_MPC: {
        my $c = Math::MPC::Rmpc_init2($PREC);
        Math::MPC::Rmpc_add_fr($c, $y, $x, $ROUND);
        return $c;
    }

    #
    ## MPC
    #
  Math_MPC__Math_MPC: {
        my $r = Math::MPC::Rmpc_init2($PREC);
        Math::MPC::Rmpc_add($r, $x, $y, $ROUND);
        return $r;
    }

  Math_MPC__Scalar: {
        my $r = Math::MPC::Rmpc_init2($PREC);
        $y < 0
          ? Math::MPC::Rmpc_sub_ui($r, $x, -$y, $ROUND)
          : Math::MPC::Rmpc_add_ui($r, $x, $y, $ROUND);
        return $r;
    }

  Math_MPC__Math_MPFR: {
        my $r = Math::MPC::Rmpc_init2($PREC);
        Math::MPC::Rmpc_add_fr($r, $x, $y, $ROUND);
        return $r;
    }

  Math_MPC__Math_GMPz: {
        my $r = Math::MPC::Rmpc_init2($PREC);
        Math::MPC::Rmpc_set_z($r, $y, $ROUND);
        Math::MPC::Rmpc_add($r, $r, $x, $ROUND);
        return $r;
    }

  Math_MPC__Math_GMPq: {
        my $r = Math::MPC::Rmpc_init2($PREC);
        Math::MPC::Rmpc_set_q($r, $y, $ROUND);
        Math::MPC::Rmpc_add($r, $r, $x, $ROUND);
        return $r;
    }
}

sub add {    # used in overloading
    my ($x, $y) = @_;

    if (ref($y) eq __PACKAGE__) {
        return bless \__add__($$x, $$y);
    }

    $x = $$x;

    if (!ref($y)) {
        if (CORE::int($y) eq $y and $y < ULONG_MAX and $y > LONG_MIN) {
            return bless \__add__($x, $y);
        }

        return bless \__add__($x, _str2obj($y));
    }

    bless \__add__($x, _star2obj($y));
}

#
## SUBTRACTION
#

sub __sub__ {
    my ($x, $y) = @_;
    goto(join('__', ref($x) || 'Scalar', ref($y) || 'Scalar') =~ tr/:/_/rs);

    #
    ## GMPq
    #
  Math_GMPq__Math_GMPq: {
        my $r = Math::GMPq::Rmpq_init();
        Math::GMPq::Rmpq_sub($r, $x, $y);
        return $r;
    }

  Math_GMPq__Math_GMPz: {
        my $r = Math::GMPq::Rmpq_init();
        Math::GMPq::Rmpq_sub_z($r, $x, $y);
        return $r;
    }

  Math_GMPq__Math_MPFR: {
        my $r = Math::MPFR::Rmpfr_init2($PREC);
        Math::MPFR::Rmpfr_sub_q($r, $y, $x, $ROUND);
        Math::MPFR::Rmpfr_neg($r, $r, $ROUND);
        return $r;
    }

  Math_GMPq__Math_MPC: {
        my $r = Math::MPC::Rmpc_init2($PREC);
        Math::MPC::Rmpc_set_q($r, $x, $ROUND);
        Math::MPC::Rmpc_sub($r, $r, $y, $ROUND);
        return $r;
    }

  Math_GMPq__Scalar: {
        my $r = Math::GMPq::Rmpq_init();
        $y < 0
          ? Math::GMPq::Rmpq_set_si($r, $y, 1)
          : Math::GMPq::Rmpq_set_ui($r, $y, 1);
        Math::GMPq::Rmpq_sub($r, $x, $r);
        return $r;
    }

  Scalar__Math_GMPq: {
        my $r = Math::GMPq::Rmpq_init();
        $x < 0
          ? Math::GMPq::Rmpq_set_si($r, $x, 1)
          : Math::GMPq::Rmpq_set_ui($r, $x, 1);
        Math::GMPq::Rmpq_sub($r, $r, $y);
        return $r;
    }

    #
    ## GMPz
    #
  Math_GMPz__Math_GMPz: {
        my $r = Math::GMPz::Rmpz_init();
        Math::GMPz::Rmpz_sub($r, $x, $y);
        return $r;
    }

  Math_GMPz__Scalar: {
        my $r = Math::GMPz::Rmpz_init();
        $y < 0
          ? Math::GMPz::Rmpz_add_ui($r, $x, -$y)
          : Math::GMPz::Rmpz_sub_ui($r, $x, $y);
        return $r;
    }

  Scalar__Math_GMPz: {
        my $r = Math::GMPz::Rmpz_init();
        $x < 0
          ? do {
            Math::GMPz::Rmpz_add_ui($r, $y, -$x);
            Math::GMPz::Rmpz_neg($r, $r);
          }
          : Math::GMPz::Rmpz_ui_sub($r, $x, $y);
        return $r;
    }

  Math_GMPz__Math_GMPq: {
        my $r = Math::GMPq::Rmpq_init();
        Math::GMPq::Rmpq_z_sub($r, $x, $y);
        return $r;
    }

  Math_GMPz__Math_MPFR: {
        my $r = Math::MPFR::Rmpfr_init2($PREC);

#<<<
        state $has_z_sub = (Math::MPFR::MPFR_VERSION_MAJOR() >  3)
                        || (Math::MPFR::MPFR_VERSION_MAJOR() == 3
                        &&  Math::MPFR::MPFR_VERSION_MINOR() >= 1);
#>>>

        $has_z_sub
          ? Math::MPFR::Rmpfr_z_sub($r, $x, $y, $ROUND)
          : do {
            Math::MPFR::Rmpfr_sub_z($r, $y, $x, $ROUND);
            Math::MPFR::Rmpfr_neg($r, $r, $ROUND);
          };

        return $r;
    }

  Math_GMPz__Math_MPC: {
        my $r = Math::MPC::Rmpc_init2($PREC);
        Math::MPC::Rmpc_set_z($r, $x, $ROUND);
        Math::MPC::Rmpc_sub($r, $r, $y, $ROUND);
        return $r;
    }

    #
    ## MPFR
    #
  Math_MPFR__Math_MPFR: {
        my $r = Math::MPFR::Rmpfr_init2($PREC);
        Math::MPFR::Rmpfr_sub($r, $x, $y, $ROUND);
        return $r;
    }

  Math_MPFR__Scalar: {
        my $r = Math::MPFR::Rmpfr_init2($PREC);
        $y < 0
          ? Math::MPFR::Rmpfr_add_ui($r, $x, -$y, $ROUND)
          : Math::MPFR::Rmpfr_sub_ui($r, $x, $y, $ROUND);
        return $r;
    }

  Scalar__Math_MPFR: {
        my $r = Math::MPFR::Rmpfr_init2($PREC);
        $x < 0
          ? Math::MPFR::Rmpfr_si_sub($r, $x, $y, $ROUND)
          : Math::MPFR::Rmpfr_ui_sub($r, $x, $y, $ROUND);
        return $r;
    }

  Math_MPFR__Math_GMPq: {
        my $r = Math::MPFR::Rmpfr_init2($PREC);
        Math::MPFR::Rmpfr_sub_q($r, $x, $y, $ROUND);
        return $r;
    }

  Math_MPFR__Math_GMPz: {
        my $r = Math::MPFR::Rmpfr_init2($PREC);
        Math::MPFR::Rmpfr_sub_z($r, $x, $y, $ROUND);
        return $r;
    }

  Math_MPFR__Math_MPC: {
        my $r = Math::MPC::Rmpc_init2($PREC);
        Math::MPC::Rmpc_set_fr($r, $x, $ROUND);
        Math::MPC::Rmpc_sub($r, $r, $y, $ROUND);
        return $r;
    }

    #
    ## MPC
    #
  Math_MPC__Math_MPC: {
        my $r = Math::MPC::Rmpc_init2($PREC);
        Math::MPC::Rmpc_sub($r, $x, $y, $ROUND);
        return $r;
    }

  Math_MPC__Scalar: {
        my $r = Math::MPC::Rmpc_init2($PREC);
        $y < 0
          ? Math::MPC::Rmpc_add_ui($r, $x, -$y, $ROUND)
          : Math::MPC::Rmpc_sub_ui($r, $x, $y, $ROUND);
        return $r;
    }

  Scalar__Math_MPC: {
        my $r = Math::MPC::Rmpc_init2($PREC);
        $x < 0
          ? do {
            Math::MPC::Rmpc_add_ui($r, $y, -$x, $ROUND);
            Math::MPC::Rmpc_neg($r, $r, $ROUND);
          }
          : Math::MPC::Rmpc_ui_sub($r, $x, $y, $ROUND);
        return $r;
    }

  Math_MPC__Math_MPFR: {
        my $r = Math::MPC::Rmpc_init2($PREC);
        Math::MPC::Rmpc_set_fr($r, $y, $ROUND);
        Math::MPC::Rmpc_sub($r, $x, $r, $ROUND);
        return $r;
    }

  Math_MPC__Math_GMPz: {
        my $r = Math::MPC::Rmpc_init2($PREC);
        Math::MPC::Rmpc_set_z($r, $y, $ROUND);
        Math::MPC::Rmpc_sub($r, $x, $r, $ROUND);
        return $r;
    }

  Math_MPC__Math_GMPq: {
        my $r = Math::MPC::Rmpc_init2($PREC);
        Math::MPC::Rmpc_set_q($r, $y, $ROUND);
        Math::MPC::Rmpc_sub($r, $x, $r, $ROUND);
        return $r;
    }
}

sub sub {    # used in overloading
    my ($x, $y) = @_;

    if (!ref($x) and CORE::int($x) eq $x and $x < ULONG_MAX and $x > LONG_MIN) {

        if (ref($y) eq __PACKAGE__) {
            return bless \__sub__($x, $$y);
        }

        return bless \__sub__($x, ref($y) ? _star2obj($y) : _str2obj($y));
    }

    $x =
        ref($x) eq __PACKAGE__ ? $$x
      : ref($x)                ? _star2obj($x)
      :                          _str2obj($x);

    if (ref($y) eq __PACKAGE__) {
        return bless \__sub__($x, $$y);
    }

    if (!ref($y)) {
        if (CORE::int($y) eq $y and $y < ULONG_MAX and $y > LONG_MIN) {
            return bless \__sub__($x, $y);
        }

        return bless \__sub__($x, _str2obj($y));
    }

    bless \__sub__($x, _star2obj($y));
}

#
## MULTIPLICATION
#

sub __mul__ {
    my ($x, $y) = @_;
    goto(join('__', ref($x), ref($y) || 'Scalar') =~ tr/:/_/rs);

    #
    ## GMPq
    #
  Math_GMPq__Math_GMPq: {
        my $r = Math::GMPq::Rmpq_init();
        Math::GMPq::Rmpq_mul($r, $x, $y);
        return $r;
    }

  Math_GMPq__Math_GMPz: {
        my $r = Math::GMPq::Rmpq_init();
        Math::GMPq::Rmpq_mul_z($r, $x, $y);
        return $r;
    }

  Math_GMPq__Math_MPFR: {
        my $r = Math::MPFR::Rmpfr_init2($PREC);
        Math::MPFR::Rmpfr_mul_q($r, $y, $x, $ROUND);
        return $r;
    }

  Math_GMPq__Math_MPC: {
        my $r = Math::MPC::Rmpc_init2($PREC);
        Math::MPC::Rmpc_set_q($r, $x, $ROUND);
        Math::MPC::Rmpc_mul($r, $r, $y, $ROUND);
        return $r;
    }

  Math_GMPq__Scalar: {
        my $r = Math::GMPq::Rmpq_init();
        $y < 0
          ? Math::GMPq::Rmpq_set_si($r, $y, 1)
          : Math::GMPq::Rmpq_set_ui($r, $y, 1);
        Math::GMPq::Rmpq_mul($r, $r, $x);
        return $r;
    }

    #
    ## GMPz
    #
  Math_GMPz__Math_GMPz: {
        my $r = Math::GMPz::Rmpz_init();
        Math::GMPz::Rmpz_mul($r, $x, $y);
        return $r;
    }

  Math_GMPz__Scalar: {
        my $r = Math::GMPz::Rmpz_init();
        $y < 0
          ? Math::GMPz::Rmpz_mul_si($r, $x, $y)
          : Math::GMPz::Rmpz_mul_ui($r, $x, $y);
        return $r;
    }

  Math_GMPz__Math_GMPq: {
        my $r = Math::GMPq::Rmpq_init();
        Math::GMPq::Rmpq_mul_z($r, $y, $x);
        return $r;
    }

  Math_GMPz__Math_MPFR: {
        my $f = Math::MPFR::Rmpfr_init2($PREC);
        Math::MPFR::Rmpfr_mul_z($f, $y, $x, $ROUND);
        return $f;
    }

  Math_GMPz__Math_MPC: {
        my $r = Math::MPC::Rmpc_init2($PREC);
        Math::MPC::Rmpc_set_z($r, $x, $ROUND);
        Math::MPC::Rmpc_mul($r, $r, $y, $ROUND);
        return $r;
    }

    #
    ## MPFR
    #
  Math_MPFR__Math_MPFR: {
        my $r = Math::MPFR::Rmpfr_init2($PREC);
        Math::MPFR::Rmpfr_mul($r, $x, $y, $ROUND);
        return $r;
    }

  Math_MPFR__Scalar: {
        my $r = Math::MPFR::Rmpfr_init2($PREC);
        $y < 0
          ? Math::MPFR::Rmpfr_mul_si($r, $x, $y, $ROUND)
          : Math::MPFR::Rmpfr_mul_ui($r, $x, $y, $ROUND);
        return $r;
    }

  Math_MPFR__Math_GMPq: {
        my $r = Math::MPFR::Rmpfr_init2($PREC);
        Math::MPFR::Rmpfr_mul_q($r, $x, $y, $ROUND);
        return $r;
    }

  Math_MPFR__Math_GMPz: {
        my $r = Math::MPFR::Rmpfr_init2($PREC);
        Math::MPFR::Rmpfr_mul_z($r, $x, $y, $ROUND);
        return $r;
    }

  Math_MPFR__Math_MPC: {
        my $r = Math::MPC::Rmpc_init2($PREC);
        Math::MPC::Rmpc_mul_fr($r, $y, $x, $ROUND);
        return $r;
    }

    #
    ## MPC
    #
  Math_MPC__Math_MPC: {
        my $r = Math::MPC::Rmpc_init2($PREC);
        Math::MPC::Rmpc_mul($r, $x, $y, $ROUND);
        return $r;
    }

  Math_MPC__Scalar: {
        my $r = Math::MPC::Rmpc_init2($PREC);
        $y < 0
          ? Math::MPC::Rmpc_mul_si($r, $x, $y, $ROUND)
          : Math::MPC::Rmpc_mul_ui($r, $x, $y, $ROUND);
        return $r;
    }

  Math_MPC__Math_MPFR: {
        my $r = Math::MPC::Rmpc_init2($PREC);
        Math::MPC::Rmpc_mul_fr($r, $x, $y, $ROUND);
        return $r;
    }

  Math_MPC__Math_GMPz: {
        my $r = Math::MPC::Rmpc_init2($PREC);
        Math::MPC::Rmpc_set_z($r, $y, $ROUND);
        Math::MPC::Rmpc_mul($r, $r, $x, $ROUND);
        return $r;
    }

  Math_MPC__Math_GMPq: {
        my $r = Math::MPC::Rmpc_init2($PREC);
        Math::MPC::Rmpc_set_q($r, $y, $ROUND);
        Math::MPC::Rmpc_mul($r, $r, $x, $ROUND);
        return $r;
    }
}

sub mul {    # used in overloading
    my ($x, $y) = @_;

    if (ref($y) eq __PACKAGE__) {
        return bless \__mul__($$x, $$y);
    }

    $x = $$x;

    if (!ref($y)) {
        if (CORE::int($y) eq $y and $y < ULONG_MAX and $y > LONG_MIN) {
            return bless \__mul__($x, $y);
        }

        return bless \__mul__($x, _str2obj($y));
    }

    bless \__mul__($x, _star2obj($y));
}

#
## DIVISION
#

sub __div__ {
    my ($x, $y) = @_;
    goto(join('__', ref($x) || 'Scalar', ref($y) || 'Scalar') =~ tr/:/_/rs);

    #
    ## GMPq
    #
  Math_GMPq__Math_GMPq: {

        # Check for division by zero
        Math::GMPq::Rmpq_sgn($y) || do {
            $x = _mpq2mpfr($x);
            goto Math_MPFR__Math_GMPq;
        };

        my $r = Math::GMPq::Rmpq_init();
        Math::GMPq::Rmpq_div($r, $x, $y);
        return $r;
    }

  Math_GMPq__Math_GMPz: {

        # Check for division by zero
        Math::GMPz::Rmpz_sgn($y) || do {
            $x = _mpq2mpfr($x);
            goto Math_MPFR__Math_GMPz;
        };

        my $r = Math::GMPq::Rmpq_init();
        Math::GMPq::Rmpq_div_z($r, $x, $y);
        return $r;
    }

  Math_GMPq__Math_MPFR: {
        my $r = Math::MPFR::Rmpfr_init2($PREC);
        Math::MPFR::Rmpfr_q_div($r, $x, $y, $ROUND);
        return $r;
    }

  Math_GMPq__Math_MPC: {
        my $r = Math::MPC::Rmpc_init2($PREC);
        Math::MPC::Rmpc_set_q($r, $x, $ROUND);
        Math::MPC::Rmpc_div($r, $r, $y, $ROUND);
        return $r;
    }

  Math_GMPq__Scalar: {
        my $r = Math::GMPq::Rmpq_init();
        $y < 0
          ? Math::GMPq::Rmpq_set_si($r, -1, -$y)
          : Math::GMPq::Rmpq_set_ui($r, 1, $y);
        Math::GMPq::Rmpq_mul($r, $r, $x);
        return $r;
    }

  Scalar__Math_GMPq: {

        # Check for division by zero
        Math::GMPq::Rmpq_sgn($y) || do {
            $y = _mpq2mpfr($y);
            goto Scalar__Math_MPFR;
        };

        my $r = Math::GMPq::Rmpq_init();

        if ($x == 1 or $x == -1) {
            Math::GMPq::Rmpq_inv($r, $y);
            Math::GMPq::Rmpq_neg($r, $r) if $x < 0;
            return $r;
        }

        $x < 0
          ? Math::GMPq::Rmpq_set_si($r, $x, 1)
          : Math::GMPq::Rmpq_set_ui($r, $x, 1);

        Math::GMPq::Rmpq_div($r, $r, $y);

        return $r;
    }

    #
    ## GMPz
    #
  Math_GMPz__Math_GMPz: {

        # Check for division by zero
        Math::GMPz::Rmpz_sgn($y) || do {
            $x = _mpz2mpfr($x);
            goto Math_MPFR__Math_GMPz;
        };

        # Check for exact divisibility
        if (Math::GMPz::Rmpz_divisible_p($x, $y)) {
            my $r = Math::GMPz::Rmpz_init();
            Math::GMPz::Rmpz_divexact($r, $x, $y);
            return $r;
        }

        my $r = Math::GMPq::Rmpq_init();
        Math::GMPq::Rmpq_set_num($r, $x);
        Math::GMPq::Rmpq_set_den($r, $y);
        Math::GMPq::Rmpq_canonicalize($r);
        return $r;
    }

  Math_GMPz__Scalar: {

        # Check for exact divisibility
        if (Math::GMPz::Rmpz_divisible_ui_p($x, CORE::abs($y))) {
            my $r = Math::GMPz::Rmpz_init();
            Math::GMPz::Rmpz_divexact_ui($r, $x, CORE::abs($y));
            Math::GMPz::Rmpz_neg($r, $r) if $y < 0;
            return $r;
        }

        my $r = Math::GMPq::Rmpq_init();
        Math::GMPq::Rmpq_set_ui($r, 1, CORE::abs($y));
        Math::GMPq::Rmpq_set_num($r, $x);
        Math::GMPq::Rmpq_neg($r, $r) if $y < 0;
        Math::GMPq::Rmpq_canonicalize($r);
        return $r;
    }

  Scalar__Math_GMPz: {

        # Check for division by zero
        Math::GMPz::Rmpz_sgn($y) || do {
            $y = _mpz2mpfr($y);
            goto Scalar__Math_MPFR;
        };

        my $r = Math::GMPq::Rmpq_init();

        if ($x == 1 or $x == -1) {
            Math::GMPq::Rmpq_set_z($r, $y);
            Math::GMPq::Rmpq_inv($r, $r);
            Math::GMPq::Rmpq_neg($r, $r) if $x < 0;
            return $r;
        }

        $x < 0
          ? Math::GMPq::Rmpq_set_si($r, $x, 1)
          : Math::GMPq::Rmpq_set_ui($r, $x, 1);

        Math::GMPq::Rmpq_set_den($r, $y);
        Math::GMPq::Rmpq_canonicalize($r);

        # If the result is an integer, return a GMPz object
        if (Math::GMPq::Rmpq_integer_p($r)) {
            my $z = Math::GMPz::Rmpz_init();
            Math::GMPq::Rmpq_get_num($z, $r);
            return $z;
        }

        return $r;
    }

  Math_GMPz__Math_GMPq: {

        # Check for division by zero
        Math::GMPq::Rmpq_sgn($y) || do {
            $x = _mpz2mpfr($x);
            goto Math_MPFR__Math_GMPq;
        };

        my $q = Math::GMPq::Rmpq_init();
        Math::GMPq::Rmpq_z_div($q, $x, $y);
        return $q;
    }

  Math_GMPz__Math_MPFR: {
        my $r = Math::MPFR::Rmpfr_init2($PREC);
        Math::MPFR::Rmpfr_z_div($r, $x, $y, $ROUND);
        return $r;
    }

  Math_GMPz__Math_MPC: {
        my $r = Math::MPC::Rmpc_init2($PREC);
        Math::MPC::Rmpc_set_z($r, $x, $ROUND);
        Math::MPC::Rmpc_div($r, $r, $y, $ROUND);
        return $r;
    }

    #
    ## MPFR
    #
  Math_MPFR__Math_MPFR: {
        my $r = Math::MPFR::Rmpfr_init2($PREC);
        Math::MPFR::Rmpfr_div($r, $x, $y, $ROUND);
        return $r;
    }

  Math_MPFR__Scalar: {
        my $r = Math::MPFR::Rmpfr_init2($PREC);
        $y < 0
          ? Math::MPFR::Rmpfr_div_si($r, $x, $y, $ROUND)
          : Math::MPFR::Rmpfr_div_ui($r, $x, $y, $ROUND);
        return $r;
    }

  Scalar__Math_MPFR: {
        my $r = Math::MPFR::Rmpfr_init2($PREC);
        $x < 0
          ? Math::MPFR::Rmpfr_si_div($r, $x, $y, $ROUND)
          : Math::MPFR::Rmpfr_ui_div($r, $x, $y, $ROUND);
        return $r;
    }

  Math_MPFR__Math_GMPq: {
        my $r = Math::MPFR::Rmpfr_init2($PREC);
        Math::MPFR::Rmpfr_div_q($r, $x, $y, $ROUND);
        return $r;
    }

  Math_MPFR__Math_GMPz: {
        my $r = Math::MPFR::Rmpfr_init2($PREC);
        Math::MPFR::Rmpfr_div_z($r, $x, $y, $ROUND);
        return $r;
    }

  Math_MPFR__Math_MPC: {
        my $r = Math::MPC::Rmpc_init2($PREC);
        Math::MPC::Rmpc_set_fr($r, $x, $ROUND);
        Math::MPC::Rmpc_div($r, $r, $y, $ROUND);
        return $r;
    }

    #
    ## MPC
    #
  Math_MPC__Math_MPC: {
        my $r = Math::MPC::Rmpc_init2($PREC);
        Math::MPC::Rmpc_div($r, $x, $y, $ROUND);
        return $r;
    }

  Math_MPC__Scalar: {
        my $r = Math::MPC::Rmpc_init2($PREC);
        if ($y < 0) {
            Math::MPC::Rmpc_div_ui($r, $x, -$y, $ROUND);
            Math::MPC::Rmpc_neg($r, $r, $ROUND);
        }
        else {
            Math::MPC::Rmpc_div_ui($r, $x, $y, $ROUND);
        }
        return $r;
    }

  Scalar__Math_MPC: {
        my $r = Math::MPC::Rmpc_init2($PREC);
        if ($x < 0) {
            Math::MPC::Rmpc_ui_div($r, -$x, $y, $ROUND);
            Math::MPC::Rmpc_neg($r, $r, $ROUND);
        }
        else {
            Math::MPC::Rmpc_ui_div($r, $x, $y, $ROUND);
        }
        return $r;
    }

  Math_MPC__Math_MPFR: {
        my $r = Math::MPC::Rmpc_init2($PREC);
        Math::MPC::Rmpc_div_fr($r, $x, $y, $ROUND);
        return $r;
    }

  Math_MPC__Math_GMPz: {
        my $r = Math::MPC::Rmpc_init2($PREC);
        Math::MPC::Rmpc_set_z($r, $y, $ROUND);
        Math::MPC::Rmpc_div($r, $x, $r, $ROUND);
        return $r;
    }

  Math_MPC__Math_GMPq: {
        my $r = Math::MPC::Rmpc_init2($PREC);
        Math::MPC::Rmpc_set_q($r, $y, $ROUND);
        Math::MPC::Rmpc_div($r, $x, $r, $ROUND);
        return $r;
    }
}

sub div {    # used in overloading
    my ($x, $y) = @_;

    if (!ref($x) and CORE::int($x) eq $x and $x < ULONG_MAX and $x > LONG_MIN) {

        if (ref($y) eq __PACKAGE__) {
            return bless \__div__($x, $$y);
        }

        return bless \__div__($x, ref($y) ? _star2obj($y) : _str2obj($y));
    }

    $x =
        ref($x) eq __PACKAGE__ ? $$x
      : ref($x)                ? _star2obj($x)
      :                          _str2obj($x);

    if (ref($y) eq __PACKAGE__) {
        return bless \__div__($x, $$y);
    }

    if (!ref($y)) {
        if (CORE::int($y) eq $y and $y < ULONG_MAX and $y > LONG_MIN and CORE::int($y)) {
            return bless \__div__($x, $y);
        }

        return bless \__div__($x, _str2obj($y));
    }

    bless \__div__($x, _star2obj($y));
}

#
## INTEGER ADDITION
#

sub iadd ($$) {
    my ($x, $y) = @_;

    if (!ref($x) and ref($y)) {
        ($x, $y) = ($y, $x);
    }

    $x = _star2mpz($x) // goto &nan;

    if (!ref($y) and CORE::int($y) eq $y and $y < ULONG_MAX and $y > LONG_MIN) {
        my $r = Math::GMPz::Rmpz_init();
        $y < 0
          ? Math::GMPz::Rmpz_sub_ui($r, $x, -$y)
          : Math::GMPz::Rmpz_add_ui($r, $x, $y);
        return bless \$r;
    }

    $y = _star2mpz($y) // goto &nan;

    my $r = Math::GMPz::Rmpz_init();
    Math::GMPz::Rmpz_add($r, $x, $y);
    bless \$r;
}

#
## INTEGER SUBTRACTION
#

sub isub ($$) {
    my ($x, $y) = @_;

    $x = _star2mpz($x) // goto &nan;

    if (!ref($y) and CORE::int($y) eq $y and $y < ULONG_MAX and $y > LONG_MIN) {
        my $r = Math::GMPz::Rmpz_init();
        $y < 0
          ? Math::GMPz::Rmpz_add_ui($r, $x, -$y)
          : Math::GMPz::Rmpz_sub_ui($r, $x, $y);
        return bless \$r;
    }

    $y = _star2mpz($y) // goto &nan;

    my $r = Math::GMPz::Rmpz_init();
    Math::GMPz::Rmpz_sub($r, $x, $y);
    bless \$r;
}

#
## INTEGER MULTIPLICATION
#

sub imul ($$) {
    my ($x, $y) = @_;

    if (!ref($x) and ref($y)) {
        ($x, $y) = ($y, $x);
    }

    $x = _star2mpz($x) // goto &nan;

    if (!ref($y) and CORE::int($y) eq $y and $y < ULONG_MAX and $y > LONG_MIN) {
        my $r = Math::GMPz::Rmpz_init();
        Math::GMPz::Rmpz_mul_ui($r, $x, $y < 0 ? -$y : $y);
        Math::GMPz::Rmpz_neg($r, $r) if $y < 0;
        return bless \$r;
    }

    $y = _star2mpz($y) // goto &nan;

    my $r = Math::GMPz::Rmpz_init();
    Math::GMPz::Rmpz_mul($r, $x, $y);
    bless \$r;
}

#
## INTEGER DIVISION
#

sub idiv ($$) {
    my ($x, $y) = @_;

    $x = _star2mpz($x) // goto &nan;

    if (!ref($y) and CORE::int($y) eq $y and CORE::int($y) > 0 and $y < ULONG_MAX) {
        my $r = Math::GMPz::Rmpz_init();
        Math::GMPz::Rmpz_div_ui($r, $x, $y);
        return bless \$r;
    }

    $y = _star2mpz($y) // goto &nan;

    # Detect division by zero
    Math::GMPz::Rmpz_sgn($y) || do {
        my $sign = Math::GMPz::Rmpz_sgn($x);

        if ($sign == 0) {    # 0/0
            goto &nan;
        }
        elsif ($sign > 0) {    # x/0 where: x > 0
            goto &inf;
        }
        else {                 # x/0 where: x < 0
            goto &ninf;
        }
    };

    my $r = Math::GMPz::Rmpz_init();
    Math::GMPz::Rmpz_div($r, $x, $y);
    bless \$r;
}

sub idiv_ceil ($$) {
    my ($x, $y) = @_;

    $x = _star2mpz($x) // (goto &nan);

    if (!ref($y) and CORE::int($y) eq $y and CORE::int($y) > 0 and $y < ULONG_MAX) {
        my $r = Math::GMPz::Rmpz_init();
        Math::GMPz::Rmpz_cdiv_q_ui($r, $x, $y);
        return bless \$r;
    }

    $y = _star2mpz($y) // (goto &nan);

    # Detect division by zero
    Math::GMPz::Rmpz_sgn($y) || do {
        my $sign = Math::GMPz::Rmpz_sgn($x);

        if ($sign == 0) {    # 0/0
            goto &nan;
        }
        elsif ($sign > 0) {    # x/0 where: x > 0
            goto &inf;
        }
        else {                 # x/0 where: x < 0
            goto &ninf;
        }
    };

    my $r = Math::GMPz::Rmpz_init();
    Math::GMPz::Rmpz_cdiv_q($r, $x, $y);
    bless \$r;
}

sub idiv_trunc ($$) {
    my ($x, $y) = @_;

    $x = _star2mpz($x) // (goto &nan);

    if (!ref($y) and CORE::int($y) eq $y and CORE::int($y) > 0 and $y < ULONG_MAX) {
        my $r = Math::GMPz::Rmpz_init();
        Math::GMPz::Rmpz_tdiv_q_ui($r, $x, $y);
        return bless \$r;
    }

    $y = _star2mpz($y) // (goto &nan);

    # Detect division by zero
    Math::GMPz::Rmpz_sgn($y) || do {
        my $sign = Math::GMPz::Rmpz_sgn($x);

        if ($sign == 0) {    # 0/0
            goto &nan;
        }
        elsif ($sign > 0) {    # x/0 where: x > 0
            goto &inf;
        }
        else {                 # x/0 where: x < 0
            goto &ninf;
        }
    };

    my $r = Math::GMPz::Rmpz_init();
    Math::GMPz::Rmpz_tdiv_q($r, $x, $y);
    bless \$r;
}

sub idiv_round ($$) {
    my ($x, $y) = @_;

    $x = _star2mpz($x) // (goto &nan);
    $y = _star2mpz($y) // (goto &nan);

    # Detect division by zero
    Math::GMPz::Rmpz_sgn($y) || do {
        my $sign = Math::GMPz::Rmpz_sgn($x);

        if ($sign == 0) {    # 0/0
            goto &nan;
        }
        elsif ($sign > 0) {    # x/0 where: x > 0
            goto &inf;
        }
        else {                 # x/0 where: x < 0
            goto &ninf;
        }
    };

    my $r = Math::GMPz::Rmpz_init();
    Math::GMPz::Rmpz_set($r, $y);
    Math::GMPz::Rmpz_addmul_ui($r, $x, 2);
    Math::GMPz::Rmpz_div($r, $r, $y);
    Math::GMPz::Rmpz_div_2exp($r, $r, 1);
    bless \$r;
}

#
## POWER (x^y)
#

sub __pow__ {
    my ($x, $y) = @_;
    goto(join('__', ref($x), ref($y) || 'Scalar') =~ tr/:/_/rs);

    #
    ## GMPq
    #
  Math_GMPq__Scalar: {

        my $r = Math::GMPq::Rmpq_init();
        Math::GMPq::Rmpq_pow_ui($r, $x, CORE::abs($y));

        if ($y < 0) {
            Math::GMPq::Rmpq_sgn($r) || goto &_inf;
            Math::GMPq::Rmpq_inv($r, $r);
        }

        return $r;
    }

  Math_GMPq__Math_GMPq: {

        # Integer power
        if (Math::GMPq::Rmpq_integer_p($y)) {
            $y = Math::GMPq::Rmpq_get_d($y);
            goto Math_GMPq__Scalar;
        }

        # (-x)^(a/b) is a complex number
        if (Math::GMPq::Rmpq_sgn($x) < 0) {
            $x = _mpq2mpc($x);
            $y = _mpq2mpc($y);
            goto Math_MPC__Math_MPC;
        }

        $x = _mpq2mpfr($x);
        $y = _mpq2mpfr($y);

        goto Math_MPFR__Math_MPFR;
    }

  Math_GMPq__Math_GMPz: {
        $y = Math::GMPz::Rmpz_get_d($y);
        goto Math_GMPq__Scalar;
    }

  Math_GMPq__Math_MPFR: {
        $x = _mpq2mpfr($x);
        goto Math_MPFR__Math_MPFR;
    }

  Math_GMPq__Math_MPC: {
        $x = _mpq2mpc($x);
        goto Math_MPC__Math_MPC;
    }

    #
    ## GMPz
    #

  Math_GMPz__Scalar: {

        my $r = Math::GMPz::Rmpz_init();
        Math::GMPz::Rmpz_pow_ui($r, $x, CORE::abs($y));

        if ($y < 0) {
            Math::GMPz::Rmpz_sgn($r) || goto &_inf;

            my $q = Math::GMPq::Rmpq_init();
            Math::GMPq::Rmpq_set_z($q, $r);
            Math::GMPq::Rmpq_inv($q, $q);
            return $q;
        }

        return $r;
    }

  Math_GMPz__Math_GMPz: {
        $y = Math::GMPz::Rmpz_get_d($y);
        goto Math_GMPz__Scalar;
    }

  Math_GMPz__Math_GMPq: {

        if (Math::GMPq::Rmpq_integer_p($y)) {
            $y = Math::GMPq::Rmpq_get_d($y);
            goto Math_GMPz__Scalar;
        }

        $x = _mpz2mpfr($x);
        $y = _mpq2mpfr($y);

        goto Math_MPFR__Math_MPFR;
    }

  Math_GMPz__Math_MPFR: {
        $x = _mpz2mpfr($x);
        goto Math_MPFR__Math_MPFR;
    }

  Math_GMPz__Math_MPC: {
        $x = _mpz2mpc($x);
        goto Math_MPC__Math_MPC;
    }

    #
    ## MPFR
    #
  Math_MPFR__Math_MPFR: {

        if (    Math::MPFR::Rmpfr_sgn($x) < 0
            and !Math::MPFR::Rmpfr_integer_p($y)
            and Math::MPFR::Rmpfr_number_p($y)) {
            $x = _mpfr2mpc($x);
            goto Math_MPC__Math_MPFR;
        }

        my $r = Math::MPFR::Rmpfr_init2($PREC);
        Math::MPFR::Rmpfr_pow($r, $x, $y, $ROUND);
        return $r;
    }

  Math_MPFR__Scalar: {
        my $r = Math::MPFR::Rmpfr_init2($PREC);
        $y < 0
          ? Math::MPFR::Rmpfr_pow_si($r, $x, $y, $ROUND)
          : Math::MPFR::Rmpfr_pow_ui($r, $x, $y, $ROUND);
        return $r;
    }

  Math_MPFR__Math_GMPq: {
        $y = _mpq2mpfr($y);
        goto Math_MPFR__Math_MPFR;
    }

  Math_MPFR__Math_GMPz: {
        my $r = Math::MPFR::Rmpfr_init2($PREC);
        Math::MPFR::Rmpfr_pow_z($r, $x, $y, $ROUND);
        return $r;
    }

  Math_MPFR__Math_MPC: {
        $x = _mpfr2mpc($x);
        goto Math_MPC__Math_MPC;
    }

    #
    ## MPC
    #
  Math_MPC__Math_MPC: {
        my $r = Math::MPC::Rmpc_init2($PREC);
        Math::MPC::Rmpc_pow($r, $x, $y, $ROUND);
        return $r;
    }

  Math_MPC__Scalar: {
        my $r = Math::MPC::Rmpc_init2($PREC);
        $y < 0
          ? Math::MPC::Rmpc_pow_si($r, $x, $y, $ROUND)
          : Math::MPC::Rmpc_pow_ui($r, $x, $y, $ROUND);
        return $r;
    }

  Math_MPC__Math_MPFR: {
        my $r = Math::MPC::Rmpc_init2($PREC);
        Math::MPC::Rmpc_pow_fr($r, $x, $y, $ROUND);
        return $r;
    }

  Math_MPC__Math_GMPz: {
        my $r = Math::MPC::Rmpc_init2($PREC);
        Math::MPC::Rmpc_pow_z($r, $x, $y, $ROUND);
        return $r;
    }

  Math_MPC__Math_GMPq: {
        $y = _mpq2mpc($y);
        goto Math_MPC__Math_MPC;
    }
}

sub pow ($$) {
    my ($x, $y) = @_;

    $x =
        ref($x) eq __PACKAGE__ ? $$x
      : ref($x)                ? _star2obj($x)
      :                          _str2obj($x);

    if (ref($y) eq __PACKAGE__) {
        return bless \__pow__($x, $$y);
    }

    if (!ref($y)) {
        if (CORE::int($y) eq $y and $y < ULONG_MAX and $y > LONG_MIN) {
            return bless \__pow__($x, $y);
        }

        return bless \__pow__($x, _str2obj($y));
    }

    bless \__pow__($x, _star2obj($y));
}

#
## INTEGER POWER
#

sub ipow ($$) {
    my ($x, $y) = @_;

    $y = _star2si($y) // goto &nan;

    # Both `x` and `y` are unsigned native integers
    if (    !ref($x)
        and CORE::int($x) eq $x
        and $x >= 0
        and $x < ULONG_MAX
        and $y >= 0) {
        my $r = Math::GMPz::Rmpz_init();
        Math::GMPz::Rmpz_ui_pow_ui($r, $x, $y);
        return bless \$r;
    }

    $x = _star2mpz($x) // goto &nan;

    my $r = Math::GMPz::Rmpz_init();
    Math::GMPz::Rmpz_pow_ui($r, $x, $y < 0 ? -$y : $y);

    if ($y < 0) {
        Math::GMPz::Rmpz_sgn($r) || goto &inf;    # 0^(-y) = Inf
        state $ONE_Z = Math::GMPz::Rmpz_init_set_ui_nobless(1);
        Math::GMPz::Rmpz_div($r, $ONE_Z, $r);
    }

    bless \$r;
}

#
## IPOW2
#

sub ipow2 ($) {
    my ($n) = @_;

    $n = _star2si($n) // goto &nan;

    goto &zero if $n < 0;

    my $r = Math::GMPz::Rmpz_init();
    Math::GMPz::Rmpz_setbit($r, $n);
    bless \$r;
}

#
## IPOW10
#

sub ipow10 ($) {
    my ($n) = @_;

    $n = _star2si($n) // goto &nan;

    goto &zero if $n < 0;

    my $r = Math::GMPz::Rmpz_init();
    Math::GMPz::Rmpz_ui_pow_ui($r, 10, $n);
    bless \$r;
}

#
## ROOT
#

sub root ($$) {
    my ($x, $y) = @_;

    $x =
        ref($x) eq __PACKAGE__ ? $$x
      : ref($x)                ? _star2obj($x)
      :                          _str2obj($x);

    $y =
        ref($y) eq __PACKAGE__ ? $$y
      : ref($y)                ? _star2obj($y)
      :                          _str2obj($y);

    bless \__pow__($x, __inv__($y));
}

#
## Polygonal root
#

sub __polygonal_root__ {
    my ($n, $k, $second) = @_;
    goto(join('__', ref($n), ref($k)) =~ tr/:/_/rs);

    # polygonal_root(n, k)
    #   = ((k - 4) ± sqrt(8 * (k - 2) * n + (k - 4)^2)) / (2 * (k - 2))

  Math_MPFR__Math_MPFR: {
        my $t = Math::MPFR::Rmpfr_init2($PREC);
        my $u = Math::MPFR::Rmpfr_init2($PREC);

        Math::MPFR::Rmpfr_sub_ui($u, $k, 2, $ROUND);     # u = k-2
        Math::MPFR::Rmpfr_mul($t, $n, $u, $ROUND);       # t = n*u
        Math::MPFR::Rmpfr_mul_2ui($t, $t, 3, $ROUND);    # t = t*8

        Math::MPFR::Rmpfr_sub_ui($u, $u, 2, $ROUND);     # u = u-2
        Math::MPFR::Rmpfr_sqr($u, $u, $ROUND);           # u = u^2
        Math::MPFR::Rmpfr_add($t, $t, $u, $ROUND);       # t = t+u

        # Return a complex number for `t < 0`
        if (Math::MPFR::Rmpfr_sgn($t) < 0) {
            $n = _mpfr2mpc($n);
            $k = _mpfr2mpc($k);
            goto Math_MPC__Math_MPC;
        }

        Math::MPFR::Rmpfr_sqrt($t, $t, $ROUND);          # t = sqrt(t)
        Math::MPFR::Rmpfr_sub_ui($u, $k, 4, $ROUND);     # u = k-4

        $second
          ? Math::MPFR::Rmpfr_sub($t, $u, $t, $ROUND)     # t = u-t
          : Math::MPFR::Rmpfr_add($t, $t, $u, $ROUND);    # t = t+u

        Math::MPFR::Rmpfr_add_ui($u, $u, 2, $ROUND);      # u = u+2
        Math::MPFR::Rmpfr_mul_2ui($u, $u, 1, $ROUND);     # u = u*2

        Math::MPFR::Rmpfr_zero_p($u) && return $n;        # `u` is zero
        Math::MPFR::Rmpfr_div($t, $t, $u, $ROUND);        # t = t/u
        return $t;
    }

  Math_MPFR__Math_MPC: {
        $n = _mpfr2mpc($n);
        goto Math_MPC__Math_MPC;
    }

  Math_MPC__Math_MPFR: {
        $k = _mpfr2mpc($k);
        goto Math_MPC__Math_MPC;
    }

  Math_MPC__Math_MPC: {
        my $t = Math::MPC::Rmpc_init2($PREC);
        my $u = Math::MPC::Rmpc_init2($PREC);

        Math::MPC::Rmpc_sub_ui($u, $k, 2, $ROUND);     # u = k-2
        Math::MPC::Rmpc_mul($t, $n, $u, $ROUND);       # t = n*u
        Math::MPC::Rmpc_mul_2ui($t, $t, 3, $ROUND);    # t = t*8

        Math::MPC::Rmpc_sub_ui($u, $u, 2, $ROUND);     # u = u-2
        Math::MPC::Rmpc_sqr($u, $u, $ROUND);           # u = u^2
        Math::MPC::Rmpc_add($t, $t, $u, $ROUND);       # t = t+u

        Math::MPC::Rmpc_sqrt($t, $t, $ROUND);          # t = sqrt(t)
        Math::MPC::Rmpc_sub_ui($u, $k, 4, $ROUND);     # u = k-4

        $second
          ? Math::MPC::Rmpc_sub($t, $u, $t, $ROUND)     # t = u-t
          : Math::MPC::Rmpc_add($t, $t, $u, $ROUND);    # t = t+u

        Math::MPC::Rmpc_add_ui($u, $u, 2, $ROUND);      # u = u+2
        Math::MPC::Rmpc_mul_2ui($u, $u, 1, $ROUND);     # u = u*2

        if (Math::MPC::Rmpc_cmp_si($t, 0) == 0) {       # `u` is zero
            return $n;
        }

        Math::MPC::Rmpc_div($t, $t, $u, $ROUND);        # t = t/u
        return $t;
    }
}

sub polygonal_root ($$) {
    bless \__polygonal_root__(_star2mpfr_mpc($_[0]), _star2mpfr_mpc($_[1]));
}

#
## Second polygonal root
#

sub polygonal_root2 ($$) {
    bless \__polygonal_root__(_star2mpfr_mpc($_[0]), _star2mpfr_mpc($_[1]), 1);
}

#
## isqrt
#

sub isqrt ($) {
    my ($x) = @_;

    $x = _star2mpz($x) // goto &nan;

    Math::GMPz::Rmpz_sgn($x) < 0 and goto &nan;
    my $r = Math::GMPz::Rmpz_init();
    Math::GMPz::Rmpz_sqrt($r, $x);
    bless \$r;
}

#
## icbrt
#

sub icbrt ($) {
    my ($x) = @_;

    $x = _star2mpz($x) // goto &nan;

    my $r = Math::GMPz::Rmpz_init();
    Math::GMPz::Rmpz_root($r, $x, 3);
    bless \$r;
}

#
## IROOT
#

sub iroot ($$) {
    my ($x, $y) = @_;

    $x = _star2mpz($x) // goto &nan;
    $y = _star2si($y)  // goto &nan;

    if ($y == 0) {
        Math::GMPz::Rmpz_sgn($x) || goto &zero;    # 0^Inf = 0

        # 1^Inf = 1 ; (-1)^Inf = 1
        if (Math::GMPz::Rmpz_cmpabs_ui($x, 1) == 0) {
            goto &one;
        }

        goto &inf;
    }

    if ($y < 0) {
        my $sign = Math::GMPz::Rmpz_sgn($x)
          || goto &inf;                            # 1 / 0^k = Inf

        if ($sign < 0) {
            goto &nan;
        }

        if (Math::GMPz::Rmpz_cmp_ui($x, 1) == 0) {    # 1 / 1^k = 1
            goto &one;
        }

        goto &zero;
    }

    if ($y % 2 == 0 and Math::GMPz::Rmpz_sgn($x) < 0) {
        goto &nan;
    }

    my $r = Math::GMPz::Rmpz_init();
    $y == 2
      ? Math::GMPz::Rmpz_sqrt($r, $x)
      : Math::GMPz::Rmpz_root($r, $x, $y);
    bless \$r;
}

#
## ISQRTREM
#

sub isqrtrem ($) {
    my ($x) = @_;

    $x = _star2mpz($x) // return (nan(), nan());

    Math::GMPz::Rmpz_sgn($x) < 0
      and return (nan(), nan());

    my $r = Math::GMPz::Rmpz_init();
    my $s = Math::GMPz::Rmpz_init();

    Math::GMPz::Rmpz_sqrtrem($r, $s, $x);

    ((bless \$r), (bless \$s));
}

#
## IROOTREM
#

sub irootrem ($$) {
    my ($x, $y) = @_;

    $x = _star2mpz($x) // return (nan(), nan());
    $y = _star2si($y)  // return (nan(), nan());

    if ($y == 0) {

        # 0^Inf = 0
        if (Math::GMPz::Rmpz_sgn($x) == 0) {
            return (zero(), mone());
        }

        my $r = Math::GMPz::Rmpz_init();
        Math::GMPz::Rmpz_sub_ui($r, $x, 1);

        # 1^Inf = 1 ; (-1)^Inf = 1
        if (Math::GMPz::Rmpz_cmpabs_ui($x, 1) == 0) {
            return (one(), (bless \$r));
        }

        return (inf(), (bless \$r));
    }

    if ($y < 0) {
        my $sgn = Math::GMPz::Rmpz_sgn($x);

        # 1 / 0^k = Inf
        if ($sgn == 0) {
            return (inf(), zero());
        }

        # 1 / 1^k = 1
        if (Math::GMPz::Rmpz_cmp_ui($x, 1) == 0) {
            return (one(), zero());
        }

        # x is negative
        if ($sgn < 0) {
            return (nan(), nan());
        }

        return (zero(), ninf());
    }

    if ($y % 2 == 0 and Math::GMPz::Rmpz_sgn($x) < 0) {
        return (nan(), nan());
    }

    my $r = Math::GMPz::Rmpz_init();
    my $s = Math::GMPz::Rmpz_init();

    $y == 2
      ? Math::GMPz::Rmpz_sqrtrem($r, $s, $x)
      : Math::GMPz::Rmpz_rootrem($r, $s, $x, $y);

    ((bless \$r), (bless \$s));
}

#
## MOD
#

sub __mod__ {
    my ($x, $y) = @_;
    goto(join('__', ref($x), ref($y) || 'Scalar') =~ tr/:/_/rs);

    #
    ## GMPq
    #
  Math_GMPq__Math_GMPq: {

        if (Math::GMPq::Rmpq_integer_p($y)) {
            $y = _mpq2mpz($y);
            goto Math_GMPq__Math_GMPz;
        }

        Math::GMPq::Rmpq_sgn($y) || goto &_nan;

        my $quo = Math::GMPq::Rmpq_init();
        Math::GMPq::Rmpq_div($quo, $x, $y);

        # Floor
        Math::GMPq::Rmpq_integer_p($quo) || do {
            my $z = Math::GMPz::Rmpz_init();
            Math::GMPz::Rmpz_set_q($z, $quo);
            Math::GMPz::Rmpz_sub_ui($z, $z, 1) if Math::GMPq::Rmpq_sgn($quo) < 0;
            Math::GMPq::Rmpq_set_z($quo, $z);
        };

        Math::GMPq::Rmpq_mul($quo, $quo, $y);
        Math::GMPq::Rmpq_sub($quo, $x, $quo);

        return $quo;
    }

  Math_GMPq__Math_GMPz: {
        Math::GMPz::Rmpz_sgn($y) || goto &_nan;
        my $r = _modular_rational($x, $y) // do {

            my $quo = Math::GMPq::Rmpq_init();
            Math::GMPq::Rmpq_div_z($quo, $x, $y);

            # Floor
            Math::GMPq::Rmpq_integer_p($quo) || do {
                my $z = Math::GMPz::Rmpz_init();
                Math::GMPz::Rmpz_set_q($z, $quo);
                Math::GMPz::Rmpz_sub_ui($z, $z, 1) if Math::GMPq::Rmpq_sgn($quo) < 0;
                Math::GMPq::Rmpq_set_z($quo, $z);
            };

            Math::GMPq::Rmpq_mul_z($quo, $quo, $y);
            Math::GMPq::Rmpq_sub($quo, $x, $quo);

            return $quo;
        };
        Math::GMPz::Rmpz_mod($r, $r, $y);
        return $r;
    }

  Math_GMPq__Math_MPFR: {
        $x = _mpq2mpfr($x);
        goto Math_MPFR__Math_MPFR;
    }

  Math_GMPq__Math_MPC: {
        $x = _mpq2mpc($x);
        goto Math_MPC__Math_MPC;
    }

    #
    ## GMPz
    #
  Math_GMPz__Math_GMPz: {

        my $sgn_y = Math::GMPz::Rmpz_sgn($y) || goto &_nan;

        my $r = Math::GMPz::Rmpz_init();
        Math::GMPz::Rmpz_mod($r, $x, $y);

        if (!Math::GMPz::Rmpz_sgn($r)) {
            ## ok
        }
        elsif ($sgn_y < 0) {
            Math::GMPz::Rmpz_add($r, $r, $y);
        }

        return $r;
    }

  Math_GMPz__Scalar: {
        my $r = Math::GMPz::Rmpz_init();
        Math::GMPz::Rmpz_mod_ui($r, $x, $y);
        return $r;
    }

  Math_GMPz__Math_GMPq: {
        $x = _mpz2mpq($x);
        goto Math_GMPq__Math_GMPq;
    }

  Math_GMPz__Math_MPFR: {
        $x = _mpz2mpfr($x);
        goto Math_MPFR__Math_MPFR;
    }

  Math_GMPz__Math_MPC: {
        $x = _mpz2mpc($x);
        goto Math_MPC__Math_MPC;
    }

    #
    ## MPFR
    #
  Math_MPFR__Math_MPFR: {

        my $quo = Math::MPFR::Rmpfr_init2($PREC);
        Math::MPFR::Rmpfr_div($quo, $x, $y, $ROUND);
        Math::MPFR::Rmpfr_floor($quo, $quo);
        Math::MPFR::Rmpfr_mul($quo, $quo, $y, $ROUND);
        Math::MPFR::Rmpfr_sub($quo, $x, $quo, $ROUND);

        return $quo;
    }

  Math_MPFR__Scalar: {

        my $quo = Math::MPFR::Rmpfr_init2($PREC);
        Math::MPFR::Rmpfr_div_ui($quo, $x, $y, $ROUND);
        Math::MPFR::Rmpfr_floor($quo, $quo);
        Math::MPFR::Rmpfr_mul_ui($quo, $quo, $y, $ROUND);
        Math::MPFR::Rmpfr_sub($quo, $x, $quo, $ROUND);

        return $quo;
    }

  Math_MPFR__Math_GMPq: {

        my $quo = Math::MPFR::Rmpfr_init2($PREC);
        Math::MPFR::Rmpfr_div_q($quo, $x, $y, $ROUND);
        Math::MPFR::Rmpfr_floor($quo, $quo);
        Math::MPFR::Rmpfr_mul_q($quo, $quo, $y, $ROUND);
        Math::MPFR::Rmpfr_sub($quo, $x, $quo, $ROUND);

        return $quo;
    }

  Math_MPFR__Math_GMPz: {

        my $quo = Math::MPFR::Rmpfr_init2($PREC);
        Math::MPFR::Rmpfr_div_z($quo, $x, $y, $ROUND);
        Math::MPFR::Rmpfr_floor($quo, $quo);
        Math::MPFR::Rmpfr_mul_z($quo, $quo, $y, $ROUND);
        Math::MPFR::Rmpfr_sub($quo, $x, $quo, $ROUND);

        return $quo;
    }

  Math_MPFR__Math_MPC: {
        $x = _mpfr2mpc($x);
        goto Math_MPC__Math_MPC;
    }

    #
    ## MPC
    #
  Math_MPC__Math_MPC: {

        my $quo = Math::MPC::Rmpc_init2($PREC);
        Math::MPC::Rmpc_div($quo, $x, $y, $ROUND);

        my $real = Math::MPFR::Rmpfr_init2($PREC);
        my $imag = Math::MPFR::Rmpfr_init2($PREC);

        Math::MPC::RMPC_RE($real, $quo);
        Math::MPC::RMPC_IM($imag, $quo);

        Math::MPFR::Rmpfr_floor($real, $real);
        Math::MPFR::Rmpfr_floor($imag, $imag);

        Math::MPC::Rmpc_set_fr_fr($quo, $real, $imag, $ROUND);

        Math::MPC::Rmpc_mul($quo, $quo, $y, $ROUND);
        Math::MPC::Rmpc_sub($quo, $x, $quo, $ROUND);

        return $quo;
    }

  Math_MPC__Scalar: {

        my $quo = Math::MPC::Rmpc_init2($PREC);
        Math::MPC::Rmpc_div_ui($quo, $x, $y, $ROUND);

        my $real = Math::MPFR::Rmpfr_init2($PREC);
        my $imag = Math::MPFR::Rmpfr_init2($PREC);

        Math::MPC::RMPC_RE($real, $quo);
        Math::MPC::RMPC_IM($imag, $quo);

        Math::MPFR::Rmpfr_floor($real, $real);
        Math::MPFR::Rmpfr_floor($imag, $imag);

        Math::MPC::Rmpc_set_fr_fr($quo, $real, $imag, $ROUND);

        Math::MPC::Rmpc_mul_ui($quo, $quo, $y, $ROUND);
        Math::MPC::Rmpc_sub($quo, $x, $quo, $ROUND);

        return $quo;
    }

  Math_MPC__Math_MPFR: {
        $y = _mpfr2mpc($y);
        goto Math_MPC__Math_MPC;
    }

  Math_MPC__Math_GMPz: {
        $y = _mpz2mpc($y);
        goto Math_MPC__Math_MPC;
    }

  Math_MPC__Math_GMPq: {
        $y = _mpq2mpc($y);
        goto Math_MPC__Math_MPC;
    }
}

sub mod ($$) {
    my ($x, $y) = @_;

    $x =
        ref($x) eq __PACKAGE__ ? $$x
      : ref($x)                ? _star2obj($x)
      :                          _str2obj($x);

    if (ref($y) eq __PACKAGE__) {
        return bless \__mod__($x, $$y);
    }

    if (!ref($y)) {

        if (    ref($x) ne 'Math::GMPq'
            and CORE::int($y) eq $y
            and $y > 0
            and $y < ULONG_MAX) {
            return bless \__mod__($x, $y);
        }

        return bless \__mod__($x, _str2obj($y));
    }

    bless \__mod__($x, _star2obj($y));
}

#
## IMOD
#

sub imod ($$) {
    my ($x, $y) = @_;

    $x = _star2mpz($x) // goto &nan;

    if (!ref($y) and CORE::int($y) eq $y and $y < ULONG_MAX and $y > LONG_MIN) {

        CORE::int($y) || goto &nan;

        my $neg_y = $y < 0;
        $y = -$y if $neg_y;

        my $r = Math::GMPz::Rmpz_init();
        Math::GMPz::Rmpz_mod_ui($r, $x, $y);

        if (!Math::GMPz::Rmpz_sgn($r)) {
            ## OK
        }
        elsif ($neg_y) {
            Math::GMPz::Rmpz_sub_ui($r, $r, $y);
        }

        return bless \$r;
    }

    $y = _star2mpz($y) // goto &nan;

    my $sign_y = Math::GMPz::Rmpz_sgn($y) || goto &nan;

    my $r = Math::GMPz::Rmpz_init();
    Math::GMPz::Rmpz_mod($r, $x, $y);

    if (!Math::GMPz::Rmpz_sgn($r)) {
        ## OK
    }
    elsif ($sign_y < 0) {
        Math::GMPz::Rmpz_add($r, $r, $y);
    }

    bless \$r;
}

#
## POLYMOD
#

sub polymod {
    my @list = map { ref($_) eq __PACKAGE__ ? $$_ : _star2obj($_) } @_;

    my @r;
    my $x = shift(@list);

    foreach my $m (@list) {
        my $mod = __mod__($x, $m);

        $x = __sub__($x, $mod);
        $x = __div__($x, $m);

        push @r, $mod;
    }

    push @r, $x;
    map { bless \$_ } @r;
}

# Modular operations

sub addmod ($$$) {
    my ($x, $y, $m) = @_;

    $x = _star2mpz($x) // goto &nan;
    $y = _star2mpz($y) // goto &nan;
    $m = _star2mpz($m) // goto &nan;

    my $r = Math::GMPz::Rmpz_init();
    Math::GMPz::Rmpz_add($r, $x, $y);
    Math::GMPz::Rmpz_mod($r, $r, $m);
    bless \$r;
}

sub submod ($$$) {
    my ($x, $y, $m) = @_;

    $x = _star2mpz($x) // goto &nan;
    $y = _star2mpz($y) // goto &nan;
    $m = _star2mpz($m) // goto &nan;

    my $r = Math::GMPz::Rmpz_init();
    Math::GMPz::Rmpz_sub($r, $x, $y);
    Math::GMPz::Rmpz_mod($r, $r, $m);
    bless \$r;
}

sub mulmod ($$$) {
    my ($x, $y, $m) = @_;

    $x = _star2mpz($x) // goto &nan;
    $y = _star2mpz($y) // goto &nan;
    $m = _star2mpz($m) // goto &nan;

    my $r = Math::GMPz::Rmpz_init();
    Math::GMPz::Rmpz_mul($r, $x, $y);
    Math::GMPz::Rmpz_mod($r, $r, $m);
    bless \$r;
}

#
## DIVMOD
#

sub divmod ($$;$) {
    my ($x, $y, $m) = @_;

    if (defined($m)) {    # modular division

        $x = _star2mpz($x) // goto &nan;
        $y = _star2mpz($y) // goto &nan;
        $m = _star2mpz($m) // goto &nan;

        my $r = Math::GMPz::Rmpz_init();

        if (Math::GMPz::Rmpz_divisible_p($x, $y) and Math::GMPz::Rmpz_sgn($y)) {
            Math::GMPz::Rmpz_divexact($r, $x, $y);
            Math::GMPz::Rmpz_mod($r, $r, $m);
        }
        elsif (Math::GMPz::Rmpz_invert($r, $y, $m)) {
            Math::GMPz::Rmpz_mul($r, $r, $x);
            Math::GMPz::Rmpz_mod($r, $r, $m);
        }
        else {
            goto &nan;
        }

        return bless \$r;
    }

    $x = _star2mpz($x) // return (nan(), nan());
    $y = _star2mpz($y) // return (nan(), nan());

    Math::GMPz::Rmpz_sgn($y)
      || return (nan(), nan());

    my $r = Math::GMPz::Rmpz_init();
    my $s = Math::GMPz::Rmpz_init();

    Math::GMPz::Rmpz_divmod($r, $s, $x, $y);

    ((bless \$r), (bless \$s));
}

#
## is_div
#

sub is_div ($$) {
    my ($n, $k) = @_;

    if (ref($n) eq __PACKAGE__ and ref($$n) eq 'Math::GMPz') {
        if (ref($k)) {
            if (ref($k) eq __PACKAGE__ and ref($$k) eq 'Math::GMPz') {
                return (Math::GMPz::Rmpz_sgn($$k) && Math::GMPz::Rmpz_divisible_p($$n, $$k));
            }
        }
        elsif (CORE::int($k) eq $k and $k and $k < ULONG_MAX and $k > LONG_MIN) {
            return Math::GMPz::Rmpz_divisible_ui_p($$n, $k < 0 ? -$k : $k);
        }
    }

    @_ = (${mod($n, $k)}, 0);
    goto &__eq__;
}

#
## is_congruent
#

sub is_congruent ($$$) {
    my ($n, $k, $m) = @_;

    $n = $$n if (ref($n) eq __PACKAGE__);
    $k = $$k if (ref($k) eq __PACKAGE__);
    $m = $$m if (ref($m) eq __PACKAGE__);

    if (ref($n) eq 'Math::GMPz') {

        if (    !ref($k)
            and !ref($m)
            and CORE::int($k) eq $k
            and $k >= 0
            and $k < ULONG_MAX
            and CORE::int($m) eq $m
            and $m > 0
            and $m < ULONG_MAX) {
            return Math::GMPz::Rmpz_congruent_ui_p($n, $k, $m);
        }

        if (ref($k) eq 'Math::GMPz' and ref($m) eq 'Math::GMPz') {
            return (Math::GMPz::Rmpz_sgn($m) && Math::GMPz::Rmpz_congruent_p($n, $k, $m));
        }
    }

    $n = _star2obj($n) if !ref($n);
    $k = _star2obj($k) if !ref($k);
    $m = _star2obj($m) if !ref($m);

    if (ref($n) eq 'Math::GMPz' and ref($k) eq 'Math::GMPz' and ref($m) eq 'Math::GMPz') {
        return (Math::GMPz::Rmpz_sgn($m) && Math::GMPz::Rmpz_congruent_p($n, $k, $m));
    }

    @_ = (__mod__($n, $m), __mod__($k, $m));
    goto &__eq__;
}

#
## SPECIAL
#

#
## LOG
#

sub __log__ {
    my ($x) = @_;
    goto(ref($x) =~ tr/:/_/rs);

  Math_MPFR: {

        # Complex for x < 0
        if (Math::MPFR::Rmpfr_sgn($x) < 0) {
            my $r = _mpfr2mpc($x);
            Math::MPC::Rmpc_log($r, $r, $ROUND);
            return $r;
        }

        my $r = Math::MPFR::Rmpfr_init2($PREC);
        Math::MPFR::Rmpfr_log($r, $x, $ROUND);
        return $r;
    }

  Math_MPC: {
        my $r = Math::MPC::Rmpc_init2($PREC);
        Math::MPC::Rmpc_log($r, $x, $ROUND);
        return $r;
    }

}

#
## LOG_2
#

sub __log2__ {
    my ($x) = @_;
    goto(ref($x) =~ tr/:/_/rs);

  Math_MPFR: {

        # Complex for x < 0
        if (Math::MPFR::Rmpfr_sgn($x) < 0) {
            $x = _mpfr2mpc($x);
            goto Math_MPC;
        }

        my $r = Math::MPFR::Rmpfr_init2($PREC);
        Math::MPFR::Rmpfr_log2($r, $x, $ROUND);
        return $r;
    }

  Math_MPC: {
        my $r   = Math::MPC::Rmpc_init2($PREC);
        my $ln2 = Math::MPFR::Rmpfr_init2($PREC);
        Math::MPFR::Rmpfr_const_log2($ln2, $ROUND);
        Math::MPC::Rmpc_log($r, $x, $ROUND);
        Math::MPC::Rmpc_div_fr($r, $r, $ln2, $ROUND);
        return $r;
    }
}

#
## LOG_10
#

sub __log10__ {
    my ($x) = @_;
    goto(ref($x) =~ tr/:/_/rs);

  Math_MPFR: {

        # Complex for x < 0
        if (Math::MPFR::Rmpfr_sgn($x) < 0) {
            $x = _mpfr2mpc($x);
            goto Math_MPC;
        }

        my $r = Math::MPFR::Rmpfr_init2($PREC);
        Math::MPFR::Rmpfr_log10($r, $x, $ROUND);
        return $r;
    }

  Math_MPC: {
        state $MPC_VERSION = Math::MPC::MPC_VERSION();

        my $r = Math::MPC::Rmpc_init2($PREC);

        if ($MPC_VERSION >= 65536) {    # available only in mpc>=1.0.0
            Math::MPC::Rmpc_log10($r, $x, $ROUND);
        }
        else {
            my $ln10 = Math::MPFR::Rmpfr_init2($PREC);
            Math::MPFR::Rmpfr_set_ui($ln10, 10, $ROUND);
            Math::MPFR::Rmpfr_log($ln10, $ln10, $ROUND);
            Math::MPC::Rmpc_log($r, $x, $ROUND);
            Math::MPC::Rmpc_div_fr($r, $r, $ln10, $ROUND);
        }

        return $r;
    }
}

sub ln {    # used in overloading
    bless \__log__(_star2mpfr_mpc($_[0]));
}

sub log2 ($) {
    bless \__log2__(_star2mpfr_mpc($_[0]));
}

sub log10 ($) {
    bless \__log10__(_star2mpfr_mpc($_[0]));
}

sub log (_;$) {
    my ($x, $y) = @_;

    if (!defined($y)) {
        return bless \__log__(_star2mpfr_mpc($x));
    }

    bless \__div__(__log__(_star2mpfr_mpc($x)), __log__(_star2mpfr_mpc($y)));
}

#
## Integer logarithm to a given base
#

sub __ilog__ {
    my ($x, $y) = @_;

    if (ref($y) eq 'Math::GMPz' and Math::GMPz::Rmpz_fits_ulong_p($y)) {
        $y = Math::GMPz::Rmpz_get_ui($y);
    }

    # ilog(x, y <= 1) = NaN
    $y <= 1 and return;

    # ilog(x <= 0, y) = NaN
    Math::GMPz::Rmpz_sgn($x) <= 0 and return;

    # ilog(x,y) = 0, when y > x
    (ref($y) ? Math::GMPz::Rmpz_cmp($x, $y) : Math::GMPz::Rmpz_cmp_ui($x, $y)) >= 0
      or return 0;

    # Return faster for y <= 62
    if ($y <= 62) {

        $y = Math::GMPz::Rmpz_get_ui($y) if ref($y);

        my $e = (Math::GMPz::Rmpz_sizeinbase($x, $y) || return) - 1;

        if ($e > 0) {
            state $t = Math::GMPz::Rmpz_init_nobless();
            Math::GMPz::Rmpz_ui_pow_ui($t, $y, $e);
            Math::GMPz::Rmpz_cmp($t, $x) > 0 and --$e;
        }

        return $e;
    }

    # Make sure `y` is a Math::GMPz object
    $y = Math::GMPz::Rmpz_init_set_ui($y) if !ref($y);

    my $e = 0;

    state $t       = Math::GMPz::Rmpz_init_nobless();
    state $round_z = Math::MPFR::MPFR_RNDZ();
    state $logx    = Math::MPFR::Rmpfr_init2_nobless(64);
    state $logy    = Math::MPFR::Rmpfr_init2_nobless(64);

    Math::MPFR::Rmpfr_set_z($logx, $x, $round_z);
    Math::MPFR::Rmpfr_set_z($logy, $y, $round_z);

    Math::MPFR::Rmpfr_log($logx, $logx, $round_z);
    Math::MPFR::Rmpfr_log($logy, $logy, $round_z);

    Math::MPFR::Rmpfr_div($logx, $logx, $logy, $round_z);

    if (Math::MPFR::Rmpfr_fits_ulong_p($logx, $round_z)) {
        $e = Math::MPFR::Rmpfr_get_ui($logx, $round_z) - 1;
        Math::GMPz::Rmpz_pow_ui($t, $y, $e + 1);
    }
    else {
        Math::GMPz::Rmpz_set($t, $y);
    }

    for (; Math::GMPz::Rmpz_cmp($t, $x) <= 0 ; Math::GMPz::Rmpz_mul($t, $t, $y)) {
        ++$e;
    }

    return $e;
}

sub ilog2 ($) {
    my ($x) = @_;
    $x = _star2mpz($x) // goto &nan;
    bless \Math::GMPz::Rmpz_init_set_ui(__ilog__($x, 2) // goto &nan);
}

sub ilog10 ($) {
    my ($x) = @_;
    $x = _star2mpz($x) // goto &nan;
    bless \Math::GMPz::Rmpz_init_set_ui(__ilog__($x, 10) // goto &nan);
}

sub ilog ($;$) {
    my ($x, $y) = @_;

    if (!defined($y)) {
        return bless \(_any2mpz(__log__(_star2mpfr_mpc($x))) // goto &nan);
    }

    $x = _star2mpz($x) // goto &nan;

    if (!ref($y) and CORE::int($y) eq $y and $y > 1 and $y < ULONG_MAX) {
        ## y is a native integer -- OK
    }
    else {
        $y = _star2mpz($y) // goto &nan;
    }

    bless \Math::GMPz::Rmpz_init_set_ui(__ilog__($x, $y) // goto &nan);
}

sub length ($;$) {
    my ($x, $y) = @_;

    $x = _star2mpz($x) // return undef;

    my $neg = ((Math::GMPz::Rmpz_sgn($x) || return 1) < 0) ? 1 : 0;

    if (defined($y)) {
        if (!ref($y) and CORE::int($y) eq $y and $y > 1 and $y < ULONG_MAX) {
            ## y is a native integer -- OK
        }
        else {
            $y = _star2mpz($y) // return undef;
        }
    }
    else {
        $y = 10;
    }

    if ($neg) {
        $x = Math::GMPz::Rmpz_init_set($x);
        Math::GMPz::Rmpz_abs($x, $x);
    }

    1 + (__ilog__($x, $y) // return 0);
}

#
## Square root
#

sub __sqrt__ {
    my ($x) = @_;
    goto(ref($x) =~ tr/:/_/rs);

  Math_MPFR: {

        # Complex for x < 0
        if (Math::MPFR::Rmpfr_sgn($x) < 0) {
            my $r = _mpfr2mpc($x);
            Math::MPC::Rmpc_sqrt($r, $r, $ROUND);
            return $r;
        }

        my $r = Math::MPFR::Rmpfr_init2($PREC);
        Math::MPFR::Rmpfr_sqrt($r, $x, $ROUND);
        return $r;
    }

  Math_MPC: {
        my $r = Math::MPC::Rmpc_init2($PREC);
        Math::MPC::Rmpc_sqrt($r, $x, $ROUND);
        return $r;
    }
}

sub sqrt {    # used in overloading
    bless \__sqrt__(_star2mpfr_mpc($_[0]));
}

#
## Cube root
#

sub __cbrt__ {
    my ($x) = @_;
    goto(ref($x) =~ tr/:/_/rs);

  Math_MPFR: {

        # Complex for x < 0
        if (Math::MPFR::Rmpfr_sgn($x) < 0) {
            $x = _mpfr2mpc($x);
            goto Math_MPC;
        }

        my $r = Math::MPFR::Rmpfr_init2($PREC);
        Math::MPFR::Rmpfr_cbrt($r, $x, $ROUND);
        return $r;
    }

  Math_MPC: {

        state $three_inv = do {
            my $r = Math::MPC::Rmpc_init2_nobless($PREC);
            Math::MPC::Rmpc_set_ui($r, 3, $ROUND);
            Math::MPC::Rmpc_ui_div($r, 1, $r, $ROUND);
            $r;
        };

        my $r = Math::MPC::Rmpc_init2($PREC);
        Math::MPC::Rmpc_pow($r, $x, $three_inv, $ROUND);
        return $r;
    }
}

sub cbrt ($) {
    bless \__cbrt__(_star2mpfr_mpc($_[0]));
}

#
## Square (x^2)
#

sub sqr ($) {
    my ($x) = @_;

    $x =
      ref($x) eq __PACKAGE__
      ? $$x
      : _star2obj($x);

    bless \__mul__($x, $x);
}

#
## Normalized value: norm(a + b*i) = a^2 + b^2
#

sub __norm__ {
    my ($x) = @_;
    goto(ref($x) =~ tr/:/_/rs);

  Math_MPC: {
        my $r = Math::MPFR::Rmpfr_init2($PREC);
        Math::MPC::Rmpc_norm($r, $x, $ROUND);
        return $r;
    }

  Math_MPFR: {
        my $r = Math::MPFR::Rmpfr_init2($PREC);
        Math::MPFR::Rmpfr_sqr($r, $x, $ROUND);
        return $r;
    }

  Math_GMPz: {
        my $r = Math::GMPz::Rmpz_init();
        Math::GMPz::Rmpz_mul($r, $x, $x);
        return $r;
    }

  Math_GMPq: {
        my $r = Math::GMPq::Rmpq_init();
        Math::GMPq::Rmpq_mul($r, $x, $x);
        return $r;
    }
}

sub norm ($) {
    my ($x) = @_;

    $x =
      ref($x) eq __PACKAGE__
      ? $$x
      : _star2obj($x);

    bless \__norm__($x);
}

#
## Natural exponentiation function (e^x)
#

sub __exp__ {
    my ($x) = @_;
    goto(ref($x) =~ tr/:/_/rs);

  Math_MPFR: {
        my $r = Math::MPFR::Rmpfr_init2($PREC);
        Math::MPFR::Rmpfr_exp($r, $x, $ROUND);
        return $r;
    }

  Math_MPC: {
        my $r = Math::MPC::Rmpc_init2($PREC);
        Math::MPC::Rmpc_exp($r, $x, $ROUND);
        return $r;
    }
}

sub exp {    # used in overloading
    bless \__exp__(_star2mpfr_mpc($_[0]));
}

sub exp2 ($) {
    my ($x) = @_;

    state $base = Math::GMPz::Rmpz_init_set_ui(2);

    if (ref($x) eq __PACKAGE__) {
        bless \__pow__($base, $$x);
    }
    elsif (!ref($x) and CORE::int($x) eq $x and $x > LONG_MIN and $x < ULONG_MAX) {
        bless \__pow__($base, $x);
    }
    else {
        bless \__pow__($base, _star2obj($x));
    }
}

sub exp10 ($) {
    my ($x) = @_;

    state $base = Math::GMPz::Rmpz_init_set_ui(10);

    if (ref($x) eq __PACKAGE__) {
        bless \__pow__($base, $$x);
    }
    elsif (!ref($x) and CORE::int($x) eq $x and $x > LONG_MIN and $x < ULONG_MAX) {
        bless \__pow__($base, $x);
    }
    else {
        bless \__pow__($base, _star2obj($x));
    }
}

#
## floor(x) function -- round towards -Infinity
#

sub __floor__ {
    my ($x) = @_;
    goto(ref($x) =~ tr/:/_/rs);

  Math_MPFR: {
        my $r = Math::MPFR::Rmpfr_init2($PREC);
        Math::MPFR::Rmpfr_floor($r, $x);
        return $r;
    }

  Math_GMPq: {
        my $z = Math::GMPz::Rmpz_init();
        Math::GMPz::Rmpz_set_q($z, $x);
        Math::GMPq::Rmpq_integer_p($x) && return $z;
        Math::GMPz::Rmpz_sub_ui($z, $z, 1) if Math::GMPq::Rmpq_sgn($x) < 0;
        return $z;
    }

  Math_MPC: {

        my $real = Math::MPFR::Rmpfr_init2($PREC);
        my $imag = Math::MPFR::Rmpfr_init2($PREC);

        Math::MPC::RMPC_RE($real, $x);
        Math::MPC::RMPC_IM($imag, $x);

        Math::MPFR::Rmpfr_floor($real, $real);
        Math::MPFR::Rmpfr_floor($imag, $imag);

        if (Math::MPFR::Rmpfr_zero_p($imag)) {
            return $real;
        }

        my $r = Math::MPC::Rmpc_init2($PREC);
        Math::MPC::Rmpc_set_fr_fr($r, $real, $imag, $ROUND);
        return $r;
    }
}

sub floor ($) {
    my ($x) = @_;

    if (ref($x) ne __PACKAGE__) {
        $x = __PACKAGE__->new($x);
    }

    ref($$x) eq 'Math::GMPz' and return $x;    # already an integer
    bless \__floor__($$x);
}

#
## ceil(x) function -- round towards +Infinity
#

sub __ceil__ {
    my ($x) = @_;
    goto(ref($x) =~ tr/:/_/rs);

  Math_MPFR: {
        my $r = Math::MPFR::Rmpfr_init2($PREC);
        Math::MPFR::Rmpfr_ceil($r, $x);
        return $r;
    }

  Math_GMPq: {
        my $z = Math::GMPz::Rmpz_init();
        Math::GMPz::Rmpz_set_q($z, $x);
        Math::GMPq::Rmpq_integer_p($x) && return $z;
        Math::GMPz::Rmpz_add_ui($z, $z, 1) if Math::GMPq::Rmpq_sgn($x) > 0;
        return $z;
    }

  Math_MPC: {

        my $real = Math::MPFR::Rmpfr_init2($PREC);
        my $imag = Math::MPFR::Rmpfr_init2($PREC);

        Math::MPC::RMPC_RE($real, $x);
        Math::MPC::RMPC_IM($imag, $x);

        Math::MPFR::Rmpfr_ceil($real, $real);
        Math::MPFR::Rmpfr_ceil($imag, $imag);

        if (Math::MPFR::Rmpfr_zero_p($imag)) {
            return $real;
        }

        my $r = Math::MPC::Rmpc_init2($PREC);
        Math::MPC::Rmpc_set_fr_fr($r, $real, $imag, $ROUND);
        return $r;
    }
}

sub ceil ($) {
    my ($x) = @_;

    if (ref($x) ne __PACKAGE__) {
        $x = __PACKAGE__->new($x);
    }

    ref($$x) eq 'Math::GMPz' and return $x;    # already an integer
    bless \__ceil__($$x);
}

#
## sin / sinh / asin / asinh
#

sub __sin__ {
    my ($x) = @_;
    goto(ref($x) =~ tr/:/_/rs);

  Math_MPFR: {
        my $r = Math::MPFR::Rmpfr_init2($PREC);
        Math::MPFR::Rmpfr_sin($r, $x, $ROUND);
        return $r;
    }

  Math_MPC: {
        my $r = Math::MPC::Rmpc_init2($PREC);
        Math::MPC::Rmpc_sin($r, $x, $ROUND);
        return $r;
    }
}

sub sin {    # used in overloading
    bless \__sin__(_star2mpfr_mpc($_[0]));
}

sub __sinh__ {
    my ($x) = @_;
    goto(ref($x) =~ tr/:/_/rs);

  Math_MPFR: {
        my $r = Math::MPFR::Rmpfr_init2($PREC);
        Math::MPFR::Rmpfr_sinh($r, $x, $ROUND);
        return $r;
    }

  Math_MPC: {
        my $r = Math::MPC::Rmpc_init2($PREC);
        Math::MPC::Rmpc_sinh($r, $x, $ROUND);
        return $r;
    }
}

sub sinh ($) {
    bless \__sinh__(_star2mpfr_mpc($_[0]));
}

sub __asin__ {
    my ($x) = @_;
    goto(ref($x) =~ tr/:/_/rs);

  Math_MPFR: {

        # Return a complex number for x < -1 or x > 1
        if (   Math::MPFR::Rmpfr_cmp_ui($x, 1) > 0
            or Math::MPFR::Rmpfr_cmp_si($x, -1) < 0) {
            my $r = _mpfr2mpc($x);
            Math::MPC::Rmpc_asin($r, $r, $ROUND);
            return $r;
        }

        my $r = Math::MPFR::Rmpfr_init2($PREC);
        Math::MPFR::Rmpfr_asin($r, $x, $ROUND);
        return $r;
    }

  Math_MPC: {
        my $r = Math::MPC::Rmpc_init2($PREC);
        Math::MPC::Rmpc_asin($r, $x, $ROUND);
        return $r;
    }
}

sub asin ($) {
    bless \__asin__(_star2mpfr_mpc($_[0]));
}

sub __asinh__ {
    my ($x) = @_;
    goto(ref($x) =~ tr/:/_/rs);

  Math_MPFR: {
        my $r = Math::MPFR::Rmpfr_init2($PREC);
        Math::MPFR::Rmpfr_asinh($r, $x, $ROUND);
        return $r;
    }

  Math_MPC: {
        my $r = Math::MPC::Rmpc_init2($PREC);
        Math::MPC::Rmpc_asinh($r, $x, $ROUND);
        return $r;
    }
}

sub asinh ($) {
    bless \__asinh__(_star2mpfr_mpc($_[0]));
}

#
## cos / cosh / acos / acosh
#

sub __cos__ {
    my ($x) = @_;
    goto(ref($x) =~ tr/:/_/rs);

  Math_MPFR: {
        my $r = Math::MPFR::Rmpfr_init2($PREC);
        Math::MPFR::Rmpfr_cos($r, $x, $ROUND);
        return $r;
    }

  Math_MPC: {
        my $r = Math::MPC::Rmpc_init2($PREC);
        Math::MPC::Rmpc_cos($r, $x, $ROUND);
        return $r;
    }
}

sub cos {    # used in overloading
    bless \__cos__(_star2mpfr_mpc($_[0]));
}

sub __cosh__ {
    my ($x) = @_;
    goto(ref($x) =~ tr/:/_/rs);

  Math_MPFR: {
        my $r = Math::MPFR::Rmpfr_init2($PREC);
        Math::MPFR::Rmpfr_cosh($r, $x, $ROUND);
        return $r;
    }

  Math_MPC: {
        my $r = Math::MPC::Rmpc_init2($PREC);
        Math::MPC::Rmpc_cosh($r, $x, $ROUND);
        return $r;
    }
}

sub cosh ($) {
    bless \__cosh__(_star2mpfr_mpc($_[0]));
}

sub __acos__ {
    my ($x) = @_;
    goto(ref($x) =~ tr/:/_/rs);

  Math_MPFR: {

        # Return a complex number for x < -1 or x > 1
        if (   Math::MPFR::Rmpfr_cmp_ui($x, 1) > 0
            or Math::MPFR::Rmpfr_cmp_si($x, -1) < 0) {
            my $r = _mpfr2mpc($x);
            Math::MPC::Rmpc_acos($r, $r, $ROUND);
            return $r;
        }

        my $r = Math::MPFR::Rmpfr_init2($PREC);
        Math::MPFR::Rmpfr_acos($r, $x, $ROUND);
        return $r;
    }

  Math_MPC: {
        my $r = Math::MPC::Rmpc_init2($PREC);
        Math::MPC::Rmpc_acos($r, $x, $ROUND);
        return $r;
    }
}

sub acos ($) {
    bless \__acos__(_star2mpfr_mpc($_[0]));
}

sub __acosh__ {
    my ($x) = @_;
    goto(ref($x) =~ tr/:/_/rs);

  Math_MPFR: {

        # Return a complex number for x < 1
        if (Math::MPFR::Rmpfr_cmp_ui($x, 1) < 0) {
            my $r = _mpfr2mpc($x);
            Math::MPC::Rmpc_acosh($r, $r, $ROUND);
            return $r;
        }

        my $r = Math::MPFR::Rmpfr_init2($PREC);
        Math::MPFR::Rmpfr_acosh($r, $x, $ROUND);
        return $r;
    }

  Math_MPC: {
        my $r = Math::MPC::Rmpc_init2($PREC);
        Math::MPC::Rmpc_acosh($r, $x, $ROUND);
        return $r;
    }
}

sub acosh ($) {
    bless \__acosh__(_star2mpfr_mpc($_[0]));
}

#
## tan / tanh / atan / atanh
#

sub __tan__ {
    my ($x) = @_;
    goto(ref($x) =~ tr/:/_/rs);

  Math_MPFR: {
        my $r = Math::MPFR::Rmpfr_init2($PREC);
        Math::MPFR::Rmpfr_tan($r, $x, $ROUND);
        return $r;
    }

  Math_MPC: {
        my $r = Math::MPC::Rmpc_init2($PREC);
        Math::MPC::Rmpc_tan($r, $x, $ROUND);
        return $r;
    }
}

sub tan ($) {
    bless \__tan__(_star2mpfr_mpc($_[0]));
}

sub __tanh__ {
    my ($x) = @_;
    goto(ref($x) =~ tr/:/_/rs);

  Math_MPFR: {
        my $r = Math::MPFR::Rmpfr_init2($PREC);
        Math::MPFR::Rmpfr_tanh($r, $x, $ROUND);
        return $r;
    }

  Math_MPC: {
        my $r = Math::MPC::Rmpc_init2($PREC);
        Math::MPC::Rmpc_tanh($r, $x, $ROUND);
        return $r;
    }
}

sub tanh ($) {
    bless \__tanh__(_star2mpfr_mpc($_[0]));
}

sub __atan__ {
    my ($x) = @_;
    goto(ref($x) =~ tr/:/_/rs);

  Math_MPFR: {
        my $r = Math::MPFR::Rmpfr_init2($PREC);
        Math::MPFR::Rmpfr_atan($r, $x, $ROUND);
        return $r;
    }

  Math_MPC: {
        my $r = Math::MPC::Rmpc_init2($PREC);
        Math::MPC::Rmpc_atan($r, $x, $ROUND);
        return $r;
    }
}

sub atan ($) {
    bless \__atan__(_star2mpfr_mpc($_[0]));
}

sub __atanh__ {
    my ($x) = @_;
    goto(ref($x) =~ tr/:/_/rs);

  Math_MPFR: {

        # Return a complex number for x < -1 or x > 1
        if (   Math::MPFR::Rmpfr_cmp_ui($x, +1) > 0
            or Math::MPFR::Rmpfr_cmp_si($x, -1) < 0) {
            my $r = _mpfr2mpc($x);
            Math::MPC::Rmpc_atanh($r, $r, $ROUND);
            return $r;
        }

        my $r = Math::MPFR::Rmpfr_init2($PREC);
        Math::MPFR::Rmpfr_atanh($r, $x, $ROUND);
        return $r;
    }

  Math_MPC: {
        my $r = Math::MPC::Rmpc_init2($PREC);
        Math::MPC::Rmpc_atanh($r, $x, $ROUND);
        return $r;
    }
}

sub atanh ($) {
    bless \__atanh__(_star2mpfr_mpc($_[0]));
}

sub __atan2__ {
    my ($x, $y) = @_;
    goto(join('__', ref($x), ref($y)) =~ tr/:/_/rs);

  Math_MPFR__Math_MPFR: {
        my $r = Math::MPFR::Rmpfr_init2($PREC);
        Math::MPFR::Rmpfr_atan2($r, $x, $y, $ROUND);
        return $r;
    }

  Math_MPFR__Math_MPC: {
        $x = _mpfr2mpc($x);
        goto Math_MPC__Math_MPC;
    }

  Math_MPC__Math_MPFR: {
        $y = _mpfr2mpc($y);
        goto Math_MPC__Math_MPC;
    }

    #
    ## atan2(x, y) = -i * log((y + x*i) / sqrt(x^2 + y^2))
    #
  Math_MPC__Math_MPC: {
        my $r = Math::MPC::Rmpc_init2($PREC);

        Math::MPC::Rmpc_mul_i($r, $x, 1, $ROUND);
        Math::MPC::Rmpc_add($r, $r, $y, $ROUND);

        my $t1 = Math::MPC::Rmpc_init2($PREC);
        my $t2 = Math::MPC::Rmpc_init2($PREC);

        Math::MPC::Rmpc_sqr($t1, $x, $ROUND);
        Math::MPC::Rmpc_sqr($t2, $y, $ROUND);
        Math::MPC::Rmpc_add($t1, $t1, $t2, $ROUND);
        Math::MPC::Rmpc_sqrt($t1, $t1, $ROUND);

        Math::MPC::Rmpc_div($r, $r, $t1, $ROUND);
        Math::MPC::Rmpc_log($r, $r, $ROUND);
        Math::MPC::Rmpc_mul_i($r, $r, -1, $ROUND);

        return $r;
    }
}

sub atan2 ($$) {
    bless \__atan2__(_star2mpfr_mpc($_[0]), _star2mpfr_mpc($_[1]));
}

#
## sec / sech / asec / asech
#

sub __sec__ {
    my ($x) = @_;
    goto(ref($x) =~ tr/:/_/rs);

  Math_MPFR: {
        my $r = Math::MPFR::Rmpfr_init2($PREC);
        Math::MPFR::Rmpfr_sec($r, $x, $ROUND);
        return $r;
    }

    # sec(x) = 1/cos(x)
  Math_MPC: {
        my $r = Math::MPC::Rmpc_init2($PREC);
        Math::MPC::Rmpc_cos($r, $x, $ROUND);
        Math::MPC::Rmpc_ui_div($r, 1, $r, $ROUND);
        return $r;
    }
}

sub sec ($) {
    bless \__sec__(_star2mpfr_mpc($_[0]));
}

sub __sech__ {
    my ($x) = @_;
    goto(ref($x) =~ tr/:/_/rs);

  Math_MPFR: {
        my $r = Math::MPFR::Rmpfr_init2($PREC);
        Math::MPFR::Rmpfr_sech($r, $x, $ROUND);
        return $r;
    }

    # sech(x) = 1/cosh(x)
  Math_MPC: {
        my $r = Math::MPC::Rmpc_init2($PREC);
        Math::MPC::Rmpc_cosh($r, $x, $ROUND);
        Math::MPC::Rmpc_ui_div($r, 1, $r, $ROUND);
        return $r;
    }
}

sub sech ($) {
    bless \__sech__(_star2mpfr_mpc($_[0]));
}

sub __asec__ {
    my ($x) = @_;
    goto(ref($x) =~ tr/:/_/rs);

    # asec(x) = acos(1/x)
  Math_MPFR: {

        # Return a complex number for x > -1 and x < 1
        if (    Math::MPFR::Rmpfr_cmp_ui($x, 1) < 0
            and Math::MPFR::Rmpfr_cmp_si($x, -1) > 0) {
            $x = _mpfr2mpc($x);
            goto Math_MPC;
        }

        my $r = Math::MPFR::Rmpfr_init2($PREC);
        Math::MPFR::Rmpfr_ui_div($r, 1, $x, $ROUND);
        Math::MPFR::Rmpfr_acos($r, $r, $ROUND);
        return $r;
    }

    # asec(x) = acos(1/x)
  Math_MPC: {
        my $r = Math::MPC::Rmpc_init2($PREC);
        Math::MPC::Rmpc_ui_div($r, 1, $x, $ROUND);
        Math::MPC::Rmpc_acos($r, $r, $ROUND);
        return $r;
    }
}

sub asec ($) {
    bless \__asec__(_star2mpfr_mpc($_[0]));
}

sub __asech__ {
    my ($x) = @_;
    goto(ref($x) =~ tr/:/_/rs);

    # asech(x) = acosh(1/x)
  Math_MPFR: {

        # Return a complex number for x < 0 or x > 1
        if (   Math::MPFR::Rmpfr_cmp_ui($x, 1) > 0
            or Math::MPFR::Rmpfr_cmp_ui($x, 0) < 0) {
            $x = _mpfr2mpc($x);
            goto Math_MPC;
        }

        my $r = Math::MPFR::Rmpfr_init2($PREC);
        Math::MPFR::Rmpfr_ui_div($r, 1, $x, $ROUND);
        Math::MPFR::Rmpfr_acosh($r, $r, $ROUND);
        return $r;
    }

    # asech(x) = acosh(1/x)
  Math_MPC: {
        my $r = Math::MPC::Rmpc_init2($PREC);
        Math::MPC::Rmpc_ui_div($r, 1, $x, $ROUND);
        Math::MPC::Rmpc_acosh($r, $r, $ROUND);
        return $r;
    }
}

sub asech ($) {
    bless \__asech__(_star2mpfr_mpc($_[0]));
}

#
## csc / csch / acsc / acsch
#

sub __csc__ {
    my ($x) = @_;
    goto(ref($x) =~ tr/:/_/rs);

  Math_MPFR: {
        my $r = Math::MPFR::Rmpfr_init2($PREC);
        Math::MPFR::Rmpfr_csc($r, $x, $ROUND);
        return $r;
    }

    # csc(x) = 1/sin(x)
  Math_MPC: {
        my $r = Math::MPC::Rmpc_init2($PREC);
        Math::MPC::Rmpc_sin($r, $x, $ROUND);
        Math::MPC::Rmpc_ui_div($r, 1, $r, $ROUND);
        return $r;
    }
}

sub csc ($) {
    bless \__csc__(_star2mpfr_mpc($_[0]));
}

sub __csch__ {
    my ($x) = @_;
    goto(ref($x) =~ tr/:/_/rs);

  Math_MPFR: {
        my $r = Math::MPFR::Rmpfr_init2($PREC);
        Math::MPFR::Rmpfr_csch($r, $x, $ROUND);
        return $r;
    }

    # csch(x) = 1/sinh(x)
  Math_MPC: {
        my $r = Math::MPC::Rmpc_init2($PREC);
        Math::MPC::Rmpc_sinh($r, $x, $ROUND);
        Math::MPC::Rmpc_ui_div($r, 1, $r, $ROUND);
        return $r;
    }
}

sub csch ($) {
    bless \__csch__(_star2mpfr_mpc($_[0]));
}

sub __acsc__ {
    my ($x) = @_;
    goto(ref($x) =~ tr/:/_/rs);

    # acsc(x) = asin(1/x)
  Math_MPFR: {

        # Return a complex number for x > -1 and x < 1
        if (    Math::MPFR::Rmpfr_cmp_ui($x, 1) < 0
            and Math::MPFR::Rmpfr_cmp_si($x, -1) > 0) {
            $x = _mpfr2mpc($x);
            goto Math_MPC;
        }

        my $r = Math::MPFR::Rmpfr_init2($PREC);
        Math::MPFR::Rmpfr_ui_div($r, 1, $x, $ROUND);
        Math::MPFR::Rmpfr_asin($r, $r, $ROUND);
        return $r;
    }

    # acsc(x) = asin(1/x)
  Math_MPC: {
        my $r = Math::MPC::Rmpc_init2($PREC);
        Math::MPC::Rmpc_ui_div($r, 1, $x, $ROUND);
        Math::MPC::Rmpc_asin($r, $r, $ROUND);
        return $r;
    }
}

sub acsc ($) {
    bless \__acsc__(_star2mpfr_mpc($_[0]));
}

sub __acsch__ {
    my ($x) = @_;
    goto(ref($x) =~ tr/:/_/rs);

    # acsch(x) = asinh(1/x)
  Math_MPFR: {
        my $r = Math::MPFR::Rmpfr_init2($PREC);
        Math::MPFR::Rmpfr_ui_div($r, 1, $x, $ROUND);
        Math::MPFR::Rmpfr_asinh($r, $r, $ROUND);
        return $r;
    }

    # acsch(x) = asinh(1/x)
  Math_MPC: {
        my $r = Math::MPC::Rmpc_init2($PREC);
        Math::MPC::Rmpc_ui_div($r, 1, $x, $ROUND);
        Math::MPC::Rmpc_asinh($r, $r, $ROUND);
        return $r;
    }
}

sub acsch ($) {
    bless \__acsch__(_star2mpfr_mpc($_[0]));
}

#
## cot / coth / acot / acoth
#

sub __cot__ {
    my ($x) = @_;
    goto(ref($x) =~ tr/:/_/rs);

  Math_MPFR: {
        my $r = Math::MPFR::Rmpfr_init2($PREC);
        Math::MPFR::Rmpfr_cot($r, $x, $ROUND);
        return $r;
    }

    # cot(x) = 1/tan(x)
  Math_MPC: {
        my $r = Math::MPC::Rmpc_init2($PREC);
        Math::MPC::Rmpc_tan($r, $x, $ROUND);
        Math::MPC::Rmpc_ui_div($r, 1, $r, $ROUND);
        return $r;
    }
}

sub cot ($) {
    bless \__cot__(_star2mpfr_mpc($_[0]));
}

sub __coth__ {
    my ($x) = @_;
    goto(ref($x) =~ tr/:/_/rs);

  Math_MPFR: {
        my $r = Math::MPFR::Rmpfr_init2($PREC);
        Math::MPFR::Rmpfr_coth($r, $x, $ROUND);
        return $r;
    }

    # coth(x) = 1/tanh(x)
  Math_MPC: {
        my $r = Math::MPC::Rmpc_init2($PREC);
        Math::MPC::Rmpc_tanh($r, $x, $ROUND);
        Math::MPC::Rmpc_ui_div($r, 1, $r, $ROUND);
        return $r;
    }
}

sub coth ($) {
    bless \__coth__(_star2mpfr_mpc($_[0]));
}

sub __acot__ {
    my ($x) = @_;
    goto(ref($x) =~ tr/:/_/rs);

    # acot(x) = atan(1/x)
  Math_MPFR: {
        my $r = Math::MPFR::Rmpfr_init2($PREC);
        Math::MPFR::Rmpfr_ui_div($r, 1, $x, $ROUND);
        Math::MPFR::Rmpfr_atan($r, $r, $ROUND);
        return $r;
    }

    # acot(x) = atan(1/x)
  Math_MPC: {
        my $r = Math::MPC::Rmpc_init2($PREC);
        Math::MPC::Rmpc_ui_div($r, 1, $x, $ROUND);
        Math::MPC::Rmpc_atan($r, $r, $ROUND);
        return $r;
    }
}

sub acot ($) {
    bless \__acot__(_star2mpfr_mpc($_[0]));
}

sub __acoth__ {
    my ($x) = @_;
    goto(ref($x) =~ tr/:/_/rs);

    # acoth(x) = atanh(1/x)
  Math_MPFR: {

        # Return a complex number for x > -1 and x < 1
        if (    Math::MPFR::Rmpfr_cmp_ui($x, 1) < 0
            and Math::MPFR::Rmpfr_cmp_si($x, -1) > 0) {
            $x = _mpfr2mpc($x);
            goto Math_MPC;
        }

        my $r = Math::MPFR::Rmpfr_init2($PREC);
        Math::MPFR::Rmpfr_ui_div($r, 1, $x, $ROUND);
        Math::MPFR::Rmpfr_atanh($r, $r, $ROUND);
        return $r;
    }

    # acoth(x) = atanh(1/x)
  Math_MPC: {
        my $r = Math::MPC::Rmpc_init2($PREC);
        Math::MPC::Rmpc_ui_div($r, 1, $x, $ROUND);
        Math::MPC::Rmpc_atanh($r, $r, $ROUND);
        return $r;
    }
}

sub acoth ($) {
    bless \__acoth__(_star2mpfr_mpc($_[0]));
}

sub deg2rad ($) {
    my ($x) = @_;
    my $f = Math::MPFR::Rmpfr_init2($PREC);
    Math::MPFR::Rmpfr_const_pi($f, $ROUND);
    Math::MPFR::Rmpfr_div_ui($f, $f, 180, $ROUND);
    bless \__mul__(_star2obj($x), $f);
}

sub rad2deg ($) {
    my ($x) = @_;
    my $f = Math::MPFR::Rmpfr_init2($PREC);
    Math::MPFR::Rmpfr_const_pi($f, $ROUND);
    Math::MPFR::Rmpfr_ui_div($f, 180, $f, $ROUND);
    bless \__mul__(_star2obj($x), $f);
}

#
## gamma
#

sub gamma ($) {
    my $r = Math::MPFR::Rmpfr_init2($PREC);
    Math::MPFR::Rmpfr_gamma($r, _star2mpfr($_[0]), $ROUND);
    bless \$r;
}

#
## lgamma
#

sub lgamma ($) {
    my $r = Math::MPFR::Rmpfr_init2($PREC);
    Math::MPFR::Rmpfr_lgamma($r, _star2mpfr($_[0]), $ROUND);
    bless \$r;
}

#
## lngamma
#

sub lngamma ($) {
    my $r = Math::MPFR::Rmpfr_init2($PREC);
    Math::MPFR::Rmpfr_lngamma($r, _star2mpfr($_[0]), $ROUND);
    bless \$r;
}

#
## digamma
#

sub digamma ($) {
    my $r = Math::MPFR::Rmpfr_init2($PREC);
    Math::MPFR::Rmpfr_digamma($r, _star2mpfr($_[0]), $ROUND);
    bless \$r;
}

#
## zeta
#

sub zeta ($) {
    my ($x) = @_;

    if (!ref($x) and CORE::int($x) eq $x and $x >= 0 and $x < ULONG_MAX) {
        ## $x is an unsigned integer
    }
    else {
        $x = _star2mpfr($x);

        # If $x fits inside an unsigned integer, then unpack it.
        if (    Math::MPFR::Rmpfr_integer_p($x)
            and Math::MPFR::Rmpfr_fits_ulong_p($x, $ROUND)) {
            $x = Math::MPFR::Rmpfr_get_ui($x, $ROUND);
        }
    }

    my $r = Math::MPFR::Rmpfr_init2($PREC);

    ref($x)
      ? Math::MPFR::Rmpfr_zeta($r, $x, $ROUND)
      : Math::MPFR::Rmpfr_zeta_ui($r, $x, $ROUND);

    bless \$r;
}

#
## Dirichlet eta function
#

# Implemented as:
#    eta(1) = ln(2)
#    eta(x) = (1 - 2**(1-x)) * zeta(x)

sub eta ($) {
    my $x = _star2mpfr($_[0]);

    my $r        = Math::MPFR::Rmpfr_init2($PREC);
    my $x_is_int = Math::MPFR::Rmpfr_integer_p($x);

    # Special case for eta(1) = log(2)
    if ($x_is_int and Math::MPFR::Rmpfr_cmp_ui($x, 1) == 0) {
        Math::MPFR::Rmpfr_const_log2($r, $ROUND);
        return bless \$r;
    }

    my $t = Math::MPFR::Rmpfr_init2($PREC);

    Math::MPFR::Rmpfr_ui_sub($r, 1, $x, $ROUND);
    Math::MPFR::Rmpfr_ui_pow($r, 2, $r, $ROUND);
    Math::MPFR::Rmpfr_ui_sub($r, 1, $r, $ROUND);

    if ($x_is_int and Math::MPFR::Rmpfr_fits_ulong_p($x, $ROUND)) {
        Math::MPFR::Rmpfr_zeta_ui($t, Math::MPFR::Rmpfr_get_ui($x, $ROUND), $ROUND);
    }
    else {
        Math::MPFR::Rmpfr_zeta($t, $x, $ROUND);
    }

    Math::MPFR::Rmpfr_mul($r, $r, $t, $ROUND);
    bless \$r;
}

#
## Beta(x,y) function
#

# Implemented as:
#    beta(x,y) = gamma(x)*gamma(y) / gamma(x+y)

sub beta ($$) {
    my $x = _star2mpfr($_[0]);
    my $y = _star2mpfr($_[1]);

    state $has_beta = (Math::MPFR::MPFR_VERSION_MAJOR() >= 4);

    if ($has_beta) {    # available since mpfr-4.0.0
        my $r = Math::MPFR::Rmpfr_init2($PREC);
        Math::MPFR::Rmpfr_beta($r, $x, $y, $ROUND);
        return bless \$r;
    }

    my $t1 = Math::MPFR::Rmpfr_init2($PREC);    # gamma(x+y)
    my $t2 = Math::MPFR::Rmpfr_init2($PREC);    # gamma(y)

    my $r = Math::MPFR::Rmpfr_init2($PREC);

    Math::MPFR::Rmpfr_add($t1, $x, $y, $ROUND);
    Math::MPFR::Rmpfr_gamma($t1, $t1, $ROUND);
    Math::MPFR::Rmpfr_gamma($r,  $x,  $ROUND);
    Math::MPFR::Rmpfr_gamma($t2, $y,  $ROUND);
    Math::MPFR::Rmpfr_mul($r, $r, $t2, $ROUND);
    Math::MPFR::Rmpfr_div($r, $r, $t1, $ROUND);

    bless \$r;
}

#
## Airy function (Ai)
#

sub Ai ($) {
    my $r = Math::MPFR::Rmpfr_init2($PREC);
    Math::MPFR::Rmpfr_ai($r, _star2mpfr($_[0]), $ROUND);
    bless \$r;
}

#
## Exponential integral (Ei)
#

sub Ei ($) {
    my $r = Math::MPFR::Rmpfr_init2($PREC);
    Math::MPFR::Rmpfr_eint($r, _star2mpfr($_[0]), $ROUND);
    bless \$r;
}

#
## Logarithmic integral (Li)
#
sub Li ($) {
    my $r = Math::MPFR::Rmpfr_init2($PREC);
    Math::MPFR::Rmpfr_log($r, _star2mpfr($_[0]), $ROUND);
    Math::MPFR::Rmpfr_eint($r, $r, $ROUND);
    bless \$r;
}

#
## Dilogarithm function (Li_2)
#
sub Li2 ($) {
    my $r = Math::MPFR::Rmpfr_init2($PREC);
    Math::MPFR::Rmpfr_li2($r, _star2mpfr($_[0]), $ROUND);
    bless \$r;
}

#
## Error function
#
sub erf ($) {
    my $r = Math::MPFR::Rmpfr_init2($PREC);
    Math::MPFR::Rmpfr_erf($r, _star2mpfr($_[0]), $ROUND);
    bless \$r;
}

#
## Complementary error function
#
sub erfc ($) {
    my $r = Math::MPFR::Rmpfr_init2($PREC);
    Math::MPFR::Rmpfr_erfc($r, _star2mpfr($_[0]), $ROUND);
    bless \$r;
}

#
## Lambert W function
#

sub __LambertW__ {
    my ($x) = @_;

    my $p = Math::MPFR::Rmpfr_init2($PREC);
    Math::MPFR::Rmpfr_set_str($p, '1e-' . CORE::int($PREC >> 2), 10, $ROUND);

    goto(ref($x) =~ tr/:/_/rs);

  Math_MPFR: {

        # Return a complex number for x < -1/e
        if (Math::MPFR::Rmpfr_cmp_d($x, -1 / CORE::exp(1)) < 0) {
            $x = _mpfr2mpc($x);
            goto Math_MPC;
        }

        Math::MPFR::Rmpfr_set_ui((my $r = Math::MPFR::Rmpfr_init2($PREC)), 1, $ROUND);
        Math::MPFR::Rmpfr_set_ui((my $y = Math::MPFR::Rmpfr_init2($PREC)), 0, $ROUND);

        my $count = 0;
        my $tmp   = Math::MPFR::Rmpfr_init2($PREC);

        while (1) {
            Math::MPFR::Rmpfr_sub($tmp, $r, $y, $ROUND);
            Math::MPFR::Rmpfr_cmpabs($tmp, $p) <= 0 and last;

            Math::MPFR::Rmpfr_set($y, $r, $ROUND);

            Math::MPFR::Rmpfr_log($tmp, $r, $ROUND);
            Math::MPFR::Rmpfr_add_ui($tmp, $tmp, 1, $ROUND);

            Math::MPFR::Rmpfr_add($r, $r, $x, $ROUND);
            Math::MPFR::Rmpfr_div($r, $r, $tmp, $ROUND);
            last if ++$count > $PREC;
        }

        Math::MPFR::Rmpfr_log($r, $r, $ROUND);
        return $r;
    }

  Math_MPC: {
        my $r = Math::MPC::Rmpc_init2($PREC);
        Math::MPC::Rmpc_sqrt($r, $x, $ROUND);
        Math::MPC::Rmpc_add_ui($r, $r, 1, $ROUND);

        my $y = Math::MPC::Rmpc_init2($PREC);
        Math::MPC::Rmpc_set_ui($y, 0, $ROUND);

        my $tmp = Math::MPC::Rmpc_init2($PREC);
        my $abs = Math::MPFR::Rmpfr_init2($PREC);

        my $count = 0;
        while (1) {
            Math::MPC::Rmpc_sub($tmp, $r, $y, $ROUND);

            Math::MPC::Rmpc_abs($abs, $tmp, $ROUND);
            Math::MPFR::Rmpfr_cmp($abs, $p) <= 0 and last;

            Math::MPC::Rmpc_set($y, $r, $ROUND);

            Math::MPC::Rmpc_log($tmp, $r, $ROUND);
            Math::MPC::Rmpc_add_ui($tmp, $tmp, 1, $ROUND);

            Math::MPC::Rmpc_add($r, $r, $x, $ROUND);
            Math::MPC::Rmpc_div($r, $r, $tmp, $ROUND);
            last if ++$count > $PREC;
        }

        Math::MPC::Rmpc_log($r, $r, $ROUND);
        return $r;
    }
}

sub LambertW ($) {
    bless \__LambertW__(_star2mpfr_mpc($_[0]));
}

#
## lgrt -- logarithmic root
#

sub __lgrt__ {
    my ($c) = @_;

    my $p = Math::MPFR::Rmpfr_init2($PREC);
    Math::MPFR::Rmpfr_set_str($p, '1e-' . CORE::int($PREC >> 2), 10, $ROUND);

    goto(ref($c) =~ tr/:/_/rs);

  Math_MPFR: {

        # Return a complex number for x < e^(-1/e)
        if (Math::MPFR::Rmpfr_cmp_d($c, CORE::exp(-1 / CORE::exp(1))) < 0) {
            $c = _mpfr2mpc($c);
            goto Math_MPC;
        }

        my $r = Math::MPFR::Rmpfr_init2($PREC);
        Math::MPFR::Rmpfr_log($r, $c, $ROUND);

        Math::MPFR::Rmpfr_set_ui((my $x = Math::MPFR::Rmpfr_init2($PREC)), 1, $ROUND);
        Math::MPFR::Rmpfr_set_ui((my $y = Math::MPFR::Rmpfr_init2($PREC)), 0, $ROUND);

        my $count = 0;
        my $tmp   = Math::MPFR::Rmpfr_init2($PREC);

        while (1) {
            Math::MPFR::Rmpfr_sub($tmp, $x, $y, $ROUND);
            Math::MPFR::Rmpfr_cmpabs($tmp, $p) <= 0 and last;

            Math::MPFR::Rmpfr_set($y, $x, $ROUND);

            Math::MPFR::Rmpfr_log($tmp, $x, $ROUND);
            Math::MPFR::Rmpfr_add_ui($tmp, $tmp, 1, $ROUND);

            Math::MPFR::Rmpfr_add($x, $x, $r, $ROUND);
            Math::MPFR::Rmpfr_div($x, $x, $tmp, $ROUND);
            last if ++$count > $PREC;
        }

        return $x;
    }

  Math_MPC: {
        my $d = Math::MPC::Rmpc_init2($PREC);
        Math::MPC::Rmpc_log($d, $c, $ROUND);

        my $x = Math::MPC::Rmpc_init2($PREC);
        Math::MPC::Rmpc_sqrt($x, $c, $ROUND);
        Math::MPC::Rmpc_add_ui($x, $x, 1, $ROUND);
        Math::MPC::Rmpc_log($x, $x, $ROUND);

        my $y = Math::MPC::Rmpc_init2($PREC);
        Math::MPC::Rmpc_set_ui($y, 0, $ROUND);

        my $tmp = Math::MPC::Rmpc_init2($PREC);
        my $abs = Math::MPFR::Rmpfr_init2($PREC);

        my $count = 0;
        while (1) {
            Math::MPC::Rmpc_sub($tmp, $x, $y, $ROUND);

            Math::MPC::Rmpc_abs($abs, $tmp, $ROUND);
            Math::MPFR::Rmpfr_cmp($abs, $p) <= 0 and last;

            Math::MPC::Rmpc_set($y, $x, $ROUND);

            Math::MPC::Rmpc_log($tmp, $x, $ROUND);
            Math::MPC::Rmpc_add_ui($tmp, $tmp, 1, $ROUND);

            Math::MPC::Rmpc_add($x, $x, $d, $ROUND);
            Math::MPC::Rmpc_div($x, $x, $tmp, $ROUND);
            last if ++$count > $PREC;
        }

        return $x;
    }
}

sub lgrt ($) {
    bless \__lgrt__(_star2mpfr_mpc($_[0]));
}

#
## Arithmetic-geometric mean
#

sub __agm__ {
    my ($x, $y) = @_;
    goto(join('__', ref($x), ref($y)) =~ tr/:/_/rs);

  Math_MPFR__Math_MPFR: {

        if (   Math::MPFR::Rmpfr_sgn($x) < 0
            or Math::MPFR::Rmpfr_sgn($y) < 0) {

            $x = _mpfr2mpc($x);
            $y = _mpfr2mpc($y);

            goto Math_MPC__Math_MPC;
        }

        my $r = Math::MPFR::Rmpfr_init2($PREC);
        Math::MPFR::Rmpfr_agm($r, $x, $y, $ROUND);
        return $r;
    }

  Math_MPC__Math_MPC: {

        # agm(0,  x) = 0
        Math::MPC::Rmpc_cmp_si_si($x, 0, 0) || return $x;

        # agm(x, 0) = 0
        Math::MPC::Rmpc_cmp_si_si($y, 0, 0) || return $y;

        my $a0 = Math::MPC::Rmpc_init2($PREC);
        my $g0 = Math::MPC::Rmpc_init2($PREC);

        my $a1 = Math::MPC::Rmpc_init2($PREC);
        my $g1 = Math::MPC::Rmpc_init2($PREC);

        my $t = Math::MPC::Rmpc_init2($PREC);

        Math::MPC::Rmpc_set($a0, $x, $ROUND);
        Math::MPC::Rmpc_set($g0, $y, $ROUND);

        my $count = 0;
        {
            Math::MPC::Rmpc_add($a1, $a0, $g0, $ROUND);
            Math::MPC::Rmpc_div_2ui($a1, $a1, 1, $ROUND);

            Math::MPC::Rmpc_mul($g1, $a0, $g0, $ROUND);
            Math::MPC::Rmpc_add($t, $a0, $g0, $ROUND);
            Math::MPC::Rmpc_sqr($t, $t, $ROUND);
            Math::MPC::Rmpc_cmp_si_si($t, 0, 0) || return $t;
            Math::MPC::Rmpc_div($g1, $g1, $t, $ROUND);
            Math::MPC::Rmpc_sqrt($g1, $g1, $ROUND);
            Math::MPC::Rmpc_add($t, $a0, $g0, $ROUND);
            Math::MPC::Rmpc_mul($g1, $g1, $t, $ROUND);

            if (Math::MPC::Rmpc_cmp($a0, $a1) and ++$count < $PREC) {
                Math::MPC::Rmpc_set($a0, $a1, $ROUND);
                Math::MPC::Rmpc_set($g0, $g1, $ROUND);
                redo;
            }
        }

        return $g0;
    }

  Math_MPFR__Math_MPC: {
        $x = _mpfr2mpc($x);
        goto Math_MPC__Math_MPC;
    }

  Math_MPC__Math_MPFR: {
        $y = _mpfr2mpc($y);
        goto Math_MPC__Math_MPC;
    }
}

sub agm ($$) {
    bless \__agm__(_star2mpfr_mpc($_[0]), _star2mpfr_mpc($_[1]));
}

#
## hypot
#

# hypot(x, y) = sqrt(x^2 + y^2)

sub __hypot__ {
    my ($x, $y) = @_;
    goto(join('__', ref($x), ref($y)) =~ tr/:/_/rs);

  Math_MPFR__Math_MPFR: {
        my $r = Math::MPFR::Rmpfr_init2($PREC);
        Math::MPFR::Rmpfr_hypot($r, $x, $y, $ROUND);
        return $r;
    }

  Math_MPFR__Math_MPC: {
        my $r = Math::MPFR::Rmpfr_init2($PREC);
        Math::MPC::Rmpc_abs($r, $y, $ROUND);
        Math::MPFR::Rmpfr_hypot($r, $r, $x, $ROUND);
        return $r;
    }

  Math_MPC__Math_MPFR: {
        my $r = Math::MPFR::Rmpfr_init2($PREC);
        Math::MPC::Rmpc_abs($r, $x, $ROUND);
        Math::MPFR::Rmpfr_hypot($r, $r, $y, $ROUND);
        return $r;
    }

  Math_MPC__Math_MPC: {
        my $r = Math::MPFR::Rmpfr_init2($PREC);
        Math::MPC::Rmpc_abs($r, $x, $ROUND);
        my $t = Math::MPFR::Rmpfr_init2($PREC);
        Math::MPC::Rmpc_abs($t, $y, $ROUND);
        Math::MPFR::Rmpfr_hypot($r, $r, $t, $ROUND);
        return $r;
    }
}

sub hypot ($$) {
    bless \__hypot__(_star2mpfr_mpc($_[0]), _star2mpfr_mpc($_[1]));
}

#
## BesselJ
#

sub __BesselJ__ {
    my ($x, $n) = @_;
    goto(join('__', ref($x), ref($n) || 'Scalar') =~ tr/:/_/rs);

  Math_MPFR__Scalar: {
        my $r = Math::MPFR::Rmpfr_init2($PREC);

        if ($n == 0) {
            Math::MPFR::Rmpfr_j0($r, $x, $ROUND);
        }
        elsif ($n == 1) {
            Math::MPFR::Rmpfr_j1($r, $x, $ROUND);
        }
        else {
            Math::MPFR::Rmpfr_jn($r, $n, $x, $ROUND);
        }

        return $r;
    }

  Math_MPFR__Math_GMPz: {

        $n = Math::GMPz::Rmpz_get_d($n);

        # Limit goes to zero when n goes to +/-Infinity
        if (($n < LONG_MIN or $n > ULONG_MAX)
            and Math::MPFR::Rmpfr_number_p($x)) {
            my $r = Math::MPFR::Rmpfr_init2($PREC);
            Math::MPFR::Rmpfr_set_ui($r, 0, $ROUND);
            return $r;
        }

        goto Math_MPFR__Scalar;
    }
}

sub BesselJ ($$) {
    my ($x, $y) = @_;

    $x = ref($x) eq __PACKAGE__ ? _any2mpfr($$x) : _star2mpfr($x);

    if (!ref($y) and CORE::int($y) eq $y and $y < ULONG_MAX and $y > LONG_MIN) {
        return bless \__BesselJ__($x, $y);
    }

    bless \__BesselJ__($x, _star2mpz($y) // (goto &nan));
}

#
## BesselY
#

sub __BesselY__ {
    my ($x, $n) = @_;
    goto(join('__', ref($x), ref($n) || 'Scalar') =~ tr/:/_/rs);

  Math_MPFR__Scalar: {
        my $r = Math::MPFR::Rmpfr_init2($PREC);

        if ($n == 0) {
            Math::MPFR::Rmpfr_y0($r, $x, $ROUND);
        }
        elsif ($n == 1) {
            Math::MPFR::Rmpfr_y1($r, $x, $ROUND);
        }
        else {
            Math::MPFR::Rmpfr_yn($r, $n, $x, $ROUND);
        }

        return $r;
    }

  Math_MPFR__Math_GMPz: {

        $n = Math::GMPz::Rmpz_get_d($n);

        if ($n < LONG_MIN or $n > ULONG_MAX) {

            my $r = Math::MPFR::Rmpfr_init2($PREC);

            if (Math::MPFR::Rmpfr_sgn($x) < 0 or !Math::MPFR::Rmpfr_number_p($x)) {
                Math::MPFR::Rmpfr_set_nan($r);
                return $r;
            }

            if ($n < 0) {
                Math::MPFR::Rmpfr_set_inf($r, 1);
            }
            else {
                Math::MPFR::Rmpfr_set_inf($r, -1);
            }

            return $r;
        }

        goto Math_MPFR__Scalar;
    }
}

sub BesselY ($$) {
    my ($x, $y) = @_;

    $x = ref($x) eq __PACKAGE__ ? _any2mpfr($$x) : _star2mpfr($x);

    if (!ref($y) and CORE::int($y) eq $y and $y < ULONG_MAX and $y > LONG_MIN) {
        return bless \__BesselY__($x, $y);
    }

    bless \__BesselY__($x, _star2mpz($y) // (goto &nan));
}

#
## ROUND
#

sub __round__ {
    my ($x, $prec) = @_;
    goto(ref($x) =~ tr/:/_/rs);

  Math_MPFR: {

        my $nth = -CORE::int($prec);

        my $p = Math::MPFR::Rmpfr_init2($PREC);
        Math::MPFR::Rmpfr_set_str($p, '1e' . CORE::abs($nth), 10, $ROUND);

        my $r = Math::MPFR::Rmpfr_init2($PREC);

        if ($nth < 0) {
            Math::MPFR::Rmpfr_div($r, $x, $p, $ROUND);
        }
        else {
            Math::MPFR::Rmpfr_mul($r, $x, $p, $ROUND);
        }

        Math::MPFR::Rmpfr_round($r, $r);

        if ($nth < 0) {
            Math::MPFR::Rmpfr_mul($r, $r, $p, $ROUND);
        }
        else {
            Math::MPFR::Rmpfr_div($r, $r, $p, $ROUND);
        }

        return $r;
    }

  Math_MPC: {

        my $real = Math::MPFR::Rmpfr_init2($PREC);
        my $imag = Math::MPFR::Rmpfr_init2($PREC);

        Math::MPC::RMPC_RE($real, $x);
        Math::MPC::RMPC_IM($imag, $x);

        $real = __round__($real, $prec);
        $imag = __round__($imag, $prec);

        if (Math::MPFR::Rmpfr_zero_p($imag)) {
            return $real;
        }

        my $r = Math::MPC::Rmpc_init2($PREC);
        Math::MPC::Rmpc_set_fr_fr($r, $real, $imag, $ROUND);
        return $r;
    }

  Math_GMPq: {

        my $nth = -CORE::int($prec);

        my $n = Math::GMPq::Rmpq_init();
        Math::GMPq::Rmpq_set($n, $x);

        my $sgn = Math::GMPq::Rmpq_sgn($n);

        if ($sgn < 0) {
            Math::GMPq::Rmpq_neg($n, $n);
        }

        my $p = Math::GMPz::Rmpz_init_set_str('1' . ('0' x CORE::abs($nth)), 10);

        if ($nth < 0) {
            Math::GMPq::Rmpq_div_z($n, $n, $p);
        }
        else {
            Math::GMPq::Rmpq_mul_z($n, $n, $p);
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
            Math::GMPq::Rmpq_mul_z($n, $n, $p);
        }
        else {
            Math::GMPq::Rmpq_div_z($n, $n, $p);
        }

        if ($sgn < 0) {
            Math::GMPq::Rmpq_neg($n, $n);
        }

        if (Math::GMPq::Rmpq_integer_p($n)) {
            Math::GMPz::Rmpz_set_q($z, $n);
            return $z;
        }

        return $n;
    }

  Math_GMPz: {
        $x = _mpz2mpq($x);
        goto Math_GMPq;
    }
}

sub round ($;$) {
    my ($x, $y) = @_;

    $x = ref($x) eq __PACKAGE__ ? $$x : _star2obj($x);

    if (!defined($y)) {
        return bless \__round__($x, 0);
    }

    $y = _star2si($y) // goto &nan;

    bless \__round__($x, $y);
}

#
## RAND / IRAND
#

sub __irand__ {
    my ($x, $y, $state) = @_;

    if (defined($y)) {
        my $cmp = Math::GMPz::Rmpz_cmp($y, $x);

        if ($cmp == 0) {
            return $x;
        }
        elsif ($cmp < 0) {
            ($x, $y) = ($y, $x);
        }

        my $r = Math::GMPz::Rmpz_init();
        Math::GMPz::Rmpz_sub($r, $y, $x);
        Math::GMPz::Rmpz_add_ui($r, $r, 1);
        Math::GMPz::Rmpz_urandomm($r, $state, $r, 1);
        Math::GMPz::Rmpz_add($r, $r, $x);
        return $r;
    }

    my $sgn = Math::GMPz::Rmpz_sgn($x) || return $x;

    my $r = Math::GMPz::Rmpz_init_set($x);

    if ($sgn < 0) {
        Math::GMPz::Rmpz_sub_ui($r, $r, 1);
    }
    else {
        Math::GMPz::Rmpz_add_ui($r, $r, 1);
    }

    Math::GMPz::Rmpz_urandomm($r, $state, $r, 1);
    Math::GMPz::Rmpz_neg($r, $r) if $sgn < 0;
    return $r;
}

{
    my $srand = srand();

    {
        state $state = Math::MPFR::Rmpfr_randinit_mt_nobless();
        Math::MPFR::Rmpfr_randseed_ui($state, $srand);

        sub rand (;$;$) {
            my ($x, $y) = @_;

            if (@_ == 0) {
                $x = one();
            }

            $x = ref($x) eq __PACKAGE__ ? $$x : _star2obj($x);

            if (!defined($y)) {
                my $rand = Math::MPFR::Rmpfr_init2($PREC);
                Math::MPFR::Rmpfr_urandom($rand, $state, $ROUND);
                return bless \__mul__($rand, $x);
            }

            $y = ref($y) eq __PACKAGE__ ? $$y : _star2obj($y);

            my $rand = Math::MPFR::Rmpfr_init2($PREC);
            Math::MPFR::Rmpfr_urandom($rand, $state, $ROUND);
            $rand = __mul__($rand, __sub__($y, $x));
            bless \__add__($rand, $x);
        }

        sub seed ($) {
            my ($x) = @_;

            $x = $$x if (ref($x) eq __PACKAGE__);

            if (ref($x) ne 'Math::GMPz') {
                $x = _star2mpz($x) // do {
                    require Carp;
                    Carp::croak("seed(): invalid seed value <<$_[0]>> (expected an integer)");
                };
            }
            Math::MPFR::Rmpfr_randseed($state, $x);
            bless \$x;
        }
    }

    {
        state $state = Math::GMPz::zgmp_randinit_mt_nobless();
        Math::GMPz::zgmp_randseed_ui($state, $srand);

        sub irand ($;$) {
            my ($x, $y) = @_;

            $x = _star2mpz($x) // goto &nan;

            if (!defined($y)) {
                return bless \__irand__($x, undef, $state);
            }

            $y = _star2mpz($y) // goto &nan;

            bless \__irand__($x, $y, $state);
        }

        sub iseed ($) {
            my ($x) = @_;

            $x = _star2mpz($x) // do {
                require Carp;
                Carp::croak("iseed(): invalid seed value <<$_[0]>> (expected an integer)");
            };

            Math::GMPz::zgmp_randseed($state, $x);
            bless \$x;
        }
    }
}

#
## n-th Fibonacci number of k-th order
#

sub fibonacci ($;$) {
    my ($n, $k) = @_;

    $n = _star2ui($n) // goto &nan;

    # N-th Fibonacci number of k-th order
    if (defined($k)) {

        $k = _star2ui($k) // goto &nan;

        if ($k == 2) {
            my $z = Math::GMPz::Rmpz_init();
            Math::GMPz::Rmpz_fib_ui($z, $n);
            return bless \$z;
        }

        if ($n < $k - 1) {
            return zero();
        }

        # Algorithm after M. F. Hasler
        # See: https://oeis.org/A302990

        my @f = map {
            $_ < $k
              ? do {
                my $z = Math::GMPz::Rmpz_init();
                Math::GMPz::Rmpz_setbit($z, $_);
                $z;
              }
              : Math::GMPz::Rmpz_init_set_ui(1)
        } 1 .. ($k + 1);

        my $t = Math::GMPz::Rmpz_init();

        foreach my $i (2 * ++$k - 2 .. $n) {
            Math::GMPz::Rmpz_mul_2exp($t, $f[($i - 1) % $k], 1);
            Math::GMPz::Rmpz_sub($f[$i % $k], $t, $f[$i % $k]);
        }

        my $r = $f[$n % $k];
        return bless \$r;
    }

    my $r = Math::GMPz::Rmpz_init();
    Math::GMPz::Rmpz_fib_ui($r, $n);
    bless \$r;
}

#
## n-th Lucas number
#

sub lucas ($) {
    my ($n) = @_;

    $n = _star2ui($n) // goto &nan;

    my $r = Math::GMPz::Rmpz_init();
    Math::GMPz::Rmpz_lucnum_ui($r, $n);
    bless \$r;
}

sub __lucasV__ {
    my ($P, $Q, $n) = @_;

    my ($V1, $V2) = (Math::GMPz::Rmpz_init_set_ui(2), Math::GMPz::Rmpz_init_set($P));
    my ($Q1, $Q2) = (Math::GMPz::Rmpz_init_set_ui(1), Math::GMPz::Rmpz_init_set_ui(1));

    foreach my $bit (split(//, Math::GMPz::Rmpz_get_str($n, 2))) {

        Math::GMPz::Rmpz_mul($Q1, $Q1, $Q2);

        if ($bit) {
            Math::GMPz::Rmpz_mul($Q2, $Q1, $Q);
            Math::GMPz::Rmpz_mul($V1, $V1, $V2);
            Math::GMPz::Rmpz_mul($V2, $V2, $V2);
            Math::GMPz::Rmpz_submul($V1, $P, $Q1);
            Math::GMPz::Rmpz_submul_ui($V2, $Q2, 2);
        }
        else {
            Math::GMPz::Rmpz_set($Q2, $Q1);
            Math::GMPz::Rmpz_mul($V2, $V2, $V1);
            Math::GMPz::Rmpz_mul($V1, $V1, $V1);
            Math::GMPz::Rmpz_submul($V2, $P, $Q1);
            Math::GMPz::Rmpz_submul_ui($V1, $Q2, 2);
        }
    }

    return ($V1, $V2);
}

sub __lucasVmod__ {
    my ($P, $Q, $n, $m) = @_;

    my ($V1, $V2) = (Math::GMPz::Rmpz_init_set_ui(2), Math::GMPz::Rmpz_init_set($P));
    my ($Q1, $Q2) = (Math::GMPz::Rmpz_init_set_ui(1), Math::GMPz::Rmpz_init_set_ui(1));

    foreach my $bit (split(//, Math::GMPz::Rmpz_get_str($n, 2))) {

        Math::GMPz::Rmpz_mul($Q1, $Q1, $Q2);
        Math::GMPz::Rmpz_mod($Q1, $Q1, $m);

        if ($bit) {
            Math::GMPz::Rmpz_mul($Q2, $Q1, $Q);
            Math::GMPz::Rmpz_mul($V1, $V1, $V2);
            Math::GMPz::Rmpz_powm_ui($V2, $V2, 2, $m);
            Math::GMPz::Rmpz_submul($V1, $P, $Q1);
            Math::GMPz::Rmpz_submul_ui($V2, $Q2, 2);
            Math::GMPz::Rmpz_mod($V1, $V1, $m);
        }
        else {
            Math::GMPz::Rmpz_set($Q2, $Q1);
            Math::GMPz::Rmpz_mul($V2, $V2, $V1);
            Math::GMPz::Rmpz_powm_ui($V1, $V1, 2, $m);
            Math::GMPz::Rmpz_submul($V2, $P, $Q1);
            Math::GMPz::Rmpz_submul_ui($V1, $Q2, 2);
            Math::GMPz::Rmpz_mod($V2, $V2, $m);
        }
    }

    Math::GMPz::Rmpz_mod($V1, $V1, $m);

    return ($V1, $V2);
}

sub __lucasUV__ {
    my ($P, $Q, $n) = @_;

    my $U1 = Math::GMPz::Rmpz_init_set_ui(1);

    my ($V1, $V2) = (Math::GMPz::Rmpz_init_set_ui(2), Math::GMPz::Rmpz_init_set($P));
    my ($Q1, $Q2) = (Math::GMPz::Rmpz_init_set_ui(1), Math::GMPz::Rmpz_init_set_ui(1));

    my $t = Math::GMPz::Rmpz_init();
    my $s = Math::GMPz::Rmpz_scan1($n, 0);

    Math::GMPz::Rmpz_div_2exp($t, $n, $s + 1);

    foreach my $bit (split(//, Math::GMPz::Rmpz_get_str($t, 2))) {

        Math::GMPz::Rmpz_mul($Q1, $Q1, $Q2);

        if ($bit) {
            Math::GMPz::Rmpz_mul($Q2, $Q1, $Q);
            Math::GMPz::Rmpz_mul($U1, $U1, $V2);
            Math::GMPz::Rmpz_mul($V1, $V1, $V2);

            Math::GMPz::Rmpz_mul($V2, $V2, $V2);
            Math::GMPz::Rmpz_submul($V1, $Q1, $P);
            Math::GMPz::Rmpz_submul_ui($V2, $Q2, 2);
        }
        else {
            Math::GMPz::Rmpz_set($Q2, $Q1);
            Math::GMPz::Rmpz_mul($U1, $U1, $V1);
            Math::GMPz::Rmpz_mul($V2, $V2, $V1);
            Math::GMPz::Rmpz_sub($U1, $U1, $Q1);
            Math::GMPz::Rmpz_mul($V1, $V1, $V1);
            Math::GMPz::Rmpz_submul($V2, $Q1, $P);
            Math::GMPz::Rmpz_submul_ui($V1, $Q2, 2);
        }
    }

    Math::GMPz::Rmpz_mul($Q1, $Q1, $Q2);
    Math::GMPz::Rmpz_mul($Q2, $Q1, $Q);
    Math::GMPz::Rmpz_mul($U1, $U1, $V1);
    Math::GMPz::Rmpz_mul($V1, $V1, $V2);
    Math::GMPz::Rmpz_sub($U1, $U1, $Q1);
    Math::GMPz::Rmpz_submul($V1, $Q1, $P);
    Math::GMPz::Rmpz_mul($Q1, $Q1, $Q2);

    for (1 .. $s) {
        Math::GMPz::Rmpz_mul($U1, $U1, $V1);
        Math::GMPz::Rmpz_mul($V1, $V1, $V1);
        Math::GMPz::Rmpz_submul_ui($V1, $Q1, 2);
        Math::GMPz::Rmpz_mul($Q1, $Q1, $Q1);
    }

    return ($U1, $V1);
}

sub __lucasUVmod__ {
    my ($P, $Q, $n, $m) = @_;

    my $U1 = Math::GMPz::Rmpz_init_set_ui(1);

    my ($V1, $V2) = (Math::GMPz::Rmpz_init_set_ui(2), Math::GMPz::Rmpz_init_set($P));
    my ($Q1, $Q2) = (Math::GMPz::Rmpz_init_set_ui(1), Math::GMPz::Rmpz_init_set_ui(1));

    my $t = Math::GMPz::Rmpz_init();
    my $s = Math::GMPz::Rmpz_scan1($n, 0);

    Math::GMPz::Rmpz_div_2exp($t, $n, $s + 1);

    foreach my $bit (split(//, Math::GMPz::Rmpz_get_str($t, 2))) {

        Math::GMPz::Rmpz_mul($Q1, $Q1, $Q2);
        Math::GMPz::Rmpz_mod($Q1, $Q1, $m);

        if ($bit) {
            Math::GMPz::Rmpz_mul($Q2, $Q1, $Q);
            Math::GMPz::Rmpz_mul($U1, $U1, $V2);
            Math::GMPz::Rmpz_mul($V1, $V1, $V2);

            Math::GMPz::Rmpz_powm_ui($V2, $V2, 2, $m);
            Math::GMPz::Rmpz_submul($V1, $Q1, $P);
            Math::GMPz::Rmpz_submul_ui($V2, $Q2, 2);

            Math::GMPz::Rmpz_mod($V1, $V1, $m);
            Math::GMPz::Rmpz_mod($U1, $U1, $m);
        }
        else {
            Math::GMPz::Rmpz_set($Q2, $Q1);
            Math::GMPz::Rmpz_mul($U1, $U1, $V1);
            Math::GMPz::Rmpz_mul($V2, $V2, $V1);
            Math::GMPz::Rmpz_sub($U1, $U1, $Q1);

            Math::GMPz::Rmpz_powm_ui($V1, $V1, 2, $m);
            Math::GMPz::Rmpz_submul($V2, $Q1, $P);
            Math::GMPz::Rmpz_submul_ui($V1, $Q2, 2);

            Math::GMPz::Rmpz_mod($V2, $V2, $m);
            Math::GMPz::Rmpz_mod($U1, $U1, $m);
        }
    }

    Math::GMPz::Rmpz_mul($Q1, $Q1, $Q2);
    Math::GMPz::Rmpz_mul($Q2, $Q1, $Q);
    Math::GMPz::Rmpz_mul($U1, $U1, $V1);
    Math::GMPz::Rmpz_mul($V1, $V1, $V2);
    Math::GMPz::Rmpz_sub($U1, $U1, $Q1);
    Math::GMPz::Rmpz_submul($V1, $Q1, $P);
    Math::GMPz::Rmpz_mul($Q1, $Q1, $Q2);

    for (1 .. $s) {
        Math::GMPz::Rmpz_mul($U1, $U1, $V1);
        Math::GMPz::Rmpz_mod($U1, $U1, $m);
        Math::GMPz::Rmpz_powm_ui($V1, $V1, 2, $m);
        Math::GMPz::Rmpz_submul_ui($V1, $Q1, 2);
        Math::GMPz::Rmpz_powm_ui($Q1, $Q1, 2, $m);
    }

    Math::GMPz::Rmpz_mod($U1, $U1, $m);
    Math::GMPz::Rmpz_mod($V1, $V1, $m);

    return ($U1, $V1);
}

sub lucasU ($$$) {
    my ($P, $Q, $n) = @_;

    $P = _star2mpz($P) // goto &nan;
    $Q = _star2mpz($Q) // goto &nan;
    $n = _star2mpz($n) // goto &nan;

    # U_0(P, Q) = 0
    Math::GMPz::Rmpz_sgn($n) || goto &zero;

    # undefined for n < 0
    Math::GMPz::Rmpz_sgn($n) < 0 && goto &nan;

    my $D = Math::GMPz::Rmpz_init();

    Math::GMPz::Rmpz_mul($D, $P, $P);
    Math::GMPz::Rmpz_submul_ui($D, $Q, 4);

    # When `P*P - 4*Q != 0`, we can use a faster algorithm
    if (Math::GMPz::Rmpz_sgn($D)) {

        my ($V1, $V2) = __lucasV__($P, $Q, $n);

        Math::GMPz::Rmpz_mul_2exp($V2, $V2, 1);
        Math::GMPz::Rmpz_submul($V2, $V1, $P);
        Math::GMPz::Rmpz_divexact($V2, $V2, $D);

        return bless \$V2;
    }

    my ($U) = __lucasUV__($P, $Q, $n);

    bless \$U;
}

sub lucasUmod ($$$$) {
    my ($P, $Q, $n, $m) = @_;

    $P = _star2mpz($P) // goto &nan;
    $Q = _star2mpz($Q) // goto &nan;
    $n = _star2mpz($n) // goto &nan;
    $m = _star2mpz($m) // goto &nan;

    # undefined for m=0
    Math::GMPz::Rmpz_sgn($m) || goto &nan;

    # U_0(P, Q) = 0
    Math::GMPz::Rmpz_sgn($n) || goto &zero;

    # undefined for n < 0
    Math::GMPz::Rmpz_sgn($n) < 0 && goto &nan;

    my $D = Math::GMPz::Rmpz_init();

    Math::GMPz::Rmpz_mul($D, $P, $P);
    Math::GMPz::Rmpz_submul_ui($D, $Q, 4);

    # When `gcd(P*P - 4*Q, m) = 1`, we can use a faster algorithm
    if (Math::GMPz::Rmpz_invert($D, $D, $m)) {

        my ($V1, $V2) = __lucasVmod__($P, $Q, $n, $m);

        Math::GMPz::Rmpz_mul_2exp($V2, $V2, 1);
        Math::GMPz::Rmpz_submul($V2, $V1, $P);
        Math::GMPz::Rmpz_mul($V2, $V2, $D);
        Math::GMPz::Rmpz_mod($V2, $V2, $m);

        return bless \$V2;
    }

    my ($U) = __lucasUVmod__($P, $Q, $n, $m);

    bless \$U;
}

sub lucasV ($$$) {
    my ($P, $Q, $n) = @_;

    $P = _star2mpz($P) // goto &nan;
    $Q = _star2mpz($Q) // goto &nan;
    $n = _star2mpz($n) // goto &nan;

    # undefined for n < 0
    Math::GMPz::Rmpz_sgn($n) < 0 && goto &nan;

    my ($V) = __lucasV__($P, $Q, $n);

    bless \$V;
}

sub lucasVmod ($$$$) {
    my ($P, $Q, $n, $m) = @_;

    $P = _star2mpz($P) // goto &nan;
    $Q = _star2mpz($Q) // goto &nan;
    $n = _star2mpz($n) // goto &nan;
    $m = _star2mpz($m) // goto &nan;

    # undefined for m=0
    Math::GMPz::Rmpz_sgn($m) || goto &nan;

    # undefined for n < 0
    Math::GMPz::Rmpz_sgn($n) < 0 && goto &nan;

    my ($V) = __lucasVmod__($P, $Q, $n, $m);

    bless \$V;
}

#
## fibonacci(n) mod m
#

sub fibmod ($$) {
    my ($n, $m) = @_;

    $n = _star2mpz($n) // goto &nan;
    $m = _star2mpz($m) // goto &nan;

    Math::GMPz::Rmpz_sgn($m) == 0 and goto &nan;

    my $sgn = Math::GMPz::Rmpz_sgn($n);

    $sgn < 0  and goto &nan;
    $sgn == 0 and goto &zero;

#<<<
    my ($f, $g, $w) = (
        Math::GMPz::Rmpz_init_set_ui(0),
        Math::GMPz::Rmpz_init_set_ui(1),
    );
#>>>

    my $t = Math::GMPz::Rmpz_init();

    foreach my $bit (split(//, substr(Math::GMPz::Rmpz_get_str($n, 2), 1))) {

        Math::GMPz::Rmpz_powm_ui($g, $g, 2, $m);
        Math::GMPz::Rmpz_powm_ui($f, $f, 2, $m);

        Math::GMPz::Rmpz_mul_2exp($t, $g, 2);
        Math::GMPz::Rmpz_sub($t, $t, $f);

        $w
          ? Math::GMPz::Rmpz_add_ui($t, $t, 2)
          : Math::GMPz::Rmpz_sub_ui($t, $t, 2);

        Math::GMPz::Rmpz_add($f, $f, $g);

        if ($bit) {
            Math::GMPz::Rmpz_sub($f, $t, $f);
            Math::GMPz::Rmpz_set($g, $t);
            $w = 0;
        }
        else {
            Math::GMPz::Rmpz_sub($g, $t, $f);
            $w = 1;
        }
    }

    Math::GMPz::Rmpz_mod($g, $g, $m);

    return bless \$g;
}

#
## lucas(n) mod m
#

sub lucasmod ($$) {
    my ($n, $m) = @_;

    $n = _star2mpz($n) // goto &nan;
    $m = _star2mpz($m) // goto &nan;

    Math::GMPz::Rmpz_sgn($m) == 0 and goto &nan;

    my $sgn = Math::GMPz::Rmpz_sgn($n);

    $sgn < 0  and goto &nan;
    $sgn == 0 and return bless \Math::GMPz::Rmpz_init_set_ui(2);

#<<<
    my ($f, $g, $w) = (
        Math::GMPz::Rmpz_init_set_ui(3),
        Math::GMPz::Rmpz_init_set_ui(1),
    );
#>>>

    foreach my $bit (split(//, substr(Math::GMPz::Rmpz_get_str($n, 2), 1))) {

        Math::GMPz::Rmpz_powm_ui($g, $g, 2, $m);
        Math::GMPz::Rmpz_powm_ui($f, $f, 2, $m);

        if ($w) {
            Math::GMPz::Rmpz_sub_ui($g, $g, 2);
            Math::GMPz::Rmpz_add_ui($f, $f, 2);
        }
        else {
            Math::GMPz::Rmpz_add_ui($g, $g, 2);
            Math::GMPz::Rmpz_sub_ui($f, $f, 2);
        }

        if ($bit) {
            Math::GMPz::Rmpz_sub($g, $f, $g);
            $w = 0;
        }
        else {
            Math::GMPz::Rmpz_sub($f, $f, $g);
            $w = 1;
        }
    }

    Math::GMPz::Rmpz_mod($g, $g, $m);

    bless \$g;
}

#
## Chebyshev polynomials: T_n(x)
#

sub _quadratic_mul {
    my ($xa, $xb, $ya, $yb, $w) = @_;
    (__add__(__mul__($xa, $ya), __mul__(__mul__($xb, $yb), $w)), __add__(__mul__($xa, $yb), __mul__($xb, $ya)));
}

sub _quadratic_invmod {
    my ($xa, $xb, $w, $m) = @_;

    $xa = __mod__($xa, $m);
    $xb = __mod__($xb, $m);

    my $t = invmod(__sub__(__mul__($xa, $xa), __mul__(__mul__($xb, $xb), $w)), $m);
    (__mod__(__mul__($xa, $$t), $m), __mod__(__neg__(__mul__($xb, $$t)), $m));
}

sub _quadratic_pow {
    my ($x, $y, $w, $n) = @_;

    my ($c1, $c2) = (Math::GMPz::Rmpz_init_set_ui(1), Math::GMPz::Rmpz_init_set_ui(0));

    for (; $n > 0 ; $n >>= 1) {

        if ($n & 1) {
            ($c1, $c2) = _quadratic_mul($c1, $c2, $x, $y, $w);
        }

        ($x, $y) = _quadratic_mul($x, $y, $x, $y, $w);
    }

    ($c1, $c2);
}

sub _mpz_quadratic_powmod {
    my ($x, $y, $a, $b, $w, $n, $m) = @_;

    state $t = Math::GMPz::Rmpz_init_nobless();

    for my $i (0 .. Math::GMPz::Rmpz_sizeinbase($n, 2) - 1) {

        if (Math::GMPz::Rmpz_tstbit($n, $i)) {

            # (x, y) = ((a*x + b*y*w) % m, (a*y + b*x) % m)
            Math::GMPz::Rmpz_mul($t, $b, $w);
            Math::GMPz::Rmpz_mul($t, $t, $y);
            Math::GMPz::Rmpz_addmul($t, $a, $x);
            Math::GMPz::Rmpz_mul($y, $y, $a);
            Math::GMPz::Rmpz_addmul($y, $x, $b);
            Math::GMPz::Rmpz_mod($x, $t, $m);
            Math::GMPz::Rmpz_mod($y, $y, $m);
        }

        # (a, b) = ((a*a + b*b*w) % m, (2*a*b) % m)
        Math::GMPz::Rmpz_mul($t, $a, $b);
        Math::GMPz::Rmpz_mul_2exp($t, $t, 1);
        Math::GMPz::Rmpz_powm_ui($a, $a, 2, $m);
        Math::GMPz::Rmpz_powm_ui($b, $b, 2, $m);
        Math::GMPz::Rmpz_addmul($a, $b, $w);
        Math::GMPz::Rmpz_mod($b, $t, $m);
    }
}

sub _quadratic_powmod {
    my ($x, $y, $w, $n, $m) = @_;

    my $negative_power = 0;

    if (Math::GMPz::Rmpz_sgn($n) < 0) {
        $n = Math::GMPz::Rmpz_init_set($n);    # copy
        Math::GMPz::Rmpz_abs($n, $n);
        $negative_power = 1;
    }

    my ($c1, $c2) = (Math::GMPz::Rmpz_init_set_ui(1), Math::GMPz::Rmpz_init_set_ui(0));

    if (ref($x) eq 'Math::GMPz' and ref($y) eq 'Math::GMPz' and ref($w) eq 'Math::GMPz' and ref($m) eq 'Math::GMPz') {
        _mpz_quadratic_powmod($c1, $c2, $x, $y, $w, $n, $m);
    }
    else {
        for my $i (0 .. Math::GMPz::Rmpz_sizeinbase($n, 2) - 1) {

            if (Math::GMPz::Rmpz_tstbit($n, $i)) {
                ($c1, $c2) = map { __mod__($_, $m) } _quadratic_mul($c1, $c2, $x, $y, $w);
            }

            ($x, $y) = map { __mod__($_, $m) } _quadratic_mul($x, $y, $x, $y, $w);
        }
    }

    if ($negative_power) {
        ($c1, $c2) = _quadratic_invmod($c1, $c2, $w, $m);
    }

    ($c1, $c2);
}

sub quadratic_powmod ($$$$$) {
    my ($x, $y, $w, $n, $m) = @_;

    $x = _star2obj($x);
    $y = _star2obj($y);
    $w = _star2obj($w);
    $n = _star2mpz($n) // return (nan(), nan());
    $m = _star2obj($m);

    my ($r1, $r2) = _quadratic_powmod($x, $y, $w, $n, $m);

    ((bless \$r1), (bless \$r2));
}

sub chebyshevT ($$) {
    my ($n, $x) = @_;

    $n = _star2si($n) // goto &nan;
    $x = _star2obj($x);

    $n = -$n if $n < 0;
    $n == 0 and goto &one;
    $n == 1 and return bless \$x;

    if (ref($x) eq 'Math::GMPz' or (ref($x) eq 'Math::GMPq' and __is_int__($x))) {
        return lucasV(2 * $x, 1, $n)->idiv(2);
    }

    # T_n(x) = 1/2 * ((x - sqrt(x^2 - 1))^n + (x + sqrt(x^2 - 1))^n)

    my ($r1, $r2) = _quadratic_pow($x, Math::GMPz::Rmpz_init_set_si(-1), __dec__(__mul__($x, $x)), $n);
    bless \$r1;
}

#
## Modular Chebyshev polynomials: T_n(x) mod m
#

sub chebyshevTmod ($$$) {
    my ($n, $x, $m) = @_;

    $n = _star2mpz($n) // goto &nan;
    $x = _star2obj($x);
    $m = _star2mpz($m) // goto &nan;

    if (Math::GMPz::Rmpz_sgn($n) < 0) {
        $n = Math::GMPz::Rmpz_init_set($n);    # copy
        Math::GMPz::Rmpz_abs($n, $n);
    }

    if (Math::GMPz::Rmpz_odd_p($m) and (ref($x) eq 'Math::GMPz' or (ref($x) eq 'Math::GMPq' and __is_int__($x)))) {
        return lucasVmod(2 * $x, 1, $n, $m)->divmod(2, $m);
    }

    # T_n(x) = 1/2 * ((x - sqrt(x^2 - 1))^n + (x + sqrt(x^2 - 1))^n)

    my ($r1, $r2) = _quadratic_powmod($x, Math::GMPz::Rmpz_init_set_si(-1), __dec__(__mul__($x, $x)), $n, $m);
    my $r = bless \$r1;
    $r = $r->mod($m);
    $r;
}

#
## Chebyshev polynomials: U_n(x)
#

sub chebyshevU ($$) {
    my ($n, $x) = @_;

    $n = _star2si($n) // goto &nan;
    $n == 0 and goto &one;

    my $negative = 0;

    if ($n < 0) {

        $n == -1 and goto &zero;
        $n == -2 and goto &mone;

        $n        = -$n - 2;
        $negative = 1;
    }

    $x = _star2obj($x);

    if (ref($x) eq 'Math::GMPz' or (ref($x) eq 'Math::GMPz' and __is_int__($x))) {
        my $r = lucasU(2 * $x, 1, $n + 1);
        $r = $r->neg if $negative;
        return $r;
    }

    # U_n(x) = ((x + sqrt(x^2 - 1))^(n+1) - (x - sqrt(x^2 - 1))^(n+1)) / (2 * sqrt(x^2 - 1))

    my ($r1, $r2) = _quadratic_pow($x, Math::GMPz::Rmpz_init_set_ui(1), __dec__(__mul__($x, $x)), $n + 1);

    my $r = bless \$r2;
    $r = $r->neg if $negative;
    $r;
}

#
## Modular Chebyshev polynomials: U_n(x) mod m
#

sub chebyshevUmod {
    my ($n, $x, $m) = @_;

    $n = _star2mpz($n) // goto &nan;
    $x = _star2obj($x);
    $m = _star2mpz($m) // goto &nan;

    my $negative = 0;

    if (Math::GMPz::Rmpz_sgn($n) < 0) {

        if (Math::GMPz::Rmpz_cmp_si($n, -1) == 0) {
            return (zero()->mod(bless \$m));
        }

        if (Math::GMPz::Rmpz_cmp_si($n, -2) == 0) {
            return (mone()->mod(bless \$m));
        }

        $n        = -$n - 2;
        $negative = 1;
    }

    if (ref($x) eq 'Math::GMPz' or (ref($x) eq 'Math::GMPq' and __is_int__($x))) {
        my $r = lucasUmod(2 * $x, 1, $n + 1, $m);
        $r = $r->neg->mod($m) if $negative;
        return $r;
    }

    # U_n(x) = ((x + sqrt(x^2 - 1))^(n+1) - (x - sqrt(x^2 - 1))^(n+1)) / (2 * sqrt(x^2 - 1))

    my ($r1, $r2) = _quadratic_pow($x, Math::GMPz::Rmpz_init_set_ui(1), __dec__(__mul__($x, $x)), $n + 1, $m);

    my $r = bless \$r2;
    $r = $r->neg if $negative;
    $r = $r->mod($m);
    $r;
}

#
## Laguerre polynomials: L_n(x)
#

sub laguerreL ($$) {
    my ($n, $x) = @_;

    $n = _star2ui($n) // goto &nan;
    $x = _star2obj($x);

    $n == 0 and goto &one;                       # L_0(x) = 1
    $n == 1 and return bless \__sub__(1, $x);    # L_1(x) = 1-x

    my $t = Math::GMPz::Rmpz_init();
    my $u = Math::GMPz::Rmpz_init_set_ui(1);

    my @terms;
    foreach my $k (0 .. $n) {
        Math::GMPz::Rmpz_bin_uiui($t, $n, $k);
        Math::GMPz::Rmpz_neg($t, $t) if ($k & 1);
        push @terms, __div__(__mul__(__pow__($x, $k), $t), $u);
        Math::GMPz::Rmpz_mul_ui($u, $u, $k + 1);
    }

    bless \_binsplit(\@terms, \&__add__);
}

#
## Legendre polynomials: P_n(x)
#

sub legendreP ($$) {
    my ($n, $x) = @_;

    $n = _star2ui($n) // goto &nan;
    $x = _star2obj($x);

    $n == 0 and goto &one;
    $n == 1 and return bless \$x;

    my $x1 = __dec__($x);
    my $x2 = __inc__($x);

    my $t = Math::GMPz::Rmpz_init();

    my @terms;
    foreach my $k (0 .. $n) {
        Math::GMPz::Rmpz_bin_uiui($t, $n, $k);
        Math::GMPz::Rmpz_mul($t, $t, $t);
        push @terms, __mul__(__mul__(__pow__($x1, $n - $k), __pow__($x2, $k)), $t);
    }

    my $sum = _binsplit(\@terms, \&__add__);

    Math::GMPz::Rmpz_set_ui($t, 0);
    Math::GMPz::Rmpz_setbit($t, $n);

    bless \__div__($sum, $t);
}

#
## The physicists' Hermite polynomials H_n(x)
#

sub hermiteH ($$) {
    my ($n, $x) = @_;

    $n = _star2ui($n) // goto &nan;
    $x = _star2obj($x);

    $x = __add__($x, $x);

    $n == 0 and goto &one;
    $n == 1 and return bless \$x;

    my $t = Math::GMPz::Rmpz_init();
    my $u = Math::GMPz::Rmpz_init_set_ui(1);

    my $v = Math::GMPz::Rmpz_init();
    Math::GMPz::Rmpz_fac_ui($v, $n);

    my @terms;
    foreach my $m (0 .. $n >> 1) {
        Math::GMPz::Rmpz_mul($t, $v, $u);
        Math::GMPz::Rmpz_neg($t, $t) if ($m & 1);

        push @terms, __div__(__pow__($x, $n - ($m << 1)), $t);

        my $d = ($n - ($m << 1)) * ($n - ($m << 1) - 1);
        Math::GMPz::Rmpz_divexact_ui($v, $v, $d) if $d;
        Math::GMPz::Rmpz_mul_ui($u, $u, $m + 1);
    }

    my $sum = _binsplit(\@terms, \&__add__);
    Math::GMPz::Rmpz_fac_ui($v, $n);
    bless \__mul__($sum, $v);
}

#
## The probabilists' Hermite polynomials He_n(x)
#

sub hermiteHe ($$) {
    my ($n, $x) = @_;

    $n = _star2ui($n) // goto &nan;
    $x = _star2obj($x);

    $n == 0 and goto &one;
    $n == 1 and return bless \$x;

    my $t = Math::GMPz::Rmpz_init();
    my $u = Math::GMPz::Rmpz_init_set_ui(1);

    my $v = Math::GMPz::Rmpz_init();
    Math::GMPz::Rmpz_fac_ui($v, $n);

    my @terms;
    foreach my $m (0 .. $n >> 1) {
        Math::GMPz::Rmpz_mul($t, $v, $u);
        Math::GMPz::Rmpz_mul_2exp($t, $t, $m);
        Math::GMPz::Rmpz_neg($t, $t) if ($m & 1);

        push @terms, __div__(__pow__($x, $n - ($m << 1)), $t);

        my $d = ($n - ($m << 1)) * ($n - ($m << 1) - 1);
        Math::GMPz::Rmpz_divexact_ui($v, $v, $d) if $d;
        Math::GMPz::Rmpz_mul_ui($u, $u, $m + 1);
    }

    my $sum = _binsplit(\@terms, \&__add__);
    Math::GMPz::Rmpz_fac_ui($v, $n);
    bless \__mul__($sum, $v);
}

#
## Primorial
#
sub primorial ($) {
    my ($n) = @_;

    $n = _star2ui($n) // goto &nan;

    my $r = Math::GMPz::Rmpz_init();
    Math::GMPz::Rmpz_primorial_ui($r, $n);
    bless \$r;
}

sub min {
    my @terms = map { ref($_) eq __PACKAGE__ ? $$_ : _star2obj($_) } @_;

    @terms || return undef;

    my $min = shift(@terms);
    foreach my $curr (@terms) {
        if ((__cmp__($curr, $min) // return undef) < 0) {
            $min = $curr;
        }
    }

    bless \$min;
}

sub max {
    my @terms = map { ref($_) eq __PACKAGE__ ? $$_ : _star2obj($_) } @_;

    @terms || return undef;

    my $max = shift(@terms);
    foreach my $curr (@terms) {
        if ((__cmp__($curr, $max) // return undef) > 0) {
            $max = $curr;
        }
    }

    bless \$max;
}

sub sum {
    my @terms = map { ref($_) eq __PACKAGE__ ? $$_ : _star2obj($_) } @_;

    @terms || goto &zero;

    my @non_mpz;
    my $sum = Math::GMPz::Rmpz_init_set_ui(0);

    foreach my $n (@terms) {
        if (ref($n) eq 'Math::GMPz') {
            Math::GMPz::Rmpz_add($sum, $sum, $n);
        }
        else {
            push @non_mpz, $n;
        }
    }

    if (@non_mpz) {
        $sum = __add__($sum, _binsplit(\@non_mpz, \&__add__));
    }

    bless \$sum;
}

sub prod {
    my @terms = map { ref($_) eq __PACKAGE__ ? $$_ : _star2obj($_) } @_;
    @terms || goto &one;
    bless \_binsplit(\@terms, \&__mul__);
}

sub _secant_numbers {
    my ($n) = @_;

    state @cache;

    if ($n <= $#cache) {
        return @cache;
    }

    $n <<= 1 if ($n <= 512);

    my @S = (Math::GMPz::Rmpz_init_set_ui(1));

    foreach my $k (1 .. $n) {
        Math::GMPz::Rmpz_mul_ui($S[$k] = Math::GMPz::Rmpz_init(), $S[$k - 1], $k);
    }

    foreach my $k (1 .. $n) {
        foreach my $j ($k + 1 .. $n) {
            Math::GMPz::Rmpz_addmul_ui($S[$j], $S[$j - 1], ($j - $k) * ($j - $k + 2));
        }
    }

    push @cache, @S[@cache .. (@S <= 1024 ? $#S : 1024)];

    return @S;
}

sub _tangent_numbers {
    my ($n) = @_;

    state @cache;

    if ($n <= $#cache) {
        return @cache;
    }

    $n <<= 1 if ($n <= 512);

    my @T = (Math::GMPz::Rmpz_init_set_ui(1));

    foreach my $k (1 .. $n) {
        Math::GMPz::Rmpz_mul_ui($T[$k] = Math::GMPz::Rmpz_init(), $T[$k - 1], $k);
    }

    foreach my $k (1 .. $n) {
        foreach my $j ($k .. $n) {
            Math::GMPz::Rmpz_mul_ui($T[$j], $T[$j], $j - $k + 2);
            Math::GMPz::Rmpz_addmul_ui($T[$j], $T[$j - 1], $j - $k);
        }
    }

    push @cache, @T[@cache .. (@T <= 1024 ? $#T : 1024)];

    return @T;
}

sub _bernoulli_numbers {
    my ($n) = @_;

    $n = ($n >> 1) + 1;

    state @cache;

    if ($n <= $#cache) {
        return @cache;
    }

    my @B;
    my @T = _tangent_numbers($n);

    my $t = Math::GMPz::Rmpz_init();

    foreach my $k (scalar(@cache) .. 2 * @T) {

        $k % 2 == 0 or $k == 1 or next;

        my $q = Math::GMPq::Rmpq_init();

        if ($k == 0) {
            Math::GMPq::Rmpq_set_ui($q, 1, 1);
            $B[$k] = $q;
            next;
        }

        if ($k == 1) {
            Math::GMPq::Rmpq_set_si($q, -1, 2);
            $B[$k] = $q;
            next;
        }

        # T_k
        Math::GMPz::Rmpz_mul_ui($t, $T[($k >> 1) - 1], $k);
        Math::GMPz::Rmpz_neg($t, $t) if ((($k >> 1) - 1) & 1);
        Math::GMPq::Rmpq_set_z($q, $t);

        # (2^k - 1) * 2^k
        Math::GMPz::Rmpz_set_ui($t, 0);
        Math::GMPz::Rmpz_setbit($t, $k);
        Math::GMPz::Rmpz_sub_ui($t, $t, 1);
        Math::GMPz::Rmpz_mul_2exp($t, $t, $k);

        # B_k = q
        Math::GMPq::Rmpq_div_z($q, $q, $t);

        $B[($k >> 1) + 1] = $q;
    }

    push @cache, @B[@cache .. (@B <= 1024 ? $#B : 1024)];

    return (@cache, (@B > @cache ? @B[@cache .. $#B] : ()));
}

sub bernoulli_polynomial ($$) {
    my ($n, $x) = @_;

    #
    ## B_n(x) = Sum_{k=0..n} binomial(n, k) * bernoulli(n-k) * x^k
    #

    $n = _star2ui($n) // goto &nan;
    $x = ref($x) eq __PACKAGE__ ? $$x : _star2obj($x);

    my @B = _bernoulli_numbers($n);

    my $u = $n + 1;
    my $z = Math::GMPz::Rmpz_init();
    my $q = Math::GMPq::Rmpq_init();

    my @terms;

    foreach my $k (0 .. $n) {

        --$u & 1 and $u > 1 and next;    # B_n = 0 for odd n > 1

        Math::GMPz::Rmpz_bin_uiui($z, $n, $k);
        Math::GMPq::Rmpq_mul_z($q, $u <= 1 ? $B[$u] : $B[($u >> 1) + 1], $z);

        push @terms, __mul__(__pow__($x, $k), $q);
    }

    bless \_binsplit([reverse @terms], \&__add__);
}

#
## Bernoulli number
#

# Algorithm due to Kevin J. McGown (December 8, 2005).
# Described in his paper: "Computing Bernoulli Numbers Quickly".

sub __bernfrac__ {
    my ($n) = @_;    # $n is an unsigned integer

#<<<
    # B(n) = (-1)^(n/2 + 1) * zeta(n)*2*n! / (2*pi)^n

    if ($n == 0) {
        goto &_one;
    }

    if ($n == 1) {
        my $r = Math::GMPq::Rmpq_init();
        Math::GMPq::Rmpq_set_ui($r, 1, 2);
        return $r;
    }

    if (($n & 1) and ($n > 1)) {    # Bn = 0 for odd n>1
        goto &_zero;
    }

    if ($n < 512) {
        return ((_bernoulli_numbers($n))[($n>>1)+1]);
    }

    state $round = Math::MPFR::MPFR_RNDN();
    state $tau   = 6.28318530717958647692528676655900576839433879875;

    my $log2B = (CORE::log(4 * $tau * $n) / 2 + $n * (CORE::log($n / $tau) - 1)) / CORE::log(2);

    my $prec = CORE::int($n + $log2B) + ($n <= 90 ? 24 : 0);
    state $d = Math::GMPz::Rmpz_init_nobless();
    Math::GMPz::Rmpz_fac_ui($d, $n);                      # d = n!

    my $K = Math::MPFR::Rmpfr_init2($prec);
    Math::MPFR::Rmpfr_const_pi($K, $round);               # K = pi
    Math::MPFR::Rmpfr_pow_si($K, $K, -$n, $round);        # K = K^(-n)
    Math::MPFR::Rmpfr_mul_z($K, $K, $d, $round);          # K = K*d
    Math::MPFR::Rmpfr_div_2ui($K, $K, $n - 1, $round);    # K = K / 2^(n-1)

    # `d` is the denominator of bernoulli(n)
    Math::GMPz::Rmpz_set_ui($d, 2);                       # d = 2

    my @primes = (2);

    { # Sieve the primes <= n+1
      # Sieve of Eratosthenes + Dana Jacobsen's optimizations
        my $N = $n + 1;

        my @composite;
        my $bound = CORE::int(CORE::sqrt($N));

        for (my $i = 3 ; $i <= $bound ; $i += 2) {
            if (!exists($composite[$i])) {
                for (my $j = $i * $i ; $j <= $N ; $j += 2 * $i) {
                    undef $composite[$j];
                }
            }
        }

        foreach my $k (1 .. ($N - 1) >> 1) {
            if (!exists($composite[2 * $k + 1])) {

                push(@primes, 2 * $k + 1);

                if ($n % (2 * $k) == 0) {    # d = d*p   iff (p-1)|n
                    Math::GMPz::Rmpz_mul_ui($d, $d, 2 * $k + 1);
                }
            }
        }
    }

    state $N = Math::MPFR::Rmpfr_init2_nobless(64);

    Math::MPFR::Rmpfr_mul_z($K, $K, $d, $round);         # K = K*d
    Math::MPFR::Rmpfr_set_ui($N, $n - 1, $round);        # N = n-1
    Math::MPFR::Rmpfr_ui_div($N, 1, $N, $round);         # N = 1/N
    Math::MPFR::Rmpfr_pow($N, $K, $N, $round);           # N = K^N

    Math::MPFR::Rmpfr_ceil($N, $N);                      # N = ceil(N)

    my $bound = Math::MPFR::Rmpfr_get_ui($N, $round);    # bound = int(N)

    my $z = Math::MPFR::Rmpfr_init2($prec);              # zeta(n)
    my $u = Math::GMPz::Rmpz_init();                     # p^n

    Math::MPFR::Rmpfr_set_ui($z, 1, $round);             # z = 1

    # `Math::GMPf` would perform slightly faster here.
    for (my $i = 0 ; $primes[$i] <= $bound ; ++$i) {     # primes <= bound
        Math::GMPz::Rmpz_ui_pow_ui($u, $primes[$i], $n);    # u = p^n
        Math::MPFR::Rmpfr_mul_z($z, $z, $u, $round);        # z = z*u
        Math::GMPz::Rmpz_sub_ui($u, $u, 1);                 # u = u-1
        Math::MPFR::Rmpfr_div_z($z, $z, $u, $round);        # z = z/u
    }

    Math::MPFR::Rmpfr_mul($z, $z, $K, $round);              # z = z * K
    Math::MPFR::Rmpfr_ceil($z, $z);                         # z = ceil(z)

    my $q = Math::GMPq::Rmpq_init();

    Math::GMPq::Rmpq_set_den($q, $d);                       # denominator
    Math::MPFR::Rmpfr_get_z($d, $z, $round);
    Math::GMPz::Rmpz_neg($d, $d) if $n % 4 == 0;            # d = -d, iff 4|n
    Math::GMPq::Rmpq_set_num($q, $d);                       # numerator

#>>>
    return $q;    # Bn
}

sub bernfrac ($;$) {
    my ($n, $x) = @_;

    @_ == 2 && goto &bernoulli_polynomial;
    $n = _star2ui($n) // goto &nan;

    bless \__bernfrac__($n);
}

*bernoulli = \&bernfrac;

sub faulhaber_polynomial {
    my ($n, $x) = @_;

    $n = _star2ui($n) // goto &nan;
    $x = ref($x) eq __PACKAGE__ ? $$x : _star2obj($x);

    $n += 1;
    $x = __inc__($x);

    bernoulli_polynomial($n, $x)->sub(bernfrac($n))->div($n);
}

*faulhaber = \&faulhaber_polynomial;

sub euler_polynomial ($$) {
    my ($n, $x) = @_;

    #
    ## E_n(x) = Sum_{k=0..n} binomial(n, n-k) * euler_number(n-k) / 2^(n-k) * (x - 1/2)^k
    #

    $n = _star2ui($n) // goto &nan;
    $x = ref($x) eq __PACKAGE__ ? $$x : _star2obj($x);

    my @S = _secant_numbers($n >> 1);

    my $u = $n + 1;
    my $z = Math::GMPz::Rmpz_init();

    $x = __dec__(__add__($x, $x));    # x = 2*x - 1

    my @terms;

    foreach my $k (0 .. $n) {
        --$u & 1 and next;            # E_n = 0 for all odd n

        Math::GMPz::Rmpz_bin_uiui($z, $n, $u);
        Math::GMPz::Rmpz_mul($z, $z, $S[$u >> 1]);
        Math::GMPz::Rmpz_neg($z, $z) if (($u >> 1) & 1);

        push @terms, __mul__(__pow__($x, $k), $z);
    }

    Math::GMPz::Rmpz_set_ui($z, 0);
    Math::GMPz::Rmpz_setbit($z, $n);

    bless \__div__(_binsplit(\@terms, \&__add__), $z);
}

sub euler ($;$) {
    my ($n, $x) = @_;

    @_ == 2 && goto &euler_polynomial;

    $n = _star2ui($n) // goto &nan;
    $n & 1 and goto &zero;    # E_n = 0 for all odd indices

    my $e = Math::GMPz::Rmpz_init_set((_secant_numbers($n >> 1))[$n >> 1]);
    Math::GMPz::Rmpz_neg($e, $e) if (($n >> 1) & 1);
    bless \$e;
}

sub secant_number ($) {
    my ($n) = @_;

    $n = _star2ui($n) // goto &nan;

    my @E = _secant_numbers($n);
    bless \Math::GMPz::Rmpz_init_set($E[$n]);
}

sub tangent_number ($) {
    my ($n) = @_;

    $n = _star2ui($n) // goto &nan;

    $n || goto &zero;
    my @T = _tangent_numbers($n);
    bless \Math::GMPz::Rmpz_init_set($T[$n - 1]);
}

#
## The n-th Harmonic number: 1 + 1/2 + ... + 1/n
#

sub harmfrac ($) {
    my ($n) = @_;

    $n = _star2ui($n) // goto &nan;

    $n || goto &zero;
    $n < 0 && goto &nan;

    # Use binary splitting for large values of n. (by Fredrik Johansson)
    # https://fredrik-j.blogspot.com/2009/02/how-not-to-compute-harmonic-numbers.html
    if ($n > 7000) {

        my $num = Math::GMPz::Rmpz_init_set_ui(1);
        my $den = Math::GMPz::Rmpz_init_set_ui($n + 1);

        my $temp = Math::GMPz::Rmpz_init();

        # Translation of Dana Jacobsen's code from Math::Prime::Util::{PP,GMP}.
        #   https://metacpan.org/pod/Math::Prime::Util::PP
        #   https://metacpan.org/pod/Math::Prime::Util::GMP
        sub {
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
                Math::GMPz::Rmpz_div_2exp($temp, $temp, 1);
                my $q = Math::GMPz::Rmpz_init_set($temp);
                my $r = Math::GMPz::Rmpz_init_set($temp);
                __SUB__->($num, $q);
                __SUB__->($r,   $den);
                Math::GMPz::Rmpz_mul($num,  $num, $den);
                Math::GMPz::Rmpz_mul($temp, $q,   $r);
                Math::GMPz::Rmpz_add($num, $num, $temp);
                Math::GMPz::Rmpz_mul($den, $den, $q);
            }
          }
          ->($num, $den);

        my $q = Math::GMPq::Rmpq_init();
        Math::GMPq::Rmpq_set_num($q, $num);
        Math::GMPq::Rmpq_set_den($q, $den);
        Math::GMPq::Rmpq_canonicalize($q);
        return bless \$q;
    }

    my $num = Math::GMPz::Rmpz_init_set_ui(1);
    my $den = Math::GMPz::Rmpz_init_set_ui(1);

    for (my $k = 2 ; $k <= $n ; ++$k) {
        Math::GMPz::Rmpz_mul_ui($num, $num, $k);    # num = num * k
        Math::GMPz::Rmpz_add($num, $num, $den);     # num = num + den
        Math::GMPz::Rmpz_mul_ui($den, $den, $k);    # den = den * k
    }

    my $r = Math::GMPq::Rmpq_init();
    Math::GMPq::Rmpq_set_num($r, $num);
    Math::GMPq::Rmpq_set_den($r, $den);
    Math::GMPq::Rmpq_canonicalize($r);
    bless \$r;
}

*harmonic = \&harmfrac;

#
## Bernoulli number as a floating-point value
#

sub bernreal ($) {
    my ($n) = @_;

    $n = _star2ui($n) // goto &nan;

    if ($n == 0) {
        my $r = Math::MPFR::Rmpfr_init2($PREC);
        Math::MPFR::Rmpfr_set_ui($r, 1, $ROUND);
        return bless \$r;
    }

    if ($n == 1) {
        my $r = Math::MPFR::Rmpfr_init2($PREC);
        Math::MPFR::Rmpfr_set_d($r, 0.5, $ROUND);
        return bless \$r;
    }

    if ($n & 1) {    # Bn = 0 for odd n>1
        my $r = Math::MPFR::Rmpfr_init2($PREC);
        Math::MPFR::Rmpfr_set_ui($r, 0, $ROUND);
        return bless \$r;
    }

    my $f = Math::MPFR::Rmpfr_init2($PREC);
    my $p = Math::MPFR::Rmpfr_init2($PREC);

    Math::MPFR::Rmpfr_zeta_ui($f, $n, $ROUND);       # f = zeta(n)
    Math::MPFR::Rmpfr_set_ui($p, $n + 1, $ROUND);    # p = n+1
    Math::MPFR::Rmpfr_gamma($p, $p, $ROUND);         # p = gamma(p)

    Math::MPFR::Rmpfr_mul($f, $f, $p, $ROUND);       # f = f * p

    Math::MPFR::Rmpfr_const_pi($p, $ROUND);          # p = PI
    Math::MPFR::Rmpfr_pow_ui($p, $p, $n, $ROUND);    # p = p^n

    Math::MPFR::Rmpfr_div_2ui($f, $f, $n - 1, $ROUND);    # f = f / 2^(n-1)

    Math::MPFR::Rmpfr_div($f, $f, $p, $ROUND);            # f = f/p
    Math::MPFR::Rmpfr_neg($f, $f, $ROUND) if $n % 4 == 0;

    bless \$f;
}

# Natural logarithm of the n-th Bernoulli number

sub lnbern ($) {
    my ($n) = @_;

    $n = _star2mpz($n) // goto &nan;

    # log(|B(n)|) = (1 - n)*log(2) - n*log(π) + log(zeta(n)) + log(n!)

    (Math::GMPz::Rmpz_sgn($n) || goto &zero) < 0 and goto &nan;

    my $L = Math::MPFR::Rmpfr_init2($PREC);
    Math::MPFR::Rmpfr_const_log2($L, $ROUND);

    if (Math::GMPz::Rmpz_cmp_ui($n, 1) == 0) {
        Math::MPFR::Rmpfr_neg($L, $L, $ROUND);
        return bless \$L;
    }

    Math::GMPz::Rmpz_odd_p($n) && goto &ninf;    # log(Bn) = -Inf for odd n>1

    my $pi = Math::MPFR::Rmpfr_init2($PREC);
    Math::MPFR::Rmpfr_const_pi($pi, $ROUND);     # pi = π

    my $t = Math::MPFR::Rmpfr_init2($PREC);
    Math::MPFR::Rmpfr_log($t, $pi, $ROUND);         # t = log(π)
    Math::MPFR::Rmpfr_mul_z($t, $t, $n, $ROUND);    # t = n*log(π)

    my $s = Math::GMPz::Rmpz_init();
    Math::GMPz::Rmpz_ui_sub($s, 1, $n);             # s = 1-n

    Math::MPFR::Rmpfr_mul_z($L, $L, $s, $ROUND);    # L = (1 - n)*log(2)
    Math::MPFR::Rmpfr_sub($L, $L, $t, $ROUND);      # L -= n*log(π)

    if (Math::GMPz::Rmpz_fits_ulong_p($n)) {        # n is a native unsigned integer
        Math::MPFR::Rmpfr_zeta_ui($t, Math::GMPz::Rmpz_get_ui($n), $ROUND);
    }
    else {
        Math::MPFR::Rmpfr_set_z($t, $n, $ROUND);    # t = n
        Math::MPFR::Rmpfr_zeta($t, $t, $ROUND);     # t = zeta(n)
    }

    Math::MPFR::Rmpfr_log($t, $t, $ROUND);          # t = log(zeta(n))
    Math::MPFR::Rmpfr_add($L, $L, $t, $ROUND);      # L += log(zeta(n))

    Math::GMPz::Rmpz_add_ui($s, $n, 1);             # s = n+1
    Math::MPFR::Rmpfr_set_z($t, $s, $ROUND);        # t = n+1
    Math::MPFR::Rmpfr_lngamma($t, $t, $ROUND);      # t = log(gamma(n+1)) = log(n!)

    Math::MPFR::Rmpfr_add($L, $L, $t, $ROUND);      # L += log(n!)

    # If 4|n, then B_n is negative; log(-Re(x)) = log(Re(x)) + π*i, for x>0
    if (Math::GMPz::Rmpz_divisible_2exp_p($n, 2)) {
        my $c = Math::MPC::Rmpc_init2($PREC);
        Math::MPC::Rmpc_set_fr_fr($c, $L, $pi, $ROUND);
        return bless \$c;
    }

    bless \$L;
}

#
## The n-th Harmonic number as a floating-point value
#

# harmreal(x) = digamma(x+1) + EulerGamma

sub __harmreal__ {
    my ($x) = @_;    # $x is a Math::MPFR object

    my $r = Math::MPFR::Rmpfr_init2($PREC);
    Math::MPFR::Rmpfr_add_ui($r, $x, 1, $ROUND);
    Math::MPFR::Rmpfr_digamma($r, $r, $ROUND);

    my $t = Math::MPFR::Rmpfr_init2($PREC);
    Math::MPFR::Rmpfr_const_euler($t, $ROUND);
    Math::MPFR::Rmpfr_add($r, $r, $t, $ROUND);

    $r;
}

sub harmreal ($) {
    bless \__harmreal__(_star2mpfr($_[0]) // (goto &nan));
}

#
## Subfactorial
#

sub subfactorial ($;$) {
    my ($m, $k) = @_;

    $m = _star2ui($m) // goto &nan;

    if (defined($k)) {
        $k = _star2si($k) // goto &nan;
    }
    else {
        $k = 0;
    }

    my $n = $m - $k;

    goto &zero if ($k < 0);
    goto &one  if ($n == 0);
    goto &zero if ($n < 0);

    my $tau  = 6.28318530717958647692528676655900576839433879875;
    my $prec = 4 + CORE::int(($n * CORE::log($n) + CORE::log($tau * $n) / 2 - $n) / CORE::log(2));

    my $z = Math::GMPz::Rmpz_init();
    Math::GMPz::Rmpz_fac_ui($z, $n);

    state $round_z = Math::MPFR::MPFR_RNDZ();

    my $f = Math::MPFR::Rmpfr_init2($prec);
    Math::MPFR::Rmpfr_set_ui($f, 1, $round_z);
    Math::MPFR::Rmpfr_exp($f, $f, $round_z);
    Math::MPFR::Rmpfr_z_div($f, $z, $f, $round_z);
    Math::MPFR::Rmpfr_add_d($f, $f, 0.5, $round_z);
    Math::MPFR::Rmpfr_floor($f, $f);
    Math::MPFR::Rmpfr_get_z($z, $f, $round_z);

    if ($k != 0) {
        my $t = Math::GMPz::Rmpz_init();
        Math::GMPz::Rmpz_bin_uiui($t, $m, $k);
        Math::GMPz::Rmpz_mul($z, $z, $t);
    }

    bless \$z;
}

sub superfactorial ($) {
    my ($n) = @_;

    $n = _star2ui($n) // goto &nan;

    my @list;
    foreach my $k (2 .. $n) {
        my $z = Math::GMPz::Rmpz_init();
        Math::GMPz::Rmpz_ui_pow_ui($z, $k, $n - $k + 1);
        push @list, $z;
    }

    @list || goto &one;
    bless \_binsplit(\@list, \&__mul__);
}

sub lnsuperfactorial ($) {
    my ($n) = @_;

    $n = _star2ui($n) // goto &nan;

    my $r = Math::MPFR::Rmpfr_init2($PREC);
    my $t = Math::MPFR::Rmpfr_init2($PREC);

    Math::MPFR::Rmpfr_set_ui($r, 0, $ROUND);

    foreach my $k (2 .. $n) {
        Math::MPFR::Rmpfr_set_ui($t, $k, $ROUND);
        Math::MPFR::Rmpfr_log($t, $t, $ROUND);
        Math::MPFR::Rmpfr_mul_ui($t, $t, $n - $k + 1, $ROUND);
        Math::MPFR::Rmpfr_add($r, $r, $t, $ROUND);
    }

    bless \$r;
}

sub hyperfactorial ($) {
    my ($n) = @_;

    $n = _star2ui($n) // goto &nan;

    my @list;
    foreach my $k (2 .. $n) {
        my $z = Math::GMPz::Rmpz_init();
        Math::GMPz::Rmpz_ui_pow_ui($z, $k, $k);
        push @list, $z;
    }

    @list || goto &one;
    bless \_binsplit(\@list, \&__mul__);
}

sub lnhyperfactorial ($) {
    my ($n) = @_;

    $n = _star2ui($n) // goto &nan;

    my $r = Math::MPFR::Rmpfr_init2($PREC);
    my $t = Math::MPFR::Rmpfr_init2($PREC);

    Math::MPFR::Rmpfr_set_ui($r, 0, $ROUND);

    foreach my $k (2 .. $n) {
        Math::MPFR::Rmpfr_set_ui($t, $k, $ROUND);
        Math::MPFR::Rmpfr_log($t, $t, $ROUND);
        Math::MPFR::Rmpfr_mul_ui($t, $t, $k, $ROUND);
        Math::MPFR::Rmpfr_add($r, $r, $t, $ROUND);
    }

    bless \$r;
}

#
## Factorial
#

sub factorial ($) {
    my ($n) = @_;

    $n = _star2ui($n) // goto &nan;

    my $r = Math::GMPz::Rmpz_init();
    Math::GMPz::Rmpz_fac_ui($r, $n);
    bless \$r;
}

#
## Double-factorial
#

sub dfactorial ($) {
    my ($n) = @_;

    $n = _star2ui($n) // goto &nan;

    my $r = Math::GMPz::Rmpz_init();
    Math::GMPz::Rmpz_2fac_ui($r, $n);
    bless \$r;
}

#
## M-factorial
#

sub mfactorial ($$) {
    my ($n, $k) = @_;

    $n = _star2ui($n) // goto &nan;
    $k = _star2ui($k) // goto &nan;

    my $r = Math::GMPz::Rmpz_init();
    Math::GMPz::Rmpz_mfac_uiui($r, $n, $k);
    bless \$r;
}

#
## falling_factorial(x, +y) = binomial(x, y) * y!
## falling_factorial(x, -y) = 1/falling_factorial(x + y, y)
#
sub falling_factorial ($$) {
    my ($x, $y) = @_;

    $x = _star2mpz($x) // goto &nan;
    $y = _star2si($y)  // goto &nan;

    my $r = Math::GMPz::Rmpz_init_set($x);

    if ($y < 0) {
        Math::GMPz::Rmpz_add_ui($r, $r, -$y);
    }

    Math::GMPz::Rmpz_fits_ulong_p($r)
      ? Math::GMPz::Rmpz_bin_uiui($r, Math::GMPz::Rmpz_get_ui($r), $y < 0 ? -$y : $y)
      : Math::GMPz::Rmpz_bin_ui($r, $r, $y < 0                            ? -$y : $y);

    Math::GMPz::Rmpz_sgn($r) || do {
        $y < 0
          ? (goto &nan)
          : (goto &zero);
    };

    state $t = Math::GMPz::Rmpz_init_nobless();
    Math::GMPz::Rmpz_fac_ui($t, $y < 0 ? -$y : $y);
    Math::GMPz::Rmpz_mul($r, $r, $t);

    if ($y < 0) {
        my $q = Math::GMPq::Rmpq_init();
        Math::GMPq::Rmpq_set_z($q, $r);
        Math::GMPq::Rmpq_inv($q, $q);
        return bless \$q;
    }

    bless \$r;
}

#
## rising_factorial(x, +y) = binomial(x + y - 1, y) * y!
## rising_factorial(x, -y) = 1/rising_factorial(x - y, y)
#
sub rising_factorial ($$) {
    my ($x, $y) = @_;

    $x = _star2mpz($x) // goto &nan;
    $y = _star2si($y)  // goto &nan;

    my $r = Math::GMPz::Rmpz_init_set($x);
    Math::GMPz::Rmpz_add_ui($r, $r, $y < 0 ? -$y : $y);
    Math::GMPz::Rmpz_sub_ui($r, $r, 1);

    if ($y < 0) {
        Math::GMPz::Rmpz_sub_ui($r, $r, $y < 0 ? -$y : $y);
    }

    Math::GMPz::Rmpz_fits_ulong_p($r)
      ? Math::GMPz::Rmpz_bin_uiui($r, Math::GMPz::Rmpz_get_ui($r), $y < 0 ? -$y : $y)
      : Math::GMPz::Rmpz_bin_ui($r, $r, $y < 0                            ? -$y : $y);

    Math::GMPz::Rmpz_sgn($r) || do {
        $y < 0
          ? (goto &nan)
          : (goto &zero);
    };

    state $t = Math::GMPz::Rmpz_init_nobless();
    Math::GMPz::Rmpz_fac_ui($t, $y < 0 ? -$y : $y);
    Math::GMPz::Rmpz_mul($r, $r, $t);

    if ($y < 0) {
        my $q = Math::GMPq::Rmpq_init();
        Math::GMPq::Rmpq_set_z($q, $r);
        Math::GMPq::Rmpq_inv($q, $q);
        return bless \$q;
    }

    bless \$r;
}

#
## Greatest common multiple
#

sub gcd {
    my ($x, $y) = @_;

    @_ or goto &zero;    # By convention, gcd of an empty set is 0.
    @_ == 1 and return $x;

    my $r = Math::GMPz::Rmpz_init();

    if (@_ > 2) {
        my @terms = map { _star2mpz($_) // goto &nan } @_;

        Math::GMPz::Rmpz_set($r, shift(@terms));

        foreach my $z (@terms) {
            Math::GMPz::Rmpz_gcd($r, $r, $z);
            Math::GMPz::Rmpz_cmp_ui($r, 1) || last;
        }

        return bless \$r;
    }

    if (ref($y) and !ref($x)) {
        ($x, $y) = ($y, $x);
    }

    $x = _star2mpz($x) // goto &nan;

    if (!ref($y) and CORE::int($y) eq $y and $y < ULONG_MAX and $y > LONG_MIN) {
        Math::GMPz::Rmpz_gcd_ui($r, $x, $y < 0 ? -$y : $y);
    }
    else {
        $y = _star2mpz($y) // goto &nan;
        Math::GMPz::Rmpz_gcd($r, $x, $y);
    }

    bless \$r;
}

sub gcdext ($$) {
    my ($n, $k) = @_;

    $n = _star2mpz($n) // return (nan(), nan());
    $k = _star2mpz($k) // return (nan(), nan());

    my $g = Math::GMPz::Rmpz_init();
    my $u = Math::GMPz::Rmpz_init();
    my $v = Math::GMPz::Rmpz_init();

    Math::GMPz::Rmpz_gcdext($g, $u, $v, $n, $k);

    ((bless \$u), (bless \$v), (bless \$g));
}

#
## Least common multiple
#

sub __lcm__ {
    my ($n, $k) = @_;
    my $r = Math::GMPz::Rmpz_init();
    Math::GMPz::Rmpz_lcm($r, $n, $k);
    $r;
}

sub lcm {
    my ($x, $y) = @_;

    @_ or goto &one;    # By convention, lcm of an empty set is 1.
    @_ == 1 and return $x;

    if (@_ > 2) {
        my @terms = map { _star2mpz($_) // goto &nan } @_;
        return bless \_binsplit(\@terms, \&__lcm__);
    }

    if (ref($y) and !ref($x)) {
        ($x, $y) = ($y, $x);
    }

    $x = _star2mpz($x) // goto &nan;

    my $r = Math::GMPz::Rmpz_init();

    if (!ref($y) and CORE::int($y) eq $y and $y < ULONG_MAX and $y > LONG_MIN) {
        Math::GMPz::Rmpz_lcm_ui($r, $x, $y < 0 ? -$y : $y);
    }
    else {
        $y = _star2mpz($y) // goto &nan;
        Math::GMPz::Rmpz_lcm($r, $x, $y);
    }

    bless \$r;
}

#
## Next prime after `n`.
#

sub next_prime ($) {
    my ($n) = @_;
    $n = _star2mpz($n) // goto &nan;
    my $r = Math::GMPz::Rmpz_init();
    Math::GMPz::Rmpz_nextprime($r, $n);
    bless \$r;
}

#
## True if `n` is an integer
#

sub __is_int__ {
    my ($x) = @_;

    ref($x) eq 'Math::GMPz' && return 1;
    ref($x) eq 'Math::GMPq' && return Math::GMPq::Rmpq_integer_p($x);
    ref($x) eq 'Math::MPFR' && return Math::MPFR::Rmpfr_integer_p($x);

    (@_) = _any2mpfr($x);
    goto __SUB__;
}

sub is_int ($) {
    my ($n) = @_;
    $n = ref($n) eq __PACKAGE__ ? $$n : _star2obj($n);
    ref($n) eq 'Math::GMPz' ? 1 : __is_int__($n);
}

#
## True if `n` is a rational number
#

sub is_rat ($) {
    my ($n) = @_;
    my $ref = ref(ref($n) eq __PACKAGE__ ? $$n : _star2obj($n));
    $ref eq 'Math::GMPz' or $ref eq 'Math::GMPq';
}

#
## True if `n` is probably a prime number
#

sub is_prime ($;$) {
    my ($n, $r) = @_;

    $n = ref($n) eq __PACKAGE__ ? $$n : _star2obj($n);

    if (ref($n) ne 'Math::GMPz') {
        __is_int__($n) || return 0;
        $n = _any2mpz($n) // return 0;
    }

    Math::GMPz::Rmpz_sgn($n) > 0 or return 0;
    $r = defined($r) ? (CORE::abs(CORE::int($r)) || 23) : 23;
    Math::GMPz::Rmpz_probab_prime_p($n, $r);
}

#
## True if `n` is coprime to `k`
#

sub is_coprime ($$) {
    my ($n, $k) = @_;

    $n = ref($n) eq __PACKAGE__ ? $$n : _star2obj($n);

    if (ref($n) ne 'Math::GMPz') {
        __is_int__($n) || return 0;
        $n = _any2mpz($n) // return 0;
    }

    if (!ref($k) and CORE::int($k) eq $k and $k >= 0 and $k < ULONG_MAX) {
        ## `k` is a native integer
    }
    else {
        $k = ref($k) eq __PACKAGE__ ? $$k : _star2obj($k);

        if (ref($k) ne 'Math::GMPz') {
            __is_int__($k) || return 0;
            $k = _any2mpz($k) // return 0;
        }
    }

    if (ref($k)) {
        state $t = Math::GMPz::Rmpz_init_nobless();
        Math::GMPz::Rmpz_gcd($t, $n, $k);
        return (Math::GMPz::Rmpz_cmp_ui($t, 1) == 0);
    }

    Math::GMPz::Rmpz_gcd_ui($Math::GMPz::NULL, $n, $k) == 1;
}

#
## True if all the prime factors of `n` are <= k.
#

sub is_smooth ($$) {
    my ($n, $k) = @_;

    $n = ref($n) eq __PACKAGE__ ? $$n : _star2obj($n);

    if (ref($n) ne 'Math::GMPz') {
        __is_int__($n) || return 0;
        $n = _any2mpz($n) // return 0;
    }

    return 0 if Math::GMPz::Rmpz_sgn($n) <= 0;

    $k = _star2ui($k) // return 0;

    return 1 if Math::GMPz::Rmpz_cmp_ui($n, 1) == 0;
    return 0 if $k <= 1;

    my $B = _cached_primorial($k);

    state $g = Math::GMPz::Rmpz_init_nobless();
    Math::GMPz::Rmpz_gcd($g, $n, $B);

    if (Math::GMPz::Rmpz_cmp_ui($g, 1) == 0) {
        return 0;
    }

    my $t = Math::GMPz::Rmpz_init_set($n);

    while (Math::GMPz::Rmpz_cmp_ui($g, 1) > 0) {
        Math::GMPz::Rmpz_remove($t, $t, $g);
        return 1 if Math::GMPz::Rmpz_cmp_ui($t, 1) == 0;
        Math::GMPz::Rmpz_gcd($g, $t, $g);
    }

    return 0;
}

#
## True if all the prime factors of `n` are >= k.
#

sub is_rough ($$) {
    my ($n, $k) = @_;

    $n = _star2mpz($n) // return 0;

    return 0 if Math::GMPz::Rmpz_sgn($n) <= 0;
    return 1 if Math::GMPz::Rmpz_cmp_ui($n, 1) == 0;

    $k = (_star2ui($k) // return 0) - 1;

    return 1 if $k <= 1;

    my $B = _cached_primorial($k);

    state $g = Math::GMPz::Rmpz_init_nobless();
    Math::GMPz::Rmpz_gcd($g, $n, $B);
    (Math::GMPz::Rmpz_cmp_ui($g, 1) > 0) ? 0 : 1;
}

#
## Smooth part of n, containing all prime factors p|n such that p <= k.
#
sub smooth_part {
    my ($n, $k) = @_;

    $n = _star2mpz($n) // goto &nan;

    goto &zero if Math::GMPz::Rmpz_sgn($n) <= 0;

    $k = _star2ui($k) // goto &nan;

    goto &one if $k <= 1;
    goto &one if Math::GMPz::Rmpz_cmp_ui($n, 1) == 0;

    my $B = _cached_primorial($k);

    state $g = Math::GMPz::Rmpz_init_nobless();
    Math::GMPz::Rmpz_gcd($g, $n, $B);

    if (Math::GMPz::Rmpz_cmp_ui($g, 1) == 0) {
        goto &one;
    }

    my $t = Math::GMPz::Rmpz_init_set($n);

    while (Math::GMPz::Rmpz_cmp_ui($g, 1) > 0) {
        Math::GMPz::Rmpz_remove($t, $t, $g);
        return (bless \$n) if Math::GMPz::Rmpz_cmp_ui($t, 1) == 0;
        Math::GMPz::Rmpz_gcd($g, $t, $g);
    }

    Math::GMPz::Rmpz_divexact($t, $n, $t);
    bless \$t;
}

#
## Rough part of n, containing all prime factors p|n such that p >= k.
#
sub rough_part {
    my ($n, $k) = @_;

    $n = _star2mpz($n) // goto &nan;

    goto &zero if Math::GMPz::Rmpz_sgn($n) <= 0;

    $k = (_star2ui($k) // goto &nan) - 1;

    return (bless \$n) if $k <= 1;
    goto &one          if Math::GMPz::Rmpz_cmp_ui($n, 1) == 0;

    my $B = _cached_primorial($k);

    state $g = Math::GMPz::Rmpz_init_nobless();
    Math::GMPz::Rmpz_gcd($g, $n, $B);

    if (Math::GMPz::Rmpz_cmp_ui($g, 1) == 0) {
        return bless \$n;
    }

    my $t = Math::GMPz::Rmpz_init_set($n);

    while (Math::GMPz::Rmpz_cmp_ui($g, 1) > 0) {
        Math::GMPz::Rmpz_remove($t, $t, $g);
        goto &one if Math::GMPz::Rmpz_cmp_ui($t, 1) == 0;
        Math::GMPz::Rmpz_gcd($g, $t, $g);
    }

    bless \$t;
}

sub is_smooth_over_prod ($$) {
    my ($n, $k) = @_;

    $n = ref($n) eq __PACKAGE__ ? $$n : _star2obj($n);

    if (ref($n) ne 'Math::GMPz') {
        __is_int__($n) || return 0;
        $n = _any2mpz($n) // return 0;
    }

    return 0 if Math::GMPz::Rmpz_sgn($n) <= 0;

    $k = ref($k) eq __PACKAGE__ ? $$k : _star2obj($k);

    if (ref($k) ne 'Math::GMPz') {
        __is_int__($k) || return 0;
        $k = _any2mpz($k) // return 0;
    }

    return 0 if Math::GMPz::Rmpz_sgn($k) <= 0;
    return 1 if Math::GMPz::Rmpz_cmp_ui($n, 1) == 0;

    state $g = Math::GMPz::Rmpz_init_nobless();

    Math::GMPz::Rmpz_gcd($g, $n, $k);

    if (Math::GMPz::Rmpz_cmp_ui($g, 1) == 0) {
        return 0;
    }

    my $t = Math::GMPz::Rmpz_init_set($n);

    while (Math::GMPz::Rmpz_cmp_ui($g, 1) > 0) {
        Math::GMPz::Rmpz_remove($t, $t, $g);
        return 1 if Math::GMPz::Rmpz_cmp_ui($t, 1) == 0;
        Math::GMPz::Rmpz_gcd($g, $t, $g);
    }

    return 0;
}

#
## Numerator of a number
#

sub numerator ($) {
    my ($x) = @_;

    my $r = ref($x) eq __PACKAGE__ ? $$x : _star2obj($x);

    while (1) {

        if (ref($r) eq 'Math::GMPq') {
            my $z = Math::GMPz::Rmpz_init();
            Math::GMPq::Rmpq_get_num($z, $r);
            return bless \$z;
        }

        ref($r) eq 'Math::GMPz' and return $x;    # is an integer

        $r = _any2mpq($r) // goto &nan;
    }
}

#
## Denominator of a number
#

sub denominator ($) {
    my ($x) = @_;

    my $r = ref($x) eq __PACKAGE__ ? $$x : _star2obj($x);

    while (1) {

        if (ref($r) eq 'Math::GMPq') {
            my $z = Math::GMPz::Rmpz_init();
            Math::GMPq::Rmpq_get_den($z, $r);
            return bless \$z;
        }

        ref($r) eq 'Math::GMPz' and goto &one;    # is an integer

        $r = _any2mpq($r) // goto &nan;
    }
}

#
## (numerator, denominator)
#

sub nude ($) {
    my ($x) = @_;

    if (ref($x) ne __PACKAGE__) {
        $x = __PACKAGE__->new($x);
    }

    ($x->numerator, $x->denominator);
}

#
## Sign of a number
#

sub __sgn__ {
    my ($x) = @_;
    goto(ref($x) =~ tr/:/_/rs);

  Math_MPFR: {
        return Math::MPFR::Rmpfr_sgn($x);
    }

  Math_GMPq: {
        return Math::GMPq::Rmpq_sgn($x);
    }

  Math_GMPz: {
        return Math::GMPz::Rmpz_sgn($x);
    }

    # sgn(x) = x / abs(x)
  Math_MPC: {
        my $abs = Math::MPFR::Rmpfr_init2($PREC);
        Math::MPC::Rmpc_abs($abs, $x, $ROUND);

        if (Math::MPFR::Rmpfr_zero_p($abs)) {    # it's zero
            return 0;
        }

        my $r = Math::MPC::Rmpc_init2($PREC);
        Math::MPC::Rmpc_div_fr($r, $x, $abs, $ROUND);
        return $r;
    }
}

sub sgn ($) {
    my ($x) = @_;
    my $r = __sgn__(ref($x) eq __PACKAGE__ ? $$x : _star2obj($x));
    ref($r) ? (bless \$r) : $r;
}

#
## True if `x` is a real number
#

sub is_real ($) {
    my ($x) = @_;

    my $r = ref($x) eq __PACKAGE__ ? $$x : _star2obj($x);

    while (1) {
        my $ref = ref($r);

        $ref eq 'Math::GMPz' && return 1;
        $ref eq 'Math::GMPq' && return 1;
        $ref eq 'Math::MPFR' && return Math::MPFR::Rmpfr_number_p($r);

        $r = _any2mpfr($r);
    }
}

#
## True if `x` is an imaginary number
#

sub is_imag ($) {
    my ($x) = @_;

    my $r = ref($x) eq __PACKAGE__ ? $$x : _star2obj($x);
    ref($r) eq 'Math::MPC' or return 0;

    my $f = Math::MPFR::Rmpfr_init2($PREC);
    Math::MPC::RMPC_RE($f, $r);
    Math::MPFR::Rmpfr_zero_p($f) || return 0;    # is complex
    Math::MPC::RMPC_IM($f, $r);
    !Math::MPFR::Rmpfr_zero_p($f);
}

#
## True if `x` is a complex number
#

sub is_complex ($) {
    my ($x) = @_;

    my $r = ref($x) eq __PACKAGE__ ? $$x : _star2obj($x);
    ref($r) eq 'Math::MPC' or return 0;

    my $f = Math::MPFR::Rmpfr_init2($PREC);
    Math::MPC::RMPC_IM($f, $r);
    Math::MPFR::Rmpfr_zero_p($f) && return 0;    # is real
    Math::MPC::RMPC_RE($f, $r);
    !Math::MPFR::Rmpfr_zero_p($f);
}

#
## True if `x == +Inf`
#

sub is_inf ($) {
    my ($x) = @_;

    my $r = ref($x) eq __PACKAGE__ ? $$x : _star2obj($x);

    while (1) {
        my $ref = ref($r);

        $ref eq 'Math::GMPz' && return 0;
        $ref eq 'Math::GMPq' && return 0;
        $ref eq 'Math::MPFR' && return (Math::MPFR::Rmpfr_inf_p($r) and Math::MPFR::Rmpfr_sgn($r) > 0);

        $r = _any2mpfr($r);
    }
}

#
## True if `x == -Inf`
#

sub is_ninf ($) {
    my ($x) = @_;

    my $r = ref($x) eq __PACKAGE__ ? $$x : _star2obj($x);

    while (1) {
        my $ref = ref($r);

        $ref eq 'Math::GMPz' && return 0;
        $ref eq 'Math::GMPq' && return 0;
        $ref eq 'Math::MPFR' && return (Math::MPFR::Rmpfr_inf_p($r) and Math::MPFR::Rmpfr_sgn($r) < 0);

        $r = _any2mpfr($r);
    }
}

#
## True if `x` is Not-a-Number (NaN)
#

sub is_nan ($) {
    my ($x) = @_;

    $x = ref($x) eq __PACKAGE__ ? $$x : _star2obj($x);

    ref($x) eq 'Math::GMPz' && return 0;
    ref($x) eq 'Math::GMPq' && return 0;
    ref($x) eq 'Math::MPFR' && return Math::MPFR::Rmpfr_nan_p($x);

    my $t = Math::MPFR::Rmpfr_init2($PREC);

    Math::MPC::RMPC_RE($t, $x);
    Math::MPFR::Rmpfr_nan_p($t) && return 1;

    Math::MPC::RMPC_IM($t, $x);
    Math::MPFR::Rmpfr_nan_p($t) && return 1;

    return 0;
}

#
## True if `n` is an even integer
#

sub is_even ($) {
    my ($n) = @_;

    $n = ref($n) eq __PACKAGE__ ? $$n : _star2obj($n);

    if (ref($n) ne 'Math::GMPz') {
        __is_int__($n) || return 0;
        $n = _any2mpz($n) // return 0;
    }

    Math::GMPz::Rmpz_even_p($n);
}

#
## True if `n` is an odd integer
#

sub is_odd ($) {
    my ($n) = @_;

    $n = ref($n) eq __PACKAGE__ ? $$n : _star2obj($n);

    if (ref($n) ne 'Math::GMPz') {
        __is_int__($n) || return 0;
        $n = _any2mpz($n) // return 0;
    }

    Math::GMPz::Rmpz_odd_p($n);
}

#
## True if `n == 0`
#

sub is_zero ($) {
    my ($n) = @_;
    @_ = ((ref($n) eq __PACKAGE__ ? $$n : _star2obj($n)), 0);
    goto &__eq__;
}

#
## True if `n == 1`
#

sub is_one ($) {
    my ($n) = @_;
    @_ = ((ref($n) eq __PACKAGE__ ? $$n : _star2obj($n)), 1);
    goto &__eq__;
}

#
## True if `n == -1`
#

sub is_mone ($) {
    my ($n) = @_;
    @_ = ((ref($n) eq __PACKAGE__ ? $$n : _star2obj($n)), -1);
    goto &__eq__;
}

#
## True if `n` is positive
#

sub is_pos ($) {
    my ($n) = @_;
    (__cmp__((ref($n) eq __PACKAGE__ ? $$n : _star2obj($n)), 0) // return undef) > 0;
}

#
## True if `n` is negative
#

sub is_neg ($) {
    my ($n) = @_;
    (__cmp__((ref($n) eq __PACKAGE__ ? $$n : _star2obj($n)), 0) // return undef) < 0;
}

#
## True if `n` is a perfect square
#

sub is_square ($) {
    my ($n) = @_;

    $n = ref($n) eq __PACKAGE__ ? $$n : _star2obj($n);

    if (ref($n) ne 'Math::GMPz') {
        __is_int__($n) || return 0;
        $n = _any2mpz($n) // return 0;
    }

    Math::GMPz::Rmpz_perfect_square_p($n);
}

#
## True if `n` is a k-gonal number
#

sub __is_polygonal__ {
    my ($n, $k, $second) = @_;

    Math::GMPz::Rmpz_sgn($n) || return 1;

    # polygonal_root(n, k)
    #   = ((k - 4) ± sqrt(8 * (k - 2) * n + (k - 4)^2)) / (2 * (k - 2))

    state $t = Math::GMPz::Rmpz_init_nobless();
    state $u = Math::GMPz::Rmpz_init_nobless();

    Math::GMPz::Rmpz_sub_ui($u, $k, 2);      # u = k-2
    Math::GMPz::Rmpz_mul($t, $n, $u);        # t = n*u
    Math::GMPz::Rmpz_mul_2exp($t, $t, 3);    # t = t*8

    Math::GMPz::Rmpz_sub_ui($u, $u, 2);      # u = u-2
    Math::GMPz::Rmpz_mul($u, $u, $u);        # u = u^2

    Math::GMPz::Rmpz_add($t, $t, $u);        # t = t+u
    Math::GMPz::Rmpz_perfect_square_p($t) || return 0;
    Math::GMPz::Rmpz_sqrt($t, $t);           # t = sqrt(t)

    Math::GMPz::Rmpz_sub_ui($u, $k, 4);      # u = k-4

    $second
      ? Math::GMPz::Rmpz_sub($t, $u, $t)     # t = u-t
      : Math::GMPz::Rmpz_add($t, $t, $u);    # t = t+u

    Math::GMPz::Rmpz_add_ui($u, $u, 2);      # u = u+2
    Math::GMPz::Rmpz_mul_2exp($u, $u, 1);    # u = u*2

    Math::GMPz::Rmpz_divisible_p($t, $u);    # true iff u|t
}

sub is_polygonal ($$) {
    my ($n, $k) = @_;

    $n = ref($n) eq __PACKAGE__ ? $$n : _star2obj($n);

    if (ref($n) ne 'Math::GMPz') {
        __is_int__($n) || return 0;
        $n = _any2mpz($n) // return 0;
    }

    $k = _star2mpz($k) // return 0;
    __is_polygonal__($n, $k);
}

#
## Is a second polygonal number?
#

sub is_polygonal2 ($$) {
    my ($n, $k) = @_;

    $n = ref($n) eq __PACKAGE__ ? $$n : _star2obj($n);

    if (ref($n) ne 'Math::GMPz') {
        __is_int__($n) || return 0;
        $n = _any2mpz($n) // return 0;
    }

    $k = _star2mpz($k) // return 0;

    __is_polygonal__($n, $k, 1);
}

#
## Integer polygonal root
#

sub __ipolygonal_root__ {
    my ($n, $k, $second) = @_;

    # polygonal_root(n, k)
    #   = ((k - 4) ± sqrt(8 * (k - 2) * n + (k - 4)^2)) / (2 * (k - 2))

    state $t = Math::GMPz::Rmpz_init_nobless();
    state $u = Math::GMPz::Rmpz_init_nobless();

    Math::GMPz::Rmpz_sub_ui($u, $k, 2);      # u = k-2
    Math::GMPz::Rmpz_mul($t, $n, $u);        # t = n*u
    Math::GMPz::Rmpz_mul_2exp($t, $t, 3);    # t = t*8

    Math::GMPz::Rmpz_sub_ui($u, $u, 2);      # u = u-2
    Math::GMPz::Rmpz_mul($u, $u, $u);        # u = u^2
    Math::GMPz::Rmpz_add($t, $t, $u);        # t = t+u

    Math::GMPz::Rmpz_sgn($t) < 0 && goto &_nan;    # `t` is negative

    Math::GMPz::Rmpz_sqrt($t, $t);                 # t = sqrt(t)
    Math::GMPz::Rmpz_sub_ui($u, $k, 4);            # u = k-4

    $second
      ? Math::GMPz::Rmpz_sub($t, $u, $t)           # t = u-t
      : Math::GMPz::Rmpz_add($t, $t, $u);          # t = t+u

    Math::GMPz::Rmpz_add_ui($u, $u, 2);            # u = u+2
    Math::GMPz::Rmpz_mul_2exp($u, $u, 1);          # u = u*2

    Math::GMPz::Rmpz_sgn($u) || return $n;         # `u` is zero

    my $r = Math::GMPz::Rmpz_init();
    Math::GMPz::Rmpz_div($r, $t, $u);              # r = floor(t/u)
    return $r;
}

sub ipolygonal_root ($$) {
    my ($n, $k) = @_;

    $n = _star2mpz($n) // goto &nan;
    $k = _star2mpz($k) // goto &nan;

    bless \__ipolygonal_root__($n, $k);
}

#
## Second integer polygonal root
#

sub ipolygonal_root2 ($$) {
    my ($n, $k) = @_;

    $n = _star2mpz($n) // goto &nan;
    $k = _star2mpz($k) // goto &nan;

    bless \__ipolygonal_root__($n, $k, 1);
}

#
## n-th k-gonal number
#

sub polygonal ($$) {
    my ($n, $k) = @_;

    $n = _star2mpz($n) // goto &nan;

    if (!ref($k) and CORE::int($k) eq $k and $k >= 0 and $k < ULONG_MAX) {
        ## `k` is a native unsigned integer
    }
    else {
        $k = _star2mpz($k) // goto &nan;
    }

    #
    ## polygonal(n, k) = n * (k*n - k - 2*n + 4) / 2
    #

    my $r = Math::GMPz::Rmpz_init();

    if (!ref($k)) {    # `k` is a native unsigned integer
        Math::GMPz::Rmpz_mul_ui($r, $n, $k);    # r = n*k
        Math::GMPz::Rmpz_sub_ui($r, $r, $k);    # r = r-k
    }
    else {
        Math::GMPz::Rmpz_mul($r, $n, $k);       # r = n*k
        Math::GMPz::Rmpz_sub($r, $r, $k);       # r = r-k
    }

    Math::GMPz::Rmpz_submul_ui($r, $n, 2);    # r = r-2*n
    Math::GMPz::Rmpz_add_ui($r, $r, 4);       # r = r+4
    Math::GMPz::Rmpz_mul($r, $r, $n);         # r = r*n
    Math::GMPz::Rmpz_div_2exp($r, $r, 1);     # r = r/2

    bless \$r;
}

#
## True if n = c^k for some integer c
#

sub __is_power__ {
    my ($n, $k) = @_;

    # Everything is a first power
    $k == 1 and return 1;

    Math::GMPz::Rmpz_cmp_ui($n, 1) == 0 and return 1;

    # Return a true value when $n=-1 and $k is odd
    $k % 2 and (Math::GMPz::Rmpz_cmp_si($n, -1) == 0) and return 1;

    # Don't accept a non-positive power
    # Also, when $n is negative and $k is even, return faster
    if ($k <= 0 or ($k % 2 == 0 and Math::GMPz::Rmpz_sgn($n) < 0)) {
        return 0;
    }

    # Optimization for perfect squares
    $k == 2 and return Math::GMPz::Rmpz_perfect_square_p($n);

    Math::GMPz::Rmpz_perfect_power_p($n) || return 0;
    state $t = Math::GMPz::Rmpz_init_nobless();
    Math::GMPz::Rmpz_root($t, $n, $k);
}

sub is_power ($;$) {
    my ($n, $k) = @_;

    $n = _star2mpz($n) // return 0;
    $k // return Math::GMPz::Rmpz_perfect_power_p($n);
    $k = _star2si($k) // return 0;

    __is_power__($n, $k);
}

sub is_power_of ($$) {
    my ($n, $k) = @_;

    $n = _star2obj($n);
    $k = _star2obj($k);

    if (ref($n) ne 'Math::GMPz') {
        __is_int__($n) || return 0;
        $n = _any2mpz($n) // return 0;
    }

    if (ref($k) ne 'Math::GMPz') {
        $k = _any2mpz($k) // 0;
    }

    if (Math::GMPz::Rmpz_cmp_ui($k, 2) == 0) {
        return (Math::GMPz::Rmpz_popcount($n) == 1);
    }

    my $e = __ilog__($n, $k) // return 0;

    state $t = Math::GMPz::Rmpz_init_nobless();
    Math::GMPz::Rmpz_pow_ui($t, $k, $e);

    (Math::GMPz::Rmpz_cmp($t, $n) == 0);
}

#
## kronecker
#

sub kronecker ($$) {
    my ($n, $k) = @_;

    if (!ref($n) and CORE::int($n) eq $n and $n < ULONG_MAX and $n > LONG_MIN) {

        if (!ref($k) and CORE::int($k) eq $k and $k < ULONG_MAX and $k > LONG_MIN) {
            $k =
              ($k < 0)
              ? Math::GMPz::Rmpz_init_set_si($k)
              : Math::GMPz::Rmpz_init_set_ui($k);
        }
        else {
            $k = _star2mpz($k) // goto &nan;
        }

        return (
                $n < 0
                ? Math::GMPz::Rmpz_si_kronecker($n, $k)
                : Math::GMPz::Rmpz_ui_kronecker($n, $k)
               );
    }

    $n = _star2mpz($n) // goto &nan;

    if (!ref($k) and CORE::int($k) eq $k and $k < ULONG_MAX and $k > LONG_MIN) {
        return (
                $k < 0
                ? Math::GMPz::Rmpz_kronecker_si($n, $k)
                : Math::GMPz::Rmpz_kronecker_ui($n, $k)
               );
    }

    $k = _star2mpz($k) // goto &nan;

    Math::GMPz::Rmpz_kronecker($n, $k);
}

#
## valuation
#

sub __valuation__ {    # takes two Math::GMPz objects
    my ($x, $y) = @_;
    Math::GMPz::Rmpz_sgn($y)          || return (0, $x);
    Math::GMPz::Rmpz_cmpabs_ui($y, 1) || return (0, $x);
    my $r = Math::GMPz::Rmpz_init();
    my $v = Math::GMPz::Rmpz_remove($r, $x, $y);
    ($v, $r);
}

sub valuation ($$) {
    my ($n, $k) = @_;

    $n = _star2mpz($n) // goto &nan;
    $k = _star2mpz($k) // goto &nan;

    (__valuation__($n, $k))[0];
}

#
## remdiv
#

sub remdiv ($$) {
    my ($n, $k) = @_;

    $n = _star2mpz($n) // goto &nan;
    $k = _star2mpz($k) // goto &nan;

    bless \((__valuation__($n, $k))[1]);
}

#
## Make n coprime to k, by removing from n common factors with k
#
sub make_coprime {
    my ($n, $k) = @_;

    $n = _star2mpz($n) // goto &nan;
    $k = _star2mpz($k) // goto &nan;

    if (Math::GMPz::Rmpz_sgn($n) == 0) {
        return bless \$n;
    }

    my $r = Math::GMPz::Rmpz_init_set($n);
    my $g = Math::GMPz::Rmpz_init();

    Math::GMPz::Rmpz_gcd($g, $r, $k);

    while (Math::GMPz::Rmpz_cmp_ui($g, 1) > 0) {
        Math::GMPz::Rmpz_remove($r, $r, $g);
        Math::GMPz::Rmpz_gcd($g, $r, $g);
    }

    bless \$r;
}

#
## Invmod
#

sub invmod ($$) {
    my ($n, $k) = @_;

    $n = _star2mpz($n) // goto &nan;
    $k = _star2mpz($k) // goto &nan;

    my $r = Math::GMPz::Rmpz_init();
    Math::GMPz::Rmpz_invert($r, $n, $k) || (goto &nan);
    bless \$r;
}

sub _modular_rational {
    my ($n, $m) = @_;

    if (ref($n) ne 'Math::GMPq') {
        $n = _any2mpq($n) // return;
    }

    state $z = Math::GMPz::Rmpz_init_nobless();

    my $t = Math::GMPz::Rmpz_init();
    Math::GMPq::Rmpq_get_den($z, $n);
    Math::GMPz::Rmpz_invert($t, $z, $m) or return;
    Math::GMPq::Rmpq_get_num($z, $n);
    Math::GMPz::Rmpz_mul($t, $t, $z);

    return $t;
}

#
## Ratmod
#

sub ratmod ($$) {
    my ($n, $m) = @_;

    $n = _star2obj($n) // goto &nan;
    $m = _star2mpz($m) // goto &nan;

    my $r = Math::GMPz::Rmpz_init();

    if (ref($n) eq 'Math::GMPz') {
        Math::GMPz::Rmpz_mod($r, $n, $m);
    }
    else {
        $r = _modular_rational($n, $m) // goto &nan;
        Math::GMPz::Rmpz_mod($r, $r, $m);
    }

    bless \$r;
}

#
## Powmod
#

sub powmod ($$$) {
    my ($n, $k, $m) = @_;

    $n = _star2obj($n) // goto &nan;
    $k = _star2mpz($k) // goto &nan;
    $m = _star2mpz($m) // goto &nan;

    Math::GMPz::Rmpz_sgn($m) || goto &nan;

    if (ref($n) ne 'Math::GMPz') {
        if (__is_int__($n)) {
            $n = _any2mpz($n) // goto &nan;
        }
        else {
            $n = _modular_rational($n, $m) // goto &nan;
        }
    }

    my $r = Math::GMPz::Rmpz_init();

    if (Math::GMPz::Rmpz_sgn($k) < 0) {
        Math::GMPz::Rmpz_invert($r, $n, $m) or goto &nan;
    }

    Math::GMPz::Rmpz_fits_ulong_p($k)
      ? Math::GMPz::Rmpz_powm_ui($r, $n, Math::GMPz::Rmpz_get_ui($k), $m)
      : Math::GMPz::Rmpz_powm($r, $n, $k, $m);

    bless \$r;
}

#
## Geometric summation formula
## https://en.wikipedia.org/wiki/Geometric_series
#

sub geometric_sum ($$) {
    my ($n, $r) = @_;

    $n = ref($n) eq __PACKAGE__ ? $$n : _star2obj($n);
    $r = ref($r) eq __PACKAGE__ ? $$r : _star2obj($r);

    bless \__div__(__sub__(__pow__($r, __add__($n, 1)), 1), __sub__($r, 1));
}

#
## Faulhaber's summation formula
## https://en.wikipedia.org/wiki/Faulhaber%27s_formula
#

sub faulhaber_sum ($$) {
    my ($n, $p) = @_;

    $n = _star2mpz($n) // goto &nan;
    $p = _star2ui($p)  // goto &nan;

    if ($p == 0) {
        return bless \$n;
    }

    if ($p == 1 or $p == 3) {
        my $r = Math::GMPz::Rmpz_init();
        Math::GMPz::Rmpz_add_ui($r, $n, 1);
        Math::GMPz::Rmpz_mul($r, $r, $n);
        Math::GMPz::Rmpz_div_2exp($r, $r, 1);
        Math::GMPz::Rmpz_mul($r, $r, $r) if ($p == 3);
        return bless \$r;
    }

    state $z = Math::GMPz::Rmpz_init_nobless();

    if ($p == 2) {    # n*(n+1)*(2*n+1)/6
        my $r = Math::GMPz::Rmpz_init();
        Math::GMPz::Rmpz_add_ui($z, $n, 1);
        Math::GMPz::Rmpz_mul($r, $z, $n);
        Math::GMPz::Rmpz_mul_2exp($z, $z, 1);
        Math::GMPz::Rmpz_sub_ui($z, $z, 1);
        Math::GMPz::Rmpz_mul($r, $r, $z);
        Math::GMPz::Rmpz_divexact_ui($r, $r, 6);
        return bless \$r;
    }

    # When p >= n, sum the powers directly.
    if (Math::GMPz::Rmpz_cmp_ui($n, $p) <= 0) {
        my $r = Math::GMPz::Rmpz_init_set_ui(0);
        foreach my $k (1 .. Math::GMPz::Rmpz_get_ui($n)) {
            Math::GMPz::Rmpz_ui_pow_ui($z, $k, $p);
            Math::GMPz::Rmpz_add($r, $r, $z);
        }
        return bless \$r;
    }

    my @B = _bernoulli_numbers($p);

    my $q = Math::GMPq::Rmpq_init();
    my $u = Math::GMPz::Rmpz_init_set_ui(1);

    my $sum = Math::GMPq::Rmpq_init();
    Math::GMPq::Rmpq_set_ui($sum, 0, 1);

    # Sum_{k=1..n} k^p = 1/(p+1) * Sum_{j=0..p} binomial(p+1, j) * n^(p-j+1) * bernoulli(j)
    #                  = 1/(p+1) * Sum_{j=0..p} binomial(p+1, p-j) * n^(j+1) * bernoulli(p-j)

    foreach my $j (0 .. $p - 2) {

        Math::GMPz::Rmpz_mul($u, $u, $n);

        # Skip when bernoulli(p-j) == 0
        ($p - $j) % 2 == 0 or next;

        Math::GMPz::Rmpz_bin_uiui($z, $p + 1, $p - $j);
        Math::GMPz::Rmpz_mul($z, $z, $u);
        Math::GMPq::Rmpq_mul_z($q, $B[(($p - $j) >> 1) + 1], $z);
        Math::GMPq::Rmpq_add($sum, $sum, $q);
    }

    # sum += (1/2) * n^p * (2*n + p + 1)
    Math::GMPz::Rmpz_mul($u, $u, $n);
    Math::GMPz::Rmpz_mul_2exp($z, $n, 1);
    Math::GMPz::Rmpz_add_ui($z, $z, $p + 1);
    Math::GMPz::Rmpz_mul($u, $u, $z);
    Math::GMPq::Rmpq_set_ui($q, 1, 2);
    Math::GMPq::Rmpq_mul_z($q, $q, $u);
    Math::GMPq::Rmpq_add($sum, $sum, $q);

    # z = sum/(p+1)
    Math::GMPq::Rmpq_get_num($u, $sum);
    Math::GMPz::Rmpz_divexact_ui($u, $u, $p + 1);
    bless \$u;
}

#
## Dirichlet hyperbola method
## https://en.wikipedia.org/wiki/Dirichlet_hyperbola_method
#

sub dirichlet_sum ($$$$$) {
    my ($n, $f, $g, $F, $G) = @_;

    $n = _star2mpz($n) // goto &nan;
    Math::GMPz::Rmpz_sgn($n) > 0 or goto &zero;

    $f //= sub { 1 };
    $g //= sub { 1 };

    $F //= sub { $_[0] };
    $G //= sub { $_[0] };

    my $s = Math::GMPz::Rmpz_init();
    Math::GMPz::Rmpz_sqrt($s, $n);

    my $sum = Math::GMPz::Rmpz_init_set_ui(0);

    my $t = bless \Math::GMPz::Rmpz_init_set_ui(0);
    my $u = bless \Math::GMPz::Rmpz_init_set_ui(0);

    Math::GMPz::Rmpz_fits_slong_p($s) || goto &nan;

    foreach my $k (1 .. Math::GMPz::Rmpz_get_ui($s)) {

        Math::GMPz::Rmpz_set_ui($$t, $k);
        Math::GMPz::Rmpz_div_ui($$u, $n, $k);

        my $f_r = $f->($t);
        my $g_r = $g->($t);
        my $F_r = $F->($u);
        my $G_r = $G->($u);

        $f_r = _star2mpz($f_r) // goto &nan;
        $g_r = _star2mpz($g_r) // goto &nan;
        $F_r = _star2mpz($F_r) // goto &nan;
        $G_r = _star2mpz($G_r) // goto &nan;

        Math::GMPz::Rmpz_addmul($sum, $f_r, $G_r);
        Math::GMPz::Rmpz_addmul($sum, $g_r, $F_r);
    }

    $sum = __sub__($sum, __mul__(_star2mpz($F->(bless \$s)), _star2mpz($G->(bless \$s))));
    bless \$sum;
}

#
## Catalan numbers
#

sub catalan ($;$) {
    my ($n, $k) = @_;

    # Catalan's triangle
    # catalan(n, k) = binomial(n+k, k) - binomial(n+k, k-1)
    if (scalar(@_) == 2) {

        $n = _star2mpz($n) // goto &nan;
        $k = _star2ui($k)  // goto &nan;

        my $t = Math::GMPz::Rmpz_init();
        my $u = Math::GMPz::Rmpz_init();

        Math::GMPz::Rmpz_add_ui($t, $n, $k);
        Math::GMPz::Rmpz_bin_ui($u, $t, $k);
        ($k > 0)
          ? Math::GMPz::Rmpz_bin_ui($t, $t, $k - 1)
          : Math::GMPz::Rmpz_bin_si($t, $t, $k - 1);
        Math::GMPz::Rmpz_sub($u, $u, $t);

        return bless \$u;
    }

    $n = _star2ui($n) // goto &nan;

    my $r = Math::GMPz::Rmpz_init();
    Math::GMPz::Rmpz_bin_uiui($r, $n << 1, $n);
    Math::GMPz::Rmpz_divexact_ui($r, $r, $n + 1);
    bless \$r;
}

#
## Bell numbers
#

sub bell ($) {
    my ($n) = @_;

    $n = _star2ui($n) // goto &nan;

    my @acc;

    my $t    = Math::GMPz::Rmpz_init();
    my $bell = Math::GMPz::Rmpz_init_set_ui(1);

    foreach my $k (1 .. $n) {

        Math::GMPz::Rmpz_set($t, $bell);

        foreach my $item (@acc) {
            Math::GMPz::Rmpz_add($t, $t, $item);
            Math::GMPz::Rmpz_set($item, $t);
        }

        unshift @acc, $bell;
        $bell = Math::GMPz::Rmpz_init_set($acc[-1]);
    }

    bless \$bell;
}

#
## Binomial coefficient
#

sub binomial ($$) {
    my ($n, $k) = @_;

    # `n` and `k` are native unsigned integers
    if (    !ref($n)
        and !ref($k)
        and CORE::int($n) eq $n
        and CORE::int($k) eq $k
        and $n >= 0
        and $k >= 0
        and $n < 1e6
        and $k < ULONG_MAX) {
        my $r = Math::GMPz::Rmpz_init();
        Math::GMPz::Rmpz_bin_uiui($r, $n, $k);
        return bless \$r;
    }

    $n = _star2mpz($n) // goto &nan;
    $k = _star2si($k)  // goto &nan;

    my $r = Math::GMPz::Rmpz_init();

    if ($k >= 0 and Math::GMPz::Rmpz_fits_ulong_p($n) and Math::GMPz::Rmpz_cmp_ui($n, 1e6) <= 0) {
        Math::GMPz::Rmpz_bin_uiui($r, Math::GMPz::Rmpz_get_ui($n), $k);
    }
    else {
        $k < 0
          ? Math::GMPz::Rmpz_bin_si($r, $n, $k)
          : Math::GMPz::Rmpz_bin_ui($r, $n, $k);
    }

    bless \$r;
}

#
## Multinomial coefficient
#

sub multinomial {
    my ($n, @mset) = @_;

    $n = _star2mpz($n) // goto &nan;

    my $bin  = Math::GMPz::Rmpz_init();
    my $sum  = Math::GMPz::Rmpz_init_set($n);
    my $prod = Math::GMPz::Rmpz_init_set_ui(1);

    foreach my $k (@mset) {

        $k = _star2si($k) // goto &nan;

        $k < 0
          ? Math::GMPz::Rmpz_sub_ui($sum, $sum, -$k)
          : Math::GMPz::Rmpz_add_ui($sum, $sum, $k);

        if ($k >= 0 and Math::GMPz::Rmpz_fits_ulong_p($sum)) {
            Math::GMPz::Rmpz_bin_uiui($bin, Math::GMPz::Rmpz_get_ui($sum), $k);
        }
        else {
            $k < 0
              ? Math::GMPz::Rmpz_bin_si($bin, $sum, $k)
              : Math::GMPz::Rmpz_bin_ui($bin, $sum, $k);
        }

        Math::GMPz::Rmpz_mul($prod, $prod, $bin);
    }

    bless \$prod;
}

#
## AND
#

sub and {    # used in overloading
    my ($n, $k) = @_;

    $n = _star2mpz($n) // goto &nan;
    $k = _star2mpz($k) // goto &nan;

    my $r = Math::GMPz::Rmpz_init();
    Math::GMPz::Rmpz_and($r, $n, $k);
    bless \$r;
}

#
## OR
#

sub or {    # used in overloading
    my ($n, $k) = @_;

    $n = _star2mpz($n) // goto &nan;
    $k = _star2mpz($k) // goto &nan;

    my $r = Math::GMPz::Rmpz_init();
    Math::GMPz::Rmpz_ior($r, $n, $k);
    bless \$r;
}

#
## XOR
#

sub xor {    # used in overloading
    my ($n, $k) = @_;

    $n = _star2mpz($n) // goto &nan;
    $k = _star2mpz($k) // goto &nan;

    my $r = Math::GMPz::Rmpz_init();
    Math::GMPz::Rmpz_xor($r, $n, $k);
    bless \$r;
}

#
## NOT
#

sub not {    # used in overloading
    my ($n) = @_;

    $n = _star2mpz($n) // goto &nan;

    my $r = Math::GMPz::Rmpz_init();
    Math::GMPz::Rmpz_com($r, $n);
    bless \$r;
}

#
## Get k-th bit of integer `n`
#

sub getbit ($$) {
    my ($n, $k) = @_;

    $n = _star2mpz($n) // return undef;
    $k = _star2ui($k)  // return undef;

    Math::GMPz::Rmpz_tstbit($n, $k);
}

#
## Set k-th bit of integer `n` to 1
#

sub setbit ($$) {
    my ($n, $k) = @_;

    $n = _star2mpz($n) // return undef;
    $k = _star2ui($k)  // return undef;

    my $r = Math::GMPz::Rmpz_init_set($n);
    Math::GMPz::Rmpz_setbit($r, $k);
    bless \$r;
}

#
## FLIP-BIT (XOR)
#

sub flipbit ($$) {
    my ($n, $k) = @_;

    $n = _star2mpz($n) // goto &nan;
    $k = _star2ui($k)  // goto &nan;

    my $r = Math::GMPz::Rmpz_init_set($n);

    Math::GMPz::Rmpz_tstbit($r, $k)
      ? Math::GMPz::Rmpz_clrbit($r, $k)
      : Math::GMPz::Rmpz_setbit($r, $k);

    bless \$r;
}

#
## CLEAR BIT (set bit $y to 0)
#

sub clearbit ($$) {
    my ($n, $k) = @_;

    $n = _star2mpz($n) // goto &nan;
    $k = _star2ui($k)  // goto &nan;

    my $r = Math::GMPz::Rmpz_init_set($n);
    Math::GMPz::Rmpz_clrbit($r, $k);
    bless \$r;
}

#
## Scan n starting from bit index k, towards more
## significant bits, until the first 0 is found.
#

sub bit_scan0 ($;$) {
    my ($n, $k) = @_;

    $n = _star2mpz($n) // return undef;

    if (defined($k)) {
        $k = _star2ui($k) // return undef;
    }
    else {
        $k = 0;
    }

    Math::GMPz::Rmpz_scan0($n, $k);
}

#
## Scan n starting from bit index k, towards more
## significant bits, until the first 1 is found.
#

sub bit_scan1 ($;$) {
    my ($n, $k) = @_;

    $n = _star2mpz($n) // return undef;

    if (defined($k)) {
        $k = _star2ui($k) // return undef;
    }
    else {
        $k = 0;
    }

    Math::GMPz::Rmpz_scan1($n, $k);
}

#
## LEFT SHIFT
#

sub lsft {    # used in overloading
    my ($n, $k) = @_;

    $n = _star2mpz($n) // goto &nan;
    $k = _star2si($k)  // goto &nan;

    my $r = Math::GMPz::Rmpz_init();

    $k < 0
      ? Math::GMPz::Rmpz_div_2exp($r, $n, -$k)
      : Math::GMPz::Rmpz_mul_2exp($r, $n, CORE::int($k));

    bless \$r;
}

#
## RIGHT SHIFT
#

sub rsft {    # used in overloading
    my ($n, $k) = @_;

    $n = _star2mpz($n) // goto &nan;
    $k = _star2si($k)  // goto &nan;

    my $r = Math::GMPz::Rmpz_init();

    $k < 0
      ? Math::GMPz::Rmpz_mul_2exp($r, $n, -$k)
      : Math::GMPz::Rmpz_div_2exp($r, $n, CORE::int($k));

    bless \$r;
}

#
## Population count: number of 1's in the binary representation of `n`
#

sub popcount ($) {
    my ($n) = @_;

    $n = _star2mpz($n) // return undef;

    if (Math::GMPz::Rmpz_sgn($n) < 0) {
        $n = Math::GMPz::Rmpz_init_set($n);
        Math::GMPz::Rmpz_neg($n, $n);
    }

    Math::GMPz::Rmpz_popcount($n);
}

#
## Hamming distance
#

sub hamdist ($$) {
    my ($n, $k) = @_;

    $n = _star2mpz($n) // return undef;
    $k = _star2mpz($k) // return undef;

    Math::GMPz::Rmpz_hamdist($n, $k);
}

#
## Conversions
#

sub as_bin ($) {
    my ($n) = @_;
    $n = _star2mpz($n) // return undef;
    Math::GMPz::Rmpz_get_str($n, 2);
}

sub as_oct ($) {
    my ($n) = @_;
    $n = _star2mpz($n) // return undef;
    Math::GMPz::Rmpz_get_str($n, 8);
}

sub as_hex ($) {
    my ($n) = @_;
    $n = _star2mpz($n) // return undef;
    Math::GMPz::Rmpz_get_str($n, 16);
}

sub as_int ($;$) {
    my ($n, $k) = @_;

    my $base = 10;
    if (defined($k)) {

        $base = _star2ui($k) // 0;

        if ($base < 2 or $base > 62) {
            require Carp;
            Carp::croak("base must be between 2 and 62, got $k");
        }
    }

    $n = _star2mpz($n) // return undef;
    Math::GMPz::Rmpz_get_str($n, $base);
}

sub __as_rat__ {
    my ($n, $k) = @_;

    $n = ref($n) eq __PACKAGE__ ? $$n : _star2obj($n);

    my $base = 10;
    if (defined($k)) {

        $base = _star2ui($k) // 0;

        if ($base < 2 or $base > 62) {
            require Carp;
            Carp::croak("base must be between 2 and 62, got $k");
        }
    }

    my $ref = ref($n);
    if ($ref eq 'Math::GMPq' or $ref eq 'Math::GMPz') {
        return (
                $ref eq 'Math::GMPq'
                ? Math::GMPq::Rmpq_get_str($n, $base)
                : Math::GMPz::Rmpz_get_str($n, $base)
               );
    }

    $n = _any2mpq($n) // return undef;
    Math::GMPq::Rmpq_get_str($n, $base);
}

sub as_rat ($;$) {
    my ($n, $k) = @_;
    __as_rat__($n, $k) // return undef;
}

sub as_frac ($;$) {
    my ($n, $k) = @_;
    my $rat = __as_rat__($n, $k) // return undef;
    $rat .= '/1' if (index($rat, '/') == -1);
    $rat;
}

sub as_dec ($;$) {
    my ($n, $d) = @_;

    my $prec = $PREC;
    if (defined($d)) {

        $prec = _star2ui($d) // 0;
        $prec <<= 2;

        state $min_prec = Math::MPFR::RMPFR_PREC_MIN();
        state $max_prec = Math::MPFR::RMPFR_PREC_MAX();

        if ($prec < $min_prec or $prec > $max_prec) {
            require Carp;
            Carp::croak("precision must be between $min_prec and $max_prec, got ", $prec);
        }
    }

    local $PREC = $prec;
    __stringify__(_star2mpfr_mpc($n));
}

sub __base__ {
    my ($x, $base) = @_;
    goto(ref($x) =~ tr/:/_/rs);

  Math_GMPz: {
        return Math::GMPz::Rmpz_get_str($x, $base);
    }

  Math_GMPq: {
        return Math::GMPq::Rmpq_get_str($x, $base);
    }

  Math_MPFR: {
        return Math::MPFR::Rmpfr_get_str($x, $base, 0, $ROUND);
    }

  Math_MPC: {

        # return Math::MPC::Rmpc_get_str($base, 0, $x, $ROUND);       # not OK

        my $fr = Math::MPFR::Rmpfr_init2(CORE::int($PREC));
        Math::MPC::RMPC_RE($fr, $x);
        my $real = __base__($fr, $base);
        Math::MPC::RMPC_IM($fr, $x);
        return $real if Math::MPFR::Rmpfr_zero_p($fr);
        my $imag = __base__($fr, $base);
        return "($real $imag)";
    }
}

sub base {
    my ($n, $k) = @_;

    $n = ref($n) eq __PACKAGE__ ? $$n : _star2obj($n);

    my $base = 10;
    if (defined($k)) {

        $base = _star2ui($k) // 0;

        if ($base < 2 or $base > 62) {
            require Carp;
            Carp::croak("base must be between 2 and 62, got $k");
        }
    }

    __base__($n, $base);
}

sub rat_approx ($) {
    my ($x) = @_;

    $x = _star2mpfr($x);

    Math::MPFR::Rmpfr_number_p($x) || goto &nan;

    my $n1 = Math::GMPz::Rmpz_init_set_ui(0);
    my $n2 = Math::GMPz::Rmpz_init_set_ui(1);

    my $d1 = Math::GMPz::Rmpz_init_set_ui(1);
    my $d2 = Math::GMPz::Rmpz_init_set_ui(0);

    my $q = Math::GMPq::Rmpq_init();
    my $z = Math::GMPz::Rmpz_init();

    my $s = __stringify__($x);

    my $f1 = Math::MPFR::Rmpfr_init2($PREC);
    my $f2 = Math::MPFR::Rmpfr_init2($PREC);
    my $f3 = Math::MPFR::Rmpfr_init2($PREC);

    Math::MPFR::Rmpfr_set($f1, $x, $ROUND);

    while (1) {
        Math::MPFR::Rmpfr_floor($f2, $f1);
        Math::MPFR::Rmpfr_get_z($z, $f2, $ROUND);

        Math::GMPz::Rmpz_addmul($n1, $n2, $z);    # n1 += n2 * z
        Math::GMPz::Rmpz_addmul($d1, $d2, $z);    # d1 += d2 * z

        ($n1, $n2) = ($n2, $n1);
        ($d1, $d2) = ($d2, $d1);

        # q = n2 / d2
        Math::GMPq::Rmpq_set_num($q, $n2);
        Math::GMPq::Rmpq_set_den($q, $d2);
        Math::GMPq::Rmpq_canonicalize($q);

        Math::MPFR::Rmpfr_set_q($f3, $q, $ROUND);
        CORE::index(__stringify__($f3), $s) == 0 and last;

        # f1 = 1 / (f1 - f2)
        Math::MPFR::Rmpfr_sub($f1, $f1, $f2, $ROUND);
        Math::MPFR::Rmpfr_zero_p($f1) && last;
        Math::MPFR::Rmpfr_ui_div($f1, 1, $f1, $ROUND);
    }

    bless \$q;
}

my %DIGITS_36;
@DIGITS_36{0 .. 9, 'a' .. 'z'} = (0 .. 35);

my %DIGITS_62;
@DIGITS_62{0 .. 9, 'A' .. 'Z', 'a' .. 'z'} = (0 .. 61);

sub digits ($;$) {
    my ($n, $k) = @_;

    $n = _star2mpz($n) // return;

    $k //= 10;

    my $sgn = Math::GMPz::Rmpz_sgn($n);

    if ($sgn == 0) {    # n = 0
        return (0);
    }
    elsif ($sgn < 0) {    # n < 0; make it absolute
        $n = Math::GMPz::Rmpz_init_set($n);
        Math::GMPz::Rmpz_abs($n, $n);
    }

    if (!ref($k) and CORE::int($k) eq $k and $k > 1 and $k < ULONG_MAX) {
        return if ($k <= 1);    # not defined for k <= 1
    }
    else {
        $k = _star2mpz($k) // return;
        return if (Math::GMPz::Rmpz_cmp_ui($k, 1) <= 0);    # not defined for k <= 1
    }

    # Return faster for k=2..62
    if (ref($k) ? (Math::GMPz::Rmpz_cmp_ui($k, 62) <= 0) : ($k <= 62)) {
        $k = Math::GMPz::Rmpz_get_ui($k) if ref($k);
        return map { $k <= 36 ? $DIGITS_36{$_} : $DIGITS_62{$_} }
          split(//, scalar reverse scalar(Math::GMPz::Rmpz_get_str($n, $k)));
    }

    # Subquadratic algorithm from "Modern Computer Arithmetic" by Richard P. Brent and Paul Zimmermann
    if (!ref($k) || Math::GMPz::Rmpz_fits_ulong_p($k)) {

        my $A = $n;
        my $B = ref($k) ? Math::GMPz::Rmpz_get_ui($k) : $k;

        # Find r such that B^(2r - 2) <= A < B^(2r)
        my $r = (__ilog__($A, $B) >> 1) + 1;

        state $Q = Math::GMPz::Rmpz_init_nobless();
        state $R = Math::GMPz::Rmpz_init_nobless();

        return sub {
            my ($A, $r) = @_;

            # Cut the recursion early
            if (Math::GMPz::Rmpz_fits_ulong_p($A)) {
                my $v = Math::GMPz::Rmpz_init_set($A);
                my $m = Math::GMPz::Rmpz_init();

                my @digits;
                while (Math::GMPz::Rmpz_sgn($v)) {
                    push @digits, Math::GMPz::Rmpz_divmod_ui($v, $m, $v, $B);
                }
                return @digits;
            }

            #~ if (Math::GMPz::Rmpz_cmp_ui($A, $B) < 0) {
            #~ return Math::GMPz::Rmpz_get_ui($A);
            #~ }

            my $t = Math::GMPz::Rmpz_init();
            Math::GMPz::Rmpz_ui_pow_ui($t, $B, 2 * ($r - 1));    # can this be optimized away?

            if (Math::GMPz::Rmpz_cmp($t, $A) > 0) {
                --$r;
            }

            Math::GMPz::Rmpz_ui_pow_ui($t, $B, $r);
            Math::GMPz::Rmpz_divmod($Q, $R, $A, $t);

            my $w = ($r + 1) >> 1;
            Math::GMPz::Rmpz_set($t, $Q);

            my @right = __SUB__->($R, $w);
            my @left  = __SUB__->($t, $w);

            (@right, (0) x ($r - scalar(@right)), @left);
          }
          ->($A, $r);
    }

    # This algorithm will be used only when base > ULONG_MAX
    my @digits;

    $n = Math::GMPz::Rmpz_init_set($n);    # copy

    while (Math::GMPz::Rmpz_sgn($n) > 0) {
        my $m = Math::GMPz::Rmpz_init();
        Math::GMPz::Rmpz_divmod($n, $m, $n, $k);
        push @digits, bless \$m;
    }

    return @digits;
}

sub sumdigits ($;$) {
    my ($n, $k) = @_;

    $n = _star2mpz($n) // goto &nan;

    $k //= 10;

    my $sgn = Math::GMPz::Rmpz_sgn($n);

    if ($sgn == 0) {    # n = 0
        goto &zero;
    }
    elsif ($sgn < 0) {    # n < 0; make it absolute
        $n = Math::GMPz::Rmpz_init_set($n);
        Math::GMPz::Rmpz_abs($n, $n);
    }

    if (!ref($k) and CORE::int($k) eq $k and $k > 1 and $k < ULONG_MAX) {
        goto &nan if ($k <= 1);    # not defined for k <= 1
    }
    else {
        $k = _star2mpz($k) // goto &nan;
        goto &nan if (Math::GMPz::Rmpz_cmp_ui($k, 1) <= 0);    # not defined for k <= 1
    }

    # Return faster for k=2..62
#<<<
    if (ref($k) ? (Math::GMPz::Rmpz_cmp_ui($k, 62) <= 0) : ($k <= 62)) {
        $k = Math::GMPz::Rmpz_get_ui($k) if ref($k);

        return bless \Math::GMPz::Rmpz_init_set_ui(Math::GMPz::Rmpz_popcount($n)) if $k == 2;

        if (Math::GMPz::Rmpz_sizeinbase($n, $k) <= 1e6) {
            return bless \Math::GMPz::Rmpz_init_set_ui(List::Util::sum(map { $k <= 36 ? $DIGITS_36{$_} : $DIGITS_62{$_} } split(//, Math::GMPz::Rmpz_get_str($n, $k))));
        }
    }
#>>>

    # Subquadratic algorithm from "Modern Computer Arithmetic" by Richard P. Brent and Paul Zimmermann
    if (!ref($k) || Math::GMPz::Rmpz_fits_ulong_p($k)) {

        my $A = $n;
        my $B = ref($k) ? Math::GMPz::Rmpz_get_ui($k) : $k;

        # Find r such that B^(2r - 2) <= A < B^(2r)
        my $r = (__ilog__($A, $B) >> 1) + 1;

        state $Q = Math::GMPz::Rmpz_init_nobless();
        state $R = Math::GMPz::Rmpz_init_nobless();

        my $total = sub {
            my ($A, $r) = @_;

            # Cut the recursion early
            if (Math::GMPz::Rmpz_fits_ulong_p($A)) {
                my $v = Math::GMPz::Rmpz_init_set($A);
                my $m = Math::GMPz::Rmpz_init();

                my $sum = 0;
                while (Math::GMPz::Rmpz_sgn($v)) {
                    $sum += Math::GMPz::Rmpz_divmod_ui($v, $m, $v, $B);
                }
                return $sum;
            }

            #~ if (Math::GMPz::Rmpz_cmp_ui($A, $B) < 0) {
            #~ return Math::GMPz::Rmpz_get_ui($A);
            #~ }

            my $w = ($r + 1) >> 1;
            my $t = Math::GMPz::Rmpz_init();

            Math::GMPz::Rmpz_ui_pow_ui($t, $B, $r);
            Math::GMPz::Rmpz_divmod($Q, $R, $A, $t);
            Math::GMPz::Rmpz_set($t, $Q);

            __SUB__->($R, $w) + __SUB__->($t, $w);
          }
          ->($A, $r);

        ($total < ULONG_MAX)
          && return bless \Math::GMPz::Rmpz_init_set_ui($total);
    }

    # This algorithm will be used only for very large bases,
    # base > ULONG_MAX, or when the sum of digits exceeds ULONG_MAX.
    $k = Math::GMPz::Rmpz_init_set_ui($k) if !ref($k);
    $n = Math::GMPz::Rmpz_init_set($n);                  # copy

    my $m   = Math::GMPz::Rmpz_init();
    my $sum = Math::GMPz::Rmpz_init_set_ui(0);

    while (Math::GMPz::Rmpz_sgn($n) > 0) {
        Math::GMPz::Rmpz_divmod($n, $m, $n, $k);
        Math::GMPz::Rmpz_add($sum, $sum, $m);
    }

    bless \$sum;
}

my %FROM_DIGITS_36;
@FROM_DIGITS_36{0 .. 35} = (0 .. 9, 'a' .. 'z');

my %FROM_DIGITS_62;
@FROM_DIGITS_62{0 .. 61} = (0 .. 9, 'A' .. 'Z', 'a' .. 'z');

sub digits2num {
    my ($digits, $base) = @_;

    ref($digits) eq 'ARRAY' or goto &nan;

    $base //= 10;

    if ($base <= 1) {
        goto &nan;
    }

    @$digits || goto &zero;

#<<<
    if ($base <= 62) {
        $base = ref($base) ? Math::GMPz::Rmpz_get_ui(_star2mpz($base) // goto &nan) : CORE::int($base);
        return bless \Math::GMPz::Rmpz_init_set_str(scalar reverse(join('', map { ($base <= 36 ? $FROM_DIGITS_36{$_} : $FROM_DIGITS_62{$_}) // goto &nan } @$digits)), $base);
    }
#>>>

    if (!ref($base) and CORE::int($base) eq $base and $base > 1 and $base < ULONG_MAX) {
        $base = Math::GMPz::Rmpz_init_set_ui($base);
    }
    else {
        $base = Math::GMPz::Rmpz_init_set(_star2mpz($base) // goto &nan);
    }

    my @digits = map {
        (!ref($_) and CORE::int($_) eq $_ and $_ >= 0 and $_ < ULONG_MAX)
          ? Math::GMPz::Rmpz_init_set_ui($_)
          : Math::GMPz::Rmpz_init_set(_star2mpz($_) // goto &nan);
    } @$digits;

    my $L = \@digits;

    # Algorithm from "Modern Computer Arithmetic"
    #       by Richard P. Brent and Paul Zimmermann

    for (my $k = scalar(@digits) ; $k > 1 ; $k = ($k >> 1) + ($k & 1)) {

        my @T;
        for (0 .. ($k >> 1) - 1) {
            Math::GMPz::Rmpz_addmul($L->[$_ << 1], $L->[($_ << 1) + 1], $base);
            push @T, $L->[$_ << 1];
        }

        push(@T, $L->[-1]) if ($k & 1);
        $L = \@T;
        Math::GMPz::Rmpz_mul($base, $base, $base);
    }

    bless \($L->[0]);
}

sub bsearch ($$;$) {
    my ($left, $right, $block) = @_;

    if (@_ == 3) {
        $left  = Math::GMPz::Rmpz_init_set(_star2mpz($left)  // return undef);
        $right = Math::GMPz::Rmpz_init_set(_star2mpz($right) // return undef);
    }
    else {
        $block = $right;
        $right = Math::GMPz::Rmpz_init_set(_star2mpz($left) // return undef);
        $left  = Math::GMPz::Rmpz_init_set_ui(0);
    }

    my $middle = Math::GMPz::Rmpz_init();

    while (Math::GMPz::Rmpz_cmp($left, $right) <= 0) {

        Math::GMPz::Rmpz_add($middle, $left, $right);
        Math::GMPz::Rmpz_div_2exp($middle, $middle, 1);

        my $cmp = do {
            local $_ = bless \Math::GMPz::Rmpz_init_set($middle);
            $block->($_) || return $_;
        };

        if ($cmp > 0) {
            Math::GMPz::Rmpz_sub_ui($right, $middle, 1);
        }
        else {
            Math::GMPz::Rmpz_add_ui($left, $middle, 1);
        }
    }

    return undef;
}

sub bsearch_ge ($$;$) {
    my ($left, $right, $block) = @_;

    if (@_ == 3) {
        $left  = Math::GMPz::Rmpz_init_set(_star2mpz($left)  // return undef);
        $right = Math::GMPz::Rmpz_init_set(_star2mpz($right) // return undef);
    }
    else {
        $block = $right;
        $right = Math::GMPz::Rmpz_init_set(_star2mpz($left) // return undef);
        $left  = Math::GMPz::Rmpz_init_set_ui(0);
    }

    my $middle = Math::GMPz::Rmpz_init();

    while (1) {

        Math::GMPz::Rmpz_add($middle, $left, $right);
        Math::GMPz::Rmpz_div_2exp($middle, $middle, 1);

        my $cmp = do {
            local $_ = bless \Math::GMPz::Rmpz_init_set($middle);
            $block->($_) || return $_;
        };

        if ($cmp < 0) {
            Math::GMPz::Rmpz_add_ui($left, $middle, 1);

            if (Math::GMPz::Rmpz_cmp($left, $right) > 0) {
                Math::GMPz::Rmpz_add_ui($middle, $middle, 1);
                last;
            }
        }
        else {
            Math::GMPz::Rmpz_sub_ui($right, $middle, 1);
            Math::GMPz::Rmpz_cmp($left, $right) > 0 and last;
        }
    }

    bless \$middle;
}

sub bsearch_le ($$;$) {
    my ($left, $right, $block) = @_;

    if (@_ == 3) {
        $left  = Math::GMPz::Rmpz_init_set(_star2mpz($left)  // return undef);
        $right = Math::GMPz::Rmpz_init_set(_star2mpz($right) // return undef);
    }
    else {
        $block = $right;
        $right = Math::GMPz::Rmpz_init_set(_star2mpz($left) // return undef);
        $left  = Math::GMPz::Rmpz_init_set_ui(0);
    }

    my $middle = Math::GMPz::Rmpz_init();

    while (1) {

        Math::GMPz::Rmpz_add($middle, $left, $right);
        Math::GMPz::Rmpz_div_2exp($middle, $middle, 1);

        my $cmp = do {
            local $_ = bless \Math::GMPz::Rmpz_init_set($middle);
            $block->($_) || return $_;
        };

        if ($cmp < 0) {
            Math::GMPz::Rmpz_add_ui($left, $middle, 1);
            Math::GMPz::Rmpz_cmp($left, $right) > 0 and last;
        }
        else {
            Math::GMPz::Rmpz_sub_ui($right, $middle, 1);
            if (Math::GMPz::Rmpz_cmp($left, $right) > 0) {
                Math::GMPz::Rmpz_sub_ui($middle, $middle, 1);
                last;
            }
        }
    }

    bless \$middle;
}

1;    # End of Math::AnyNum
