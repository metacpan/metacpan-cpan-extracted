# NAME

Geo::Gpx - Create and parse GPX files.

# SYNOPSIS

    # Version 0.10 compatibility
    use Geo::Gpx;
    my $gpx = Geo::Gpx->new( @waypoints );
    my $xml = $gpx->xml;

    # New API, generate GPX
    my $gpx = Geo::Gpx->new();
    $gpx->waypoints( \@wpt );
    my $xml = $gpx->xml( '1.0' );

    # Parse GPX
    my $gpx       = Geo::Gpx->new( xml => $xml );
    my $waypoints = $gpx->waypoints();
    my $tracks    = $gpx->tracks();

    # Parse GPX from open file
    my $gpx       = Geo::Gpx->new( input => $fh );
    my $waypoints = $gpx->waypoints();
    my $tracks    = $gpx->tracks();

# DESCRIPTION

The original goal of this module was to produce GPX/XML files which were
parsable by both GPX Spinner and EasyGPS. As of version 0.13 it has
been extended to support general parsing and generation of GPX data. GPX
1.0 and 1.1 are supported.

# INTERFACE

## `new( { args } )`

The original purpose of `Geo::Gpx` was to allow an array of
[Geo::Cache](https://metacpan.org/pod/Geo%3A%3ACache) objects to be converted into a GPX file. This behaviour is
maintained by this release:

    use Geo::Gpx;
    my $gpx = Geo::Gpx->new( @waypoints );
    my $xml = $gpx->xml;

New applications can use C <Geo::Gpx> to parse a GPX file :

    my $gpx = Geo::Gpx->new( xml => $gpx_document );

or from an open filehandle :

    my $gpx = Geo::Gpx->new( input => $fh );

or can create an empty container to which waypoints, routes and tracks
can then be added:

    my $gpx = Geo::Gpx->new();
    $gpx->waypoints( \@wpt );

The following additional options can be specified:

- ` use_datetime `

    If true time values in parsed GPX will be [DateTime](https://metacpan.org/pod/DateTime) objects rather
    than epoch times.

## `add_waypoint( waypoint ... )`

Add one or more waypoints. Each waypoint must be a reference to a
hash. Each waypoint must include the keys `lat` and `lon` and may
include others:

    my $wpt = {
      lat         => 54.786989,
      lon         => -2.344214,
      ele         => 512,
      time        => 1164488503,
      magvar      => 0,
      geoidheight => 0,
      name        => 'My house & home',
      cmt         => 'Where I live',
      desc        => '<<Chez moi>>',
      src         => 'Testing',
      link        => {
        href => 'http://hexten.net/',
        text => 'Hexten',
        type => 'Blah'
      },
      sym           => 'pin',
      type          => 'unknown',
      fix           => 'dgps',
      sat           => 3,
      hdop          => 10,
      vdop          => 10,
      pdop          => 10,
      ageofdgpsdata => 45,
      dgpsid        => 247
    };

    $gpx->add_waypoint( $wpt );

Time values may either be an epoch offset or a [DateTime](https://metacpan.org/pod/DateTime). If you wish
to specify the timezone use a [DateTime](https://metacpan.org/pod/DateTime).

## `iterate_waypoints()`

Get an iterator that visits all the waypoints in a `Geo::Gpx`.

## `iterate_routepoints()`

Get an iterator that visits all the routepoints in a `Geo::Gpx`.

## `iterate_trackpoints()`

Get an iterator that visits all the trackpoints in a `Geo::Gpx`.

## `iterate_points()`

Get an iterator that visits all the points in a `Geo::Gpx`. For example

    my $iter = $gpx->iterate_points();
    while ( my $pt = $iter->() ) {
      print "Point: ", join( ', ', $pt->{lat}, $pt->{lon} ), "\n";
    }

## `bounds( [ $iterator ] )`

Compute the bounding box of all the points in a `Geo::Gpx` returning
the result as a hash reference. For example:

    my $gpx = Geo::Gpx->new( xml => $some_xml );
    my $bounds = $gpx->bounds();

returns a structure like this:

    $bounds = {
      minlat => 57.120939,
      minlon => -2.9839832,
      maxlat => 57.781729,
      maxlon => -1.230902
    };

`$iterator` defaults to `$self->iterate_points`.

## `xml( [ $version ] )`

Generate GPX XML.

    my $gpx10 = $gpx->xml( '1.0' );
    my $gpx11 = $gpx->xml( '1.1' );

If the version is omitted it defaults to the value of the `version`
attribute. Parsing a GPX document sets the version. If the `version`
attribute is unset defaults to 1.0.

`Geo::Gpx` version 0.10 used [Geo::Cache](https://metacpan.org/pod/Geo%3A%3ACache) to render each of the
points. [Geo::Cache](https://metacpan.org/pod/Geo%3A%3ACache) generates a number of hardwired values to suit the
original application of that module which aren't appropriate for general
purpose GPX manipulation. Legacy mode is triggered by passing a list of
[Geo::Cache](https://metacpan.org/pod/Geo%3A%3ACache) points to the constructor; this should probably be avoided
for new applications.

## `TO_JSON`

For compatibility with [JSON](https://metacpan.org/pod/JSON) modules. Converts this object to a hash
with keys that correspond to the above methods. Generated ala:

    my %json = map { $_ => $self->$_ }
     qw(name desc author keywords copyright
     time link waypoints tracks routes version );
    $json{bounds} = $self->bounds( $iter );

With one difference: the keys will only be set if they are defined.

## `gpx`

Synonym for `xml()`. Provided for compatibility with version 0.10.

## `loc`

Provided for compatibility with version 0.10.

## `gpsdrive`

Provided for compatibility with version 0.10.

## `name( [ $newname ] )`

Accessor for the &lt;name> element of a GPX. To get the name:

    my $name = $gpx->name();

and to set it:

    $gpx->name( 'My big adventure' );

## `desc( [ $newdesc ] )`

Accessor for the &lt;desc> element of a GPX. To get the the description:

    my $desc = $gpx->desc();

and to set it:

    $gpx->desc('Got lost, wandered around for ages, got cold, got hungry.');

## `author( [ $newauthor ] )`

Accessor for the author structure of a GPX. The author information is stored
in a hash that reflects the structure of a GPX 1.1 document:

    my $author = $gpx->author();
    $author = {
      link => {
        text => 'Hexten',
        href => 'http://hexten.net/'
      },
      email => {
        domain => 'hexten.net',
        id => 'andy'
      },
      name => 'Andy Armstrong'
    },

When setting the author data a similar structure must be supplied:

    $gpx->author({
      name => 'Me!'
    });

The bizarre encoding of email addresses as id and domain is a
feature of GPX.

## `time( [ $newtime ] )`

Accessor for the &lt;time> element of a GPX. The time is converted to a
Unix epoch time when a GPX document is parsed unless the `use_datetime`
option is specified in which case times will be represented as
[DateTime](https://metacpan.org/pod/DateTime) objects.

When setting the time you may supply either an epoch time or a
[DateTime](https://metacpan.org/pod/DateTime) object.

## `keywords( [ $newkeywords ] )`

Access for the &lt;keywords> element of a GPX. Keywords are stored as an
array reference:

    $gpx->keywords(['bleak', 'cold', 'scary']);
    my $k = $gpx->keywords();
    print join(', ', @{$k}), "\n";

prints

    bleak, cold, scary

## `copyright( [ $newcopyright ] )`

Access for the &lt;copyright> element of a GPX.

    $gpx->copyright('(c) You Know Who');
    print $gpx->copyright(), "\n";

prints

    You Know Who

## `link`

Accessor for the &lt;link> element of a GPX. Links are stored in a hash
like this:

    $link = {
      'text' => 'Hexten',
      'href' => 'http://hexten.net/'
    };

For example:

    $gpx->link({ href => 'http://google.com/', text => 'Google' });

## `waypoints( [ $newwaypoints ] )`

Accessor for the waypoints array of a GPX. Each waypoint is a hash
(which may also be a [Geo::Cache](https://metacpan.org/pod/Geo%3A%3ACache) instance in legacy mode):

    my $wpt = {
      # All standard GPX fields
      lat           => 54.786989,
      lon           => -2.344214,
      ele           => 512,
      time          => 1164488503,
      magvar        => 0,
      geoidheight   => 0,
      name          => 'My house & home',
      cmt           => 'Where I live',
      desc          => '<<Chez moi>>',
      src           => 'Testing',
      link          => {
        href => 'http://hexten.net/',
        text => 'Hexten',
        type => 'Blah'
      },
      sym           => 'pin',
      type          => 'unknown',
      fix           => 'dgps',
      sat           => 3,
      hdop          => 10,
      vdop          => 10,
      pdop          => 10,
      ageofdgpsdata => 45,
      dgpsid        => 247
    };

All fields apart from `lat` and `lon` are optional. See the GPX
specification for an explanation of the fields. The waypoints array is
an anonymous array of such points:

    $gpx->waypoints([ { lat => 57.0, lon => -2 },
                      { lat => 57.2, lon => -2.1 } ]);

## `routes( [ $newroutes ] )`

Accessor for the routes array. The routes array is an array of hashes
like this:

    my $routes = [
      {
        'name' => 'Route 1'
        'points' => [
          {
            'lat' => '54.3286193447719',
            'name' => 'WPT1',
            'lon' => '-2.38972155527137'
          },
          {
            'lat' => '54.6634365629388',
            'name' => 'WPT2',
            'lon' => '-2.55373552512617'
          },
          {
            'lat' => '54.7289259665049',
            'name' => 'WPT3',
            'lon' => '-3.05196861273443'
          }
        ],
      },
      {
        'name' => 'Route 2'
        'points' => [
          {
            'lat' => '54.4165154835049',
            'name' => 'WPT4',
            'lon' => '-2.56153453279676'
          },
          {
            'lat' => '54.6670126167344',
            'name' => 'WPT5',
            'lon' => '-2.69526089464403'
          }
        ],
      }
    ];

    $gpx->routes($routes);

Each of the points in a route may have any of the attributes that are
legal for a waypoint.

## `tracks( [ $newtracks ] )`

Accessor for the tracks array. The tracks array is an array of hashes
like this:

    my $tracks = [
      {
        'name' => 'Track 1',
        'segments' => [
          {
            'points' => [
              {
                'lat' => '54.5182217145253',
                'lon' => '-2.62191579018834'
              },
              {
                'lat' => '54.1507759448355',
                'lon' => '-3.05774931478646'
              },
              {
                'lat' => '54.6016296784874',
                'lon' => '-3.40418920968631'
              }
            ]
          },
          {
            'points' => [
              {
                'lat' => '54.6862790450185',
                'lon' => '-3.68760108982739'
              }
            ]
          }
        ]
      },
      {
        'name' => 'Track 2',
        'segments' => [
          {
            'points' => [
              {
                'lat' => '54.9927807628549',
                'lon' => '-4.04712811256436'
              },
              {
                'lat' => '55.1148395198045',
                'lon' => '-4.33623533555793'
              },
              {
                'lat' => '54.6214174046189',
                'lon' => '-4.26293674042878'
              },
              {
                'lat' => '55.0540816059084',
                'lon' => '-4.42261020671926'
              },
              {
                'lat' => '55.4451622411372',
                'lon' => '-4.32873765338'
              }
            ]
          }
        ]
      }
    ];

## `version( [ $newversion ] )`

Accessor for the schema version of a GPX document. Versions 1.0 and 1.1
are supported.

    print $gpx->version();

prints

    1.0

# DIAGNOSTICS

- `Invalid arguments`

    Invalid arguments passed to `new()`.

- `Undefined accessor method: %s`

    The various accessor methods are implemented as an AUTOLOAD handler.
    This error is thrown if an attempt is made to call an accessor other
    than `name`, `desc`, `author`, `time`, `keywords`, `copyright`,
    `link`, `waypoints`, `tracks`, `routes` or `version`.

# DEPENDENCIES

[DateTime::Format::ISO8601](https://metacpan.org/pod/DateTime%3A%3AFormat%3A%3AISO8601),
[DateTime](https://metacpan.org/pod/DateTime),
[HTML::Entities](https://metacpan.org/pod/HTML%3A%3AEntities),
[Scalar::Util](https://metacpan.org/pod/Scalar%3A%3AUtil),
[Time::Local](https://metacpan.org/pod/Time%3A%3ALocal),
[XML::Descent](https://metacpan.org/pod/XML%3A%3ADescent)

# SEE ALSO

[JSON](https://metacpan.org/pod/JSON)

# BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to `bug-geo-gpx@rt.cpan.org`, or through the web interface at [http://rt.cpan.org](http://rt.cpan.org).

# AUTHOR

Originally by Rich Bowen `<rbowen@rcbowen.com>` and Andy Armstrong  `<andy@hexten.net>`.

This version by Patrick Joly `<patjol@cpan.org>`.

# VERSION

1.02

# LICENCE AND COPYRIGHT

Copyright (c) 2004-2022, Andy Armstrong `<andy@hexten.net>`, Patrick Joly `patjol@cpan.org`. All
rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See [perlartistic](https://metacpan.org/pod/perlartistic).

# DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL,
INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR
INABILITY TO USE THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF
DATA OR DATA BEING RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR
THIRD PARTIES OR A FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER
SOFTWARE), EVEN IF SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE
POSSIBILITY OF SUCH DAMAGES.
