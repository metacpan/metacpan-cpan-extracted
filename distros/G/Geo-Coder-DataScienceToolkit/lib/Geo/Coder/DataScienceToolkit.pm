package Geo::Coder::DataScienceToolkit;

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
use LWP::Protocol::http;
use Object::Configure 0.14;
use URI;

=head1 NAME

Geo::Coder::DataScienceToolkit - Provides a geocoding functionality using
http://www.datasciencetoolkit.org/

=head1 VERSION

Version 0.04

=cut

our $VERSION = '0.04';

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

A hashref of the same arguments is accepted as well:

    $geocoder = Geo::Coder::DataScienceToolkit->new({ ua => $ua });

An odd number of arguments is refused rather than read as a key with no value.

=cut

sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;

	# Object::Configure::configure() takes a hashref of the caller's values, not
	# the argument list: handing it \@_ made every call that passed a value die
	# with "Not a HASH reference", which is why new(ua => $ua) - the form the
	# POD documents - did not work.  A hashref is accepted as well as a list, so
	# that neither spelling of the same arguments is a surprise.
	my %args;
	if(@_ == 1 && ref($_[0]) eq 'HASH') {
		%args = %{$_[0]};
	} else {
		Carp::croak('Usage: ', __PACKAGE__, '->new(ua => $ua)') if(@_ % 2);
		%args = @_;
	}

	my $params = Object::Configure::configure($class, \%args);

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
