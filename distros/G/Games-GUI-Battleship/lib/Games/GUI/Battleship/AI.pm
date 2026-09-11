package Games::GUI::Battleship::AI;

use v5.38;
use experimental 'signatures';
use feature 'try';
no warnings 'experimental::try';
use Carp              qw(croak);
use Logic::Relational ();
use Logic::Relational::Goal::Call;

sub new ( $class, %args ) {
    my $self = {
        name          => $args{name}       // 'AI',
        difficulty    => $args{difficulty} // 'normal',
        shots_history => {},
        stats         => { shots => 0, hits => 0, ships_sunk => 0 },
        program       => undef,
    };
    bless $self, $class;
    $self->init_program;
    return $self;
}

sub create ( $class, $difficulty = 'normal' ) {
    $difficulty = lc($difficulty);
    if ( $difficulty eq 'easy' ) {
        require Games::GUI::Battleship::AI::Naive;
        return Games::GUI::Battleship::AI::Naive->new;
    }
    elsif ( $difficulty eq 'hard' ) {
        require Games::GUI::Battleship::AI::Hard;
        return Games::GUI::Battleship::AI::Hard->new;
    }
    else {
        require Games::GUI::Battleship::AI::Parity;
        return Games::GUI::Battleship::AI::Parity->new;
    }
}

sub name ($self) {
    return $self->{name};
}

sub difficulty ($self) {
    return $self->{difficulty};
}

sub stats ($self) {
    return $self->{stats};
}

sub program ($self) {
    return $self->{program};
}

sub shots_history ($self) {
    return $self->{shots_history};
}

sub has_shot ( $self, $x, $y ) {
    return $self->{shots_history}{"$x,$y"} ? 1 : 0;
}

sub init_program ($self) {
    croak "Subclasses must implement init_program";
}

sub select_target ($self) {
    croak "Subclasses must implement select_target";
}

sub record_result ( $self, %args ) {
    my $x      = $args{x}      // croak 'x is required';
    my $y      = $args{y}      // croak 'y is required';
    my $result = $args{result} // croak 'result is required';
    my $ship   = $args{ship};

    $self->{shots_history}{"$x,$y"} = 1;
    $self->{stats}{shots}++;

    if ( $result eq 'hit' ) {
        $self->{stats}{hits}++;
        $self->{program}->fact( shot_hit => $x, $y );
    }
    elsif ( $result eq 'sunk' ) {
        $self->{stats}{hits}++;
        $self->{stats}{ships_sunk}++;

        if ($ship) {
            for my $coord ( $ship->coordinates ) {
                my ( $cx, $cy ) = ( $coord->[0], $coord->[1] );
                $self->{program}->retract( shot_hit => $cx, $cy );
                $self->{program}->fact( sunk_cell => $cx, $cy );
            }
        }
        else {
            $self->{program}->retract( shot_hit => $x, $y );
            $self->{program}->fact( sunk_cell => $x, $y );
        }
    }
    else {
        $self->{program}->fact( shot_miss => $x, $y );
    }

    return $self;
}

sub reset ($self) {
    $self->{shots_history} = {};
    $self->{stats}         = { shots => 0, hits => 0, ships_sunk => 0 };
    $self->init_program;
    return $self;
}

sub clone_program ( $self, $template ) {
    require Logic::Relational::Program;
    my $clone = Logic::Relational::Program->new;

    for my $key ( keys %{ $template->{predicates} } ) {
        $clone->{predicates}{$key} = [ @{ $template->{predicates}{$key} } ];
        $clone->{active_predicates}{$key} =
          [ @{ $template->{predicates}{$key} } ];
    }
    $clone->{generators} = { %{ $template->{generators} } };
    return $clone;
}

1;

