
use strict;
use warnings;

use Test::More tests => 3;
use Math::Goedel;

$@ = undef;
eval "goedel(9)";
ok($@);
$@ = undef;
eval "enc(9)";
ok($@);
$@ = undef;
eval "use Math::Goedel qw/enc/;";
ok($@);


