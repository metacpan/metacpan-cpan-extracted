use Test::More tests => 6;
use File::Spec;
use lib File::Spec->catfile("..","lib");
use Math::MatrixReal qw/:all/;
use strict;
use warnings;

do 'funcs.pl';

my ($x,$y,$z) = (42, 42.0001,42.0000001);

ok ( similar($x,$y, 1e-2 ), 'similar' );
ok (! similar($x,$y, 1e-6 ), 'similar' );
ok (! similar($x,$y), 'similar' );

ok ( similar($y,$z, 1e-3 ), 'similar' );
ok (! similar($y,$z, 1e-8 ), 'similar' );
ok (! similar($y,$z), 'similar' );
