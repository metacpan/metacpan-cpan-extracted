use strict;
use Test;
BEGIN { plan tests => 1 }
use Math::BigSimple;

my $g = Math::BigSimple->new(Length => 10, Checks => 3);
my $s = $g->make();
if($s && (int($s) == $s))
{
	ok(1);
}
else
{
	ok(0);
}