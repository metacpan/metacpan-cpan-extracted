package Games::Snake::Player;
{
  $Games::Snake::Player::VERSION = '0.000001';
}

# ABSTRACT: Player object

use strict;
use warnings;
use Moo;
use MooX::Types::MooseLike::Base qw( ArrayRef Num Bool Int );
use Sub::Quote qw(quote_sub);

has segments => (
    is      => 'ro',
    isa     => ArrayRef,
    default => quote_sub q{ [] },
);

has speed => (
    is      => 'rw',
    isa     => Num,
    default => quote_sub q{ 0.1 },
);

has _move_time => (
    is      => 'rw',
    isa     => Num,
    default => quote_sub q{ 0 },
);

has direction => (
    is      => 'rw',
    isa     => ArrayRef,
    default => quote_sub q{ [] },
);

has alive => (
    is      => 'rw',
    isa     => Bool,
    default => quote_sub q{ 1 },
);

has growing => (
    is      => 'rw',
    isa     => Int,
    default => quote_sub q{ 0 },
);

has size => (
    is       => 'ro',
    isa      => Int,
    required => quote_sub q{ 1 },
);

has color => (
    is       => 'ro',
    isa      => Int,
    required => quote_sub q{ 1 },
);

sub head {
    my ($self) = @_;
    return $self->segments->[0];
}

sub body {
    my ($self) = @_;
    my @segments = @{ $self->segments };
    return [ @segments[ 1 .. $#segments ] ];
}

sub move {
    my ( $self, $t ) = @_;

    return unless $self->alive;

    return unless $t >= $self->_move_time + $self->speed;
    $self->_move_time($t);

    my $segments = $self->segments;

    my @head = @{ $self->head };
    my @d    = @{ $self->direction };
    unshift @$segments, [ $head[0] + $d[0], $head[1] + $d[1] ];

    if ( my $grow = $self->growing ) {
        $self->growing( $grow - 1 );
    }
    else {
        pop @$segments;
    }
}

sub hit_self {
    my ($self) = @_;

    my @head = @{ $self->head };
    return
        scalar grep { $head[0] == $_->[0] && $head[1] == $_->[1] }
        @{ $self->body };
}

sub is_segment {
    my ( $self, $coord ) = @_;

    return
        scalar grep { $coord->[0] == $_->[0] && $coord->[1] == $_->[1] }
        @{ $self->segments };
}

sub draw {
    my ( $self, $surface ) = @_;

    my $size  = $self->size;
    my $color = $self->color;

    foreach my $segment ( @{ $self->segments } ) {
        $surface->draw_rect(
            [ ( map { $_ * $size } @$segment ), $size, $size ], $color );
    }
}

1;



=pod

=head1 NAME

Games::Snake::Player - Player object

=head1 VERSION

version 0.000001

=for Pod::Coverage body color draw head hit_self is_segment move segments size

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


