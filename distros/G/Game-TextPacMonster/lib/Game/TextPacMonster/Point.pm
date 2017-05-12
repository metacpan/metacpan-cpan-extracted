package Game::TextPacMonster::Point;

use strict;
use warnings;
use utf8;


sub new {
    my ( $class, $x, $y ) = @_;
    my $self = {
        x => $x,
        y => $y,
    };

    bless $self, $class;
}


sub equals {
    my ( $self, $point ) = @_;
    my $result_x = ( $self->x_coord == $point->x_coord ) ? 1 : 0;
    my $result_y = ( $self->y_coord == $point->y_coord ) ? 1 : 0;

    if ( $result_x && $result_y ) {
        return 1;
    }

    return 0;
}



sub x_coord {
    my $self = shift;
    if (@_) {
        $self->{x} = shift;
        return $self;
    }
    else {
        return $self->{x};
    }
}


sub y_coord {
    my $self = shift;
    if (@_) {
        $self->{y} = shift;
        return $self;
    }
    else {
        return $self->{y};
    }
}

1;
