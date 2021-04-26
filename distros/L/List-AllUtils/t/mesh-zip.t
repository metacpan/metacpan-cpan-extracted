use strict;
use warnings;

use Test::More;

use List::Util 1.56 ();
use List::AllUtils qw( mesh zip );

my @x = ( 1, 3 );
my @y = ( 2, 4 );

is_deeply(
    [ mesh @x, @y ], [ 1, 2, 3, 4 ],
    'mesh accepts arrays, not array refs'
);
is_deeply(
    [ zip @x, @y ], [ 1, 2, 3, 4 ],
    'zip accepts arrays, not array refs'
);

done_testing();

