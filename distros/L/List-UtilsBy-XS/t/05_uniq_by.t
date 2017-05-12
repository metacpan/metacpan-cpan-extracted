use strict;
use warnings;

use Test::More;
use List::UtilsBy::XS qw( uniq_by );

my $expected;
my @gots;
my @array;

is_deeply( [ uniq_by { } ], [], 'empty list' );

is_deeply( [ uniq_by { $_ } "a" ], [ "a" ], 'unit list' );

@gots = uniq_by { $_ } "a", "b";
is_deeply(\@gots, [ "a", "b" ],'identity function no-op');

@gots = uniq_by { $_ } "b", "a";
is_deeply(\@gots, [ "b", "a" ], 'identity function on $_' );

@gots = uniq_by { length $_ } "a", "b", "cc", "dd", "eee";
is_deeply(\@gots, [ "a", "cc", "eee" ], 'length function' );

done_testing;
