#!/usr/bin/perl

use v5.18;
use warnings FATAL => 'all';
use Test2::V0;

use FormValidator::Tiny qw( length_in_range );

like dies {
        my $foo = length_in_range(10, 1);
    }, qr/must be less than or equal/,
    'invalid range causes error';

like dies {
        my $foo = length_in_range(-1, 10);
    }, qr/must be a positive/,
    'invalid minimum causes error';

like dies {
        my $foo = length_in_range('x', 10);
    }, qr/must be a positive integer/,
    'invalid minimum causes error';

like dies {
        my $foo = length_in_range(1, 'x');
    }, qr/must be a positive integer/,
    'invalid maximum causes error';

my ($v, $e);

my $limit_5_10 = length_in_range(5, 10);
($v, $e) = $limit_5_10->('x' x 4);
ok !$v, 'short string is invalid';
like $e, qr/Must be at least 5/, 'error message for too short';
($v, $e) = $limit_5_10->('x' x 6);
ok $v, 'medium string is valid';
($v, $e) = $limit_5_10->('x' x 12);
ok !$v, 'long string is invalid';
like $e, qr/Must be no longer than 10/, 'error message for too long';

my $limit_s_10 = length_in_range('*', 10);
($v, $e) = $limit_s_10->('x' x 4);
ok $v, 'short string is valid';
($v, $e) = $limit_s_10->('x' x 6);
ok $v, 'medium string is valid';
($v, $e) = $limit_s_10->('x' x 12);
ok !$v, 'long string is invalid';
like $e, qr/Must be no longer than 10/, 'error message for too long';

my $limit_5_s = length_in_range(5, '*');
($v, $e) = $limit_5_s->('x' x 4);
ok !$v, 'short string is invalid';
like $e, qr/Must be at least 5/, 'error message for too short';
($v, $e) = $limit_5_s->('x' x 6);
ok $v, 'medium string is valid';
($v, $e) = $limit_5_s->('x' x 12);
ok $v, 'long string is valid';

my $limit_s_s = length_in_range('*', '*');
($v, $e) = $limit_s_s->('x' x 4);
ok $v, 'short string is valid';
($v, $e) = $limit_s_s->('x' x 6);
ok $v, 'medium string is valid';
($v, $e) = $limit_s_s->('x' x 12);
ok $v, 'long string is valid';

done_testing;
