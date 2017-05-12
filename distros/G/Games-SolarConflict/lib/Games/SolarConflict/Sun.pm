package Games::SolarConflict::Sun;
{
  $Games::SolarConflict::Sun::VERSION = '0.000001';
}

# ABSTRACT: Sun model

use strict;
use warnings;
use Mouse;

with 'Games::SolarConflict::Roles::Physical';

has '+r' => ( default => 38 );

has '+mass' => ( default => 100000 );

has sprite => (
    is       => 'ro',
    isa      => 'SDLx::Sprite',
    required => 1,
    handles  => [qw( draw )],
);

with 'Games::SolarConflict::Roles::Drawable';

before draw => sub {
    my ($self) = @_;
    $self->sprite->x( $self->x - $self->sprite->w / 2 );
    $self->sprite->y( $self->y - $self->sprite->h / 2 );
};

around draw => sub {
    my ( $orig, $self, $surface ) = @_;
    $self->$orig($surface);
    return $self->sprite->rect;
};

# The sun doesn't move
sub acc { ( 0, 0, 0 ) }

__PACKAGE__->meta->make_immutable;

no Mouse;

1;



=pod

=head1 NAME

Games::SolarConflict::Sun - Sun model

=head1 VERSION

version 0.000001

=for Pod::Coverage acc

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


