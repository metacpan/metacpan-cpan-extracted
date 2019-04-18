=head1 NAME

Geo::WebService::Elevation::USGS - Elevation queries against USGS web services.

=head1 SYNOPSIS

 use Geo::WebService::Elevation::USGS;
 
 my $eq = Geo::WebService::Elevation::USGS->new();
 print "The elevation of the White House is ",
   $eq->elevation( 38.898748, -77.037684 )->{Elevation},
   " feet above sea level.\n";

=head1 NOTICE

Version 0.106_01 changes the default value of the C<'compatible'>
attribute to C<0> (i.e. false). With version 0.108_01, the
first attempt to modify this attribute will warn. With version
0.110_01, all attempts to modify this attribute will warn,
and six months after the release of this version, any attempt to modify
it will become fatal.

The GIS data web service this module was originally based on has gone
the way of the dodo. This release uses the NED service, which is similar
but simpler. I have taken advantage of the new service's ability to
provide output in JSON to simplify processing, and have added a
compatibility mode to make the output from the new service as much like
the output of the old as possible, but there are still differences:

* The new service does not expose data source selection. Therefore all
functionality related to selecting data from a particular source now
does nothing.

* The new service does not support retrieval of data from more than one
source. Therefore any functionality that used to do this now returns
data from a single source.

* The new service does not return the C<{Data_ID}> information in any
way whatsoever. So, at least in compatibility mode, this is set to the
value of C<{Data_Source}>.

* The new service does not report extent errors. Instead it appears to
return an elevation of C<0>.

* The structure returned by the new service is similar to that returned
by the old service, but the top-level hash key name is different. This
module will attempt to hide this difference in compatibility mode.

Because this module attempts to hide the differences from the data
returned by the old service, a new attribute, C<compatible>, is added to
manage this. If this attribute is true (the default) returned data will
be as close to the old server's data as possible.

With release 0.100, the following functionality is
deprecated:

* Attributes C<default_ns>, C<proxy>, C<source>, and C<use_all_limit>.

* Methods C<getElevation()> and C<getAllElevations()>. The
C<elevation()> method will remain.

Starting with release 0.104_01, all deprecated functionality warns
every time it is used. The plan was to make these fatal in another six
months, but that fell in the cracks, and when I revisited it I thought
the change in the default value of the C<'compatible'> attribute (to
false, see below) was disruptive enough that I would make it a release
by itself. The current plan is to delay making the deprecated methods
fatal the C<compatible> attribute becomes fatal.

In the meantime you can suppress the warnings with

 no warnings qw{ deprecated };

The C<compatible> attribute is deprecated as of release 0.104_01. As of
release 0.106_01 it will warn when set true. In the first
release after March 1 2019 it will warn on any use. Six months after
that, it will become a fatal error to use it.

=head1 DESCRIPTION

This module executes elevation queries against the United States
Geological Survey's web NAD server. You provide the latitude and longitude
in degrees, with south latitude and west longitude being negative. The
return is typically a hash containing the data you want. Query errors
are exceptions by default, though the object can be configured to signal
an error by an undef response, with the error retrievable from the
'error' attribute.

For documentation on the underlying web service, see
L<http://ned.usgs.gov>.

For all methods, the input latitude and longitude are documented at the
above web site as being WGS84, which for practical purposes I understand
to be equivalent to NAD83. The vertical reference is not documented
under the above link, but correspondence with the USGS says that it is
derived from the National Elevation Dataset (NED; see
L<http://ned.usgs.gov>). This is referred to NAD83 (horizontal) and
NAVD88 (vertical). NAVD88 is based on geodetic leveling surveys, B<not
the WGS84/NAD83 ellipsoid,> and takes as its zero datum sea level at
Father Point/Rimouski, in Quebec, Canada. Alaska is an exception, and is
based on NAD27 (horizontal) and NAVD29 (vertical).

Anyone interested in the gory details may find the paper I<Converting
GPS Height into NAVD88 Elevation with the GEOID96 Geoid Height Model> by
Dennis G. Milbert, Ph.D. and Dru A. Smith, Ph.D helpful. This is
available at L<http://www.ngs.noaa.gov/PUBS_LIB/gislis96.html>. This
paper states that the difference between ellipsoid and geoid heights
ranges between -75 and +100 meters globally, and between -53 and -8
meters in "the conterminous United States."

=head2 Methods

The following public methods are provided:

=cut

package Geo::WebService::Elevation::USGS;

use 5.008;

use strict;
use warnings;

use Carp;
use HTTP::Request::Common;
use JSON;
use LWP::UserAgent;
use Scalar::Util 1.10 qw{ blessed looks_like_number };

our $VERSION = '0.112';

use constant BEST_DATA_SET => -1;
use constant USGS_URL => 'http://ned.usgs.gov/epqs/pqs.php';

use constant ARRAY_REF	=> ref [];
use constant CODE_REF	=> ref sub {};
use constant HASH_REF	=> ref {};
use constant REGEXP_REF	=> ref qr{};

my $using_time_hires;
{
    my $mark;
    if ( eval {
	    require Time::HiRes;
	    Time::HiRes->can( 'time' ) && Time::HiRes->can( 'sleep' );
	} ) {
	*_time = \&Time::HiRes::time;
	*_sleep = \&Time::HiRes::sleep;
	$using_time_hires = 1;
    } else {
	*_time = sub { return time };
	*_sleep = sub { return sleep $_[0] };
    }

    $mark = _time();
    sub _pause {
##	my ( $self ) = @_;	# Invocant unused
	my $now = _time();
	while ( $now < $mark ) {
	    _sleep( $mark - $now );
	    $now = _time();
	}
	# We use __PACKAGE__ rather than $self because the attribute is
	# static, and it needs to be static because it needs to apply to
	# everything coming from this user, not just everything coming
	# from the invoking object.
	$mark = $now + __PACKAGE__->get( 'throttle' );
	return;
    }
}

=head3 $eq = Geo::WebService::Elevation::USGS->new();

This method instantiates a query object. If any arguments are given,
they are passed to the set() method. The instantiated object is
returned.

=cut

sub new {
    my ($class, @args) = @_;
    ref $class and $class = ref $class;
    $class or croak "No class name specified";
    shift;
    my $self = {
	carp	=> 0,
	compatible	=> 0,
	croak	=> 1,
	default_ns	=> 'http://gisdata.usgs.gov/XMLWebServices2/',
	error	=> undef,
	places	=> undef,
	proxy	=>
	    'http://gisdata.usgs.gov/XMLWebServices2/Elevation_Service.asmx',
	retry	=> 0,
	retry_hook => sub {},
	source	=> BEST_DATA_SET,
	timeout	=> 30,
	trace	=> undef,
	units	=> 'FEET',
	usgs_url	=> $ENV{GEO_WEBSERVICE_ELEVATION_USGS_URL} || USGS_URL,
	use_all_limit => 5,
    };
    bless $self, $class;
    @args and $self->set(@args);
    return $self;
}

my %mutator = (
    croak	=> \&_set_literal,
    carp	=> \&_set_literal,
    compatible	=> \&_set_literal,
    default_ns	=> \&_set_literal,
    error	=> \&_set_literal,
    places	=> \&_set_integer_or_undef,
    proxy	=> \&_set_literal,
    retry	=> \&_set_unsigned_integer,
    retry_hook	=> \&_set_hook,
    source	=> \&_set_source,
    throttle	=> \&_set_throttle,
    timeout	=> \&_set_integer_or_undef,
    trace	=> \&_set_literal,
    units	=> \&_set_literal,
    usgs_url	=> \&_set_literal,
    use_all_limit => \&_set_integer,
);

my %access_type = (
    throttle	=> \&_only_static_attr,
);

foreach my $name ( keys %mutator ) {
    exists $access_type{$name}
	or $access_type{$name} = \&_no_static_attr;
}

=head3 %values = $eq->attributes();

This method returns a list of the names and values of all attributes of
the object. If called in scalar context it returns a hash reference.

=cut

sub attributes {
    my $self = shift;
    my %attr;
    foreach (keys %mutator) {
	$attr{$_} = $self->{$_};
    }
    return wantarray ? %attr : \%attr;
}

=head3 $rslt = $usgs->elevation($lat, $lon, $valid);

This method queries the data base for the elevation at the given
latitude and longitude, returning the results as a hash reference. This
hash will contain the following keys:

{Data_Source} => A text description of the data source;

{Elevation} => The elevation in the given units;

{Units} => The units of the elevation (C<'Feet'> or C<'Meters'>);

{x} => The C<$lon> argument;

{y} => The C<$lat> argument.

For compatibility with versions of this module before C<0.100>, this
method behaves slightly differently if the L<compatible|/compatible>
attribute is true:

* The C<{Data_ID}> key of the return will be set to the value of the
{Data_Source} key;

* The C<{Units}> key will be converted to upper case;

* If called in scalar context the return will be a reference to an array
whose single element is the results hash.

B<Note> that as of version 0.106_01, the default for this
attribute is B<false>.

You can also pass a C<Geo::Point>, C<GPS::Point>, or C<Net::GPSD::Point>
object in lieu of the C<$lat> and C<$lon> arguments. If you do this,
C<$valid> becomes the second argument, rather than the third.

If the optional C<$valid> argument is specified and the returned data
are invalid, nothing is returned. This means an empty array if
L<compatible|/compatible> is true. The NAD source does not seem to
produce data recognizable as invalid, so you will probably not see this.

The NAD server appears to return an elevation of C<0> if the elevation
is unavailable.

=cut

sub elevation {
    my ( $self, $lat, $lon, $valid ) = _latlon( @_ );

    my $rslt = $self->_elevation( $lat, $lon, $valid )
	or return;

    # TODO compatibility
    $self->get( 'compatible' )
	or return $rslt;
    return wantarray ? $rslt : [ $rslt ];
}

=head3 $value = $eq->get($attribute);

This method returns the value of the given attribute. It will croak if
the attribute does not exist.

=cut

sub get {
    my ($self, $name) = @_;
    $access_type{$name}
	or croak "No such attribute as '$name'";
    my $holder = $access_type{$name}->( $self, $name );
    return $holder->{$name};
}

=head3 $rslt = $eq->getAllElevations($lat, $lon, $valid);

Starting with version 0.100, this method is essentially a wrapper for
the C<elevation()> method. For compatibility with the prior version of
this module it returns an array reference in scalar context.

=cut

sub getAllElevations {
    my ( $self, $lat, $lon, $valid ) = _latlon( @_ );

    _deprecate( 'subroutine' );

    my $rslt = $self->_elevation( $lat, $lon, $valid )
	or return;

    return wantarray ? $rslt : [ $rslt ];
}

=head3 $rslt = $eq->getElevation($lat, $lon, $source, $elevation_only);

Starting with version 0.100, this method is essentially a wrapper for
the C<elevation()> method.

The C<$source> argument is both optional and ignored, but must be
present for backwards compatibility if the C<$elevation_only> argument
is used. Feel free to pass C<undef>.

The C<$elevation_only> argument is optional. If provided and true (in the
Perl sense) it causes the return on success to be the numeric value of
the elevation, rather than the hash reference described below.

=cut

sub getElevation {
    my ($self, $lat, $lon, undef, $only) = _latlon( @_ );

    _deprecate( 'subroutine' );

    my $rslt = $self->_elevation( $lat, $lon )
	or return;

    return $only ? $rslt->{Elevation} : $rslt;
}

=head3 $boolean = $eq->is_valid($elevation);

This method (which can also be called as a static method or as a
subroutine) returns true if the given datum represents a valid
elevation, and false otherwise. A valid elevation is a number having a
value greater than -1e+300. The input can be either an elevation value
or a hash whose {Elevation} key supplies the elevation value.

=cut

sub is_valid {
    my $ele = pop;
    my $ref = ref $ele;
    if ( HASH_REF eq $ref ) {
	$ele = $ele->{Elevation};
    } elsif ($ref) {
	croak "$ref reference not understood";
    }
    return defined( $ele ) && looks_like_number($ele) && $ele > -1e+300;
}

=head3 $eq = $eq->set($attribute => $value ...);

This method sets the value of the given attribute. Multiple
attribute/value pairs may be specified. The object itself is returned,
to allow call chaining. An attempt to set a non-existent attribute will
result in an exception being thrown.

=cut


{

    # Changes in these values require re-instantiating the transport
    # object. Or at least, they may do, under the following assumptions:
    # SOAP: default_ns, proxy, timeout;
    # HTTP_Post: timeout.
    my %clean_transport_object = map { $_ => 1 } qw{ default_ns proxy timeout };

    sub set {	## no critic (ProhibitAmbiguousNames)
	my ($self, @args) = @_;
	my $clean;
	while (@args) {
	    my ( $name, $val ) = splice @args, 0, 2;
	    $access_type{$name}
		or croak "No such attribute as '$name'";
	    exists $mutator{$name}
		or croak "Attribute '$name' is read-only";
	    _deprecate( attribute => $name );
	    my $holder = $access_type{$name}->( $self, $name );
	    $mutator{$name}->( $holder, $name, $val );
	    $clean ||= $clean_transport_object{$name};
	}
	$clean and delete $self->{_transport_object};
	return $self;
    }

}

sub _set_hook {
    my ( $self, $name, $val ) = @_;
    CODE_REF eq ref $val
	or croak "Attribute $name must be a code reference";
    return( $self->{$name} = $val );
}

sub _set_integer {
    my ($self, $name, $val) = @_;
    (!defined $val || $val !~ m/ \A [-+]? \d+ \z /smx)
	and croak "Attribute $name must be an integer";
    return ($self->{$name} = $val + 0);
}

sub _set_integer_or_undef {
    my ($self, $name, $val) = @_;
    (defined $val && $val !~ m/ \A \d+ \z /smx)
	and croak "Attribute $name must be an unsigned integer or undef";
    return ($self->{$name} = $val);
}

sub _set_literal {
    return $_[0]{$_[1]} = $_[2];
}

{
    my %supported = map { $_ => 1 } ARRAY_REF, CODE_REF, HASH_REF,
	REGEXP_REF;

    sub _set_source {
	my ($self, $name, $val) = @_;
	my $ref = ref $val;
	($ref && !$supported{$ref})
	    and croak "Attribute $name may not be a $ref ref";
	return ($self->{$name} = $val);
    }
}

sub _set_throttle {
    my ( $self, $name, $val ) = @_;
    if ( defined $val ) {
	looks_like_number( $val )
	    and $val >= 0
	    or croak "The $name attribute must be undef or a ",
		'non-negative number';
	$using_time_hires
	    or $val >= 1
	    or $val == 0
	    or $val = 1;
    } else {
	$val = 0;
    }
    return( $self->{$name} = $val );
}

sub _set_unsigned_integer {
    my ($self, $name, $val) = @_;
    ( !defined $val || $val !~ m/ \A \d+ \z /smx )
	and croak "Attribute $name must be an unsigned integer";
    return ($self->{$name} = $val + 0);
}

########################################################################
#
#	Private methods
#
#	The author reserves the right to change these without notice.

{
    # NOTE to me: The deprecation of everything but 'compatible' is on
    # hold until 'compatible' gets to 2. Then everything goes to 3
    # together.
    my %dep = (
	attribute	=> {
	    dflt	=> sub { return },
	    item	=> {
		compatible	=> 2,
		default_ns	=> 2,
		proxy		=> 2,
		source		=> 2,
		use_all_limit	=> 2,
	    },
	},
	subroutine	=> {
	    dflt	=> sub {
		( my $name = ( caller( 2 ) )[3] ) =~ s/ .* :: //smx;
		return $name;
	    },
	    item	=> {
		getElevation		=> 2,
		getAllElevations	=> 2,
	    },
	},
    );

    sub _deprecate {
	my ( $group, $item ) = @_;
	my $info = $dep{$group}
	    or confess "Programming error - Deprecation group '$group' unknown";
	defined $item
	    or defined( $item = $info->{dflt}->() )
	    or croak "Programming error - No item default for group '$group'";
	$info->{item}{$item}
	    or return;
	my $msg = ucfirst "$group $item is deprecated";
	$info->{item}{$item} > 2
	    and croak "Fatal - $msg";
	warnings::enabled( 'deprecated' )
	    or return;
	carp "Warning - $msg";
	$info->{item}{$item} == 1
	    and $info->{item}{$item} = 0;
	return;
    }
}

#	$rslt = $ele->_elevation( $lat, $lon, $only );
#
#	This is the prospective elevation(), once compatibility goes
#	away.

sub _elevation {
    my ( $self, $lat, $lon, $valid ) = _latlon( @_ );
    my $retry_limit = $self->get( 'retry' );
    my $retry = 0;

    while ( $retry++ <= $retry_limit ) {

	$self->{error} = undef;

	$self->_pause();

	my $rslt;
	eval {
	    $rslt = $self->_request(
		x	=> $lon,
		y	=> $lat,
		units	=> $self->{units},
	    );
	    1;
	} or do {
	    $self->_error( $@ );
	    next;
	};

	$rslt
	    or next;

	not $valid
	    or is_valid( $rslt )
	    or next;

	return $rslt;

    } continue {

	if ( $retry <= $retry_limit ) {
	    ( my $sub = ( caller( 0 ) )[3] ) =~ s/ .* :: //smx;
	    $self->get( 'retry_hook' )->( $self, $retry, $sub, $lat,
		$lon );
	}

    }

    $self->{croak} and croak $self->{error};
    return;

}

#	$ele->_error($text);
#
#	Set the error attribute, and croak if the croak attribute is
#	true. If croak is false, just return, carping if the carp
#	attribute is true.

sub _error {
    my ($self, @args) = @_;
    $self->{error} = join '', @args;
##  $self->{croak} and croak $self->{error};
    $self->{croak} and return;
    $self->{carp} and carp $self->{error};
    return;
}

#	_instance( $object, $class )
#	    and print "\$object isa $class\n";
#
#	Return true if $object is an instance of class $class, and false
#	otherwise. Unlike UNIVERSAL::isa, this is false if the first
#	object is not a reference.

sub _instance {
    my ( $object, $class ) = @_;
    blessed( $object ) or return;
    return $object->isa( $class );
}

#	my ($self, $lat, $lon, @_) = _latlon(@_);
#
#	Strip the object reference, latitude, and longitude off the
#	argument list. If the first argument is a Geo::Point,
#	GPS::Point, or Net::GPSD::Point object the latitude and
#	longitude come from it.  Otherwise the first argument is assumed
#	to be latitude, and the second to be longitude.

{

    my %known = (
	'Geo::Point' => sub {$_[0]->latlong('wgs84')},
	'GPS::Point' => sub {$_[0]->latlon()},
	'Net::GPSD::Point' => sub {$_[0]->latlon()},
    );

    sub _latlon {
	my ($self, $obj, @args) = @_;
	foreach my $class (keys %known) {
	    if (_instance( $obj, $class ) ) {
		return ($self, $known{$class}->($obj), @args);
	    }
	}
	return ($self, $obj, @args);
    }
}

{
    my %static = (	# Static attribute values.
	throttle => 0,
    );

#	$self->_no_static_attr( $name );
#
#	Croaks if the invocant is not a reference. The message assumes
#	the method was called trying to access an attribute, whose name
#	is $name.

    sub _no_static_attr {
	my ( $self, $name ) = @_;
	ref $self
	    or croak "Attribute $name may not be accessed statically";
	return $self;
    }

#	$self->_only_static_attr( $name );
#
#	Croaks if the invocant is a reference. The message assumes the
#	method was called trying to access an attribute, whose name is
#	$name.

    sub _only_static_attr {
	my ( $self, $name ) = @_;
	ref $self
	    and croak "Attribute $name may only be accessed statically";
	return \%static;
    }

}

#	$rslt = $self->_request( %args );
#
#	This private method requests data from the USGS' web service.
#	The %args are the arguments for the request:
#	    {x} => longitude (West is negative)
#	    {y} => latitude (South is negative)
#	    {units} => desired units ('Meters' or 'Feet')
#	The return is a reference to a hash containing the parsed JSON
#	returned from the NAD server.

sub _request {
    my ( $self, %arg ) = @_;

    # The allow_nonref() is for the benefit of {_hack_result}.
    my $json = $self->{_json} ||= JSON->new()->utf8()->allow_nonref();

    my $ua = $self->{_transport_object} ||=
	LWP::UserAgent->new( timeout => $self->{timeout} );

    defined $arg{units}
	or $arg{units} = 'Feet';
    $arg{units} = $arg{units} =~ m/ \A meters \z /smxi
	? 'Meters'
	: 'Feet';
    $arg{output}	= 'json';

    my $uri = URI->new( $self->get( 'usgs_url' ) );
    $uri->query_form( \%arg );
    my $rqst = HTTP::Request::Common::GET( $uri );

    $self->{trace}
	and print STDERR $rqst->as_string();

    my $rslt = exists $self->{_hack_result} ? do {
	my $data = delete $self->{_hack_result};
	CODE_REF eq ref $data ? $data->( $self, %arg ) : $data;
    } : $ua->request( $rqst );

    $self->{trace}
	and print STDERR $rslt->as_string();

    $rslt->is_success()
	or croak $rslt->status_line();

    $rslt = $json->decode( $rslt->content() );

    defined $rslt
	or return $self->_error( 'No data found in query result' );

    foreach my $key (
	qw{ USGS_Elevation_Point_Query_Service Elevation_Query }
    ) {
	HASH_REF eq ref $rslt
	    and exists $rslt->{$key}
	    or return $self->_error(
	    "Elevation result is missing element {$key}" );
	$rslt = $rslt->{$key};
    }

    unless ( ref $rslt ) {
	$rslt =~ s/ (?<! [.?!] ) \z /./smx;
	return $self->_error( $rslt );
    }

    my $places;
    defined $rslt->{Elevation}
	and defined( $places = $self->get( 'places' ) )
	and $rslt->{Elevation} = sprintf '%.*f', $places, $rslt->{Elevation};

    if ( $self->get( 'compatible' ) ) {
	$rslt->{Units} = uc $rslt->{Units};
	$rslt->{Data_ID} = $rslt->{Data_Source};
    }

    return $rslt;
}

1;

__END__

=head2 Attributes

=head3 carp (boolean)

This boolean attribute determines whether the data acquisition methods carp on
encountering an error. If false, they silently return undef. Note,
though, that the L<croak|/croak> attribute trumps this one.

If L<retry|/retry> is set to a number greater than 0, you will get a
carp on each failed query, provided L<croak|/croak> is false. If
L<croak|/croak> is true, no retries will be carped.

This attribute was introduced in Geo::WebService::Elevation::USGS
version 0.005_01.

The default is 0 (i.e. false).

=head3 compatible (boolean)

This boolean attribute determines whether this object attempts to make
returned data consistent with the old GIS server.

The default was C<1> (i.e. true) when it was introduced in version
0.100, but as of version 0.106_01, and per the deprecation
plan, it is C<0> (i.e. false). Like the other deprecated attributes any
use of it will eventually become fatal. See the L<NOTICE|/NOTICE> above
for details.

=head3 croak (boolean)

This attribute determines whether the data acquisition methods croak on
encountering an error. If false, they return undef on an error.

If L<retry|/retry> is set to a number greater than 0, the data
acquisition method will not croak until all retries are exhausted.

The default is 1 (i.e. true).

=head3 default_ns (string)

This attribute is deprecated. See the L<NOTICE|/NOtICE> above for the
deprecation schedule.

This attribute records the XML namespace used by the SOAP query. This
must agree with the targetNamespace value given in the USGS' WSDL found
at
L<http://gisdata.usgs.gov/XMLWebServices/TNM_Elevation_service.asmx?WSDL>.

This attribute should not ordinarily need to be modified, but the
desperate user may be able to use it to get him- or herself going again
if the USGS changes the WSDL and this module has not been modified to
track the change.

The default is 'http://gisdata.usgs.gov/XMLWebServices2/'.

=head3 error (string)

This attribute records the error returned by the last query operation,
or undef if no error occurred. This attribute can be set by the user,
but will be reset by any query operation.

The default (before any queries have occurred) is undef.

=head3 places (integer)

If this attribute is set to a non-negative integer, elevation results
will be rounded to this number of decimal places by running them through
sprintf "%.${places}f".

The default is undef.

=head3 proxy (string)

This attribute is deprecated. See the L<NOTICE|/NOtICE> above for the
deprecation schedule.

This attribute specifies the actual url to which the SOAP query is
posted. It must agree with the soap:address location value given for
wsdl:port name "Elevation_ServiceSoap" given in the USGS' WSDL found
at
L<http://gisdata.usgs.gov/XMLWebServices/TNM_Elevation_service.asmx?WSDL>.

This attribute should not ordinarily need to be modified, but the
desperate user may be able to use it to get him- or herself going again
if the USGS changes the WSDL and this module has not been modified to
track the change.

The default is
C<'http://gisdata.usgs.gov/XMLWebServices2/Elevation_Service.asmx'>.

=head3 retry (unsigned integer)

This attribute specifies the number of retries to be done by
C<getAllElevations()> and C<getElevation()> when an error is
encountered. The first try is not considered a retry, so if you set this
to 1 you get a maximum of two queries (the try and the retry).

Retries are done only on actual errors, not on bad extents. They are
also subject to the L</throttle> setting if any.

The default is 0, i.e. no retries.

=head3 retry_hook (code reference)

This attribute specifies a piece of code to be called before retrying.
The code will be called before a retry takes place, and will be passed
the Geo::WebService::Elevation::USGS object, the number of the retry
(from 1), the name of the method being retried (C<'getAllElevations'> or
C<'getElevation'>), and the arguments to that method. If the position
was passed as an object, the hook gets the latitude and longitude
unpacked from the object. The hook will B<not> be called before the
first try, nor after the last retry.

Examples:

 # To sleep 5 seconds between retries:
 $eq->set( retry_hook => sub { sleep 5 } );
 
 # To sleep 1 second before the first retry, 2 seconds
 # before the second, and so on:
 $eq->set( retry_hook => sub { sleep $_[1] } );
 
 # To do nothing between retries:
 $eq->set( retry_hook => sub {} );

The default is the null subroutine, i.e. C<sub {}>.

=head3 source

This attribute is deprecated. See the L</NOTICE> above for the
deprecation schedule.

This attribute specifies the ID of the source layer to be queried by
the elevation() method. Valid layer IDs are documented at
L<http://gisdata.usgs.gov/XMLWebServices/TNM_Elevation_Service_Methods.php>.

A legal value is a scalar, or an ARRAY, CODE, HASH, or Regexp reference.
Please see the elevation() method's documentation for how these are
used.

The default is '-1', which requests a response from the 'best' data
source for the given point.

=head3 throttle (non-negative number, or undef)

 Geo::WebService::Elevation::USGS->set( throttle => 5 );

This attribute, if defined and positive, specifies the minimum interval
between queries, in seconds. This attribute may be set statically only,
and the limit applies to all queries, not just the ones from a given
object. If L<Time::HiRes|Time::HiRes> can be loaded, then sub-second
intervals are supported, otherwise not.

This functionality, and its implementation, are experimental, and may be
changed or retracted without notice. Heck, I may even go back to
C<$TARGET>, though I don't think so.

=head3 timeout (integer, or undef)

This attribute specifies the timeout for the SOAP query in seconds.

The default is 30.

=head3 trace (boolean)

If true, this attribute requests that network requests and responses be
dumped to standard error.  This should only be used for troubleshooting,
and the author makes no representation about and has no control over
what output you get if you set this true.

The default is undef (i.e. false).

=head3 units (string)

This attribute specifies the desired units for the resultant elevations.
Valid values are C<'Feet'> and C<'Meters'>. In practice these are not
case-sensitive, and any value other than case-insensitive C<'Meters'>
will be taken as C<'Feet'>.

The default is 'FEET', but this will become C<'Feet'> when the
compatibility code goes away.

=head3 use_all_limit (integer)

This attribute is deprecated. See the L<NOTICE|/NOtICE> above for the
deprecation schedule.

This attribute is used to optimize the behavior of the elevation()
method when the 'source' attribute is an array or hash reference. If the
number of elements in the array or hash is greater than or equal to this,
elevation() gets its data by calling getAllElevations() and then
dropping unwanted data. If the number of elements is less than
this number, elevation() iterates over the elements of the array or the
sorted keys of the hash, calling getElevation() on each.

Note that setting this to 0 causes getAllElevations() to be used always.
Setting this to -1 (or any negative number) is special-cased to cause
getElevation() to be used whenever the 'source' array or hash has any
entries at all, no matter how many it has.

The default is 5, which was chosen based on timings of the two methods.

=head3 usgs_url

This attribute specifies the URL to query. Under normal circumstances
you will not need to change this, but maybe it can get you going again
if the USGS moves the service.

The default is the value of environment variable 
C<GEO_WEBSERVICE_ELEVATION_USGS_URL>. If that is undefined, the default
is C<http://ned.usgs.gov/epqs/pqs.php>.

=head1 ACKNOWLEDGMENTS

The author wishes to acknowledge the following individuals and groups.

The members of the geo-perl mailing list provided valuable suggestions
and feedback, and generally helped me thrash through such issues as how
the module should work and what it should actually be called.

Michael R. Davis provided prompt and helpful feedback on a testing
problem in my first module to rely heavily on Test::More.

=head1 BUGS

Bugs can be reported to the author by mail, or through
L<http://rt.cpan.org/>.

=head1 SEE ALSO

=head1 AUTHOR

Thomas R. Wyant, III; F<wyant at cpan dot org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008-2019 Thomas R. Wyant, III

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl 5.10.0. For more details, see the full text
of the licenses in the directory LICENSES.

This program is distributed in the hope that it will be useful, but
without any warranty; without even the implied warranty of
merchantability or fitness for a particular purpose.

=cut

# ex: set textwidth=72 :
