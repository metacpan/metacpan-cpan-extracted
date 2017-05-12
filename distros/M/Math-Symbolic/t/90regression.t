use strict;
use warnings;
use Test::More tests => 1;

use Math::Symbolic qw/parse_from_string/;

my $f = parse_from_string('x + (-5)*y');
my $fs = $f->simplify;

#diag("Before simplification: $f");
#diag("After simplification:  $fs");

ok($f->test_num_equiv($fs));

