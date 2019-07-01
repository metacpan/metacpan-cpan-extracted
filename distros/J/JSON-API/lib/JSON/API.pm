package JSON::API;
use strict;
use HTTP::Status qw/:constants/;
use LWP::UserAgent;
use JSON;
use Data::Dumper;
use URI::Encode qw/uri_encode/;

BEGIN {
	use Exporter ();
	use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
	$VERSION     = v1.1.1;
	@ISA         = qw(Exporter);
	#Give a hoot don't pollute, do not export more than needed by default
	@EXPORT      = qw();
	@EXPORT_OK   = qw();
	%EXPORT_TAGS = ();
}

sub _debug
{
	my ($self, @lines) = @_;
	my $output = join('\n', @lines);
	print STDERR $output . "\n" if ($self->{debug});
}

sub _server
{
	my ($self, $input) = @_;
	$input =~ s|^(https?://)?||;
	$input =~ m|^([^\s:/]+)(:\d+)?.*|;
	$input = $1 . ($2 || '');
	return $input;
}

sub _http_req
{
	my ($self, $method, $path, $data, $apphdr) = @_;
	$self->_debug('_http_req called with the following:',Dumper($method,$path,$data, $apphdr));

	my $url = $self->url($path);
	$self->_debug("URL calculated to be: $url");
        delete $self->{response};

	my $headers = HTTP::Headers->new(
			'Accept'       => 'application/json',
			'Content-Type' => 'application/json',
	);
        if( $apphdr && ref $apphdr ) {
            $headers->header( $_, $apphdr->{$_} ) foreach (keys %$apphdr);
        }
	my $json;
	if (defined $data) {
		$json = $self->_encode($data);
		return (wantarray ? (500, {}) : {}) unless defined $json;
	}

	my $req = HTTP::Request->new($method, $url, $headers, $json);
	$self->_debug("Requesting: ",Dumper($req));
	my $res = $self->{user_agent}->request($req);

	$self->_debug("Response: ",Dumper($res));
        $self->{response} = $res;
	if ($res->is_success) {
		$self->{has_error}    = 0;
		$self->{error_string} = '';
		$self->_debug("Successful request detected");
        } elsif ($res->code == HTTP_NOT_MODIFIED) {
            return wantarray ?
                             ($res->code, {}) :
                             {};
        } else {
		$self->{has_error} = 1;
		$self->{error_string} = $res->content;
		$self->_debug("Error detected: ".$self->{error_string});
		# If internal warning, return before decoding, as it will fail + overwrite the error_string
		if ($res->header('client-warning') =~ m/internal response/i) {
			return wantarray ? ($res->code, {}) : {};
		}
	}
	my $decoded = $res->content ? ($self->_decode($res->content) || {}) : {};

	#FIXME: should we auto-populate an error key in the {} if error detected but no content?
	return wantarray ?
			($res->code, $decoded) :
			$decoded;
}

sub _encode
{
	my ($self, $obj) = @_;

	my $json = undef;
	eval {
		$json = to_json($obj);
		$self->_debug("JSON created: $json");
	} or do {
		if ($@) {
			$self->{has_error} = 1;
			$self->{error_string} = $@;
			$self->{error_string} =~ s/\s+at\s+\S+\s+line\s+\d+\.?\s*//;
			$self->_debug("Error serializing json from \$obj:" . $self->{error_string});
		}
	};
	return $json;
}

sub _decode
{
	my ($self, $json) = @_;

	$self->_debug("Deserializing JSON");
	my $obj = undef;
	eval {
		$json = $self->{predecodehook}->($json)
			 if defined($self->{predecodehook});
		$obj = from_json($json);
		$self->_debug("Deserializing successful:",Dumper($obj));
	} or do {
		if ($@) {
			$self->{has_error} = 1;
			$self->{error_string} = $@;
			$self->{error_string} =~ s/\s+at\s+\S+\s+line\s+\d+\.?\s*//;
			$self->_debug("Error deserializing: ".$self->{error_string});
		}
	};
	return $obj;
}

sub new
{
	my ($class, $base_url, %parameters) = @_;
	return undef unless $base_url;

	my %ua_opts = %parameters;
	map { delete $parameters{$_}; } qw(user pass realm debug predecodehook);

	my $ua = LWP::UserAgent->new(%parameters);

	my $self = bless ({
				base_url     => $base_url,
				user_agent   => $ua,
				has_error    => 0,
				error_string => '',
				debug        => $ua_opts{debug},
				predecodehook => $ua_opts{predecodehook},
		}, ref ($class) || $class);

	my $server = $self->_server($base_url);
	my $default_port = $base_url =~ m|^https://| ? 443 : 80;
	$server .= ":$default_port" unless $server =~ /:\d+$/;
	$ua->credentials($server, $ua_opts{realm}, $ua_opts{user}, $ua_opts{pass})
		if ($ua_opts{realm} && $ua_opts{user} && $ua_opts{pass});

	return $self;
}

sub get
{
	my ($self, $path, $data, $apphdr) = @_;
	if ($data) {
		my @qp = map { "$_=".uri_encode($data->{$_}, { encode_reserved => 1 }) } sort keys %$data;
		$path .= "?".join("&", @qp);
	}
	$self->_http_req("GET", $path, undef, $apphdr);
}

sub put
{
	my ($self, $path, $data, $apphdr) = @_;
	$self->_http_req("PUT", $path, $data, $apphdr);
}

sub post
{
	my ($self, $path, $data, $apphdr) = @_;
	$self->_http_req("POST", $path, $data, $apphdr);
}

sub del
{
	my ($self, $path, $apphdr) = @_;
	$self->_http_req("DELETE", $path, undef, $apphdr);
}

sub url
{
	my ($self, $path) = @_;
	my $url = $self->{base_url} . "/$path";
	# REGEX-FU: look through the URL, replace any matches of /+ with '/',
	# as long as the previous character was not a ':'
	# (e.g. http://example.com//api//mypath/ becomes http://example.com/api/mypath/
	$url =~ s|(?<!:)/+|/|g;
	return $url;
}

sub response
{
    my ($self) = @_;

    return $self->{response};
}

sub header
{
    my ($self, $name) = @_;

    return unless( $self->{response} );

    unless( $name ) {
        return $self->{response}->header_field_names;
    }
    return $self->{response}->header( $name );
}

sub errstr
{
	my ($self) = @_;
	return ! $self->was_success ? $self->{error_string} : '';
}

sub was_success
{
	my ($self) = @_;
	return $self->{has_error} ? 0 : 1;
}

1;

__END__

=head1 NAME

JSON::API - Module to interact with a JSON API

=head1 SYNOPSIS

  use JSON::API;
  my $api = JSON::API->new("http://myapp.com/");
  my $obj = { name => 'foo', type => 'bar' };
  if ($api->put("/add/obj", $obj) {
    print "Success!\n";
  } else {
    print $api->errstr . "\n";
  }

=head1 DESCRIPTION

This module wraps JSON and LWP::UserAgent to create a flexible utility
for accessing APIs that accept/provide JSON data.

It supports all the options LWP supports, including authentication.

=head1 METHODS

=head2 new

Creates a new JSON::API object for connecting to any API that accepts
and provide JSON data.

Example:

	my $api = JSON::API->new("https://myapp.com:8443/path/to/app",
		user => 'foo',
		pass => 'bar',
		realm => 'my_protected_site',
		agent => 'MySpecialBrowser/1.0',
		cookie_jar => '/tmp/cookie_jar',
	);

Parameters:

=over

=item base_url

The base URL to apply to all requests you send this api, for example:

https://myapp.com:8443/path/to/app

=item parameters

This is a hash of options that can be passed in to an LWP object.
Additionally, the B<user>, B<pass>, and B<realm> may be provided
to configure authentication for LWP. You must provide all three parameters
for authentication to work properly.

Specifying debug => 1 in the parameters hash will also enable debugging output
within JSON::API.

Additionally you can specify predecodehook in the parameters hash with a
reference to a subroutine. The subroutine will then be called with the received
raw content as only parameter before it is decoded. It then can preprocess the
content e.g. alter it to be valid json. An example use case for this is calling
a JSON API that prefixes the json with garbage to prevent CSRF. The pre-decode
hook can then strip the garbage from the raw content before the JSON data is
being decoded.

=back

=head2 get|post|put|del

Perform an HTTP action (GET|POST|PUT|DELETE) against the given API. All methods
take the B<path> to the API endpoint as the first parameter. The B<put()> and
B<post()> methods also accept a second B<data> parameter, which should be a reference
to be serialized into JSON for POST/PUTing to the endpoint.

All methods also accept an optional B<apphdr> parameter in the last position, which
is a hashref.  The referenced hash contains header names and values that will be
submitted with the request.  See HTTP::Headers.  This can be used to provide
B<If-Modified> or other headers required by the API.

If called in scalar context, returns the deserialized JSON content returned by
the server. If no content was returned, returns an empty hashref. To check for errors,
call B<errstr> or B<was_success>.

If called in list context, returns a two-value array. The first value will be the
HTTP response code for the request. The second value will either be the deserialized
JSON data. If no data is returned, returns an empty hashref.

=head2 get

Performs an HTTP GET on the given B<path>. B<path> will be appended to the
B<base_url> provided when creating this object. If given a B<data> object,
this will be turned into querystring parameters, with URI encoded values.

  my $obj = $api->get('/objects/1');
  # Automatically add + encode querystring params
  my $obj = $api->get('/objects/1', { param => 'value' });

=head2 put

Performs an HTTP PUT on the given B<path>, with the provided B<data>. Like
B<get>, this will append path to the end of the B<base_url>.

  $api->put('/objects/', $obj);

=head2 post

Performs an HTTP POST on the given B<path>, with the provided B<data>. Like
B<get>, this will append path to the end of the B<base_url>.

  $api->post('/objects/', [$obj1, $obj2]);

=head2 del

Performs an HTTP DELETE on the given B<path>. Like B<get>, this will append
path to the end of the B<base_url>.

  $api->del('/objects/first');

=head2 response

Returns the last C<HTTP::Response>, or undef if none or if the last request
didn't generate one. This can be used to obtain detailed status.

=head2 header

With no argument, C<header> returns a list of the header fields in the last response.
If a field name is specified, returns the value(s) of the named field.  A multi-valued
field will be returned comma-separated in scalar context, or as separate values in
list context.  See C<HTTP::Header>.

This snippet can be used to dump all the response headers:

 print "$_ => ", scalar $api->header($_), "\n" foreach ($api->header);

=head2 errstr

Returns the current error string for the last call.

=head2 was_success

Returns whether or not the last request was successful.

=head2 url

Returns the complete URL of a request, when given a path.

=head1 EXAMPLES

This is a more advanced example of accessing the GitHub API.  It uses a custom
request header and conditional GET requests for efficiency.  It falls-back to
unconditional GET when necessary.

This code uses constants and methods from C<IO::SOCKET::SSL> and C<Storable>.
Error handling and logging have been omitted for clarity.

  my $repo = eval { lock_retrieve( "repo.status" ) };
  my $api = JSON::API->new( 'https://api.github.com/repos/user/app',
                            agent => "$prog/$VERSION",
                            protocols_allowed => [ qw/https/ ],
                            env_proxy => 1,
                            ssl_opts => { verify_hostname => $vhost || 0,
                                          SSL_verify_mode => ( $vhost?
                                                               SSL_VERIFY_PEER :
                                                               SSL_VERIFY_NONE ) },
                          );
  my($rc, $tags) = ( $repo && $repo->{tags_etag} )?
      $api->get( '/tags', undef, { Accept => 'application/vnd.github.v3+json',
                                   If_None_Match => $repo->{tags_etag}, } ) :
      $api->get( '/tags', undef, { Accept => 'application/vnd.github.v3+json' } );
  unless( ref $tags && $api->was_success ) {
      exit( 1 );
  }
  if( $api->can( 'header' ) ) {
      if( $rc == HTTP_NOT_MODIFIED ) {
          $tags = $repo->{tags};
      } else {
          $repo ||= {};
          $repo->{tags_etag} = $api->header( 'ETag' );
          $repo->{tags} = $tags;
          eval { lock_store( $repo, 'repo.status' ) };
      }
  }

=head1 REPOSITORY

L<https://github.com/geofffranks/json-api>

=head1 AUTHOR

    Geoff Franks <gfranks@cpan.org>

=head1 COPYRIGHT

Copyright 2014, Geoff Franks

This library is licensed under the GNU General Public License 3.0

=cut
