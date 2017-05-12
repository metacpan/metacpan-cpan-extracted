use strict;
use warnings;

use Test::More;

use List::UtilsBy::XS qw( nsort_by rev_nsort_by );

{
    my $expected;
    my @gots;
    my @array;

    is_deeply( [ nsort_by { } ], [], 'nsort_by empty list' );

    is_deeply( [ nsort_by { $_ } 1 ], [ 1 ], 'nsort_by unit list' );

    @gots = nsort_by { $_ } 20, 25;
    is_deeply(\@gots, [ 20, 25 ], 'identity function no-op' );

    @gots = nsort_by { $_ } 25, 20;
    is_deeply(\@gots, [ 20, 25 ], 'identity function on $_' );

    @gots = nsort_by { $_ } 1.0, 2.1, 1.5;
    is_deeply(\@gots, [ 1.0, 1.5, 2.1 ], 'floating numbers sort' );

    is_deeply( [ nsort_by { length $_ } "a", "bbb", "cc" ], [ "a", "cc", "bbb" ], 'length function' );

    # List context would yield the matches and fail, scalar context would yield
    # the count and be correct
    @gots = nsort_by { () = m/(a)/g } "apple", "hello", "armageddon";
    $expected = [ qw/hello apple armageddon/ ];
    is_deeply(\@gots, $expected, 'scalar context' );
}

{
    my $expected;
    my @gots;
    my @array;

    is_deeply( [ rev_nsort_by { } ], [], 'rev_nsort_by empty list' );
    is_deeply( [ rev_nsort_by { $_ } 1 ], [ 1 ], 'rev_nsort_by unit list' );

    @gots = rev_nsort_by { $_ } 20, 25;
    is_deeply(\@gots, [ 25, 20 ], 'identity function no-op' );

    @gots = rev_nsort_by { $_ } 25, 20;
    is_deeply(\@gots, [ 25, 20 ], 'identity function on $_' );

    @gots = rev_nsort_by { $_ } 1.0, 2.0, 1.5;
    is_deeply(\@gots, [ 2.0, 1.5, 1.0 ], 'floating numbers sort' );

    @gots = rev_nsort_by { length $_ } "a", "bbb", "cc";
    $expected = [ qw/bbb cc a/ ];
    is_deeply(\@gots, $expected, 'reverse sort length function' );

    @gots = rev_nsort_by { () = m/(a)/g } "apple", "hello", "armageddon";
    $expected = [ qw/armageddon apple hello/ ];
    is_deeply(\@gots, $expected, 'scalar context' );
}

done_testing;
