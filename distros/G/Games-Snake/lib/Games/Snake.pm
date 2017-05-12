package Games::Snake;
{
  $Games::Snake::VERSION = '0.000001';
}

# ABSTRACT: Snake game

use strict;
use warnings;
use Moo;
use MooX::Types::MooseLike::Base qw( Int ArrayRef );
use Sub::Quote qw(quote_sub);
use SDL 2.500;
use SDL::Event;
use SDLx::App;
use Games::Snake::Player;
use Games::Snake::Level;

has app => (
    is      => 'ro',
    lazy    => 1,
    builder => '_build_app',
    handles => [qw( run )],
);

has size => (
    is      => 'ro',
    isa     => Int,
    default => quote_sub q{ 10 },
);

has player => (
    is      => 'rw',
    lazy    => 1,
    builder => '_build_player',
);

has level => (
    is      => 'ro',
    lazy    => 1,
    builder => '_build_level',
);

has apple => (
    is      => 'rw',
    isa     => ArrayRef,
    lazy    => 1,
    builder => '_build_apple',
);

sub _build_app {
    return SDLx::App->new(
        title => 'Snake',
        w     => 800,
        h     => 600,
        eoq   => 1,
        dt    => 0.05,
        delay => 20,
    );
}

sub _build_level {
    my ($self) = @_;
    return Games::Snake::Level->new(
        size  => $self->size,
        w     => $self->app->w / $self->size,
        h     => $self->app->h / $self->size,
        color => 0x00C2BB0FF,
    );
}

sub _build_player {
    my ($self) = @_;
    return Games::Snake::Player->new(
        size     => $self->size,
        color    => 0x6EC200FF,
        growing  => 9,
        segments => [ [ 40, 30 ] ],
        direction => [ 1, 0 ],
    );
}

sub _build_apple {
    my ($self) = @_;

    my $level  = $self->level;
    my $player = $self->player;

    my $coord;

    do {
        $coord = [ int( rand( $level->w ) ), int( rand( $level->h ) ) ];
    } while ( $player->is_segment($coord) || $level->is_wall($coord) );

    return $coord;
}

sub BUILD {
    my ($self) = @_;

    my $app = $self->app;
    $app->add_event_handler( sub { $self->handle_event(@_) } );
    $app->add_move_handler( sub  { $self->handle_move(@_) } );
    $app->add_show_handler( sub  { $self->handle_show(@_) } );
}

sub handle_event {
    my ( $self, $event, $app ) = @_;

    my $player = $self->player;

    if ( $event->type == SDL_KEYDOWN ) {
        $player->direction( [ -1, 0 ] )  if $event->key_sym == SDLK_LEFT;
        $player->direction( [ 1,  0 ] )  if $event->key_sym == SDLK_RIGHT;
        $player->direction( [ 0,  -1 ] ) if $event->key_sym == SDLK_UP;
        $player->direction( [ 0,  1 ] )  if $event->key_sym == SDLK_DOWN;

        my $key = SDL::Events::get_key_name( $event->key_sym );
        if ( !$player->alive && $key eq 'r' ) {
            $self->player( $self->_build_player );
        }
    }
}

sub handle_move {
    my ( $self, $step, $app, $t ) = @_;

    my $level  = $self->level;
    my $player = $self->player;

    $player->move($t);

    if ( $player->hit_self() || $level->is_wall( $player->head ) ) {
        $player->alive(0);
    }
    elsif ($player->head->[0] == $self->apple->[0]
        && $player->head->[1] == $self->apple->[1] )
    {
        $player->speed( $player->speed * 0.9 );
        $player->growing( $player->growing + 10 );
        $self->apple( $self->_build_apple );
    }
}

sub handle_show {
    my ( $self, $delta, $app ) = @_;

    $app->draw_rect( [ 0, 0, $app->w, $app->h ], 0x000000FF );

    my $size = $self->size;
    $app->draw_rect(
        [ ( map { $_ * $size } @{ $self->apple } ), $size, $size ],
        0xC20006FF );

    $self->player->draw($app);
    $self->level->draw($app);

    if ( !$self->player->alive ) {
        $app->draw_gfx_text( [ 12, 12 ],
            0xFFFFFFFF,
            'Snake length: ' . scalar @{ $self->player->segments } );
        $app->draw_gfx_text( [ 12, 22 ], 0xFFFFFFFF, 'Press R to restart' );
    }

    $app->update();
}

1;



=pod

=head1 NAME

Games::Snake - Snake game

=head1 VERSION

version 0.000001

=head1 DESCRIPTION

Games::Snake is a clone of the classic Snake game.

This game was originally created for The SDL Perl Game Contest!

See L<snake.pl> for instructions to play the game.

=for Pod::Coverage BUILD handle_event handle_move handle_show size

=head1 SEE ALSO

=over 4

=item * L<snake.pl>

=item * L<SDL>

=item * L<The SDL Perl Game Contest!|http://onionstand.blogspot.com/2011/02/sdl-perl-game-contest.html>

=item * L<Snake|http://en.wikipedia.org/wiki/Snake_%28video_game%29>

=back

=head1 AUTHOR

Jeffrey T. Palmer <jtpalmer@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2012 by Jeffrey T. Palmer.

This is free software, licensed under:

  The MIT (X11) License

=cut


__END__


