#!/usr/bin/perl

use v5.18;
use warnings FATAL => 'all';
use Test2::V0;

use FormValidator::Tiny qw( number_in_range );

like dies {
        my $foo = number_in_range(10, 1);
    }, qr/must be less than or equal/,
    'invalid range causes error';

like dies {
        my $foo = number_in_range('x', 10);
    }, qr/must be a positive integer/,
    'invalid minimum causes error';

like dies {
        my $foo = number_in_range(1, 'x');
    }, qr/must be a positive integer/,
    'invalid maximum causes error';

my ($v, $e);

my $limit_5_10 = number_in_range(5, 10);
($v, $e) = $limit_5_10->(4);
ok !$v, 'small number is invalid';
like $e, qr/must be at least 5/, 'error message for too small';
($v, $e) = $limit_5_10->(5);
ok $v, 'inclusive minimum is inclusive';
($v, $e) = $limit_5_10->(6);
ok $v, 'medium number is valid';
($v, $e) = $limit_5_10->(10);
ok $v, 'inclusive maximum is inclusive';
($v, $e) = $limit_5_10->(12);
ok !$v, 'large number is invalid';
like $e, qr/must be no more than 10/, 'error message for too large';

my $limit_x5_x10 = number_in_range(exclusive => 5, exclusive => 10);
($v, $e) = $limit_x5_x10->(5);
ok !$v, 'exclusive minimum is exclusive';
like $e, qr/must be greater than 5/, 'small exclusive error message';
($v, $e) = $limit_x5_x10->(10);
ok !$v, 'exclusive maximum is exclusive';
like $e, qr/must be less than 10/, 'large exclusive error message';

my $limit_s_10 = number_in_range('*', 10);
($v, $e) = $limit_s_10->(4);
ok $v, 'small number is valid';
($v, $e) = $limit_s_10->(6);
ok $v, 'medium number is valid';
($v, $e) = $limit_s_10->(12);
ok !$v, 'large number is invalid';
like $e, qr/must be no more than 10/, 'error message for too large';

my $limit_5_s = number_in_range(5, '*');
($v, $e) = $limit_5_s->(4);
ok !$v, 'small number is invalid';
like $e, qr/must be at least 5/, 'error message for too small';
($v, $e) = $limit_5_s->(6);
ok $v, 'medium number is valid';
($v, $e) = $limit_5_s->(12);
ok $v, 'large number is valid';

my $limit_s_s = number_in_range('*', '*');
($v, $e) = $limit_s_s->(4);
ok $v, 'small number is valid';
($v, $e) = $limit_s_s->(6);
ok $v, 'medium number is valid';
($v, $e) = $limit_s_s->(12);
ok $v, 'large number is valid';

done_testing;
