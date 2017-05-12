use strict;
use warnings;

use Test::More;

use List::UtilsBy::XS qw(min_by nmin_by);

my $expected;
my $got;
my @gots;
my @array;

is_deeply( [ min_by {} ], [], 'empty list yields empty' );

$got = scalar (min_by { $_ } 10);
ok($got == 10, 'unit list yields value in scalar context');
is_deeply( [ min_by { $_ } 10 ], [ 10 ], 'unit list yields unit list value' );

is_deeply( ( scalar min_by { $_ } 10, 20 ), 10, 'identity function on $_' );

$got = scalar(min_by { length $_ } "a", "ccc", "bb");
ok($got eq 'a', "length function in scalar context");

@gots = min_by { length $_ } "a", "ccc", "bb";
is_deeply(\@gots, [ 'a' ], "length function in list context");

$got = scalar(min_by { length $_ } "a", "ccc", "bb", "ddd");
ok($got eq 'a', "first max element");

@gots = min_by { length $_ } "a", "ccc", "b", "ddd";
$expected = [ qw/a b/ ];
is_deeply(\@gots, $expected, 'ties yield all maximal in list context');

is_deeply( ( scalar nmin_by { $_ } 10, 20 ), 10, 'nmin_by alias' );

done_testing;
