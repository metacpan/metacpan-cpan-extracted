#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 1;

use Math::Cephes qw(:cmplx);

my $x = new_cmplx(3, 5);
my $y = new_cmplx(2, 3);
my $z = new_cmplx();

cdiv( $x, $y, $z );

# TEST
like(
    "$z->{r},$z->{i}",
    qr/\A0\.617.*?,-0\.0294/,
    "use Math::Cephes qw(:cmplx) works without explicit use Math::Cephes::Complex",
);
