package Math::AnyNum;

use 5.014;
use strict;
use warnings;

no warnings qw(numeric uninitialized);

use Math::MPFR qw();
use Math::GMPq qw();
use Math::GMPz qw();
use Math::MPC qw();

use constant {
              ULONG_MAX => Math::GMPq::_ulong_max(),
              LONG_MIN  => Math::GMPq::_long_min(),
             };

our $VERSION = '0.22';
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
                  e       => \&e,
                  phi     => \&phi,
                  tau     => \&tau,
                  pi      => \&pi,
                  ln2     => \&ln2,
                  euler   => \&euler,
                  i       => \&i,
                  catalan => \&catalan,
                  Inf     => \&inf,
                  NaN     => \&nan,
                );

    my %trig = (
        sin => sub (_) { goto &sin },    # built-in function
        sinh  => \&sinh,
        asin  => \&asin,
        asinh => \&asinh,

        cos => sub (_) { goto &cos },    # built-in function
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

        exp => sub (_) { goto &exp },      # built-in function
        exp2  => \&exp2,
        exp10 => \&exp10,

        ln => sub ($) { goto &ln },        # used in overloading
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

        bernreal => \&bernreal,
        harmreal => \&harmreal,

        polygonal_root  => \&polygonal_root,
        polygonal_root2 => \&polygonal_root2,
                  );

    my %ntheory = (
        factorial    => \&factorial,
        dfactorial   => \&dfactorial,
        mfactorial   => \&mfactorial,
        subfactorial => \&subfactorial,
        primorial    => \&primorial,
        binomial     => \&binomial,
        multinomial  => \&multinomial,

        rising_factorial  => \&rising_factorial,
        falling_factorial => \&falling_factorial,

        lucas     => \&lucas,
        fibonacci => \&fibonacci,

        faulhaber_sum => \&faulhaber_sum,

        bernfrac => \&bernfrac,
        harmfrac => \&harmfrac,

        lcm       => \&lcm,
        gcd       => \&gcd,
        valuation => \&valuation,
        kronecker => \&kronecker,

        remdiv => \&remdiv,
        divmod => \&divmod,

        iadd => \&iadd,
        isub => \&isub,
        imul => \&imul,
        idiv => \&idiv,
        imod => \&imod,

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

        is_power      => \&is_power,
        is_square     => \&is_square,
        is_polygonal  => \&is_polygonal,
        is_polygonal2 => \&is_polygonal2,

        is_prime   => \&is_prime,
        is_coprime => \&is_coprime,
        is_smooth  => \&is_smooth,
        next_prime => \&next_prime,
                  );

    my %misc = (
        rand  => \&rand,
        irand => \&irand,

        seed  => \&seed,
        iseed => \&iseed,

        floor => \&floor,
        ceil  => \&ceil,
        round => \&round,
        sgn   => \&sgn,
        acmp  => \&acmp,

        popcount => \&popcount,

        neg => sub ($) { goto &neg },    # used in overloading
        inv => \&inv,
        conj  => \&conj,
        real  => \&real,
        imag  => \&imag,
        reals => \&reals,

        int => sub (_) { goto &int },    # built-in function
        rat => \&rat,
        float   => \&float,
        complex => \&complex,

        numerator   => \&numerator,
        denominator => \&denominator,
        nude        => \&nude,

        digits => \&digits,

        as_bin  => \&as_bin,
        as_hex  => \&as_hex,
        as_oct  => \&as_oct,
        as_int  => \&as_int,
        as_frac => \&as_frac,
        as_dec  => \&as_dec,

        rat_approx => \&rat_approx,

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

        is_odd  => \&is_odd,
        is_even => \&is_even,
        is_div  => \&is_div,
               );

    sub import {
        shift;

        my $caller = caller(0);

        while (@_) {
            my $name = shift(@_);

            if ($name eq ':overload') {
                overload::constant
                  integer => sub { bless \Math::GMPz::Rmpz_init_set_ui($_[0]) },
                  float   => sub { bless \_str2obj($_[0]) },
                  binary  => sub {
                    my $const = ($_[0] =~ tr/_//dr);
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
                $s < 0
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
        if (Math::MPFR::Rmpfr_set_str($r, $s, 10, $ROUND)) {
            Math::MPFR::Rmpfr_set_nan($r);
        }
        return $r;
    }

    # Remove the plus sign
    $s =~ s/^\+//;

    # Fraction
    if (index($s, '/') != -1 and $s =~ m{^\s*[-+]?[0-9]+\s*/\s*[-+]?[1-9]+[0-9]*\s*\z}) {
        my $r = Math::GMPq::Rmpq_init();
        Math::GMPq::Rmpq_set_str($r, $s, 10);
        Math::GMPq::Rmpq_canonicalize($r);
        return $r;
    }

    # Integer
    eval { Math::GMPz::Rmpz_init_set_str($s, 10) } // goto &_nan;
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

    (@_) = _any2mpfr($x);
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

    (@_) = _any2mpfr($x);
    goto &_any2mpq;
}

sub _any2ui {
    my ($x) = @_;
    goto(ref($x) =~ tr/:/_/rs);

  Math_GMPz: {

        if (Math::GMPz::Rmpz_fits_ulong_p($x)) {
            goto &Math::GMPz::Rmpz_get_ui;
        }

        return;
    }

  Math_GMPq: {

        if (Math::GMPq::Rmpq_integer_p($x)) {
            @_ = ($x = _mpq2mpz($x));
            goto Math_GMPz;
        }

        my $d = CORE::int(Math::GMPq::Rmpq_get_d($x));
        return (($d < 0 or $d > ULONG_MAX) ? undef : $d);
    }

  Math_MPFR: {

        if (Math::MPFR::Rmpfr_integer_p($x) and Math::MPFR::Rmpfr_fits_ulong_p($x, $ROUND)) {
            push @_, $ROUND;
            goto &Math::MPFR::Rmpfr_get_ui;
        }

        if (Math::MPFR::Rmpfr_number_p($x)) {
            my $d = CORE::int(Math::MPFR::Rmpfr_get_d($x, $ROUND));
            return (($d < 0 or $d > ULONG_MAX) ? undef : $d);
        }

        return;
    }

  Math_MPC: {
        @_ = ($x = _any2mpfr($x));
        goto Math_MPFR;
    }
}

sub _any2si {
    my ($x) = @_;
    goto(ref($x) =~ tr/:/_/rs);

  Math_GMPz: {

        if (Math::GMPz::Rmpz_fits_slong_p($x)) {
            goto &Math::GMPz::Rmpz_get_si;
        }

        if (Math::GMPz::Rmpz_fits_ulong_p($x)) {
            goto &Math::GMPz::Rmpz_get_ui;
        }

        return;
    }

  Math_GMPq: {

        if (Math::GMPq::Rmpq_integer_p($x)) {
            @_ = ($x = _mpq2mpz($x));
            goto Math_GMPz;
        }

        my $d = CORE::int(Math::GMPq::Rmpq_get_d($x));
        return (($d < LONG_MIN or $d > ULONG_MAX) ? undef : $d);
    }

  Math_MPFR: {

        if (Math::MPFR::Rmpfr_integer_p($x)) {
            if (Math::MPFR::Rmpfr_fits_slong_p($x, $ROUND)) {
                push @_, $ROUND;
                goto &Math::MPFR::Rmpfr_get_si;
            }

            if (Math::MPFR::Rmpfr_fits_ulong_p($x, $ROUND)) {
                push @_, $ROUND;
                goto &Math::MPFR::Rmpfr_get_ui;
            }
        }

        if (Math::MPFR::Rmpfr_number_p($x)) {
            my $d = CORE::int(Math::MPFR::Rmpfr_get_d($x, $ROUND));
            return (($d < LONG_MIN or $d > ULONG_MAX) ? undef : $d);
        }

        return;
    }

  Math_MPC: {
        @_ = ($x = _any2mpfr($x));
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

    (@_) = $x;
    ref($x) eq 'Math::GMPz' && goto &_mpz2mpfr;
    ref($x) eq 'Math::GMPq' && goto &_mpq2mpfr;
    goto &_any2mpfr;
}

#
## Anything to GMPz (including strings)
#
sub _star2mpz {
    my ($x) = @_;

    $x =
        ref($x) eq __PACKAGE__ ? $$x
      : ref($x)                ? _star2obj($x)
      :                          _str2obj($x);

    ref($x) eq 'Math::GMPz' and return $x;

    (@_) = $x;
    ref($x) eq 'Math::GMPq' and goto &_mpq2mpz;
    goto &_any2mpz;
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

    (@_) = $x;
    ref($x) eq 'Math::GMPz' && goto &_mpz2mpfr;
    ref($x) eq 'Math::GMPq' && goto &_mpq2mpfr;
    goto &_any2mpfr;    # this should not happen
}

# Anything to a {GMP*, MPFR or MPC} object
sub _star2obj {
    my ($x) = @_;

    ref($x) || goto &_str2obj;

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
        (@_) = "$x";
        goto &_str2obj;
    }
}

sub new {
    my ($class, $num, $base) = @_;

    my $ref = ref($num);

    # Special string values
    if (!$ref and (!defined($base) or CORE::int($base) == 10)) {
        return bless \_str2obj($num), $class;
    }

    # Special case
    if (!defined($base) and $ref eq __PACKAGE__) {
        return $num;
    }

    # Number with base
    if (defined($base) and CORE::int($base) != 10) {

        my $int_base = CORE::int($base);

        if ($int_base < 2 or $int_base > 36) {
            require Carp;
            Carp::croak("base must be between 2 and 36, got $base");
        }

        $num = defined($num) ? "$num" : '0';

        if (index($num, '/') != -1) {
            my $r = Math::GMPq::Rmpq_init();
            eval { Math::GMPq::Rmpq_set_str($r, $num, $int_base); 1 } // goto &nan;

            if (Math::GMPq::Rmpq_get_str($r, 10) !~ m{^\s*[-+]?[0-9]+\s*(?:/\s*[-+]?[1-9]+[0-9]*\s*)?\z}) {
                goto &nan;
            }

            Math::GMPq::Rmpq_canonicalize($r);
            return bless \$r, $class;
        }
        elsif (index($num, '.') != -1) {
            my $r = Math::MPFR::Rmpfr_init2($PREC);
            if (Math::MPFR::Rmpfr_set_str($r, $num, $int_base, $ROUND)) {
                Math::MPFR::Rmpfr_set_nan($r);
            }
            return bless \$r, $class;
        }
        else {
            return bless \(eval { Math::GMPz::Rmpz_init_set_str($num, $int_base) } // goto &nan), $class;
        }
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
    bless \Math::GMPz::Rmpz_init_set_str($str, $base // 10), $class;
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
    Math::MPFR::Rmpfr_set_str($r, $str, $base // 10, $ROUND);
    bless \$r, $class;
}

sub new_c {
    my ($class, $real, $imag, $base) = @_;

    my $c = Math::MPC::Rmpc_init2($PREC);

    if (defined($imag)) {
        my $re = Math::MPFR::Rmpfr_init2($PREC);
        my $im = Math::MPFR::Rmpfr_init2($PREC);

        Math::MPFR::Rmpfr_set_str($re, $real, $base // 10, $ROUND);
        Math::MPFR::Rmpfr_set_str($im, $imag, $base // 10, $ROUND);

        Math::MPC::Rmpc_set_fr_fr($c, $re, $im, $ROUND);
    }
    else {
        Math::MPC::Rmpc_set_str($c, $real, $base // 10, $ROUND);
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

sub euler {
    my $euler = Math::MPFR::Rmpfr_init2($PREC);
    Math::MPFR::Rmpfr_const_euler($euler, $ROUND);
    bless \$euler;
}

sub catalan {
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
## OTHER
#

sub stringify {    # used in overloading
    require Math::AnyNum::stringify;
    (@_) = (${$_[0]});
    goto &__stringify__;
}

sub numify {       # used in overloading
    require Math::AnyNum::numify;
    (@_) = (${$_[0]});
    goto &__numify__;
}

sub boolify {      # used in overloading
    require Math::AnyNum::boolify;
    (@_) = (${$_[0]});
    goto &__boolify__;
}

#
## EQUALITY
#

sub eq {    # used in overloading
    require Math::AnyNum::eq;
    my ($x, $y) = @_;

    if (ref($y) eq __PACKAGE__) {
        (@_) = ($$x, $$y);
        goto &__eq__;
    }

    if (!ref($y)) {
        if (CORE::int($y) eq $y and $y < ULONG_MAX and $y > LONG_MIN) {
            (@_) = ($$x, $y);
        }
        else {
            (@_) = ($$x, _str2obj($y));
        }
        goto &__eq__;
    }

    (@_) = ($$x, _star2obj($y));
    goto &__eq__;
}

#
## INEQUALITY
#

sub ne {    # used in overloading
    require Math::AnyNum::ne;
    my ($x, $y) = @_;

    if (ref($y) eq __PACKAGE__) {
        (@_) = ($$x, $$y);
        goto &__ne__;
    }

    if (!ref($y)) {
        if (CORE::int($y) eq $y and $y < ULONG_MAX and $y > LONG_MIN) {
            (@_) = ($$x, $y);
        }
        else {
            (@_) = ($$x, _str2obj($y));
        }
        goto &__ne__;
    }

    (@_) = ($$x, _star2obj($y));
    goto &__ne__;
}

#
## COMPARISON
#

sub cmp ($$) {
    require Math::AnyNum::cmp;
    my ($x, $y) = @_;

    if (ref($y) eq __PACKAGE__) {
        (@_) = ($$x, $$y);
        goto &__cmp__;
    }

    if (!ref($y)) {
        if (CORE::int($y) eq $y and $y < ULONG_MAX and $y > LONG_MIN) {
            (@_) = ($$x, $y);
        }
        else {
            (@_) = ($$x, _str2obj($y));
        }
        goto &__cmp__;
    }

    (@_) = ($$x, _star2obj($y));
    goto &__cmp__;
}

sub acmp ($$) {
    require Math::AnyNum::abs;
    require Math::AnyNum::cmp;
    my ($x, $y) = @_;

    if (!ref($y) and CORE::int($y) eq $y and $y >= 0 and $y < ULONG_MAX) {
        ## `y` is a native unsigned integer
    }
    else {
        $y = __abs__(ref($y) eq __PACKAGE__ ? $$y : _star2obj($y));
    }

    __cmp__(__abs__(ref($x) eq __PACKAGE__ ? $$x : _star2obj($x)), $y);
}

#
## GREATER THAN
#

sub gt {    # used in overloading
    require Math::AnyNum::cmp;
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
    require Math::AnyNum::cmp;
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
    require Math::AnyNum::cmp;
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
    require Math::AnyNum::cmp;
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

    bless \(
              ref($x) eq __PACKAGE__
            ? ref($$x) eq 'Math::MPFR'
                  ? (return $x)
                  : _any2mpfr($$x)
            : _star2mpfr($x)
           );
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
## NEGATION
#

sub neg {    # used in overloading
    require Math::AnyNum::neg;
    my ($x) = @_;
    bless \__neg__(ref($x) eq __PACKAGE__ ? $$x : _star2obj($x));
}

#
## ABSOLUTE VALUE
#

sub abs {    # used in overloading
    require Math::AnyNum::abs;
    my ($x) = @_;
    bless \__abs__(ref($x) eq __PACKAGE__ ? $$x : _star2obj($x));
}

#
## MULTIPLICATIVE INVERSE
#

sub inv ($) {
    require Math::AnyNum::inv;
    my ($x) = @_;
    bless \__inv__(ref($x) eq __PACKAGE__ ? $$x : _star2obj($x));
}

#
## INCREMENTATION BY ONE
#

sub inc ($) {
    require Math::AnyNum::inc;
    my ($x) = @_;
    bless \__inc__($$x);
}

#
## DECREMENTATION BY ONE
#

sub dec ($) {
    require Math::AnyNum::dec;
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

sub add {    # used in overloading
    require Math::AnyNum::add;
    my ($x, $y) = @_;

    if (ref($y) eq __PACKAGE__) {
        return bless \__add__($$x, $$y);
    }

    $x = $$x;

    if (!ref($y)) {
        if (CORE::int($y) eq $y and $y < ULONG_MAX and $y > LONG_MIN) {
            if (ref($x) eq 'Math::GMPq') {
                my $r = Math::GMPq::Rmpq_init();
                $y < 0
                  ? Math::GMPq::Rmpq_set_si($r, $y, 1)
                  : Math::GMPq::Rmpq_set_ui($r, $y, 1);
                Math::GMPq::Rmpq_add($r, $r, $x);
                return bless \$r;
            }

            return bless \__add__($x, $y);
        }

        return bless \__add__($x, _str2obj($y));
    }

    bless \__add__($x, _star2obj($y));
}

#
## SUBTRACTION
#

sub sub {    # used in overloading
    require Math::AnyNum::sub;
    my ($x, $y) = @_;

    $x =
        ref($x) eq __PACKAGE__ ? $$x
      : ref($x)                ? _star2obj($x)
      :                          _str2obj($x);

    if (ref($y) eq __PACKAGE__) {
        return bless \__sub__($x, $$y);
    }

    if (!ref($y)) {
        if (CORE::int($y) eq $y and $y < ULONG_MAX and $y > LONG_MIN) {
            if (ref($x) eq 'Math::GMPq') {
                my $r = Math::GMPq::Rmpq_init();
                $y < 0
                  ? Math::GMPq::Rmpq_set_si($r, $y, 1)
                  : Math::GMPq::Rmpq_set_ui($r, $y, 1);
                Math::GMPq::Rmpq_sub($r, $x, $r);
                return bless \$r;
            }

            return bless \__sub__($x, $y);
        }

        return bless \__sub__($x, _str2obj($y));
    }

    bless \__sub__($x, _star2obj($y));
}

#
## MULTIPLICATION
#

sub mul {    # used in overloading
    require Math::AnyNum::mul;
    my ($x, $y) = @_;

    if (ref($y) eq __PACKAGE__) {
        return bless \__mul__($$x, $$y);
    }

    $x = $$x;

    if (!ref($y)) {
        if (CORE::int($y) eq $y and $y < ULONG_MAX and $y > LONG_MIN) {
            if (ref($x) eq 'Math::GMPq') {
                my $r = Math::GMPq::Rmpq_init();
                $y < 0
                  ? Math::GMPq::Rmpq_set_si($r, $y, 1)
                  : Math::GMPq::Rmpq_set_ui($r, $y, 1);
                Math::GMPq::Rmpq_mul($r, $r, $x);
                return bless \$r;
            }

            return bless \__mul__($x, $y);
        }

        return bless \__mul__($x, _str2obj($y));
    }

    bless \__mul__($x, _star2obj($y));
}

#
## DIVISION
#

sub div {    # used in overloading
    require Math::AnyNum::div;
    my ($x, $y) = @_;

    $x =
        ref($x) eq __PACKAGE__ ? $$x
      : ref($x)                ? _star2obj($x)
      :                          _str2obj($x);

    if (ref($y) eq __PACKAGE__) {
        return bless \__div__($x, $$y);
    }

    if (!ref($y)) {
        if (CORE::int($y) eq $y and $y < ULONG_MAX and $y > LONG_MIN and CORE::int($y)) {
            if (ref($x) eq 'Math::GMPq') {
                my $r = Math::GMPq::Rmpq_init();
                $y < 0
                  ? Math::GMPq::Rmpq_set_si($r, -1, -$y)
                  : Math::GMPq::Rmpq_set_ui($r, 1, $y);
                Math::GMPq::Rmpq_mul($r, $r, $x);
                return bless \$r;
            }

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

    if (!ref($y) and CORE::int($y) eq $y and CORE::abs($y) < ULONG_MAX) {
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

    if (!ref($y) and CORE::int($y) eq $y and CORE::abs($y) < ULONG_MAX) {
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

    if (!ref($y) and CORE::int($y) eq $y and CORE::abs($y) < ULONG_MAX) {
        my $r = Math::GMPz::Rmpz_init();
        Math::GMPz::Rmpz_mul_ui($r, $x, CORE::abs($y));
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

    if (!ref($y) and CORE::int($y) eq $y and CORE::int($y) and CORE::abs($y) < ULONG_MAX) {
        my $r = Math::GMPz::Rmpz_init();
        Math::GMPz::Rmpz_tdiv_q_ui($r, $x, CORE::abs($y));
        Math::GMPz::Rmpz_neg($r, $r) if $y < 0;
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
    Math::GMPz::Rmpz_tdiv_q($r, $x, $y);
    bless \$r;
}

#
## POWER
#

sub pow ($$) {
    require Math::AnyNum::pow;
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

    # Both `x` and `y` are unsigned native integers
    if (    !ref($x)
        and !ref($y)
        and CORE::int($x) eq $x
        and $x >= 0
        and $x < ULONG_MAX
        and CORE::int($y) eq $y
        and $y >= 0
        and $y < ULONG_MAX) {

        my $r = Math::GMPz::Rmpz_init();
        Math::GMPz::Rmpz_ui_pow_ui($r, $x, $y);
        return bless \$r;
    }

    $x = (ref($x) eq __PACKAGE__ ? _any2mpz($$x) : _star2mpz($x)) // (goto &nan);

    if (!ref($y) and CORE::int($y) eq $y and CORE::abs($y) < ULONG_MAX) {
        ## `y` is already a native integer
    }
    else {
        $y = _any2si(ref($y) eq __PACKAGE__ ? $$y : _star2obj($y)) // (goto &nan);
    }

    my $r = Math::GMPz::Rmpz_init();
    Math::GMPz::Rmpz_pow_ui($r, $x, CORE::abs($y));

    if ($y < 0) {
        Math::GMPz::Rmpz_sgn($r) || goto &inf;    # 0^(-y) = Inf
        state $ONE_Z = Math::GMPz::Rmpz_init_set_ui_nobless(1);
        Math::GMPz::Rmpz_tdiv_q($r, $ONE_Z, $r);
    }

    bless \$r;
}

#
## IPOW2
#

sub ipow2 ($) {
    my ($n) = @_;

    if (ref($n) eq __PACKAGE__) {
        $n = _any2si($$n) // goto &nan;
    }
    elsif (    !ref($n)
           and CORE::int($n) eq $n
           and $n > LONG_MIN
           and $n < ULONG_MAX) {
        ## `n` is already a native integer
    }
    else {
        $n = _any2si(_star2obj($n)) // goto &nan;
    }

    goto &zero if $n < 0;
    state $one = Math::GMPz::Rmpz_init_set_ui_nobless(1);

    my $r = Math::GMPz::Rmpz_init();
    Math::GMPz::Rmpz_mul_2exp($r, $one, $n);
    bless \$r;
}

#
## IPOW10
#

sub ipow10 ($) {
    my ($n) = @_;

    if (ref($n) eq __PACKAGE__) {
        $n = _any2si($$n) // goto &nan;
    }
    elsif (    !ref($n)
           and CORE::int($n) eq $n
           and $n > LONG_MIN
           and $n < ULONG_MAX) {
        ## $n is a native integer
    }
    else {
        $n = _any2si(_star2obj($n)) // goto &nan;
    }

    goto &zero if $n < 0;

    my $r = Math::GMPz::Rmpz_init();
    Math::GMPz::Rmpz_ui_pow_ui($r, 10, $n);
    bless \$r;
}

#
## ROOT
#

sub root ($$) {
    require Math::AnyNum::pow;
    require Math::AnyNum::inv;
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

sub polygonal_root ($$) {
    require Math::AnyNum::polygonal_root;
    bless \__polygonal_root__(_star2mpfr_mpc($_[0]), _star2mpfr_mpc($_[1]));
}

#
## Second polygonal root
#

sub polygonal_root2 ($$) {
    require Math::AnyNum::polygonal_root;
    bless \__polygonal_root__(_star2mpfr_mpc($_[0]), _star2mpfr_mpc($_[1]), 1);
}

#
## isqrt
#

sub isqrt ($) {
    my ($x) = @_;

    $x = (ref($x) eq __PACKAGE__ ? _any2mpz($$x) : _star2mpz($x)) // goto &nan;

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
    $x = (ref($x) eq __PACKAGE__ ? _any2mpz($$x) : _star2mpz($x)) // goto &nan;
    my $r = Math::GMPz::Rmpz_init();
    Math::GMPz::Rmpz_root($r, $x, 3);
    bless \$r;
}

#
## IROOT
#

sub iroot ($$) {
    my ($x, $y) = @_;

    $x = (ref($x) eq __PACKAGE__ ? _any2mpz($$x) : _star2mpz($x)) // goto &nan;

    if (!ref($y) and CORE::int($y) eq $y and CORE::abs($y) < ULONG_MAX) {
        ## `y`is native integer
    }
    elsif (ref($y) eq __PACKAGE__) {
        $y = _any2si($$y) // goto &nan;
    }
    else {
        $y = _any2si(_star2obj($y)) // goto &nan;
    }

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

    $x = (ref($x) eq __PACKAGE__ ? _any2mpz($$x) : _star2mpz($x)) // return (nan(), nan());

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

    $x = (ref($x) eq __PACKAGE__ ? _any2mpz($$x) : _star2mpz($x)) // return (nan(), nan());

    if (!ref($y) and CORE::int($y) eq $y and $y < ULONG_MAX and $y > LONG_MIN) {
        ## `y` is a native integer
    }
    else {
        $y = _any2si(ref($y) eq __PACKAGE__ ? $$y : _star2obj($y)) // (return (nan(), nan()));
    }

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

sub mod ($$) {
    require Math::AnyNum::mod;
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

    $x = (ref($x) eq __PACKAGE__ ? _any2mpz($$x) : _star2mpz($x)) // (goto &nan);

    if (!ref($y) and CORE::int($y) eq $y and CORE::abs($y) < ULONG_MAX) {

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

    $y = (ref($y) eq __PACKAGE__ ? _any2mpz($$y) : _star2mpz($y)) // goto &nan;

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
    require Math::AnyNum::mod;
    require Math::AnyNum::div;
    require Math::AnyNum::sub;

    my @list = map { _star2obj($_) } @_;

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

#
## DIVMOD
#

sub divmod ($$) {
    my ($x, $y) = @_;

    $x = (ref($x) eq __PACKAGE__ ? _any2mpz($$x) : _star2mpz($x)) // return (nan(), nan());
    $y = (ref($y) eq __PACKAGE__ ? _any2mpz($$y) : _star2mpz($y)) // return (nan(), nan());

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
    require Math::AnyNum::eq;
    my ($x, $y) = @_;

    if (ref($x) eq __PACKAGE__ and ref($$x) eq 'Math::GMPz') {
        if (ref($y)) {
            if (ref($y) eq __PACKAGE__ and ref($$y) eq 'Math::GMPz') {
                return (Math::GMPz::Rmpz_divisible_p($$x, $$y) && Math::GMPz::Rmpz_sgn($$y));
            }
        }
        elsif (CORE::int($y) eq $y and $y and CORE::abs($y) < ULONG_MAX) {
            return Math::GMPz::Rmpz_divisible_ui_p($$x, CORE::abs($y));
        }
    }

    (@_) = (${mod($x, $y)}, 0);
    goto &__eq__;
}

#
## SPECIAL
#

sub ln {    # used in overloading
    require Math::AnyNum::log;
    bless \__log__(_star2mpfr_mpc($_[0]));
}

sub log2 ($) {
    require Math::AnyNum::log;
    bless \__log2__(_star2mpfr_mpc($_[0]));
}

sub log10 ($) {
    require Math::AnyNum::log;
    bless \__log10__(_star2mpfr_mpc($_[0]));
}

sub length ($) {
    my ($z) = _star2mpz($_[0]) // return -1;
    CORE::length(Math::GMPz::Rmpz_get_str($z, 10)) - (Math::GMPz::Rmpz_sgn($z) < 0 ? 1 : 0);
}

sub log (_;$) {
    require Math::AnyNum::log;
    my ($x, $y) = @_;

    if (!defined($y)) {
        return bless \__log__(_star2mpfr_mpc($x));
    }

    require Math::AnyNum::div;
    bless \__div__(__log__(_star2mpfr_mpc($x)), __log__(_star2mpfr_mpc($y)));
}

#
## ILOG
#

sub ilog2 ($) {
    require Math::AnyNum::ilog;
    state $two = Math::GMPz::Rmpz_init_set_ui(2);
    bless \__ilog__((_star2mpz($_[0]) // goto &nan), $two);
}

sub ilog10 ($) {
    require Math::AnyNum::ilog;
    state $ten = Math::GMPz::Rmpz_init_set_ui(10);
    bless \__ilog__((_star2mpz($_[0]) // goto &nan), $ten);
}

sub ilog ($;$) {
    my ($x, $y) = @_;

    if (!defined($y)) {
        require Math::AnyNum::log;
        return bless \(_any2mpz(__log__(_star2mpfr_mpc($x))) // goto &nan);
    }

    require Math::AnyNum::ilog;
    bless \__ilog__((_star2mpz($x) // goto &nan), (_star2mpz($y) // goto &nan));
}

#
## SQRT
#

sub sqrt {    # used in overloading
    require Math::AnyNum::sqrt;
    bless \__sqrt__(_star2mpfr_mpc($_[0]));
}

sub cbrt ($) {
    require Math::AnyNum::cbrt;
    bless \__cbrt__(_star2mpfr_mpc($_[0]));
}

sub sqr ($) {
    require Math::AnyNum::mul;
    my ($x) = @_;

    $x =
      ref($x) eq __PACKAGE__
      ? $$x
      : _star2obj($x);

    bless \__mul__($x, $x);
}

sub norm ($) {
    require Math::AnyNum::norm;
    my ($x) = @_;

    $x =
      ref($x) eq __PACKAGE__
      ? $$x
      : _star2obj($x);

    bless \__norm__($x);
}

sub exp {    # used in overloading
    require Math::AnyNum::exp;
    bless \__exp__(_star2mpfr_mpc($_[0]));
}

sub exp2 ($) {
    require Math::AnyNum::pow;
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
    require Math::AnyNum::pow;
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

sub floor ($) {
    require Math::AnyNum::floor;
    my ($x) = @_;

    if (ref($x) ne __PACKAGE__) {
        $x = __PACKAGE__->new($x);
    }

    ref($$x) eq 'Math::GMPz' and return $x;    # already an integer
    bless \__floor__($$x);
}

sub ceil ($) {
    require Math::AnyNum::ceil;
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

sub sin {    # used in overloading
    require Math::AnyNum::sin;
    bless \__sin__(_star2mpfr_mpc($_[0]));
}

sub sinh ($) {
    require Math::AnyNum::sinh;
    bless \__sinh__(_star2mpfr_mpc($_[0]));
}

sub asin ($) {
    require Math::AnyNum::asin;
    bless \__asin__(_star2mpfr_mpc($_[0]));
}

sub asinh ($) {
    require Math::AnyNum::asinh;
    bless \__asinh__(_star2mpfr_mpc($_[0]));
}

#
## cos / cosh / acos / acosh
#

sub cos {    # used in overloading
    require Math::AnyNum::cos;
    bless \__cos__(_star2mpfr_mpc($_[0]));
}

sub cosh ($) {
    require Math::AnyNum::cosh;
    bless \__cosh__(_star2mpfr_mpc($_[0]));
}

sub acos ($) {
    require Math::AnyNum::acos;
    bless \__acos__(_star2mpfr_mpc($_[0]));
}

sub acosh ($) {
    require Math::AnyNum::acosh;
    bless \__acosh__(_star2mpfr_mpc($_[0]));
}

#
## tan / tanh / atan / atanh
#

sub tan ($) {
    require Math::AnyNum::tan;
    bless \__tan__(_star2mpfr_mpc($_[0]));
}

sub tanh ($) {
    require Math::AnyNum::tanh;
    bless \__tanh__(_star2mpfr_mpc($_[0]));
}

sub atan ($) {
    require Math::AnyNum::atan;
    bless \__atan__(_star2mpfr_mpc($_[0]));
}

sub atanh ($) {
    require Math::AnyNum::atanh;
    bless \__atanh__(_star2mpfr_mpc($_[0]));
}

sub atan2 ($$) {
    require Math::AnyNum::atan2;
    bless \__atan2__(_star2mpfr_mpc($_[0]), _star2mpfr_mpc($_[1]));
}

#
## sec / sech / asec / asech
#

sub sec ($) {
    require Math::AnyNum::sec;
    bless \__sec__(_star2mpfr_mpc($_[0]));
}

sub sech ($) {
    require Math::AnyNum::sech;
    bless \__sech__(_star2mpfr_mpc($_[0]));
}

sub asec ($) {
    require Math::AnyNum::asec;
    bless \__asec__(_star2mpfr_mpc($_[0]));
}

sub asech ($) {
    require Math::AnyNum::asech;
    bless \__asech__(_star2mpfr_mpc($_[0]));
}

#
## csc / csch / acsc / acsch
#

sub csc ($) {
    require Math::AnyNum::csc;
    bless \__csc__(_star2mpfr_mpc($_[0]));
}

sub csch ($) {
    require Math::AnyNum::csch;
    bless \__csch__(_star2mpfr_mpc($_[0]));
}

sub acsc ($) {
    require Math::AnyNum::acsc;
    bless \__acsc__(_star2mpfr_mpc($_[0]));
}

sub acsch ($) {
    require Math::AnyNum::acsch;
    bless \__acsch__(_star2mpfr_mpc($_[0]));
}

#
## cot / coth / acot / acoth
#

sub cot ($) {
    require Math::AnyNum::cot;
    bless \__cot__(_star2mpfr_mpc($_[0]));
}

sub coth ($) {
    require Math::AnyNum::coth;
    bless \__coth__(_star2mpfr_mpc($_[0]));
}

sub acot ($) {
    require Math::AnyNum::acot;
    bless \__acot__(_star2mpfr_mpc($_[0]));
}

sub acoth ($) {
    require Math::AnyNum::acoth;
    bless \__acoth__(_star2mpfr_mpc($_[0]));
}

sub deg2rad ($) {
    require Math::AnyNum::mul;
    my ($x) = @_;
    my $f = Math::MPFR::Rmpfr_init2($PREC);
    Math::MPFR::Rmpfr_const_pi($f, $ROUND);
    Math::MPFR::Rmpfr_div_ui($f, $f, 180, $ROUND);
    bless \__mul__(_star2mpfr_mpc($x), $f);
}

sub rad2deg ($) {
    require Math::AnyNum::mul;
    my ($x) = @_;
    my $f = Math::MPFR::Rmpfr_init2($PREC);
    Math::MPFR::Rmpfr_const_pi($f, $ROUND);
    Math::MPFR::Rmpfr_ui_div($f, 180, $f, $ROUND);
    bless \__mul__(_star2mpfr_mpc($x), $f);
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
## eta
#

sub eta ($) {
    require Math::AnyNum::eta;
    bless \__eta__(_star2mpfr($_[0]));
}

#
## beta
#
sub beta ($$) {
    require Math::AnyNum::beta;
    bless \__beta__(_star2mpfr($_[0]), _star2mpfr($_[1]));
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
## Lambert W
#

sub LambertW ($) {
    require Math::AnyNum::LambertW;
    bless \__LambertW__(_star2mpfr_mpc($_[0]));
}

#
## lgrt -- logarithmic root
#

sub lgrt ($) {
    require Math::AnyNum::lgrt;
    bless \__lgrt__(_star2mpfr_mpc($_[0]));
}

#
## agm
#
sub agm ($$) {
    require Math::AnyNum::agm;
    bless \__agm__(_star2mpfr_mpc($_[0]), _star2mpfr_mpc($_[1]));
}

#
## hypot
#

sub hypot ($$) {
    require Math::AnyNum::hypot;
    bless \__hypot__(_star2mpfr_mpc($_[0]), _star2mpfr_mpc($_[1]));
}

#
## BesselJ
#

sub BesselJ ($$) {
    require Math::AnyNum::BesselJ;
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

sub BesselY ($$) {
    require Math::AnyNum::BesselY;
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

sub round ($;$) {
    require Math::AnyNum::round;
    my ($x, $y) = @_;

    $x = ref($x) eq __PACKAGE__ ? $$x : _star2obj($x);

    if (!defined($y)) {
        return bless \__round__($x, 0);
    }

    if (!ref($y)) {
        if (CORE::int($y) eq $y and $y > LONG_MIN and $y < ULONG_MAX) {
            ## `y` is a native integer
        }
        else {
            $y = _any2si(_str2obj($y)) // (goto &nan);
        }
    }
    elsif (ref($y) eq __PACKAGE__) {
        $y = _any2si($$y) // (goto &nan);
    }
    else {
        $y = _any2si(_star2obj($y)) // (goto &nan);
    }

    bless \__round__($x, $y);
}

#
## RAND / IRAND
#

{
    my $srand = srand();

    {
        state $state = Math::MPFR::Rmpfr_randinit_mt_nobless();
        Math::MPFR::Rmpfr_randseed_ui($state, $srand);

        sub rand (;$;$) {
            require Math::AnyNum::mul;
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

            require Math::AnyNum::sub;
            require Math::AnyNum::add;

            $y = ref($y) eq __PACKAGE__ ? $$y : _star2obj($y);

            my $rand = Math::MPFR::Rmpfr_init2($PREC);
            Math::MPFR::Rmpfr_urandom($rand, $state, $ROUND);
            $rand = __mul__($rand, __sub__($y, $x));
            bless \__add__($rand, $x);
        }

        sub seed ($) {
            my $z = _star2mpz($_[0]) // do {
                require Carp;
                Carp::croak("seed(): invalid seed value <<$_[0]>> (expected an integer)");
            };
            Math::MPFR::Rmpfr_randseed($state, $z);
            bless \$z;
        }
    }

    {
        state $state = Math::GMPz::zgmp_randinit_mt_nobless();
        Math::GMPz::zgmp_randseed_ui($state, $srand);

        sub irand ($;$) {
            require Math::AnyNum::irand;
            my ($x, $y) = @_;

            $x = (ref($x) eq __PACKAGE__ ? _any2mpz($$x) : _star2mpz($x)) // (goto &nan);

            if (!defined($y)) {
                return bless \__irand__($x, undef, $state);
            }

            $y = (ref($y) eq __PACKAGE__ ? _any2mpz($$y) : _star2mpz($y)) // (goto &nan);
            bless \__irand__($x, $y, $state);
        }

        sub iseed ($) {
            my $z = _star2mpz($_[0]) // do {
                require Carp;
                Carp::croak("iseed(): invalid seed value <<$_[0]>> (expected an integer)");
            };
            Math::GMPz::zgmp_randseed($state, $z);
            bless \$z;
        }
    }
}

#
## Fibonacci
#
sub fibonacci ($) {
    my ($x) = @_;

    if (!ref($x) and CORE::int($x) eq $x and $x >= 0 and $x < ULONG_MAX) {
        ## `x` is a native unsigned integer
    }
    elsif (ref($x) eq __PACKAGE__) {
        $x = _any2ui($$x) // goto &nan;
    }
    else {
        $x = _any2ui(_star2obj($x)) // goto &nan;
    }

    my $r = Math::GMPz::Rmpz_init();
    Math::GMPz::Rmpz_fib_ui($r, $x);
    bless \$r;
}

#
## Lucas
#
sub lucas ($) {
    my ($x) = @_;

    if (!ref($x) and CORE::int($x) eq $x and $x >= 0 and $x < ULONG_MAX) {
        ## `x` is a native unsigned integer
    }
    elsif (ref($x) eq __PACKAGE__) {
        $x = _any2ui($$x) // goto &nan;
    }
    else {
        $x = _any2ui(_star2obj($x)) // goto &nan;
    }

    my $r = Math::GMPz::Rmpz_init();
    Math::GMPz::Rmpz_lucnum_ui($r, $x);
    bless \$r;
}

#
## Primorial
#
sub primorial ($) {
    my ($x) = @_;

    if (!ref($x) and CORE::int($x) eq $x and $x >= 0 and $x < ULONG_MAX) {
        ## `x` is a native unsigned integer
    }
    elsif (ref($x) eq __PACKAGE__) {
        $x = _any2ui($$x) // goto &nan;
    }
    else {
        $x = _any2ui(_star2obj($x)) // goto &nan;
    }

    my $r = Math::GMPz::Rmpz_init();
    Math::GMPz::Rmpz_primorial_ui($r, $x);
    bless \$r;
}

#
## bernfrac
#

sub bernfrac ($) {
    require Math::AnyNum::bernfrac;
    my ($x) = @_;

    if (!ref($x) and CORE::int($x) eq $x and $x >= 0 and $x < ULONG_MAX) {
        ## `x` is a native unsigned integer
    }
    elsif (ref($x) eq __PACKAGE__) {
        $x = _any2ui($$x) // goto &nan;
    }
    else {
        $x = _any2ui(_star2obj($x)) // goto &nan;
    }

    bless \__bernfrac__($x);
}

#
## harmfrac
#

sub harmfrac ($) {
    require Math::AnyNum::harmfrac;
    my ($x) = @_;

    if (!ref($x) and CORE::int($x) eq $x and $x >= 0 and $x < ULONG_MAX) {
        ## `x` is a native unsigned integer
    }
    elsif (ref($x) eq __PACKAGE__) {
        $x = _any2ui($$x) // goto &nan;
    }
    else {
        $x = _any2ui(_star2obj($x)) // goto &nan;
    }

    bless \__harmfrac__($x);
}

#
## bernreal
#

sub bernreal ($) {
    require Math::AnyNum::bernreal;
    my ($x) = @_;

    if (!ref($x) and CORE::int($x) eq $x and $x >= 0 and $x < ULONG_MAX) {
        ## `x` is a native unsigned integer
    }
    elsif (ref($x) eq __PACKAGE__) {
        $x = _any2ui($$x) // goto &nan;
    }
    else {
        $x = _any2ui(_star2obj($x)) // goto &nan;
    }

    bless \__bernreal__($x);
}

#
## harmreal
#

sub harmreal ($) {
    require Math::AnyNum::harmreal;
    bless \__harmreal__(_star2mpfr($_[0]) // (goto &nan));
}

#
## Subfactorial
#

sub subfactorial ($;$) {
    my ($x, $y) = @_;

    my ($m, $k);

    if (!ref($x) and CORE::int($x) eq $x and $x >= 0 and $x < ULONG_MAX) {
        $m = $x;
    }
    elsif (ref($x) eq __PACKAGE__) {
        $m = _any2ui($$x) // goto &nan;
    }
    else {
        $m = _any2ui(_star2obj($x)) // goto &nan;
    }

    if (defined($y)) {
        if (!ref($y) and CORE::int($y) eq $y and $y > LONG_MIN and $y < ULONG_MAX) {
            $k = $y;
        }
        elsif (ref($y) eq __PACKAGE__) {
            $k = _any2si($$y) // goto &nan;
        }
        else {
            $k = _any2si(_star2obj($y)) // goto &nan;
        }
    }
    else {
        $k = 0;
    }

    my $n = $m - $k;

    goto &zero if ($k < 0);
    goto &one  if ($n == 0);
    goto &nan  if ($n < 0);

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

#
## Factorial
#

sub factorial ($) {
    my ($x) = @_;

    if (!ref($x) and CORE::int($x) eq $x and $x >= 0 and $x < ULONG_MAX) {
        ## `x` is a native unsigned integer
    }
    elsif (ref($x) eq __PACKAGE__) {
        $x = _any2ui($$x) // goto &nan;
    }
    else {
        $x = _any2ui(_star2obj($x)) // goto &nan;
    }

    my $r = Math::GMPz::Rmpz_init();
    Math::GMPz::Rmpz_fac_ui($r, $x);
    bless \$r;
}

#
## Double-factorial
#

sub dfactorial ($) {
    my ($x) = @_;

    if (!ref($x) and CORE::int($x) eq $x and $x >= 0 and $x < ULONG_MAX) {
        ## `x` is a native unsigned integer
    }
    elsif (ref($x) eq __PACKAGE__) {
        $x = _any2ui($$x) // goto &nan;
    }
    else {
        $x = _any2ui(_star2obj($x)) // goto &nan;
    }

    my $r = Math::GMPz::Rmpz_init();
    Math::GMPz::Rmpz_2fac_ui($r, $x);
    bless \$r;
}

#
## M-factorial
#

sub mfactorial ($$) {
    my ($x, $y) = @_;

    if (!ref($x) and CORE::int($x) eq $x and $x >= 0 and $x < ULONG_MAX) {
        ## `x` is an unsigned native integer
    }
    elsif (ref($x) eq __PACKAGE__) {
        $x = _any2ui($$x) // goto &nan;
    }
    else {
        $x = _any2ui(_star2obj($x)) // goto &nan;
    }

    if (!ref($y) and CORE::int($y) eq $y and $y >= 0 and $y < ULONG_MAX) {
        ## `y` is an unsigned native integer
    }
    elsif (ref($y) eq __PACKAGE__) {
        $y = _any2ui($$y) // goto &nan;
    }
    else {
        $y = _any2ui(_star2obj($y)) // goto &nan;
    }

    my $r = Math::GMPz::Rmpz_init();
    Math::GMPz::Rmpz_mfac_uiui($r, $x, $y);
    bless \$r;
}

#
## falling_factorial(x, +y) = binomial(x, y) * y!
## falling_factorial(x, -y) = 1/falling_factorial(x + y, y)
#
sub falling_factorial ($$) {
    my ($x, $y) = @_;

    $x = _star2mpz($x) // goto &nan;

    if (ref($y) eq __PACKAGE__) {
        $y = _any2si($$y) // goto &nan;
    }
    elsif (!ref($y) and CORE::int($y) eq $y and $y > LONG_MIN and $y < ULONG_MAX) {
        ## `y` is a native integer
    }
    else {
        $y = _any2si(_star2obj($y)) // goto &nan;
    }

    my $r = Math::GMPz::Rmpz_init_set($x);

    if ($y < 0) {
        Math::GMPz::Rmpz_add_ui($r, $r, CORE::abs($y));
    }

    Math::GMPz::Rmpz_fits_ulong_p($r)
      ? Math::GMPz::Rmpz_bin_uiui($r, Math::GMPz::Rmpz_get_ui($r), CORE::abs($y))
      : Math::GMPz::Rmpz_bin_ui($r, $r, CORE::abs($y));

    Math::GMPz::Rmpz_sgn($r) || do {
        $y < 0
          ? (goto &nan)
          : (goto &zero);
    };

    state $t = Math::GMPz::Rmpz_init_nobless();
    Math::GMPz::Rmpz_fac_ui($t, CORE::abs($y));
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

    if (ref($y) eq __PACKAGE__) {
        $y = _any2si($$y) // goto &nan;
    }
    elsif (!ref($y) and CORE::int($y) eq $y and $y > LONG_MIN and $y < ULONG_MAX) {
        ## `y` is a native integer
    }
    else {
        $y = _any2si(_star2obj($y)) // goto &nan;
    }

    my $r = Math::GMPz::Rmpz_init_set($x);
    Math::GMPz::Rmpz_add_ui($r, $r, CORE::abs($y));
    Math::GMPz::Rmpz_sub_ui($r, $r, 1);

    if ($y < 0) {
        Math::GMPz::Rmpz_sub_ui($r, $r, CORE::abs($y));
    }

    Math::GMPz::Rmpz_fits_ulong_p($r)
      ? Math::GMPz::Rmpz_bin_uiui($r, Math::GMPz::Rmpz_get_ui($r), CORE::abs($y))
      : Math::GMPz::Rmpz_bin_ui($r, $r, CORE::abs($y));

    Math::GMPz::Rmpz_sgn($r) || do {
        $y < 0
          ? (goto &nan)
          : (goto &zero);
    };

    state $t = Math::GMPz::Rmpz_init_nobless();
    Math::GMPz::Rmpz_fac_ui($t, CORE::abs($y));
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

sub gcd ($$) {
    my ($x, $y) = @_;

    if (ref($y) and !ref($x)) {
        ($x, $y) = ($y, $x);
    }

    $x = (ref($x) eq __PACKAGE__ ? _any2mpz($$x) : _star2mpz($x)) // (goto &nan);

    my $r = Math::GMPz::Rmpz_init();

    if (!ref($y) and CORE::int($y) eq $y and CORE::abs($y) < ULONG_MAX) {
        Math::GMPz::Rmpz_gcd_ui($r, $x, CORE::abs($y));
    }
    else {
        $y = (ref($y) eq __PACKAGE__ ? _any2mpz($$y) : _star2mpz($y)) // (goto &nan);
        Math::GMPz::Rmpz_gcd($r, $x, $y);
    }

    bless \$r;
}

#
## Least common multiple
#

sub lcm ($$) {
    my ($x, $y) = @_;

    if (ref($y) and !ref($x)) {
        ($x, $y) = ($y, $x);
    }

    $x = (ref($x) eq __PACKAGE__ ? _any2mpz($$x) : _star2mpz($x)) // (goto &nan);

    my $r = Math::GMPz::Rmpz_init();

    if (!ref($y) and CORE::int($y) eq $y and CORE::abs($y) < ULONG_MAX) {
        Math::GMPz::Rmpz_lcm_ui($r, $x, CORE::abs($y));
    }
    else {
        $y = (ref($y) eq __PACKAGE__ ? _any2mpz($$y) : _star2mpz($y)) // (goto &nan);
        Math::GMPz::Rmpz_lcm($r, $x, $y);
    }

    bless \$r;
}

#
## Next prime after `x`.
#

sub next_prime ($) {
    my ($x) = @_;
    $x = (ref($x) eq __PACKAGE__ ? _any2mpz($$x) : _star2mpz($x)) // goto &nan;
    my $r = Math::GMPz::Rmpz_init();
    Math::GMPz::Rmpz_nextprime($r, $x);
    bless \$r;
}

#
## Is prime?
#

sub is_prime ($;$) {
    require Math::AnyNum::is_int;
    my ($x, $y) = @_;

    $x = ref($x) eq __PACKAGE__ ? $$x : _star2obj($x);

    __is_int__($x) || return 0;

    $y = defined($y) ? (CORE::abs(CORE::int($y)) || 20) : 20;
    Math::GMPz::Rmpz_probab_prime_p(_any2mpz($x) // (return 0), $y);
}

#
## Is `x` coprime to `y`?
#

sub is_coprime ($$) {
    require Math::AnyNum::is_int;
    my ($x, $y) = @_;

    $x = ref($x) eq __PACKAGE__ ? $$x : _star2obj($x);

    __is_int__($x) || return 0;

    $x = _any2mpz($x) // return 0;

    if (!ref($y) and CORE::int($y) eq $y and $y >= 0 and $y < ULONG_MAX) {
        ## `y` is a native integer
    }
    else {
        $y = ref($y) eq __PACKAGE__ ? $$y : _star2obj($y);
        __is_int__($y) || return 0;
        $y = _any2mpz($y) // return 0;
    }

    state $t = Math::GMPz::Rmpz_init_nobless();

    ref($y)
      ? Math::GMPz::Rmpz_gcd($t, $x, $y)
      : Math::GMPz::Rmpz_gcd_ui($t, $x, $y);

    Math::GMPz::Rmpz_cmp_ui($t, 1) == 0;
}

#
## Returns a true value if all the divisors of `x` are <= n.
#

sub is_smooth ($$) {
    require Math::AnyNum::is_int;
    my ($x, $n) = @_;

    $x = ref($x) eq __PACKAGE__ ? $$x : _star2obj($x);

    __is_int__($x) || return 0;

    if (ref($x) ne 'Math::GMPz') {
        $x = _any2mpz($x) // return 0;
    }

    return 0 if (Math::GMPz::Rmpz_sgn($x) <= 0);

    $n = (ref($n) eq __PACKAGE__ ? _any2mpz($$n) : _star2mpz($n)) // return 0;

    return 0 if (Math::GMPz::Rmpz_sgn($n) <= 0);

    my $p = Math::GMPz::Rmpz_init_set_ui(2);
    my $t = Math::GMPz::Rmpz_init_set($x);

    for (; Math::GMPz::Rmpz_cmp($p, $n) <= 0 ; Math::GMPz::Rmpz_nextprime($p, $p)) {
        if (Math::GMPz::Rmpz_divisible_p($t, $p)) {
            Math::GMPz::Rmpz_remove($t, $t, $p);
            Math::GMPz::Rmpz_cmp_ui($t, 1) == 0 and return 1;
        }
    }

    Math::GMPz::Rmpz_cmp_ui($t, 1) == 0;
}

#
## Is integer?
#

sub is_int ($) {
    require Math::AnyNum::is_int;
    my ($x) = @_;
    __is_int__(ref($x) eq __PACKAGE__ ? $$x : _star2obj($x));
}

#
## Is rational?
#

sub is_rat ($) {
    my ($x) = @_;
    my $ref = ref(ref($x) eq __PACKAGE__ ? $$x : _star2obj($x));
    $ref eq 'Math::GMPz' or $ref eq 'Math::GMPq';
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

sub sgn ($) {
    require Math::AnyNum::sgn;
    my ($x) = @_;
    my $r = __sgn__(ref($x) eq __PACKAGE__ ? $$x : _star2obj($x));
    ref($r) ? (bless \$r) : $r;
}

#
## Is a real number?
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
## Is an imaginary number?
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
## Is a complex number?
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
## Is positive infinity?
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
## Is negative infinity?
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
## Is Not-A-Number?
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
## Is an even integer?
#

sub is_even ($) {
    require Math::AnyNum::is_int;
    my ($x) = @_;

    $x = ref($x) eq __PACKAGE__ ? $$x : _star2obj($x);

    __is_int__($x)
      && Math::GMPz::Rmpz_even_p(_any2mpz($x) // (return 0));
}

#
## Is an odd integer?
#

sub is_odd ($) {
    require Math::AnyNum::is_int;
    my ($x) = @_;

    $x = ref($x) eq __PACKAGE__ ? $$x : _star2obj($x);

    __is_int__($x)
      && Math::GMPz::Rmpz_odd_p(_any2mpz($x) // (return 0));
}

#
## Is zero?
#

sub is_zero ($) {
    require Math::AnyNum::eq;
    my ($x) = @_;
    (@_) = ((ref($x) eq __PACKAGE__ ? $$x : _star2obj($x)), 0);
    goto &__eq__;
}

#
## Is one?
#

sub is_one ($) {
    require Math::AnyNum::eq;
    my ($x) = @_;
    (@_) = ((ref($x) eq __PACKAGE__ ? $$x : _star2obj($x)), 1);
    goto &__eq__;
}

#
## Is minus one?
#

sub is_mone ($) {
    require Math::AnyNum::eq;
    my ($x) = @_;
    (@_) = ((ref($x) eq __PACKAGE__ ? $$x : _star2obj($x)), -1);
    goto &__eq__;
}

#
## Is positive?
#

sub is_pos ($) {
    require Math::AnyNum::cmp;
    my ($x) = @_;
    (__cmp__((ref($x) eq __PACKAGE__ ? $$x : _star2obj($x)), 0) // return undef) > 0;
}

#
## Is negative?
#

sub is_neg ($) {
    require Math::AnyNum::cmp;
    my ($x) = @_;
    (__cmp__((ref($x) eq __PACKAGE__ ? $$x : _star2obj($x)), 0) // return undef) < 0;
}

#
## Is square?
#

sub is_square ($) {
    require Math::AnyNum::is_int;
    my ($x, $y) = @_;

    $x = ref($x) eq __PACKAGE__ ? $$x : _star2obj($x);

    __is_int__($x)
      && Math::GMPz::Rmpz_perfect_square_p(_any2mpz($x) // (return 0));
}

#
## Is a polygonal number?
#

sub is_polygonal ($$) {
    require Math::AnyNum::is_int;
    require Math::AnyNum::is_polygonal;
    my ($n, $k) = @_;

    $n = ref($n) eq __PACKAGE__ ? $$n : _star2obj($n);

    $n = (__is_int__($n)         ? _any2mpz($n)  : return 0) // return 0;
    $k = (ref($k) eq __PACKAGE__ ? _any2mpz($$k) : _star2mpz($k)) // return 0;

    __is_polygonal__($n, $k);
}

#
## Is a second polygonal number?
#

sub is_polygonal2 ($$) {
    require Math::AnyNum::is_int;
    require Math::AnyNum::is_polygonal;
    my ($n, $k) = @_;

    $n = ref($n) eq __PACKAGE__ ? $$n : _star2obj($n);

    $n = (__is_int__($n)         ? _any2mpz($n)  : return 0) // return 0;
    $k = (ref($k) eq __PACKAGE__ ? _any2mpz($$k) : _star2mpz($k)) // return 0;

    __is_polygonal__($n, $k, 1);
}

#
## Integer polygonal root
#

sub ipolygonal_root ($$) {
    require Math::AnyNum::ipolygonal_root;
    my ($n, $k) = @_;

    $n = (ref($n) eq __PACKAGE__ ? _any2mpz($$n) : _star2mpz($n)) // goto &nan;
    $k = (ref($k) eq __PACKAGE__ ? _any2mpz($$k) : _star2mpz($k)) // goto &nan;

    bless \__ipolygonal_root__($n, $k);
}

#
## Second integer polygonal root
#

sub ipolygonal_root2 ($$) {
    require Math::AnyNum::ipolygonal_root;
    my ($n, $k) = @_;

    $n = (ref($n) eq __PACKAGE__ ? _any2mpz($$n) : _star2mpz($n)) // goto &nan;
    $k = (ref($k) eq __PACKAGE__ ? _any2mpz($$k) : _star2mpz($k)) // goto &nan;

    bless \__ipolygonal_root__($n, $k, 1);
}

#
## n-th k-gonal number
#

sub polygonal ($$) {
    my ($n, $k) = @_;

    $n = (ref($n) eq __PACKAGE__ ? _any2mpz($$n) : _star2mpz($n)) // goto &nan;

    if (!ref($k) and CORE::int($k) eq $k and $k >= 0 and $k < ULONG_MAX) {
        ## `k` is a native unsigned integer
    }
    else {
        $k = (ref($k) eq __PACKAGE__ ? _any2mpz($$k) : _star2mpz($k)) // goto &nan;
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

    Math::GMPz::Rmpz_submul_ui($r, $n, 2);      # r = r-2*n
    Math::GMPz::Rmpz_add_ui($r, $r, 4);         # r = r+4
    Math::GMPz::Rmpz_mul($r, $r, $n);           # r = r*n
    Math::GMPz::Rmpz_div_2exp($r, $r, 1);       # r = r/2

    bless \$r;
}

#
## is_power
#

sub is_power ($;$) {
    require Math::AnyNum::is_power;
    require Math::AnyNum::is_int;
    my ($x, $y) = @_;

    $x = ref($x) eq __PACKAGE__ ? $$x : _star2obj($x);

    __is_int__($x) || return 0;
    $x = _any2mpz($x) // goto &nan;

    if (!defined($y)) {
        return Math::GMPz::Rmpz_perfect_power_p($x);
    }

    if (!ref($y) and CORE::int($y) eq $y and $y < ULONG_MAX and $y > LONG_MIN) {
        ## `y` is a native integer
    }
    else {
        $y = _any2si(ref($y) eq __PACKAGE__ ? $$y : _star2obj($y)) // return 0;
    }

    __is_power__($x, $y);
}

#
## kronecker
#

sub kronecker ($$) {
    my ($x, $y) = @_;

    $x = (ref($x) eq __PACKAGE__ ? _any2mpz($$x) : _star2mpz($x)) // goto &nan;

    if (!ref($y) and CORE::int($y) eq $y and $y < ULONG_MAX and $y > LONG_MIN) {
        return (
                $y < 0
                ? Math::GMPz::Rmpz_kronecker_si($x, $y)
                : Math::GMPz::Rmpz_kronecker_ui($x, $y)
               );
    }

    $y = (ref($y) eq __PACKAGE__ ? _any2mpz($$y) : _star2mpz($y)) // goto &nan;

    Math::GMPz::Rmpz_kronecker($x, $y);
}

#
## valuation
#

sub valuation ($$) {
    require Math::AnyNum::valuation;
    my ($x, $y) = @_;

    $x = (ref($x) eq __PACKAGE__ ? _any2mpz($$x) : _star2mpz($x)) // goto &nan;
    $y = (ref($y) eq __PACKAGE__ ? _any2mpz($$y) : _star2mpz($y)) // goto &nan;

    (__valuation__($x, $y))[0];
}

#
## remdiv
#

sub remdiv ($$) {
    require Math::AnyNum::valuation;
    my ($x, $y) = @_;

    $x = (ref($x) eq __PACKAGE__ ? _any2mpz($$x) : _star2mpz($x)) // goto &nan;
    $y = (ref($y) eq __PACKAGE__ ? _any2mpz($$y) : _star2mpz($y)) // goto &nan;

    bless \((__valuation__($x, $y))[1]);
}

#
## Invmod
#

sub invmod ($$) {
    my ($x, $y) = @_;

    $x = (ref($x) eq __PACKAGE__ ? _any2mpz($$x) : _star2mpz($x)) // goto &nan;
    $y = (ref($y) eq __PACKAGE__ ? _any2mpz($$y) : _star2mpz($y)) // goto &nan;

    my $r = Math::GMPz::Rmpz_init();
    Math::GMPz::Rmpz_invert($r, $x, $y) || (goto &nan);
    bless \$r;
}

#
## Powmod
#

sub powmod ($$$) {
    my ($x, $y, $z) = @_;

    $x = (ref($x) eq __PACKAGE__ ? _any2mpz($$x) : _star2mpz($x)) // goto &nan;
    $y = (ref($y) eq __PACKAGE__ ? _any2mpz($$y) : _star2mpz($y)) // goto &nan;
    $z = (ref($z) eq __PACKAGE__ ? _any2mpz($$z) : _star2mpz($z)) // goto &nan;

    Math::GMPz::Rmpz_sgn($z) || goto &nan;

    if (Math::GMPz::Rmpz_sgn($y) < 0) {
        my $t = Math::GMPz::Rmpz_init();
        Math::GMPz::Rmpz_gcd($t, $x, $z);
        Math::GMPz::Rmpz_cmp_ui($t, 1) == 0 or goto &nan;
    }

    my $r = Math::GMPz::Rmpz_init();
    Math::GMPz::Rmpz_powm($r, $x, $y, $z);
    bless \$r;
}

#
## Faulhaber summation formula
#

sub faulhaber_sum ($$) {
    require Math::AnyNum::bernfrac;
    my ($n, $p) = @_;

    my $native_n = 0;    # true when `n` is a native integer

    if (!ref($n) and CORE::int($n) eq $n and $n >= 0 and $n < ULONG_MAX) {
        ## `n` is a native unsigned integer
        $native_n = 1;
    }
    else {
        $n = (ref($n) eq __PACKAGE__ ? _any2mpz($$n) : _star2mpz($n)) // goto &nan;

        # Try to unbox `n` when it fits inside a native unsigned integer
        if (Math::GMPz::Rmpz_fits_ulong_p($n)) {
            $native_n = 1;
            $n        = Math::GMPz::Rmpz_get_ui($n);
        }
    }

    if (!ref($p) and CORE::int($p) eq $p and $p >= 0 and $p < ULONG_MAX) {
        ## `p` is already a native unsigned integer
    }
    else {
        $p = (ref($p) eq __PACKAGE__ ? _any2ui($$p) : _any2ui(_star2obj($p))) // goto &nan;
    }

    state @cache;    # cache for Bernoulli numbers

    my $t = Math::GMPz::Rmpz_init();
    my $u = Math::GMPz::Rmpz_init();

    my $numerator   = Math::GMPz::Rmpz_init();
    my $denominator = Math::GMPz::Rmpz_init_set_ui(1);

#<<<
    $native_n
      ? Math::GMPz::Rmpz_ui_pow_ui($numerator, $n, $p + 1)    # numerator = n^(p + 1)
      : Math::GMPz::Rmpz_pow_ui(   $numerator, $n, $p + 1);   # ==//==
#>>>

    foreach my $j (1 .. $p) {

        # When `j` is odd and greater than 1, we can skip it.
        $j % 2 == 0 or $j == 1 or next;

        Math::GMPz::Rmpz_bin_uiui($t, $p + 1, $j);    # t = binomial(p+1, j)

#<<<
        $native_n
          ? Math::GMPz::Rmpz_ui_pow_ui($u, $n, $p + 1 - $j)    # u = n^(p + 1 - j)
          : Math::GMPz::Rmpz_pow_ui(   $u, $n, $p + 1 - $j);   # ==//==
#>>>

        # Compute Bernouli(j)
        my $bern = ($j <= 100 ? ($cache[$j] //= __bernfrac__($j)) : __bernfrac__($j));

#<<<
        Math::GMPz::Rmpz_mul($t, $t, $u);         # t = t * u
        Math::GMPq::Rmpq_get_num($u, $bern);      # u = numerator(bern)
        Math::GMPz::Rmpz_mul($t, $t, $u);         # t = t * u
        Math::GMPq::Rmpq_get_den($u, $bern);      # u = denominator(bern)

        Math::GMPz::Rmpz_mul(   $numerator,   $numerator,   $u);   # numerator   = numerator   * u
        Math::GMPz::Rmpz_addmul($numerator,   $denominator, $t);   # numerator  += denominator * t
        Math::GMPz::Rmpz_mul(   $denominator, $denominator, $u);   # denominator = denominator * u
#>>>
    }

#<<<
    Math::GMPz::Rmpz_mul_ui($denominator, $denominator, $p + 1);        # denominator = denominator * (p+1)
    Math::GMPz::Rmpz_divexact($numerator, $numerator, $denominator);    # numerator = numerator / denominator
#>>>

    bless \$numerator;
}

#
## Binomial coefficient
#

sub binomial ($$) {
    my ($x, $y) = @_;

    # `x` and `y` are native unsigned integers
    if (    !ref($x)
        and !ref($y)
        and CORE::int($x) eq $x
        and CORE::int($y) eq $y
        and $x >= 0
        and $y >= 0
        and $x < ULONG_MAX
        and $y < ULONG_MAX) {
        my $r = Math::GMPz::Rmpz_init();
        Math::GMPz::Rmpz_bin_uiui($r, $x, $y);
        return bless \$r;
    }

    $x = (ref($x) eq __PACKAGE__ ? _any2mpz($$x) : _star2mpz($x)) // goto &nan;

    if (!ref($y) and CORE::int($y) eq $y and $y > LONG_MIN and $y < ULONG_MAX) {
        ## `y` is a native integer
    }
    else {
        $y = _any2si(ref($y) eq __PACKAGE__ ? $$y : _star2obj($y)) // goto &nan;
    }

    my $r = Math::GMPz::Rmpz_init();

    if ($y >= 0 and Math::GMPz::Rmpz_fits_ulong_p($x)) {
        Math::GMPz::Rmpz_bin_uiui($r, Math::GMPz::Rmpz_get_ui($x), $y);
    }
    else {
        $y < 0
          ? Math::GMPz::Rmpz_bin_si($r, $x, $y)
          : Math::GMPz::Rmpz_bin_ui($r, $x, $y);
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

        if (!ref($k) and CORE::int($k) eq $k and $k > LONG_MIN and $k < ULONG_MAX) {
            ## `k` is a native integer
        }
        else {
            $k = _any2si(ref($k) eq __PACKAGE__ ? $$k : _star2obj($k)) // goto &nan;
        }

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
    my ($x, $y) = @_;

    $x = _any2mpz($$x) // (goto &nan);
    $y = (ref($y) eq __PACKAGE__ ? _any2mpz($$y) : _star2mpz($y)) // (goto &nan);

    my $r = Math::GMPz::Rmpz_init();
    Math::GMPz::Rmpz_and($r, $x, $y);
    bless \$r;
}

#
## OR
#

sub or {    # used in overloading
    my ($x, $y) = @_;

    $x = _any2mpz($$x) // (goto &nan);
    $y = (ref($y) eq __PACKAGE__ ? _any2mpz($$y) : _star2mpz($y)) // (goto &nan);

    my $r = Math::GMPz::Rmpz_init();
    Math::GMPz::Rmpz_ior($r, $x, $y);
    bless \$r;
}

#
## XOR
#

sub xor {    # used in overloading
    my ($x, $y) = @_;

    $x = _any2mpz($$x) // (goto &nan);
    $y = (ref($y) eq __PACKAGE__ ? _any2mpz($$y) : _star2mpz($y)) // (goto &nan);

    my $r = Math::GMPz::Rmpz_init();
    Math::GMPz::Rmpz_xor($r, $x, $y);
    bless \$r;
}

#
## NOT
#

sub not {    # used in overloading
    my ($x) = @_;
    $x = _any2mpz($$x) // (goto &nan);
    my $r = Math::GMPz::Rmpz_init();
    Math::GMPz::Rmpz_com($r, $x);
    bless \$r;
}

#
## LEFT SHIFT
#

sub lsft {    # used in overloading
    my ($x, $y) = @_;

    $x = (ref($x) eq __PACKAGE__ ? _any2mpz($$x) : _star2mpz($x)) // goto &nan;

    if (!ref($y) and CORE::int($y) eq $y and $y > LONG_MIN and $y < ULONG_MAX) {
        ## `y` is a native integer
    }
    else {
        $y = (ref($y) eq __PACKAGE__ ? _any2si($$y) : _any2si(_star2obj($y))) // goto &nan;
    }

    my $r = Math::GMPz::Rmpz_init();

    $y < 0
      ? Math::GMPz::Rmpz_div_2exp($r, $x, -$y)
      : Math::GMPz::Rmpz_mul_2exp($r, $x, $y);

    bless \$r;
}

#
## RIGHT SHIFT
#

sub rsft {    # used in overloading
    my ($x, $y) = @_;

    $x = (ref($x) eq __PACKAGE__ ? _any2mpz($$x) : _star2mpz($x)) // goto &nan;

    if (!ref($y) and CORE::int($y) eq $y and $y > LONG_MIN and $y < ULONG_MAX) {
        ## `y` is a native integer
    }
    else {
        $y = (ref($y) eq __PACKAGE__ ? _any2si($$y) : _any2si(_star2obj($y))) // goto &nan;
    }

    my $r = Math::GMPz::Rmpz_init();

    $y < 0
      ? Math::GMPz::Rmpz_mul_2exp($r, $x, -$y)
      : Math::GMPz::Rmpz_div_2exp($r, $x, $y);

    bless \$r;
}

#
## POPCOUNT
#

sub popcount ($) {
    my ($x) = @_;

    $x = (ref($x) eq __PACKAGE__ ? _any2mpz($$x) : _any2mpz(_star2obj($x))) // return -1;

    if (Math::GMPz::Rmpz_sgn($x) < 0) {
        my $t = Math::GMPz::Rmpz_init();
        Math::GMPz::Rmpz_neg($t, $x);
        $x = $t;
    }

    Math::GMPz::Rmpz_popcount($x);
}

#
## Conversions
#

sub as_bin ($) {
    Math::GMPz::Rmpz_get_str((_star2mpz($_[0]) // return undef), 2);
}

sub as_oct ($) {
    Math::GMPz::Rmpz_get_str((_star2mpz($_[0]) // return undef), 8);
}

sub as_hex ($) {
    Math::GMPz::Rmpz_get_str((_star2mpz($_[0]) // return undef), 16);
}

sub as_int ($;$) {
    my ($x, $y) = @_;

    my $base = 10;
    if (defined($y)) {

        if (!ref($y) and CORE::int($y) eq $y) {
            $base = $y;
        }
        elsif (ref($y) eq __PACKAGE__) {
            $base = _any2ui($$y) // 0;
        }
        else {
            $base = _any2ui(_star2mpz($y) // return undef) // 0;
        }

        if ($base < 2 or $base > 36) {
            require Carp;
            Carp::croak("base must be between 2 and 36, got $y");
        }
    }

    Math::GMPz::Rmpz_get_str((_star2mpz($x) // return undef), $base);
}

sub as_frac ($;$) {
    my ($x, $y) = @_;

    my $base = 10;
    if (defined($y)) {

        if (!ref($y) and CORE::int($y) eq $y) {
            $base = $y;
        }
        elsif (ref($y) eq __PACKAGE__) {
            $base = _any2ui($$y) // 0;
        }
        else {
            $base = _any2ui(_star2mpz($y) // return undef) // 0;
        }

        if ($base < 2 or $base > 36) {
            require Carp;
            Carp::croak("base must be between 2 and 36, got $y");
        }
    }

    $x = ref($x) eq __PACKAGE__ ? $$x : _star2obj($x);

    my $ref = ref($x);
    if (   $ref eq 'Math::GMPq'
        or $ref eq 'Math::GMPz') {
        my $frac = (
                    $ref eq 'Math::GMPq'
                    ? Math::GMPq::Rmpq_get_str($x, $base)
                    : Math::GMPz::Rmpz_get_str($x, $base)
                   );
        $frac .= '/1' if (index($frac, '/') == -1);
        return $frac;
    }

    $x = _any2mpq($x) // return undef;

    my $frac = Math::GMPq::Rmpq_get_str($x, $base);
    $frac .= '/1' if (index($frac, '/') == -1);
    $frac;
}

sub as_dec ($;$) {
    my ($x, $y) = @_;
    require Math::AnyNum::stringify;

    my $prec = $PREC;
    if (defined($y)) {
        if (!ref($y) and CORE::int($y) eq $y) {
            $prec = $y;
        }
        elsif (ref($y) eq __PACKAGE__) {
            $prec = _any2ui($$y) // 0;
        }
        else {
            $prec = _any2ui(_star2mpz($y) // return undef) // 0;
        }

        $prec <<= 2;

        state $min_prec = Math::MPFR::RMPFR_PREC_MIN();
        state $max_prec = Math::MPFR::RMPFR_PREC_MAX();

        if ($prec < $min_prec or $prec > $max_prec) {
            require Carp;
            Carp::croak("precision must be between $min_prec and $max_prec, got ", $prec >> 2);
        }
    }

    local $PREC = $prec;
    __stringify__(_star2mpfr_mpc($x));
}

sub rat_approx ($) {
    require Math::AnyNum::stringify;
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
        Math::MPFR::Rmpfr_round($f2, $f1);
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

sub digits ($;$) {
    my ($x, $y) = @_;

    $x = _star2mpz($x) // return;
    $y //= 10;

    if (!ref($y) and CORE::int($y) eq $y and $y > 1 and $y < ULONG_MAX) {

        if ($y <= 10) {
            my @digits = split(//, scalar reverse scalar Math::GMPz::Rmpz_get_str($x, $y));
            pop(@digits) if $digits[-1] eq '-';
            return @digits;
        }

        if ($y == 16) {
            my @digits = split(//, scalar reverse scalar Math::GMPz::Rmpz_get_str($x, $y));
            pop(@digits) if $digits[-1] eq '-';
            return map { hex($_) } @digits;
        }
    }

    $y = _star2mpz($y) // return;

    # Not defined for y <= 1
    if (Math::GMPz::Rmpz_cmp_ui($y, 1) <= 0) {
        return;
    }

    # Return faster when y <= 10
    if (Math::GMPz::Rmpz_cmp_ui($y, 10) <= 0) {
        my @digits = split(//, scalar reverse scalar Math::GMPz::Rmpz_get_str($x, Math::GMPz::Rmpz_get_ui($y)));
        pop(@digits) if $digits[-1] eq '-';
        return @digits;
    }

    my @digits;
    my $t = Math::GMPz::Rmpz_init_set($x);

    my $sgn = Math::GMPz::Rmpz_sgn($t);

    if ($sgn == 0) {
        return (zero());
    }
    elsif ($sgn < 0) {
        Math::GMPz::Rmpz_abs($t, $t);
    }

    while (Math::GMPz::Rmpz_sgn($t) > 0) {
        my $m = Math::GMPz::Rmpz_init();
        Math::GMPz::Rmpz_divmod($t, $m, $t, $y);
        push @digits, bless \$m;
    }

    return @digits;
}

1;    # End of Math::AnyNum
