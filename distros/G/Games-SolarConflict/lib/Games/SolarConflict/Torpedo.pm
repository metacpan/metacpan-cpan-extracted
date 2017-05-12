package Games::SolarConflict::Torpedo;
{
  $Games::SolarConflict::Torpedo::VERSION = '0.000001';
}

# ABSTRACT: Torpedo model

use strict;
use warnings;
use Mouse;
use SDL::Color;
use SDL::GFX::Primitives;

with 'Games::SolarConflict::Roles::Drawable';
with 'Games::SolarConflict::Roles::Physical';

has '+r' => ( default => 3 );

has '+mass' => ( default => 10 );

has '+active' => ( default => 0 );

has '+visible' => ( default => 0 );

has color => (
    is      => 'ro',
    isa     => 'Int',
    default => 0xFFFFFFFF,
);

after active => sub {
    my ( $self, $active ) = @_;
    $self->visible($active) if defined $active;
};

# torpedos have negligible gravitational force
sub force_on { ( 0, 0 ) }

sub interact {
    my ( $self, $obj ) = @_;

    $self->active(0);
}

sub draw {
    my ( $self, $surface ) = @_;

    SDL::GFX::Primitives::filled_circle_color( $surface, $self->x, $self->y,
        $self->r, $self->color );
    return [
        $self->x - $self->r - 1,
        $self->y - $self->r - 1,
        $self->r * 2 + 2,
        $self->r * 2 + 2
    ];
}

__PACKAGE__->meta->make_immutable;

no Mouse;

1;



=pod

=head1 NAME

Games::SolarConflict::Torpedo - Torpedo model

=head1 VERSION

version 0.000001

=for Pod::Coverage force_on interact

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


