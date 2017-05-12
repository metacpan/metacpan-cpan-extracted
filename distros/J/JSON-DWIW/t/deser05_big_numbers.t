#!/usr/bin/env perl

# Creation date: 2007-04-07 17:08:45
# Authors: don

use strict;
use Test;

# main
{
    use JSON::DWIW;

    unless (JSON::DWIW->has_deserialize) {
        plan tests => 1;

        print "# deserialize not implemented on this platform\n";
        skip("Skipping on this platform", 0); # skipping on this platform
        exit 0;
    }


    local $SIG{__DIE__};

    my $converter = JSON::DWIW->new;
    my $have_big_int = JSON::DWIW->have_big_int;
    my $have_big_float = JSON::DWIW->have_big_float;

    my $num_tests = 1;
    if ($have_big_int) {
        # print STDERR "# have big int\n";
        $num_tests += 1;
    }
    else {
        $num_tests += 1;
    }
    
    if ($have_big_float) {
        # print STDERR "# have big float\n";
        $num_tests += 1;
    }
    else {
        $num_tests += 1;
    }
    
    plan tests => $num_tests;

    my $str = '{"stuff":42949672954294967295}';
    my $data = JSON::DWIW::deserialize($str);
    ok($data->{stuff} =~ /\A\+?42949672954294967295\Z/);
    
    if ($have_big_int) {
        my $num_str = '115792089237316195423570985008687907853269984665640564039457584007913129639936';
        # my $big_int = Math::BigInt->new($num_str);
        $str = qq{{"stuff":$num_str}};
        $data = JSON::DWIW::deserialize($str);
        ok($data->{stuff} =~ /\A\+?$num_str\Z/);
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

