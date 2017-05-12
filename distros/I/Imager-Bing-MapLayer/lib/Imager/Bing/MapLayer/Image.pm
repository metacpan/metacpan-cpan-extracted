package Imager::Bing::MapLayer::Image;

use v5.10.1;

use Moose;
use MooseX::StrictConstructor;

use Moose::Util::TypeConstraints;

use Class::MOP::Method;
use Const::Fast;
use Imager;
use Imager::Color;
use Imager::Fill;
use Imager::Fountain;
use List::Util 1.30 qw/ min pairmap /;

use namespace::autoclean;

use version 0.77; our $VERSION = version->declare('v0.1.9');

=head1 NAME

Imager::Bing::MapLayer::Image - a wrapper for L<Imager> objects

=head1 SYNOPSIS

    my $image = Imager::Bing::MapLayer::Image->new(
        pixel_origin => [ $left, $top ],
        width        => 1 + $right - $left,
        height       => 1 + $bottom - $top,
    );

=head1 DESCRIPTION

This module is for internal use by L<Imager::Bing::MapLayer>.

=begin :internal

This is a base class for images that acts as a wrapper around
L<Imager> but automatically translates coordinates from the pixel
origin.

This is mainly used for rendering a large polyline so that sections of
it can be composed onto tiles.

=head1 ATTRIBUTES

=head2 C<pixel_origin>

The coordinates of the top-left point on the image.

=cut

has 'pixel_origin' => (
    is  => 'ro',
    isa => 'ArrayRef',
);

=head2 C<width>

The width of the image.

=cut

has 'width' => (
    is       => 'ro',
    isa      => subtype( as 'Int', where { $_ >= 1 }, ),
    required => 1,
);

=head2 C<height>

The height of the image.

=cut

has 'height' => (
    is       => 'ro',
    isa      => subtype( as 'Int', where { $_ >= 1 }, ),
    required => 1,
);

=head2 C<left>

The left-most point of the C<x> axis of the image.  This corresponds to
the C<x> coordinate of the C</pixel_origin>.

=cut

has 'left' => (
    is      => 'ro',
    isa     => 'Int',
    default => sub {
        my ($self) = @_;
        my $origin = $self->pixel_origin;
        return $origin->[0];
    },
    lazy     => 1,
    init_arg => undef,
);

=head2 C<top>

The top-most point of the C<y> axis on the image.  This corresponds to
the C<y> coordinate of the C</pixel_origin>.

=cut

has 'top' => (
    is      => 'ro',
    isa     => 'Int',
    default => sub {
        my ($self) = @_;
        my $origin = $self->pixel_origin;
        return $origin->[1];
    },
    lazy     => 1,
    init_arg => undef,
);

=head2 C<right>

The rightmost point on the C<x> axis.

=cut

has 'right' => (
    is      => 'ro',
    isa     => 'Int',
    default => sub {
        my ($self) = @_;
        return $self->left + $self->width - 1;
    },
    lazy     => 1,
    init_arg => undef,
);

=head2 C<bottom>

The bottom-most point of the C<y> axis.

=cut

has 'bottom' => (
    is      => 'ro',
    isa     => 'Int',
    default => sub {
        my ($self) = @_;
        return $self->top + $self->height - 1;
    },
    lazy     => 1,
    init_arg => undef,
);

=head2 C<image>

The L<Imager> object.

=cut

has 'image' => (
    is      => 'ro',
    isa     => 'Imager',
    lazy    => 1,
    default => sub {
        my ($self) = @_;

        my $image = Imager->new(
            xsize    => $self->width,
            ysize    => $self->height,
            channels => 4,
        );

        # We draw a transparent white box on the image so as to fix
        # any issues with colour composition.

        $image->box(
            color => Imager::Color->new( 255, 255, 255, 0 ),
            box => [ 0, 0, $self->width - 1, $self->height - 1 ],
        );

        return $image;
    },
    init_arg => undef,
    handles  => [qw/ errstr getwidth getheight /],
);

=head1 METHODS

=head2 C<errstr>

The L<Imager> error string.

=cut

sub _translate_x {
    my ( $self, $x ) = @_;

    my $left = $self->left;

    if ( ref $x ) {
        return [ map { $_ - $left } @{$x} ];
    } else {
        return $x - $left;
    }
}

sub _translate_y {
    my ( $self, $y ) = @_;

    my $top = $self->top;

    if ( ref $y ) {
        return [ map { $_ - $top } @{$y} ];
    } else {
        return $y - $top;
    }
}

sub _translate_points {
    my ( $self, $points ) = @_;
    return [
        map {
            [ $self->_translate_x( $_->[0] ), $self->_translate_y( $_->[1] ) ]
        } @{$points}
    ];
}

sub _translate_coords {
    my ( $self, $points ) = @_;
    no warnings 'once';
    return [ pairmap { ( $self->_translate_x($a), $self->_translate_y($b) ) }
        @{$points} ];
}

const my %ARG_TO_METHOD => (
    points => '_translate_points',

    box => '_translate_coords',

    x   => '_translate_x',
    'y' => '_translate_y',

    x1 => '_translate_x',
    y1 => '_translate_y',
    x2 => '_translate_x',
    y2 => '_translate_y',

    xmin => '_translate_x',
    ymin => '_translate_y',
    xmax => '_translate_x',
    ymax => '_translate_y',

    left => '_translate_x',
    top  => '_translate_y',

    right  => '_translate_x',
    bottom => '_translate_y',

);

sub _translate_point_arguments {
    my ( $self, %args ) = @_;

    my %i_args;

    foreach my $arg ( keys %ARG_TO_METHOD ) {

        if ( my $method = $self->can( $ARG_TO_METHOD{$arg} ) ) {

            $i_args{$arg} = $self->$method( $args{$arg} )
                if ( exists $args{$arg} );

        }

    }

    return %i_args;
}

=head2 C<_make_imager_wrapper_method>

Rather than have a lot of cut-and-paste code for wrappers to L<Imager>
methods, we have a L<Moose> method for creating new methods.

These methods translate the C<points>, C<x> and C<y> arguments for the
level into coordinates on the tile, and then run the corresponding
L<Imager> methods on the tile.

=cut

sub _make_imager_wrapper_method {
    my ( $class, $opts ) = @_;

    $opts->{args} //= [];

    $class->meta->add_method(

        $opts->{name} => sub {

            my ( $self, %args ) = @_;

            my %imager_args = $self->_translate_point_arguments(%args);

            foreach my $arg ( @{ $opts->{args} } ) {
                $imager_args{$arg} = $args{$arg} if ( exists $args{$arg} );
            }

            my $method = Imager->can( $opts->{name} );

            return wantarray
                ? ( $self->image->$method(%imager_args) )
                : $self->image->$method(%imager_args);

        },
    );

}

# TODO test copy, crop, paste and compose etc.

=head2 C<copy>

=cut

__PACKAGE__->_make_imager_wrapper_method( { name => 'copy', } );

=head2 C<crop>

=cut

__PACKAGE__->_make_imager_wrapper_method(
    {   name => 'crop',
        args => [qw/ width height /],
    }
);

=head2 C<paste>

=cut

__PACKAGE__->_make_imager_wrapper_method(
    {   name => 'paste',
        args => [
            qw/ width height src img combine src_minx src_miny src_maxx src_maxy /
        ],
    }
);

=head2 C<compose>

=cut

__PACKAGE__->_make_imager_wrapper_method(
    {   name => 'compose',
        args => [
            qw/ width height src combine opacity mask src_minx src_miny src_maxx src_maxy /
        ],
    }
);

=head2 C<getpixel>

This method used mainly for testing, and may not be usable from the
L<Imager::Bing::MapLayer::Level> and
L<Imager::Bing::MapLayer> objects that this tile belongs to.

=cut

__PACKAGE__->_make_imager_wrapper_method( { name => 'getpixel', } );

=head2 C<setpixel>

=cut

__PACKAGE__->_make_imager_wrapper_method(
    {   name => 'setpixel',
        args => [qw/ color /],
    }
);

=head2 C<line>

=cut

__PACKAGE__->_make_imager_wrapper_method(
    {   name => 'line',
        args => [qw/ color endp aa antialias /],
    }
);

=head2 C<box>

=cut

__PACKAGE__->_make_imager_wrapper_method(
    {   name => 'box',
        args => [qw/ color filled fill /],
    }
);

=head2 C<polyline>

=cut

__PACKAGE__->_make_imager_wrapper_method(
    {   name => 'polyline',
        args => [qw/ color aa antialias /],
    }
);

=head2 C<polygon>

=cut

__PACKAGE__->_make_imager_wrapper_method(
    {   name => 'polygon',
        args => [qw/ color fill /],
    }
);

=head2 C<arc>

=cut

__PACKAGE__->_make_imager_wrapper_method(
    {   name => 'arc',
        args => [qw/ r d1 d2 color fill aa filled /],
    }
);

=head2 C<circle>

=cut

__PACKAGE__->_make_imager_wrapper_method(
    {   name => 'circle',
        args => [qw/ r color fill aa filled /],
    }
);

=head2 C<flood_fill>

=cut

__PACKAGE__->_make_imager_wrapper_method(
    {   name => 'flood_fill',
        args => [qw/ color border fill /],
    }
);

=head2 C<string>

=cut

__PACKAGE__->_make_imager_wrapper_method(
    {   name => 'string',
        args => [
            qw/ string font aa align channel color size sizew utf8 vlayout text /
        ],
    }
);

=head2 C<align_string>

=cut

__PACKAGE__->_make_imager_wrapper_method(
    {   name => 'align_string',
        args => [
            qw/ string font aa valign halign channel color size sizew utf8 vlayout text /
        ],
    }
);

=head2 C<radial_circle>

Draw a fuzzy, "radial" greyscale circle: used for plotting points in a
heatmap.  When all radial circles have been plotted, the L</colourise>
method should be run.

=cut

sub radial_circle {
    my ( $self, %args ) = @_;

    my $center_x = $args{x};
    my $center_y = $args{y};
    my $radius   = $args{r};

    state $palette;

    unless ($palette) {

        my $shades = 20;

        my ( @palette, @positions );

        foreach my $i ( 0 .. $shades ) {
            my $alpha = $i ? int( sqrt( ( $i / $shades ) ) * 96 ) : 0;
            my $val = $i ? int( ( 1 - $i / $shades ) * 128 ) + 128 : 255;
            unshift @palette, Imager::Color->new( ($val) x 3, $alpha, );
            push @positions, ( $i / $shades );
        }

        $palette = Imager::Fountain->simple(
            positions => \@positions,
            colors    => \@palette,
        );

    }

    my $fill = Imager::Fill->new(
        fountain     => 'radial',
        segments     => $palette,
        xa           => $radius,
        ya           => $radius,
        xb           => 0,
        yb           => $radius,
        super_sample => 'circle',
    );

    if ( my $diam = ( $radius + $radius ) ) {

        my $circle = Imager->new(
            xsize    => $diam,
            ysize    => $diam,
            channels => 4
        );

        $circle->circle(
            r      => $radius,
            x      => $radius,
            'y'    => $radius,
            aa     => 1,
            filled => 1,
            fill   => $fill,
        );

        $self->compose(
            src     => $circle,
            tx      => $center_x - $radius,
            ty      => $center_y - $radius,
            combine => 'normal',              # TODO change this?
        );
    }
}

# TODO/FIXME - generic method with callbacks to apply a function to a tile?

=head2 C<colourise>

=head2 C<colorize>

    $tile->colourise();

The method colourises greyscale tiles.

It is intended to be run for all tiles on a map when the rendering is
completed.

Note that the the color of a pixel is determined by the opacity of the
the pixel, and not the gray level.

=cut

sub colourise {
    my ( $self, %args ) = @_;

    state $colorize = {};

    my $img = $self->image;

    foreach my $y ( 0 .. $img->getheight - 1 ) {

        my @colors = $img->getscanline( 'y' => $y );
        for ( my $i = 0; $i < @colors; $i++ ) {

            my $a = ( $colors[$i]->rgba )[-1];

            $colorize->{$a} //= Imager::Color->new(
                hue => int( ( ( 255 - $a ) / 255 ) * 240 ),
                saturation => 1.0,
                value      => 1.0,
                alpha      => min( $a, 128 ),
            );

            $colors[$i] = $colorize->{$a};

        }

        $img->setscanline( 'y' => $y, pixels => \@colors );

    }

    return 1;
}

sub colorize {
    my ( $self, %args ) = @_;
    $self->colourise(%args);
}

=end :internal

=cut

use namespace::autoclean;

1;
