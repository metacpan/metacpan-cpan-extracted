package Geo::Coder::Multimap;

use strict;
use warnings;

use Carp qw(croak);
use Encode ();
use JSON;
use LWP::UserAgent;
use URI;
use URI::Escape qw(uri_unescape);

our $VERSION = '0.01';
$VERSION = eval $VERSION;

sub new {
    my ($class, %params) = @_;

    my $key = $params{apikey} or croak q('apikey' is required);

    my $self = bless {
        key => uri_unescape($key),
    }, $class;

    if ($params{ua}) {
        $self->ua($params{ua});
    }
    else {
        $self->{ua} = LWP::UserAgent->new(agent => "$class/$VERSION");
    }

    return $self;
}

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
    my $self = shift;

    my %params   = (@_ % 2) ? (location => shift, @_) : @_;
    my $location = $params{location} or return;
    my $country  = $params{country};

    $location = Encode::encode('utf-8', $location);

    my $uri = URI->new(
        'http://developer.multimap.com/API/geocode/1.2/' . $self->{key}
    );
    $uri->query_form(
        qs     => $params{location},
        output => 'json',
        $country ? (countryCode => $country) : (),
    );

    my $res = $self->ua->get($uri);
    return unless $res->is_success;

    my $data = eval { from_json($res->decoded_content) };
    return unless $data;

    my @results = @{ $data->{result_set} || [] };
    return wantarray ? @results : $results[0];
}


1;

__END__

=head1 NAME

Geo::Coder::Multimap - Geocode addresses with the Multimap Open API

=head1 SYNOPSIS

    use Geo::Coder::Multimap;

    my $geocoder = Geo::Coder::Multimap->new(apikey => 'Your API Key');
    my $location = $geocoder->geocode(
        location => 'Hollywood and Highland, Los Angeles, CA, US'
    );

=head1 DESCRIPTION

The C<Geo::Coder::Multimap> module provides an interface to the geocoding
functionality of the Multimap Open API.

=head1 METHODS

=head2 new

    $geocoder = Geo::Coder::Multimap->new(apikey => 'Your API Key')

Creates a new geocoding object.

An API key can be obtained here:
L<https://www.multimap.com/openapi/signup/>.

Accepts an optional B<ua> parameter for passing in a custom LWP::UserAgent
object.

=head2 geocode

    $location = $geocoder->geocode(location => $loc)
    $location = $geocoder->geocode(location => $loc, country => $code)
    @locations = $geocoder->geocode(location => $loc)

The C<location> string should either include the country or the C<country>
paramter should be given. Note, the C<country> parameter will produce
better results in most cases.

In scalar context, this method returns the first location result; and in
list context it returns all locations results.

Each location result is a hashref; a typical example looks like:

    {
        'geocode_quality' => '3a',
        'point'           => {
            'lat' => '34.10156',
            'lon' => '-118.33872'
        },
        'zoom_factor' => 14,
        'address'     => {
            'postal_code'  => '90028',
            'country_code' => 'US',
            'areas'        => [ 'HOLLYWOOD', 'CA' ],
            'display_name' => 'HOLLYWOOD, CA, 90028'
        },
        'geocode_score' => '0.409'
    }

=head2 ua

    $ua = $geocoder->ua()
    $ua = $geocoder->ua($ua)

Accessor for the UserAgent object.

=head1 SEE ALSO

L<http://www.multimap.com/openapidocs/1.2/web_service/ws_geocoding.htm>

L<Geo::Coder::Bing>, L<Geo::Coder::Google>, L<Geo::Coder::Mapquest>,
L<Geo::Coder::Yahoo>

=head1 REQUESTS AND BUGS

Please report any bugs or feature requests to
L<http://rt.cpan.org/Public/Bug/Report.html?Queue=Geo-Coder-Multimap>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Geo::Coder::Multimap

You can also look for information at:

=over

=item * GitHub Source Repository

L<http://github.com/gray/geo-coder-multimap>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Geo-Coder-Multimap>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Geo-Coder-Multimap>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/Public/Dist/Display.html?Name=Geo-Coder-Multimap>

=item * Search CPAN

L<http://search.cpan.org/dist/Geo-Coder-Multimap>

=back

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 gray <gray at cpan.org>, all rights reserved.

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 AUTHOR

gray, <gray at cpan.org>

=cut
