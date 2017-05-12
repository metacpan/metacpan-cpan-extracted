#!perl -T
use 5.010001;
use strict;
use warnings;
use Test::More tests => 2;

use Math::Utils qw(:utility);

my @rem;
my $rstr;

@rem = moduli(29, 3);
$rstr = join("", @rem);
ok($rstr eq "2001", "moduli(29, 3) returned $rstr");

@rem = moduli(4095, 2);
$rstr = join("", @rem);
ok($rstr eq "111111111111", "moduli(4095, 2) returned $rstr");

#@rem = moduli(29, [4, 9]);
#$rstr = join("", @rem);
#ok($rstr eq "17", "moduli(29, [4, 9]) returned $rstr");

#@rem = moduli(803151, [4, 5, 8, 9]);
#$rstr = join(", ", @rem);
#ok($rstr eq "3, 2, 5, 6", "moduli(803151, [4, 5, 8, 9]) returned $rstr");

