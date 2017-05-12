use strict;
package Games::Tetris::Shape;
use base 'Class::Accessor::Fast';
__PACKAGE__->mk_accessors(qw( shape width depth center ));

=head1 NAME

Games::Tetris::Shape - representation of a tetris shape

=head1 SYNOPSIS

=head1 METHODS

=head2 new( @rows )

Construct a new shape

=cut

sub new {
    my $class = shift;
    my @rows = @_;

    my $self = $class->SUPER::new;
    $self->shape( [ map { [ map { / / ? undef : $_ } split // ] } @rows ] );
    $self->width( scalar @{ $self->shape->[0] } );
    $self->depth( scalar @{ $self->shape } );
    $self->center([ int($self->width / 2), int($self->depth / 2) ]);
    return $self;
}

sub print {
    my $self = shift;
    print join('', @$_), "\n"
      for @{ $self->shape };
}


=head1 covers( $offset_x, $offset_y )

return a list of points that the shape covers, offset by $offset_x,
$offset_y.

Each point is an anonymous array containing $x, $y, and what's in the
cell

=cut

sub covers {
    my $self = shift;
    my ($x, $y) = @_;
    my ($cx, $cy) = @{ $self->center };
    my @points;

    for (my $iy = 0; $iy < $self->depth; $iy++) {
        for (my $ix = 0; $ix < $self->width; $ix++) {
            my $point = $self->shape->[ $iy ][ $ix ];
            push @points, [ $x + ($ix - $cx), $y + ($iy - $cy), $point ]
              if $point;
        }
    }
    return @points;
}

1;

__END__

=head1 AUTHOR

Richard Clamp <richardc@unixbeard.net>

=head1 COPYRIGHT

Copyright (C) 2003 Richard Clamp.  All Rights Reserved.

This module is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 SEE ALSO

Games::Tetris

=cut
