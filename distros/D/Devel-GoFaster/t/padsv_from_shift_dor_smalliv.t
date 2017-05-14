use warnings;
use strict;

BEGIN {
	if("$]" < 5.009000) {
		require Test::More;
		Test::More::plan(skip_all => "no dor op on this perl");
	}
}

use Test::More tests => 11;

use Devel::GoFaster;

sub t0 {
	my $x;
	my $y = shift // 0;
	my $z = shift(@_) // 123;
	return [ ($x = shift // -1), $y, $z, $x ];
}
is_deeply t0(), [ -1, 0, 123, -1 ];
is_deeply t0(qw(a)), [ -1, "a", 123, -1 ];
is_deeply t0(qw(a b)), [ -1, "a", "b", -1 ];
is_deeply t0(qw(a b c)), [ qw(c a b c) ];
is_deeply t0(qw(a b c d)), [ qw(c a b c) ];
is_deeply t0(undef, qw(b c d)), [ "c", 0, "b", "c" ];
is_deeply t0("a", undef, "c", "d"), [ "c", "a", 123, "c" ];
is_deeply t0("a", "b", undef, "d"), [ -1, "a", "b", -1 ];
is_deeply t0("a", "b", "c", undef), [ qw(c a b c) ];

sub t1 {
	my $a = shift // -200;
	my $b = shift // -128;
	my $c = shift // -127;
	my $d = shift // 127;
	my $e = shift // 128;
	my $f = shift // 200;
	my $g = shift // "001";
	my $h = shift // "";
	return [ $a, $b, $c, $d, $e, $f, $g, $h ];
}
is_deeply t1(qw(A B C D E F G H)), [qw(A B C D E F G H)];
is_deeply t1(), [ -200, -128, -127, 127, 128, 200, "001", "" ];

1;
