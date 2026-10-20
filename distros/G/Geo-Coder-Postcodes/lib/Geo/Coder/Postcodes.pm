package Geo::Coder::Postcodes;

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
use Params::Get 0.13;
use JSON::MaybeXS;
use HTTP::Request;
use LWP::UserAgent;
use LWP::Protocol::https;
use Object::Configure 0.14;
use URI;

=head1 NAME

Geo::Coder::Postcodes - Provides a geocoding functionality using L<https://postcodes.io>.

=head1 VERSION

Version 0.09

=cut

our $VERSION = '0.09';

=head1 SYNOPSIS

      use Geo::Coder::Postcodes;

      my $geo_coder = Geo::Coder::Postcodes->new();
      my $location = $geo_coder->geocode(location => 'Margate');

=head1 DESCRIPTION

Geo::Coder::Postcodes provides an interface to postcodes.io,
a free Geo-Coder database covering the towns in the UK.

=head1 METHODS

=head2 new

    $geo_coder = Geo::Coder::Postcodes->new();
    my $ua = LWP::UserAgent->new();
    $ua->env_proxy(1);
    $geo_coder = Geo::Coder::Postcodes->new(ua => $ua);

=cut

sub new {
	my $class = shift;
	my $params = Params::Get::get_params(undef, @_) || {};

	if(!defined($class)) {
		# Geo::Coder::Postcodes::new() used rather than Geo::Coder::Postcodes->new()
		# FIXME: this only works when no arguments are given
		$class = __PACKAGE__;
	} elsif(ref($class)) {
		# clone the given object
		return bless { %{$class}, %{$params} }, ref($class);
	}

	$params = Object::Configure::configure($class, $params);

	my $ua = $params->{ua} || LWP::UserAgent->new(agent => __PACKAGE__ . "/$VERSION");
	# if(!defined($args{'host'})) {
		# $ua->ssl_opts(verify_hostname => 0);	# Yuck
	# }
	my $host = $params->{host} || 'api.postcodes.io';

	return bless { %{$params}, ua => $ua, host => $host }, $class;
}

=head2 geocode

    $location = $geo_coder->geocode(location => $location);

    print 'Latitude: ', $location->{'latitude'}, "\n";
    print 'Longitude: ', $location->{'logitude'}, "\n";

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

	my $params = Params::Get::get_params('location', @_) ||
		Carp::croak('Usage: geocode(location => $location)');

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

	my $county;
	if($location =~ /,/) {
		if($location =~ /^([\w\s\-]+?),([\w\s]+?),[\w\s]+?$/i) {
			# Turn 'Ramsgate, Kent, UK' into 'Ramsgate'
			$location = $1;
			$county = $2;
			$county =~ s/^\s//g;
			$county =~ s/\s$//g;
		} else {
			Carp::croak('Postcodes.io only supports towns, not full addresses');
			return;
		}
	}
	$location =~ s/\s/+/g;

	if(Encode::is_utf8($location)) {
		$location = Encode::encode_utf8($location);
	}

	my $uri = URI->new("https://$self->{host}/places/");
	my %query_parameters = ('q' => $location);
	$uri->query_form(%query_parameters);
	my $url = $uri->as_string();
	$url =~ s/%2B/+/g;

	my $res = $self->{ua}->get($url);

	if($res->is_error()) {
		Carp::croak("postcodes.io API returned error: on $url " . $res->status_line());
		return;
	}

	my $json = JSON::MaybeXS->new()->utf8();

	# TODO: wantarray
	my $rc = $json->decode($res->decoded_content());
	if($rc->{'result'}) {
		my @results = @{$rc->{result}};
		if($county) {
			# TODO: search through all results for the right one, e.g. Leeds in
			#	Kent or in West Yorkshire?
			foreach my $result(@results) {
				# if(defined($result->{'county_unitary'}) && ($result->{'county_unitary_type'} eq 'County')) {
				if(my $unitary = $result->{'county_unitary'}) {
					# $location =~ s/+/ /g;
					if(($unitary =~ /$county/i) || ($unitary =~ /$location/i)) {
						return $result;
					}
				}
				if((my $region = $result->{'region'}) && ($county =~ /\s+(\w+)$/)) {
					if($region =~ /$1/) {
						# e.g. looked for South Yorkshire, got Yorkshire and the Humber
						return $result;
					}
				}
			}
			return;
		}
		return $results[0];
	}
}

=head2 ua

Accessor method to get and set UserAgent object used internally. You
can call I<env_proxy> for example, to get the proxy information from
environment variables:

    $geo_coder->ua()->env_proxy(1);

You can also set your own User-Agent object:

    use LWP::UserAgent::Throttled;
    $geo_coder->ua(LWP::UserAgent::Throttled->new());

=cut

sub ua {
	my $self = shift;
	if (@_) {
		$self->{ua} = $_[0];
	}
	$self->{ua};
}

=head2 reverse_geocode

    $location = $geo_coder->reverse_geocode(latlng => '37.778907,-122.39732');

Similar to geocode except it expects a latitude/longitude parameter.

=cut

sub reverse_geocode {
	my $self = shift;

	scalar(@_) > 0 or
		Carp::croak('Usage: reverse_geocode(latlng => $latlng)');

	my $params = Params::Get::get_params('latlng', @_) || {};

	my $latlng = $params->{latlng};
	unless(defined($latlng)) {
		Carp::croak('Usage: reverse_geocode(latlng => $latlng)');
		return;
	}

	my $uri = URI->new("https://$self->{host}/postcodes/");
	my ($lat, $lon) = split(/,/, $params->{latlng});
	my %query_parameters = ('lat' => $lat, 'lon' => $lon, radius => '1000');
	$uri->query_form(%query_parameters);
	my $url = $uri->as_string;

	my $res = $self->{ua}->get($url);

	if($res->is_error()) {
		Carp::croak("postcodes.io API returned error: on $url ", $res->status_line());
		return;
	}

	my $json = JSON::MaybeXS->new->utf8();

	my $rc = $json->decode($res->content);
	if($rc->{'result'}) {
		my @results = @{$rc->{'result'}};
		return $results[0];
	}
	return;
}

=head1 BUGS

Note that this most only works on towns and cities, some searches such as "Margate, Kent, UK"
may work, but you're best to search only for "Margate".

=head1 AUTHOR

Nigel Horne C<< <njh@nigelhorne.com> >>

Based on L<Geo::Coder::GooglePlaces>.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

Lots of thanks to the folks at postcodes.io.

=head1 SEE ALSO

L<Geo::Coder::GooglePlaces>, L<HTML::GoogleMaps::V3>

=head1 LICENSE AND COPYRIGHT

Copyright 2017-2026 Nigel Horne.

This program is released under the following licence: GPL2

=cut

1;
