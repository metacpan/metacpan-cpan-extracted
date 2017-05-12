package Games::SolarConflict::Controller::MainMenu;
{
  $Games::SolarConflict::Controller::MainMenu::VERSION = '0.000001';
}

# ABSTRACT: Main menu controller

use strict;
use warnings;
use Mouse;
use SDL::Event;
use SDL::Events;
use SDLx::Text;

with 'Games::SolarConflict::Roles::Controller';

has title => (
    is      => 'ro',
    isa     => 'SDLx::Text',
    builder => '_build_title',
);

sub _build_title {
    my ($self) = @_;

    return SDLx::Text->new(
        color   => 0xAAAAAAFF,
        size    => 96,
        font    => $self->game->font,
        text    => 'Solar Conflict',
        h_align => 'center',
        x       => $self->game->app->w / 2,
        y       => 50,
    );
}

sub handle_show {
    my ( $self, $delta, $app ) = @_;

    $app->draw_rect( [ 0, 0, $app->w, $app->h ], 0x000000FF );
    $self->game->background->blit( $app, [ 0, 0, $app->w, $app->h ] );

    $self->title->write_to($app);

    $app->draw_gfx_text( [ 400, 210 ],
        0xFFFFFFFF, 'Press 1 for single player' );
    $app->draw_gfx_text( [ 400, 220 ], 0xFFFFFFFF, 'Press 2 for two player' );

    my ( $x1, $y1 ) = ( 300, 300 );

    $app->draw_gfx_text( [ $x1, $y1 ], 0xFFFFFFFF, 'Player 1' );
    $self->game->spaceship1->sprite->draw_xy( $app, $x1, $y1 + 10 );
    $app->draw_gfx_text( [ $x1, $y1 + 40 ], 0xFFFFFFFF, 'Q - Fire Torpedo' );
    $app->draw_gfx_text( [ $x1, $y1 + 50 ], 0xFFFFFFFF, 'W - Accelerate' );
    $app->draw_gfx_text( [ $x1, $y1 + 60 ], 0xFFFFFFFF, 'A - Rotate CCW' );
    $app->draw_gfx_text( [ $x1, $y1 + 70 ], 0xFFFFFFFF, 'D - Rotate CW' );
    $app->draw_gfx_text( [ $x1, $y1 + 80 ], 0xFFFFFFFF, 'S - Hyperspace' );

    my ( $x2, $y2 ) = ( 600, 300 );

    $app->draw_gfx_text( [ $x2, $y2 + 00 ], 0xFFFFFFFF, 'Player 2' );
    $self->game->spaceship2->sprite->draw_xy( $app, $x2, $y2 + 10 );
    $app->draw_gfx_text( [ $x2, $y2 + 40 ], 0xFFFFFFFF, 'U - Fire Torpedo' );
    $app->draw_gfx_text( [ $x2, $y2 + 50 ], 0xFFFFFFFF, 'I - Accelerate' );
    $app->draw_gfx_text( [ $x2, $y2 + 60 ], 0xFFFFFFFF, 'J - Rotate CCW' );
    $app->draw_gfx_text( [ $x2, $y2 + 70 ], 0xFFFFFFFF, 'L - Rotate CW' );
    $app->draw_gfx_text( [ $x2, $y2 + 80 ], 0xFFFFFFFF, 'K - Hyperspace' );
    $app->update();
}

sub handle_event {
    my ( $self, $event, $app ) = @_;

    if ( $event->type == SDL_QUIT ) {
        $app->stop();
    }
    elsif ( $event->type == SDL_KEYDOWN ) {
        my $key = SDL::Events::get_key_name( $event->key_sym );

        if ( $key eq '1' || $key eq '2' ) {
            $self->game->transit_to( 'main_game', players => $key );
        }
    }
}

__PACKAGE__->meta->make_immutable;

no Mouse;

1;



=pod

=head1 NAME

Games::SolarConflict::Controller::MainMenu - Main menu controller

=head1 VERSION

version 0.000001

=for Pod::Coverage handle_event handle_show

=head1 SEE ALSO

=over 4

=item * L<Games::SolarConflict>

=back

=head1 AUTHOR

Jeffrey T. Palmer <jtpalmer@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2012 by Jeffrey T. Palmer.

This is free software, licensed under:

  The MIT (X11) License

=cut


__END__


