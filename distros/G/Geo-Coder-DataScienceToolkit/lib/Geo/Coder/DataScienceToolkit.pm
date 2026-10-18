package Geo::Coder::DataScienceToolkit;

use strict;
use warnings;

use Carp;
use Encode;
use JSON::MaybeXS;
use HTTP::Request;
use LWP::UserAgent;
use LWP::Protocol::http;
use Object::Configure 0.14;
use URI;

# Geo::Coder::Free::Validate holds the one definition of what counts as a
# location.  Look for it when this module is loaded, so that a site with
# Geo::Coder::Free installed gets that definition and not a second copy of it.
# It is not a prerequisite: without it a reference is refused here, which is
# the case this module used to get wrong by testing the string the reference
# turns into instead of testing the value.
my $have_validate = eval {
	require Geo::Coder::Free::Validate;
	Geo::Coder::Free::Validate->can('_valid_location') ? 1 : 0;
};

=head1 NAME

Geo::Coder::DataScienceToolkit - Provides a geocoding functionality using
http://www.datasciencetoolkit.org/

=head1 VERSION

Version 0.03

=cut

our $VERSION = '0.03';

=head1 SYNOPSIS

      use Geo::Coder::DataScienceToolkit;

      my $geocoder = Geo::Coder::DataScienceToolkit->new();
      my $location = $geocoder->geocode(location => '10 Downing St., London, UK');

=head1 DESCRIPTION

Geo::Coder::DataScienceToolkit provides an interface to datasciencetoolkit,
a free geocode database covering the US and UK.

=head1 METHODS

=head2 new

    $geocoder = Geo::Coder::DataScienceToolkit->new();
    my $ua = LWP::UserAgent->new();
    $ua->env_proxy(1);
    $geocoder = Geo::Coder::DataScienceToolkit->new(ua => $ua);

=cut

sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $params = Object::Configure::configure($class, @_ ? \@_ : undef);

	my $ua = delete $params->{ua} || LWP::UserAgent->new(agent => __PACKAGE__ . "/$VERSION");
	# if(!defined($params{'host'})) {
		# $ua->ssl_opts(verify_hostname => 0);	# Yuck
	# }
	my $host = $params->{host} || 'www.datasciencetoolkit.org';

	return bless { %{$params}, ua => $ua, host => $host }, $class;
}

=head2 geocode

    $location = $geocoder->geocode(location => $location);

    print 'Latitude: ', $location->{'results'}[0]->{'geometry'}->{'location'}->{'lat'}, 38.90, 1e-2); "\n";
    print 'Longitude: ', delta_within($location->{'results'}[0]->{'geometry'}->{'location'}->{'lng'}, -77.04, 1e-2); "\n";

    @locations = $geocoder->geocode('Portland, USA');
    diag 'There are Portlands in ', join (', ', map { $_->{'state'} } @locations);

=cut

sub geocode {
	my $self = shift;
	my %params;

	if(!ref($self)) {
		if(scalar(@_)) {
			return(__PACKAGE__->new()->parse(@_));
		}
		return(__PACKAGE__->new()->parse($self));
	} elsif(ref($self) eq 'HASH') {
		return(__PACKAGE__->new()->parse($self));
	} elsif(ref($_[0]) eq 'HASH') {
		%params = %{$_[0]};
	} elsif(scalar(@_) == 1) {
		$params{'location'} = shift;
	} elsif(scalar(@_) && (scalar(@_) % 2 == 0)) {
		%params = @_;
	} else {
		Carp::croak('Usage: ', __PACKAGE__, '::geocode(location => $location)');
	}

	my $location = $params{location};
	# A scalar reference is one way of passing the string it points at, and
	# Params::Get dereferences it when it is the only argument.  Do it here as
	# well, in every calling form, so that it means the string however the
	# method is called.
	$location = ${$location} if ref($location) eq 'SCALAR';

	# A reference is not a location, however it would print.  Checked before the
	# "is there anything to look up?" test below, so that a reference is refused
	# for being a reference rather than for being false.
	if(ref($location) && !_could_be_a_location($location)) {
		Carp::croak('Usage: ', __PACKAGE__, ': invalid input to geocode(), a reference is not a location');
		return;
	}

	unless($location) {
		Carp::croak("Usage: geocode(location => \$location)");
	}

	# Fail when the input is just a set of numbers
	if($location !~ /\D/) {
		Carp::croak('Usage: ', __PACKAGE__, ": invalid input to geocode(), $location");
		return;
	}

	if (Encode::is_utf8($location)) {
		$location = Encode::encode_utf8($location);
	}

	my $uri = URI->new("http://$self->{host}/maps/api/geocode/json");
	$location =~ s/\s/+/g;
	my %query_parameters = ('address' => $location, 'sensor' => 'false');
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
		$rc = $json->decode($res->content());
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

    $geocoder->ua()->env_proxy(1);

You can also set your own User-Agent object:

    use LWP::UserAgent::Throttled;
    $geocoder->ua(LWP::UserAgent::Throttled->new());

=cut

sub ua {
	my $self = shift;
	if (@_) {
		$self->{ua} = shift;
	}
	$self->{ua};
}

=head2 reverse_geocode

Reverse geocoding is not supported by datasciencetoolkit.org, so calls to
this will generate an error.

=cut

sub reverse_geocode {
	Carp::carp('datasciencetoolkit.org does not support reverse encoding');
}

# Could the value handed to it be a location?  Only a reference gets asked here,
# and the answer is whatever Geo::Coder::Free::Validate says when it is
# installed.  Without it, a reference is refused: only a string can name a
# place, and there is nothing in this module that could make sense of a
# reference that claims otherwise.
sub _could_be_a_location {
	my $value = shift;

	return $have_validate ? Geo::Coder::Free::Validate::_valid_location($value) : 0;
}

=head1 AUTHOR

Nigel Horne <njh@bandsman.co.uk>

Based on L<Geo::Coder::XYZ>.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

Lots of thanks to the folks at DSTK.

=head1 SEE ALSO

L<Geo::Coder::GooglePlaces>,
L<HTML::GoogleMaps::V3>,
L<http://www.datasciencetoolkit.org/about>.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Geo::Coder::DataScienceToolKit

You can also look for information at:

=over 4

=item * MetaCPAN

L<https://metacpan.org/dist/Geo-Coder-DataScienceToolkit>

=item * RT: CPAN's request tracker

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Geo-Coder-DataScienceToolkit>

=item * CPAN Testers' Matrix

L<http://matrix.cpantesters.org/?dist=Geo-Coder-DataScienceToolkit>

=item * CPAN Testers Dependencies

L<http://deps.cpantesters.org/?module=Geo-Coder-DataScienceToolkit>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2019-2026 Nigel Horne.

This program is released under the following licence: GPL2

=cut

1;
