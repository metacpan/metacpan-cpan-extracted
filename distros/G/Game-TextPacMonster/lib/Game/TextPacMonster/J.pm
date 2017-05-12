package Game::TextPacMonster::J;

use strict;
use warnings;
use utf8;

use Game::TextPacMonster::Point;

use base 'Game::TextPacMonster::Creature';

sub new {
    my $class = shift @_;
    my $self = $class->SUPER::new(@_);
    $self->{_enter_crossing_count} = 0;
    return $self;
}


sub move_free {
    my $self = shift;

    my $crossing_count = $self->{_enter_crossing_count};

    my $is_r_behavior = ( $crossing_count % 2 == 1 ) ? 1 : 0;

    my @next_rules = $self->_get_rule($is_r_behavior);

    for my $rule (@next_rules) {
        if ( $self->$rule ) {
            $self->{_enter_crossing_count} += 1;
            return 1;
        }
    }

    return 0;
}


sub _get_delta_point {
    my $self = shift;

    my $pre_p = $self->pre_point;
    my $now_p = $self->point;

    my $delta_x = $now_p->x_coord - $pre_p->x_coord;
    my $delta_y = $now_p->y_coord - $pre_p->y_coord;

    return Game::TextPacMonster::Point->new($delta_x, $delta_y);
}


sub _get_rules {
    my ( $self, $is_r_behavior ) = @_;

    my %r_rules = ();

    # R will face to move right, front, left
    $r_rules{left_to_right} = [ 'move_down',  'move_right', 'move_up' ];
    $r_rules{right_to_left} = [ 'move_up',    'move_left',  'move_down' ];
    $r_rules{up_to_down}    = [ 'move_left',  'move_down',  'move_right' ];
    $r_rules{down_to_up}    = [ 'move_right', 'move_up',    'move_left' ];


    my %l_rules = ();

    # L will face to move left, front, right
    $l_rules{left_to_right} = [ 'move_up',    'move_right', 'move_down' ];
    $l_rules{right_to_left} = [ 'move_down',  'move_left',  'move_up' ];
    $l_rules{up_to_down}    = [ 'move_right', 'move_down',  'move_left' ];
    $l_rules{down_to_up}    = [ 'move_left',  'move_up',    'move_right' ]; 


    my %rules = ( $is_r_behavior ) ? %r_rules : %l_rules;
    return %rules;
}



sub _get_rule {
    my ($self, $is_r_behavior)  = @_;

    my $delta_p = $self->_get_delta_point;

    my %rules = $self->_get_rules($is_r_behavior);

    my $orientation = q{};    # empty string

    if ( $delta_p->y_coord == 0 ) {
        $orientation = $delta_p->x_coord > 0 ? 'left_to_right' : 'right_to_left';
    }
    else {
        $orientation = $delta_p->y_coord > 0 ? 'up_to_down' : 'down_to_up';
    }

    return @{ $rules{$orientation} };
}

1;
