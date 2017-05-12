use warnings;
use strict;

use Params::Classify qw(is_string);
use Test::More tests => 2867;

BEGIN { $SIG{__WARN__} = sub { die "WARNING: $_[0]" }; }

BEGIN { use_ok "Math::Decimal", qw(
	$dec_number_rx $dec_integer_rx $dec_zero_rx $dec_one_rx $dec_negone_rx
	is_dec_number check_dec_number
	dec_canonise
	dec_sgn dec_abs dec_neg
	dec_cmp dec_min dec_max dec_add dec_sub dec_mul
	dec_pow10 dec_mul_pow10
	dec_rndiv_and_rem dec_rndiv dec_round_and_rem dec_round dec_rem
); }

foreach my $arg (
	undef,
	*STDOUT,
	\"0",
	[],
	{},
	sub{},
	bless({},"main"),
	bless({},"ARRAY"),
	bless([],"main"),
	bless([],"HASH"),
	"", " ", "0 ", " 0",
	qw(
		+ - . 0. .0 +. +0. +.0 -. -0. -.0
		++0 --0 +-0 -+0
		a 0a a0 0x0 0e0
		0+ 0-
		0..0 0.0. 0.0.0
	),
	(map { do {
		no warnings "utf8";
		my $c = chr(hex($_));
		die "chr/ord failure" unless sprintf("%x", ord($c)) eq $_;
		$c;
	} } qw(
		0 1 8 9 a b c d e 1f
		2f 3a 7f 80 9f a0 a3
		d7ff e000 fffd 10000 1fffd 20000 10fffd
		b0 130 10030
		b2 660 6f0 966 9e6 a66 ae6 b66 d66 e50 ed0 2070 2080 2460 ff10
	)),
) {
	if(is_string($arg)) {
		no warnings "utf8";
		foreach my $rx (
			qr/\A$dec_number_rx\z/o,
			qr/\A$dec_integer_rx\z/o,
			qr/\A$dec_zero_rx\z/o,
			qr/\A$dec_one_rx\z/o,
			qr/\A$dec_negone_rx\z/o,
		) {
			ok $arg !~ $rx;
		}
	}
	ok !is_dec_number($arg);
	foreach my $func (
		\&check_dec_number,
		\&dec_canonise,
		\&dec_sgn,
		\&dec_abs,
		\&dec_neg,
		\&dec_pow10,
	) {
		eval { $func->($arg) };
		like $@, qr/\Anot a decimal number\b/;
	}
	foreach my $func (
		\&dec_cmp,
		\&dec_min,
		\&dec_max,
		\&dec_add,
		\&dec_sub,
		\&dec_mul,
		\&dec_mul_pow10,
		sub { dec_rndiv_and_rem("TWZ", $_[0], $_[1]) },
		sub { dec_rndiv("TWZ", $_[0], $_[1]) },
		sub { dec_round_and_rem("TWZ", $_[0], $_[1]) },
		sub { dec_round("TWZ", $_[0], $_[1]) },
		sub { dec_rem("TWZ", $_[0], $_[1]) },
	) {
		eval { $func->($arg, "0") };
		like $@, qr/\Anot a decimal number\b/;
		eval { $func->("0", $arg) };
		like $@, qr/\Anot a decimal number\b/;
	}
}

1;
