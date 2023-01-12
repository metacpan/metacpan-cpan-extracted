package Geo::Coder::OpenCage;
# ABSTRACT: Geocode coordinates and addresses with the OpenCage Geocoder
$Geo::Coder::OpenCage::VERSION = '0.34';
use strict;
use warnings;

use Carp;
use HTTP::Tiny;
use JSON::MaybeXS;
use URI;
# FIXME - must be a way to get this from dist.ini?
my $version = 0.34;
my $ua_string;

sub new {
    my $class  = shift;
    my %params = @_;

    if (!$params{api_key}) {
        croak "api_key is a required parameter for new()";
    }

    $ua_string = $class . ' ' . $version;
    my $ua   = $params{ua} || HTTP::Tiny->new(agent => $ua_string);
    my $api_url = 'https://api.opencagedata.com/geocode/v1/json';
    
    if (defined($params{http} && $params{http} == 1 )){
        $api_url =~ s|^https|http|;
    }
    my $self = {
        version => $version,
        api_key => $params{api_key},
        ua      => $ua,
        json    => JSON::MaybeXS->new(utf8 => 1),
        url     => URI->new($api_url),
    };

    return bless $self, $class;
}

sub ua {
    my $self = shift;
    my $ua   = shift;
    if (defined($ua)) {
        $ua->agent($ua_string);
        $self->{ua} = $ua;
    }
    return $self->{ua};
}

# see list: https://opencagedata.com/api#forward-opt
my %valid_params = (
    abbrv          => 1,
    address_only   => 1,    
    add_request    => 1,
    bounds         => 1,
    countrycode    => 1,
    format         => 0,
    jsonp          => 0,
    language       => 1,
    limit          => 1,
    min_confidence => 1,
    no_annotations => 1,
    no_dedupe      => 1,
    no_record      => 1,
    q              => 1,
    pretty         => 1, # makes no actual difference
    proximity      => 1,
    roadinfo       => 1,
);

sub geocode {
    my $self   = shift;
    my %params = @_;

    if (defined($params{location})) {
        $params{q} = delete $params{location};
    } else {
        warn "location is a required parameter for geocode()";
        return undef;
    }

    for my $k (keys %params) {
        if (!defined($params{$k})) {
            warn "Unknown geocode parameter: $k";
            delete $params{$k};
        }
        if (!$params{$k}) { # is a real parameter but we dont support it
            warn "Unsupported geocode parameter: $k";
            delete $params{$k};
        }
    }

    $params{key} = $self->{api_key};
    
    # sort the params for better cachability
    my @final_params;
    foreach my $k (sort keys %params){
        push(@final_params, $k => $params{$k})
        
    }
    my $URL = $self->{url}->clone();    
    $URL->query_form(\@final_params);
    # print STDERR 'url: ' . $URL->as_string . "\n";
    my $response = $self->{ua}->get($URL);

    if (!$response) {
        my $reason = (ref($response) eq 'HTTP::Response')
                    ? $response->status_line() # <code> <message>
                    : $response->{reason};
        warn "failed to fetch '$URL': ", $reason;
        return undef;
    }

    # Support HTTP::Tiny and LWP:: CPAN packages
    my $content = (ref($response) eq 'HTTP::Response')
                    ? $response->decoded_content()
                    : $response->{content};
    my $is_success = (ref($response) eq 'HTTP::Response')
                       ? $response->is_success()
                       : $response->{success};

    my $rh_content = $self->{json}->decode($content);


    if (!$is_success) {
        warn "response when requesting '$URL': " . $rh_content->{status}{code} . ', ' . $rh_content->{status}{message};
        return undef;
    }
    return $rh_content;
}

sub reverse_geocode {
    my $self   = shift;
    my %params = @_;

    foreach my $k (qw(lat lng)) {
        if (!defined($params{$k})) {
            warn "$k is a required parameter";
            return undef;
        }
    }

    $params{location} = join(',', delete @params{'lat', 'lng'});
    return $self->geocode(%params);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Geo::Coder::OpenCage - Geocode coordinates and addresses with the OpenCage Geocoder

=head1 VERSION

version 0.34

=head1 SYNOPSIS

    my $Geocoder = Geo::Coder::OpenCage->new(api_key => $my_api_key);

    my $result = $Geocoder->geocode(location => "Donostia");

=head1 DESCRIPTION

This module provides an interface to the OpenCage geocoding service.

For full details of the API visit L<https://opencagedata.com/api>.

It is recommended you read the L<best practices for using the OpenCage geocoder|https://opencagedata.com/api#bestpractices> before you start.

=head1 METHODS

=head2 new

    my $Geocoder = Geo::Coder::OpenCage->new(api_key => $my_api_key);

Get your API key from L<https://opencagedata.com>.
Optionally "http => 1" can also be specified in which case API requests will NOT be made via https

=head2 ua

    $ua = $geocoder->ua();
    $ua = $geocoder->ua($ua);

Accessor for the UserAgent object. By default HTTP::Tiny is used. Useful if for
example you want to specify that something like LWP::UserAgent::Throttled for 
rate limiting. Even if a new UserAgent is specified the useragent string will 
be specified as "Geo::Coder::OpenCage $version"

=head2 geocode

Takes a single named parameter 'location' and returns a result hashref.

    my $result = $Geocoder->geocode(location => "Mudgee, Australia");

warns and returns undef if the query fails for some reason.

If you will be doing forward geocoding, please see the 
L<OpenCage query formatting guidelines|https://opencagedata.com/guides/how-to-format-your-geocoding-query>

The OpenCage Geocoder has a few optional parameters:

=over 1

=item Supported Parameters

please see L<the OpenCage geocoder documentation|https://opencagedata.com/api>. Most of
L<the various optional parameters|https://opencagedata.com/api#forward-opt> are supported. For example:

=over 2

=item language

An IETF format language code (such as es for Spanish or pt-BR for Brazilian
Portuguese); if this is omitted a code of en (English) will be assumed.

=item limit

Limits the maximum number of results returned. Default is 10.

=item countrycode

Provides the geocoder with a hint to the country that the query resides in.
This value will help the geocoder but will not restrict the possible results to
the supplied country.

The country code is a comma seperated list of 2 character code as defined by the ISO 3166-1 Alpha 2 standard.

=back

=item Not Supported

=over 2

=item jsonp

This module always parses the response as a Perl data structure, so the jsonp
option is never used.

=back

=back

As a full example:

    my $result = $Geocoder->geocode(
        location => "Псковская улица, Санкт-Петербург, Россия",
        language => "ru",
        countrycode => "ru",
    );

=head2 reverse_geocode

Takes two named parameters 'lat' and 'lng' and returns a result hashref.

    my $result = $Geocoder->reverse_geocode(lat => -22.6792, lng => 14.5272);

This method supports the optional parameters in the same way that geocode() does.

=head1 ENCODING

All strings passed to and received from Geo::Coder::OpenCage methods are
expected to be character strings, not byte strings.

For more information see L<perlunicode>.

=head1 SEE ALSO

This module was L<featured in the 2016 Perl Advent Calendar|http://perladvent.org/2016/2016-12-08.html>.

Ed Freyfogle from the OpenCage team gave L<an interview with Built in Perl about how Perl is used at OpenCage|http://blog.builtinperl.com/post/opencage-data-geocoding-in-perl>.

=head1 AUTHOR

Ed Freyfogle <cpan@opencagedata.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023 by OpenCage GmbH.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
