#!/usr/bin/env perl

use strict;
use warnings;
use Test::More tests => 25;

use_ok 'Math::Currency' or exit 1;

my $small = Math::Currency->new(10);
my $large = Math::Currency->new(100);

# ensure bcmp works the way documented in Math::BigFloat:
# $x->bcmp($y);           # compare numbers (undef, < 0, == 0, > 0)
cmp_ok $small->bcmp($large), '==', -1;
cmp_ok $small->bcmp($small), '==', 0;
cmp_ok $large->bcmp($small), '==', 1;

cmp_ok $small->bcmp(100), '==', -1;
cmp_ok $small->bcmp(10), '==', 0;
cmp_ok $large->bcmp(10), '==', 1;

# legacy Math::BigInt (1.99) <=> overload syntax
cmp_ok ref($small)->bcmp($small, $large), '==', -1;
cmp_ok ref($small)->bcmp($small, $small), '==', 0;
cmp_ok ref($large)->bcmp($large, $small), '==', 1;
cmp_ok ref($small)->bcmp($small, 100), '==', -1;
cmp_ok ref($small)->bcmp($small, 10), '==', 0;
cmp_ok ref($large)->bcmp($large, 10), '==', 1;

# float tests.
$small = Math::Currency->new(10.01);
$large = Math::Currency->new(100.01);

cmp_ok $small->bcmp($large), '==', -1;
cmp_ok $small->bcmp($small), '==', 0;
cmp_ok $large->bcmp($small), '==', 1;

cmp_ok $small->bcmp(100.01), '==', -1;
cmp_ok $small->bcmp(10.01), '==', 0;
cmp_ok $large->bcmp(10.01), '==', 1;

# legacy Math::BigInt (1.99) <=> overload syntax
cmp_ok ref($small)->bcmp($small, $large), '==', -1;
cmp_ok ref($small)->bcmp($small, $small), '==', 0;
cmp_ok ref($large)->bcmp($large, $small), '==', 1;
cmp_ok ref($small)->bcmp($small, 100.01), '==', -1;
cmp_ok ref($small)->bcmp($small, 10.01), '==', 0;
cmp_ok ref($large)->bcmp($large, 10.01), '==', 1;
