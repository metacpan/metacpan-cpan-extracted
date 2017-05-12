use strict;
use warnings;

use Test::More;

use List::UtilsBy::XS qw( sort_by rev_sort_by );

{
    my $expected;
    my @gots;
    my @array;

    is_deeply( [ sort_by { } ], [], 'sort_by with empty list' );
    is_deeply( [ sort_by { $_ } "a" ], [ "a" ], 'unit list' );

    my $obj = { foo => 'bar' };
    $expected = [ { foo => 'bar' } ];
    @gots = sort_by { $_->{bar} } $obj;
    is_deeply(\@gots, $expected, "unit list by hash key");

    is_deeply( [ sort_by { $_ } "a", "b" ], [ "a", "b" ], 'identity function no-op' );
    is_deeply( [ sort_by { $_ } "b", "a" ], [ "a", "b" ], 'identity function on $_' );

    is_deeply( [ sort_by { reverse $_ } "az", "by" ], [ "by", "az" ], 'reverse function' );
}

{
    my $expected;
    my @gots;
    my @array;

    is_deeply( [ sort_by { } ], [], 'rev_sort_by with empty list' );

    $expected = ["b", "a"];
    @gots = rev_sort_by { $_ } "a", "b";
    is_deeply(\@gots, $expected, 'reverse sort identity function');

    push @array, { foo => 'aaa' };
    push @array, { foo => 'bbb' };

    @gots = rev_sort_by { $_->{foo} } @array;
    $expected = [ { foo => "bbb" }, { foo => "aaa" } ];
    is_deeply(\@gots, $expected, "reverse sort by hash key 'foo'");
}

done_testing;
