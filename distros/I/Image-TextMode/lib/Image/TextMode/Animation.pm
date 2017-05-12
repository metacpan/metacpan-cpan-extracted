package Image::TextMode::Animation;

use Moo;
use Types::Standard qw( ArrayRef );
use Symbol ();

BEGIN {
    for my $sub (
        qw( getpixel getpixel_obj putpixel clear_screen clear_line ) )
    {
        *{ Symbol::qualify_to_ref( __PACKAGE__ . "\::$sub" ) } = sub {
            shift->frames->[ -1 ]->$sub( @_ );
            }
    }
}

=head1 NAME

Image::TextMode::Animation - A base class for text mode animation file formats

=head1 DESCRIPTION

This class should be used for any format that requires a sequence of frames
for display.

=head1 ACCESSORS

=over 4

=item * frames - an arrayref of frame objects

=back

=cut

has 'frames' => ( is => 'rw', lazy => 1, isa => ArrayRef, default => sub { [] } );

=head1 METHODS

=head2 new( %args )

Creates a new instance.

=head2 add_frame( $frame )

Adds a frame to the end of the array.

=cut

sub add_frame {
    my ( $self, $frame ) = @_;
    push @{ $self->frames }, $frame;
}

=head2 width( )

Returns the largest frame width.

=cut

sub width {
    my $self = shift;
    my @widths = sort { $b <=> $a } map { $_->width } @{ $self->frames };
    return $widths[ 0 ];
}

=head2 height( )

Returns the largest frame height.

=cut

sub height {
    my $self = shift;
    my @heights = sort { $b <=> $a } map { $_->height } @{ $self->frames };
    return $heights[ 0 ];
}

=head2 dimensions( )

Returns the a list containing the values of C<width> and C<height>.

=cut

sub dimensions {
    my $self = shift;
    return $self->width, $self->height;
}

=head2 as_ascii( )

Returns all of the text from all of the frames.

=cut

sub as_ascii {
    my $self = shift;
    return join( "\n", map { $_->as_ascii } @{ $self->frames } );
}

=head1 PROXIED METHODS

The following methods are proxies to the last element in C<frames>.

=over 4

=item * getpixel

=item * getpixel_obj

=item * putpixel

=item * clear_screen

=item * clear_line

=back

=head1 AUTHOR

Brian Cassidy E<lt>bricas@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2008-2015 by Brian Cassidy

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut

1;
