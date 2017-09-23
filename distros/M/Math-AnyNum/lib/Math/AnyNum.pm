package Math::AnyNum;

use 5.014;
use strict;
use warnings;

no warnings qw(numeric uninitialized);

use Math::MPFR qw();
use Math::GMPq qw();
use Math::GMPz qw();
use Math::MPC qw();

use POSIX qw(ULONG_MAX LONG_MIN);

our $VERSION = '0.12';
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

  '&' => sub { $_[0]->and($_[1]) },
  '|' => sub { $_[0]->or($_[1]) },
  '^' => sub { $_[0]->xor($_[1]) },
  '~' => \&not,

  '>'  => sub { $_[2] ? (goto &lt) : (goto &gt) },
  '>=' => sub { $_[2] ? (goto &le) : (goto &ge) },
  '<'  => sub { $_[2] ? (goto &gt) : (goto &lt) },
  '<=' => sub { $_[2] ? (goto &ge) : (goto &le) },

  '<=>' => sub { $_[2] ? -($_[0]->cmp($_[1]) // return undef) : $_[0]->cmp($_[1]) },

  '>>' => sub { @_ = ($_[1], $_[0]) if $_[2]; goto &rsft },
  '<<' => sub { @_ = ($_[1], $_[0]) if $_[2]; goto &lsft },
  '**' => sub { @_ = ($_[1], $_[0]) if $_[2]; goto &pow },
  '%'  => sub { @_ = ($_[1], $_[0]) if $_[2]; goto &mod },
  '/'  => sub { @_ = ($_[1], $_[0]) if $_[2]; goto &div },
  '-'  => sub { @_ = ($_[1], $_[0]) if $_[2]; goto &sub },

  atan2 => sub { &atan2($_[2] ? ($_[1], $_[0]) : ($_[0], $_[1])) },

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
        sin   => sub (_) { goto &sin },     # built-in function
        sinh  => sub ($) { goto &sinh },
        asin  => sub ($) { goto &asin },
        asinh => sub ($) { goto &asinh },

        cos   => sub (_) { goto &cos },     # built-in function
        cosh  => sub ($) { goto &cosh },
        acos  => sub ($) { goto &acos },
        acosh => sub ($) { goto &acosh },

        tan   => sub ($) { goto &tan },
        tanh  => sub ($) { goto &tanh },
        atan  => sub ($) { goto &atan },
        atanh => sub ($) { goto &atanh },

        cot   => sub ($) { goto &cot },
        coth  => sub ($) { goto &coth },
        acot  => sub ($) { goto &acot },
        acoth => sub ($) { goto &acoth },

        sec   => sub ($) { goto &sec },
        sech  => sub ($) { goto &sech },
        asec  => sub ($) { goto &asec },
        asech => sub ($) { goto &asech },

        csc   => sub ($) { goto &csc },
        csch  => sub ($) { goto &csch },
        acsc  => sub ($) { goto &acsc },
        acsch => sub ($) { goto &acsch },

        atan2   => sub ($$) { goto &atan2 },
        deg2rad => sub ($)  { goto &deg2rad },
        rad2deg => sub ($)  { goto &rad2deg },
               );

    my %special = (
                   beta     => sub ($$)  { goto &beta },
                   zeta     => sub ($)   { goto &zeta },
                   eta      => sub ($)   { goto &eta },
                   gamma    => sub ($)   { goto &gamma },
                   lgamma   => sub ($)   { goto &lgamma },
                   lngamma  => sub ($)   { goto &lngamma },
                   digamma  => sub ($)   { goto &digamma },
                   Ai       => sub ($)   { goto &Ai },
                   Ei       => sub ($)   { goto &Ei },
                   Li       => sub ($)   { goto &Li },
                   Li2      => sub ($)   { goto &Li2 },
                   LambertW => sub ($)   { goto &LambertW },
                   BesselJ  => sub ($$)  { goto &BesselJ },
                   BesselY  => sub ($$)  { goto &BesselY },
                   lgrt     => sub ($)   { goto &lgrt },
                   pow      => sub ($$)  { goto &pow },
                   sqr      => sub ($)   { goto &sqr },
                   norm     => sub ($)   { goto &norm },
                   sqrt     => sub (_)   { goto &sqrt },       # built-in function
                   cbrt     => sub ($)   { goto &cbrt },
                   root     => sub ($$)  { goto &root },
                   exp      => sub (_)   { goto &exp },        # built-in function
                   exp2     => sub ($)   { goto &exp2 },
                   exp10    => sub ($)   { goto &exp10 },
                   ln       => sub ($)   { goto &ln },
                   log      => sub (_;$) { goto &log },        # built-in function
                   log2     => sub ($)   { goto &log2 },
                   log10    => sub ($)   { goto &log10 },
                   mod      => sub ($$)  { goto &mod },
                   abs      => sub (_)   { goto &abs },        # built-in function
                   erf      => sub ($)   { goto &erf },
                   erfc     => sub ($)   { goto &erfc },
                   hypot    => sub ($$)  { goto &hypot },
                   agm      => sub ($$)  { goto &agm },
                   bernreal => sub ($)   { goto &bernreal },
                   harmreal => sub ($)   { goto &harmreal },
                  );

    my %ntheory = (
        factorial  => sub ($)  { goto &factorial },
        dfactorial => sub ($)  { goto &dfactorial },
        mfactorial => sub ($$) { goto &mfactorial },
        primorial  => sub ($)  { goto &primorial },
        binomial   => sub ($$) { goto &binomial },

        rising_factorial  => sub ($$) { goto &rising_factorial },
        falling_factorial => sub ($$) { goto &falling_factorial },

        lucas     => sub ($) { goto &lucas },
        fibonacci => sub ($) { goto &fibonacci },

        bernfrac => sub ($) { goto &bernfrac },
        harmfrac => sub ($) { goto &harmfrac },

        lcm       => sub ($$) { goto &lcm },
        gcd       => sub ($$) { goto &gcd },
        valuation => sub ($$) { goto &valuation },
        kronecker => sub ($$) { goto &kronecker },

        remdiv => sub ($$) { goto &remdiv },
        divmod => sub ($$) { goto &divmod },

        iadd => sub ($$) { goto &iadd },
        isub => sub ($$) { goto &isub },
        imul => sub ($$) { goto &imul },
        idiv => sub ($$) { goto &idiv },
        imod => sub ($$) { goto &imod },

        ipow   => sub ($$) { goto &ipow },
        ipow2  => sub ($)  { goto &ipow2 },
        ipow10 => sub ($)  { goto &ipow10 },

        iroot => sub ($$) { goto &iroot },
        isqrt => sub ($)  { goto &isqrt },
        icbrt => sub ($)  { goto &icbrt },

        ilog   => sub ($;$) { goto &ilog },
        ilog2  => sub ($)   { goto &ilog2 },
        ilog10 => sub ($)   { goto &ilog10 },

        isqrtrem => sub ($)  { goto &isqrtrem },
        irootrem => sub ($$) { goto &irootrem },

        powmod => sub ($$$) { goto &powmod },
        invmod => sub ($$)  { goto &invmod },

        is_power   => sub ($;$) { goto &is_power },
        is_square  => sub ($)   { goto &is_square },
        is_prime   => sub ($;$) { goto &is_prime },
        is_coprime => sub ($$)  { goto &is_coprime },
        next_prime => sub ($)   { goto &next_prime },
                  );

    my %misc = (
        rand => sub (;$;$) {    # built-in function
            @_ ? (goto &rand) : do { (@_) = one(); goto &rand }
        },
        irand => sub ($;$) { goto &irand },

        seed  => sub ($) { goto &seed },
        iseed => sub ($) { goto &iseed },

        floor => sub ($)   { goto &floor },
        ceil  => sub ($)   { goto &ceil },
        round => sub ($;$) { goto &round },
        sgn   => sub ($)   { goto &sgn },

        popcount => sub ($) { goto &popcount },

        neg   => sub ($) { goto &neg },
        inv   => sub ($) { goto &inv },
        conj  => sub ($) { goto &conj },
        real  => sub ($) { goto &real },
        imag  => sub ($) { goto &imag },
        reals => sub ($) { goto &reals },

        int     => sub (_) { goto &int },       # built-in function
        rat     => sub ($) { goto &rat },
        float   => sub ($) { goto &float },
        complex => sub ($) { goto &complex },

        numerator   => sub ($) { goto &numerator },
        denominator => sub ($) { goto &denominator },
        nude        => sub ($) { goto &nude },

        digits => sub ($;$) { goto &digits },

        as_bin  => sub ($)   { goto &as_bin },
        as_hex  => sub ($)   { goto &as_hex },
        as_oct  => sub ($)   { goto &as_oct },
        as_int  => sub ($;$) { goto &as_int },
        as_frac => sub ($;$) { goto &as_frac },
        as_dec  => sub ($;$) { goto &as_dec },

        rat_approx => sub ($) { goto &rat_approx },

        is_inf     => sub ($) { goto &is_inf },
        is_ninf    => sub ($) { goto &is_ninf },
        is_neg     => sub ($) { goto &is_neg },
        is_pos     => sub ($) { goto &is_pos },
        is_nan     => sub ($) { goto &is_nan },
        is_rat     => sub ($) { goto &is_rat },
        is_real    => sub ($) { goto &is_real },
        is_imag    => sub ($) { goto &is_imag },
        is_int     => sub ($) { goto &is_int },
        is_complex => sub ($) { goto &is_complex },
        is_zero    => sub ($) { goto &is_zero },
        is_one     => sub ($) { goto &is_one },
        is_mone    => sub ($) { goto &is_mone },

        is_odd  => sub ($)  { goto &is_odd },
        is_even => sub ($)  { goto &is_even },
        is_div  => sub ($$) { goto &is_div },
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
        overload::remove_constant('binary', '', 'float', '', 'integer');
    }
}

# Converts a string into an mpq object
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
    if (CORE::int($s) eq $s and $s >= LONG_MIN and $s <= ULONG_MAX) {
        return (
                $s < 0
                ? Math::GMPz::Rmpz_init_set_si($s)
                : Math::GMPz::Rmpz_init_set_ui($s)
               );
    }

    # Complex number
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

            my $r = Math::MPC::Rmpc_init2($PREC);

            $re = _str2obj($re);
            $im = _str2obj($im);

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
            else {    # this should never happen
                $re = _any2mpfr($re);
                $im = _any2mpfr($im);
                Math::MPC::Rmpc_set_fr_fr($r, $re, $im, $ROUND);
            }

            return $r;
        }
    }

    # Floating point value
    if ($s =~ tr/e.//) {
        my $r = Math::MPFR::Rmpfr_init2($PREC);
        if (Math::MPFR::Rmpfr_set_str($r, $s, 10, $ROUND)) {
            Math::MPFR::Rmpfr_set_nan($r);
        }
        return $r;
    }

    # Fractional value
    if (index($s, '/') != -1 and $s =~ m{^\s*[-+]?[0-9]+\s*/\s*[-+]?[1-9]+[0-9]*\s*\z}) {
        my $r = Math::GMPq::Rmpq_init();
        Math::GMPq::Rmpq_set_str($r, $s, 10);
        Math::GMPq::Rmpq_canonicalize($r);
        return $r;
    }

    $s =~ s/^\+//;

    eval { Math::GMPz::Rmpz_init_set_str($s, 10) } // goto &_nan;
}

# Parse a base-10 string as a base-10 fraction
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

    my $i;
    if (($i = index($str, 'e')) != -1) {

        my $exp = substr($str, $i + 1);

        # Handle specially numbers with very big exponents
        # (not a very good solution, but this will happen very rarely, if ever)
        if (CORE::abs($exp) >= 1000000) {
            Math::MPFR::Rmpfr_set_str((my $mpfr = Math::MPFR::Rmpfr_init2($PREC)), "$sign$str", 10, $ROUND);
            Math::MPFR::Rmpfr_get_q((my $mpq = Math::GMPq::Rmpq_init()), $mpfr);
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
                return _str2frac("$sign$s");
            }
        }

        "$sign$numerator/$denominator";
    }
    elsif (($i = index($str, '.')) != -1) {
        my ($before, $after) = (substr($str, 0, $i), substr($str, $i + 1));
        if (($after =~ tr/0//) == CORE::length($after)) {
            return "$sign$before";
        }
        $sign . ("$before$after/1" =~ s/^0+//r) . ('0' x CORE::length($after));
    }
    else {
        "$sign$str";
    }
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

    if (ref($x) eq 'Math::GMPz') {
        my $d = CORE::int(Math::GMPz::Rmpz_get_d($x));
        ($d < 0 or $d > ULONG_MAX) && return;
        return $d;
    }

    if (ref($x) eq 'Math::GMPq') {
        my $d = CORE::int(Math::GMPq::Rmpq_get_d($x));
        ($d < 0 or $d > ULONG_MAX) && return;
        return $d;
    }

    if (ref($x) eq 'Math::MPFR') {
        if (Math::MPFR::Rmpfr_number_p($x)) {
            my $d = CORE::int(Math::MPFR::Rmpfr_get_d($x, $ROUND));
            ($d < 0 or $d > ULONG_MAX) && return;
            return $d;
        }
        return;
    }

    (@_) = _any2mpfr($x);
    goto &_any2ui;
}

sub _any2si {
    my ($x) = @_;

    if (ref($x) eq 'Math::GMPz') {
        my $d = CORE::int(Math::GMPz::Rmpz_get_d($x));
        ($d < LONG_MIN or $d > ULONG_MAX) && return;
        return $d;
    }

    if (ref($x) eq 'Math::GMPq') {
        my $d = CORE::int(Math::GMPq::Rmpq_get_d($x));
        ($d < LONG_MIN or $d > ULONG_MAX) && return;
        return $d;
    }

    if (ref($x) eq 'Math::MPFR') {
        if (Math::MPFR::Rmpfr_number_p($x)) {
            my $d = CORE::int(Math::MPFR::Rmpfr_get_d($x, $ROUND));
            ($d < LONG_MIN or $d > ULONG_MAX) && return;
            return $d;
        }
        return;
    }

    (@_) = _any2mpfr($x);
    goto &_any2si;
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
    elsif (
           ref($x)
           and (   ref($x) eq 'Math::GMPz'
                or ref($x) eq 'Math::GMPq'
                or ref($x) eq 'Math::MPFR'
                or ref($x) eq 'Math::MPC')
      ) {
        $x;
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

            if (Math::GMPq::Rmpq_get_str($r, 10) !~ m{^\s*[-+]?[0-9]+\s*/\s*[-+]?[1-9]+[0-9]*\s*\z}) {
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

sub stringify {
    require Math::AnyNum::stringify;
    (@_) = (${$_[0]});
    goto &__stringify__;
}

sub numify {
    require Math::AnyNum::numify;
    (@_) = (${$_[0]});
    goto &__numify__;
}

sub boolify {
    require Math::AnyNum::boolify;
    (@_) = (${$_[0]});
    goto &__boolify__;
}

#
## EQUALITY
#

sub eq {
    require Math::AnyNum::eq;
    my ($x, $y) = @_;

    if (ref($y) eq __PACKAGE__) {
        (@_) = ($$x, $$y);
        goto &__eq__;
    }

    if (!ref($y)) {
        if (CORE::int($y) eq $y and $y <= ULONG_MAX and $y >= LONG_MIN) {
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

sub ne {
    require Math::AnyNum::ne;
    my ($x, $y) = @_;

    if (ref($y) eq __PACKAGE__) {
        (@_) = ($$x, $$y);
        goto &__ne__;
    }

    if (!ref($y)) {
        if (CORE::int($y) eq $y and $y <= ULONG_MAX and $y >= LONG_MIN) {
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

sub cmp {
    require Math::AnyNum::cmp;
    my ($x, $y) = @_;

    if (ref($y) eq __PACKAGE__) {
        (@_) = ($$x, $$y);
        goto &__cmp__;
    }

    if (!ref($y)) {
        if (CORE::int($y) eq $y and $y <= ULONG_MAX and $y >= LONG_MIN) {
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

#
## GREATER THAN
#

sub gt {
    require Math::AnyNum::cmp;
    my ($x, $y) = @_;

    if (ref($y) eq __PACKAGE__) {
        return ((__cmp__($$x, $$y) // return undef) > 0);
    }

    if (!ref($y)) {
        if (CORE::int($y) eq $y and $y <= ULONG_MAX and $y >= LONG_MIN) {
            return ((__cmp__($$x, $y) // return undef) > 0);
        }
        return ((__cmp__($$x, _str2obj($y)) // return undef) > 0);
    }

    (__cmp__($$x, _star2obj($y)) // return undef) > 0;
}

#
## EQUAL OR GREATER THAN
#

sub ge {
    require Math::AnyNum::cmp;
    my ($x, $y) = @_;

    if (ref($y) eq __PACKAGE__) {
        return ((__cmp__($$x, $$y) // return undef) >= 0);
    }

    if (!ref($y)) {
        if (CORE::int($y) eq $y and $y <= ULONG_MAX and $y >= LONG_MIN) {
            return ((__cmp__($$x, $y) // return undef) >= 0);
        }
        return ((__cmp__($$x, _str2obj($y)) // return undef) >= 0);
    }

    (__cmp__($$x, _star2obj($y)) // return undef) >= 0;
}

#
## LESS THAN
#

sub lt {
    require Math::AnyNum::cmp;
    my ($x, $y) = @_;

    if (ref($y) eq __PACKAGE__) {
        return ((__cmp__($$x, $$y) // return undef) < 0);
    }

    if (!ref($y)) {
        if (CORE::int($y) eq $y and $y <= ULONG_MAX and $y >= LONG_MIN) {
            return ((__cmp__($$x, $y) // return undef) < 0);
        }
        return ((__cmp__($$x, _str2obj($y)) // return undef) < 0);
    }

    (__cmp__($$x, _star2obj($y)) // return undef) < 0;
}

#
## EQUAL OR LESS THAN
#

sub le {
    require Math::AnyNum::cmp;
    my ($x, $y) = @_;

    if (ref($y) eq __PACKAGE__) {
        return ((__cmp__($$x, $$y) // return undef) <= 0);
    }

    if (!ref($y)) {
        if (CORE::int($y) eq $y and $y <= ULONG_MAX and $y >= LONG_MIN) {
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

sub copy {
    my ($x) = @_;
    bless \_copy($$x);
}

#
## CONVERSION TO INTEGER
#

sub int {
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

sub rat {
    my ($x) = @_;
    if (ref($x) eq __PACKAGE__) {
        ref($$x) eq 'Math::GMPq' && return $x;
        bless \(_any2mpq($$x) // (goto &nan));
    }
    else {

        # Parse a decimal number as an exact fraction
        if ("$x" =~ /^([+-]?+(?=\.?[0-9])[0-9_]*+(?:\.[0-9_]++)?(?:[Ee](?:[+-]?+[0-9_]+))?)\z/) {
            my $frac = _str2frac(lc($1));
            my $q    = Math::GMPq::Rmpq_init();
            Math::GMPq::Rmpq_set_str($q, $frac, 10);
            Math::GMPq::Rmpq_canonicalize($q) if (index($frac, '/') != -1);
            return bless \$q;
        }

        my $r = __PACKAGE__->new($x);
        ref($$r) eq 'Math::GMPq' && return $r;
        bless(\_any2mpq($$r) // goto &nan);
    }
}

#
## CONVERSION TO FLOATING-POINT
#

sub float {
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

sub complex {
    my ($x) = @_;
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

sub neg {
    require Math::AnyNum::neg;
    my ($x) = @_;
    bless \__neg__(ref($x) eq __PACKAGE__ ? $$x : _star2obj($x));
}

#
## ABSOLUTE VALUE
#

sub abs {
    require Math::AnyNum::abs;
    my ($x) = @_;
    bless \__abs__(ref($x) eq __PACKAGE__ ? $$x : _star2obj($x));
}

#
## MULTIPLICATIVE INVERSE
#

sub inv {
    require Math::AnyNum::inv;
    my ($x) = @_;
    bless \__inv__(ref($x) eq __PACKAGE__ ? $$x : _star2obj($x));
}

#
## INCREMENTATION BY ONE
#

sub inc {
    require Math::AnyNum::inc;
    my ($x) = @_;
    bless \__inc__($$x);
}

#
## DECREMENTATION BY ONE
#

sub dec {
    require Math::AnyNum::dec;
    my ($x) = @_;
    bless \__dec__($$x);
}

sub conj {
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

sub real {
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

sub imag {
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

sub reals {
    my ($x) = @_;

    if (ref($x) ne __PACKAGE__) {
        $x = __PACKAGE__->new($x);
    }

    ($x->real, $x->imag);
}

#
## ADDITION
#

sub add {
    require Math::AnyNum::add;
    my ($x, $y) = @_;

    if (ref($y) eq __PACKAGE__) {
        return bless \__add__($$x, $$y);
    }

    $x = $$x;

    if (!ref($y)) {
        if (CORE::int($y) eq $y and $y <= ULONG_MAX and $y >= LONG_MIN) {
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

sub sub {
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
        if (CORE::int($y) eq $y and $y <= ULONG_MAX and $y >= LONG_MIN) {
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

sub mul {
    require Math::AnyNum::mul;
    my ($x, $y) = @_;

    if (ref($y) eq __PACKAGE__) {
        return bless \__mul__($$x, $$y);
    }

    $x = $$x;

    if (!ref($y)) {
        if (CORE::int($y) eq $y and $y <= ULONG_MAX and $y >= LONG_MIN) {
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

sub div {
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
        if (CORE::int($y) eq $y and $y <= ULONG_MAX and $y >= LONG_MIN and CORE::int($y)) {
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

sub iadd {
    my ($x, $y) = @_;

    if (!ref($x) and ref($y)) {
        ($x, $y) = ($y, $x);
    }

    $x = _star2mpz($x) // goto &nan;

    if (!ref($y) and CORE::int($y) eq $y and CORE::int($y) and CORE::abs($y) <= ULONG_MAX) {
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

sub isub {
    my ($x, $y) = @_;

    $x = _star2mpz($x) // goto &nan;

    if (!ref($y) and CORE::int($y) eq $y and CORE::int($y) and CORE::abs($y) <= ULONG_MAX) {
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

sub imul {
    my ($x, $y) = @_;

    if (!ref($x) and ref($y)) {
        ($x, $y) = ($y, $x);
    }

    $x = _star2mpz($x) // goto &nan;

    if (!ref($y) and CORE::int($y) eq $y and CORE::int($y) and CORE::abs($y) <= ULONG_MAX) {
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

sub idiv {
    my ($x, $y) = @_;

    $x = _star2mpz($x) // goto &nan;

    if (!ref($y) and CORE::int($y) eq $y and CORE::int($y) and CORE::abs($y) <= ULONG_MAX) {
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

sub pow {
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
        if (CORE::int($y) eq $y and $y <= ULONG_MAX and $y >= LONG_MIN) {
            return bless \__pow__($x, $y);
        }

        return bless \__pow__($x, _str2obj($y));
    }

    bless \__pow__($x, _star2obj($y));
}

#
## INTEGER POWER
#

sub ipow {
    my ($x, $y) = @_;

    # Both `x` and `y` are strings
    if (    !ref($x)
        and !ref($y)
        and CORE::int($x) eq $x
        and $x >= 0
        and $x <= ULONG_MAX
        and CORE::int($y) eq $y
        and $y >= 0
        and $y <= ULONG_MAX) {

        my $r = Math::GMPz::Rmpz_init();
        Math::GMPz::Rmpz_ui_pow_ui($r, $x, $y);
        return bless \$r;
    }

    $x = (ref($x) eq __PACKAGE__ ? _any2mpz($$x) : _star2mpz($x)) // (goto &nan);

    if (!ref($y) and CORE::int($y) eq $y and CORE::abs($y) <= ULONG_MAX) {
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

sub ipow2 {
    my ($n) = @_;

    if (ref($n) eq __PACKAGE__) {
        $n = _any2si($$n) // goto &nan;
    }
    elsif (    !ref($n)
           and CORE::int($n) eq $n
           and $n >= LONG_MIN
           and $n <= ULONG_MAX) {
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

sub ipow10 {
    my ($n) = @_;

    if (ref($n) eq __PACKAGE__) {
        $n = _any2si($$n) // goto &nan;
    }
    elsif (    !ref($n)
           and CORE::int($n) eq $n
           and $n >= LONG_MIN
           and $n <= ULONG_MAX) {
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

sub root {
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
## isqrt
#

sub isqrt {
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

sub icbrt {
    require Math::AnyNum::iroot;
    bless \__iroot__(_star2mpz($_[0]) // (goto &nan), 3);
}

#
## IROOT
#

sub iroot {
    require Math::AnyNum::iroot;
    my ($x, $y) = @_;

    $x = (ref($x) eq __PACKAGE__ ? _any2mpz($$x) : _star2mpz($x)) // (goto &nan);

    if (ref($y) eq __PACKAGE__) {
        return bless \__iroot__($x, _any2si($$y) // (goto &nan));
    }

    if (!ref($y)) {
        if (CORE::int($y) eq $y and CORE::abs($y) <= ULONG_MAX) {
            return bless \__iroot__($x, $y);
        }

        return bless \__iroot__($x, _any2si(_str2obj($y)) // (goto &nan));
    }

    bless \__iroot__($x, _any2si(_star2obj($y)) // (goto &nan));
}

#
## ISQRTREM
#

sub isqrtrem {
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

sub irootrem {
    my ($x, $y) = @_;

    $x = (ref($x) eq __PACKAGE__ ? _any2mpz($$x) : _star2mpz($x)) // return (nan(), nan());

    if (!ref($y) and CORE::int($y) eq $y and $y <= ULONG_MAX and $y >= LONG_MIN) {
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

sub mod {
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
            and $y <= ULONG_MAX) {
            return bless \__mod__($x, $y);
        }

        return bless \__mod__($x, _str2obj($y));
    }

    bless \__mod__($x, _star2obj($y));
}

#
## IMOD
#

sub imod {
    my ($x, $y) = @_;

    $x = (ref($x) eq __PACKAGE__ ? _any2mpz($$x) : _star2mpz($x)) // (goto &nan);

    if (!ref($y) and CORE::int($y) eq $y and CORE::abs($y) <= ULONG_MAX) {

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
## DIVMOD
#

sub divmod {
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

sub is_div {
    require Math::AnyNum::eq;
    (@_) = (${mod($_[0], $_[1])}, 0);
    goto &__eq__;
}

#
## SPECIAL
#

sub ln {
    require Math::AnyNum::log;
    bless \__log__(_star2mpfr_mpc($_[0]));
}

sub log2 {
    require Math::AnyNum::log;
    bless \__log2__(_star2mpfr_mpc($_[0]));
}

sub log10 {
    require Math::AnyNum::log;
    bless \__log10__(_star2mpfr_mpc($_[0]));
}

sub length {
    my ($z) = _star2mpz($_[0]) // return -1;
    CORE::length(Math::GMPz::Rmpz_get_str($z, 10)) - (Math::GMPz::Rmpz_sgn($z) < 0 ? 1 : 0);
}

sub log {
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

sub ilog2 {
    require Math::AnyNum::ilog;
    state $two = Math::GMPz::Rmpz_init_set_ui(2);
    bless \__ilog__((_star2mpz($_[0]) // goto &nan), $two);
}

sub ilog10 {
    require Math::AnyNum::ilog;
    state $ten = Math::GMPz::Rmpz_init_set_ui(10);
    bless \__ilog__((_star2mpz($_[0]) // goto &nan), $ten);
}

sub ilog {
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

sub sqrt {
    require Math::AnyNum::sqrt;
    bless \__sqrt__(_star2mpfr_mpc($_[0]));
}

sub cbrt {
    require Math::AnyNum::cbrt;
    bless \__cbrt__(_star2mpfr_mpc($_[0]));
}

sub sqr {
    require Math::AnyNum::mul;
    my ($x) = @_;

    $x =
      ref($x) eq __PACKAGE__
      ? $$x
      : _star2obj($x);

    bless \__mul__($x, $x);
}

sub norm {
    require Math::AnyNum::norm;
    my ($x) = @_;

    $x =
      ref($x) eq __PACKAGE__
      ? $$x
      : _star2obj($x);

    bless \__norm__($x);
}

sub exp {
    require Math::AnyNum::exp;
    bless \__exp__(_star2mpfr_mpc($_[0]));
}

sub exp2 {
    require Math::AnyNum::pow;
    my ($x) = @_;

    state $base = Math::GMPz::Rmpz_init_set_ui(2);

    if (ref($x) eq __PACKAGE__) {
        bless \__pow__($base, $$x);
    }
    elsif (!ref($x) and CORE::int($x) eq $x and $x >= LONG_MIN and $x <= ULONG_MAX) {
        bless \__pow__($base, $x);
    }
    else {
        bless \__pow__($base, _star2obj($x));
    }
}

sub exp10 {
    require Math::AnyNum::pow;
    my ($x) = @_;

    state $base = Math::GMPz::Rmpz_init_set_ui(10);

    if (ref($x) eq __PACKAGE__) {
        bless \__pow__($base, $$x);
    }
    elsif (!ref($x) and CORE::int($x) eq $x and $x >= LONG_MIN and $x <= ULONG_MAX) {
        bless \__pow__($base, $x);
    }
    else {
        bless \__pow__($base, _star2obj($x));
    }
}

sub floor {
    require Math::AnyNum::floor;
    my ($x) = @_;

    if (ref($x) ne __PACKAGE__) {
        $x = __PACKAGE__->new($x);
    }

    ref($$x) eq 'Math::GMPz' and return $x;    # already an integer
    bless \__floor__($$x);
}

sub ceil {
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

sub sin {
    require Math::AnyNum::sin;
    bless \__sin__(_star2mpfr_mpc($_[0]));
}

sub sinh {
    require Math::AnyNum::sinh;
    bless \__sinh__(_star2mpfr_mpc($_[0]));
}

sub asin {
    require Math::AnyNum::asin;
    bless \__asin__(_star2mpfr_mpc($_[0]));
}

sub asinh {
    require Math::AnyNum::asinh;
    bless \__asinh__(_star2mpfr_mpc($_[0]));
}

#
## cos / cosh / acos / acosh
#

sub cos {
    require Math::AnyNum::cos;
    bless \__cos__(_star2mpfr_mpc($_[0]));
}

sub cosh {
    require Math::AnyNum::cosh;
    bless \__cosh__(_star2mpfr_mpc($_[0]));
}

sub acos {
    require Math::AnyNum::acos;
    bless \__acos__(_star2mpfr_mpc($_[0]));
}

sub acosh {
    require Math::AnyNum::acosh;
    bless \__acosh__(_star2mpfr_mpc($_[0]));
}

#
## tan / tanh / atan / atanh
#

sub tan {
    require Math::AnyNum::tan;
    bless \__tan__(_star2mpfr_mpc($_[0]));
}

sub tanh {
    require Math::AnyNum::tanh;
    bless \__tanh__(_star2mpfr_mpc($_[0]));
}

sub atan {
    require Math::AnyNum::atan;
    bless \__atan__(_star2mpfr_mpc($_[0]));
}

sub atanh {
    require Math::AnyNum::atanh;
    bless \__atanh__(_star2mpfr_mpc($_[0]));
}

sub atan2 {
    require Math::AnyNum::atan2;
    bless \__atan2__(_star2mpfr_mpc($_[0]), _star2mpfr_mpc($_[1]));
}

#
## sec / sech / asec / asech
#

sub sec {
    require Math::AnyNum::sec;
    bless \__sec__(_star2mpfr_mpc($_[0]));
}

sub sech {
    require Math::AnyNum::sech;
    bless \__sech__(_star2mpfr_mpc($_[0]));
}

sub asec {
    require Math::AnyNum::asec;
    bless \__asec__(_star2mpfr_mpc($_[0]));
}

sub asech {
    require Math::AnyNum::asech;
    bless \__asech__(_star2mpfr_mpc($_[0]));
}

#
## csc / csch / acsc / acsch
#

sub csc {
    require Math::AnyNum::csc;
    bless \__csc__(_star2mpfr_mpc($_[0]));
}

sub csch {
    require Math::AnyNum::csch;
    bless \__csch__(_star2mpfr_mpc($_[0]));
}

sub acsc {
    require Math::AnyNum::acsc;
    bless \__acsc__(_star2mpfr_mpc($_[0]));
}

sub acsch {
    require Math::AnyNum::acsch;
    bless \__acsch__(_star2mpfr_mpc($_[0]));
}

#
## cot / coth / acot / acoth
#

sub cot {
    require Math::AnyNum::cot;
    bless \__cot__(_star2mpfr_mpc($_[0]));
}

sub coth {
    require Math::AnyNum::coth;
    bless \__coth__(_star2mpfr_mpc($_[0]));
}

sub acot {
    require Math::AnyNum::acot;
    bless \__acot__(_star2mpfr_mpc($_[0]));
}

sub acoth {
    require Math::AnyNum::acoth;
    bless \__acoth__(_star2mpfr_mpc($_[0]));
}

sub deg2rad {
    require Math::AnyNum::mul;
    my ($x) = @_;
    my $f = Math::MPFR::Rmpfr_init2($PREC);
    Math::MPFR::Rmpfr_const_pi($f, $ROUND);
    Math::MPFR::Rmpfr_div_ui($f, $f, 180, $ROUND);
    bless \__mul__(_star2mpfr_mpc($x), $f);
}

sub rad2deg {
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

sub gamma {
    my $r = Math::MPFR::Rmpfr_init2($PREC);
    Math::MPFR::Rmpfr_gamma($r, _star2mpfr($_[0]), $ROUND);
    bless \$r;
}

#
## lgamma
#

sub lgamma {
    my $r = Math::MPFR::Rmpfr_init2($PREC);
    Math::MPFR::Rmpfr_lgamma($r, _star2mpfr($_[0]), $ROUND);
    bless \$r;
}

#
## lngamma
#

sub lngamma {
    my $r = Math::MPFR::Rmpfr_init2($PREC);
    Math::MPFR::Rmpfr_lngamma($r, _star2mpfr($_[0]), $ROUND);
    bless \$r;
}

#
## digamma
#

sub digamma {
    my $r = Math::MPFR::Rmpfr_init2($PREC);
    Math::MPFR::Rmpfr_digamma($r, _star2mpfr($_[0]), $ROUND);
    bless \$r;
}

#
## zeta
#

sub zeta {
    my ($x) = @_;

    if (!ref($x) and CORE::int($x) eq $x and $x >= 0 and $x <= ULONG_MAX) {
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

sub eta {
    require Math::AnyNum::eta;
    bless \__eta__(_star2mpfr($_[0]));
}

#
## beta
#
sub beta {
    require Math::AnyNum::beta;
    bless \__beta__(_star2mpfr($_[0]), _star2mpfr($_[1]));
}

#
## Airy function (Ai)
#

sub Ai {
    my $r = Math::MPFR::Rmpfr_init2($PREC);
    Math::MPFR::Rmpfr_ai($r, _star2mpfr($_[0]), $ROUND);
    bless \$r;
}

#
## Exponential integral (Ei)
#

sub Ei {
    my $r = Math::MPFR::Rmpfr_init2($PREC);
    Math::MPFR::Rmpfr_eint($r, _star2mpfr($_[0]), $ROUND);
    bless \$r;
}

#
## Logarithmic integral (Li)
#
sub Li {
    my $r = Math::MPFR::Rmpfr_init2($PREC);
    Math::MPFR::Rmpfr_log($r, _star2mpfr($_[0]), $ROUND);
    Math::MPFR::Rmpfr_eint($r, $r, $ROUND);
    bless \$r;
}

#
## Dilogarithm function (Li_2)
#
sub Li2 {
    my $r = Math::MPFR::Rmpfr_init2($PREC);
    Math::MPFR::Rmpfr_li2($r, _star2mpfr($_[0]), $ROUND);
    bless \$r;
}

#
## Error function
#
sub erf {
    my $r = Math::MPFR::Rmpfr_init2($PREC);
    Math::MPFR::Rmpfr_erf($r, _star2mpfr($_[0]), $ROUND);
    bless \$r;
}

#
## Complementary error function
#
sub erfc {
    my $r = Math::MPFR::Rmpfr_init2($PREC);
    Math::MPFR::Rmpfr_erfc($r, _star2mpfr($_[0]), $ROUND);
    bless \$r;
}

#
## Lambert W
#

sub LambertW {
    require Math::AnyNum::LambertW;
    bless \__LambertW__(_star2mpfr_mpc($_[0]));
}

#
## lgrt -- logarithmic root
#

sub lgrt {
    require Math::AnyNum::lgrt;
    bless \__lgrt__(_star2mpfr_mpc($_[0]));
}

#
## agm
#
sub agm {
    require Math::AnyNum::agm;
    bless \__agm__(_star2mpfr_mpc($_[0]), _star2mpfr_mpc($_[1]));
}

#
## hypot
#

sub hypot {
    require Math::AnyNum::hypot;
    bless \__hypot__(_star2mpfr_mpc($_[0]), _star2mpfr_mpc($_[1]));
}

#
## BesselJ
#

sub BesselJ {
    require Math::AnyNum::BesselJ;
    my ($x, $y) = @_;

    $x = ref($x) eq __PACKAGE__ ? _any2mpfr($$x) : _star2mpfr($x);

    if (!ref($y) and CORE::int($y) eq $y and $y <= ULONG_MAX and $y >= LONG_MIN) {
        return bless \__BesselJ__($x, $y);
    }

    bless \__BesselJ__($x, _star2mpz($y) // (goto &nan));
}

#
## BesselY
#

sub BesselY {
    require Math::AnyNum::BesselY;
    my ($x, $y) = @_;

    $x = ref($x) eq __PACKAGE__ ? _any2mpfr($$x) : _star2mpfr($x);

    if (!ref($y) and CORE::int($y) eq $y and $y <= ULONG_MAX and $y >= LONG_MIN) {
        return bless \__BesselY__($x, $y);
    }

    bless \__BesselY__($x, _star2mpz($y) // (goto &nan));
}

#
## ROUND
#

sub round {
    require Math::AnyNum::round;
    my ($x, $y) = @_;

    $x = ref($x) eq __PACKAGE__ ? $$x : _star2obj($x);

    if (!defined($y)) {
        return bless \__round__($x, 0);
    }

    if (!ref($y)) {
        if (CORE::int($y) eq $y and $y >= LONG_MIN and $y <= ULONG_MAX) {
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

        sub rand {
            require Math::AnyNum::mul;
            my ($x, $y) = @_;

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

        sub seed {
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

        sub irand {
            require Math::AnyNum::irand;
            my ($x, $y) = @_;

            $x = (ref($x) eq __PACKAGE__ ? _any2mpz($$x) : _star2mpz($x)) // (goto &nan);

            if (!defined($y)) {
                return bless \__irand__($x, undef, $state);
            }

            $y = (ref($y) eq __PACKAGE__ ? _any2mpz($$y) : _star2mpz($y)) // (goto &nan);
            bless \__irand__($x, $y, $state);
        }

        sub iseed {
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
sub fibonacci {
    my ($x) = @_;

    if (!ref($x) and CORE::int($x) eq $x and $x >= 0 and $x <= ULONG_MAX) {
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
sub lucas {
    my ($x) = @_;

    if (!ref($x) and CORE::int($x) eq $x and $x >= 0 and $x <= ULONG_MAX) {
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
sub primorial {
    my ($x) = @_;

    if (!ref($x) and CORE::int($x) eq $x and $x >= 0 and $x <= ULONG_MAX) {
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

sub bernfrac {
    require Math::AnyNum::bernfrac;
    my ($x) = @_;

    if (!ref($x) and CORE::int($x) eq $x and $x >= 0 and $x <= ULONG_MAX) {
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

sub harmfrac {
    require Math::AnyNum::harmfrac;
    my ($x) = @_;

    if (!ref($x) and CORE::int($x) eq $x and $x >= 0 and $x <= ULONG_MAX) {
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

sub bernreal {
    require Math::AnyNum::bernreal;
    my ($x) = @_;

    if (!ref($x) and CORE::int($x) eq $x and $x >= 0 and $x <= ULONG_MAX) {
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

sub harmreal {
    require Math::AnyNum::harmreal;
    bless \__harmreal__(_star2mpfr($_[0]) // (goto &nan));
}

#
## Factorial
#
sub factorial {
    my ($x) = @_;

    if (!ref($x) and CORE::int($x) eq $x and $x >= 0 and $x <= ULONG_MAX) {
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

sub dfactorial {
    my ($x) = @_;

    if (!ref($x) and CORE::int($x) eq $x and $x >= 0 and $x <= ULONG_MAX) {
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

sub mfactorial {
    my ($x, $y) = @_;

    if (!ref($x) and CORE::int($x) eq $x and $x >= 0 and $x <= ULONG_MAX) {
        ## `x` is an unsigned native integer
    }
    elsif (ref($x) eq __PACKAGE__) {
        $x = _any2ui($$x) // goto &nan;
    }
    else {
        $x = _any2ui(_star2obj($x)) // goto &nan;
    }

    if (!ref($y) and CORE::int($y) eq $y and $y >= 0 and $y <= ULONG_MAX) {
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
sub falling_factorial {
    my ($x, $y) = @_;

    $x = _star2mpz($x) // goto &nan;

    if (ref($y) eq __PACKAGE__) {
        $y = _any2si($$y) // goto &nan;
    }
    elsif (!ref($y) and CORE::int($y) eq $y and $y >= LONG_MIN and $y <= ULONG_MAX) {
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
sub rising_factorial {
    my ($x, $y) = @_;

    $x = _star2mpz($x) // goto &nan;

    if (ref($y) eq __PACKAGE__) {
        $y = _any2si($$y) // goto &nan;
    }
    elsif (!ref($y) and CORE::int($y) eq $y and $y >= LONG_MIN and $y <= ULONG_MAX) {
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
## GCD
#

sub gcd {
    my ($x, $y) = @_;

    if (ref($y) and !ref($x)) {
        ($x, $y) = ($y, $x);
    }

    $x = (ref($x) eq __PACKAGE__ ? _any2mpz($$x) : _star2mpz($x)) // (goto &nan);

    my $r = Math::GMPz::Rmpz_init();

    if (!ref($y) and CORE::int($y) eq $y and CORE::abs($y) <= ULONG_MAX) {
        Math::GMPz::Rmpz_gcd_ui($r, $x, $y);
    }
    else {
        $y = (ref($y) eq __PACKAGE__ ? _any2mpz($$y) : _star2mpz($y)) // (goto &nan);
        Math::GMPz::Rmpz_gcd($r, $x, $y);
    }

    bless \$r;
}

#
## LCM
#

sub lcm {
    my ($x, $y) = @_;

    if (ref($y) and !ref($x)) {
        ($x, $y) = ($y, $x);
    }

    $x = (ref($x) eq __PACKAGE__ ? _any2mpz($$x) : _star2mpz($x)) // (goto &nan);

    my $r = Math::GMPz::Rmpz_init();

    if (!ref($y) and CORE::int($y) eq $y and CORE::abs($y) <= ULONG_MAX) {
        Math::GMPz::Rmpz_lcm_ui($r, $x, $y);
    }
    else {
        $y = (ref($y) eq __PACKAGE__ ? _any2mpz($$y) : _star2mpz($y)) // (goto &nan);
        Math::GMPz::Rmpz_lcm($r, $x, $y);
    }

    bless \$r;
}

#
## next_prime
#

sub next_prime {
    my ($x) = @_;
    $x = (ref($x) eq __PACKAGE__ ? _any2mpz($$x) : _star2mpz($x)) // goto &nan;
    my $r = Math::GMPz::Rmpz_init();
    Math::GMPz::Rmpz_nextprime($r, $x);
    bless \$r;
}

#
## is_prime
#

sub is_prime {
    require Math::AnyNum::is_int;
    my ($x, $y) = @_;

    $x = ref($x) eq __PACKAGE__ ? $$x : _star2obj($x);

    __is_int__($x) || return 0;

    $y = defined($y) ? (CORE::abs(CORE::int($y)) || 20) : 20;
    Math::GMPz::Rmpz_probab_prime_p(_any2mpz($x) // (return 0), $y);
}

sub is_coprime {
    require Math::AnyNum::is_int;
    my ($x, $y) = @_;

    $x = ref($x) eq __PACKAGE__ ? $$x : _star2obj($x);

    __is_int__($x) || return 0;

    $x = _any2mpz($x) // return 0;

    if (!ref($y) and CORE::int($y) eq $y and $y >= 0 and $y <= ULONG_MAX) {
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

sub is_int {
    require Math::AnyNum::is_int;
    my ($x) = @_;
    __is_int__(ref($x) eq __PACKAGE__ ? $$x : _star2obj($x));
}

sub is_rat {
    my ($x) = @_;
    my $ref = ref(ref($x) eq __PACKAGE__ ? $$x : _star2obj($x));
    $ref eq 'Math::GMPz' or $ref eq 'Math::GMPq';
}

sub numerator {
    my ($x) = @_;

    my $r = ref($x) eq __PACKAGE__ ? $$x : _star2obj($x);
    {
        my $ref = ref($r);
        ref($r) eq 'Math::GMPz' && return $x;    # is an integer

        if (ref($r) eq 'Math::GMPq') {
            my $z = Math::GMPz::Rmpz_init();
            Math::GMPq::Rmpq_get_num($z, $r);
            return bless \$z;
        }

        $r = _any2mpq($r) // goto &nan;
        redo;
    }
}

sub denominator {
    my ($x) = @_;

    my $r = ref($x) eq __PACKAGE__ ? $$x : _star2obj($x);
    {
        my $ref = ref($r);
        ref($r) eq 'Math::GMPz' && goto &one;    # is an integer

        if (ref($r) eq 'Math::GMPq') {
            my $z = Math::GMPz::Rmpz_init();
            Math::GMPq::Rmpq_get_den($z, $r);
            return bless \$z;
        }
        $r = _any2mpq($r) // goto &nan;
        redo;
    }
}

sub nude {
    my ($x) = @_;

    if (ref($x) ne __PACKAGE__) {
        $x = __PACKAGE__->new($x);
    }

    ($x->numerator, $x->denominator);
}

sub sgn {
    require Math::AnyNum::sgn;
    my ($x) = @_;
    my $r = __sgn__(ref($x) eq __PACKAGE__ ? $$x : _star2obj($x));
    ref($r) ? (bless \$r) : $r;
}

sub is_real {
    my ($x) = @_;

    my $r = ref($x) eq __PACKAGE__ ? $$x : _star2obj($x);
    {
        my $ref = ref($r);

        $ref eq 'Math::GMPz' && return 1;
        $ref eq 'Math::GMPq' && return 1;
        $ref eq 'Math::MPFR' && return Math::MPFR::Rmpfr_number_p($r);

        $r = _any2mpfr($r);
        redo;
    }
}

sub is_imag {
    my ($x) = @_;

    my $r = ref($x) eq __PACKAGE__ ? $$x : _star2obj($x);
    ref($r) eq 'Math::MPC' or return 0;

    my $f = Math::MPFR::Rmpfr_init2($PREC);
    Math::MPC::RMPC_RE($f, $r);
    Math::MPFR::Rmpfr_zero_p($f) || return 0;    # is complex
    Math::MPC::RMPC_IM($f, $r);
    !Math::MPFR::Rmpfr_zero_p($f);
}

sub is_complex {
    my ($x) = @_;

    my $r = ref($x) eq __PACKAGE__ ? $$x : _star2obj($x);
    ref($r) eq 'Math::MPC' or return 0;

    my $f = Math::MPFR::Rmpfr_init2($PREC);
    Math::MPC::RMPC_IM($f, $r);
    Math::MPFR::Rmpfr_zero_p($f) && return 0;    # is real
    Math::MPC::RMPC_RE($f, $r);
    !Math::MPFR::Rmpfr_zero_p($f);
}

sub is_inf {
    my ($x) = @_;

    my $r = ref($x) eq __PACKAGE__ ? $$x : _star2obj($x);
    {
        my $ref = ref($r);

        $ref eq 'Math::GMPz' && return 0;
        $ref eq 'Math::GMPq' && return 0;
        $ref eq 'Math::MPFR' && return (Math::MPFR::Rmpfr_inf_p($r) and Math::MPFR::Rmpfr_sgn($r) > 0);

        $r = _any2mpfr($r);
        redo;
    }
}

sub is_ninf {
    my ($x) = @_;

    my $r = ref($x) eq __PACKAGE__ ? $$x : _star2obj($x);
    {
        my $ref = ref($r);

        $ref eq 'Math::GMPz' && return 0;
        $ref eq 'Math::GMPq' && return 0;
        $ref eq 'Math::MPFR' && return (Math::MPFR::Rmpfr_inf_p($r) and Math::MPFR::Rmpfr_sgn($r) < 0);

        $r = _any2mpfr($r);
        redo;
    }
}

sub is_nan {
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

sub is_even {
    require Math::AnyNum::is_int;
    my ($x) = @_;

    $x = ref($x) eq __PACKAGE__ ? $$x : _star2obj($x);

    __is_int__($x)
      && Math::GMPz::Rmpz_even_p(_any2mpz($x) // (return 0));
}

sub is_odd {
    require Math::AnyNum::is_int;
    my ($x) = @_;

    $x = ref($x) eq __PACKAGE__ ? $$x : _star2obj($x);

    __is_int__($x)
      && Math::GMPz::Rmpz_odd_p(_any2mpz($x) // (return 0));
}

sub is_zero {
    require Math::AnyNum::eq;
    my ($x) = @_;
    (@_) = ((ref($x) eq __PACKAGE__ ? $$x : _star2obj($x)), 0);
    goto &__eq__;
}

sub is_one {
    require Math::AnyNum::eq;
    my ($x) = @_;
    (@_) = ((ref($x) eq __PACKAGE__ ? $$x : _star2obj($x)), 1);
    goto &__eq__;
}

sub is_mone {
    require Math::AnyNum::eq;
    my ($x) = @_;
    (@_) = ((ref($x) eq __PACKAGE__ ? $$x : _star2obj($x)), -1);
    goto &__eq__;
}

sub is_pos {
    require Math::AnyNum::cmp;
    my ($x) = @_;
    (__cmp__((ref($x) eq __PACKAGE__ ? $$x : _star2obj($x)), 0) // return undef) > 0;
}

sub is_neg {
    require Math::AnyNum::cmp;
    my ($x) = @_;
    (__cmp__((ref($x) eq __PACKAGE__ ? $$x : _star2obj($x)), 0) // return undef) < 0;
}

#
## is_square
#
sub is_square {
    require Math::AnyNum::is_int;
    my ($x, $y) = @_;

    $x = ref($x) eq __PACKAGE__ ? $$x : _star2obj($x);

    __is_int__($x)
      && Math::GMPz::Rmpz_perfect_square_p(_any2mpz($x) // (return 0));
}

#
## is_power
#

sub is_power {
    require Math::AnyNum::is_power;
    require Math::AnyNum::is_int;
    my ($x, $y) = @_;

    $x = ref($x) eq __PACKAGE__ ? $$x : _star2obj($x);

    __is_int__($x) || return 0;
    $x = _any2mpz($x) // goto &nan;

    if (!defined($y)) {
        return Math::GMPz::Rmpz_perfect_power_p($x);
    }

    if (!ref($y) and CORE::int($y) eq $y and $y <= ULONG_MAX and $y >= LONG_MIN) {
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

sub kronecker {
    my ($x, $y) = @_;

    $x = (ref($x) eq __PACKAGE__ ? _any2mpz($$x) : _star2mpz($x)) // goto &nan;
    $y = (ref($y) eq __PACKAGE__ ? _any2mpz($$y) : _star2mpz($y)) // goto &nan;

    Math::GMPz::Rmpz_kronecker($x, $y);
}

#
## valuation
#

sub valuation {
    require Math::AnyNum::valuation;
    my ($x, $y) = @_;

    $x = (ref($x) eq __PACKAGE__ ? _any2mpz($$x) : _star2mpz($x)) // goto &nan;
    $y = (ref($y) eq __PACKAGE__ ? _any2mpz($$y) : _star2mpz($y)) // goto &nan;

    (__valuation__($x, $y))[0];
}

#
## remdiv
#

sub remdiv {
    require Math::AnyNum::valuation;
    my ($x, $y) = @_;

    $x = (ref($x) eq __PACKAGE__ ? _any2mpz($$x) : _star2mpz($x)) // goto &nan;
    $y = (ref($y) eq __PACKAGE__ ? _any2mpz($$y) : _star2mpz($y)) // goto &nan;

    bless \((__valuation__($x, $y))[1]);
}

#
## Invmod
#

sub invmod {
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

sub powmod {
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
## Binomial
#

sub binomial {
    my ($x, $y) = @_;

    # `x` and `y` are native unsigned integers
    if (    !ref($x)
        and !ref($y)
        and CORE::int($x) eq $x
        and CORE::int($y) eq $y
        and $x >= 0
        and $y >= 0
        and $x <= ULONG_MAX
        and $y <= ULONG_MAX) {
        my $r = Math::GMPz::Rmpz_init();
        Math::GMPz::Rmpz_bin_uiui($r, $x, $y);
        return bless \$r;
    }

    $x = (ref($x) eq __PACKAGE__ ? _any2mpz($$x) : _star2mpz($x)) // goto &nan;

    if (!ref($y) and CORE::int($y) eq $y and $y >= LONG_MIN and $y <= ULONG_MAX) {
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
## AND
#

sub and {
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

sub or {
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

sub xor {
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

sub not {
    my ($x) = @_;
    $x = _any2mpz($$x) // (goto &nan);
    my $r = Math::GMPz::Rmpz_init();
    Math::GMPz::Rmpz_com($r, $x);
    bless \$r;
}

#
## LEFT SHIFT
#

sub lsft {
    my ($x, $y) = @_;

    $x = (ref($x) eq __PACKAGE__ ? _any2mpz($$x) : _star2mpz($x)) // (goto &nan);

    if (!ref($y) and CORE::int($y) eq $y and $y >= LONG_MIN and $y <= ULONG_MAX) {
        ## `y` is a native integer
    }
    else {
        $y = (
              ref($y) eq __PACKAGE__
              ? _any2si($$y)
              : _any2si(_star2obj($y))
             ) // (goto &nan);
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

sub rsft {
    my ($x, $y) = @_;

    $x = (ref($x) eq __PACKAGE__ ? _any2mpz($$x) : _star2mpz($x)) // (goto &nan);

    if (!ref($y) and CORE::int($y) eq $y and $y >= LONG_MIN and $y <= ULONG_MAX) {
        ## `y` is a native integer
    }
    else {
        $y = (ref($y) eq __PACKAGE__ ? _any2si($$y) : _any2si(_star2obj($y))) // (goto &nan);
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

sub popcount {
    my ($x) = @_;

    $x = (
          ref($x) eq __PACKAGE__
          ? _any2mpz($$x)
          : _any2mpz(_star2obj($x))
         ) // return -1;

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

sub as_bin {
    Math::GMPz::Rmpz_get_str((_star2mpz($_[0]) // return undef), 2);
}

sub as_oct {
    Math::GMPz::Rmpz_get_str((_star2mpz($_[0]) // return undef), 8);
}

sub as_hex {
    Math::GMPz::Rmpz_get_str((_star2mpz($_[0]) // return undef), 16);
}

sub as_int {
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

sub as_frac {
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

sub as_dec {
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

sub rat_approx {
    require Math::AnyNum::stringify;
    my ($x) = @_;

    $x = _star2mpfr($x);

    Math::MPFR::Rmpfr_number_p($x) || goto &nan;

    my $t = Math::MPFR::Rmpfr_init2($PREC);    # temporary variable
    my $r = Math::MPFR::Rmpfr_init2($PREC);

    Math::MPFR::Rmpfr_set($r, $x, $ROUND);

    my $num2cfrac = sub {
        my ($callback, $n) = @_;

        while (1) {
            Math::MPFR::Rmpfr_floor($t, $r);

            my $z = Math::GMPz::Rmpz_init();
            Math::MPFR::Rmpfr_get_z($z, $t, Math::MPFR::MPFR_RNDZ);

            $callback->($z) && return 1;

            Math::MPFR::Rmpfr_sub($r, $r, $t, $ROUND);
            Math::MPFR::Rmpfr_zero_p($r) && last;
            Math::MPFR::Rmpfr_ui_div($r, 1, $r, $ROUND);
        }
    };

    my $q = Math::GMPq::Rmpq_init();

    my $cfrac2num = sub {
        my (@f) = @_;

        Math::GMPq::Rmpq_set_ui($q, 0, 1);

        for (1 .. $#f) {
            Math::GMPq::Rmpq_add_z($q, $q, CORE::pop(@f));
            Math::GMPq::Rmpq_inv($q, $q);
        }

        Math::GMPq::Rmpq_add_z($q, $q, $f[0]);
    };

    my @cfrac;
    my $s = __stringify__($x);
    my $u = Math::MPFR::Rmpfr_init2($PREC);    # temporary variable

#<<<
    $num2cfrac->(
        sub {
            my ($n) = @_;
            CORE::push(@cfrac, $n);
            $cfrac2num->(@cfrac);
            Math::MPFR::Rmpfr_set_q($u, $q, $ROUND);
            CORE::index(__stringify__($u), $s) == 0;
        }, $x
    );
#>>>

    bless \$q;
}

sub digits {
    my ($x, $y) = @_;
    my $str = as_int($x, $y) // return ();
    my @digits = split(//, $str);
    shift(@digits) if $digits[0] eq '-';
    (@digits);
}

1;    # End of Math::AnyNum
