package Geo::Coder::ArcGIS;

use strict;
use warnings;

use Carp qw(croak);
use JSON;
use LWP::UserAgent;
use URI;

our $VERSION = '0.01';
$VERSION = eval $VERSION;

sub new {
    my ($class, %params) = @_;

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
    my $raw = delete $params{raw};

    my $location = $params{location} or return;
    $location = Encode::encode('utf-8', $location);

    my $uri = URI->new(
        'http://tasks.arcgis.com/ArcGIS/rest/services/WorldLocator/'
            . 'GeocodeServer/findAddressCandidates'
    );
    $uri->scheme('https') if $self->{https};
    $uri->query_form(
        SingleLine => $location,
        f          => 'json',
        outFields  => '*',
    );

    my $res = $self->{response} = $self->ua->get(
        $uri, referer => 'http://www.arcgis.com/home/webmap/viewer.html'
    );
    return unless $res->is_success;

    # Change the content type of the response from 'application/json' so
    # HTTP::Message will decode the character encoding.
    $res->content_type('text/plain');

    my $content = $res->decoded_content;
    return unless $content;

    my $data = eval { from_json($content) };
    return unless $data;
    return $data if $raw;

    my @results = @{ $data->{candidates} || [] };
    return wantarray ? @results : $results[0];
}


1;

__END__

=head1 NAME

Geo::Coder::ArcGIS - Geocode addresses with ArcGIS

=head1 SYNOPSIS

    use Geo::Coder::ArcGIS;

    my $geocoder = Geo::Coder::ArcGIS->new;
    my $location = $geocoder->geocode(
        location => '380 New York Street, Redlands, CA',
    );

=head1 DESCRIPTION

The C<Geo::Coder::ArcGIS> module provides an interface to the ArcGIS Online
geocoding service.

=head1 METHODS

=head2 new

    $geocoder = Geo::Coder::ArcGIS->new

Accepts the following named arguments:

=over

=item * I<compress>

Enable compression. (default: 1, unless I<debug> is enabled)

=item * I<debug>

Enable debugging. This prints the headers and content for requests and
responses. (default: 0)

=item * I<https>

Use https protocol for securing network traffic. (default: 0)

=item * I<ua>

A custom LWP::UserAgent object. (optional)

=back

=head2 geocode

    $location = $geocoder->geocode(location => $location)
    @locations = $geocoder->geocode(location => $location)

Accepts the following named arguments:

=over

=item * I<location>

The free-form, single line address to be located.

=item * I<raw>

Returns the raw data structure converted from the response, not split into
location results. (optional)

=back

In scalar context, this method returns the first location result; and in
list context it returns all location results.

An example of the data structure representing a location result:

    {
        address => "380 New York St, Redlands, CA 92373 San Bernardino, USA",
        attributes => {
            East_Lon   => -117.1929409,
            MatchLevel => "houseNumber",
            North_Lat  => 34.058295,
            Score      => 100,
            South_Lat  => 34.0560467,
            West_Lon   => -117.1956547,
        },
        location => { x => -117.1942978, y => 34.0571709 },
        score    => 100,
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

L<http://www.arcgis.com/home/webmap/viewer.html>

=head1 REQUESTS AND BUGS

Please report any bugs or feature requests to
L<http://rt.cpan.org/Public/Bug/Report.html?Queue=Geo-Coder-ArcGIS>. I will
be notified, and then you'll automatically be notified of progress on your
bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Geo::Coder::ArcGIS

You can also look for information at:

=over

=item * GitHub Source Repository

L<http://github.com/gray/geo-coder-arcgis>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Geo-Coder-ArcGIS>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Geo-Coder-ArcGIS>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/Public/Dist/Display.html?Name=Geo-Coder-ArcGIS>

=item * Search CPAN

L<http://search.cpan.org/dist/Geo-Coder-ArcGIS/>

=back

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011 gray <gray at cpan.org>, all rights reserved.

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 AUTHOR

gray, <gray at cpan.org>

=cut
