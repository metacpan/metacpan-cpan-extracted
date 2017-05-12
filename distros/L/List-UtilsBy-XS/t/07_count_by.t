use strict;
use warnings;

use Test::More;

use List::UtilsBy::XS qw(count_by);

my $expected;
my %gots;
my @array;

is_deeply( { count_by { } }, {}, 'empty list' );
is_deeply( { count_by { $_ } "a" }, { a => 1 }, 'unit list' );

is_deeply( { count_by { "all" } "a", "b" }, { all => 2 }, 'constant function' );

%gots = count_by { length $_ } "a", "b", "cc", "dd", "eee";
$expected = { 1 => 2, 2 => 2, 3 => 1 };
is_deeply(\%gots, $expected, 'length function' );

done_testing;
