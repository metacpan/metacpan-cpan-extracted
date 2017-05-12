#!/usr/bin/perl -w

use strict;
use Math::Units;

my($v_in, $v_out, $u_in, $u_out);

while (1) {
    print "enter value and unit: "; $v_in = <>;
    print "         output unit: "; $u_out = <>;

    if ($v_in !~ m|^\s*(\d+)\s+(.*)|) {
	print "** you must enter a value and a unit\n";
	next;
    }

    $v_in = $1;
    $u_in = $2;

    $v_out = Math::Units::convert($v_in, $u_in, $u_out);

    print "                    = $v_out $u_out\n";
}
