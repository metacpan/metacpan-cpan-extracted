=head1 NAME

Math::Decimal - arithmetic in decimal

=head1 SYNOPSIS

	use Math::Decimal qw($dec_number_rx);

	if($arg =~ /\A$dec_number_rx\z/o) { ...
	# and other regular expressions

	use Math::Decimal qw(is_dec_number check_dec_number);

	if(is_dec_number($arg)) { ...
	check_dec_number($arg);

	use Math::Decimal qw(dec_canonise);

	$r = dec_canonise($a);

	use Math::Decimal qw(
		dec_sgn dec_abs
		dec_cmp dec_min dec_max
		dec_neg dec_add dec_sub
		dec_pow10 dec_mul_pow10
		dec_mul
		dec_rndiv_and_rem dec_rndiv
		dec_round_and_rem dec_round
		dec_rem
	);

	$v = dec_sgn($a);
	$v = dec_abs($a);
	@v = sort { dec_cmp($a, $b) } @a;
	$v = dec_min($a, $b);
	$v = dec_max($a, $b);
	$v = dec_neg($a);
	$v = dec_add($a, $b);
	$v = dec_sub($a, $b);
	$v = dec_pow10($a);
	$v = dec_mul_pow10($a, $b);
	$v = dec_mul($a, $b);
	($q, $r) = dec_rndiv_and_rem("NEAR_EVN", $a, $b);
	$q = dec_rndiv("NEAR_EVN", $a, $b);
	($v, $r) = dec_round_and_rem("NEAR_EVN", $a, $b);
	$v = dec_round("NEAR_EVN", $a, $b);
	$r = dec_rem("NEAR_EVN", $a, $b);

=head1 DESCRIPTION

This module performs basic arithmetic with arbitrary-precision numbers
expressed in decimal in ordinary Perl strings.  The numbers can be
arbitrarily large, and can involve arbitrarily small fractions, and
all results are exact.  This differs from Perl's standard arithmetic,
which is limited-precision binary (floating point) arithmetic.  However,
because Perl performs implicit conversions between strings and numbers,
using decimal in the string form, it is extremely easy to exchange values
between this module and Perl's native arithmetic.

Although Perl's scalars have space to store a number directly, that is
not used here.  This module operates only on the string part of scalars,
ignoring the Perlish numerics entirely.  It is not confused by dualvars
(scalars with independent string and number values).

Numbers are represented in strings in a simple format, consisting of
optional sign, one or more integer digits, then optionally a dot (for
the decimal point) and one or more fractional digits.  All representable
numbers have infinitely many acceptable representations (by adding leading
and trailing zero digits).  The functions of this module consistently
return numbers in their shortest possible form.

This module is intended for situations where exact numeric behaviour is
important, and Perl's default arithmetic is inadequate because fractions
or large numbers are involved, but the arithmetic makes up only a small
part of the program's behaviour.  In those situations, it is convenient
that the functions here operate directly on strings that are useful
elsewhere in the program.  If arithmetic is a large part of the program,
it will probably be better to use specialised (non-string) numeric object
types, such as those of L<Math::GMP>.  These objects are less convenient
for interoperation, but arithmetic with them is more efficient.

If you need to represent arbitrary (non-decimal) fractions exactly,
such as 1/3, then this module is not suitable.  In that case you need a
general rational arithmetic module, such as L<Math::BigRat>.  Be prepared
to pay a large performance penalty for it.

Most of this module is implemented in XS, with a pure Perl backup version
for systems that can't handle XS.

=head1 THEORY

The numbers processed by this module, the decimals, are those of the
form M * 10^-E, where M is an integer and E is a non-negative integer,
with range otherwise unlimited.  (For any such number there are actually
an infinite number of possible (M, E) tuples: if a certain E value is
possible then all greater integers are also possible E values.)  It is
an infinite set of cardinality aleph-0 (although this implementation is
hampered by the finiteness of computer memory).  The set includes both
positive and negative numbers, and zero.  It is a proper superset of the
integers, and a proper subset of the rationals.  There are no infinite
numbers, nulls, irrationals, non-real complex numbers, or signed zeroes.

Like the set of integers, the set of decimals is closed under mathematical
addition, subtraction, and multiplication.  It thus forms a commutative
ring (in fact, an integral domain).  Unlike the set of rationals, it is
not closed under exact division, and so it does not form a field.

The arithmetic operations supplied by this module are those of ordinary
mathematical arithmetic.  They thus obey the usual identities, such as
associativity (of addition and multiplication) and cancellation laws.
(This is unlike floating point arithmetic.  Any system of floating
point numbers is not closed under mathematical addition, for example,
but by construction it is closed under floating point addition, which
necessarily differs from mathematical addition.  Floating point addition
does not obey associativity or cancellation laws.)

=head1 ROUNDING MODES

For rounding division operations, a rounding mode must be specified.
It is given as a short string, which may be any of these:

=over

=item B<TWZ>

towards zero

=item B<AWZ>

away from zero

=item B<FLR>

floor: downwards (toward negative infinity)

=item B<CLG>

ceiling: upwards (toward positive infinity)

=item B<EVN>

to even

=item B<ODD>

to odd

=item B<NEAR_>I<MODE>

to nearest, breaking ties according to I<MODE> (which must be one of
the six above)

=item B<EXACT>

C<die> if any rounding is required

=back

The mode "B<NEAR_EVN>" (rounding to nearest, breaking ties to the even
number), commonly known as "bankers' rounding", is usually the best for
general rounding purposes.

=cut

package Math::Decimal;

{ use 5.006; }
use warnings;
use strict;

use Carp qw(croak);
use Params::Classify 0.000 qw(is_string);

our $VERSION = "0.003";

use parent "Exporter";
our @EXPORT_OK = qw(
	$dec_number_rx $dec_integer_rx $dec_zero_rx $dec_one_rx $dec_negone_rx
	is_dec_number check_dec_number
	dec_canonise
	dec_sgn dec_abs
	dec_cmp dec_min dec_max
	dec_neg dec_add dec_sub
	dec_pow10 dec_mul_pow10
	dec_mul
	dec_rndiv_and_rem dec_rndiv dec_round_and_rem dec_round dec_rem
);

eval { local $SIG{__DIE__};
	require XSLoader;
	XSLoader::load(__PACKAGE__, $VERSION);
};

=head1 REGULAR EXPRESSIONS

Each of these regular expressions matches some subset of numbers, in
the string form used by this module.  The regular expressions do not
include any anchors, so to check whether an entire string matches a
number format you must supply the anchors yourself.

=over

=item $dec_number_rx

Any number processed by this module.  This checks the syntax in
which the number is expressed, without restricting its numeric value.
The number syntax consists of optional sign, one or more integer digits,
then optionally a dot (for the decimal point) and one or more fractional
digits.  It is not permitted to have no integer digits, nor to have no
fractional digits if there is a decimal point.  All digits must be ASCII
decimal digits.  Unlike Perl's standard string-to-number conversions,
whitespace and other non-numeric parts are not permitted.

=cut

our $dec_number_rx = qr/[-+]?[0-9]+(?:\.[0-9]+)?/;

=item $dec_integer_rx

Any integer.  This recognises integer values expressed in the
decimal format used by this module, I<not> an integer-specific format.
So fractional decimal digits are allowed, provided that they are all zero,
as in "C<123.000>".

=cut

our $dec_integer_rx = qr/[-+]?[0-9]+(?:\.0+)?/;

=item $dec_zero_rx

Zero.  This may have arbitrarily many integer and fractional digits,
and may be expressed with either sign.

=cut

our $dec_zero_rx = qr/[-+]?0+(?:\.0+)?/;

=item $dec_one_rx

Positive one.

=cut

our $dec_one_rx = qr/\+?0*1(?:\.0+)?/;

=item $dec_negone_rx

Negative one.

=cut

our $dec_negone_rx = qr/-0*1(?:\.0+)?/;

=back

=head1 FUNCTIONS

Each C<dec_> function takes one or more decimal arguments (I<A>, I<B>)
to operate on.  If these arguments are not valid decimal numbers then
the function will C<die>.  Results are always returned as decimals in
minimum-length (canonical) form.

=head2 Classification

=over

=item is_dec_number(ARG)

Returns a truth value indicating whether I<ARG> is a plain string
satisfying the decimal number syntax.

=cut

unless(defined &is_dec_number) { { local $SIG{__DIE__}; eval q{
sub is_dec_number($) {
	no warnings "utf8";
	return is_string($_[0]) && $_[0] =~ /\A$dec_number_rx\z/o;
}
}; } die $@ if $@ ne "" }

=item check_dec_number(ARG)

Checks whether I<ARG> is a plain string satisfying the decimal number
syntax.  Returns normally if it is.  C<die>s if it is not.

=cut

unless(defined &check_dec_number) { { local $SIG{__DIE__}; eval q{
sub check_dec_number($) {
	croak "not a decimal number" unless &is_dec_number;
}
}; } die $@ if $@ ne "" }

=back

=head2 Representation

=over

=item dec_canonise(A)

This returns the value I<A>, numerically unmodified, but expressed
in minimum-length (canonical) form.  Numerically this is the identity
function.

=cut

unless(defined &dec_canonise) { { local $SIG{__DIE__}; eval q{
sub dec_canonise($) {
	croak "not a decimal number" unless is_string($_[0]);
	$_[0] =~ /\A(?:(-)|\+?)0*([1-9][0-9]*|0)(?:(\.[0-9]*[1-9])0*|\.0+|)\z/
		or croak "not a decimal number";
	my $num = (defined($1) ? $1 : "").$2.(defined($3) ? $3 : "");
	return $num eq "-0" ? "0" : $num;
}
}; } die $@ if $@ ne "" }

=back

=head2 Arithmetic

=over

=item dec_sgn(A)

Returns +1 if the argument is positive, 0 if the argument is zero,
or -1 if the argument is negative.

The value returned is not just a string, as usual for this module, but
has also been subjected to Perl's implicit numerification.  This is
necessary for it to be an acceptable comparison value in a C<sort>
operation, on Perls prior to 5.11.0, due to perl bug #69384.

=cut

my @sgn_result = ("-1", "0", "1");
foreach(@sgn_result) {
	no warnings "void";
	$_ + 0;
}

unless(defined &dec_sgn) { { local $SIG{__DIE__}; eval q{
sub dec_sgn($) {
	croak "not a decimal number" unless is_string($_[0]);
	$_[0] =~ /\A(?:(-)|\+?)0*(?:0(?:\.0+)?()|[0-9]+(?:\.[0-9]+)?)\z/
		or croak "not a decimal number";
	return $sgn_result[defined($2) ? 1 : defined($1) ? 0 : 2];
}
}; } die $@ if $@ ne "" }

=item dec_abs(A)

Absolute value (magnitude, discarding sign).

=cut

unless(defined &dec_abs) { { local $SIG{__DIE__}; eval q{
sub dec_abs($) {
	croak "not a decimal number" unless is_string($_[0]);
	my $a = $_[0];
	$a =~ s/\A-(?=[0-9])//;
	return dec_canonise($a);
}
}; } die $@ if $@ ne "" }

=item dec_cmp(A, B)

Arithmetic comparison.  Returns -1, 0, or +1, indicating whether I<A> is
less than, equal to, or greater than I<B>.

The value returned is not just a string, as usual for this module, but
has also been subjected to Perl's implicit numerification.  This is
necessary for it to be an acceptable comparison value in a C<sort>
operation, on Perls prior to 5.11.0, due to perl bug #69384.

=cut

unless(defined &dec_cmp) { { local $SIG{__DIE__}; eval q{
my %sgn_cmp = (
	"+0" => "1",
	"+-" => "1",
	"0+" => "-1",
	"00" => "0",
	"0-" => "1",
	"-+" => "-1",
	"-0" => "-1",
);
foreach(values %sgn_cmp) {
	no warnings "void";
	$_ + 0;
}

sub dec_cmp($$) {
	croak "not a decimal number"
		unless is_string($_[0]) && is_string($_[1]);
	my($as, $ai, $af) = ($_[0] =~ /\A([-+])?([0-9]+)(?:\.([0-9]+))?\z/);
	my($bs, $bi, $bf) = ($_[1] =~ /\A([-+])?([0-9]+)(?:\.([0-9]+))?\z/);
	croak "not a decimal number" unless defined($ai) && defined($bi);
	$as = "+" unless defined $as;
	$bs = "+" unless defined $bs;
	$af = "0" unless defined $af;
	$bf = "0" unless defined $bf;
	$as = "0" if $ai =~ /\A0+\z/ && $af =~ /\A0+\z/;
	$bs = "0" if $bi =~ /\A0+\z/ && $bf =~ /\A0+\z/;
	my $cmp = $sgn_cmp{$as.$bs};
	return $cmp if defined $cmp;
	my $ld = length($ai) - length($bi);
	if($ld < 0) {
		$ai = ("0" x -$ld) . $ai;
	} elsif($ld > 0) {
		$bi = ("0" x $ld) . $bi;
	}
	$ld = length($af) - length($bf);
	if($ld < 0) {
		$af .= "0" x -$ld;
	} elsif($ld > 0) {
		$bf .= "0" x $ld;
	}
	($ai, $af, $bi, $bf) = ($bi, $bf, $ai, $af) if $as eq "-";
	return $sgn_result[($ai.$af cmp $bi.$bf) + 1];
}
}; } die $@ if $@ ne "" }

=item dec_min(A, B)

Arithmetic minimum.  Returns the arithmetically lesser of the two arguments.

=cut

unless(defined &dec_min) { { local $SIG{__DIE__}; eval q{
sub dec_min($$) { dec_canonise($_[&dec_cmp eq "-1" ? 0 : 1]) }
}; } die $@ if $@ ne "" }

=item dec_max(A, B)

Arithmetic maximum.  Returns the arithmetically greater of the two arguments.

=cut

unless(defined &dec_max) { { local $SIG{__DIE__}; eval q{
sub dec_max($$) { dec_canonise($_[&dec_cmp eq "1" ? 0 : 1]) }
}; } die $@ if $@ ne "" }

=item dec_neg(A)

Negation: returns -A.

=cut

unless(defined &dec_neg) { { local $SIG{__DIE__}; eval q{
my %negate_sign = (
	"" => "-",
	"+" => "-",
	"-" => "+",
);

sub dec_neg($) {
	my $a = $_[0];
	check_dec_number($a);
	$a =~ s/\A([-+]?)/$negate_sign{$1}/e;
	return dec_canonise($a);
}
}; } die $@ if $@ ne "" }

=item dec_add(A, B)

Addition: returns A + B.

=cut

unless(defined &dec_add) { { local $SIG{__DIE__}; eval q{
sub dec_add($$) {
	croak "not a decimal number"
		unless is_string($_[0]) && is_string($_[1]);
	my($as, $ai, $af) = ($_[0] =~ /\A([-+])?([0-9]+)(?:\.([0-9]+))?\z/);
	my($bs, $bi, $bf) = ($_[1] =~ /\A([-+])?([0-9]+)(?:\.([0-9]+))?\z/);
	croak "not a decimal number" unless defined($ai) && defined($bi);
	$as = "+" unless defined $as;
	$bs = "+" unless defined $bs;
	$af = "0" unless defined $af;
	$bf = "0" unless defined $bf;
	{
		my $ld = length($ai) - length($bi);
		if($ld < 0) {
			$ai = ("0" x -$ld) . $ai;
		} elsif($ld > 0) {
			$bi = ("0" x $ld) . $bi;
		}
		$ld = length($af) - length($bf);
		if($ld < 0) {
			$af .= "0" x -$ld;
		} elsif($ld > 0) {
			$bf .= "0" x $ld;
		}
	}
	my $il = length($ai);
	my $ad = $ai.$af;
	my $bd = $bi.$bf;
	if($as eq $bs) {
		# same sign, add magnitudes
		my $c = 0;
		my $rd = " " x length($ad);
		for(my $pos = length($ad); $pos--; ) {
			my $rv = ord(substr($ad, $pos, 1)) +
				(ord(substr($bd, $pos, 1)) - 0x30) + $c;
			$c = $rv >= 0x3a ? 1 : 0;
			$rv -= 10 if $c;
			substr $rd, $pos, 1, chr($rv);
		}
		return dec_canonise($as.($c ? "1" : "").substr($rd, 0, $il).
					".".substr($rd, $il));
	} else {
		# different sign, subtract magnitudes
		($as, $ad, $bd) = ($bs, $bd, $ad) if $ad lt $bd;
		my $c = 0;
		my $rd = " " x length($ad);
		for(my $pos = length($ad); $pos--; ) {
			my $rv = ord(substr($ad, $pos, 1)) -
				(ord(substr($bd, $pos, 1)) - 0x30) - $c;
			$c = $rv < 0x30 ? 1 : 0;
			$rv += 10 if $c;
			substr $rd, $pos, 1, chr($rv);
		}
		return dec_canonise($as.substr($rd, 0, $il).
					".".substr($rd, $il));
	}
}
}; } die $@ if $@ ne "" }

=item dec_sub(A, B)

Subtraction: returns A - B.

=cut

unless(defined &dec_sub) { { local $SIG{__DIE__}; eval q{
sub dec_sub($$) { dec_add($_[0], dec_neg($_[1])) }
}; } die $@ if $@ ne "" }

=item dec_pow10(A)

Power of ten: returns 10^A.
I<A> must be an integer value (though it has the usual decimal syntax).
C<die>s if I<A> is too large for Perl to handle the result.

=cut

unless(defined(&dec_pow10) && defined(&dec_mul_pow10)) {
				{ local $SIG{__DIE__}; eval q{
sub _parse_expt($) {
	croak "not a decimal number" unless is_string($_[0]);
	my($pneg, $pi, $pbadf) =
		($_[0] =~ /\A(?:(-)|\+?)
			   0*(0|[1-9][0-9]*)
			   (?:|\.0+|\.[0-9]+())\z/x);
	croak "not a decimal number" unless defined $pi;
	croak "not an integer" if defined $pbadf;
	croak "exponent too large" if length($pi) > 9;
	return defined($pneg) && $pi ne "0" ? 0-$pi : 0+$pi;
}
}; } die $@ if $@ ne "" }

unless(defined &dec_pow10) { { local $SIG{__DIE__}; eval q{
sub dec_pow10($) {
	my $p = &_parse_expt;
	if($p < 0) {
		return "0.".("0" x (-1-$p))."1";
	} else {
		return "1".("0" x $p);
	}
}
}; } die $@ if $@ ne "" }

=item dec_mul_pow10(A, B)

Digit shifting: returns A * 10^B.
I<B> must be an integer value (though it has the usual decimal syntax).
C<die>s if I<B> is too large for Perl to handle the result.

=cut

unless(defined &dec_mul_pow10) { { local $SIG{__DIE__}; eval q{
sub dec_mul_pow10($$) {
	croak "not a decimal number" unless is_string($_[0]);
	my($as, $ai, $af) = ($_[0] =~ /\A([-+]?)([0-9]+)(?:\.([0-9]+))?\z/);
	croak "not a decimal number" unless defined $ai;
	$af = "" unless defined $af;
	my $p = _parse_expt($_[1]);
	if($p < 0) {
		my $il = length($ai);
		$ai = ("0" x (1-$p-$il)).$ai if $il+$p <= 0;
		return dec_canonise($as.substr($ai, 0, $p).".".
					substr($ai, $p).$af);
	} else {
		my $fl = length($af);
		$af .= "0" x (1+$p-$fl) if $p >= $fl;
		return dec_canonise($as.$ai.substr($af, 0, $p).".".
					substr($af, $p));
	}
}
}; } die $@ if $@ ne "" }

=item dec_mul(A, B)

Multiplication: returns A * B.

=cut

unless(defined &dec_mul) { { local $SIG{__DIE__}; eval q{
sub dec_mul($$) {
	croak "not a decimal number"
		unless is_string($_[0]) && is_string($_[1]);
	my($as, $ai, $af) =
		($_[0] =~ /\A([-+])?0*(0|[1-9][0-9]*)(?:\.([0-9]+))?\z/);
	my($bs, $bi, $bf) =
		($_[1] =~ /\A([-+])?0*(0|[1-9][0-9]*)(?:\.([0-9]+))?\z/);
	croak "not a decimal number" unless defined($ai) && defined($bi);
	$as = "+" unless defined $as;
	$bs = "+" unless defined $bs;
	$af = "" unless defined $af;
	$bf = "0" unless defined $bf;
	my $il = length($ai) + length($bi);
	my $ad = $ai.$af;
	my $bd = $bi.$bf;
	my $al = length($ad);
	my $bl = length($bd);
	my $rd = "0" x ($al+$bl);
	for(my $bp = $bl; $bp--; ) {
		my $bv = ord(substr($bd, $bp, 1)) - 0x30;
		next if $bv == 0;
		my $c = 0;
		for(my $ap = $al; $ap--; ) {
			my $rp = $ap + $bp + 1;
			my $av = ord(substr($ad, $ap, 1)) - 0x30;
			my $v = $av*$bv + $c + ord(substr($rd, $rp, 1)) - 0x30;
			substr $rd, $rp, 1,
				chr(do { use integer; $v%10 + 0x30 });
			$c = do { use integer; $v / 10 };
		}
		substr $rd, $bp, 1, chr(ord(substr($rd, $bp, 1)) + $c);
	}
	return dec_canonise(($as eq $bs ? "+" : "-").substr($rd, 0, $il).
				".".substr($rd, $il));
}
}; } die $@ if $@ ne "" }

=item dec_rndiv_and_rem(MODE, A, B)

Rounding division: returns a list of two items, the quotient (I<Q>) and
remainder (I<R>) from the division of I<A> by I<B>.
The quotient is by definition
integral, and the quantities are related by the equation Q*B + R = A.
I<MODE> controls the rounding mode, which determines which integer I<Q> is
when I<R> is non-zero.

=cut

unless(defined &dec_rndiv_and_rem) { { local $SIG{__DIE__}; eval q{

sub _nonneg_rndiv_and_rem_twz($$) {
	croak "division by zero" if $_[1] eq "0";
	return ("0", "0") if $_[0] eq "0";
	$_[0] =~ /\A(?:[1-9]([0-9]*)|0\.(0*)[1-9])/;
	my $a_expt = defined($1) ? length($1) : -1-length($2);
	$_[1] =~ /\A(?:[1-9]([0-9]*)|0\.(0*)[1-9])/;
	my $b_expt = defined($1) ? length($1) : -1-length($2);
	my $q = "0";
	my $r = $_[0];
	for(my $s = $a_expt-$b_expt; $s >= 0; $s--) {
		my $sd = dec_mul_pow10($_[1], $s);
		for(my $m = 9; ; $m--) {
			my $msd = dec_mul($sd, $m);
			if(dec_cmp($msd, $r) ne "1") {
				$q = dec_add($q, dec_mul_pow10($m, $s));
				$r = dec_sub($r, $msd);
				last;
			}
		}
	}
	return ($q, $r);
}

my %round_tiebreak = (
	(map { ($_ => $_, "NEAR_$_" => $_) } qw(TWZ AWZ FLR CLG EVN ODD)),
	EXACT => "EXACT",
);

my %round_positive = (
	(map { my($f, $t) = split(/:/, $_); ($f => $t, "NEAR_$f" => "NEAR_$t") }
		qw(TWZ:TWZ AWZ:AWZ FLR:TWZ CLG:AWZ EVN:EVN ODD:ODD)),
	EXACT => "EXACT",
);

my %round_negative = (
	(map { my($f, $t) = split(/:/, $_); ($f => $t, "NEAR_$f" => "NEAR_$t") }
		qw(TWZ:TWZ AWZ:AWZ FLR:AWZ CLG:TWZ EVN:EVN ODD:ODD)),
	EXACT => "EXACT",
);

my %base_round_handler = (
	TWZ => sub { 0 },
	AWZ => sub { 1 },
	EVN => sub { $_[0] =~ /[13579]\z/ },
	ODD => sub { $_[0] =~ /[02468]\z/ },
);

sub dec_rndiv_and_rem($$$) {
	my $mode = $_[0];
	croak "invalid rounding mode"
		unless is_string($mode) && exists($round_tiebreak{$mode});
	my $sgn_a = dec_sgn($_[1]);
	my $sgn_b = dec_sgn($_[2]);
	my $abs_a = dec_abs($_[1]);
	my $abs_b = dec_abs($_[2]);
	my($q, $r) = _nonneg_rndiv_and_rem_twz($abs_a, $abs_b);
	$mode = ($sgn_a == $sgn_b ? \%round_positive : \%round_negative)
			->{$mode};
	my $half_cmp;
	if(
		$r eq "0" ? 0 :
		$mode eq "EXACT" ? croak("inexact division") :
		$mode =~ /\ANEAR_/ &&
			($half_cmp = dec_cmp(dec_mul($r, "2"), $abs_b))
			ne "0" ?
				$half_cmp eq "1" :
		$base_round_handler{$round_tiebreak{$mode}}->($q)
	) {
		$q = dec_add($q, "1");
		$r = dec_sub($r, $abs_b);
	}
	return (($sgn_a ne $sgn_b ? dec_neg($q) : $q),
		($sgn_a ne "1" ? dec_neg($r) : $r));
}

}; } die $@ if $@ ne "" }

=item dec_rndiv(MODE, A, B)

Rounding division: returns the quotient (I<Q>)
from the division of I<A> by I<B>.
The quotient is by definition integral, and approximates A/B.  I<MODE>
controls the rounding mode, which determines which integer I<Q> is when it
can't be exactly A/B.

=cut

unless(defined &dec_rndiv) { { local $SIG{__DIE__}; eval q{
sub dec_rndiv($$$) {
	my($quotient, undef) = &dec_rndiv_and_rem;
	return $quotient;
}
}; } die $@ if $@ ne "" }

=item dec_round_and_rem(MODE, A, B)

Rounding: returns a list of two items, the rounded value (I<V>) and remainder
(I<R>) from the rounding of I<A> to a multiple of I<B>.  The rounded value is
an exact multiple of I<B>, and the quantities are related by the equation
V + R = A.  I<MODE> controls the rounding mode, which determines which
multiple of I<B> I<V> is when I<R> is non-zero.

=cut

unless(defined &dec_round_and_rem) { { local $SIG{__DIE__}; eval q{
sub dec_round_and_rem($$$) {
	my($quotient, $remainder) = &dec_rndiv_and_rem;
	return (dec_mul($_[2], $quotient), $remainder);
}
}; } die $@ if $@ ne "" }

=item dec_round(MODE, A, B)

Rounding: returns the rounded value (I<V>) from the rounding of I<A> to
a multiple of I<B>.  The rounded value is an exact multiple of I<B>, and
approximates I<A>.  I<MODE> controls the rounding mode, which determines
which multiple of I<B> I<V> is when it can't be exactly I<A>.

=cut

unless(defined &dec_round) { { local $SIG{__DIE__}; eval q{
sub dec_round($$$) {
	my($quotient, undef) = &dec_rndiv_and_rem;
	return dec_mul($_[2], $quotient);
}
}; } die $@ if $@ ne "" }

=item dec_rem(MODE, A, B)

Remainder: returns the remainder (I<R>) from the division of I<A> by I<B>.
I<R> differs from I<A> by an exact multiple of I<B>.
I<MODE> controls the rounding
mode, which determines which quotient is used when I<R> is non-zero.

=cut

unless(defined &dec_rem) { { local $SIG{__DIE__}; eval q{
sub dec_rem($$$) {
	my(undef, $remainder) = &dec_rndiv_and_rem;
	return $remainder;
}
}; } die $@ if $@ ne "" }

=back

=head1 BUGS

The implementation of division is hideously inefficient.
This should be improved in a future version.

=head1 SEE ALSO

L<Math::BigRat>

=head1 AUTHOR

Andrew Main (Zefram) <zefram@fysh.org>

=head1 COPYRIGHT

Copyright (C) 2009, 2010, 2011 Andrew Main (Zefram) <zefram@fysh.org>

=head1 LICENSE

This module is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;
