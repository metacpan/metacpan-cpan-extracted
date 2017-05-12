package Games::Cellulo::Game::Screen;
$Games::Cellulo::Game::Screen::VERSION = '0.22';
use strict;
use warnings FATAL => 'all';

use Moo;
require Term::Screen;

has _screen => (
    is      => 'lazy',
    handles => {
        'at'        => 'at',
        key_pressed => 'key_pressed',
        clrscr => 'clrscr',
    } );

has grid => (
    is => 'lazy',
);

sub _build_rows { shift->_screen->rows }
sub _build_cols { shift->_screen->cols }
has rows => ( is => 'lazy' );
has cols => ( is => 'lazy' );


sub reset_grid {
    my $self = shift;
    my $grid = $self->grid;
    @$grid = @{ $self->_build_grid };
    return $grid;
}
sub _build_grid {
    my $self = shift;
    my $ret = [ map { [ (undef) x $self->cols ] } ( 1 .. $self->rows ) ];
    return $ret;
}

sub _build__screen {
    my $self = shift;
    Term::Screen->new;
}

sub xpos {
    my( $self, $xx ) = @_;
    if( $xx >= $self->cols ) {
        $xx -= $self->cols;
    } elsif ( $xx < 0 ) {
        $xx += $self->cols;
    }
    return $xx;
}

sub ypos {
    my( $self, $yy ) = @_;
    if( $yy >= $self->rows ) {
        $yy -= $self->rows;
    } elsif ( $yy < 0 ) {
        $yy += $self->rows;
    }
    return $yy;
}

1;
