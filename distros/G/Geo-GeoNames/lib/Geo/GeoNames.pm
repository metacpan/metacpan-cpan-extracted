package Geo::GeoNames;
use utf8;
use v5.10;
use strict;
use warnings;

use Carp;
use Mojo::UserAgent;
use Scalar::Util qw/blessed/;

=encoding utf8

=head1 NAME

Geo::GeoNames - Perform geographical queries using GeoNames Web Services

=head1 VERSION

Version 1.14

=cut

our $VERSION = '1.14';

use vars qw($DEBUG $CACHE);

our %searches = (
	cities                              => 'cities?',
	country_code                        => 'countrycode?type=xml&',
	country_info                        => 'countryInfo?',
	earthquakes                         => 'earthquakesJSON?',
	find_nearby_placename               => 'findNearbyPlaceName?',
	find_nearby_postalcodes             => 'findNearbyPostalCodes?',
	find_nearby_streets                 => 'findNearbyStreets?',
	find_nearby_weather                 => 'findNearByWeatherXML?',
	find_nearby_wikipedia               => 'findNearbyWikipedia?',
	find_nearby_wikipedia_by_postalcode => 'findNearbyWikipedia?',
	find_nearest_address                => 'findNearestAddress?',
	find_nearest_intersection           => 'findNearestIntersection?',
	postalcode_country_info             => 'postalCodeCountryInfo?',
	postalcode_search                   => 'postalCodeSearch?',
	search                              => 'search?',
	wikipedia_bounding_box              => 'wikipediaBoundingBox?',
	wikipedia_search                    => 'wikipediaSearch?',
	get                                 => 'get?',
	hierarchy                           => 'hierarchy?',
	children                            => 'children?',
	);

#   r   = required
#   o   = optional
#   rc  = required - only one of the fields marked with rc is allowed. At least one must be present
#   om  = optional, multiple entries allowed
#   d   = deprecated - will be removed in later versions
our %valid_parameters = (
	search => {
		'q'    => 'rc',
		name    => 'rc',
		name_equals => 'rc',
		maxRows    => 'o',
		startRow    => 'o',
		country    => 'om',
		continentCode    => 'o',
		adminCode1    => 'o',
		adminCode2    => 'o',
		adminCode3    => 'o',
		fclass    => 'omd',
		featureClass    => 'om',
		featureCode => 'om',
		lang    => 'o',
		type    => 'o',
		style    => 'o',
		isNameRequired    => 'o',
		tag    => 'o',
		username => 'r',
		name_startsWith => 'o',
		countryBias => 'o',
		cities => 'om',
		operator => 'o',
		searchlang => 'o',
		charset => 'o',
		fuzzy => 'o',
		north => 'o',
		west => 'o',
		east => 'o',
		south => 'o',
		orderby => 'o',
		},
	postalcode_search => {
		postalcode    => 'rc',
		placename    => 'rc',
		country    => 'o',
		maxRows    => 'o',
		style    => 'o',
		username => 'r',
		},
	find_nearby_postalcodes => {
		lat    => 'r',
		lng    => 'r',
		radius    => 'o',
		maxRows    => 'o',
		style    => 'o',
		country    => 'o',
		username => 'r',
		},
	postalcode_country_info => {
		username => 'r',
		},
	find_nearby_placename => {
		lat    => 'r',
		lng    => 'r',
		radius    => 'o',
		style    => 'o',
		maxRows    => 'o',
		lang => 'o',
		cities => 'o',
		username => 'r',
		},
	find_nearest_address => {
		lat    => 'r',
		lng    => 'r',
		username => 'r',
		},
	find_nearest_intersection => {
		lat    => 'r',
		lng    => 'r',
		username => 'r',
		},
	find_nearby_streets => {
		lat    => 'r',
		lng    => 'r',
		username => 'r',
		},
	find_nearby_wikipedia => {
		lang    => 'o',
		lat    => 'r',
		lng    => 'r',
		radius    => 'o',
		maxRows    => 'o',
		country    => 'o',
		username => 'r',
		},
	find_nearby_wikipedia_by_postalcode => {
		postalcode => 'r',
		country    => 'r',
		radius     => 'o',
		maxRows    => 'o',
		username   => 'r',
		},
	wikipedia_search => {
		'q'      => 'r',
		lang     => 'o',
		title    => 'o',
		maxRows  => 'o',
		username => 'r',
		},
	wikipedia_bounding_box => {
		south    => 'r',
		north    => 'r',
		east     => 'r',
		west     => 'r',
		lang     => 'o',
		maxRows  => 'o',
		username => 'r',
		},
	country_info => {
		country  => 'o',
		lang     => 'o',
		username => 'r',
		},
	country_code => {
		lat      => 'r',
		lng      => 'r',
		lang     => 'o',
		radius   => 'o',
		username => 'r',
		},
	find_nearby_weather => {
		lat      => 'r',
		lng      => 'r',
		username => 'r',
		},
	cities => {
		north      => 'r',
		south      => 'r',
		east       => 'r',
		west       => 'r',
		lang       => 'o',
		maxRows    => 'o',
		username   => 'r',
		},
	earthquakes => {
		north           => 'r',
		south           => 'r',
		east            => 'r',
		west            => 'r',
		date            => 'o',
		minMagnutide    => 'o',
		maxRows         => 'o',
		username        => 'r',
		},
	get => {
		geonameId => 'r',
		lang      => 'o',
		style     => 'o',
		username  => 'r',
		},
	hierarchy => {
		geonameId => 'r',
		username  => 'r',
		style     => 'o',
		},
	children => {
		geonameId => 'r',
		username  => 'r',
		style     => 'o',
		},
	);

sub new {
	my( $class, %hash ) = @_;

	my $self = bless { _functions => \%searches }, $class;

	croak <<"HERE" unless length $hash{username};
You must specify a GeoNames username to use Geo::GeoNames.
See http://www.geonames.org/export/web-services.html
HERE

	$self->username( $hash{username} );
	$self->url( $hash{url} // $self->default_url );

	croak 'Illegal ua object, needs either a Mojo::UserAgent or an LWP::UserAgent derived object'
	   if exists $hash{ua} && !(ref $hash{ua} && blessed($hash{ua}) && ( $hash{ua}->isa('Mojo::UserAgent') || $hash{ua}->isa('LWP::UserAgent') ) );
	$self->ua($hash{ua} || $self->default_ua );

	(exists($hash{debug})) ? $DEBUG = $hash{debug} : 0;
	(exists($hash{cache})) ? $CACHE = $hash{cache} : 0;
	$self->{_functions} = \%searches;

	return $self;
	}

sub username {
	my( $self, $username ) = @_;

	$self->{username} = $username if @_ == 2;

	$self->{username};
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
		$self->{ua} = shift;
	}
	$self->{ua};
}

sub default_ua {
	my $ua = Mojo::UserAgent->new;
	$ua->on( error => sub { carp "Can't get request" } );
	$ua;
	}
sub default_url { 'http://api.geonames.org' }

sub url {
	my( $self, $url ) = @_;

	$self->{url} = $url if @_ == 2;

	$self->{url};
	}

sub _build_request_url {
	my( $self, $request, @args ) = @_;
	my $hash = { @args, username => $self->username };
	my $request_url = $self->url . '/' . $searches{$request};

	# check to see that mandatory arguments are present
	my $conditional_mandatory_flag = 0;
	my $conditional_mandatory_required = 0;
	foreach my $arg (keys %{$valid_parameters{$request}}) {
		my $flags = $valid_parameters{$request}->{$arg};
		if($flags =~ /d/ && exists($hash->{$arg})) {
			carp("Argument $arg is deprecated.");
			}
		$flags =~ s/d//g;
		if($flags eq 'r' && !exists($hash->{$arg})) {
			carp("Mandatory argument $arg is missing!");
			}
		if($flags !~ /m/ && exists($hash->{$arg}) && ref($hash->{$arg})) {
			carp("Argument $arg cannot have multiple values.");
			}
		if($flags eq 'rc') {
			$conditional_mandatory_required = 1;
			if(exists($hash->{$arg})) {
				$conditional_mandatory_flag++;
				}
			}
		}

	if($conditional_mandatory_required == 1 && $conditional_mandatory_flag != 1) {
		carp("Invalid number of mandatory arguments (there can be only one)");
		}
	foreach my $key (sort keys(%$hash)) {
		carp("Invalid argument $key") if(!defined($valid_parameters{$request}->{$key}));
		my @vals = ref($hash->{$key}) ? @{$hash->{$key}} : $hash->{$key};
		no warnings 'uninitialized';
		$request_url .= join('', map { "$key=$_&" } sort @vals );
		}

	chop($request_url); # lose the trailing &
	return $request_url;
	}

sub _parse_xml_result {
	require XML::Simple;
	my( $self, $geonamesresponse, $single_result ) = @_;
	my @result;
	my $xmlsimple = XML::Simple->new;
	my $xml = $xmlsimple->XMLin( $geonamesresponse, KeyAttr => [], ForceArray => 1 );

	if ($xml->{'status'}) {
		carp "GeoNames error: " . $xml->{'status'}->[0]->{message};
		return [];
		}

	$xml = { geoname => [ $xml ], totalResultsCount => '1' } if $single_result;

	my $i = 0;
	foreach my $element (keys %{$xml}) {
		next if (ref($xml->{$element}) ne "ARRAY");
		foreach my $list (@{$xml->{$element}}) {
			next if (ref($list) ne "HASH");
			foreach my $attribute (%{$list}) {
				next if !defined($list->{$attribute}->[0]);
				$result[$i]->{$attribute} = (scalar @{$list->{$attribute}} == 1 ? $list->{$attribute}->[0] : $list->{$attribute});
				}
			$i++;
			}
		}
	return \@result;
	}

sub _parse_json_result {
	require JSON;
	my( $self, $geonamesresponse ) = @_;
	my @result;
	return JSON->new->utf8->decode($geonamesresponse);
	}

sub _parse_text_result {
	my( $self, $geonamesresponse ) = @_;
	my @result;
	$result[0]->{Result} = $geonamesresponse;
	return \@result;
	}

sub _request {
	my( $self, $request_url ) = @_;

	my $res = $self->{ua}->get( $request_url );
	return $res->can('res') ? $res->res : $res;
	}

sub _do_search {
	my( $self, $searchtype, @args ) = @_;

	my $request_url = $self->_build_request_url( $searchtype, @args );
	my $response = $self->_request( $request_url );

	# check mime-type to determine which parse method to use.
	# we accept text/xml, text/plain (how do see if it is JSON or not?)
	my $mime_type = $response->headers->content_type || '';

	my $body = '';
	if ($response->can('body')) {
		$body = $response->body;
		}
	else {
		$body = $response->content;
	}

	if($mime_type =~ m(\Atext/xml;?) ) {
		return $self->_parse_xml_result( $body, $searchtype eq 'get' );
		}
	if($mime_type =~ m(\Aapplication/json;?) ) {
		# a JSON object always start with a left-brace {
		# according to http://json.org/
		if( $body =~ m/\A\{/ ) {
		    if ($response->can('json')) {
				return $response->json;
				}
			else {
				return $self->_parse_json_result( $body );
			}
		}
		else {
			return $self->_parse_text_result( $body );
			}
		}

	if($mime_type eq 'text/plain') {
		carp 'Invalid mime type [text/plain]. ', $response->content();
	} else {
		carp "Invalid mime type [$mime_type]. Maybe you aren't connected.";
	}

	return [];
	}

sub geocode {
	my( $self, $q ) = @_;
	$self->search( 'q' => $q );
	}

sub AUTOLOAD {
	my $self = shift;
	my $type = ref($self) || croak "$self is not an object";
	my $name = our $AUTOLOAD;
	$name =~ s/.*://;

	unless (exists $self->{_functions}->{$name}) {
		croak "No such method '$AUTOLOAD'";
		}

	return($self->_do_search($name, @_));
	}

sub DESTROY { 1 }

1;

__END__

=head1 SYNOPSIS

	use Geo::GeoNames;
	my $geo = Geo::GeoNames->new( username => $username );

	# make a query based on placename
	my $result = $geo->search(q => 'Fredrikstad', maxRows => 2);

	# print the first result
	print " Name: " . $result->[0]->{name};
	print " Longitude: " . $result->[0]->{lng};
	print " Lattitude: " . $result->[0]->{lat};

	# Make a query based on postcode
	my $result = $geo->postalcode_search(
		postalcode => "1630", maxRows => 3, style => "FULL"
		);

=head1 DESCRIPTION

Before you start, get a free GeoNames account and enable it for
access to the free web service:

=over 4

=item * Get an account

Go to L<http://www.geonames.org/login>

=item * Respond to the email

=item * Login and enable your account for free access

L<http://www.geonames.org/enablefreewebservice>

=back

Provides a perl interface to the webservices found at
L<http://api.geonames.org>. That is, given a given placename or
postalcode, the module will look it up and return more information
(longitude, latitude, etc) for the given placename or postalcode.
Wikipedia lookups are also supported. If more than one match is found,
a list of locations will be returned.

=head1 METHODS

=over 4

=item new

	$geo = Geo::GeoNames->new( username => '...' )
	$geo = Geo::GeoNames->new( username => '...', url => $url )

Constructor for Geo::GeoNames. It returns a reference to an
Geo::GeoNames object. You may also pass the url of the webservices to
use. The default value is L<http://api.geonames.org> and is the only url,
to my knowledge, that provides the services needed by this module. The
username parameter is required.

=item ua( $ua )

With a single argument, set the UserAgent to be used by all API calls
and return that UserAgent object. Supports L<Mojo::UserAgent> and
 L<LWP::UserAgent> derivatives.

With no arguments, return the current UserAgent used.

=item username( $username )

With a single argument, set the GeoNames username and return that
username. With no arguments, return the username.

=item default_ua

Returns the default UserAgent used a Mojo::UserAgent object that
carps on errors.

=item default_url

Returns C<http://api.geonames.org>.

=item url( $url )

With a single argument, set the GeoNames url and return that
url. With no arguments, return the url.

=item geocode( $placename )

This method is just an easy access to search. It is the same as
saying:

	$geo->search( q => $placename );

=item search( arg => $arg )

Searches for information about a placename. Valid names for B<arg> are
as follows:

	q               => $placename
	name            => $placename
	name_equals     => $placename
	maxRows         => $maxrows
	startRow        => $startrow
	country         => $countrycode
	continentCode   => $continentcode
	adminCode1      => $admin1
	adminCode2      => $admin2
	adminCode3      => $admin3
	fclass          => $fclass
	featureClass    => $fclass,
	featureCode     => $code
	lang            => $lang
	type            => $type
	style           => $style
	isNameRequired  => $isnamerequired
	tag             => $tag
	name_startsWith => $name_startsWith
	countryBias     => $countryBias
	cities          => $cities
	operator        => $operator
	searchlang      => $searchlang
	charset         => $charset
	fuzzy           => $fuzzy
	north           => $north
	west            => $west
	east            => $east
	south           => $south
	orderby         => $orderby

One, and only one, of B<q>, B<name>, B<name_equals>, or B<name_startsWith> must be
supplied to this method.

fclass is deprecated.

For a thorough description of the arguments, see
L<http://www.geonames.org/export/geonames-search.html>

=item find_nearby_placename( arg => $arg )

Reverse lookup for closest placename to a given coordinate. Valid
names for B<arg> are as follows:

	lat     => $lat
	lng     => $lng
	radius  => $radius
	style   => $style
	maxRows => $maxrows

Both B<lat> and B<lng> must be supplied to this method.

For a thorough descriptions of the arguments, see
L<http://www.geonames.org/export>

=item find_nearest_address(arg => $arg)

Reverse lookup for closest address to a given coordinate. Valid names
for B<arg> are as follows:

	lat => $lat
	lng => $lng

Both B<lat> and B<lng> must be supplied to this method.

For a thorough descriptions of the arguments, see
L<http://www.geonames.org/maps/reverse-geocoder.html>

US only.

=item find_nearest_intersection(arg => $arg)

Reverse lookup for closest intersection to a given coordinate. Valid
names for B<arg> are as follows:

	lat => $lat
	lng => $lng

Both B<lat> and B<lng> must be supplied to this method.

For a thorough descriptions of the arguments, see
L<http://www.geonames.org/maps/reverse-geocoder.html>

US only.

=item find_nearby_streets(arg => $arg)

Reverse lookup for closest streets to a given coordinate. Valid names
for B<arg> are as follows:

	lat => $lat
	lng => $lng

Both B<lat> and B<lng> must be supplied to this method.

For a thorough descriptions of the arguments, see
L<http://www.geonames.org/maps/reverse-geocoder.html>

US only.

=item postalcode_search(arg => $arg)

Searches for information about a postalcode. Valid names for B<arg>
are as follows:

	postalcode => $postalcode
	placename  => $placename
	country    => $country
	maxRows    => $maxrows
	style      => $style

One, and only one, of B<postalcode> or B<placename> must be supplied
to this method.

For a thorough description of the arguments, see
L<http://www.geonames.org/export>

=item find_nearby_postalcodes(arg => $arg)

Reverse lookup for postalcodes. Valid names for B<arg> are as follows:

	lat     => $lat
	lng     => $lng
	radius  => $radius
	maxRows => $maxrows
	style   => $style
	country => $country

Both B<lat> and B<lng> must be supplied to this method.

For a thorough description of the arguments, see
L<http://www.geonames.org/export>

=item postalcode_country_info

Returns a list of all postalcodes found on GeoNames. This method
takes no arguments.

=item country_info(arg => $arg)

Returns country information. Valid names for B<arg> are as follows:

	country => $country
	lang    => $lang

For a thorough description of the arguments, see
L<http://www.geonames.org/export>

=item find_nearby_wikipedia(arg => $arg)

Reverse lookup for Wikipedia articles. Valid names for B<arg> are as
follows:

	lat     => $lat
	lng     => $lng
	radius  => $radius
	maxRows => $maxrows
	lang    => $lang
	country => $country

Both B<lat> and B<lng> must be supplied to this method.

For a thorough description of the arguments, see
L<http://www.geonames.org/export>

=item find_nearby_wikipediaby_postalcode(arg => $arg)

Reverse lookup for Wikipedia articles. Valid names for B<arg> are as
follows:

	postalcode => $postalcode
	country    => $country
	radius     => $radius
	maxRows    => $maxrows

Both B<postalcode> and B<country> must be supplied to this method.

For a thorough description of the arguments, see
L<http://www.geonames.org/export>

=item wikipedia_search(arg => $arg)

Searches for Wikipedia articles. Valid names for B<arg> are as
follows:

	q       => $placename
	maxRows => $maxrows
	lang    => $lang
	title   => $title

B<q> must be supplied to this method.

For a thorough description of the arguments, see
L<http://www.geonames.org/export>

=item wikipedia_bounding_box(arg => $arg)

Searches for Wikipedia articles. Valid names for B<arg> are as
follows:

	south   => $south
	north   => $north
	east    => $east
	west    => $west
	lang    => $lang
	maxRows => $maxrows

B<south>, B<north>, B<east>, and B<west> and must be supplied to this method.

For a thorough description of the arguments, see
L<http://www.geonames.org/export>

=item cities(arg => $arg)

Returns a list of cities and placenames within the bounding box.
Valid names for B<arg> are as follows:

	south   => $south
	north   => $north
	east    => $east
	west    => $west
	lang    => $lang
	maxRows => $maxrows

B<south>, B<north>, B<east>, and B<west> and must be supplied to this method.

For a thorough description of the arguments, see
L<http://www.geonames.org/export>

=item country_code(arg => $arg)

Return the country code for a given point. Valid names for B<arg> are
as follows:

	lat    => $lat
	lng    => $lng
	radius => $radius
	lang   => $lang

Both B<lat> and B<lng> must be supplied to this method.

For a thorough description of the arguments, see
L<http://www.geonames.org/export>

=item earthquakes(arg => $arg)

Returns a list of cities and placenames within the bounding box.
Valid names for B<arg> are as follows:

	south        => $south
	north        => $north
	east         => $east
	west         => $west
	date         => $date
	minMagnitude => $minmagnitude
	maxRows      => $maxrows

B<south>, B<north>, B<east>, and B<west> and must be supplied to this method.

For a thorough description of the arguments, see
L<http://www.geonames.org/export>

=item find_nearby_weather(arg => $arg)

Return the country code for a given point. Valid names for B<arg> are
as follows:

	lat => $lat
	lng => $lng

Both B<lat> and B<lng> must be supplied to this method.

For a thorough description of the arguments, see
L<http://www.geonames.org/export>

=item get(arg => $arg)

Returns information about a given place based on a geonameId.

	geonameId  => $geonameId
	lang       => $lang
	style      => $style (Seems to be ignored, although documented)

B<geonamesId> must be supplied to this method. B<lang> and B<style> are optional.

For a thorough description of the arguments, see
L<http://www.geonames.org/export>

=item hiearchy(arg => $arg)

Returns all GeoNames higher up in the hierarchy of a place based on a geonameId.

    geonameId => $geonameId
    style     => $style (Not documented, but seems to be respected)

B<geonamesId> must be supplied to this method. B<style> is optional.

For a thorough description of the arguments, see
L<http://www.geonames.org/export/place-hierarchy.html#hierarchy>

=item children(arg => $arg)

Returns the children (admin divisions and populated places) for a given geonameId.

    geonameId => $geonameId
    style     => $style (Not documented, but seems to be respected)

B<geonamesId> must be supplied to this method. B<style> is optional.

For a thorough description of the arguments, see
L<https://www.geonames.org/export/place-hierarchy.html>

=back

=head1 RETURNED DATASTRUCTURE

The datastructure returned from methods in this module is an array of
hashes. Each array element contains a hash which in turn contains the
information about the placename/postalcode.

For example, running the statement

	my $result = $geo->search(
		q => "Fredrikstad", maxRows => 3, style => "FULL"
		);

yields the result:

	$VAR1 = {
		'population' => {},
		'lat' => '59.2166667',
		'elevation' => {},
		'countryCode' => 'NO',
		'adminName1' => "\x{d8}stfold",
		'fclName' => 'city, village,...',
		'adminCode2' => {},
		'lng' => '10.95',
		'geonameId' => '3156529',
		'timezone' => {
			'dstOffset' => '2.0',
			'content' => 'Europe/Oslo',
			'gmtOffset' => '1.0'
			},
		'fcode' => 'PPL',
		'countryName' => 'Norway',
		'name' => 'Fredrikstad',
		'fcodeName' => 'populated place',
		'alternateNames' => 'Frederikstad,Fredrikstad,Fredrikstad kommun',
		'adminCode1' => '13',
		'adminName2' => {},
		'fcl' => 'P'
		};

The elements in the hashes depends on which B<style> is passed to the
method, but will always contain B<name>, B<lng>, and B<lat> except for
postalcode_country_info(), find_nearest_address(),
find_nearest_intersection(), and find_nearby_streets().

=head1 BUGS

Not a bug, but the GeoNames services expects placenames to be UTF-8
encoded, and all data received from the webservices are also UTF-8
encoded. So make sure that strings are encoded/decoded based on the
correct encoding.

Please report any bugs found or feature requests through GitHub issues
L<https://github.com/nigelhorne/Geo-GeoNames/issues>.
or
C<bug-geo-geonamnes at rt.cpan.org>,
or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Geo-GeoNames>.
I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SEE ALSO

=over 4

=item * L<http://www.geonames.org/export>

=item * L<http://www.geonames.org/export/ws-overview.html>

=back

=head1 SOURCE AVAILABILITY

The source code for this module is available from Github
at L<https://github.com/nigelhorne/Geo-GeoNames>.

=head1 AUTHOR

Per Henrik Johansen, C<< <per.henrik.johansen@gmail.com> >>.

Previously maintained by brian d foy, C<< <brian.d.foy@gmail.com> >>
and Nicolas Mendoza, C<< <mendoza@pvv.ntnu.no> >>

Maintained by Nigel Horne, C<< <njh at bandsman.co.uk> >>

=head1 COPYRIGHT AND LICENSE

Copyright © 2007-2021 by Per Henrik Johansen
Copyright © 2022 by Nigel Horne

This library is available under the Artistic License 2.0.

=cut
