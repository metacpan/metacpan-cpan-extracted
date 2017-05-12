use strict;
use warnings;
use Games::Dice::Roll20;
use Test::More;

my $dice = Games::Dice::Roll20->new();

sub roll {
    my ( $spec, $result, $desc ) = @_;
    is( $dice->roll($spec), $result, $desc || "$spec -> $result" );
}

# math expressions

roll 'abs(-2)',     2;
roll 'round(2.4)',  2;
roll 'round(2.5)',  3;
roll 'round(-2.5)', -2;
roll '0',           0;
roll '5+3',         8;
roll '(2+2)',       4;
roll '(2+2)*2',     8;
roll '2*2+2',       6;
roll '((2+2)*2)+2', 10;

$dice->mock( [ 5, 5, 1, 1 ] );
roll 'ceil(d6/2)',  3;
roll 'floor(d6/2)', 2;

## limit rerolls
roll '2d6r<2', 2;

$dice->mock( [ 1, 1, 1, 6, 6 ] );
roll '2d6ro<2', 7;

$dice->mock( [6] );
roll '8d6r2r6r4', 8;

$dice->mock( [ 10, 1, 10, ] );
roll '2d10r<2', 20;
$dice->mock( [ 10, 1, 10, ] );
roll '2d10r', 20;
$dice->mock( [ 10, 1, 10, ] );
roll '2d10r=10', 2;

$dice->mock( [ 50, 50, 50, 50 ] );
roll '8d100k4', 200;
$dice->mock( [ 50, 50, 50, 50 ] );
roll '8d100kl4', 4;
$dice->mock( [ 50, 50, 50, 50 ] );
roll '8d100dh4', 4;
$dice->mock( [ 50, 50, 50, 50 ] );
roll '8d100d4', 200;

roll '4d6dl2', 2;
roll '4d6kh2', 2;

$dice->mock( [6] );
roll '4d(3+3)', 9;
$dice->mock( [6] );
roll '(2+2)d6', 9;
$dice->mock( [6] );
roll '5d6!p', 10;
$dice->mock( [6] );
roll '5d6!p>5', 10;
$dice->mock( [6] );
roll '3d6>3f1', -1;
$dice->mock( [6] );
roll '10d6<4f>5', 8;
$dice->mock( [6] );
roll '10d6<4', 9;
$dice->mock( [ 6, 6 ] );
roll '10d6>4', 2;
$dice->mock( [6] );
roll '10d6=6', 1;
$dice->mock( [6] );
roll '5d6!!', 11;
$dice->mock( [5] );
roll '5d6!!5', 10;
$dice->mock( [6] );
roll '3d6!>5', 9;
$dice->mock( [ 6, 6 ] );
roll '2d6!',  14;
roll '2d6',   2;
roll 'd6+1',  2;
roll 'd6',    1;
roll '12d12', 12;
$dice->mock( [ -1, -1 ] );
roll '2dF',      -2;
roll '0d1',      0;
roll 'd1',       1;
roll 'd6+d6',    2;
roll 'd6+d6+d6', 3;

roll '2/d1', 2;
roll '2*d1', 2;
roll '2-d1', 1;

TODO: {
    local $TODO = 'Not implemented yet';
    roll '[[5+3]]', 8;
}

done_testing;
