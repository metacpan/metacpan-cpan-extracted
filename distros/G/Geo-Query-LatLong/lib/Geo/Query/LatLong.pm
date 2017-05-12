package Geo::Query::LatLong;

############################################################
# Geo::Query::LatLong
#
# Author: Reto Schaer
# Copyright (c) 2007 - 2008
#
# http://meta.pgate.net/geo-query-latlong/
#
our $VERSION = '0.8011';
############################################################

use strict;

use LWP::UserAgent;
use HTTP::Request::Common;

# GLOBAL VARIABLES
my $package = __PACKAGE__;
my %Var = ();
my $contentType = "";
my $ua;
$| = 1;

#-----  FORWARD DECLARATIONS & PROTOTYPING
sub Debug($);

sub new {
	my $type = shift;
	my %params = @_;
	my $self = {};
	$self->{'debug' } = $params{'debug' };
	$self->{'source'} = $params{'source'} || 'geo'.'111';
	Debug "$package V$VERSION" if $self->{'debug'};
	$ua = LWP::UserAgent->new( agent => "Geo::Query::LatLong $VERSION" );

	$Var{'source'} = 'geo'.'111';
	if ($self->{'source'} eq 'Google') {
		$self->{'apikey'} = $params{'apikey'} || '';
		unless ($self->{'apikey'}) {
			print STDERR "ERR: apikey required.\n";
		}
		else {
			# Everything looks good so far
			$Var{'source'} = 'Google';
		}
	}

	bless $self, $type;
}

sub query {
	my $self = shift;
	my %args = @_;

	$args{'country_code'} ||= 'SZ'; # FIPS 10
	$args{'city'        } ||= ''  ; # e.g. Zurich
	$args{'exact'       } ||= 'on';

	my %res_hash = ();
	   $res_hash{'rc'} = 0;
	   $res_hash{'lat'} = $res_hash{'lng'} = 99; # init
	   $res_hash{'source'} = $Var{'source'};

	if ($self->{'debug'}) { Debug "$_ = $args{$_}" foreach keys %args; }

	if ($Var{'source'} eq 'Google') {
		Debug 'Google API query.' if $self->{'debug'};
		my $location = &google_query($self, location => $args{'city'} );
		my @point = ();
		if (defined @{$location->{'Point'}->{'coordinates'}}) {
			$res_hash{'address'} = $location->{'address'};
			@point = @{$location->{'Point'}->{'coordinates'}};
			$res_hash{'lng'} = $point[0];
			$res_hash{'lat'} = $point[1];
		}
	}
	else {
		my $url = 'http://geo.pg' . 'ate.net/query/';
		my $r = HTTP::Request->new('GET', $url .
			"?city=$args{'city'}&country_code=$args{'country_code'}&exact=$args{'exact'}");
		my $resp = $ua->request($r);

		if ($resp->is_success) {
			my @lines = split /\n/, $resp->content();
			my $result = '';
			foreach (@lines) {
				my ($key, $val) = split /\t/;
				$res_hash{$key} = $val;
			}
		}
	}

	\%res_hash;
}

sub google_query(%) {
	my $self = shift;
	my %args = @_;
	$args{'location'} ||= '';

	eval 'use JSON::Syck; 1' or print STDERR "ERR JSON::Syck is missing\n";
	use Encode;
	# use URI;

	my $uri = URI->new("http://maps.google.com/maps/geo");
	   $uri->query_form(q => $args{'location'}, output => 'json', key => $self->{'apikey'});

	my $res = $ua->get($uri);

	# Content-Type: text/javascript; charset=UTF-8; charset=Shift_JIS
	my @ctype = $res->content_type;
	my $charset = ($ctype[1] =~ /charset=([\w\-]+)$/)[0] || "utf-8"; # Thanks to Tatsuhiko Miyagawa from Geo-Coder-Google

	my $content = Encode::decode($charset, $res->content);

	local $JSON::Syck::ImplicitUnicode = 1;
	1 if defined $JSON::Syck::ImplicitUnicode; # prevent warning
	my $data = JSON::Syck::Load($content);

	my @placemark = @{ $data->{Placemark} || [] };

	wantarray ? @placemark : $placemark[0];
}

sub Debug ($)  { print "[ $package ] $_[0]\n"; }

####  Used Warning / Error Codes  ##########################
#	Next free W Code: 1000
#	Next free E Code: 1000

####  Var
#	- source: geo.111 || Google
#	- Google_h

1;

__END__

=head1 NAME

Geo::Query::LatLong - Uniform interface to query latitude and longitude from a city.

=head1 SYNOPSIS

  use Geo::Query::LatLong;

  # Generic source
  $geo = Geo::Query::LatLong->new( debug => 0 );

or

  # Using Google Maps API
  $geo = Geo::Query::LatLong->new( source => 'Google', apikey => 'Your API key' );

=head1 DESCRIPTION

Query latitude and longitude from a city in any country. Useful to open specific locations in a Browser map. You can use a generic server or query the Google Maps API. In case of Google Maps you had to supply your Google key. Geo::Query::LatLong returns an uniform response independent of the chosen server.

=head2 Query example

  use Geo::Query::LatLong;

  $CITY = $ARGV[0] || 'Zurich';

  $res = $geo->query( city => $CITY, country_code => 'SZ' ); # FIPS 10 country code

  print "Latitude and longitude of $CITY: ",
		$res->{'lat'}, ' / ', $res->{'lng'}, "\n";

=head3 List all results from your query

  foreach (keys %{$res}) {
	print "$_ = ", $res->{$_}, "\n";
  }

=head2 Another example

Switch exactness to "off" will increase the chance you get a result.

  $res = $geo->query( city => 'Unterwalden', country_code => 'SZ', exact => 'off' ); # exact default: on

  print "-- $_ = ", $res->{$_}, "\n" foreach keys %{$res};

=head3 Parameter country_code (not required for Google API)

Country Codes according to FIPS 10: http://de.wikipedia.org/wiki/FIPS_10

=head3 Parameter city

Use the english translations for the city names, e.g. Zurich for Zuerich, Munich for Muenchen.

In conjunction with Google API you can send arguments like "Bellevue Zurich, Switzerland" as well.

=head2 Return values

The function query(...) always returns a hash reference. Hash key 'rc' is retured as 0 (Zero) on success and unequal 0 on a failure.
Additionally it is a good advice to read or display the 'msg' key on a failure to get a hint about the cause.

B<On case the city was not found:>

=item *

Hash key 'rc' returns a number unequal to zero.

=item *

Hash keys 'lat' / 'lng' are always being returned as '99' / '99'.

=head2 EXPORT

None by default.

=head1 Further documentation and feedback

http://meta.pgate.net/geo-query-latlong/

http://www.infocopter.com/perl/modules/

=head1 SEE ALSO

The Geo::Coder series here on CPAN.

=head1 AUTHOR

Reto Schaer, E<lt>retoh@cpan-cuthere.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007 - 2008 by Reto Schaer

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

http://www.infocopter.com/perl/licencing.html

=cut
