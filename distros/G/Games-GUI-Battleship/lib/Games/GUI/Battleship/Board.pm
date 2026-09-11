package Games::GUI::Battleship::Board;

use v5.38;
use experimental 'signatures';
use feature 'try';
no warnings 'experimental::try';
use Carp qw(croak);
use Games::GUI::Battleship::Ship;

sub new ( $class, %args ) {
    my $size = $args{size} // 10;

    my $self = {
        size  => int($size),
        ships => [],
        grid  => {},
        shots => {},
    };

    return bless $self, $class;
}

sub size ($self) {
    return $self->{size};
}

sub ships ($self) {
    return @{ $self->{ships} };
}

sub ship_count ($self) {
    return scalar @{ $self->{ships} };
}

sub ship_named ( $self, $type ) {
    for my $ship ( @{ $self->{ships} } ) {
        return $ship if $ship->type eq $type;
    }
    return undef;
}

sub can_place_ship ( $self, $ship ) {
    return $self->can_place( $ship->type, $ship->x, $ship->y, $ship->dir,
        $ship );
}

sub can_place ( $self, $type, $x, $y, $dir, $ignore_ship = undef ) {
    my $len = $Games::GUI::Battleship::Ship::SHIP_SIZES{$type}
      // croak "Unknown ship type: $type";
    $dir = uc($dir);

    my $size = $self->{size};

    for my $i ( 0 .. $len - 1 ) {
        my $cx = ( $dir eq 'H' ) ? $x + $i : $x;
        my $cy = ( $dir eq 'V' ) ? $y + $i : $y;

        # Bounds check (1-indexed)
        return 0 if $cx < 1 || $cx > $size || $cy < 1 || $cy > $size;

        # Collision check
        my $existing = $self->ship_at( $cx, $cy );
        if ($existing) {
            if ( !defined $ignore_ship
                || $existing->type ne $ignore_ship->type )
            {
                return 0;
            }
        }
    }

    return 1;
}

sub place_ship ( $self, $ship ) {
    if ( !$self->can_place_ship($ship) ) {
        croak "Cannot place ship "
          . $ship->type . " at ("
          . $ship->x . ","
          . $ship->y . ") "
          . $ship->dir;
    }

    # Remove any existing ship of the same type first
    $self->remove_ship( $ship->type );

    push @{ $self->{ships} }, $ship;
    for my $coord ( $ship->coordinates ) {
        $self->{grid}{"$coord->[0],$coord->[1]"} = $ship;
    }

    return $ship;
}

sub remove_ship ( $self, $type ) {
    my $removed;
    my @kept;
    for my $ship ( @{ $self->{ships} } ) {
        if ( $ship->type eq $type ) {
            $removed = $ship;
            for my $coord ( $ship->coordinates ) {
                delete $self->{grid}{"$coord->[0],$coord->[1]"};
            }
        }
        else {
            push @kept, $ship;
        }
    }
    $self->{ships} = \@kept;
    return $removed;
}

sub clear_ships ($self) {
    $self->{ships} = [];
    $self->{grid}  = {};
    return $self;
}

sub place_random_fleet ($self) {
    $self->clear_ships;
    my $size = $self->{size};

    for my $type (@Games::GUI::Battleship::Ship::FLEET_ORDER) {
        my $placed   = 0;
        my $attempts = 0;

        while ( !$placed && $attempts < 1000 ) {
            $attempts++;
            my $dir = int( rand(2) ) ? 'H' : 'V';
            my $x   = 1 + int( rand($size) );
            my $y   = 1 + int( rand($size) );

            if ( $self->can_place( $type, $x, $y, $dir ) ) {
                my $ship = Games::GUI::Battleship::Ship->new(
                    type => $type,
                    x    => $x,
                    y    => $y,
                    dir  => $dir,
                );
                $self->place_ship($ship);
                $placed = 1;
            }
        }

        if ( !$placed ) {

            # In the rare event of deadlock, restart placement
            return $self->place_random_fleet;
        }
    }

    return 1;
}

sub has_shot ( $self, $x, $y ) {
    return exists $self->{shots}{"$x,$y"} ? 1 : 0;
}

sub shot_at ( $self, $x, $y ) {
    return $self->{shots}{"$x,$y"};
}

sub ship_at ( $self, $x, $y ) {
    return $self->{grid}{"$x,$y"};
}

sub receive_shot ( $self, $x, $y ) {
    my $size = $self->{size};
    if ( $x < 1 || $x > $size || $y < 1 || $y > $size ) {
        croak "Shot coordinates out of range: ($x, $y)";
    }

    if ( $self->has_shot( $x, $y ) ) {
        return undef;
    }

    my $ship = $self->ship_at( $x, $y );

    if ($ship) {
        $self->{shots}{"$x,$y"} = 'H';
        $ship->record_hit( $x, $y );

        if ( $ship->is_sunk ) {

            # Update all coordinates of this ship to 'S'
            for my $coord ( $ship->coordinates ) {
                $self->{shots}{"$coord->[0],$coord->[1]"} = 'S';
            }
            return {
                result => 'sunk',
                ship   => $ship,
                x      => $x,
                y      => $y,
            };
        }

        return {
            result => 'hit',
            ship   => $ship,
            x      => $x,
            y      => $y,
        };
    }

    $self->{shots}{"$x,$y"} = 'M';
    return {
        result => 'miss',
        x      => $x,
        y      => $y,
    };
}

sub all_sunk ($self) {
    return 0 if scalar( @{ $self->{ships} } ) == 0;
    for my $ship ( @{ $self->{ships} } ) {
        return 0 if !$ship->is_sunk;
    }
    return 1;
}

sub ships_remaining ($self) {
    my $count = 0;
    for my $ship ( @{ $self->{ships} } ) {
        $count++ if !$ship->is_sunk;
    }
    return $count;
}

sub ships_sunk ($self) {
    my $count = 0;
    for my $ship ( @{ $self->{ships} } ) {
        $count++ if $ship->is_sunk;
    }
    return $count;
}

sub reset_shots ($self) {
    $self->{shots} = {};
    for my $ship ( @{ $self->{ships} } ) {
        $ship->clear_hits;
    }
    return $self;
}

sub total_shots ($self) {
    return scalar keys %{ $self->{shots} };
}

sub hit_count ($self) {
    my $count = 0;
    for my $val ( values %{ $self->{shots} } ) {
        $count++ if $val eq 'H' || $val eq 'S';
    }
    return $count;
}

sub miss_count ($self) {
    my $count = 0;
    for my $val ( values %{ $self->{shots} } ) {
        $count++ if $val eq 'M';
    }
    return $count;
}

sub shot_accuracy ($self) {
    my $total = $self->total_shots;
    return 0.0 if $total == 0;
    return ( $self->hit_count / $total ) * 100.0;
}

1;

