# NAME

Geo::Gpx - Create and parse GPX files

# SYNOPSIS

    my ($gpx, $waypoints, $track);

    # From an open file or an XML string
    $gpx = Geo::Gpx->new( input => $fh );
    $gpx = Geo::Gpx->new( xml => $xml );

    my $waypoints = $gpx->waypoints();
    my $tracks    = $gpx->tracks();

# DESCRIPTION

`Geo::Gpx` supports the parsing and generation of GPX data. GPX 1.0 and 1.1 are supported.

## Constructor

- new( args \[, use\_datetime => $bool, work\_dir => $working\_directory )

    Create and return a new `Geo::Gpx` instance based on an array of points that can each be constructed as [Geo::Gpx::Point](https://metacpan.org/pod/Geo%3A%3AGpx%3A%3APoint) objects or with a supplied XML file handle or XML string.

    If `use_datetime` is set to true, time values in parsed GPX will be [DateTime](https://metacpan.org/pod/DateTime) objects rather than epoch times. (This option may be disabled in the future in favour of a method that can return a [DateTime](https://metacpan.org/pod/DateTime) object from a specified point.)

    `work_dir` or `wd` for short can be set to specify where to save any working files (such as with the save\_laps() method). The module never actually [chdir](https://metacpan.org/pod/chdir)'s, it just keeps track of where the user wants to save files (and not have to type filenames with path each time), hence it is always defined.

    The working directory can be supplied as a relative (to [Cwd::cwd](https://metacpan.org/pod/Cwd%3A%3Acwd)) or absolute path but is internally stored by `set_wd()` as a full path. If `work_dir` is ommitted, it is set based on the path of the _$filename_ supplied or the current working directory if the constructor is called with an XML string or a filehandle.

## Methods

- waypoints( \\@waypoints )

    Initialize waypoints based on an array reference containing either a list of [Geo::Gpx::Point](https://metacpan.org/pod/Geo%3A%3AGpx%3A%3APoint)s or hash references with fields that can be parsed by [Geo::Gpx::Point](https://metacpan.org/pod/Geo%3A%3AGpx%3A%3APoint)'s `new()` constructor. See the later for the possible fields.

    Returns the array reference of [Geo::Gpx::Points](https://metacpan.org/pod/Geo%3A%3AGpx%3A%3APoints) stored as waypoints.

- add\_waypoint( \\%point \[, \\%point, … \] )

    Add one or more waypoints. Each waypoint must be either a [Geo::Gpx::Point](https://metacpan.org/pod/Geo%3A%3AGpx%3A%3APoint) or a hash reference with fields that can be parsed by [Geo::Gpx::Point](https://metacpan.org/pod/Geo%3A%3AGpx%3A%3APoint)'s `new()` constructor. See the later for the possible fields.

        %point = ( lat => 54.786989, lon => -2.344214, ele => 512, time => 1164488503, name => 'My house', desc => 'There\'s no place like home' );
        $gpx->add_waypoint( \%point );

          or

        $pt = Geo::Gpx::Point->new( %point );
        $gpx->add_waypoint( $pt );

    Time values may either be an epoch offset or a [DateTime](https://metacpan.org/pod/DateTime). If you wish to specify the timezone use a [DateTime](https://metacpan.org/pod/DateTime). (This behaviour may change in the future.)

- iterate\_waypoints()
- iterate\_trackpoints()
- iterate\_routepoints()

    Get an iterator for all of the waypoints, trackpoints, or routepoints in a `Geo::Gpx` instance, as per the iterator chosen.

- iterate\_points()

    Get an iterator for all of the points in a `Geo::Gpx` instance, including waypoints, trackpoints, and routepoints.

        my $iter = $gpx->iterate_points();
        while ( my $pt = $iter->() ) {
          print "Point: ", join( ', ', $pt->{lat}, $pt->{lon} ), "\n";
        }

- bounds( $iterator )

    Compute the bounding box of all the points in a `Geo::Gpx` returning the result as a hash reference.

        my $gpx = Geo::Gpx->new( xml => $some_xml );
        my $bounds = $gpx->bounds();

    returns a structure like this:

        $bounds = {
          minlat => 57.120939,
          minlon => -2.9839832,
          maxlat => 57.781729,
          maxlon => -1.230902
        };

    `$iterator` defaults to `$self->iterate_points` if not specified.

- xml( $version )

    Generate and return an XML string representation of the instance.

    If the version is omitted it defaults to the value of the `version` attribute. Parsing a GPX document sets the version. If the `version` attribute is unset defaults to 1.0.

- TO\_JSON

    For compatibility with [JSON](https://metacpan.org/pod/JSON) modules. Convert this object to a hash with keys that correspond to the above methods. Generated ala:

        my %json = map { $_ => $self->$_ }
         qw(name desc author keywords copyright
         time link waypoints tracks routes version );
        $json{bounds} = $self->bounds( $iter );

    With one difference: the keys will only be set if they are defined.

- save( filename => $fname, force => $bool, encoding => $enc )

    Saves the `Geo::Gpx` instance as a file.

    All fields are optional unless the instance was created without a filename (i.e with an XML string or a filehandle) and `set_filename()` has not been called yet. If the filename is a relative path, the file will be saved in the instance's working directory (not the caller's, `Cwd`).

    `encoding` can be either `utf-8` (the default) or `latin1`.

- set\_filename( $filename )

    Sets/gets the filename. Returns the name of the file with the complete path.

- set\_wd( $folder )

    Sets/gets the working directory and checks the validity of that path. Relative paths are supported for setting but only full paths are returned or internally stored.

    The previous working directory is also stored in memory; can call &lt;set\_wd('-')> to switch back and forth between two directories.

    Note that it does not call [chdir](https://metacpan.org/pod/chdir), it simply sets the path for the eventual saving of files.

## Accessors

- name( $str )
- desc( $str )
- copyright( $str )
- keywords( $aref )

    Accessors to get or set the `name`, `desc`, `copyright`, or `keywords` fields of the `Geo::Gpx` instance.

- author( $href )

    The author information is stored in a hash that reflects the structure of a GPX 1.1 document. To set it, supply a hash reference as (`link` and `email` are optional):
      {
        link  => { text => 'Hexten', href => 'http://hexten.net/' },
        email => { domain => 'hexten.net', id => 'andy' },
        name  => 'Andy Armstrong'
      },

- link( $href )

    The link is stored similarly to the author information, it can be set by supplying a hash reference as:
      { link  => { text => 'Hexten', href => 'http://hexten.net/' } }

- time( $epoch or $DateTime )

    Accessor for the &lt;time> element of a GPX. The time is converted to a Unix epoch time when a GPX document is parsed unless the `use_datetime` option is specified in which case times will be represented as [DateTime](https://metacpan.org/pod/DateTime) objects.

    When setting the time you may supply either an epoch time or a [DateTime](https://metacpan.org/pod/DateTime) object.

- routes( $aref )

    Return an array reference containing the routes of the instance. In the future, methods will be provided to set routes. In the meantime, to set the routes of the GPX instance, supply an array of hash references structured as:

        my $aref = [
          { 'name' => 'Route 1',
            'points' => [ <list_of_Geo_Gpx_Point> ]
          },
          { 'name' => 'Route 2',
            'points' => [ <list_of_Geo_Gpx_Point> ]
          },
        ];

- tracks( $aref )

    Returns an array reference containing the routes of the instance. In the future, methods will be provided to set tracks. In the meantime, to set the tracks of the GPX instance, supply an array of hash references structured as:

        my $aref = [
          { 'name' => 'Track 1',
            'segments' => [
              { 'points' => [ <list_of_Geo_Gpx_Point> ] },
              { 'points' => [ <list_of_Geo_Gpx_Point> ] },
            ]
          }
          { 'name' => 'Track 2',
            'segments' => [
              { 'points' => [ <list_of_Geo_Gpx_Point> ] },
              { 'points' => [ <list_of_Geo_Gpx_Point> ] },
            ]
          }
        ];

- version()

    Returns the schema version of a GPX document. Versions 1.0 and 1.1 are supported.

## Legacy methods provided for compatibility

These methods will likely removed soon as they reflect a very dated release of this module.

- gpx()

    Synonym for `xml()`.

- gpsdrive()
- loc()

    Provided for compatibility with version 0.10.

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

Please visit the project page at: [https://github.com/patjoly/geo-gpx](https://github.com/patjoly/geo-gpx).

# VERSION

1.03

# LICENSE AND COPYRIGHT

Copyright (c) 2004-2022, Andy Armstrong `<andy@hexten.net>`, Patrick Joly `patjol@cpan.org`. All rights reserved.

This module is free software; you can redistribute it and/or modify it under the same terms as Perl itself. See [perlartistic](https://metacpan.org/pod/perlartistic).

# DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENSE, BE LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGES.
