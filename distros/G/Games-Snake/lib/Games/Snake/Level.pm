package Games::Snake::Level;
{
  $Games::Snake::Level::VERSION = '0.000001';
}

# ABSTRACT: Level object

use strict;
use warnings;
use Moo;
use MooX::Types::MooseLike::Base qw( Int ArrayRef );
use Sub::Quote qw(quote_sub);

has w => (
    is       => 'ro',
    isa      => Int,
    required => 1,
);

has h => (
    is       => 'ro',
    isa      => Int,
    required => 1,
);

has walls => (
    is      => 'ro',
    isa     => ArrayRef,
    lazy    => 1,
    builder => '_build_walls',
);

has size => (
    is       => 'ro',
    isa      => Int,
    required => 1,
);

has color => (
    is      => 'ro',
    isa     => Int,
    default => quote_sub q{ 0x0000FFFF },
);

sub _build_walls {
    my ($self) = @_;

    my @walls;

    my $w = $self->w;
    my $h = $self->h;

    foreach my $x ( 0 .. $w - 1 ) {
        push @walls, [ $x, 0 ], [ $x, $h - 1 ];
    }

    foreach my $y ( 1 .. $self->w - 2 ) {
        push @walls, [ 0, $y ], [ $w - 1, $y ];
    }

    return \@walls;
}

sub is_wall {
    my ( $self, $coord ) = @_;
    return
        scalar grep { $coord->[0] == $_->[0] && $coord->[1] == $_->[1] }
        @{ $self->walls };
}

sub draw {
    my ( $self, $surface ) = @_;

    my $size  = $self->size;
    my $color = $self->color;

    foreach my $wall ( @{ $self->walls } ) {
        $surface->draw_rect( [ ( map { $_ * $size } @$wall ), $size, $size ],
            $color );
    }
}

1;



=pod

=head1 NAME

Games::Snake::Level - Level object

=head1 VERSION

version 0.000001

=for Pod::Coverage color draw h is_wall size w

=head1 SEE ALSO

=over 4

=item * L<Games::Snake>

=back

=head1 AUTHOR

Jeffrey T. Palmer <jtpalmer@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2012 by Jeffrey T. Palmer.

This is free software, licensed under:

  The MIT (X11) License

=cut


__END__


