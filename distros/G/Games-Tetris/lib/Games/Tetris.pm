package Games::Tetris;
use strict;
use Games::Tetris::Shape;
our $VERSION = '0.01';

=head1 NAME

Games::Tetris - representation of a tetris game state

=head1 SYNOPSIS

 use Games::Tetris;
 my $well = Games::Tetris->new;
 my $ess = $well->new_shape(' +',
                            '++',
                            '+ ');
 $well->drop( $ess, 3, 1 );
 $well->print;

=head1 DESCRIPTION

This module can be used as the rules engine for the game of tetris.
It allows you to create a well and drop pieces in it.  The well tracks
the status its contents and handles completed line removal.

=head1 METHODS

=head2 new

Creates a new gamestate

Takes the following optional parameters:

C<well> an initial well, an array of arrays.  use undef to indicate an
empty cell, any other value is considered occupied

or

C<width>, C<depth> dimensions of a new well (defaults to 15 x 20)

=cut

sub new {
    my $referent = shift;
    my %args = @_;
    my $class = ref $referent || $referent;

    my $self = bless {}, $class;

    my ($w, $d) = delete @args{ qw{ width depth } };
    if ($self->{_well} = delete $args{well}) {
        # figure out width and depth
        die "I be slack";
    }
    else {
        # make a new well
        $self->{_width} = $w || 15;
        $self->{_depth} = $d || 20;

        $self->{_well} = [ map {
            [ (undef) x $self->width ]
        } 1 .. $self->depth ];
    }

    die "leftover arguments:". join (', ', map {"'$_'"} keys %args)
      if keys %args;
    return $self;
}

sub width { $_[0]->{_width} }
sub depth { $_[0]->{_depth} }
sub well  { $_[0]->{_well} }

=head2 new_shape

delegates to Games::Tetris::Shape->new

=cut

sub new_shape {
    my $self = shift;
    Games::Tetris::Shape->new(@_);
}

=head2 print

used by the testsuite.  prrints the current state of the well

=cut

sub print {
    my $self = shift;
    print "# /", ('-') x $self->width, "\\\n";
    print "# |", join( '', map { $_ ? $_ : ' ' } @$_ ), "|\n"
      for @{ $self->well };
    print "# \\", ('-') x $self->width, "/\n";
}

=head2 ->fits( $shape, $x, $y )

returns a true value if the given shape would fit in the well at the
location C<$x, $y>

=cut

sub fits {
    my $self = shift;
    my ($shape, $at_x, $at_y) = @_;

    for ($shape->covers($at_x, $at_y)) {
        my ($x, $y) = @$_;
        return if ($x < 0 ||
                   $y < 0 ||
                   $x >= $self->width ||
                   $y >= $self->depth ||
                   $self->well->[ $y ][ $x ]);
    }
    return 1;
}

=head2 ->drop( $shape, $x, $y )

returns false if the shape will not fit at the location indicated by
C<$x, $y>

if the shape can be dropped it will be advanced to the bottom of the
well and the return value will be the rows removed by the dropping
operation, if any, as an array reference

=cut

sub drop {
    my $self = shift;
    my ($shape, $at_x, $at_y) = @_;

    return unless $self->fits(@_);
    my $max_y = $at_y;
    for (my $y = $at_y; $y <= $self->depth; $y++) {
        last if !$self->fits( $shape, $at_x, $y );
        $max_y = $y;
    }
    for ($shape->covers($at_x, $max_y)) {
        my ($x, $y, $val) = @$_;
        $self->well->[ $y ][ $x ] = $val;
    }

    my @removed;
    for (my $y = 0; $y < $self->depth; $y++) {
        my $inrow = grep { $_ } @{ $self->well->[$y] };
        next if $inrow != $self->width;
        push @removed, $y;
    }

    splice @{ $self->well }, $_, 1
      for reverse @removed;
    unshift @{ $self->well }, [(undef) x $self->width]
      for @removed;
    return \@removed;
}

1;

__END__

=head1 TODO

=over

=item $shape->rotate

=item Tk/Qt/Wx interface

=item Network Code

=item Watch all tuits go bye bye

=back

=head1 AUTHOR

Richard Clamp <richardc@unixbeard.net>

=head1 COPYRIGHT

Copyright (C) 2003 Richard Clamp.  All Rights Reserved.

This module is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 SEE ALSO

Games::Tetris::Shape

=cut
