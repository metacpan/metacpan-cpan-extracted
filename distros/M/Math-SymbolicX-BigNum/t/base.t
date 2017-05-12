use strict;
use warnings;
use Test::More tests => 15;

use_ok('Math::Symbolic');
use_ok('Math::SymbolicX::BigNum');
use_ok('Math::BigRat');

use Math::Symbolic qw/parse_from_string/;

my $bigint = parse_from_string('bigint(1)');
ok( defined $bigint, 'bigint-parse defined' );
ok( $bigint->value() == 1, 'bigint-value okay' );

$bigint = parse_from_string('2 * bigint(100000000000000000000) + 2');
ok( defined $bigint, 'bigint-parse defined' );
ok( $bigint->value() =~ /\Q200000000000000000002\E/, 'bigint-value okay' );

$bigint = parse_from_string('bigint(-100000000000000000000)^2 + 2');
ok( defined $bigint, 'bigint-parse defined' );
ok( $bigint->value() =~ /\Q10000000000000000000000000000000000000002\E/,
    'bigint-value okay' );

my $bigfloat =
  parse_from_string('bigfloat(1000000000000.0000000000000000000000000000001)');
ok( defined $bigfloat, 'bigfloat-parse defined' );
ok( $bigfloat->value() =~ /\Q1000000000000.0000000000000000000000000000001\E/,
    'bigfloat-value okay' );

$bigfloat =
  parse_from_string(
    'bigfloat(1000000000000.0000000000000000000000000000001)^2 - 1');
ok( defined $bigfloat, 'bigfloat-parse defined' );
ok(
    $bigfloat->value() =~
/\Q999999999999999999999999.00000000000000000020000000000000000000000000000000000000000001\E/,
    'bigfloat-value okay'
);

my $bigrat = parse_from_string('bigrat(1/7)');
ok( defined $bigrat, 'bigrat-parse defined' );
ok( $bigrat->value() == Math::BigRat->new('1/7'), 'bigrat-value okay' );

