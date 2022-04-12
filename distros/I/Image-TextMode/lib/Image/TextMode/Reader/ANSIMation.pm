package Image::TextMode::Reader::ANSIMation;

use Moo;
use Image::TextMode::Canvas;

extends 'Image::TextMode::Reader::ANSI';

sub _read {
    my ( $self, $animation, @args ) = @_;
    $animation->add_frame( Image::TextMode::Canvas->new );
    $self->SUPER::_read( $animation, @args );
}

sub set_position {
    my ( $self, @args ) = @_;

    if ( ( $args[ 0 ] || 1 ) == 1 && ( $args[ 1 ] || 1 ) == 1 ) {
        $self->next_frame;
    }

    $self->SUPER::set_position( @args );
}

sub next_frame {
    my $self      = shift;
    my $animation = $self->image;

    return unless $animation->frames->[ -1 ]->height;

    $animation->add_frame( Image::TextMode::Canvas->new );
}

=head1 NAME

Image::TextMode::Reader::ANSIMation - Reads ANSI Animation files

=head1 DESCRIPTION

Provides reading capabilities for the ANSIMation format. This module
extends the ANSI reader, and simply creates a new frame for every
C<set_position(0,0)> command executed.

=head1 METHODS

=head2 set_position( [$x, $y] )

We use this method as a clue that we're starting a new frame if $x and $y are
both 1, which is the default.

=head2 next_frame( )

Adds a new frame to the stack.

=head1 AUTHOR

Brian Cassidy E<lt>bricas@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2008-2022 by Brian Cassidy

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut

1;
