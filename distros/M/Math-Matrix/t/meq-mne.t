#!perl

use strict;
use warnings;

use Math::Matrix;
use Test::More tests => 56;

note('same size matrices with the same values');

{
    my $x = Math::Matrix -> new([[-1, 0, 1, 2]]);
    my $y = Math::Matrix -> new([[-1, 0, 1, 2]]);

    my $b0 = $x -> meq($y);
    is(ref($b0), '', '$b0 is a Perl scalar');
    cmp_ok($b0, '==', 1, '$b0 has the right values');

    is_deeply([ @$x ], [[-1, 0, 1, 2]], '$x is unmodified');
    is_deeply([ @$y ], [[-1, 0, 1, 2]], '$y is unmodified');

    my $b1 = $x -> mne($y);
    is(ref($b1), '', '$b1 is a Perl scalar');
    cmp_ok($b1, '==', 0, '$b1 has the right values');

    is_deeply([ @$x ], [[-1, 0, 1, 2]], '$x is unmodified');
    is_deeply([ @$y ], [[-1, 0, 1, 2]], '$y is unmodified');
}

note('same size matrices with different values');

{
    my $x = Math::Matrix -> new([[-1, 0, 1, 2]]);
    my $y = Math::Matrix -> new([[-1, 0, 1, 3]]);

    my $b0 = $x -> meq($y);
    is(ref($b0), '', '$b0 is a Perl scalar');
    cmp_ok($b0, '==', 0, '$b0 has the right values');

    is_deeply([ @$x ], [[-1, 0, 1, 2]], '$x is unmodified');
    is_deeply([ @$y ], [[-1, 0, 1, 3]], '$y is unmodified');

    my $b1 = $x -> mne($y);
    is(ref($b1), '', '$b1 is a Perl scalar');
    cmp_ok($b1, '==', 1, '$b1 has the right values');

    is_deeply([ @$x ], [[-1, 0, 1, 2]], '$x is unmodified');
    is_deeply([ @$y ], [[-1, 0, 1, 3]], '$y is unmodified');
}

note('different size matrices');

{
    my $x = Math::Matrix -> new([[-1, 0, 1, 2]]);
    my $y = Math::Matrix -> new([[-1, 0, 1]]);

    my $b0 = $x -> meq($y);
    is(ref($b0), '', '$b0 is a Perl scalar');
    cmp_ok($b0, '==', 0, '$b0 has the right values');

    is_deeply([ @$x ], [[-1, 0, 1, 2]], '$x is unmodified');
    is_deeply([ @$y ], [[-1, 0, 1]], '$y is unmodified');

    my $b1 = $x -> mne($y);
    is(ref($b1), '', '$b1 is a Perl scalar');
    cmp_ok($b1, '==', 1, '$b1 has the right values');

    is_deeply([ @$x ], [[-1, 0, 1, 2]], '$x is unmodified');
    is_deeply([ @$y ], [[-1, 0, 1]], '$y is unmodified');
}

note('empty matrices');

{
    my $x = Math::Matrix -> new([]);
    my $y = Math::Matrix -> new([]);

    my $b0 = $x -> meq($y);
    is(ref($b0), '', '$b0 is a Perl scalar');
    cmp_ok($b0, '==', 1, '$b0 has the right values');

    is_deeply([ @$x ], [], '$x is unmodified');
    is_deeply([ @$y ], [], '$y is unmodified');

    my $b1 = $x -> mne($y);
    is(ref($b1), '', '$b1 is a Perl scalar');
    cmp_ok($b1, '==', 0, '$b1 has the right values');

    is_deeply([ @$x ], [], '$x is unmodified');
    is_deeply([ @$y ], [], '$y is unmodified');
}

note('matrix and Perl array');

{
    my $x = Math::Matrix -> new([[-1, 0, 1, 2]]);
    my $y = [[-1, 0, 1, 2]];

    my $b0 = $x -> meq($y);
    is(ref($b0), '', '$b0 is a Perl scalar');
    cmp_ok($b0, '==', 1, '$b0 has the right values');

    is_deeply([ @$x ], [[-1, 0, 1, 2]], '$x is unmodified');
    is_deeply([ @$y ], [[-1, 0, 1, 2]], '$y is unmodified');

    my $b1 = $x -> mne($y);
    is(ref($b1), '', '$b1 is a Perl scalar');
    cmp_ok($b1, '==', 0, '$b1 has the right values');

    is_deeply([ @$x ], [[-1, 0, 1, 2]], '$x is unmodified');
    is_deeply([ @$y ], [[-1, 0, 1, 2]], '$y is unmodified');
}

note('same size matrices with the same values (overloaded)');

{
    my $x = Math::Matrix -> new([[-1, 0, 1, 2]]);
    my $y = Math::Matrix -> new([[-1, 0, 1, 2]]);

    my $b0 = $x == $y;
    is(ref($b0), '', '$b0 is a Perl scalar');
    cmp_ok($b0, '==', 1, '$b0 has the right values');

    is_deeply([ @$x ], [[-1, 0, 1, 2]], '$x is unmodified');
    is_deeply([ @$y ], [[-1, 0, 1, 2]], '$y is unmodified');

    my $b1 = $x != $y;
    is(ref($b1), '', '$b1 is a Perl scalar');
    cmp_ok($b1, '==', 0, '$b1 has the right values');

    is_deeply([ @$x ], [[-1, 0, 1, 2]], '$x is unmodified');
    is_deeply([ @$y ], [[-1, 0, 1, 2]], '$y is unmodified');
}

note('same size matrices with different values (overloaded)');

{
    my $x = Math::Matrix -> new([[-1, 0, 1, 2]]);
    my $y = Math::Matrix -> new([[-1, 0, 1, 3]]);

    my $b0 = $x == $y;
    is(ref($b0), '', '$b0 is a Perl scalar');
    cmp_ok($b0, '==', 0, '$b0 has the right values');

    is_deeply([ @$x ], [[-1, 0, 1, 2]], '$x is unmodified');
    is_deeply([ @$y ], [[-1, 0, 1, 3]], '$y is unmodified');

    my $b1 = $x != $y;
    is(ref($b1), '', '$b1 is a Perl scalar');
    cmp_ok($b1, '==', 1, '$b1 has the right values');

    is_deeply([ @$x ], [[-1, 0, 1, 2]], '$x is unmodified');
    is_deeply([ @$y ], [[-1, 0, 1, 3]], '$y is unmodified');
}
