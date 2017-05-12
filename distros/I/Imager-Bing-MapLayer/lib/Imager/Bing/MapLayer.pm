package Imager::Bing::MapLayer;

use v5.10.1;

use Moose;
with 'Imager::Bing::MapLayer::Role::TileClass';
with 'Imager::Bing::MapLayer::Role::FileHandling';
with 'Imager::Bing::MapLayer::Role::Centroid';
with 'Imager::Bing::MapLayer::Role::Misc';

use Carp qw/ confess /;
use Class::MOP::Method;
use Const::Fast;
use Moose::Util::TypeConstraints;
use MooseX::StrictConstructor;

use Imager::Bing::MapLayer::Utils qw/
    $MIN_ZOOM_LEVEL $MAX_ZOOM_LEVEL
    /;

use Imager::Bing::MapLayer::Level;

=head1 NAME

Imager::Bing::MapLayer - create a map layer for Bing Maps

=cut

use version 0.77; our $VERSION = version->declare('v0.1.9');

=head1 SYNOPSIS

    my $layer = Imager::Bing::MapLayer->new(
      base_dir           => $dir,     # base directory (default '.')
      overwrite          => 1,        # overwrite existing (default)
      autosave           => 1,        # save on exit (default)
      in_memory          => 0,        # keep tiles in memory (default false)
      min_level          => 1,        # min zoom level (default)
      max_level          => 19,       # max zoom level (default)
      combine            => 'darken', # tile composition method (default)
    );

    # Plot polygons (e.g. geographic boundaries)

    $layer->polygon(
       points => $points,                  # listref to [ lat, lon ] points
       fill   => Imager::Fill->new( ... ), #
    );

    # Plot greyscale gradient circles for heatmaps

    $layer->radial_circle(
        r      => 100,              # radius in meters
        -min_r => 1,                # minimum pixel radius for any zoom level
        x      => $longitude,       # longitude (x = east-west)
        y      => $latitude,        # latitude  (y = north-south)
    );

    # Blur filter

    $layer->filter( type => 'gaussian', stddev => 1 );

    # Colourise greyscale heatmaps

    $layer->colourise();

=head1 DESCRIPTION

This module is a wrapper around the L<Imager::Draw> module, which
allows you to create Bing map layers using longitude and latitude
coordinates.

The module will automatically map them to the appropriate points on
tile files.

=for readme stop

It adds the following options to drawing methods:

=over

=item C<-min_level>

The minimum zoom level to draw on.

=item C<-max_level>

The maximum zoom level to draw on.

=back

=head1 ATTRIBUTES

=head2 C<in_memory>

The timeout for how many seconds a tile is kept in memory. The default
is C<0>.

When a tile is timed out, it is saved to disk after each L<Imager> drawing
operation, and reloaded if it is later needed.

Setting this to a non-zero value keeps tiles in memory, but increases
the memory requirements.

=head2 C<centroid_latitude>

=head2 C<centroid_longitude>

This is the centroid latitude and longitude for translating
points to pixels.  It defaults to a point in London.

You can probably get away with ignoring this, but if you are
generating maps for different regions of the world, then you may
consider changing this, or even maininging different map sets with
different centroids.

=head2 C<overwrite>

When true (default), existing tiles will be overwritten rather than
edited.

Be wary of editing existing tiles, since antialiased lines and opaque
fills will darken existing points rather than drawing over them.

=head2 C<autosave>

When true (default), tiles will be automatically saved.

Alternatively, you can use the L</save> method to manually save tiles.

Note that any times in memory when a script is interrupted may be
lost. An alternative to add something to trap interruptions:

  local $SIG{INT} = sub {
      state $int = 0;
      unless ($int) {
          $int=1;
          $image->save();
      }
      exit 1;
  };

=head2 C<combine>

The tile combination method. It defaults to C<darken>.

=head2 C<tile_class>

The base class used for tiles.

This can be used to subclass the tiles, for instance, to save tiles
with a different filename to use with something other than Bing maps,
e.g. Google Maps.

You might use something like:

  package MyTile;

  use Moose;
  extends 'Imager::Bing::MapLayer::Tile';

  use Path::Class;

  override 'build_filename' => sub {
    my ($self) = @_;
    my $file = file($self->base_dir, $self->level,
	            join(',', @{ $self->tile_coords }) . '.png');
    return $file->stringify;
  };

=cut

=head1 METHODS

=head2 C<levels>

  my @levels = @{ $layer->levels };

This returns a reference to a list of
L<Imager::Bing::MapLayer::Level> objects.

=cut

has 'levels' => (
    is      => 'ro',
    isa     => 'ArrayRef',
    lazy    => 1,
    default => sub {
        my ($self) = @_;

        confess "min_level > max_level"
            if ( $self->min_level > $self->max_level );

        my @levels;

        foreach my $level ( $self->min_level .. $self->max_level ) {
            push @levels,
                Imager::Bing::MapLayer::Level->new(
                level               => $level,
                base_dir            => $self->base_dir,
                centroid_latitude   => $self->centroid_latitude,
                centroid_longitude  => $self->centroid_longitude,
                overwrite           => $self->overwrite,
                autosave            => $self->autosave,
                in_memory           => $self->in_memory,
                combine             => $self->combine,
                tile_class          => $self->tile_class,
                _max_buffer_breadth => $self->_max_buffer_breadth,
                );
        }

        return \@levels;
    },
    init_arg => undef,
);

=head2 C<min_level>

The minimum zoom level to generate.

=cut

has 'min_level' => (
    is  => 'ro',
    isa => subtype(
        as 'Int',
        where { ( $_ >= $MIN_ZOOM_LEVEL ) && ( $_ <= $MAX_ZOOM_LEVEL ) }
    ),
    default => sub {$MIN_ZOOM_LEVEL},
);

=head2 C<max_level>

The maximum zoom level to generate.

=cut

has 'max_level' => (
    is  => 'ro',
    isa => subtype(
        as 'Int',
        where { ( $_ >= $MIN_ZOOM_LEVEL ) && ( $_ <= $MAX_ZOOM_LEVEL ) }
    ),
    default => sub {$MAX_ZOOM_LEVEL},
);

=begin :internal

=head2 <_max_buffer_breadth>

The maximum width and height of the temporary L<Imager> image.

Generally, you do not need to be concerned with this parameter, unless
you get C<malloc> errors when rendering tiles.

=cut

has '_max_buffer_breadth' => (
    is      => 'ro',
    isa     => 'Int',
    default => 1024 * 4,    #
);

=head2 C<_make_imager_wrapper_method>

    __PACKAGE__->_make_imager_wrapper_method( { name => $method } );

This is an I<internal> method for generating wrapper L<Imagers::Draw>
methods that are applied to every level.

These methods use latitude and longitude in lieau of C<y> and C<x>
parameters.  Note that C<points> parameters contain pairs of latitude
and longitude coordinates, I<not> longitude and latitude coordinates!

See L<Imager::Draw> for documentation of the methods.

We've added the following additional arguments:

=over

=item C<-min_level>

The minimum zoom level to draw on.

=item C<-max_level>

The maximum zoom level to draw on.

=back

=end :internal

=cut

sub _make_imager_wrapper_method {
    my ( $class, $opts ) = @_;

    $opts->{args} //= [];

    $class->meta->add_method(

        $opts->{name} => sub {

            my ( $self, %args ) = @_;

            foreach my $level ( @{ $self->levels } ) {

                my $method = $level->can( $opts->{name} );

                $level->$method(%args);

            }

            }

    );
}

=head2 C<radial_circle>

    $layer->radial_circle(
        r      => $radius_in_meters,
        -min_r => $min_radius_in_pixels,
        x      => $longitude,
        y      => $latitude,
    );

This method plots "fuzzy" greyscale circles, which are intended to be
used for heatmaps.  The radius is scaled appropriately for each zoom
level in the layer.

If C<-min_r> is specified, then a circle will always be drawn with
that minimum radius: this ensures that lower zoom levels will always
have a point plotted.

=head2 C<colourise>

=head2 C<colorize>

    $layer->colourise();

The method colourises greyscale layers.  It is intended to be used for
heatmaps generated using the L</radial_circle> method.

=head2 C<filter>

    $layer->filter( type => 'gaussian', stddev => 1 );

This applies L<Imager::Filters> to every tile on every zoom level of the layer.

Be aware that some filter effects may enhance the edges of tiles in
each zoom level.

=head2 C<setpixel>

Draw a pixel at a specific latitude and longitude coordinate.

See the corresponding method in L<Imager::Draw> for more information.

=head2 C<line>

Draw a line between two coordinates.

See the corresponding method in L<Imager::Draw> for more information.

=head2 C<box>

Draw a box bounded by northwest and southeast coordinates.

See the corresponding method in L<Imager::Draw> for more information.

=head2 C<polyline>

Draw a polyline for a set of coordinates.

Note that a polyline is not closed. To draw a closed area, use the
L</polygon> method.

See the corresponding method in L<Imager::Draw> for more information.

=head2 C<polygon>

Draw a closed polygon for a set of coordinates.

See the corresponding method in L<Imager::Draw> for more information.

=head2 C<arc>

Draw an arc.

See the corresponding method in L<Imager::Draw> for more information.

=head2 C<circle>

Draw a circle.

See the corresponding method in L<Imager::Draw> for more information.

=head2 C<string>

Draw a text string.

TODO - the size is not scaled.

See the corresponding method in L<Imager::Draw> for more information.

=head2 C<align_string>

Draw an aligned text string.

TODO - the size is not scaled.

See the corresponding method in L<Imager::Draw> for more information.

=cut

foreach my $method (
    qw/
    radial_circle colourise colorize
    filter setpixel line box polyline polygon arc circle flood_fill
    string align_string
    /
    )
{

    __PACKAGE__->_make_imager_wrapper_method( { name => $method } );

}

=head2 C<save>

Save the tiles.

=cut

sub save {
    my ( $self, @args ) = @_;

    foreach my $level ( @{ $self->levels } ) {
        $level->save(@args);
    }
}

=head1 VIEWING MAP LAYERS

=head2 Bing Maps

You can view tiles using the following web page, replacing the
C<credentials> option with your Bing Maps Key:

  <!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN"
  "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
  <html xmlns="http://www.w3.org/1999/xhtml" xmlns:v="urn:schemas-microsoft-com:vml"
        xml:lang="en" lang="en">
    <head>
      <title>Tiles Test</title>
      <script src="http://ecn.dev.virtualearth.net/mapcontrol/mapcontrol.ashx?v=7.0&mkt=en-gb"></script>
      <script>
       //<![CDATA[
       var map;
       function init(){
         var map_options = {
           credentials         : "YOUR BING MAPS KEY HERE",
           center              : new Microsoft.Maps.Location(51.5171, 0.1062),
           zoom 	       : 10,
           showMapTypeSelector : false,
           useInertia          : true,
           inertiaIntensity    : 0,
           tileBuffer          : 1,
           enableSearchLogo    : false,
           enableClickableLogo : false,
           showScalebar        : false
         }
         map = new Microsoft.Maps.Map(document.getElementById('mapviewer'), map_options);
         addDefaultTileLayer();
       }

       function addDefaultTileLayer(){
         var options = { uriConstructor: 'tiles/{quadkey}.png' };
         var tileSource = new Microsoft.Maps.TileSource(options);
         var tilelayer= new Microsoft.Maps.TileLayer({ mercator: tileSource });
         map.entities.push(tilelayer);
       }
      // ]]>
      </script>
    </head>
    <body onload="init();">
      <div id="mapviewer" style="position:relative;width:100%;height:700px;"></div>
    </body>
  </html>

You can apply for a Bing Maps Key at L<https://www.bingmapsportal.com>.

=for readme continue

=head1 SEE ALSO

=over

* Bing Maps Tile System

L<http://msdn.microsoft.com/en-us/library/bb259689.aspx>

=back

=head1 AUTHOR

Robert Rothenberg, C<< <rrwo at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to the author, or through
the web interface at
L<https://github.com/robrwo/Imager-Bing-MapLayer/issues>.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Imager::Bing::MapLayer

You can also look for information at:

=over 4

=item * GitHub

L<https://github.com/robrwo/Imager-Bing-MapLayer>

=back

=head1 ACKNOWLEDGEMENTS

=over

=item *

Foxtons, Ltd.

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2013-2014 Robert Rothenberg.

This program is released under the following license: atistic2

=cut

use namespace::autoclean;

1;    # End of Imager::Bing::MapLayer
