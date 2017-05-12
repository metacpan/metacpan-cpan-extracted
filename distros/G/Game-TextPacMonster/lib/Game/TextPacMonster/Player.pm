package Game::TextPacMonster::Player;

use strict;
use warnings;
use utf8;
use Game::TextPacMonster::Point;

use base 'Game::TextPacMonster::Creature';

sub new {
    my $class = shift @_;
    my $self  = $class->SUPER::new(@_);
}

sub _get_function {
    my ( $self, $command ) = @_;

    return 0 if ( !$command );

    my %command_function_map = (
        '.' => 'stay',
        'j' => 'move_down',
        'k' => 'move_up',
        'h' => 'move_left',
        'l' => 'move_right',
    );

    return 0 if ( !$command_function_map{$command} );
    return $command_function_map{$command};
}

sub can_move {
    my ( $self, $command ) = @_;

    my $f = $self->_get_function($command);
    return 0 if ( !$f );

    my $x = $self->{_point}->x_coord;
    my $y = $self->{_point}->y_coord;

    if ( $f eq 'move_down' ) {
        ++$y;
    }
    elsif ( $f eq 'move_up' ) {
        --$y;
    }
    elsif ( $f eq 'move_left' ) {
        --$x;
    }
    elsif ( $f eq 'move_right' ) {
        ++$x;
    }
    elsif ( $f eq 'stay' ) {

        # do nothing
    }
    else {
        return 0;
    }

    my $next_point = Game::TextPacMonster::Point->new( $x, $y );

    return $self->{_map}->can_move($next_point);
}

sub move {
    my ( $self, $command ) = @_;

    my $f = $self->_get_function($command);

    if ( $f && $self->$f ) {
        $self->_eat();
        return 1;
    }

    return 0;
}

sub _eat {
    my $self = shift;
    $self->{_map}->del_feed( $self->point );
}

1;

