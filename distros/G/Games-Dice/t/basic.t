use strict;
use warnings;
use Test::More;
use Test::MockRandom 'Games::Dice';
use Games::Dice 'roll';

srand( 0.5, oneish() );

is( roll('6'),     6, 'roll 6 - constant integer' );
is( roll('d6'),    4, 'roll d6 - basic roll' );
is( roll('2d6'),   7, 'roll 2d6 - basic roll with multiplier' );

srand( (0.5) x 10 );

is( roll('2d6-2'),  6, 'roll 2d6-2 - basic roll with multiplier and - sign' );
is( roll('2d6+2'), 10, 'roll 2d6+2 - basic roll with multiplier and + sign' );
is( roll('2d6*2'), 16, 'roll 2d6*2 - basic roll with multiplier and * sign' );
is( roll('2d6x2'), 16, 'roll 2d6x2 - basic roll with multiplier and x sign' );
is( roll('2d6/2'),  4, 'roll 2d6/2 - basic roll with multiplier and / sign' );

srand( oneish(), oneish(), oneish, oneish );

is( roll('4dF'), 4,  'roll 4dF - fudge rolls with only +' );
is( roll('4dF'), -4, 'roll 4dF - fudge rolls with only -' );

srand(0.5);
is( roll('d%'), 51, 'roll d% - % as alias for 100' );

srand( 0.5, 0.1, 0.8 );
is( roll('5d6b3'), 10, 'roll 5d6b3 - best 3 out of 5' );

srand( 0.5, 0.1, 0.8 );
is( roll('5d6b6'), 12, 'roll 5d6b6 - best 6 out of 5' );

done_testing();
