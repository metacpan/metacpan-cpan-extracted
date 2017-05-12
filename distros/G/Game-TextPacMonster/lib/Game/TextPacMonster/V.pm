package Game::TextPacMonster::V;

use strict;
use warnings;
use utf8;
use Game::TextPacMonster::Point;

use base 'Game::TextPacMonster::Creature';

sub new {
    my $class = shift @_;
    my $self = $class->SUPER::new(@_);
}


sub move_free {
    my $self = shift;

    my $relative_p = $self->get_relative_point;
    my $relative_x = $relative_p->x_coord;
    my $relative_y = $relative_p->y_coord;

    my @moves = qw( move_down move_left move_up move_right);

    my $first_move = undef;

    if ( $relative_y != 0 ) {
        $first_move = ( $relative_y > 0 ) ? 'move_down' : 'move_up';
    }
    elsif ( $relative_x != 0 ) {
        $first_move = ( $relative_x > 0 ) ? 'move_right' : 'move_left';
    }

    unshift( @moves, $first_move ) if $first_move;

    for my $move (@moves) {
        return 1 if $self->$move;
    }

    return 0;
}

1;
