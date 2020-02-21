package main;

use 5.008001;

use strict;
use warnings;

use Test2::V0 -target => 'Game::Life::Faster';

my $life = CLASS->new( 10 );

is $life, {
    breed	=> [ undef, undef, undef, 1 ],
    live	=> [ undef, undef, 1, 1 ],
    max_x	=> 9,
    max_y	=> 9,
    size_x	=> 10,
    size_y	=> 10,
}, 'Initialized correctly'
    or diag explain $life;

is [ $life->get_breeding_rules() ],
[ 3 ], 'get_breeding_rules()';

is [ $life->get_living_rules() ],
[ 2, 3 ], 'get_living_rules()';

ok $life->toggle_point( 0, 0 ), 'toggle_point turned point on';

is $life->{grid}, [
    [ [ 1, 0 ], [ undef, 1 ] ],
    [ [ undef, 1 ], [ undef, 1 ], ],
], 'toggle_point left grid in correct state';

ok ! $life->toggle_point( 0, 0 ), 'toggle_point again turned point off';

is $life->{grid}, [
    [ [ 0, 0 ], [ undef, 0 ] ],
    [ [ undef, 0 ], [ undef, 0 ], ],
], 'toggle_point again left grid in correct state';

ok $life->set_point( 0, 1 ), 'set_point turned point on';

is $life->{grid}, [
    [ [ 0, 1 ], [ 1, 0 ], [ undef, 1 ] ],
    [ [ undef, 1 ], [ undef, 1 ], [ undef, 1 ] ],
], 'set_point left grid in correct state';

ok $life->set_point( 0, 1 ), 'set_point again left point on';

is $life->{grid}, [
    [ [ 0, 1 ], [ 1, 0 ], [ undef, 1 ] ],
    [ [ undef, 1 ], [ undef, 1 ], [ undef, 1 ] ],
], 'set_point again left grid unchanged';

ok ! $life->unset_point( 0, 0 ), 'unset_point on already-clear point';

is $life->{grid}, [
    [ [ 0, 1 ], [ 1, 0 ], [ undef, 1 ] ],
    [ [ undef, 1 ], [ undef, 1 ], [ undef, 1 ] ],
], 'unset_point on already-clear point left grid unchanged';

ok ! $life->unset_point( 0, 1 ), 'unset_point on set point';

is $life->{grid}, [
    [ [ 0, 0 ], [ 0, 0 ], [ undef, 0 ] ],
    [ [ undef, 0 ], [ undef, 0 ], [ undef, 0 ] ],
], 'unset_point on set point cleared it';


$life->place_text_points( 0, 0, 'X', <<'EOD' );
.X.
..X
XXX
EOD

cmp_ok $life->process( 10 ), '==', 4,
    'Last iteration of glider changed 4 cells';

is $life->get_grid(), [
    [ ( 0 ) x 10 ],
    [ ( 0 ) x 10 ],
    [ ( 0 ) x 10 ],
    [ 0, 0, 0, 0, 1, 0, 0, 0, 0, 0 ],
    [ 0, 0, 1, 0, 1, 0, 0, 0, 0, 0 ],
    [ 0, 0, 0, 1, 1, 0, 0, 0, 0, 0 ],
    [ ( 0 ) x 10 ],
    [ ( 0 ) x 10 ],
    [ ( 0 ) x 10 ],
    [ ( 0 ) x 10 ],
], 'Grid after running glider 10 steps';

is scalar $life->get_text_grid(), <<'EOD',
..........
..........
..........
....X.....
..X.X.....
...XX.....
..........
..........
..........
..........
EOD
    'Text grid after running glider 10 steps';

$life->place_points( 1, 0, [ [ 1, 1, 1 ] ] );
$life->place_text_points( 1, 7, 'X', 'XX', 'XX' );
is scalar $life->get_text_grid(), <<'EOD',
..........
XXX....XX.
.......XX.
....X.....
..X.X.....
...XX.....
..........
..........
..........
..........
EOD
    'Added blinker and block to grid';

$life->process();

is scalar $life->get_text_grid(), <<'EOD',
.X........
.X.....XX.
.X.....XX.
...X......
....XX....
...XX.....
..........
..........
..........
..........
EOD
    'Grid after another step';

$life->clear();

is scalar $life->get_text_grid(), <<'EOD', 'Clear grid';
..........
..........
..........
..........
..........
..........
..........
..........
..........
..........
EOD

$life->place_text_points( 1, 1, 'X', <<'EOD' );
XX
XX
EOD

$life->process( 10 );

is scalar $life->get_text_grid(), <<'EOD', 'Lone block after 10 steps';
..........
.XX.......
.XX.......
..........
..........
..........
..........
..........
..........
..........
EOD

$life = $life->new( [ 10, 5 ] );
is scalar $life->get_text_grid(), <<'EOD', '10 x 5 grid';
..........
..........
..........
..........
..........
EOD


done_testing;

1;

# ex: set textwidth=72 :
