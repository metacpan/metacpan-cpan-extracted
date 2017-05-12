#!/usr/bin/perl

use strict;
use warnings;

use lib './t/lib';
use Utils qw(is_between);

use Test::More tests => 1;
use Math::Cephes qw(:cmplx);
use Math::Cephes::Complex;

######################### End of black magic.

{
    my $z = new_cmplx(2,0);

    my $w = new_cmplx();

    cexp($z, $w);

    my $want = exp(2);
    # TEST
    is_between ($w->{r}, $want - 1e-5, $want + 1e-5, "Testing new_complx");
}
