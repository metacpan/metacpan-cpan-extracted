
=head1 NAME

Geo::Google::StaticMaps - API for generating URLs for static Google Maps

=head1 SYNOPSIS

    use Geo::Google::StaticMaps;
    
    my $url = Geo::Google::StaticMaps->url(
        key => "your Google Maps API key",
        size => [ 400, 300 ],
        center => [ 51.855970, 0.958499 ],
        zoom => 13,
    );

=cut

package Geo::Google::StaticMaps;

use strict;
use warnings;
use Carp;
use vars qw($VERSION);

$VERSION = 0.10;

sub new {
    my ($class, %opts) = @_;

    my $self = { %opts };

    return bless $self, $class;
}

sub url {
    my ($self, %opts) = @_;

    if (ref $self) {
        Carp::croak("Can't pass options when url is used as an instance method") if %opts;
        %opts = %$self;
    }

    return _make_url(_normalize_opts(%opts));
}

sub _normalize_opts {
    my %opts = @_;

    my $format = delete($opts{format}) || "png";
    my $maptype = delete($opts{maptype});
    my $size = _normalize_size(delete($opts{size}));
    my $markers = _normalize_markers(delete($opts{markers}));
    my $paths = _normalize_paths(delete($opts{path}));
    my $center = _normalize_point(delete($opts{center}));
    my $zoom = delete($opts{zoom});
    my $span = _normalize_point(delete($opts{span}));
    my $frame = delete($opts{frame});
    $frame = ($frame ? 1 : 0) if defined $frame;
    my $hl = delete($opts{hl});
    my $key = delete($opts{key});

    Carp::croak("Must supply a Google Maps API Key") unless $key;
    Carp::croak("Must give the map size") unless $size;
    Carp::croak("Unsupported options: ".join(', ', keys %opts)) if %opts;

    return (
        format => $format,
        maptype => $maptype,
        size => $size,
        markers => $markers,
        paths => $paths,
        center => $center,
        zoom => $zoom,
        span => $span,
        frame => $frame,
        hl => $hl,
        key => $key,
    );

}

sub _normalize_markers {
    my $markers = shift;

    return undef unless defined $markers;

    if (ref $markers ne 'ARRAY') {
        return [ _normalize_marker($markers) ];
    }
    else {
        return [ map { _normalize_marker($_) } @$markers ];
    }
}

sub _normalize_points {
    my $points = shift;

    return undef unless defined $points;

    if (ref $points ne 'ARRAY') {
        return [ _normalize_point($points) ];
    }
    else {
        return [ map { _normalize_point($_) } @$points ];
    }
}

sub _normalize_paths {
    my $paths = shift;

    return undef unless defined $paths;

    if (ref $paths ne 'ARRAY') {
        return [ _normalize_path($paths) ];
    }
    else {
        return [ map { _normalize_path($_) } @$paths ];
    }
}

sub _normalize_marker {
    my $marker = shift;

    return undef unless defined $marker;

    if (ref $marker eq 'ARRAY') {
        $marker = {
            point => $marker,
        };
    }

    my %opts = %$marker;

    my $point = _normalize_point(delete($opts{point}));

    my $lat = delete($opts{lat});
    my $lon = delete($opts{lon});

    if (defined($lat) || defined($lon)) {
        Carp::croak("Must give both lat and lon") unless defined($lat) && defined($lon);
        Carp::croak("Can't give both point and separate lat and lon") if defined($point);
        $point = _normalize_point([ $lat, $lon ]);
    }

    my $size = delete($opts{size}) || "normal";
    my $color = delete($opts{color}) || "red";
    my $letter = delete($opts{letter}) || "";

    return {
        point => $point,
        size => $size,
        color => $color,
        letter => $letter,
    };
}

sub _normalize_path {
    my $path = shift;

    return undef unless defined $path;

    my %opts = %$path;

    my $points = _normalize_points(delete($opts{points}));
    my $weight = delete($opts{weight}) || 5;
    my $color = _normalize_color(delete($opts{color})) || "rgb:0x0000ff";

    return {
        points => $points,
        weight => $weight,
        color => $color,
    };

}

sub _normalize_point {
    my $point = shift;

    return undef unless defined $point;

    my ($lat, $lon);

    if (ref $point eq 'ARRAY') {
        ($lat, $lon) = @$point;
    }
    else {
        $lat = $point->{lat};
        $lon = $point->{lon};
    }

    return [ $lat, $lon ];
}

sub _normalize_size {
    my $dimensions = shift;

    return undef unless defined $dimensions;

    my ($width, $height);

    if (ref $dimensions eq 'ARRAY') {
        ($width, $height) = @$dimensions;
    }
    else {
        $width = $dimensions->{width};
        $height = $dimensions->{height};
    }

    return [ $width, $height ];
}

sub _normalize_color {
    my $color = shift;

    return undef unless defined $color;

    if (ref $color eq '') {
        # User passed it in as a string in a format suitable for direct use.
        return $color;
    }
    else {
        my ($r, $g, $b, $a);

        if (ref($color) eq 'ARRAY') {
            ($r, $g, $b, $a) = @$color;
        }
        else {
            ($r, $g, $b, $a) = map { $color->{$_} } qw(red green blue alpha);
        }

        if (defined($a)) {
            return sprintf("rgba:0x%02x%02x%02x%02x", $r, $g, $b, $a);
        }
        else {
            return sprintf("rgb:0x%02x%02x%02x", $r, $g, $b);
        }
    }

}

sub _make_url {
    my %opts = @_;

    my $prefix = "http://maps.google.com/staticmap?";

    my %args = ();

    $args{center} = _make_point_string($opts{center}) if $opts{center};
    $args{zoom} = $opts{zoom} if $opts{zoom};
    $args{size} = sprintf("%ix%i", @{$opts{size}});
    $args{format} = $opts{format} if $opts{format};
    $args{maptype} = $opts{maptype} if $opts{maptype};
    $args{markers} = _make_markers_string($opts{markers}) if $opts{markers};
    $args{span} = _make_point_string($opts{span}) if $opts{span};
    $args{frame} = $opts{frame} if $opts{frame};
    $args{hl} = $opts{hl} if $opts{hl};
    $args{key} = $opts{key};

    my @args = map { _urlencode($_)."="._urlencode($args{$_}) } keys %args;
    my $qs = join('&', @args);

    # We do the paths separately because there can be more than one so we can't
    # represent it as a hash.
    my $path_extras = "";
    if ($opts{paths}) {
        my @path_extras = ();
        foreach my $path (@{$opts{paths}}) {
            my @points_string = map { _make_point_string($_) } @{$path->{points}};
            my $points_string = join('|', @points_string);
            push @path_extras, "&path=".$path->{color}.",weight:".$path->{weight}.",".$points_string;
        }
        $path_extras = join('', @path_extras);
    }

    return $prefix.$qs.$path_extras;
}

sub _make_markers_string {
    my $markers = shift;

    my @bits = map { sprintf("%s,%s%s%s", _make_point_string($_->{point}), $_->{size}, $_->{color}, $_->{letter}) } @$markers;

    return join("|", @bits);
}

sub _make_point_string {
    my $point = shift;

    return sprintf("%f,%f", @$point);
}

sub _urlencode {
    my $s = $_[0];
    local $_;
    $s =~ s/([^\w,\.\-])/"%".uc(sprintf("%2.2x", ord($1)))/eg;
    return $s;
}


1;

=head1 DESCRIPTION

This module provides a simple wrapper around generating URLs for Google's Static Maps API.
You can find out more about the Static Maps API here: L<http://code.google.com/apis/maps/documentation/staticmaps/>.

At the time of writing this module supports all features supported by the Static Maps API,
but arguments are provided as a data structure rather than as the (rather inconsistent) string
representations required by the API.

There is a single public static method, called C<url>, which will return a string containing
a static map URL given a data structure of arguments. The various properties and their structures
are given below.

=head1 DATA STRUCTURES

The Static Maps API has several concepts that are represented by data structures. These
are described in the following sections, along with how they can be represented in this API.

=head2 Maps

The foremost entity is the map itself. It is given as a set of name-value pairs (i.e. a hash)
passed into the C<url> method. The properties supported are:

=head3 format

The image format that will be used for the resulting map.

Takes a string containing either "png", "gif" or "jpeg". The default is "png".

=head3 maptype

The tileset used to generate the map.

This can be either "roadmap", which is the standard Google Maps road map, or "mobile",
which is the variation used on Google Maps For Mobile. The default is "roadmap".

=head3 size

The size in pixels of the resulting map. This property is B<required>.

Given either as a reference to a list containing a (width, height) pair, or
as a reference to a hash containing "width" and "height" members. No other
members can be present in the hash.

=head3 markers

A list of markers to include on the map.

Given as a list of marker structures (described below), or as a single marker structure.

Note that due to an ambiguity the shorthand whereby a marker is given simply as
a pair of coordinates in an array ref is not allowed when using the single marker
shorthand. Enclose that array ref in a further array ref to create a single-element
list.

=head3 paths

A list of paths (polygons) to draw on the map.

Given as a list of path structures (described below) or as a single path structure.

=head3 center

The geographic coordinates which will be at the center of the resulting map.

Given as a point structure (described below).

=head3 zoom

The zoom level of the resulting map.

This is an integer between 0 and 19, where 0 is zoomed out enough to show the whole
world given an appropriate map size. Not all zoom levels are supported for the whole
world. See the Static Maps API documentation on zoom levels for more information.

=head3 span

The amount of the world that the map will show in the horizontal and vertical axes.

Given as a point structure (described below) containing the number of degrees latitude
and longitide that will be shown on the map. Where the aspect ratio doesn't match
that of the map itself, additional map data may be shown.

It doesn't make much sense to use zoom and span at the same time.

=head3 frame

Whether to draw a frame around the resulting map image.

Given as a boolean. (Usually 1 for true, 0 for false. However, anything that can be
evaluated as a boolean is accepted.)

=head3 hl

A preferred language to use for the map captions.

Given as a string containing a language code. This will not necessarily be supported for all parts of the world.

=head3 key

Your Google Maps API key. This is B<required>.

Given as a string. You must sign up for an API key from the Maps API website before you can use this API.

=head2 Points

A point is a (latitude, longitude) pair.

It can be given either as a reference to a list containing the pair (with latitude first) or a reference
to a hash containing "lat" and "lon" members, and no other members.

Points are used as part of all of the other geographical structures.

=head2 Markers

A marker is an icon placed at a particular point on the map. Google provides for a few different
icon sizes and colors, and for some marker sizes allows the markers to be annotated with
a letter of the alphabet. See the Static Maps API documentation for more information.

As a shorthand, wherever it is not ambiguous, a marker can be represented simply as a point.
In this case, all of the default display settings will be used for the marker.

A marker is normally represented as a reference to a hash containing the following properties:

=head3 point

The point at which the marker will be placed on the map. These coordinates can alternatively be given
as separate "lat" and "lon" properties on the marker itself, if you wish to avoid creating a separate
point structure.

=head3 size

A keyword which determines what size marker will be used.

This is a string containing either "normal", "tiny", "mid" or "small", where "normal" is the largest
and the default.

=head3 color

A keyword which determines what color marker will be used.

This is a string containing one of the following color names:
"black", "brown", "green", "purple", "yellow", "blue", "gray", "orange", "red" or "white".

=head3 letter

If the marker is either "normal" or "mid", this gives a letter to be displayed within the marker.

This is a string containing a single uppercase letter.

=head2 Paths

A path is essentially a polyline drawn on the map. A path is formed from a sequence of
joined points along with a color and a weight.

A path is represented as a reference to a hash containing the following properties:

=head3 points

The vertices of the path. The visible lines of the path will connect these vertices.

Given as a reference to a list of point structures, as described above.

=head3 weight

How wide the drawn lines will be, as an integer number of pixels.

=head3 color

The color of the lines making up the path.

Given as a color structure, as described below.

=head2 Colors

A color is an RGB triple with an optional alpha channel.

Colors are represented either as a list with three or four elements (the latter
being for an alpha channel) or as a reference to a hash containing "red", "green",
"blue" and "alpha" properties and no other properties. Each channel value is
an integer between 0 and 255 inclusive. For alpha, 0 is completely transparent
and 255 is complete opaque. If an alpha channel is not given, it will default to 255.

Colors can also be represented as a simple string containing something that's valid
as per the Google Maps API, including the "rgb:" or "rgba:" prefix.

=head1 CAVEATS

Although this module will do some basic sanity checks to make sure that you have all of the required
arguments, it intentionally avoids itself checking for many of the limits currently imposed by the
Static Maps API, since those limits may be altered by Google in future.

You should consult the Google Static Maps API documentation to discover the range of values supported
for each property.

=head1 POSSIBLE FUTURE ENHANCEMENTS

It was planned for this module to offer also an object-oriented API where the data structure
can be built up in stages by successive method calls. However, in the interests of keeping things
simple the author decided to support in this version only the static method which takes all arguments
in a single data structure.

In future, particularly if the Static Maps API becomes more complicated, it may be desirable to
support an extended OO version of this API.

=head1 AUTHOR

Copyright 2008 Martin Atkins <mart@degeneration.co.uk>

=head1 LICENCE

This module may be distributed under the same terms as Perl itself.

