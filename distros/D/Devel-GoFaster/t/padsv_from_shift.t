use warnings;
use strict;

use Test::More tests => 12;

use Devel::GoFaster;

sub t0 {
	my $x;
	my $y = shift;
	my $z = shift(@_);
	return [ ($x = shift), scalar(my $t = shift), $y, $z, $x ];
}
is_deeply t0(), [ undef, undef, undef, undef, undef ];
is_deeply t0(qw(a)), [ undef, undef, "a", undef, undef ];
is_deeply t0(qw(a b)), [ undef, undef, "a", "b", undef ];
is_deeply t0(qw(a b c)), [ "c", undef, qw(a b c) ];
is_deeply t0(qw(a b c d)), [ qw(c d a b c) ];
is_deeply t0(undef, qw(b c d)), [ qw(c d), undef, qw(b c) ];

our @t1 = qw(x y z);
sub t1 {
	my $x = shift;
	my $y = shift(@t1);
	my $z = shift;
	return [ $x, $y, $z ];
}
is_deeply t1(qw(a b c)), [ "a", "x", "b" ];
is_deeply t1(qw(a b c)), [ "a", "y", "b" ];

sub t2 {
	my $x = shift;
	return sub { $x };
}
my $t2a = t2("aaa");
my $t2b = t2("bbb");
is ref($t2a), "CODE";
is ref($t2b), "CODE";
is $t2a->(), "aaa";
is $t2b->(), "bbb";

1;
