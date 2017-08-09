#!/usr/bin/perl

use v5.18;
use warnings FATAL => 'all';
use Test2::V0;

use FormValidator::Tiny qw( equal_to );

my $equal_to = equal_to('x');

my ($v, $e);

($v, $e) = $equal_to->('abc', { 'x' => 'abc' });
ok $v, 'equal_to passes when it should pass';

($v, $e) = $equal_to->('xyz', { 'x' => 'abc' });
ok !$v, 'equal_to fails when it should fail';
like $e, qr/must match x/, 'got a reasonable error message';

done_testing;
