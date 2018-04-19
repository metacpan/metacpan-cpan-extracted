use strict;
use warnings;

use Data::Dumper;
use Test::More;
use Test::Number::Delta within => 1e-9;
use Math::Utils::XS qw/ log2 log10 /;

sub test_log10 {
    my @cases = (
        [ 1, 0 ],
        [ 5, 0.698970004336019 ],
        [ 10, 1 ],
        [ 15, 1.1760912591],
    );
    foreach my $case (@cases) {
        my $num = $case->[0];
        my $expected = $case->[1];
        my $got = log10($num);
        delta_ok($got, $expected, "log10($num) is corect");
    }
}

sub test_log2 {
    my @cases = (
        [ 1, 0 ],
        [ 2, 1 ],
        [ 3, 1.58496250072116 ],
        [ 4, 2 ],
        [ 5, 2.3219280949 ],
    );
    foreach my $case (@cases) {
        my $num = $case->[0];
        my $expected = $case->[1];
        my $got = log2($num);
        delta_ok($got, $expected, "log2($num) is corect");
    }
}

sub main {
    test_log10();
    test_log2();
    done_testing;
    return 0;
}

exit main();
