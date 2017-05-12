package Geo::Coder::TomTom;

use strict;
use warnings;

use Carp qw(croak);
use Encode ();
use JSON;
use LWP::UserAgent;
use URI;

our $VERSION = '0.04';
$VERSION = eval $VERSION;

sub new {
    my ($class, @params) = @_;
    my %params = (@params % 2) ? (apikey => @params) : @params;

    croak q('apikey' is required) unless exists $params{apikey};

    my $self = bless \ %params, $class;

    $self->ua(
        $params{ua} || LWP::UserAgent->new(agent => "$class/$VERSION")
    );

    if ($self->{debug}) {
        my $dump_sub = sub { $_[0]->dump(maxlength => 0); return };
        $self->ua->set_my_handler(request_send  => $dump_sub);
        $self->ua->set_my_handler(response_done => $dump_sub);
        $self->{compress} ||= 0;
    }
    if (exists $self->{compress} ? $self->{compress} : 1) {
        $self->ua->default_header(accept_encoding => 'gzip,deflate');
    }

    croak q('https' requires LWP::Protocol::https)
        if $self->{https} and not $self->ua->is_protocol_supported('https');

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

    $params{query} = delete $params{location} or return;
    $_ = Encode::encode('utf-8', $_) for values %params;

    my $uri = URI->new('https://api.tomtom.com/lbs/services/geocode/4/geocode');
    $uri->scheme('https') if $self->{https};
    $uri->query_form(
        key    => $self->{apikey},
        format => 'json',
        %params,
    );

    my $res = $self->{response} = $self->ua->get($uri);
    return unless $res->is_success;

    # Change the content type of the response from 'application/json' so
    # HTTP::Message will decode the character encoding.
    $res->content_type('text/plain');

    my $content = $res->decoded_content;
    return unless $content;

    my $data = eval { from_json($content) };
    return unless $data;

    # Result is a list only if there is more than one item.
    my $results = $data->{geoResponse}{geoResult};
    my @results = 'ARRAY' eq ref $results ? @$results : ($results);

    return wantarray ? @results : $results[0];
}


1;

__END__

=head1 NAME

Geo::Coder::TomTom - Geocode addresses with the TomTom Map Toolkit API

=head1 SYNOPSIS

    use Geo::Coder::TomTom;

    my $geocoder = Geo::Coder::TomTom->new(apikey => 'Your API key');
    my $location = $geocoder->geocode(
        location => 'De Ruijterkade 154, Amsterdam, NL'
    );

=head1 DESCRIPTION

The C<Geo::Coder::TomTom> module provides an interface to the TomTom Map
Toolkit geocoding service.

=head1 METHODS

=head2 new

    $geocoder = Geo::Coder::TomTom->new('Your API key')
    $geocoder = Geo::Coder::TomTom->new(
        apikey => 'Your API key',
        # debug => 1,
    )

Creates a new geocoding object.

Accepts the following named arguments:

=over

=item * I<apikey>

An API key (required)

An API key can be obtained here: L<http://developer.tomtom.com/apps/mykeys>

=item * I<ua>

A custom LWP::UserAgent object. (optional)

=item * I<compress>

Enable compression. (default: 1, unless I<debug> is enabled)

=item * I<debug>

Enable debugging. This prints the headers and content for requests and
responses. (default: 0)

=back

=head2 geocode

    $location = $geocoder->geocode(location => $location)
    @locations = $geocoder->geocode(location => $location)

In scalar context, this method returns the first location result; and in
list context it returns all location results.

Each location result is a hashref; a typical example looks like:

    {
        "latitude": 52.3773852,
        "longitude": 4.9094794,
        "geohash": "u173zxnbrhm0",
        "mapName": "TomTomMap",
        "houseNumber": "154",
        "type": "house",
        "street": "De Ruijterkade",
        "alternativeStreetName": [],
        "city": "Amsterdam",
        "district": "Amsterdam",
        "country": "The Netherlands",
        "countryISO3": "NLD",
        "postcode": "1011 AC",
        "formattedAddress": "De Ruijterkade 154, 1011 AC Amsterdam, Amsterdam, NL",
        "isCensusMicropolitanFlag": false,
        "widthMeters": 1,
        "heightMeters": 1,
        "score": 1.0,
        "confidence": 0.40665394,
        "iteration": 0
    },

=head2 response

    $response = $geocoder->response()

Returns an L<HTTP::Response> object for the last submitted request. Can be
used to determine the details of an error.

=head2 ua

    $ua = $geocoder->ua()
    $ua = $geocoder->ua($ua)

Accessor for the UserAgent object.

=head1 SEE ALSO

L<http://developer.tomtom.com/docs/read/map_toolkit/web_services/geocoding_single_call>

=head1 REQUESTS AND BUGS

Please report any bugs or feature requests to
L<http://rt.cpan.org/Public/Bug/Report.html?Queue=Geo-Coder-TomTom>. I will
be notified, and then you'll automatically be notified of progress on your
bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Geo::Coder::TomTom

You can also look for information at:

=over

=item * GitHub Source Repository

L<http://github.com/gray/geo-coder-tomtom>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Geo-Coder-TomTom>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Geo-Coder-TomTom>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/Public/Dist/Display.html?Name=Geo-Coder-TomTom>

=item * Search CPAN

L<http://search.cpan.org/dist/Geo-Coder-TomTom/>

=back

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010-2015 gray <gray at cpan.org>, all rights reserved.

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 AUTHOR

gray, <gray at cpan.org>

=cut
