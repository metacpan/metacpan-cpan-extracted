package Game::TextPacMonster::Creature;
use strict;
use warnings;
use utf8;

use Game::TextPacMonster::Point;

sub new {
    my ( $class, $id, $point, $map ) = @_;
    my $self = {
        _id        => $id,
        _point     => $point,
        _pre_point => undef,
        _map       => $map,
    };
    bless $self, $class;
}

sub id {
    my $self = shift;
    return $self->{_id};
}

sub point {
    my $self = shift;

    if (@_) {
        $self->{_pre_point} = $self->{_point};
        $self->{_point}     = shift;
        return $self;
    }
    else {
        return $self->{_point};
    }
}

sub move_free {
    die "it should be overrided on sub class";
    return 0;
}

sub move {
    my $self = shift;

    return 1 if $self->move_first;

    my $counted_ways = $self->{_map}->count_movable_points( $self->point );

    return $self->move_back    if $counted_ways == 1;
    return $self->move_forward if $counted_ways == 2;
    return $self->move_free;
}

sub move_forward {
    my $self = shift;
    my $pre  = $self->pre_point;
    my $now  = $self->point;

    my $ways = [
        Game::TextPacMonster::Point->new(
            $now->x_coord + 1,
            $now->y_coord
        ),    # go right
        Game::TextPacMonster::Point->new(
            $now->x_coord - 1,
            $now->y_coord
        ),    # go left
        Game::TextPacMonster::Point->new(
            $now->x_coord, $now->y_coord + 1
        ),    # go down
        Game::TextPacMonster::Point->new(
            $now->x_coord, $now->y_coord - 1
        ),    # go up
    ];

    for my $way (@$ways) {
        return 1 if ( !$way->equals($pre) && $self->_move_point($way) );
    }

    return 0;
}

sub pre_point {
    my $self = shift;
    return $self->{_pre_point};
}

sub stay {
    my $self = shift;
    my $p    = $self->point;

    $self->point( Game::TextPacMonster::Point->new( $p->x_coord, $p->y_coord ) );
    return 1;
}

sub get_relative_point {
    my $self = shift;

    my $player = $self->get_player_point;
    my $me     = $self->point;

    my $x = $player->x_coord - $me->x_coord;
    my $y = $player->y_coord - $me->y_coord;

    return Game::TextPacMonster::Point->new( $x, $y );
}

sub get_player_point {
    my $self = shift;
    return $self->{_map}->get_player_point;
}

sub move_first {
    my $self = shift;

    if ( $self->{_map}->get_time == 0 ) {
        my @methods = qw( move_down move_left move_up move_right);

        for (@methods) {
            return 1 if ( $self->$_ );
        }
    }

    return 0;
}

sub move_back {
    my $self   = shift;
    my $p      = $self->pre_point;
    my $next_p = Game::TextPacMonster::Point->new( $p->x_coord, $p->y_coord );
    return $self->_move_point($next_p);
}

sub move_up {
    my $self = shift;
    my $p    = $self->point;
    my $next_p =
      Game::TextPacMonster::Point->new( $p->x_coord, $p->y_coord - 1 );
    return $self->_move_point($next_p);
}

sub move_down {
    my $self = shift;
    my $p    = $self->point;
    my $next_p =
      Game::TextPacMonster::Point->new( $p->x_coord, $p->y_coord + 1 );
    return $self->_move_point($next_p);
}

sub move_right {
    my $self = shift;
    my $p    = $self->point;
    my $next_p =
      Game::TextPacMonster::Point->new( $p->x_coord + 1, $p->y_coord );
    return $self->_move_point($next_p);
}

sub move_left {
    my $self = shift;
    my $p    = $self->point;
    my $next_p =
      Game::TextPacMonster::Point->new( $p->x_coord - 1, $p->y_coord );
    return $self->_move_point($next_p);
}

sub _move_point {
    my ( $self, $point ) = @_;

    if ( $self->{_map}->can_move($point) ) {
        $self->point($point);
        return 1;
    }
    return 0;
}

1;
