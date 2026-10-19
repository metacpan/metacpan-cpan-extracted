package Geo::Coder::GeoApify;

use strict;
use warnings;

use Carp;
use CHI;
use Encode;
# One definition of what counts as a location: Geo::Location::Predicate holds
# the rule the facade and its backends apply, so what is refused here is refused
# there for the same reason.  It is called by name rather than imported - an
# import copies the code reference into this package, and then a test could not
# swap the rule for a spy to prove that it is the rule being consulted.
#
# The rule is an optional dependency, not a prerequisite: it is a distribution of
# its own (Geo-Location-Predicate), declared in Makefile.PL under META_MERGE's
# recommends, so an installer fetches it by default and a standalone install that
# leaves it out still gets the one answer this module can give alone - a
# reference is refused.  It is looked for when it is first needed rather than
# when this module is loaded, so importing this module reads no file it may not
# need, and a rule installed after this module is loaded is still found.
my $HAVE_RULE;	# undef until the rule is first looked for
use JSON::MaybeXS;
use HTTP::Request;
use LWP::UserAgent;
use LWP::Protocol::https;
use Params::Get 0.04;
use Params::Validate::Strict;
use Time::HiRes;
use URI;

=head1 NAME

Geo::Coder::GeoApify - Provides a Geo-Coding functionality using L<https://www.geoapify.com/maps-api/>

=head1 VERSION

Version 0.03

=cut

our $VERSION = '0.03';

=head1 SYNOPSIS

    use Geo::Coder::GeoApify;

    my $geo_coder = Geo::Coder::GeoApify->new(apiKey => $ENV{'GEOAPIFY_KEY'});
    my $location = $geo_coder->geocode(location => '10 Downing St., London, UK');

=head1 DESCRIPTION

Geo::Coder::GeoApify provides an interface to L<https://www.geoapify.com/maps-api/>,
a free Geo-Coding database covering many countries.

=over 4

=item * Caching

Identical geocode requests are cached (using L<CHI> or a user-supplied caching object),
reducing the number of HTTP requests to the API and speeding up repeated queries.

This module leverages L<CHI> for caching geocoding responses.
When a geocode request is made,
a cache key is constructed from the request.
If a cached response exists,
it is returned immediately,
avoiding unnecessary API calls.

=item * Rate-Limiting

A minimum interval between successive API calls can be enforced to ensure that the API is not overwhelmed and to comply with any request throttling requirements.

Rate-limiting is implemented using L<Time::HiRes>.
A minimum interval between API
calls can be specified via the C<min_interval> parameter in the constructor.
Before making an API call,
the module checks how much time has elapsed since the
last request and,
if necessary,
sleeps for the remaining time.

=back

=head1 METHODS

=head2 new

    $geo_coder = Geo::Coder::GeoApify->new(apiKey => $ENV{'GEOAPIFY_KEY'});

Creates a new C<Geo::Coder::GeoApify> object with the provided apiKey.

It takes several optional parameters:

=over 4

=item * C<cache>

A caching object.
If not provided,
an in-memory cache is created with a default expiration of one hour.

=item * C<host>

The API host endpoint.
Defaults to L<https://api.geoapify.com/v1/geocode>.

=item * C<min_interval>

Minimum number of seconds to wait between API requests.
Defaults to C<0> (no delay).
Use this option to enforce rate-limiting.

=item * C<ua>

An object to use for HTTP requests.
If not provided, a default user agent is created.

=back

=cut

sub new
{
	my $class = shift;

	# Handle hash or hashref arguments
	my %args = (ref($_[0]) eq 'HASH') ? %{$_[0]} : @_;

	# Ensure the correct instantiation method is used
	unless (defined $class) {
		carp(__PACKAGE__, ' Use ->new() not ::new() to instantiate');
		return;
	}

	# If $class is an object, clone it with new arguments
	return bless { %{$class}, %args }, ref($class) if ref($class);

	# Validate that the apiKey is provided and is a scalar
	my $apiKey = $args{'apiKey'};
	unless (defined $apiKey && !ref($apiKey)) {
		carp(__PACKAGE__, defined $apiKey ? ' apiKey must be a scalar' : ' apiKey not given');
		return;
	}

	# Set up user agent (ua) if not provided
	my $ua = $args{'ua'} || LWP::UserAgent->new(agent => __PACKAGE__ . "/$VERSION");
	$ua->default_header(accept_encoding => 'gzip,deflate');
	$ua->env_proxy(1);

	# Disable SSL verification if the host is not defined (not recommended in production)
	$ua->ssl_opts(verify_hostname => 0) unless defined $args{'host'};

	# Set host, defaulting to 'api.geoapify.com/v1/geocode'
	my $host = $args{'host'} // 'api.geoapify.com/v1/geocode';

	# Set up caching (default to an in-memory cache if none provided)
	my $cache = $args{cache} || CHI->new(
		driver => 'Memory',
		global => 1,
		expires_in => '1 day',
	);

	# Set up rate-limiting: minimum interval between requests (in seconds)
	my $min_interval = $args{min_interval} || 0;	# default: no delay

	# Return the blessed object
	return bless {
		apiKey => $apiKey,
		cache => $cache,
		host => $host,
		min_interval => $min_interval,
		last_request => 0,	# Initialize last_request timestamp
		ua => $ua,
		%args
	}, $class;
}

=head2 geocode

    $location = $geo_coder->geocode(location => $location);

    print 'Latitude: ', $location->{'features'}[0]{'geometry'}{'coordinates'}[1], "\n";
    print 'Longitude: ', $location->{'features'}[0]{'geometry'}{'coordinates'}[0], "\n";

    @locations = $geo_coder->geocode('Portland, USA');
    print 'There are Portlands in ', join (', ', map { $_->{'state'} } @locations), "\n";

=cut

# The rule when it is installed, and the one thing that can be said without it.
# A reference is not a location however it would print: when the rule is there it
# says so, and when it is not this refuses it - the hole this module used to have
# was testing the string a reference turns into.  Whether a string of digits is a
# place is the rule's question, so without the rule it is not asked: the string
# is looked up, as it was before the rule existed.
sub _could_be_a_location {
	my $location = shift;

	if(!defined($HAVE_RULE)) {
		$HAVE_RULE = eval {
			require Geo::Location::Predicate;
			Geo::Location::Predicate->can('_valid_location') ? 1 : 0;
		} ? 1 : 0;
	}

	# When the rule is installed it decides everything, references included, so
	# that this module cannot be stricter or looser than the facade.  Without it
	# there are two answers this module can give on its own.
	return Geo::Location::Predicate::_valid_location($location) ? 1 : 0 if $HAVE_RULE;

	return 0 if ref($location);
	return 0 unless defined($location) && length($location);
	return 1;
}

sub geocode
{
	my $self = shift;
	my $params = Params::Get::get_params('location', @_);

	my $location = $params->{location};

	# A scalar reference is one way of passing the string it points at, and
	# Params::Get dereferences it when it is the only argument.  Do it here as
	# well, in every calling form, so that it means the string however the
	# method is called.
	$location = ${$location} if ref($location) eq 'SCALAR';

	# What counts as a location is Geo::Location::Predicate's answer, not a
	# second copy of it here: undef and the empty string are nothing to look up, a
	# reference is not a location however it would print, and a string of digits is
	# what a numeric column holds when the wrong one has been read.
	if(!_could_be_a_location($location)) {
		Carp::croak('Usage: geocode(location => $location)')
			unless(defined($location) && length($location));
		Carp::croak('Usage: ', __PACKAGE__, ': invalid input to geocode(), ',
			ref($location) ? 'a reference is not a location' : $location);
	}

	# Encode location if it's in UTF-8
	$location = Encode::encode_utf8($location) if Encode::is_utf8($location);

	# Create URI for the API request
	my $uri = URI->new("https://$self->{host}/search");

	# Handle potential confusion between England and New England
	$location =~ s/(.+),\s*England$/$1, United Kingdom/i;

	# Replace spaces with plus signs for URL encoding
	$location =~ s/\s/+/g;

	# Set query parameters
	$uri->query_form('text' => $location, 'apiKey' => $self->{'apiKey'});
	my $url = $uri->as_string();

	# Create a cache key based on the location (might want to use a stronger hash function if needed)
	my $cache_key = "apify:$location";
	if(my $cached = $self->{cache}->get($cache_key)) {
		return $cached;
	}

	if(my $rc = $self->_get_result($url)) {
		# Cache the result before returning it
		return $self->{'cache'}->set($cache_key, $rc);
	}
}

=head2 ua

Accessor method to get and set UserAgent object used internally. You
can call I<env_proxy> for example, to get the proxy information from
environment variables:

    $geo_coder->ua()->env_proxy(1);

You can also set your own User-Agent object:

    use LWP::UserAgent::Throttled;

    my $ua = LWP::UserAgent::Throttled->new();
    $ua->throttle({ 'api.geoapify.com' => 5 });
    $ua->env_proxy(1);
    $geo_coder = Geo::Coder::GeoApify->new({ ua => $ua, apiKey => $ENV{'GEOAPIFY_KEY'} });

=cut

sub ua
{
	my $self = shift;

	# Update 'ua' if an argument is provided
	$self->{ua} = shift if @_;

	# Return the 'ua' value
	return $self->{ua};
}

=head2 reverse_geocode

    my $address = $geo_coder->reverse_geocode(lat => 37.778907, lon => -122.39732);
    print 'City: ', $address->{features}[0]->{'properties'}{'city'}, "\n";

Similar to geocode except it expects a latitude,longitude pair.

=cut

sub reverse_geocode
{
	my $self = shift;

        my $params = Params::Validate::Strict::validate_strict({
            args => Params::Get::get_params(undef, @_),
            schema => {
                'lat' => {
                    type => 'number',
                    min => -90,
                    max => 90
                }, 'lon' => {
                    type => 'number',
                    min => -180,
                    max => 180
                }
            }
        });

	my $lat = $params->{'lat'};
	my $lon = $params->{'lon'};

	# Build URI for the API request
	my $uri = URI->new("https://$self->{host}/reverse");
	$uri->query_form(
		'lat'	=> $lat,
		'lon'	=> $lon,
		'apiKey' => $self->{'apiKey'}
	);
	my $url = $uri->as_string();

	# Create a cache key based on the location (might want to use a stronger hash function if needed)
	my $cache_key = "apify:reverse:$lat:$lon";
	if(my $cached = $self->{cache}->get($cache_key)) {
		return $cached;
	}

	# Enforce rate-limiting: ensure at least min_interval seconds between requests.
	my $now = time();
	my $elapsed = $now - $self->{last_request};
	if($elapsed < $self->{min_interval}) {
		Time::HiRes::sleep($self->{min_interval} - $elapsed);
	}

	if(my $rc = $self->_get_result($url)) {
		# Cache the result before returning it
		return $self->{'cache'}->set($cache_key, $rc);
	}
}

# Connect to the API and get results
sub _get_result
{
	my ($self, $url) = @_;

	# Enforce rate-limiting: ensure at least min_interval seconds between requests.
	my $now = time();
	my $elapsed = $now - $self->{last_request};
	if($elapsed < $self->{min_interval}) {
		Time::HiRes::sleep($self->{min_interval} - $elapsed);
	}

	# Send the request and handle response
	my $res = $self->{ua}->get($url);

	# Update last_request timestamp
	$self->{'last_request'} = time();

	# Handle API errors
	if($res->is_error()) {
		Carp::carp("API returned error on $url: ", $res->status_line());
		return {};
	}

	# Decode the JSON response
	my $json = JSON::MaybeXS->new->utf8();
	my $rc;
	eval {
		$rc = $json->decode($res->decoded_content());
	};

	# Handle JSON decoding errors
	if($@ || !defined $rc) {
		Carp::carp("$url: Failed to decode JSON - ", $@ || $res->content());
		return;
	}

	return $rc;
}

=head1 AUTHOR

Nigel Horne, C<< <njh at nigelhorne.com> >>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

Lots of thanks to the folks at geoapify.com

=head1 SEE ALSO

L<Geo::Coder::GooglePlaces>, L<HTML::GoogleMaps::V3>

=head1 LICENSE AND COPYRIGHT

Copyright 2024-2026 Nigel Horne.

This program is released under the following licence: GPL2

=cut

1;
