package Game::TextPacMonster::Map;

use strict;
use warnings;
use utf8;

use Game::TextPacMonster::Point;
use Game::TextPacMonster::Player;
use Game::TextPacMonster::V;
use Game::TextPacMonster::H;
use Game::TextPacMonster::L;
use Game::TextPacMonster::R;
use Game::TextPacMonster::J;

my $_PLAYER_ID   = 1;
my $_PLAYER_CHAR = '@';

sub new {
    my ( $class, $map_info_ref ) = @_;

    chomp( $map_info_ref->{map_string} );

    my $self = {
        _timelimit    => $map_info_ref->{timelimit},
        _current_time => 0,
        _map_string   => $map_info_ref->{map_string},
        _map          => undef,
        _map_feeds    => undef,
        _map_width    => undef,
        _map_height   => undef,
        _log          => q{},
        _objects      => {}
    };

    bless $self, $class;
    $self->_set_map();
    return $self;
}

sub command_player {
    my ( $self, $command ) = @_;

    return 0 if ( $command && !( $command =~ /^(j|k|l|h|.)$/ ) );

    my $objects = $self->{_objects};

    return 0 if ( !$objects->{$_PLAYER_ID}->can_move($command) );

    # creature move first
    for my $key ( keys %$objects ) {
        next if ( $key eq $_PLAYER_ID );
        $objects->{$key}->move();
    }

    # player move second
    $objects->{$_PLAYER_ID}->move($command);

    $self->increase_current_time;
    $self->{_log} .= $command;

    return 1;
}

sub get_log {
    my $self = shift;
    return $self->{_log};
}

sub _set_map {
    my $self = shift;
    my @map_chars = split( //, $self->{_map_string} );

    my $map_feeds = [];
    my $map       = [];

    my $x = 0;
    my $y = 0;

    my $object_id = $_PLAYER_ID + 1;

    for my $char (@map_chars) {

        if ( $char eq "\n" ) {
            $x = 0;
            $y += 1;
            next;
        }
        elsif ( $char eq '.' ) {
            $map_feeds->[$y][$x] = 1;
            $map->[$y][$x]       = q{ };
        }
        elsif ( $char eq '@' ) {
            my $point = Game::TextPacMonster::Point->new( $x, $y );
            my $player =
              Game::TextPacMonster::Player->new( $_PLAYER_ID, $point, $self );
            $self->{_objects}->{"$_PLAYER_ID"} = $player;
            $map->[$y][$x] = q{ };
        }
        elsif ( $char =~ /^(R|L|V|H|J)$/ ) {
            my $p = Game::TextPacMonster::Point->new( $x, $y );
            my $enemy =
              ("Game::TextPacMonster::$char")->new( $object_id, $p, $self );
            $self->{_objects}->{"$object_id"} = $enemy;
            $map->[$y][$x] = q{ };
            ++$object_id;
        }
        else {
            $map->[$y][$x] = $char;
        }

        $x += 1;
    }

    $self->{_map}        = $map;
    $self->{_map_feeds}  = $map_feeds;
    $self->{_map_width}  = @$map;
    $self->{_map_height} = @{ $map->[0] };
    return $self;
}

sub get_time {
    my $self = shift;
    return $self->{_current_time};
}

sub can_move {
    my ( $self, $point ) = @_;
    my $x    = $point->x_coord;
    my $y    = $point->y_coord;
    my $char = $self->{_map}->[$y][$x];

    if ( $char && $char ne '#' ) {
        return 1;
    }
    return 0;
}

sub get_left_time {
    my $self = shift;
    return $self->{_timelimit} - $self->get_time;

}

sub get_current_time {
    my $self = shift;
    return $self->{_current_time};
}

sub increase_current_time {
    my $self = shift;
    $self->{_current_time} += 1;
    return $self;
}

sub is_win {
    my $self = shift;

    my $feeds_result = ( $self->count_feeds == 0 ) ? 1 : 0;
    my $time_result =
      ( $self->{_timelimit} >= $self->get_current_time ) ? 1 : 0;
    my $result = ( $feeds_result && $time_result ) ? 1 : 0;

    return $result;
}

sub count_feeds {
    my $self = shift;

    my $feeds_num = 0;

    for ( @{ $self->{_map_feeds} } ) {
        if ($_) {
            $feeds_num += $_ ? 1 : 0 for (@$_);
        }
    }

    return $feeds_num;
}

sub del_feed {
    my ( $self, $point ) = @_;

    if ( ref($point) ne 'Game::TextPacMonster::Point' ) {
        die 'Type error: delFeed require Point instance.';
    }

    if ( $self->{_map_feeds}->[ $point->y_coord ][ $point->x_coord ] ) {
        $self->{_map_feeds}->[ $point->y_coord ][ $point->x_coord ] = undef;
    }
    return $self;
}

sub get_string {
    my $self = shift;

    # make deep copy
    my @map = map {
        my @map = map { $_ } @$_;
        \@map;
    } @{ $self->{_map} };

    my $objects = $self->{_objects};

    # First, place player on the map.
    # because player should be overlaied when player lose
    my $player   = $objects->{$_PLAYER_ID};
    my $player_p = $player->point;
    $map[ $player_p->y_coord ][ $player_p->x_coord ] = $_PLAYER_CHAR;

    # Second, enemies place on the map
    for my $key ( keys %$objects ) {
        next if $key eq $_PLAYER_ID;
        my $obj         = $objects->{$key};
        my $p_x         = $obj->point->x_coord;
        my $p_y         = $obj->point->y_coord;
        my $object_char = ( split( /::/, ref($obj) ) )[-1];
        $map[$p_y][$p_x] = $object_char;
    }

    my $feeds      = $self->{_map_feeds};
    my $map_string = q{};                   # empty string
    my $y          = 0;
    for my $horizotal (@map) {
        my $x       = 0;
        my @x_chars = map {
            my $char = ( $_ eq q{ } && $feeds->[$y][$x] ) ? '.' : $_;
            ++$x;
            $char;
        } @{$horizotal};

        push( @x_chars, "\n" );
        $map_string .= $_ for (@x_chars);
        ++$y;
    }

    chomp($map_string);
    return $map_string;
}

sub get_player_point {
    my $self = shift;
    return $self->{_objects}->{$_PLAYER_ID}->point;
}

sub is_lose {
    my $self = shift;

    return 1 if ( $self->{_timelimit} <= $self->{_current_time} );

    my $player_p     = $self->{_objects}->{$_PLAYER_ID}->point;
    my $player_pre_p = $self->{_objects}->{$_PLAYER_ID}->pre_point;

    for my $key ( keys %{ $self->{_objects} } ) {

        next if ( $key eq $_PLAYER_ID );

        my $enemy_p     = $self->{_objects}->{$key}->point;
        my $enemy_pre_p = $self->{_objects}->{$key}->pre_point;

        if ( $player_pre_p && $enemy_pre_p ) {    # not first time
            if (   $player_p->equals($enemy_pre_p)
                && $player_pre_p->equals($enemy_p) )
            {
                return 1;
            }
        }

        return 1 if $player_p->equals($enemy_p);
    }
    return 0;
}


sub count_movable_points {
    my ( $self, $point ) = @_;

    my $map = $self->{_map};

    my @way_chars = (
        $map->[ $point->y_coord ][ $point->x_coord - 1 ],
        $map->[ $point->y_coord ][ $point->x_coord + 1 ],
        $map->[ $point->y_coord - 1 ][ $point->x_coord ],
        $map->[ $point->y_coord + 1 ][ $point->x_coord ],
    );

    my $way_couter = 0;

    for my $char (@way_chars) {
        ++$way_couter if ( $char && $char ne '#' );
    }
    return $way_couter;
}

1;
