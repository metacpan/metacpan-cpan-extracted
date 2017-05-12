#!/usr/bin/perl

use strict;
use warnings;
no  warnings 'syntax';

use constant NR_OF_CHARS => 256;
use constant MAX_CHAR    => NR_OF_CHARS - 1;

use constant NR_OF_TESTS => 1_024;

use Test::More 0.88;
use Digest::Trivial;

our $r = eval "require Test::NoWarnings; 1";


foreach (1 .. NR_OF_TESTS) {
    my $str = "";
    my $xor =  0;
    my $sum =  0;

    while (my $ch = int rand MAX_CHAR) {
        $str .= chr $ch;
        $xor ^=     $ch;
        $sum +=     $ch;
    }

    is trivial_x $str, $xor,               "trivial_x";
    is trivial_s $str, $sum % NR_OF_CHARS, "trivial_s";
}


Test::NoWarnings::had_no_warnings () if $r;
 
done_testing;
