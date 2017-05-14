use warnings;
use strict;

use Test::More tests => 20;

use Devel::GoFaster;

sub t0 {
	return [ shift(@_), [@_] ];
}
is_deeply t0(), [ undef, [] ];
is_deeply t0(qw(a)), [ "a", [] ];
is_deeply t0(qw(a b)), [ "a", [qw(b)] ];
is_deeply t0(qw(a b c)), [ "a", [qw(b c)] ];
is_deeply t0(qw(a b c d)), [ "a", [qw(b c d)] ];

sub t1 {
	shift(@_);
	return [@_];
}
is_deeply t1(), [];
is_deeply t1(qw(a)), [];
is_deeply t1(qw(a b)), [qw(b)];
is_deeply t1(qw(a b c)), [qw(b c)];
is_deeply t1(qw(a b c d)), [qw(b c d)];

sub t2 {
	my $x = 100 + shift(@_);
	return [ $x, [@_] ];
}
is_deeply t2(1), [ 101, [] ];
is_deeply t2(1, 2), [ 101, [2] ];
is_deeply t2(1, 2, 3), [ 101, [2, 3] ];

our @t3 = qw(x y z);
sub t3 {
	return [ shift(@t3), [@t3], [@_] ];
}
is_deeply t3(qw(a b c)), [ "x", [qw(y z)], [qw(a b c)] ];
is_deeply t3(qw(a b c)), [ "y", [qw(z)], [qw(a b c)] ];

sub t4 {
	return [ shift(), [@_] ];
}
is_deeply t4(), [ undef, [] ];
is_deeply t4(qw(a)), [ "a", [] ];
is_deeply t4(qw(a b)), [ "a", [qw(b)] ];
is_deeply t4(qw(a b c)), [ "a", [qw(b c)] ];
is_deeply t4(qw(a b c d)), [ "a", [qw(b c d)] ];

1;
