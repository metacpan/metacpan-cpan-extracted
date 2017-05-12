package Games::SolarConflict::Roles::Explosive;
{
  $Games::SolarConflict::Roles::Explosive::VERSION = '0.000001';
}

# ABSTRACT: Explosive object role

use strict;
use warnings;
use Mouse::Role;
use SDLx::Sprite::Animated;

requires qw( x y draw visible reset );

has exploding => (
    is      => 'rw',
    isa     => 'Bool',
    default => 0,
);

has explosion => (
    is       => 'ro',
    isa      => 'SDLx::Sprite::Animated',
    required => 1,
);

around draw => sub {
    my ( $orig, $self, $surface ) = @_;

    if ( $self->exploding ) {
        my $e = $self->explosion;
        if ( $e->current_loop != 1 ) {
            $self->exploding(0);
            $self->visible(0);
            return;
        }
        $e->x( $self->x - $e->rect->w / 2 );
        $e->y( $self->y - $e->rect->h / 2 );
        $e->draw($surface);
        return $e->rect;
    }
    else {
        return $self->$orig($surface);
    }
};

after reset => sub {
    my ($self) = @_;
    $self->explosion->sequence('default');
    $self->exploding(0);
};

sub explode {
    my ($self) = @_;

    $self->exploding(1);
    $self->explosion->start();
}

no Mouse::Role;

1;



=pod

=head1 NAME

Games::SolarConflict::Roles::Explosive - Explosive object role

=head1 VERSION

version 0.000001

=for Pod::Coverage explode

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


