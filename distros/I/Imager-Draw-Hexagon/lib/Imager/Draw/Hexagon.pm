package Imager::Draw::Hexagon;
$Imager::Draw::Hexagon::VERSION = '0.0102';
use strict;
use Moo;
use Imager;


=head1 NAME

Imager::Draw::Hexagon - Draw hexes easily using Imager

=head1 VERSION

version 0.0102

=head1 SYNOPSIS

 use Imager::Draw::Hexagon;

 my $hex = Imager::Draw::Hexagon->new( image => $image, side_length => 100 );
 $hex->draw(color => 'blue');

=head1 DESCRIPTION

Drawing hexagons requires calculating all the points in the hex. It's harder than it sounds. I figured since I was solving it, I might as well solve it for everyone, so this module was born.

=head1 METHODS

=head2 new(image => $image, side_length => 100)

Constructor.

=over

=item image

The L<Imager> object to draw the hex on to. Required.

=item side_length

The length of each side of the hexagon in pixels. Required.

=item x

The x coordinate of the top left corner to start drawing the hex. Defaults to 0.

=item y

The y coordinate of the top left corner to start drawing the hex. Defaults to 0.

=back

=cut

=head2 x()

Get or set the x coordinate of the top left corner of where to start drawing the hex.

=cut

has x => (
    is          => 'rw',
    default     => sub { 0 },
);

=head2 y()

Get or set the y coordinate of the top left corner of where to start drawing the hex.

=cut

has y => (
    is          => 'rw',
    default     => sub { 0 },
);

=head2 image()

Get or set the L<Imager> object.

=cut

has image => (
    is          => 'rw',
    required    => 1,
);

=head2 side_length()

Get or set the length, in pixels, of each side of the hex.

=cut

has side_length => (
    is          => 'rw',
    required    => 1,
);

=head2 short_leg()

Hexes are essentially a square with a series of right trangles drawn around them. This is the short leg of that triangle or half the value of the side length.

=cut

sub short_leg {
    my $self = shift;
    return $self->side_length * 0.5;
}

=head2 long_leg()

Hexes are essentially a square with a series of right trangles drawn around them. This is the long leg of that triangle or the side length multiplied by 0.866 (sin(60)).

=cut

sub long_leg {
    my $self = shift;
    return $self->side_length * 0.866; # sin(60)
}

=head2 ew_coords()

Returns an array ref of coordinent pairs if the hex is to be drawn with a flat top (east-west).

=cut

sub ew_coords {
    my $self = shift;
    return [
        [ int($self->x), int($self->y + $self->long_leg) ],
        [ int($self->x + $self->short_leg), int($self->y) ],
        [ int($self->x + $self->short_leg + $self->side_length), int($self->y) ],
        [ int($self->x + (2 * $self->side_length)), int($self->y + $self->long_leg) ],
        [ int($self->x + $self->short_leg + $self->side_length), int($self->y + (2 * $self->long_leg)) ],
        [ int($self->x + $self->short_leg), int($self->y + (2 * $self->long_leg)) ],
    ];
}

=head2 ns_coords()

Returns an array ref of coordinent pairs if the hex is to be drawn with a peaked top (north-south).

=cut

sub ns_coords {
    my $self = shift;
    return [
        [ int($self->x), int($self->y + $self->short_leg) ],
        [ int($self->x + $self->long_leg), int($self->y) ],
        [ int($self->x + (2 * $self->long_leg)), int($self->y + $self->short_leg) ],
        [ int($self->x + (2 * $self->long_leg)), int($self->y + $self->short_leg + $self->side_length) ],
        [ int($self->x + $self->long_leg), int($self->y + (2 * $self->side_length)) ],
        [ int($self->x), int($self->y + $self->short_leg + $self->side_length) ],
    ];
}

=head2 outline()

Call this to draw an outline of a hex on the image. It accepts all the same parameters as L<Imager::Draw/polyline>, plus:

=over

=item direction

Defaults to C<ew>. Options are C<ew> and C<ns>. 

=back

=cut

sub outline {
    my $self = shift;
    my %params = @_;
    $params{points} = (exists $params{direction} && $params{direction} eq 'ns') ? $self->ns_coords : $self->ew_coords;
    delete $params{direction};
    push @{$params{points}}, $params{points}[0];
    $self->image->polyline(%params);
}

=head2 draw()

Call this to draw a filled hex on the image. It accepts all the same parameters as L<Imager::Draw/polygon>, plus:

=over

=item direction

Defaults to C<ew>. Options are C<ew> and C<ns>. 

=back

=cut

sub draw {
    my $self = shift;
    my %params = @_;
    $params{points} = (exists $params{direction} && $params{direction} eq 'ns') ? $self->ns_coords : $self->ew_coords;
    delete $params{direction};
    $self->image->polygon(%params);
}

=head1 TODO

None that I can think of at this time.

=head1 PREREQS

L<Moo>
L<Imager>

=head1 SUPPORT

=over

=item Repository

L<http://github.com/rizen/Imager-Draw-Hexagon>

=item Bug Reports

L<http://github.com/rizen/Imager-Draw-Hexagon/issues>

=back


=head1 AUTHOR

=over

=item JT Smith <jt_at_plainblack_dot_com>

=back

=head1 LEGAL

Imager::Draw::Hexagon is Copyright 2014 Plain Black Corporation (L<http://www.plainblack.com>) and is licensed under the same terms as Perl itself.

=cut

1;
