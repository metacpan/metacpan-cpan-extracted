use Test::More tests => 9;

use FindBin;
use lib "$FindBin::Bin/../lib";
use strict;
use warnings;
use Hash::MD5 qw( sum );

my $sum1 = sum(
    [
        "This", { string => "This is a test string.", number => 'This is a another string.' },
        "a", "test", "string."
    ]
);
my $sum2 = sum(
    [
        "This", { number => 'This is a another string.', string => "This is a test string." },
        "a", "test", "string."
    ]
);
ok( ( $sum1 eq $sum2 ) == 1, 'test compare array with numbers' );

$sum1 = sum( [ 1, 2 ] );
$sum2 = sum( [q{1","2}] );
ok( ( $sum1 eq $sum2 ) != 1, 'test compare array with numbers' );

$sum1 = sum( [ 1, 2, 3 ] );
$sum2 = sum( [ q{1","2}, 3 ] );
ok( ( $sum1 eq $sum2 ) != 1, 'test compare array with numbers' );

$sum1 = sum( [ 1,      q{2,3} ] );
$sum2 = sum( [ q{1,2}, 3 ] );
ok( ( $sum1 eq $sum2 ) != 1, 'test compare array with numbers' );

$sum1 = sum( [ 1,      q{2,3} ] );
$sum2 = sum( [ q{1,2}, 3 ] );
ok( ( $sum1 eq $sum2 ) != 1, 'test compare array with numbers' );

$sum1 = sum( [ 1,      q{2,3}, 4 ] );
$sum2 = sum( [ q{1,2}, 3,      4 ] );
ok( ( $sum1 eq $sum2 ) != 1, 'test compare array with numbers' );

$sum1 = sum(
    [ 1, 2, { string => "This is a test string.", number => 'This is a another string.' } ] );
$sum2 = sum(
    [ 1, 2, q~{ string => "This is a test string.", number => 'This is a another string.'}~ ] );
ok( ( $sum1 eq $sum2 ) != 1, 'test compare array with numbers' );

$sum1 = sum( ["\x{0100}"] );
$sum2 = sum( ["Ā"] );
ok( ( $sum1 eq $sum2 ) != 1, 'test compare character encodings' );

$sum1 = sum( [ 1,      q{2,3}, [ 1, 2, 3 ] ] );
$sum2 = sum( [ q{1,2}, 3,      [ 1, 2, 3 ] ] );
ok( ( $sum1 eq $sum2 ) != 1, 'test compare array with numbers' );

