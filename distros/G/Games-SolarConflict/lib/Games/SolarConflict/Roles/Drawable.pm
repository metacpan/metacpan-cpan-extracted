package Games::SolarConflict::Roles::Drawable;
{
  $Games::SolarConflict::Roles::Drawable::VERSION = '0.000001';
}

# ABSTRACT: Drawable role

use strict;
use warnings;
use Mouse::Role;
use SDL::Rect;

requires qw( draw );

has visible => (
    is      => 'rw',
    isa     => 'Bool',
    default => 1,
);

has prev_rect => (
    is      => 'rw',
    default => sub { [] },
);

around draw => sub {
    my ( $orig, $self, $surface ) = @_;

    return unless $self->visible;

    my $rect = $self->prev_rect;
    $self->prev_rect( $self->$orig($surface) );
    return ( $rect, $self->prev_rect );
};

no Mouse::Role;

1;



=pod

=head1 NAME

Games::SolarConflict::Roles::Drawable - Drawable role

=head1 VERSION

version 0.000001

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


