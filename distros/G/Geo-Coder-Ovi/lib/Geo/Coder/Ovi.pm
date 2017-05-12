package Geo::Coder::Ovi;

use strict;
use warnings;

use Carp qw(croak);
use Encode ();
use JSON;
use LWP::UserAgent;
use URI;

our $VERSION = '0.03';
$VERSION = eval $VERSION;

sub new {
    my ($class, %params) = @_;

    # These will be required at some point in the future.
    # croak qq('appid' and 'token' are required);
    #    unless ($params{appid} and $params{token}) {

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
    my $raw = delete $params{raw};

    $_ = Encode::encode('utf-8', $_) for values %params;

    my $location = delete $params{location} or return;

    if (my $language = delete $params{language}) {
        $params{la} = $language;
    }

    my $uri = URI->new('http://where.desktop.mos.svc.ovi.com/NOSe/json');
    $uri->query_form(
        app_id => $self->{appid},
        token  => $self->{token},
        q      => $location,
        vi     => 'where',
        dv     => 'oviMapsAPI',
        lat    => 0,
        lon    => 0,
        %params,
    );

    my $res = $self->{response} = $self->ua->get($uri);
    return unless $res->is_success;

    # Change the content type of the response from 'application/json' so
    # HTTP::Message will decode the character encoding.
    $res->content_type('text/plain');

    my $data = eval { from_json($res->decoded_content) };
    return unless $data;
    return $data if $raw;

    my @results = @{ $data->{results} || [] };
    return wantarray ? @results : $results[0];
}


1;

__END__

=head1 NAME

Geo::Coder::Ovi - Geocode addresses with the Ovi Maps API

=head1 SYNOPSIS

    use Geo::Coder::Ovi;

    my $geocoder = Geo::Coder::Ovi->new(
        appid => 'Your App ID',
        token => 'Your token',
    );
    my $location = $geocoder->geocode(
        location => '102 Corporate Park Dr, Harrison, NY'
    );

=head1 DESCRIPTION

The C<Geo::Coder::Ovi> module provides an interface to the geocoding service
of the Ovi Maps API.

=head1 METHODS

=head2 new

    $geocoder = Geo::Coder::Ovi->new(
        appid => 'Your App ID',
        token => 'Your token',
        # debug => 1,
    )

Creates a new geocoding object.

Accepts the following named arguments:

=over

=item * I<appid>

=item * I<token>

Authentication credentials. (optional, for now)

Credentials can be obtained here: L<https://api.developer.nokia.com/ovi-api>

Note: performance and/or access may be limited without credentials.

=item * I<compress>

Enable compression. (default: 1, unless I<debug> is enabled)

=item * I<debug>

Enable debugging. This prints the headers and content for requests and
responses. (default: 0)

=item * I<ua>

A custom LWP::UserAgent object. (optional)

=back

=head2 geocode

    $location = $geocoder->geocode(location => $location)
    @locations = $geocoder->geocode(location => $location)

Accepts the following named arguments:

=over

=item * I<location>

The free-form, single line address to be located. (required)

=item * I<language>

The preferred language of the response. The language may be specified as the
ISO639-1 language code (e.g. C<en>) or the language code and the ISO3166-1
alpha-2 country code (e.g. C<en-US>). (default: '')

=item * I<raw>

Returns the raw data structure converted from the response, not split into
location results. (optional)

=back

In scalar context, this method returns the first location result; and in
list context it returns all location results.

Example of the data structure representing a location result:

    {
        categories => [ { id => 9000284 } ],
        properties => {
            addrAreaotherName => "West Harrison",
            addrCityName      => "Harrison",
            addrCountryCode   => "USA",
            addrCountryName   => "United States of America",
            addrCountyName    => "Westchester",
            addrHouseAlpha    => "",
            addrHouseNumber   => 102,
            addrPopulation    => 0,
            addrPostalCode    => 10604,
            addrStateName     => "New York",
            addrStreetName    => "Corporate Park Dr",
            geoLatitude       => "41.01945027709007",
            geoLongitude      => "-73.72334106825292",
            language          => "ENG",
            title =>
                "102 Corporate Park Dr, Harrison NY 10604, United States of America",
            type => "Street",
        },
    }

Example of the data structure returned using the I<raw> option:

    {
        id      => "mbc04bl15:20110629151643842:0000049",
        results => [ $location ],
        version => "1.0",
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

L<http://api.maps.ovi.com/>

=head1 REQUESTS AND BUGS

Please report any bugs or feature requests to
L<http://rt.cpan.org/Public/Bug/Report.html?Queue=Geo-Coder-Ovi>. I will be
notified, and then you'll automatically be notified of progress on your bug
as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Geo::Coder::Ovi

You can also look for information at:

=over

=item * GitHub Source Repository

L<http://github.com/gray/geo-coder-ovi>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Geo-Coder-Ovi>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Geo-Coder-Ovi>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/Public/Dist/Display.html?Name=Geo-Coder-Ovi>

=item * Search CPAN

L<http://search.cpan.org/dist/Geo-Coder-Ovi/>

=back

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010-2011 gray <gray at cpan.org>, all rights reserved.

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 AUTHOR

gray, <gray at cpan.org>

=cut
