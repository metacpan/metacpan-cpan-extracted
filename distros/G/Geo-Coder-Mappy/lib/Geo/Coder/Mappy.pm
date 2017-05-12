package Geo::Coder::Mappy;

use strict;
use warnings;

use Carp qw(croak);
use Encode ();
use JSON;
use LWP::UserAgent;
use URI;

our $VERSION = '0.02';
$VERSION = eval $VERSION;

sub new {
    my ($class, @params) = @_;
    my %params = (@params % 2) ? (token => @params) : @params;

    croak q('token' is required) unless $params{token};

    my $self = bless \ %params, $class;

    $self->ua(
        $params{ua} || LWP::UserAgent->new(agent => "$class/$VERSION")
    );

    if ($self->{debug}) {
        my $dump_sub = sub { $_[0]->dump(maxlength => 0); return };
        $self->ua->set_my_handler(request_send  => $dump_sub);
        $self->ua->set_my_handler(response_done => $dump_sub);
    }
    elsif (exists $self->{compress} ? $self->{compress} : 1) {
        $self->ua->default_header(accept_encoding => 'gzip,deflate');
    }

    croak q('https' requires LWP::Protocol::https)
        if $params{https} and not $self->ua->is_protocol_supported('https');

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

    while (my ($key, $val) = each %params) {
        $params{$key} = Encode::encode('utf-8', $val);
    }
    my $location = delete $params{location} or return;

    my $uri = URI->new('http://axe.mappy.com/1v1/loc/get.aspx');
    $uri->query_form(
        auth              => $self->{token},
        fullAddress       => $location,
        'opt.format'      => 'json',
        'opt.interactive' => 1,
        'opt.language'    => 'ENG',
        'opt.xmlOutput'   => '3v0',
        %params,
    );
    if ($self->{https}) {
        $uri->scheme('https');
        $uri->host('ssl.mappy.com');
    }

    my $res = $self->{response} = $self->ua->get($uri);
    return unless $res->is_success;

    # Change the content type of the response to force HTTP::Message to
    # decode the character encoding.
    $res->content_type('text/plain');

    my $content = $res->decoded_content;
    return unless $content;

    my $data = eval { from_json($content) };
    return unless $data;

    # Result is a list only if there is more than one item.
    my $results = $data->{kml}{Document}{Placemark};
    my @results = 'ARRAY' eq ref $results ? @$results : ($results);
    return wantarray ? @results : $results[0];
}


1;

__END__

=head1 NAME

Geo::Coder::Mappy - Geocode addresses with the Mappy AJAX API

=head1 SYNOPSIS

    use Geo::Coder::Mappy;

    my $geocoder = Geo::Coder::Mappy->new(
        token => 'Your Mappy AJAX API token'
    );
    my $location = $geocoder->geocode(
        location => '47 Rue de Charonne, 75011 Paris, France'
    );

=head1 DESCRIPTION

The C<Geo::Coder::Mappy> module provides an interface to the geocoding
functionality of the Mappy AJAX API.

=head1 METHODS

=head2 new

    $geocoder = Geo::Coder::Mappy->new('Your Mappy AJAX API token')
    $geocoder = Geo::Coder::Mappy->new(
        token => 'Your Mappy AJAX API token',
        https => 1,
        debug => 1,
    )

Creates a new geocoding object.

An API token can be obtained here:
L<http://connect.mappy.com/en/product/add/free>

Accepts an optional B<https> parameter for securing network traffic.

Accepts an optional B<ua> parameter for passing in a custom LWP::UserAgent
object.

=head2 geocode

    $location = $geocoder->geocode(location => $location)
    @locations = $geocoder->geocode(location => $location)

In scalar context, this method returns the first location result; and in
list context it returns all location results.

Each location result is a hashref; a typical example looks like:

    {
        AddressDetails => {
            Country => {
                AdministrativeArea => {
                    AdministrativeAreaName => "Ile-de-France",
                    Locality               => {
                        LocalityName => "Paris",
                        Thoroughfare => {
                            PostalCode
                                => { PostalCodeNumber => 75011 },
                            ThoroughfareName   => "Rue de Charonne",
                            ThoroughfareNumber => [
                                { Type => "Interpolated", value => 47 },
                                { Type => "Requested",    value => 47 },
                            ],
                            Type => 1,
                        },
                        Type => 1,
                    },
                },
                CountryName => "France",
                CountryNameCode =>
                    { Scheme => "ISO 3166-1 numeric", value => 250 },
            },
            xmlns => "urn:oasis:names:tc:ciq:xsdschema:xAL:2.0",
        },
        ExtendedData => {
            "mappy:address" =>
                "47, Rue de Charonne, 75011, Paris, Ile-de-France, France",
            "mappy:coordinates_system" => 4326,
            "mappy:geocode_level"      => {
                "mappy:code"  => 4,
                "mappy:label" => "Road element level geocoding"
            },
            "mappy:global_score"      => "100.000000",
            "mappy:LocalGeocodeLevel" => {
                "mappy:code"  => 5,
                "mappy:label" => "Road element level geocoding"
            },
            "mappy:OfficialTownCode"        => 75056,
            "mappy:road_element_id"         => "202500065742970",
            "mappy:road_element_percentage" => "50.00",
            "mappy:SubcountryIsoCode"       => 11,
            "xmlns:mappy"
                => "http://schemas.mappy.com/loc/2.1",
        },
        name  => "47 Rue de Charonne 75011 Paris",
        Point => { coordinates => "2.377409,48.853351" },
    }

=head2 response

    $response = $geocoder->response()

Returns an L<HTTP::Response> object for the last submitted request. Can be
used to determine the details of an error.

=head2 ua

    $ua = $geocoder->ua()
    $ua = $geocoder->ua($ua)

Accessor for the UserAgent object.

=head1 SEE ALSO

L<http://connect.mappy.com/en/api/overview>

=head1 REQUESTS AND BUGS

Please report any bugs or feature requests to
L<http://rt.cpan.org/Public/Bug/Report.html?Queue=Geo-Coder-Mappy>.  I will
be notified, and then you'll automatically be notified of progress on your
bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Geo::Coder::Mappy

You can also look for information at:

=over

=item * GitHub Source Repository

L<http://github.com/gray/geo-coder-mappy>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Geo-Coder-Mappy>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Geo-Coder-Mappy>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/Public/Dist/Display.html?Name=Geo-Coder-Mappy>

=item * Search CPAN

L<http://search.cpan.org/dist/Geo-Coder-Mappy/>

=back

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011 gray <gray at cpan.org>, all rights reserved.

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 AUTHOR

gray, <gray at cpan.org>

=cut
