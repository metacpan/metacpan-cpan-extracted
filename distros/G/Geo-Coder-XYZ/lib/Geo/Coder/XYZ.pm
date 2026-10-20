package Geo::Coder::XYZ;

use strict;
use warnings;

use Carp;
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
use Params::Get;
use URI;

=head1 NAME

Geo::Coder::XYZ - Provides a Geo-Coding functionality using L<https://geocode.xyz>

=head1 VERSION

Version 0.11

=cut

our $VERSION = '0.11';

=head1 SYNOPSIS

      use Geo::Coder::XYZ;

      my $geo_coder = Geo::Coder::XYZ->new();
      my $location = $geo_coder->geocode(location => '10 Downing St., London, UK');

=head1 DESCRIPTION

Geo::Coder::XYZ provides an interface to geocode.xyz, a free Geo-Coding database covering many countries.

=head1 METHODS

=head2 new

    $geo_coder = Geo::Coder::XYZ->new();
    my $ua = LWP::UserAgent->new();
    $ua->env_proxy(1);
    $geo_coder = Geo::Coder::XYZ->new(ua => $ua);

=cut

sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;

	# Use Geo::Coder::XYZ->new(), not Geo::Coder::XYZ::new()
	if(!defined($class)) {
		carp(__PACKAGE__, ' use ->new() not ::new() to instantiate');
		return;
	}

	my $params = Params::Get::get_params(undef, \@_);

	my $ua = $params->{ua};
	if(!defined($ua)) {
		$ua = LWP::UserAgent->new(agent => __PACKAGE__ . "/$VERSION");
		$ua->default_header(accept_encoding => 'gzip,deflate');
	}
	if(!defined($params->{'host'})) {
		$ua->ssl_opts(verify_hostname => 0);	# Yuck
	}
	my $host = $params->{host} || 'geocode.xyz';

	return bless { ua => $ua, host => $host }, $class;
}

=head2 geocode

    $location = $geo_coder->geocode(location => $location);

    print 'Latitude: ', $location->{'latt'}, "\n";
    print 'Longitude: ', $location->{'longt'}, "\n";

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

sub geocode {
	my $self = shift;
	# @_ rather than \@_: Params::Get only unwraps that shorthand when the
	# value is a plain string, so passing the reference to the argument list
	# hid the value from the checks below and put the argument list itself in
	# its place.
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

	if (Encode::is_utf8($location)) {
		$location = Encode::encode_utf8($location);
	}

	my $uri = URI->new("https://$self->{host}/");
	if($location =~ /(.+),\s*England$/i) {
		$location = "$1, United Kingdom";	# geocode.xyz gets confused between England and New England
	}
	$location =~ s/\s/+/g;
	my %query_parameters = ('locate' => $location, 'json' => 1);
	if(wantarray) {
		# moreinfo is needed to find alternatives when the given location is ambiguous
		$query_parameters{'moreinfo'} = 1;
	}
	$uri->query_form(%query_parameters);
	my $url = $uri->as_string();

	my $res = $self->{ua}->get($url);

	if ($res->is_error) {
		Carp::carp("API returned error: on $url ", $res->status_line());
		return { };
	}

	my $json = JSON::MaybeXS->new()->utf8();
	my $rc;
	eval {
		$rc = $json->decode($res->decoded_content());
	};
	if(!defined($rc)) {
		if($@) {
			Carp::carp("$url: $@");
			return { };
		}
		Carp::carp("$url: can't decode the JSON ", $res->content());
		return { };
	}

	if($rc->{'otherlocations'} && $rc->{'otherlocations'}->{'loc'} &&
	   (ref($rc->{'otherlocations'}->{'loc'}) eq 'ARRAY')) {
		my @rc = @{$rc->{'otherlocations'}->{'loc'}};
		if(wantarray) {
			return @rc;
		}
		return $rc[0];
	}
	return $rc;

	# my @results = @{ $data || [] };
	# wantarray ? @results : $results[0];
}

=head2 ua

Accessor method to get and set UserAgent object used internally. You
can call I<env_proxy> for example, to get the proxy information from
environment variables:

    $geo_coder->ua()->env_proxy(1);

You can also set your own User-Agent object:

    use LWP::UserAgent::Throttled;
    my $ua = LWP::UserAgent::Throttled->new();
    $ua->throttle({ 'geocode.xyz' => 2 });
    $geo_coder->ua($ua);

=cut

sub ua {
	my $self = shift;
	if (@_) {
		$self->{ua} = shift;
	}
	$self->{ua};
}

=head2 reverse_geocode

    $location = $geo_coder->reverse_geocode(latlng => '37.778907,-122.39732');

Similar to geocode except it expects a latitude/longitude parameter.

=cut

sub reverse_geocode
{
	my $self = shift;
	my $params = Params::Get::get_params('latlng', @_);

	my $latlng = $params->{'latlng'}
		or Carp::carp('Usage: reverse_geocode(latlng => $latlng)');

	return $self->geocode(location => $latlng, reverse => 1);
}

=head1 SUPPORT

This module is provided as-is without any warranty.

=head1 AUTHOR

Nigel Horne, C<< <njh at nigelhorne.com> >>

Based on L<Geo::Coder::GooglePlaces>.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

Lots of thanks to the folks at geocode.xyz.

=head1 SEE ALSO

L<Geo::Coder::GooglePlaces>, L<HTML::GoogleMaps::V3>

=head1 LICENSE AND COPYRIGHT

Copyright 2017-2025 Nigel Horne.

This program is released under the following licence: GPL2

=cut

1;
