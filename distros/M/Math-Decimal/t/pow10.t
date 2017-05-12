use warnings;
use strict;

use Test::More tests => 15191;
use t::NumForms qw(num_forms);

BEGIN { $SIG{__WARN__} = sub { die "WARNING: $_[0]" }; }

BEGIN { use_ok "Math::Decimal", qw(dec_pow10 dec_mul_pow10); }

foreach(
	[qw( -3 0.001 )],
	[qw( -2 0.01 )],
	[qw( -1 0.1 )],
	[qw(  0 1 )],
	[qw(  1 10 )],
	[qw(  2 100 )],
	[qw(  3 1000 )],
) {
	my($a, $r) = @$_;
	foreach my $af (num_forms($a)) {
		is dec_pow10($af), $r;
	}
}

foreach(
	[qw( -5 0 )],
	[qw( -4 0 )],
	[qw( -3 0 )],
	[qw( -2 0 )],
	[qw( -1 0 )],
	[qw(  0 0 )],
	[qw(  1 0 )],
	[qw(  2 0 )],
	[qw(  3 0 )],
	[qw(  4 0 )],
	[qw(  5 0 )],
) {
	my($b, $r) = @$_;
	foreach my $af (num_forms("0")) {
		foreach my $bf (num_forms($b)) {
			is dec_mul_pow10($af, $bf), $r;
		}
	}
}

foreach(
	[qw( -5 0.00123456 )],
	[qw( -4 0.0123456 )],
	[qw( -3 0.123456 )],
	[qw( -2 1.23456 )],
	[qw( -1 12.3456 )],
	[qw(  0 123.456 )],
	[qw(  1 1234.56 )],
	[qw(  2 12345.6 )],
	[qw(  3 123456 )],
	[qw(  4 1234560 )],
	[qw(  5 12345600 )],
) {
	my($b, $r) = @$_;
	foreach my $af (num_forms("123.456")) {
		foreach my $bf (num_forms($b)) {
			is dec_mul_pow10($af, $bf), $r;
		}
	}
}

foreach(
	[qw( -9 0.0123456 )],
	[qw( -8 0.123456 )],
	[qw( -7 1.23456 )],
	[qw( -6 12.3456 )],
	[qw( -5 123.456 )],
	[qw( -4 1234.56 )],
	[qw( -3 12345.6 )],
	[qw( -2 123456 )],
	[qw( -1 1234560 )],
	[qw(  0 12345600 )],
	[qw(  1 123456000 )],
	[qw(  2 1234560000 )],
	[qw(  3 12345600000 )],
	[qw(  4 123456000000 )],
	[qw(  5 1234560000000 )],
) {
	my($b, $r) = @$_;
	foreach my $af (num_forms("12345600")) {
		foreach my $bf (num_forms($b)) {
			is dec_mul_pow10($af, $bf), $r;
		}
	}
}

foreach(
	[qw( -5 0.0000000123456 )],
	[qw( -4 0.000000123456 )],
	[qw( -3 0.00000123456 )],
	[qw( -2 0.0000123456 )],
	[qw( -1 0.000123456 )],
	[qw(  0 0.00123456 )],
	[qw(  1 0.0123456 )],
	[qw(  2 0.123456 )],
	[qw(  3 1.23456 )],
	[qw(  4 12.3456 )],
	[qw(  5 123.456 )],
	[qw(  6 1234.56 )],
	[qw(  7 12345.6 )],
	[qw(  8 123456 )],
	[qw(  9 1234560 )],
) {
	my($b, $r) = @$_;
	foreach my $af (num_forms("0.00123456")) {
		foreach my $bf (num_forms($b)) {
			is dec_mul_pow10($af, $bf), $r;
		}
	}
}

is dec_pow10("100"), "1".("0"x100);
is dec_pow10("-100"), "0.".("0"x99)."1";

foreach my $arg (qw(0.1 0.5 1.5 -0.5 -1.5)) {
	eval { dec_pow10($arg) };
	like $@, qr/\Anot an integer\b/;
	eval { dec_mul_pow10("0", $arg) };
	like $@, qr/\Anot an integer\b/;
}

foreach my $arg (qw(1000000000 -1000000000)) {
	eval { dec_pow10($arg) };
	like $@, qr/\Aexponent too large\b/;
	eval { dec_mul_pow10("0", $arg) };
	like $@, qr/\Aexponent too large\b/;
}

1;
