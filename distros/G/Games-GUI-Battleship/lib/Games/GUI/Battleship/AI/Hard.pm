package Games::GUI::Battleship::AI::Hard;

use v5.38;
use experimental 'signatures';
use feature 'try';
no warnings 'experimental::try';
use parent 'Games::GUI::Battleship::AI';

use Logic::Relational ();
use Logic::Relational::Syntax;
use Logic::Relational::Goal::Call;
use List::Util qw(min max);

our $CURRENT_SHOTS = {};

logic HardAITemplate {
    fact shot_hit( 0, 0 );
    fact shot_miss( 0, 0 );
    fact sunk_cell( 0, 0 );
    fact ship_alive( 'Carrier',    5 );
    fact ship_alive( 'Battleship', 4 );
    fact ship_alive( 'Cruiser',    3 );
    fact ship_alive( 'Submarine',  3 );
    fact ship_alive( 'Destroyer',  2 );

    rule cell_unshot( $x, $y ) {
        guard(
            [ $x, $y ],
            sub ( $vx, $vy ) {
                return 0 if $vx < 1 || $vx > 10 || $vy < 1 || $vy > 10;
                return $Games::GUI::Battleship::AI::Hard::CURRENT_SHOTS->{
                    "$vx,$vy"} ? 0 : 1;
            }
        );
    }
}

sub new ( $class, %args ) {
    $args{name}       = 'ProbabilityAI';
    $args{difficulty} = 'hard';
    my $self = $class->SUPER::new(%args);
    $self->{surviving_ships} = {
        Carrier    => 5,
        Battleship => 4,
        Cruiser    => 3,
        Submarine  => 3,
        Destroyer  => 2,
    };
    $self->{active_hits} = {};
    return $self;
}

sub init_program ($self) {
    $self->{program}         = $self->clone_program($HardAITemplate::PROGRAM);
    $self->{surviving_ships} = {
        Carrier    => 5,
        Battleship => 4,
        Cruiser    => 3,
        Submarine  => 3,
        Destroyer  => 2,
    };
    $self->{active_hits} = {};
    return $self->{program};
}

sub record_result ( $self, %args ) {
    my $x      = $args{x};
    my $y      = $args{y};
    my $result = $args{result};
    my $ship   = $args{ship};

    $self->SUPER::record_result(%args);

    if ( $result eq 'hit' ) {
        $self->{active_hits}{"$x,$y"} = 1;
    }
    elsif ( $result eq 'sunk' ) {
        if ($ship) {
            my $type = $ship->type;
            if ( exists $self->{surviving_ships}{$type} ) {
                my $sz = delete $self->{surviving_ships}{$type};
                $self->{program}->retract( ship_alive => $type, $sz );
            }
            for my $coord ( $ship->coordinates ) {
                delete $self->{active_hits}{"$coord->[0],$coord->[1]"};
            }
        }
        else {
            delete $self->{active_hits}{"$x,$y"};
            my ($smallest) = sort {
                $self->{surviving_ships}{$a} <=> $self->{surviving_ships}{$b}
            } keys %{ $self->{surviving_ships} };
            if ($smallest) {
                my $sz = delete $self->{surviving_ships}{$smallest};
                $self->{program}->retract( ship_alive => $smallest, $sz );
            }
        }
    }

    return $self;
}

sub select_target ($self) {
    local $CURRENT_SHOTS = $self->{shots_history};

    my %surviving = %{ $self->{surviving_ships} };
    %surviving = ( Destroyer => 2 ) unless %surviving;
    my $min_len = min( values %surviving ) // 2;

    my @hits     = keys %{ $self->{active_hits} };
    my $has_hits = scalar @hits > 0 ? 1 : 0;

    my %weights;

    for my $type ( sort keys %surviving ) {
        my $len = $surviving{$type};

        # Horizontal placements
        for my $y ( 1 .. 10 ) {
            for my $x ( 1 .. 11 - $len ) {
                my $valid     = 1;
                my $hit_count = 0;
                my @coords;

                for my $i ( 0 .. $len - 1 ) {
                    my $cx  = $x + $i;
                    my $key = "$cx,$y";
                    if ( $self->{shots_history}{$key}
                        && !$self->{active_hits}{$key} )
                    {
                        $valid = 0;
                        last;
                    }
                    $hit_count++ if $self->{active_hits}{$key};
                    push @coords, $key;
                }
                next unless $valid;

                if ($has_hits) {
                    next if $hit_count == 0;
                    my $w = 10**$hit_count;
                    for my $k (@coords) {
                        $weights{$k} += $w unless $self->{shots_history}{$k};
                    }
                }
                else {
                    for my $k (@coords) {
                        next if $self->{shots_history}{$k};
                        my ( $cx, $cy ) = split /,/x, $k;
                        my $bonus = ( ( $cx + $cy ) % $min_len == 0 ) ? 2 : 1;
                        $weights{$k} += $bonus;
                    }
                }
            }
        }

        # Vertical placements
        for my $x ( 1 .. 10 ) {
            for my $y ( 1 .. 11 - $len ) {
                my $valid     = 1;
                my $hit_count = 0;
                my @coords;

                for my $i ( 0 .. $len - 1 ) {
                    my $cy  = $y + $i;
                    my $key = "$x,$cy";
                    if ( $self->{shots_history}{$key}
                        && !$self->{active_hits}{$key} )
                    {
                        $valid = 0;
                        last;
                    }
                    $hit_count++ if $self->{active_hits}{$key};
                    push @coords, $key;
                }
                next unless $valid;

                if ($has_hits) {
                    next if $hit_count == 0;
                    my $w = 10**$hit_count;
                    for my $k (@coords) {
                        $weights{$k} += $w unless $self->{shots_history}{$k};
                    }
                }
                else {
                    for my $k (@coords) {
                        next if $self->{shots_history}{$k};
                        my ( $cx, $cy ) = split /,/x, $k;
                        my $bonus = ( ( $cx + $cy ) % $min_len == 0 ) ? 2 : 1;
                        $weights{$k} += $bonus;
                    }
                }
            }
        }
    }

    unless (%weights) {

        # Fallback to any unshot cell
        for my $y ( 1 .. 10 ) {
            for my $x ( 1 .. 10 ) {
                return ( $x, $y, 'Fallback Grid Search' )
                  unless $self->{shots_history}{"$x,$y"};
            }
        }
        return;
    }

    my $max_w = -1;
    for my $k ( keys %weights ) {
        $max_w = $weights{$k} if $weights{$k} > $max_w;
    }

    my @top    = grep { $weights{$_} == $max_w } keys %weights;
    my $chosen = $top[ int rand @top ];
    my ( $tx, $ty ) = split /,/x, $chosen;

    my $mode = 'Probability Density Hunt';
    if ($has_hits) {
        $mode =
          ( scalar @hits >= 2 && $max_w >= 200 )
          ? 'Target Heatmap (Line Extension)'
          : 'Target Heatmap (Orthogonal Focus)';
    }

    return ( $tx, $ty, $mode );
}

1;

