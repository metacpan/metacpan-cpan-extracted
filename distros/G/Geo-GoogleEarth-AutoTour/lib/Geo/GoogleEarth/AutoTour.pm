package Geo::GoogleEarth::AutoTour;
# ABSTRACT: Generate Google Earth Camera Tours from Tracks and Paths

use 5.012;
use strict;
use warnings;

use base 'Exporter';

use Carp 'croak';
use IO::Uncompress::Unzip qw( unzip $UnzipError );
use IO::Compress::Zip qw(zip $ZipError);
use XML::LibXML;
use Date::Parse 'str2time';
use Math::Trig 1.23 qw( deg2rad rad2deg great_circle_distance great_circle_bearing );

our $VERSION = '1.06'; # VERSION

our @EXPORT_OK = qw( tour kmz_to_xml xml_to_kmz load_kml read_path gather_points build_tour );

sub tour {
    my ( $input, $settings, $output ) = @_;
    croak('Input not defined') unless ( defined $input );

    my $xc = load_kml( ( ref $input ) ? kmz_to_xml($input) : $input );

    $settings //= {};
    my $doc_name = $xc->findvalue('//g:Document/g:name');
    $settings->{doc_name} //= $doc_name;

    if ( $xc->findnodes('//g:Placemark[@id="tour"]/gx:MultiTrack/gx:Track')->size ) {
        $settings->{points} = gather_points($xc);
    }
    elsif ( length $xc->findvalue('//g:Document/g:Placemark/g:LineString/g:coordinates') > 0 ) {
        $settings->{points} = read_path($xc);
    }
    else {
        croak('Input appears not to be either a track or path KML/KMZ');
    }

    my $xml = build_tour($settings);

    if ( ref $output eq 'SCALAR' ) {
        $$output = $xml;
    }
    elsif ( ref $output ) {
        xml_to_kmz( $xml, $output, $doc_name );
    }

    return $xml;
}

sub kmz_to_xml {
    my ($kmz_file_handle) = @_;
    my $buffer;
    unzip( $kmz_file_handle, \$buffer ) or die $UnzipError;
    return $buffer;
}

sub xml_to_kmz {
    my ( $xml, $kmz_file_handle ) = @_;
    zip( \$xml, $kmz_file_handle, 'Name' => 'doc.kml' ) or die $ZipError;
}

sub load_kml {
    my ($xml_input) = @_;

    my $xc;
    eval {
        $xc = XML::LibXML::XPathContext->new(
            XML::LibXML->load_xml( string => $xml_input )->documentElement
        );
    };
    croak('Unable to parse KML XML input') if ($@);

    $xc->registerNs( g => 'http://www.opengis.net/kml/2.2' );

    return $xc;
}

sub read_path {
    my ($xc) = @_;

    ( my $coords = $xc->findvalue('//g:Document/g:Placemark/g:LineString/g:coordinates') ) =~ s/^\s+|\s+$//g;
    my ( $time, $last_lat, $last_long ) = ( time, undef, undef );

    my @coords = map {
        my ( $longitude, $latitude, $altitude ) = split( /,/, $_ );
        {
            latitude  => $latitude,
            longitude => $longitude,
            altitude  => $altitude,
        };
    } split( /\s/, $coords );

    $coords[0]{time} = time;
    for ( my $i = 1; $i < @coords; $i++ ) {
        my @points = (
            deg2rad( $coords[ $i - 1 ]->{longitude} ),
            deg2rad( 90 - $coords[ $i - 1 ]->{latitude} ),
            deg2rad( $coords[$i]->{longitude} ),
            deg2rad( 90 - $coords[$i]->{latitude} ),
        );

        $coords[$i]{duration} = great_circle_distance( @points, 3956 ) / 140 * 60 * 60;
        $coords[$i]{heading} = $coords[ $i - 1 ]{heading} = rad2deg( great_circle_bearing( @points, 3956 ) );
        $coords[$i]{time} = $coords[ $i - 1 ]{time} + $coords[$i]{duration};
    }

    return \@coords;
}

sub gather_points {
    my ($xc) = @_;

    my $last_time;
    return [
        map {
            my $when    = $xc->findnodes( 'g:when', $_ );
            my $coord   = $xc->findnodes( 'gx:coord', $_ );
            my $bearing = $xc->findnodes(
                'g:ExtendedData/g:SchemaData/gx:SimpleArrayData[@name="bearing"]/gx:value',
                $_,
            );

            $when->map( sub {
                my ( $longitude, $latitude, $altitude) = split( ' ', $coord->shift->to_literal );

                my $time     = str2time( $_->to_literal );
                my $duration = ($last_time) ? $time - $last_time : undef;
                $last_time   = $time;

                {
                    latitude  => $latitude,
                    longitude => $longitude,
                    altitude  => $altitude,
                    heading   => $bearing->shift->to_literal,
                    duration  => $duration,
                    time      => $time,
                };
            } );
        } $xc->findnodes('//g:Placemark[@id="tour"]/gx:MultiTrack/gx:Track')
    ];
}

sub build_tour {
    my $settings;
    eval {
        $settings = ( ref $_[0] eq 'HASH' ) ? $_[0] : { @{ $_[0] } };
    };
    croak($@) if ($@);
    croak('Points not defined properly') unless (
        $settings->{points} and ref $settings->{points} eq 'ARRAY' and ref $settings->{points}[0] eq 'HASH'
    );

    $settings->{doc_name}            //= 'Tour';
    $settings->{tour_name}           //= 'Tour';
    $settings->{tilt}                //= 80;         # lower = deeper; higher = higher; 90 = flat
    $settings->{gap_duration}        //= 20;         # seconds
    $settings->{play_speed}          //= 20;         # higher = faster; 1 = normal
    $settings->{initial_move}        //= 2;          # seconds
    $settings->{initial_wait}        //= 5;          # seconds
    $settings->{start_trim}          //= 0;          # seconds
    $settings->{end_trim}            //= 0;          # seconds
    $settings->{altitude_adjustment} //= 100;        # feet
    $settings->{altitude_mode}       //= 'absolute'; # absolute, relativeToGround

    $settings->{altitude_mode} = 'absolute'         if ( lc( $settings->{altitude_mode} ) eq 'msl' );
    $settings->{altitude_mode} = 'relativeToGround' if ( lc( $settings->{altitude_mode} ) eq 'agl' );
    $settings->{altitude_mode} = 'relativeToGround' if ( lc( $settings->{altitude_mode} ) eq 'relative' );

    $settings->{altitude_adjustment} /= 3.28084; # convert feet into meters for use in Google Earth KML

    my $xml = XML::LibXML::Document->new( '1.0', 'UTF-8' );

    my $kml = $xml->createElement('kml');
    $kml->setAttribute( 'xmlns' => 'http://www.opengis.net/kml/2.2' );
    $kml->setAttribute( 'xmlns:gx' => 'http://www.google.com/kml/ext/2.2' );

    my $doc = $xml->createElement('Document');

    my $name = $xml->createElement('name');
    $name->appendTextNode( $settings->{doc_name} );
    $doc->appendChild($name);

    my $tour = $xml->createElement('gx:Tour');

    my $tour_name = $xml->createElement('name');
    $tour_name->appendTextNode( $settings->{tour_name} );
    $tour->appendChild($tour_name);

    my $playlist = $xml->createElement('gx:Playlist');

    my ( $wait, $total_duration ) = ( 0, 0 );
    for my $point ( @{ $settings->{points} } ) {
        next if (
            $point->{time} < $settings->{points}[0]->{time} + $settings->{start_trim}
            or
            $point->{time} > $settings->{points}[-1]->{time} - $settings->{end_trim}
        );

        $total_duration += $point->{duration} || 0;
        next if ( $total_duration < $settings->{gap_duration} );

        my $flyto = $xml->createElement('gx:FlyTo');

        my $duration = $xml->createElement('gx:duration');
        $duration->appendTextNode(
            ( defined $point->{duration} )
                ? $total_duration / $settings->{play_speed}
                : $settings->{initial_move}
        );
        $flyto->appendChild($duration);

        $total_duration = 0;

        my $mode = $xml->createElement('gx:flyToMode');
        $mode->appendTextNode('smooth');
        $flyto->appendChild($mode);

        my $camera = $xml->createElement('Camera');

        for my $node_name ( qw( latitude longitude altitude heading tilt ) ) {
            my $element = $xml->createElement($node_name);
            $element->appendTextNode(
                ( $node_name eq 'tilt' )     ? $settings->{tilt}                                       :
                ( $node_name eq 'altitude' ) ? $point->{$node_name} + $settings->{altitude_adjustment} :
                    $point->{$node_name}
            );
            $camera->appendChild($element);
        }

        my $a_mode = $xml->createElement('altitudeMode');
        $a_mode->appendTextNode( $settings->{altitude_mode} );
        $camera->appendChild($a_mode);

        $flyto->appendChild($camera);
        $playlist->appendChild($flyto);

        unless ($wait) {
            my $gx_wait = $xml->createElement('gx:Wait');

            my $element = $xml->createElement('gx:duration');
            $element->appendTextNode( $settings->{initial_wait} );
            $gx_wait->appendChild($element);

            $playlist->appendChild($gx_wait);

            $wait = 1;
        }
    }

    $tour->appendChild($playlist);
    $doc->appendChild($tour);
    $kml->appendChild($doc);
    $xml->setDocumentElement($kml);

    return $xml->toString(1);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Geo::GoogleEarth::AutoTour - Generate Google Earth Camera Tours from Tracks and Paths

=head1 VERSION

version 1.06

=for markdown [![Build Status](https://travis-ci.org/gryphonshafer/Geo-GoogleEarth-AutoTour.svg)](https://travis-ci.org/gryphonshafer/Geo-GoogleEarth-AutoTour)
[![Coverage Status](https://coveralls.io/repos/gryphonshafer/Geo-GoogleEarth-AutoTour/badge.png)](https://coveralls.io/r/gryphonshafer/Geo-GoogleEarth-AutoTour)

=for test_synopsis my( $input, $output );

=head1 SYNOPSIS

    use Geo::GoogleEarth::AutoTour 'tour';

    my $kml = tour($input);

    tour( $input, {
        doc_name            => 'Tour',
        tour_name           => 'Tour',
        tilt                => 80,
        gap_duration        => 20,
        play_speed          => 20,
        initial_move        => 2,
        initial_wait        => 5,
        start_trim          => 0,
        end_trim            => 0,
        altitude_adjustment => 100,
        altitude_mode       => 'absolute',
    }, $output );

=head1 DESCRIPTION

This module takes input expected to be a Track or Path export data from Google
Earth and produces a Tour. The expected typical case is that you start with a
Track or Path exported from Google Earth as a KMZ or KML file, and you'll get
as output a KMZ file suitable for loading in Google Earth.

=head2 INSPIRATION AND PURPOSE

I'm a pilot, and I enjoy recording flights using a cell phone and a GPS logger.
I can export that data as a KMZ/KML file and view it in Google Earth, which is
all nice and whatever; but I wanted to make Google Earth fly what I flew.

=head1 FUNCTIONS

This module allows for exporting of several functions, but typical usage will
only require "tour" to be exported.

    use Geo::GoogleEarth::AutoTour 'tour';

=head2 tour

This function should do everything you need. It expects some input, which can
be KML XML as a string, or a filehandle of a KML or KMZ file or stream.

You can optionally provide settings as a hashref. Any setting not defined gets
set as the default, which are values I find to be mostly reasonable for the
typical case. You can also optionally provide as a third parameter what should
be used as output: a filehandle or reference to a scalar.

The function will always return the generated tour KML XML, but if an output
filehandle is provided, it'll try to write to that filehandle a KMZ file.

    my $input  = IO::File->new( 'track.kmz', '<' ) or die $!;
    my $output = IO::File->new( 'tour.kmz',  '>' ) or die $!;

    my $kml_xml = tour(
        $input,
        {
            doc_name => 'Moutains Tour from Track',
            altitude_adjustment => 1500,
            altitude_mode => 'agl',
        },
        $output,
    );

See the settings section below for information about the settings.

=head2 kmz_to_xml, xml_to_kmz

As you might guess, these two functions will take a KMZ filehandle and return
KML XML as a string, or will take KML XML as a string and a KMZ filehandle to
output.

    my $input = IO::File->new( 'track.kmz', '<' ) or die $!;
    my $kml_xml = kmz_to_xml($input);

    my $output = IO::File->new( 'tour.kmz', '>' ) or die $!;
    xml_to_kmz( $kml_xml, $output );

=head2 load_kml

This is a helper function. It takes KML XML as a string and returns an
L<XML::LibXML::XPathContext> object with the OpenGIS namespace (which is the
default XMLNS) set to "g".

    my $xc     = load_kml($kml_xml);
    my $coords = $xc->findvalue('//g:Placemark/g:LineString/g:coordinates');

=head2 read_path

This function expects an L<XML::LibXML::XPathContext> object built by
C<load_kml> based on KML XML that contains a Path. It returns an arrayref of
points suitable for use with the C<build_tour> function.

    my @points = @{ read_path( load_kml($kml_xml) ) };

=head2 gather_points

This function expects an L<XML::LibXML::XPathContext> object built by
C<load_kml()> based on KML XML that contains a Track. It returns an arrayref of
points suitable for use with the C<build_tour> function.

    my @points = @{ gather_points( load_kml($kml_xml) ) };

=head2 build_tour

This function expects settings passed in as either a list or a hashref. The
settings are described below, but there needs to also be a "points" key with
the value being an arrayref of hashrefs created by C<read_path> or
C<gather_points>.

The function returns KML XML of the generated tour.

    my $kml_xml_0 = build_tour( points => read_path( load_kml($kml_xml) ) );
    my $kml_xml_1 = build_tour({
        points              => read_path( load_kml($kml_xml) ),
        altitude_adjustment => 1500,
        altitude_mode       => 'agl',
    });

=head1 SETTINGS

Settings are required by C<tour> and C<build_tour>, although you'll likely never
need to use the latter function. Any settings not provided get defaulted to what
I think are reasonable values to produce a Tour that looks reasonable well for
most cases.

    doc_name            => 'Tour',
    tour_name           => 'Tour',
    tilt                => 80,
    gap_duration        => 20,
    play_speed          => 20,
    initial_move        => 2,
    initial_wait        => 5,
    start_trim          => 0,
    end_trim            => 0,
    altitude_adjustment => 100,
    altitude_mode       => 'absolute',

=over

=item doc_name, tour_name

These are labels used for the document name and tour name (contained within
the document).

=item tilt

This is the camera angle in degrees. A tilt of 0 is pointing straight down, and
a tilt of 90 is perfectly level. Generally, a tilt of 80 seems to produce good
tours most of the time.

=item gap_duration

If you're recording a lot of GPS positions with your GPS recording application,
especially if your GPS hardware is on an old cell phone, you can get a whole
lot of noise and really, really tight readings fractions of a second apart. This
isn't useful for tour generation, and in fact, it can sometimes be problematic.

So the C<gap_duration> is a number of seconds of minimum time between each GPS
record getting included in tour generation. For example, a value of 20 means
that the GPS records used for tour generation will not be closer than 20 seconds
apart. This has the effect of making the tour a bit more flight-view realistic.

=item play_speed

This is how fast you want a Track to run. The default is 20, which means the
tour plays at about 20 times as fast as it would at a value of 0. Larger numbers
mean faster playback. A value of 0.5 would mean the playback is at half speed.

=item initial_move

When Google Earth first loads up a Tour, it tries to move you to the origin
point of the Tour. The C<initial_move> is the number of seconds you want to
tell Google Earth to do that move. Typically 2 works well.

=item initial_wait

After moving to the origin point, C<initial_wait> instructs Google Earth to
pause for a number of seconds before beginning movement. Generally, a value of
5 seconds seems to work well, but this will be highly dependent on your network
speed and hardware capabilities.

=item start_trim, end_trim

When I record a GPS Track for a flight, I tend to do it while I'm parked on the
ground before I taxi out to the runway. Similarly, I don't shutdown the recorder
until I'm parked again at the destination airport. To trim out that time, you
can use C<start_trim> and C<end_trim> to trim off a certain number of seconds
from the start or end of the Track.

=item altitude_adjustment

Some GPS hardware (mine included) isn't consistently accurate about altitude.
I've noticed I end up recording Tracks about 200 to 300 feet too low. So
C<altitude_adjustment> is the number of feet to adjust the altitude by.

Note that if you're converting a Path instead of a Track, you really ought to
set C<altitude_adjustment> since a Path is always recorded as being on ground
level.

=item altitude_mode

By default, C<altitude_mode> is set to absolute altitude, or MSL in pilot-speak.
However, sometimes you want altitude to be AGL or relative to ground level.
C<altitude_mode> can be set to absolute, MSL, relative, or AGL.

=back

=head1 SEE ALSO

You can look for additional information at:

=over 4

=item *

L<GitHub|https://github.com/gryphonshafer/Geo-GoogleEarth-AutoTour>

=item *

L<CPAN|http://search.cpan.org/dist/Geo-GoogleEarth-AutoTour>

=item *

L<MetaCPAN|https://metacpan.org/pod/Geo::GoogleEarth::AutoTour>

=item *

L<AnnoCPAN|http://annocpan.org/dist/Geo-GoogleEarth-AutoTour>

=item *

L<Travis CI|https://travis-ci.org/gryphonshafer/Geo-GoogleEarth-AutoTour>

=item *

L<Coveralls|https://coveralls.io/r/gryphonshafer/Geo-GoogleEarth-AutoTour>

=item *

L<CPANTS|http://cpants.cpanauthors.org/dist/Geo-GoogleEarth-AutoTour>

=item *

L<CPAN Testers|http://www.cpantesters.org/distro/G/Geo-GoogleEarth-AutoTour.html>

=back

=head1 AUTHOR

Gryphon Shafer <gryphon@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Gryphon Shafer.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
