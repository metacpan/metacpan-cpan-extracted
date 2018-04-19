use strict;
use warnings;

use Data::Dumper;
use Test::More;
use Test::Number::Delta within => 1e-9;
use Math::Utils::XS q(:utility);

sub test_sign {
    my @cases = (
        [ -3.14, -1 ],
        [ -2, -1 ],
        [ -1, -1 ],
        [  0,  0 ],
        [ +1, +1 ],
        [ +2, +1 ],
        [ +3.14, +1 ],
    );
    foreach my $case (@cases) {
        my $num = $case->[0];
        my $expected = $case->[1];
        my $got = sign($num);
        is($got, $expected, "sign($num) is corect");
    }
}

sub test_floor {
    my @cases = (
        [ -3.14, -4 ],
        [ -2.71, -3 ],
        [ -2, -2 ],
        [ -1, -1 ],
        [  0,  0 ],
        [ +1, +1 ],
        [ +2, +2 ],
        [ +2.71,  2 ],
        [ +3.14, +3 ],
    );
    foreach my $case (@cases) {
        my $num = $case->[0];
        my $expected = $case->[1];
        my $got = floor($num);
        delta_ok($got, $expected, "floor($num) is corect");
    }
}

sub test_ceil {
    my @cases = (
        [ -3.14, -3 ],
        [ -2.71, -2 ],
        [ -2, -2 ],
        [ -1, -1 ],
        [  0,  0 ],
        [ +1, +1 ],
        [ +2, +2 ],
        [ +2.71,  3 ],
        [ +3.14, +4 ],
    );
    foreach my $case (@cases) {
        my $num = $case->[0];
        my $expected = $case->[1];
        my $got = ceil($num);
        delta_ok($got, $expected, "floor($num) is corect");
    }
}

sub main {
    test_sign();
    test_floor();
    test_ceil();
    done_testing;
    return 0;
}

exit main();
