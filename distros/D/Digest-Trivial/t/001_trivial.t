#!/usr/bin/perl

use strict;
use warnings;
no  warnings 'syntax';

use constant NR_OF_CHARS => 256;
use constant MAX_CHAR    => NR_OF_CHARS - 1;

use Test::More 0.88;

our $r = eval "require Test::NoWarnings; 1";

BEGIN {
    use_ok 'Digest::Trivial' or
        BAIL_OUT ("Loading of 'Digest::Trivial' failed");
};

#
# Single character strings.
#
foreach my $i (0 .. MAX_CHAR) {
    my $str = chr $i;
    is trivial_x $str, $i, "trivial_x (chr $i) == $i";
}

foreach my $i (0 .. MAX_CHAR) {
    my $str = chr $i;
    is trivial_s $str, $i, "trivial_s (chr $i) == $i";
}

Test::NoWarnings::had_no_warnings () if $r;

done_testing;
