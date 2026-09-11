package Games::GUI::Battleship::AI::Parity;

use v5.38;
use experimental 'signatures';
use feature 'try';
no warnings 'experimental::try';
use parent 'Games::GUI::Battleship::AI';

use Logic::Relational ();
use Logic::Relational::Syntax;
use Logic::Relational::Goal::Call;

our $CURRENT_SHOTS = {};

logic ParityAITemplate {
    fact shot_hit( 0, 0 );
    fact shot_miss( 0, 0 );
    fact sunk_cell( 0, 0 );

    rule cell_unshot( $x, $y ) {
        guard(
            [ $x, $y ],
            sub ( $vx, $vy ) {
                return 0 if $vx < 1 || $vx > 10 || $vy < 1 || $vy > 10;
                return $Games::GUI::Battleship::AI::Parity::CURRENT_SHOTS->{
                    "$vx,$vy"} ? 0 : 1;
            }
        );
    }

    rule cell_valid( $x, $y ) {
        between( 1, 10, $x );
        between( 1, 10, $y );
        cell_unshot( $x, $y );
    }

    rule adjacent( $x1, $y1, $x2, $y2 ) {
        is_goal( $x2, [$x1], sub ($v) { $v + 1 } );
        unify( $y1, $y2 );
    }
    rule adjacent( $x1, $y1, $x2, $y2 ) {
        is_goal( $x2, [$x1], sub ($v) { $v - 1 } );
        unify( $y1, $y2 );
    }
    rule adjacent( $x1, $y1, $x2, $y2 ) {
        is_goal( $y2, [$y1], sub ($v) { $v + 1 } );
        unify( $x1, $x2 );
    }
    rule adjacent( $x1, $y1, $x2, $y2 ) {
        is_goal( $y2, [$y1], sub ($v) { $v - 1 } );
        unify( $x1, $x2 );
    }

    # Priority 1: Line Extension (Horizontal)
    rule select_target( $x, $y, $mode ) {
        fresh my ( $x1, $x2, $yh );
        shot_hit( $x1, $yh );
        is_goal( $x2, [$x1], sub ($v) { $v + 1 } );
        shot_hit( $x2, $yh );
        unify( $y, $yh );
        line_endpoint_h( $x1, $x2, $x );
        cell_valid( $x, $y );
        unify( $mode, 'Line Extension (Horizontal)' );
    }
    rule line_endpoint_h( $x1, $x2, $x ) {
        is_goal( $x, [$x2], sub ($v) { $v + 1 } );
    }
    rule line_endpoint_h( $x1, $x2, $x ) {
        is_goal( $x, [$x1], sub ($v) { $v - 1 } );
    }

    # Priority 1: Line Extension (Vertical)
    rule select_target( $x, $y, $mode ) {
        fresh my ( $y1, $y2, $xh );
        shot_hit( $xh, $y1 );
        is_goal( $y2, [$y1], sub ($v) { $v + 1 } );
        shot_hit( $xh, $y2 );
        unify( $x, $xh );
        line_endpoint_v( $y1, $y2, $y );
        cell_valid( $x, $y );
        unify( $mode, 'Line Extension (Vertical)' );
    }
    rule line_endpoint_v( $y1, $y2, $y ) {
        is_goal( $y, [$y2], sub ($v) { $v + 1 } );
    }
    rule line_endpoint_v( $y1, $y2, $y ) {
        is_goal( $y, [$y1], sub ($v) { $v - 1 } );
    }

    # Priority 2: Orthogonal Neighbor Probe
    rule select_target( $x, $y, $mode ) {
        fresh my ( $hx, $hy );
        shot_hit( $hx, $hy );
        adjacent( $hx, $hy, $x, $y );
        cell_valid( $x, $y );
        unify( $mode, 'Orthogonal Target Probe' );
    }

    # Priority 3: Checkerboard Parity Hunt
    rule select_target( $x, $y, $mode ) {
        between( 1, 10, $x );
        between( 1, 10, $y );
        cell_unshot( $x, $y );
        guard( [ $x, $y ],
            sub ( $vx, $vy ) { return ( $vx + $vy ) % 2 == 0; } );
        unify( $mode, 'Checkerboard Parity Hunt' );
    }

    # Priority 4: Fallback Search
    rule select_target( $x, $y, $mode ) {
        between( 1, 10, $x );
        between( 1, 10, $y );
        cell_unshot( $x, $y );
        unify( $mode, 'Fallback Grid Search' );
    }
}

sub new ( $class, %args ) {
    $args{name}       = 'ParityAI';
    $args{difficulty} = 'normal';
    return $class->SUPER::new(%args);
}

sub init_program ($self) {
    $self->{program} = $self->clone_program($ParityAITemplate::PROGRAM);
    return $self->{program};
}

sub _mode_tier ($mode) {
    return 1 if index( $mode, 'Line Extension' ) == 0;
    return 2 if $mode eq 'Orthogonal Target Probe';
    return 3 if $mode eq 'Checkerboard Parity Hunt';
    return 4;
}

sub select_target ($self) {
    local $CURRENT_SHOTS = $self->{shots_history};

    my $tx = Logic::Relational::variable('x');
    my $ty = Logic::Relational::variable('y');
    my $tm = Logic::Relational::variable('mode');

    my $q = $self->{program}->query(
        Logic::Relational::Goal::Call->new(
            'select_target', [ $tx, $ty, $tm ]
        )
    );

    my $first_sol   = $q->next // return;
    my $target_tier = _mode_tier( $first_sol->value($tm) );
    my @candidates  = ($first_sol);

    while ( my $sol = $q->next ) {
        if ( _mode_tier( $sol->value($tm) ) == $target_tier ) {
            push @candidates, $sol;
        }
        else {
            last;
        }
    }

    my $chosen = $candidates[ int rand @candidates ];
    return ( $chosen->value($tx), $chosen->value($ty), $chosen->value($tm) );
}

1;

