package GeoIP2::WebService::Client;

use 5.008;

use strict;
use warnings;

our $VERSION = '2.006002';

use Moo;

use Data::Validate::IP 0.25 qw( is_public_ip );
use GeoIP2::Error::Generic;
use GeoIP2::Error::HTTP;
use GeoIP2::Error::IPAddressNotFound;
use GeoIP2::Error::WebService;
use GeoIP2::Model::City;
use GeoIP2::Model::Country;
use GeoIP2::Model::Insights;
use GeoIP2::Types
    qw( JSONObject MaxMindID MaxMindLicenseKey Str URIObject UserAgentObject );
use HTTP::Headers;
use HTTP::Request;
use JSON::MaybeXS;
use MIME::Base64 qw( encode_base64 );
use LWP::Protocol::https;
use LWP::UserAgent;
use Params::Validate qw( validate );
use Scalar::Util qw( blessed );
use Sub::Quote qw( quote_sub );
use Try::Tiny;
use URI;

use namespace::clean -except => 'meta';

with 'GeoIP2::Role::HasLocales';

has account_id => (
    is       => 'ro',
    isa      => MaxMindID,
    required => 1,
);
*user_id = \&account_id;    # for backwards-compatibility

has license_key => (
    is       => 'ro',
    isa      => MaxMindLicenseKey,
    required => 1,
);

has host => (
    is      => 'ro',
    isa     => Str,
    default => quote_sub(q{ 'geoip.maxmind.com' }),
);

has ua => (
    is      => 'ro',
    isa     => UserAgentObject,
    builder => '_build_ua',
);

has _base_uri => (
    is      => 'ro',
    isa     => URIObject,
    lazy    => 1,
    builder => '_build_base_uri',
);

has _json => (
    is       => 'ro',
    isa      => JSONObject,
    init_arg => undef,
    default  => quote_sub(q{ JSON::MaybeXS->new(utf8 => 1) }),
);

around BUILDARGS => sub {
    my ( $orig, @args ) = @_;
    my %params = %{ $orig->(@args) };
    $params{account_id} = delete $params{user_id}
        if exists $params{user_id};
    return \%params;
};

sub BUILD {
    my $self = shift;

    ## no critic (TryTiny::RequireBlockTermination)
    my $self_version = try { 'v' . $self->VERSION() } || 'v?';

    my $ua         = $self->ua();
    my $ua_version = try { 'v' . $ua->VERSION() } || 'v?';

    my $agent
        = blessed($self)
        . " $self_version" . ' ('
        . blessed($ua) . q{ }
        . $ua_version . q{ / }
        . "Perl $^V)";

    $ua->agent($agent);
}

sub country {
    my $self = shift;

    return $self->_response_for(
        'country',
        'GeoIP2::Model::Country',
        @_,
    );
}

sub city {
    my $self = shift;

    return $self->_response_for(
        'city',
        'GeoIP2::Model::City',
        @_,
    );
}

sub insights {
    my $self = shift;

    return $self->_response_for(
        'insights',
        'GeoIP2::Model::Insights',
        @_,
    );
}

my %spec = (
    ip => {
        callbacks => {
            'is a public IP address or me' => sub {
                return defined $_[0]
                    && ( $_[0] eq 'me'
                    || is_public_ip( $_[0] ) );
            }
        },
    },
);

sub _response_for {
    my $self        = shift;
    my $path        = shift;
    my $model_class = shift;

    my %p = validate( @_, \%spec );

    my $uri = $self->_base_uri()->clone();
    $uri->path_segments( $uri->path_segments(), $path, $p{ip} );

    my $request = HTTP::Request->new(
        'GET', $uri,
        HTTP::Headers->new( Accept => 'application/json' ),
    );

    $request->authorization_basic(
        $self->account_id(),
        $self->license_key(),
    );

    my $response = $self->ua()->request($request);

    if ( $response->code() == 200 ) {
        my $body = $self->_handle_success( $response, $uri );
        return $model_class->new(
            %{$body},
            locales => $self->locales(),
        );
    }
    else {
        # all other error codes throw an exception
        $self->_handle_error_status( $response, $uri, $p{ip} );
    }
}

sub _handle_success {
    my $self     = shift;
    my $response = shift;
    my $uri      = shift;

    my $body;
    try {
        $body = $self->_json()->decode( $response->decoded_content() );
    }
    catch {
        GeoIP2::Error::Generic->throw(
            message =>
                "Received a 200 response for $uri but could not decode the response as JSON: $_",
        );
    };

    return $body;
}

sub _handle_error_status {
    my $self     = shift;
    my $response = shift;
    my $uri      = shift;
    my $ip       = shift;

    my $status = $response->code();

    if ( $status =~ /^4/ ) {
        $self->_handle_4xx_status( $response, $status, $uri, $ip );
    }
    elsif ( $status =~ /^5/ ) {
        $self->_handle_5xx_status( $status, $uri );
    }
    else {
        $self->_handle_non_200_status( $status, $uri );
    }
}

sub _handle_4xx_status {
    my $self     = shift;
    my $response = shift;
    my $status   = shift;
    my $uri      = shift;
    my $ip       = shift;

    if ( $status == 404 ) {
        GeoIP2::Error::IPAddressNotFound->throw(
            message    => "No record found for IP address $ip",
            ip_address => $ip,
        );
    }

    my $content = $response->decoded_content();

    my $body = {};

    if ( defined $content && length $content ) {
        if ( $response->content_type() =~ /json/ ) {
            try {
                $body = $self->_json()->decode($content);
            }
            catch {
                GeoIP2::Error::HTTP->throw(
                    message =>
                        "Received a $status error for $uri but it did not include the expected JSON body: $_",
                    http_status => $status,
                    uri         => $uri,
                );
            };
            GeoIP2::Error::Generic->throw( message =>
                    'Response contains JSON but it does not specify code or error keys'
            ) unless $body->{code} && $body->{error};
        }
        else {
            GeoIP2::Error::HTTP->throw(
                message =>
                    "Received a $status error for $uri with the following body: $content",
                http_status => $status,
                uri         => $uri,
            );
        }
    }
    else {
        GeoIP2::Error::HTTP->throw(
            message     => "Received a $status error for $uri with no body",
            http_status => $status,
            uri         => $uri,
        );
    }

    GeoIP2::Error::WebService->throw(
        message => delete $body->{error},
        %{$body},
        http_status => $status,
        uri         => $uri,
    );
}

sub _handle_5xx_status {
    my $self   = shift;
    my $status = shift;
    my $uri    = shift;

    GeoIP2::Error::HTTP->throw(
        message     => "Received a server error ($status) for $uri",
        http_status => $status,
        uri         => $uri,
    );
}

sub _handle_non_200_status {
    my $self   = shift;
    my $status = shift;
    my $uri    = shift;

    GeoIP2::Error::HTTP->throw(
        message =>
            "Received a very surprising HTTP status ($status) for $uri",
        http_status => $status,
        uri         => $uri,
    );
}

sub _build_base_uri {
    my $self = shift;

    return URI->new( 'https://' . $self->host() . '/geoip/v2.1' );
}

sub _build_ua {
    my $self = shift;

    return LWP::UserAgent->new();
}

1;

# ABSTRACT: Perl API for the GeoIP2 Precision web services

__END__

=pod

=encoding UTF-8

=head1 NAME

GeoIP2::WebService::Client - Perl API for the GeoIP2 Precision web services

=head1 VERSION

version 2.006002

=head1 SYNOPSIS

  use 5.008;

  use GeoIP2::WebService::Client;

  # This creates a Client object that can be reused across requests.
  # Replace "42" with your account id and "abcdef123456" with your license
  # key.
  my $client = GeoIP2::WebService::Client->new(
      account_id  => 42,
      license_key => 'abcdef123456',
  );

  # Replace "insights" with the method corresponding to the web service
  # that you are using, e.g., "country", "city".
  my $insights = $client->insights( ip => '24.24.24.24' );

  my $country = $insights->country();
  print $country->iso_code(), "\n";

=head1 DESCRIPTION

This class provides a client API for all the GeoIP2 Precision web service end
points. The end points are Country, City, and Insights. Each end point returns
a different set of data about an IP address, with Country returning the least
data and Insights the most.

Each web service end point is represented by a different model class, and
these model classes in turn contain multiple Record classes. The record
classes have attributes which contain data about the IP address.

If the web service does not return a particular piece of data for an IP
address, the associated attribute is not populated.

The web service may not return any information for an entire record, in which
case all of the attributes for that record class will be empty.

=head1 SSL

Requests to the GeoIP2 web service are always made with SSL.

=head1 USAGE

The basic API for this class is the same for all of the web service end
points. First you create a web service object with your MaxMind C<account_id> and
C<license_key>, then you call the method corresponding to a specific end
point, passing it the IP address you want to look up.

If the request succeeds, the method call will return a model class for the end
point you called. This model in turn contains multiple record classes, each of
which represents part of the data returned by the web service.

If the request fails, the client class throws an exception.

=head1 IP GEOLOCATION USAGE

IP geolocation is inherently imprecise. Locations are often near the center of
the population. Any location provided by a GeoIP2 web service should not be
used to identify a particular address or household.

=head1 CONSTRUCTOR

This class has a single constructor method:

=head2 GeoIP2::WebService::Client->new()

This method creates a new client object. It accepts the following arguments:

=over 4

=item * account_id

Your MaxMind Account ID. Go to L<https://www.maxmind.com/en/my_license_key> to see
your MaxMind Account ID and license key.

B<Note>: This replaces a previous C<user_id> parameter, which is still
supported for backwards-compatibility, but should no longer be used for new
code.

This argument is required.

=item * license_key

Your MaxMind license key. Go to L<https://www.maxmind.com/en/my_license_key> to
see your MaxMind Account ID and license key.

This argument is required.

=item * locales

This is an array reference where each value is a string indicating a locale.
This argument will be passed onto record classes to use when their C<name()>
methods are called.

The order of the locales is significant. When a record class has multiple
names (country, city, etc.), its C<name()> method will look at each element of
this array ref and return the first locale for which it has a name.

Note that the only locale which is always present in the GeoIP2 data in "en".
If you do not include this locale, the C<name()> method may end up returning
C<undef> even when the record in question has an English name.

Currently, the valid list of locale codes is:

=over 8

=item * de - German

=item * en - English

English names may still include accented characters if that is the accepted
spelling in English. In other words, English does not mean ASCII.

=item * es - Spanish

=item * fr - French

=item * ja - Japanese

=item * pt-BR - Brazilian Portuguese

=item * ru - Russian

=item * zh-CN - simplified Chinese

=back

Passing any other locale code will result in an error.

The default value for this argument is C<['en']>.

=item * host

The hostname to make a request against. This defaults to
"geoip.maxmind.com". In most cases, you should not need to set this
explicitly.

=item * ua

This argument allows you to your own L<LWP::UserAgent> object. This is useful
if you cannot use a vanilla LWP object, for example if you need to set proxy
parameters.

This can actually be any object which supports C<agent()> and C<request()>
methods. This method will be called with an L<HTTP::Request> object as its
only argument. This method must return an L<HTTP::Response> object.

=back

=head1 REQUEST METHODS

All of the request methods accept a single argument:

=over 4

=item * ip

This must be a valid IPv4 or IPv6 address, or the string "me". This is the
address that you want to look up using the GeoIP2 web service.

If you pass the string "me" then the web service returns data on the client
system's IP address. Note that this is the IP address that the web service
sees. If you are using a proxy, the web service will not see the client
system's actual IP address.

=back

=head2 $client->country()

This method calls the GeoIP2 Precision: Country end point. It returns a
L<GeoIP2::Model::Country> object.

=head2 $client->city()

This method calls the GeoIP2 Precision: City end point. It returns a
L<GeoIP2::Model::City> object.

=head2 $client->insights()

This method calls the GeoIP2 Precision: Insights end point. It returns a
L<GeoIP2::Model::Insights> object.

=head1 User-Agent HEADER

This module will set the User-Agent header to include the package name and
version of this module (or a subclass if you use one), the package name and
version of the user agent object, and the version of Perl.

This is set in order to help us support individual users, as well to determine
support policies for dependencies and Perl itself.

=head1 EXCEPTIONS

For details on the possible errors returned by the web service itself, see
L<http://dev.maxmind.com/geoip/geoip2/web-services> for the GeoIP2 web service
docs.

If the web service returns an explicit error document, this is thrown as a
L<GeoIP2::Error::WebService> exception object. If some other sort of error
occurs, this is thrown as a L<GeoIP2::Error::HTTP> object. The difference is
that the web service error includes an error message and error code delivered
by the web service. The latter is thrown when some sort of unanticipated error
occurs, such as the web service returning a 500 or an invalid error document.

If the web service returns any status code besides 200, 4xx, or 5xx, this also
becomes a L<GeoIP2::Error::HTTP> object.

Finally, if the web service returns a 200 but the body is invalid, the client
throws a L<GeoIP2::Error::Generic> object.

All of these error classes have an C<< $error->message() >> method and
overload stringification to show that message. This means that if you don't
explicitly catch errors they will ultimately be sent to C<STDERR> with some
sort of (hopefully) useful error message.

=head1 WHAT DATA IS RETURNED?

While many of the end points return the same basic records, the attributes
which can be populated vary between end points. In addition, while an end
point may offer a particular piece of data, MaxMind does not always have every
piece of data for any given IP address.

Because of these factors, it is possible for any end point to return a record
where some or all of the attributes are unpopulated.

See L<http://dev.maxmind.com/geoip/geoip2/web-services> for details on what data each end
point I<may> return.

The only piece of data which is always returned is the C<ip_address> key in
the C<GeoIP2::Record::Traits> record.

Every record class attribute has a corresponding predicate method so you can
check to see if the attribute is set.

=head1 SUPPORT

Bugs may be submitted through L<https://github.com/maxmind/GeoIP2-perl/issues>.

=head1 AUTHORS

=over 4

=item *

Dave Rolsky <drolsky@maxmind.com>

=item *

Greg Oschwald <goschwald@maxmind.com>

=item *

Mark Fowler <mfowler@maxmind.com>

=item *

Olaf Alders <oalders@maxmind.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 - 2019 by MaxMind, Inc.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
