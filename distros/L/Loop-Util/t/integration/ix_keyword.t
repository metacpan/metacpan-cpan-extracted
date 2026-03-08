use Test2::V0;
use Loop::Util;

my @out;

loop (3) {
	push @out, __IX__;
}

is( \@out, [ 0, 1, 2 ], '__IX__ returns iteration index in loop' );

@out = ();
for my $item (qw(a b c)) {
	push @out, __IX__;
}

is( \@out, [ 0, 1, 2 ], '__IX__ returns index in for list loop' );

my $u = __IX__;
ok( !defined $u, '__IX__ returns undef outside supported loops' );

my $stdout = qx{perl -Mblib -Ilib -MLoop::Util -E'loop(3){ say __IX__ + 1 }'};
is( $stdout, "1\n2\n3\n", 'example usage prints expected numbers' );

done_testing;
