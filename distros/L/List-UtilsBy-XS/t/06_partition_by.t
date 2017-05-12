use strict;
use warnings;

use Test::More;
use List::UtilsBy::XS qw(partition_by);

my $expected;
my %gots;
my @array;

is_deeply( { partition_by { } }, {}, 'empty list' );
is_deeply({ partition_by { $_ } "a" }, { a => [ "a" ] }, 'unit list' );

%gots = partition_by { "all" } "a", "b";
$expected = { all => [ "a", "b" ] };
is_deeply(\%gots, $expected, 'constant function preserves order' );

%gots = partition_by { "all" } "b", "a";
$expected = { all => [ "b", "a" ] };
is_deeply(\%gots, $expected, 'constant function preserves order' );

%gots = partition_by { length $_ } "a", "b", "cc", "dd", "eee";
$expected = { 1 => [ "a", "b" ], 2 => [ "cc", "dd" ], 3 => [ "eee" ] };
is_deeply(\%gots, $expected, 'length function');

done_testing;
