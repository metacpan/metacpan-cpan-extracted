#!/usr/bin/env perl

# Creation date: 2007-04-07 17:08:45
# Authors: don

use strict;
use Test;

# main
{
    use JSON::DWIW;
    my $converter = JSON::DWIW->new;

    local $SIG{__DIE__};

    my $have_big_int = JSON::DWIW->have_big_int;
    my $have_big_float = JSON::DWIW->have_big_float;

    my $num_tests = 1;
    if ($have_big_int) {
        $num_tests += 3;
    }
    else {
        $num_tests += 1;
    }
    
    if ($have_big_float) {
        $num_tests += 1;
    }
    else {
        $num_tests += 1;
    }
    
    plan tests => $num_tests;

    my $str = '{"stuff":42949672954294967295}';
    my $data = $converter->from_json($str);
    ok($data->{stuff} =~ /\A\+?42949672954294967295\Z/);
    
    if ($have_big_int) {
        my $big_int = Math::BigInt->new('42949672954294967295');
        $str = $converter->to_json($big_int);
        ok($str eq '42949672954294967295');
        
        ok(($data->{stuff} + 500) . '' =~ /\A\+?42949672954294967795\Z/);
        
        $data = { stuff => Math::BigInt->new('340282366920938463463374607431768211456') }; # 2^128
        $str = $converter->to_json($data);
        ok($str eq '{"stuff":340282366920938463463374607431768211456}');
    }
    else {
        skip("don't have Math::BigInt", 0);
    }

    if ($have_big_float) {
        $data = { stuff => Math::BigFloat->new('115792089237316195423570985008687907853269984665640564039457584007913129639936') }; # 2^256
        $str = $converter->to_json($data);
        ok($str eq '{"stuff":115792089237316195423570985008687907853269984665640564039457584007913129639936}');
#         my $val = Math::BigFloat->new('2');
#         $data = { stuff => $val ** 512 };
#         $str = $converter->to_json($data);
#         ok($str eq '{"stuff":13407807929942597099574024998205846127479365820592393377723561443721764030073546976801874298166903427690031858186486050853753882811946569946433649006084096}');
    }
    else {
        skip("don't have Math::BigFloat", 0);
    }

}

exit 0;

###############################################################################
# Subroutines

