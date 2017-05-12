use strict;
use Test;
BEGIN { plan tests => 1 }
use Math::BigSimple qw(make_simple);

my $s = make_simple(10);
if($s && (int($s) == $s))
{
	ok(1);
}
else
{
	ok(0);
}
