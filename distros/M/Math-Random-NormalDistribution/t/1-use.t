#!/usr/bin/perl -w

# ------------------------------------------------------------------------------
#
# ------------------------------------------------------------------------------

use strict;
use warnings;

use Test::More 0.88 tests => 4;
use Scalar::Util qw(looks_like_number);

use FindBin qw($Bin);
use lib ("$Bin/../lib");

BEGIN
{
    use_ok('Math::Random::NormalDistribution');
    isa_ok('Math::Random::NormalDistribution', 'Exporter');
}

&main();
# ------------------------------------------------------------------------------
sub main
{
    my $g = rand_nd_generator();
    isa_ok($g, 'CODE');
    my $v = $g->();
    ok(looks_like_number($v), 'Returns number');
}
# ------------------------------------------------------------------------------
1;
