package Imager::Bing::MapLayer::Tile;

use Moose;
with 'Imager::Bing::MapLayer::Role::FileHandling';

use MooseX::StrictConstructor;
use Moose::Util::TypeConstraints;

extends 'Imager::Bing::MapLayer::Image';

use Carp qw/ carp confess /;
use Class::MOP::Method;
use Imager;
use List::Util 1.30 qw/ pairmap /;
use Path::Class qw/ file /;

use Imager::Bing::MapLayer::Utils qw/
    $MIN_ZOOM_LEVEL $MAX_ZOOM_LEVEL
    $TILE_WIDTH $TILE_HEIGHT
    width_at_level
    pixel_to_tile_coords tile_coords_to_pixel_origin
    tile_coords_to_quad_key quad_key_to_tile_coords
    /;

use version 0.77; our $VERSION = version->declare('v0.1.9');

=head1 SYNOPSIS

   my $tile = Imager::Bing::MapLayer::Tile->new(
       quad_key  => $key,       # the "quad key" for the tile
       base_dir  => $base_dir,  # the base directory for tiles (defaults to cwd)
       overwrite => 1,          # overwrite existing tile (default) vs load it
       autosave  => 1,          # automatically save tile when done (default)
    );

=head1 DESCRIPTION

This is the the base tile class for L<Imager::Bing::MapLayer>. It is
intended for internal use, but can be subclassed as needed.

=head1 ATTRIBUTES

=head2 C<quad_key>

The quadrant key of the tile.

=cut

has 'quad_key' => (
    is  => 'ro',
    isa => subtype(
        as 'Str', where {qr/^[0-3]{$MIN_ZOOM_LEVEL,$MAX_ZOOM_LEVEL}$/},
    ),
    required => 1,
);

=head2 C<level>

The zoom level for this tile.  It is determined by the L</quad_key>.

=cut

has 'level' => (
    is      => 'ro',
    isa     => 'Int',
    default => sub {
        my ($self) = @_;
        return length( $self->quad_key );
    },
    lazy     => 1,
    init_arg => undef,
);

=head2 C<tile_coords>

The tile coordinates of this tile. They are determined by the
L</quad_key>.

=cut

has 'tile_coords' => (
    is      => 'ro',
    isa     => 'ArrayRef',
    default => sub {
        my ($self) = @_;
        return [ ( quad_key_to_tile_coords( $self->quad_key ) )[ 0, 1 ] ],;
    },
    lazy     => 1,
    init_arg => undef,
);

=head2 C<pixel_origin>

The coordinates of the top-left point on the tile. They are determined
by the L</quad_key>.

=cut

has 'pixel_origin' => (
    is      => 'ro',
    isa     => 'ArrayRef',
    default => sub {
        my ($self) = @_;
        my $tile_coords = $self->tile_coords;
        return [ tile_coords_to_pixel_origin( @{$tile_coords} ) ],;
    },
    lazy     => 1,
    init_arg => undef,
);

=head2 C<width>

The width of the tile.

=cut

has 'width' => (
    is       => 'ro',
    default  => $TILE_WIDTH,
    lazy     => 1,
    init_arg => undef,
);

=head2 C<height>

The height of the tile.

=cut

has 'height' => (
    is       => 'ro',
    default  => $TILE_HEIGHT,
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

        my $file = $self->filename;

        if ( -s $file ) {

            if ( $self->overwrite ) {

                unlink $file
                    or carp
                    sprintf( "Could not remove file '%s': %s", $file, $! );

            } else {

                $image->read( file => $file )
                    or confess sprintf( "Cannot read file '%s': %s",
                    $file, $image->errstr );

            }

        }

        return $image;
    },
    init_arg => undef,
);

=head2 C<filename>

The full pathname of the tile, when saved.

=cut

has 'filename' => (
    is       => 'ro',
    isa      => 'Str',
    lazy     => 1,
    builder  => 'build_filename',
    init_arg => undef,
);

=head1 METHODS

=head2 C<build_filename>

This method returns the default filename of the tile, which consists
of the L</base_dir> and L</quad_key>.  It can be overridden in
subclasses for map systems that require alternative filenames.

=cut

sub build_filename {
    my ($self) = @_;
    return file( $self->base_dir, $self->quad_key . '.png' )->stringify;
}

=head2 C<latlon_to_pixel>

Translate latitude and longitude to a pixel on this zoom level.

=cut

sub latlon_to_pixel {
    my ( $self, @latlon ) = @_;
    return Imager::Bing::MapLayer::Utils::latlon_to_pixel( $self->level,
        @latlon );
}

=head2 C<latlons_to_pixels>

Translate a list reference of latitude and longitude coordinates to
pixels on this zoom level.

=cut

sub latlons_to_pixels {
    my ( $self, $latlons ) = @_;
    return [ map { [ $self->latlon_to_pixel( @{$_} ) ] } @{$latlons} ];
}

=head2 C<save>

Save this tile.

=cut

sub save {
    my ($self) = @_;

    # Only save an image if there's something on it

    if ( $self->image->getcolorusage ) {
        $self->image->write( file => $self->filename );
    }
}

=begin :internal

=head2 C<DEMOLISH>

This method auto-saves the tile, if L</autosave> is enabled.

=end :internal

=cut

sub DEMOLISH {
    my ($self) = @_;
    $self->save if ( $self->autosave );
}

use namespace::autoclean;

1;
