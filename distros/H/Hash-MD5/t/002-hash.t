use Test::More tests => 15;

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../lib";
use Hash::MD5 qw( sum );

# 01.)
my $check_sum1 =
  sum( { string => "This is a test string.", number => 'This is a another string.' } );
my $check_sum2 =
  sum( { number => 'This is a another string.', string => "This is a test string." } );
ok( ( $check_sum1 eq $check_sum2 ) == 1, 'test compare strings' );

# 02.)
$check_sum1 = sum( { string => 123, number => 321 } );
$check_sum2 = sum( { number => 321, string => 123 } );
ok( ( $check_sum1 eq $check_sum2 ) == 1, 'test compare number' );

# 03.)
$check_sum1 = sum( { string => 321, number => 123 } );
$check_sum2 = sum( { number => 321, string => 123 } );
ok( ( $check_sum1 eq $check_sum2 ) != 1, 'test compare number' );

# 04.)
$check_sum1 = sum( { number => 321, string => "This is a test string." } );
$check_sum2 = sum( { string => "This is a test string.", number => 321 } );
ok( ( $check_sum1 eq $check_sum2 ) == 1, 'test compare mixed' );

# 05.)
$check_sum1 = sum( { number => 321, string => "This is a test string.", a => [ 1, 2, 3 ] } );
$check_sum2 = sum( { string => "This is a test string.", number => 321, a => [ 1, 2, 3 ] } );
ok( ( $check_sum1 eq $check_sum2 ) == 1, 'test compare mixed' );

# 06.)
$check_sum1 = sum( { a  => '', aaaa => '', } );
$check_sum2 = sum( { aa => '', aaa  => '', } );
ok( ( $check_sum1 eq $check_sum2 ) != 1, 'different keys 1' );

# 07.)
$check_sum1 = sum( { a => 'a',           aa => 'aaaaaaaaaaa', } );
$check_sum2 = sum( { a => 'aaaaaaaaaaa', aa => 'a', } );
ok( ( $check_sum1 eq $check_sum2 ) != 1, 'different keys 2' );

# 08.)
$check_sum1 = sum( { 11111111111 => '', 2           => '', } );
$check_sum2 = sum( { 1           => '', 11111111112 => '', } );
ok( ( $check_sum1 eq $check_sum2 ) != 1, 'different keys 3' );

# 09.)
$check_sum1 = sum( { 11111111111 => '', 2           => '', } );
$check_sum2 = sum( { 1           => '', 11111111112 => '', } );
ok( ( $check_sum1 eq $check_sum2 ) != 1, 'different keys 4' );

# 10.)
$check_sum1 = sum( { 'aaaaaaaaaaaaaaa"' => '', } );
$check_sum2 = sum( { a => 'aa', aa => 'aaaaaaaaaa' } );
ok( ( $check_sum1 eq $check_sum2 ) != 1, 'string keys' );

# 11.)
my %x;
$x{a} = \%x;
ok( defined sum( \%x ), 'deep recursion 1' );

# 12.)
%x = ();
$x{a} = 'one';
$x{b} = { c => \%x };
ok( defined sum( \%x ), 'very deep recursion' );

# 13.)
ok( ( sum( { b => {} } ) eq sum( { b => {} } ) ) == 1, 'same hashref 1' );

# 14.)
my $same = { b => {} };
ok( ( sum( { b => {} } ) eq sum($same) ) == 1, 'same hashref 2' );

# 15.)
my %same = ( b => {} );
ok( ( sum( { b => {} } ) eq sum( \%same ) ) == 1, 'same hashref 3' );

