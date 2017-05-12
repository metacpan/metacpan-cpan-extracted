package Geo::Coder::OSM;

use strict;
use warnings;

use Carp qw(croak);
use Encode ();
use JSON;
use LWP::UserAgent;
use URI;

our $VERSION = '0.03';
$VERSION = eval $VERSION;

our %SOURCES = (
    osm      => 'http://nominatim.openstreetmap.org',
    mapquest => 'http://open.mapquestapi.com/nominatim/v1',
);

sub new {
    my ($class, @params) = @_;
    my %params = (@params % 2) ? (key => @params) : @params;

    my $self = bless \ %params, $class;

    $self->ua(
        $params{ua} || LWP::UserAgent->new(agent => "$class/$VERSION")
    );

    if (exists $self->{sources}) {
        my $sources = $self->{sources};
        $self->{sources} = $sources = [$sources] unless ref $sources;
        for my $source (@$sources) {
            croak qq(unknown source '$source')
                unless exists $SOURCES{$source};
        }
    }
    else {
        $self->{sources} = ['osm'];
    }

    $self->{source_idx} = 0;

    if ($self->{debug}) {
        my $dump_sub = sub { $_[0]->dump(maxlength => 0); return };
        $self->ua->set_my_handler(request_send  => $dump_sub);
        $self->ua->set_my_handler(response_done => $dump_sub);
    }
    elsif (exists $self->{compress} ? $self->{compress} : 1) {
        $self->ua->default_header(accept_encoding => 'gzip,deflate');
    }

    return $self;
}

sub response { $_[0]->{response} }

sub ua {
    my ($self, $ua) = @_;
    if ($ua) {
        croak q('ua' must be (or derived from) an LWP::UserAgent')
            unless ref $ua and $ua->isa(q(LWP::UserAgent));
        $self->{ua} = $ua;
    }
    return $self->{ua};
}

sub geocode {
    my ($self, @params) = @_;
    my %params = (@params % 2) ? (location => @params) : @params;

    my $location = delete $params{location} or return;
    $location = Encode::encode('utf-8', $location);

    # Cycle throught the list of sources.
    my $idx = ($self->{source_idx} %= @{ $self->{sources} })++;

    my $uri = URI->new($SOURCES{ $self->{sources}[$idx] } . '/search');
    $uri->query_form(
        q                 => $location,
        format            => 'json',
        addressdetails    => 1,
        'accept-language' => 'en',
        %params,
    );

    return $self->_request($uri);
}

sub reverse_geocode {
    my ($self, @params) = @_;
    my %params = (@params % 2) ? (latlng => @params) : @params;

    # Maintain api compatibility with other geocoders.
    my ($lat, $lon);
    if (my $latlon = delete $params{latlng}) {
        ($lat, $lon) = split '\s*,\s*', $latlon;
    }
    else {
        $lat = delete $params{lat};
        ($lon) = grep defined, delete @params{qw(lon lng)};
    }
    return unless 2 == grep defined, $lat, $lon;

    # Cycle throught the list of sources.
    my $idx = ($self->{source_idx} %= @{ $self->{sources} })++;

    my $uri = URI->new($SOURCES{ $self->{sources}[$idx] } . '/reverse');
    $uri->query_form(
        lat               => $lat,
        lon               => $lon,
        format            => 'json',
        addressdetails    => 1,
        'accept-language' => 'en',
        %params,
    );

    return $self->_request($uri);
}

sub _request {
    my ($self, $uri) = @_;

    return unless $uri;

    my $res = $self->{response} = $self->ua->get($uri);
    return unless $res->is_success;

    # Change the content type of the response (if necessary) so
    # HTTP::Message will decode the character encoding.
    $res->content_type('text/plain')
        unless $res->content_type =~ /^text/;

    my $content = $res->decoded_content;
    return unless $content;

    my $data = eval { from_json($content) };
    return unless $data;

    my @results = 'ARRAY' eq ref $data ? @$data : ($data);
    return wantarray ? @results : $results[0];
}


1;

__END__

=head1 NAME

Geo::Coder::OSM - Geocode addresses with the OpenStreetMap Nominatim API

=head1 SYNOPSIS

    use Geo::Coder::OSM;

    my $geocoder = Geo::Coder::OSM->new;
    my $location = $geocoder->geocode(
        location => 'Hollywood and Highland, Los Angeles, CA'
    );

=head1 DESCRIPTION

The C<Geo::Coder::OSM> module provides an interface to the OpenStreet
Nominatim geocoding service.

=head1 METHODS

=head2 new

    $geocoder = Geo::Coder::OSM->new()
    $geocoder = Geo::Coder::OSM->new(
        ua      => $ua,
        sources => [ 'osm', 'mapquest' ],
        debug   => 1,
    )

Creates a new geocoding object.

Accepts an optional B<ua> parameter for passing in a custom LWP::UserAgent
object.

Accepts an optional B<sources> parameter for specifying the data sources.
Current valid values are B<osm> and B<mapquest>. The default value is B<osm>.
To cycle between different sources, specify an array reference for the
B<sources> value. To define additional sources, see L</SOURCES> below.

=head2 geocode

    $location = $geocoder->geocode(location => $location)
    @locations = $geocoder->geocode(location => $location)

In scalar context, this method returns the first location result; and in
list context it returns all location results.

Each location result is a hashref; a typical example looks like:

    {
        address => {
            city         => "Los Angeles",
            country      => "United States of America",
            country_code => "us",
            hamlet       => "Hollywood",
            road         => "Hollywood Boulevard",
            station      => "Hollywood/Highland",
            suburb       => "Little Armenia",
        },
        boundingbox => [
            "34.101634979248",   "34.1018371582031",
            "-118.339317321777", "-118.33910369873",
        ],
        class => "railway",
        display_name =>
            "Hollywood/Highland, Hollywood Boulevard, Little Armenia, Hollywood, Los Angeles, United States of America",
        icon =>
            "http://nominatim.openstreetmap.org/images/mapicons/transport_train_station2.p.20.png",
        lat => "34.101736",
        licence =>
            "Data Copyright OpenStreetMap Contributors, Some Rights Reserved. CC-BY-SA 2.0.",
        lon      => "-118.33921",
        osm_id   => 472413621,
        osm_type => "node",
        place_id => 9071654,
        type     => "station",
    }

=head2 reverse_geocode

    $location = $geocoder->reverse_geocode(lat => $lat, lon => $lon)
    $location = $geocoder->reverse_geocode(latlng => "$lat,$lon")

Returns a location result for the given lat/lon pair.

=head2 response

    $response = $geocoder->response()

Returns an L<HTTP::Response> object for the last submitted request. Can be
used to determine the details of an error.

=head2 ua

    $ua = $geocoder->ua()
    $ua = $geocoder->ua($ua)

Accessor for the UserAgent object.

=head2 SOURCES

To define additional sources add them to the B<%SOURCES> package variable like
so:

    $Geo::Coder::OSM::SOURCES{local} = 'http://127.0.0.1/api_base_path';
    $Geo::Coder::OSM::SOURCES{internal} = 'http://internal.corp/api_base_path';

=head1 SEE ALSO

L<http://wiki.openstreetmap.org/wiki/Nominatim>

L<http://open.mapquestapi.com/nominatim/>

=head1 REQUESTS AND BUGS

Please report any bugs or feature requests to
L<http://rt.cpan.org/Public/Bug/Report.html?Queue=Geo-Coder-OSM>. I will be
notified, and then you'll automatically be notified of progress on your bug
as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Geo::Coder::OSM

You can also look for information at:

=over

=item * GitHub Source Repository

L<http://github.com/gray/geo-coder-osm>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Geo-Coder-OSM>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Geo-Coder-OSM>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/Public/Dist/Display.html?Name=Geo-Coder-OSM>

=item * Search CPAN

L<http://search.cpan.org/dist/Geo-Coder-OSM/>

=back

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010-2013 gray <gray at cpan.org>, all rights reserved.

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 AUTHOR

gray, <gray at cpan.org>

=cut
