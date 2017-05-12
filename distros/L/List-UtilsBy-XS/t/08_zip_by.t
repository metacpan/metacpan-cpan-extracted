use strict;
use warnings;

use Test::More;

use List::UtilsBy::XS qw(zip_by);

my @gots;
my $expected;

is_deeply( [ zip_by { } ], [], 'empty list' );
is_deeply( [ zip_by { [ @_ ] } [ "a" ], [ "b" ], [ "c" ] ], [ [ "a", "b", "c" ] ], 'singleton lists' );

@gots = zip_by { [ @_ ] } [ "a", "b", "c" ];
$expected = [ [ "a" ], [ "b" ], [ "c" ] ];
is_deeply(\@gots, $expected, 'narrow lists' );

@gots = zip_by { [ @_ ] } [ "a1", "a2" ], [ "b1", "b2" ];
$expected = [ [ "a1", "b1" ], [ "a2", "b2" ] ];
is_deeply(\@gots, $expected, 'zip with []' );

@gots = zip_by { join ",", @_ } [ "a1", "a2" ], [ "b1", "b2" ];
$expected = [ "a1,b1", "a2,b2" ];
is_deeply(\@gots, $expected, 'zip with join()' );

@gots = zip_by { [ @_ ] } [ 1 .. 3 ], [ 1 .. 2 ];
$expected = [ [ 1, 1 ], [ 2, 2 ], [ 3, undef ] ];
is_deeply(\@gots, $expected, 'non-rectangular adds undef' );

@gots = zip_by { @_ } [qw( one two three )], [ 1, 2, 3 ];
$expected = { one => 1, two => 2, three => 3 };
is_deeply({ @gots }, $expected, 'itemfunc can return lists' );

done_testing;
