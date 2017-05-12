package Game::TextPacMonster::L;

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

    my $pre_p = $self->pre_point;
    my $now_p = $self->point;

    my $relative_point_x = $now_p->x_coord - $pre_p->x_coord;
    my $relative_point_y = $now_p->y_coord - $pre_p->y_coord;

    my $orientation = q{}; # an empty string;

    if ($relative_point_y == 0) {
	$orientation = $relative_point_x > 0 ? 'left_to_right' : 'right_to_left';
    }
    else {
	$orientation = $relative_point_y > 0 ? 'up_to_down' : 'down_to_up';
    }

    my %next_rules = $self->_make_rules;
    my @next_rule = @{$next_rules{$orientation}};

    for my $rule (@next_rule) {
	return 1 if $self->$rule;
    }

    return 0;
}

sub _make_rules {
    my %rules = ();

    # L will face to move left, front, right
    $rules{left_to_right} = [ 'move_up', 'move_right', 'move_down' ];
    $rules{right_to_left} = [ 'move_down', 'move_left', 'move_up' ];
    $rules{up_to_down} = [ 'move_right', 'move_down', 'move_left' ];
    $rules{down_to_up} = [ 'move_left', 'move_up', 'move_right' ];

    return %rules;
}


1;
