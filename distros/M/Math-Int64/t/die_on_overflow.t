#!/usr/bin/perl

use strict;
use warnings;

use Test::More 0.88;

use Math::Int64 qw(int64 uint64 string_to_int64 string_to_uint64);
use Math::Int64::die_on_overflow;

sub test_overflow (&@) {
    my $sub = shift;
    my $tb = Test::More->builder;
    my $r = eval { $sub->() };
    my $ok = $@ =~ /^Math::Int64 overflow\b/;
    $tb->ok($ok, @_);
    $tb->diag("\$r = $r") unless $ok
}

sub test_no_overflow (&@) {
    my $sub = shift;
    my $tb = Test::More->builder;
    my $r = eval { $sub->() };
    my $ok = $@ !~ /^Math::Int64 overflow\b/;
    $tb->ok($ok, @_);
    $tb->diag("\$@ = $@") unless $ok;
}

my $u2_0 = uint64(1);
my $s2_0 = int64(1);
my $ns2_0 = -$s2_0;
my $u2_30 = $u2_0 << 30;
my $u2_31 = $u2_0 << 31;
my $u2_32 = $u2_0 << 32;
my $u2_40 = $u2_0 << 40;

my $uint64_max = string_to_uint64('0xffffffffffffffff');
my $int64_max = string_to_int64('0x7fffffffffffffff');
my $int64_min = string_to_int64('-0x8000000000000000');

test_overflow { uint64(2**65) } 'overflow - NV 2_65 -> uint64';
test_overflow { uint64(2**64) } 'overflow - NV 2_64 -> uint64';
test_no_overflow { uint64(2**63) } 'overflow - NV 2_63 -> uint64';
test_overflow { int64(2**65) } 'overflow - NV 2_65 -> int64';
test_overflow { int64(2**64) } 'overflow - NV 2_64 -> int64';
test_overflow { int64(2**63) } 'overflow - NV 2_63 -> int64';
test_no_overflow { int64(2**62) } 'overflow - NV 2_62 -> int64';
test_overflow { int64(-(2**65)) } 'overflow - NV -2_65 -> int64';
test_overflow { int64(-(2**64)) } 'overflow - NV -2_64 -> int64';
test_no_overflow { int64(-(2**63)) } 'overflow - NV -2_63 -> int64';
test_no_overflow { int64(-(2**62)) } 'overflow - NV -2_62 -> int64';
test_overflow { uint64(-1) } 'overflow - SV -1 -> int64';
test_overflow { int64(uint64(1) << 63) } 'overflow - uint64 2_63 -> int64';
test_no_overflow { int64(uint64(1) << 63 - 1) } 'overflow - uint64 2_63 - 1 -> int64';
test_overflow { uint64('18446744073709551616') } 'overflow - "18446744073709551616"-> uint64';
test_no_overflow { uint64('18446744073709551615') } 'overflow - "18446744073709551615"-> uint64';
test_overflow { uint64('-18446744073709551616') } 'overflow - "-18446744073709551616"-> uint64';
test_overflow { uint64('-1') } 'overflow - "-1" -> uint64';
test_overflow { uint64('20000000000000000000') } 'overflow - "20000000000000000000"-> uint64';

test_overflow { int64('9223372036854775808') } 'overflow - "9223372036854775808"-> int64';
test_no_overflow { int64('9223372036854775807') } 'overflow - "9223372036854775807"-> int64';
test_no_overflow { int64('-9223372036854775807') } 'overflow - "-9223372036854775807"-> int64';
test_no_overflow { int64('-9223372036854775808') } 'overflow - "-9223372036854775808"-> int64';
test_overflow { int64('-9223372036854775809') } 'overflow - "-9223372036854775809"-> int64';
test_no_overflow { int64('-1') } 'overflow - "-1" -> int64';
test_overflow { int64('20000000000000000000') } 'overflow - "20000000000000000000"-> int64';
test_overflow { int64('-20000000000000000000') } 'overflow - "-20000000000000000000"-> int64';

my $b;
test_overflow { $b = $uint64_max; $b++ } 'overflow - inc UINT64_MAX';
test_overflow { $b = $int64_max; $b++ } 'overflow - inc INT64_MAX';
test_overflow { $b = uint64(0); $b-- } 'overflow - dec 0';
test_overflow { $b = $int64_min; $b-- } 'overflow - dec INT64_MIN';

test_overflow { $uint64_max + 1 } 'overflow - UINT64_MAX + 1';
test_no_overflow { $uint64_max - 1 } 'overflow - UINT64_MAX - 1';
test_overflow { $int64_max + 1 } 'overflow - INTE64_MAX + 1';
test_overflow { uint64(0) - 1 } 'overflow - uint64 0 - 1';
test_overflow { $int64_min - 1 } 'overflow - INT64_MIN - 1';

test_no_overflow { $u2_31 * $u2_31 } 'overflow - mul 31x31';
test_no_overflow { $u2_31 * $u2_32 } 'overflow - mul 31x32';
test_overflow { $u2_32 * $u2_32 } 'overflow - mul 32x32';
test_overflow { $u2_40 * $u2_30 } 'overflow - mul 40x30';

test_no_overflow { $u2_0 << 64 } 'overflow - left shift 1 << 64';
test_no_overflow { $s2_0 << 64 } 'overflow - left shift 1 << 64, signed';
test_no_overflow { $s2_0 << 63 } 'overflow - left shift 1 << 63, signed';
test_no_overflow { $s2_0 << 62 } 'overflow - left shift 1 << 62, signed';

test_overflow { uint64(2) ** 64 } 'overflow - 2 ** 64';
test_overflow { int64(2) ** 63 } ' overflow - signed 2 ** 63';

test_overflow { uint64(2642246) ** 3 } 'overflow - 2642246 ** 3';
test_no_overflow { uint64(2642245) ** 3 } 'no overflow - 2642245 ** 3';

no Math::Int64::die_on_overflow;


SKIP: {
    skip "lexical pragmas require perl 5.10 or later", 30 if $^V < 5.010;

    test_no_overflow { uint64(2**65) } 'no overflow - NV 2_65 -> uint64';
    test_no_overflow { uint64(2**64) } 'no overflow - NV 2_64 -> uint64';
    test_no_overflow { int64(2**65) } 'no overflow - NV 2_65 -> int64';
    test_no_overflow { int64(2**64) } 'no overflow - NV 2_64 -> int64';
    test_no_overflow { int64(2**63) } 'no overflow - NV 2_63 -> int64';
    test_no_overflow { int64(-(2**65)) } 'no overflow - NV -2_65 -> int64';
    test_no_overflow { int64(-(2**64)) } 'no overflow - NV -2_64 -> int64';
    test_no_overflow { uint64(-1) } 'no overflow - SV -1 -> int64';
    test_no_overflow { int64(uint64(1) << 63) } 'no overflow - uint64 2_63 -> int64';
    test_no_overflow { uint64('18446744073709551616') } 'no overflow - "18446744073709551616"-> uint64';
    test_no_overflow { uint64('-18446744073709551616') } 'no overflow - "-18446744073709551616"-> uint64';
    test_no_overflow { uint64('-1') } 'no overflow - "-1" -> uint64';
    test_no_overflow { uint64('20000000000000000000') } 'no overflow - "20000000000000000000"-> uint64';
    test_no_overflow { int64('9223372036854775808') } 'no overflow - "9223372036854775808"-> int64';
    test_no_overflow { int64('-9223372036854775809') } 'no overflow - "-9223372036854775809"-> int64';
    test_no_overflow { int64('20000000000000000000') } 'no overflow - "20000000000000000000"-> int64';
    test_no_overflow { int64('-20000000000000000000') } 'no overflow - "-20000000000000000000"-> int64';
    test_no_overflow { $b = $uint64_max; $b++ } 'no overflow - inc UINT64_MAX';
    test_no_overflow { $b = $int64_max; $b++ } 'no overflow - inc INT64_MAX';
    test_no_overflow { $b = uint64(0); $b-- } 'no overflow - dec 0';
    test_no_overflow { $b = $int64_min; $b-- } 'no overflow - dec INT64_MIN';
    test_no_overflow { $uint64_max + 1 } 'no overflow - UINT64_MAX + 1';
    test_no_overflow { $int64_max + 1 } 'no overflow - INTE64_MAX + 1';
    test_no_overflow { uint64(0) - 1 } 'no overflow - uint64 0 - 1';
    test_no_overflow { $int64_min - 1 } 'no overflow - INT64_MIN - 1';
    test_no_overflow { $u2_32 * $u2_32 } 'no overflow - mul 32x32';
    test_no_overflow { $u2_40 * $u2_30 } 'no overflow - mul 40x30';
    test_no_overflow { $u2_0 << 64 } 'no overflow - left shift 1 << 64';
    test_no_overflow { $s2_0 << 64 } 'no overflow - left shift 1 << 64, signed';
    test_no_overflow { $s2_0 << 63 } 'no overflow - left shift 1 << 63, signed';
}

done_testing();
