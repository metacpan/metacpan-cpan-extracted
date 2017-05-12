#!/usr/bin/perl

use strict;
use warnings;
no  warnings 'syntax';

use constant NR_OF_CHARS => 256;
use constant MAX_CHAR    => NR_OF_CHARS - 1;

use Test::More 0.88;
use Digest::Trivial;

our $r = eval "require Test::NoWarnings; 1";

#
# Double letters cancel out each other
#
foreach my $i (0 .. MAX_CHAR) {
    my $str  = chr $i;
       $str x= 2;
    is trivial_x $str, 0, "Double chr ($i) is cancelled in trivial_x";
}

Test::NoWarnings::had_no_warnings () if $r;

done_testing;
