use warnings;
use strict;

use Test::More tests => 2313;

BEGIN { $SIG{__WARN__} = sub { die "WARNING: $_[0]" }; }

BEGIN { use_ok "Math::Decimal", qw(
	dec_mul dec_sub
	dec_rndiv_and_rem dec_rndiv
	dec_round_and_rem dec_round
	dec_rem
); }

foreach(
	[qw( 0 13 0 )],
	[qw( 123 7 17)],
	[qw( 1.23 0.07 17 )],
	[qw( -12300 700 -17 )],
	[qw( -12345678900 -76500 161381 )],
	[qw( 123456789 765 161381 )],
	[qw( 1234567.89 -7.65 -161381 )],
	[qw( 123456.789 -0.765 -161381 )],
	[qw( 12345.6789 -0.0765 -161381 )],
	[qw( 0.123456789 0.000000765 161381 )],
	[qw( 0.0123456789 0.0000000765 161381 )],
) {
	my($a, $b, $q) = @$_;
	my $v = dec_mul($q, $b);
	my $r = dec_sub($a, $v);
	is_deeply [ dec_rndiv_and_rem("TWZ", $a, $b) ], [ $q,  $r ];
	is_deeply [ dec_rndiv("TWZ", $a, $b) ],         [ $q ];
	is_deeply [ dec_round_and_rem("TWZ", $a, $b) ], [ $v,  $r ];
	is_deeply [ dec_round("TWZ", $a, $b) ],         [ $v ];
	is_deeply [ dec_rem("TWZ", $a, $b) ],           [ $r ];
}

foreach my $a (qw(0 4 -3)) {
	foreach my $func (
		\&dec_rndiv_and_rem,
		\&dec_rndiv,
		\&dec_round_and_rem,
		\&dec_round,
		\&dec_rem,
	) {
		eval { $func->("TWZ", $a, "0") };
		like $@, qr/\Adivision by zero\b/;
	}
}

is dec_rndiv("EXACT", "123", "3"), "41";
eval { dec_rndiv("EXACT", "124", "3") }; like $@, qr/\Ainexact division\b/;

my @mode = map { ($_, "NEAR_$_") } qw(TWZ AWZ FLR CLG EVN ODD);
foreach(   # a    b  twz ntwz awz nawz flr nflr clg nclg evn nevn odd nodd
	[qw( 8    2    4    4   4    4   4    4   4    4   4    4   4    4 )],
	[qw( 7.5  2    3    4   4    4   3    4   4    4   4    4   3    4 )],
	[qw( 7    2    3    3   4    4   3    3   4    4   4    4   3    3 )],
	[qw( 6.5  2    3    3   4    3   3    3   4    3   4    3   3    3 )],
	[qw( 6    2    3    3   3    3   3    3   3    3   3    3   3    3 )],
	[qw( 5.5  2    2    3   3    3   2    3   3    3   2    3   3    3 )],
	[qw( 5    2    2    2   3    3   2    2   3    3   2    2   3    3 )],
	[qw( 4.5  2    2    2   3    2   2    2   3    2   2    2   3    2 )],
	[qw( 4    2    2    2   2    2   2    2   2    2   2    2   2    2 )],
	[qw(-4    2   -2   -2  -2   -2  -2   -2  -2   -2  -2   -2  -2   -2 )],
	[qw(-4.5  2   -2   -2  -3   -2  -3   -2  -2   -2  -2   -2  -3   -2 )],
	[qw(-5    2   -2   -2  -3   -3  -3   -3  -2   -2  -2   -2  -3   -3 )],
	[qw(-5.5  2   -2   -3  -3   -3  -3   -3  -2   -3  -2   -3  -3   -3 )],
	[qw(-6    2   -3   -3  -3   -3  -3   -3  -3   -3  -3   -3  -3   -3 )],
	[qw(-6.5  2   -3   -3  -4   -3  -4   -3  -3   -3  -4   -3  -3   -3 )],
	[qw(-7    2   -3   -3  -4   -4  -4   -4  -3   -3  -4   -4  -3   -3 )],
	[qw(-7.5  2   -3   -4  -4   -4  -4   -4  -3   -4  -4   -4  -3   -4 )],
	[qw(-8    2   -4   -4  -4   -4  -4   -4  -4   -4  -4   -4  -4   -4 )],
	[qw(-8   -2    4    4   4    4   4    4   4    4   4    4   4    4 )],
	[qw(-7.5 -2    3    4   4    4   3    4   4    4   4    4   3    4 )],
	[qw(-7   -2    3    3   4    4   3    3   4    4   4    4   3    3 )],
	[qw(-6.5 -2    3    3   4    3   3    3   4    3   4    3   3    3 )],
	[qw(-6   -2    3    3   3    3   3    3   3    3   3    3   3    3 )],
	[qw(-5.5 -2    2    3   3    3   2    3   3    3   2    3   3    3 )],
	[qw(-5   -2    2    2   3    3   2    2   3    3   2    2   3    3 )],
	[qw(-4.5 -2    2    2   3    2   2    2   3    2   2    2   3    2 )],
	[qw(-4   -2    2    2   2    2   2    2   2    2   2    2   2    2 )],
	[qw( 4   -2   -2   -2  -2   -2  -2   -2  -2   -2  -2   -2  -2   -2 )],
	[qw( 4.5 -2   -2   -2  -3   -2  -3   -2  -2   -2  -2   -2  -3   -2 )],
	[qw( 5   -2   -2   -2  -3   -3  -3   -3  -2   -2  -2   -2  -3   -3 )],
	[qw( 5.5 -2   -2   -3  -3   -3  -3   -3  -2   -3  -2   -3  -3   -3 )],
	[qw( 6   -2   -3   -3  -3   -3  -3   -3  -3   -3  -3   -3  -3   -3 )],
	[qw( 6.5 -2   -3   -3  -4   -3  -4   -3  -3   -3  -4   -3  -3   -3 )],
	[qw( 7   -2   -3   -3  -4   -4  -4   -4  -3   -3  -4   -4  -3   -3 )],
	[qw( 7.5 -2   -3   -4  -4   -4  -4   -4  -3   -4  -4   -4  -3   -4 )],
	[qw( 8   -2   -4   -4  -4   -4  -4   -4  -4   -4  -4   -4  -4   -4 )],
) {
	my($a, $b, @q) = @$_;
	foreach(my $i = 0; $i != 12; $i++) {
		my $mode = $mode[$i];
		my $q = $q[$i];
		my $v = dec_mul($q, $b);
		my $r = dec_sub($a, $v);
		is_deeply [ dec_rndiv_and_rem($mode, $a, $b) ], [ $q,  $r ];
		is_deeply [ dec_rndiv($mode, $a, $b) ],         [ $q ];
		is_deeply [ dec_round_and_rem($mode, $a, $b) ], [ $v,  $r ];
		is_deeply [ dec_round($mode, $a, $b) ],         [ $v ];
		is_deeply [ dec_rem($mode, $a, $b) ],           [ $r ];
	}
}

foreach my $arg (
	undef,
	*STDOUT,
	\"TWZ",
	[],
	{},
	sub{},
	bless({},"main"),
	bless({},"ARRAY"),
	bless([],"main"),
	bless([],"HASH"),
	"", " ", "TWZ ", " TWZ", "twz", "NEAR_EXACT",
) {
	foreach my $func (
		\&dec_rndiv_and_rem,
		\&dec_rndiv,
		\&dec_round_and_rem,
		\&dec_round,
		\&dec_rem,
	) {
		eval { $func->($arg, "x", "x") };
		like $@, qr/\Ainvalid rounding mode\b/;
	}
}

1;
