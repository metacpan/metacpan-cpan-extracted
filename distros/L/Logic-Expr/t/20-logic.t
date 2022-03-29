#!perl
#
# is the logic at least not terrible? also some code coverage

use Test2::V0;

plan(21);

use Logic::Expr::Parser;
my $le = Logic::Expr::Parser->new;
my $pe;

sub test_codex
{
    my $fn = shift;
    my @ret;
    for my $x ( 1, 0 ) {
        for my $y ( 1, 0 ) {
            push @ret, $fn->( X => $x, Y => $y );
        }
    }
    is( \@_, \@ret );
}

$pe = $le->from_string('X|Y');
is( $pe->solutions,
    [   [ [ 1, 1 ], 1, ],    # T
        [ [ 1, 0 ], 1, ],    # T
        [ [ 0, 1 ], 1, ],    # T
        [ [ 0, 0 ], 0 ]      # F
    ]
);
test_codex( $pe->codex, 1, 1, 1, 0 );

is( $pe->solutions(1), [ 1, 1, 1, 0 ] );

$pe = $le->from_string('X&Y');
is( $pe->solutions,
    [   [ [ 1, 1 ], 1, ],    # T
        [ [ 1, 0 ], 0, ],    # F
        [ [ 0, 1 ], 0, ],    # F
        [ [ 0, 0 ], 0 ]      # F
    ]
);
test_codex( $pe->codex, 1, 0, 0, 0 );

$pe = $le->from_string('X->Y');
is( $pe->solutions,
    [   [ [ 1, 1 ], 1, ],    # T
        [ [ 1, 0 ], 0, ],    # F
        [ [ 0, 1 ], 1, ],    # T
        [ [ 0, 0 ], 1 ]      # T
    ]
);
test_codex( $pe->codex, 1, 0, 1, 1 );

$pe = $le->from_string('X==Y');
is( $pe->solutions,
    [   [ [ 1, 1 ], 1, ],    # T
        [ [ 1, 0 ], 0, ],    # F
        [ [ 0, 1 ], 0, ],    # F
        [ [ 0, 0 ], 1 ]      # T
    ]
);
test_codex( $pe->codex, 1, 0, 0, 1 );

$pe = $le->from_string('~(X->Y)');
is( $pe->solutions,
    [   [ [ 1, 1 ], 0, ],    # F
        [ [ 1, 0 ], 1, ],    # T
        [ [ 0, 1 ], 0, ],    # F
        [ [ 0, 0 ], 0 ]      # F
    ]
);
test_codex( $pe->codex, 0, 1, 0, 0 );

# was bools changed by solutions? (shouldn't be)
is( \@Logic::Expr::bools, [ 1, 1 ] );

$Logic::Expr::bools[1] = 0;
is( $pe->solve, 1 );    # [1,0] case from prior solutions call
# solve should not be fiddling with bools
is( \@Logic::Expr::bools, [ 1, 0 ] );

$Logic::Expr::bools[0] = 0;
is( $pe->solve, 0 );

$pe->{expr}->[0] = -1;    # FAKE_OP
like( dies { $pe->solve }, qr/unknown op/ );
like( dies { $pe->codex }, qr/unknown op/ );

$pe->{expr} = {};
like( dies { $pe->solve }, qr/unexpected reference type/ );
like( dies { $pe->codex }, qr/unexpected reference type/ );

# hit a rare branch that is mostly not reached due to code within _walk
# that avoids needless extra _walk calls
$pe = $le->from_string('X');
my $fn = $pe->codex;
is( $fn->( X => 0 ), 0 );
is( $fn->( X => 1 ), 1 );
