package Games::SolarConflict::Controller::GameOver;
{
  $Games::SolarConflict::Controller::GameOver::VERSION = '0.000001';
}

# ABSTRACT: Game over controller

use strict;
use warnings;
use Mouse;
use SDL::Event;
use SDL::Events;

with 'Games::SolarConflict::Roles::Controller';

has players => (
    is       => 'ro',
    isa      => 'Int',
    required => 1,
);

has message => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

sub handle_show {
    my ( $self, $delta, $app ) = @_;

    $app->draw_gfx_text( [ 0, 0 ],  0xFFFFFFFF, $self->message );
    $app->draw_gfx_text( [ 0, 10 ], 0xFFFFFFFF, 'Press R to play again' );
    $app->draw_gfx_text( [ 0, 20 ],
        0xFFFFFFFF, 'Press M to go to the main menu' );
    $app->update();
}

sub handle_event {
    my ( $self, $event, $app ) = @_;

    if ( $event->type == SDL_QUIT ) {
        $app->stop();
    }
    elsif ( $event->type == SDL_KEYDOWN ) {
        my $key = SDL::Events::get_key_name( $event->key_sym );

        if ( $key eq 'r' ) {
            $self->game->transit_to( 'main_game', players => $self->players );
        }
        elsif ( $key eq 'm' ) {
            $self->game->transit_to('main_menu');
        }
    }
}

__PACKAGE__->meta->make_immutable;

no Mouse;

1;



=pod

=head1 NAME

Games::SolarConflict::Controller::GameOver - Game over controller

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


