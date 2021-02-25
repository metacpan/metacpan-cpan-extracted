package HTTP::API::Client;
$HTTP::API::Client::VERSION = '0.09';
use strict;
use warnings;

=head1 NAME

HTTP::API::Client - API Client

=head1 USAGE

 use HTTP::API::Client;

 my $ua1 = HTTP::API::Client->new;
 my $ua2 = HTTP::API::Client->new(base_url => URI->new( $url ), pre_defined_headers => { X_COMPANY => 'ABC LTD' } );
 my $ua3 = HTTP::API::Client->new(base_url => URI->new( $url ), pre_defined_data => { api_key => 123 } );

 $ua->send( $method, $url, \%data, \%header );

Send short hand methods - get, post, head, put and delete

Example:

 $ua->get( $url ) same as $ua->send( GET, $url );
 $ua->post( $url, \%data, \%headers ) same as $ua->send( GET, $url, \%data, \%headers );

Get Json Data - grab the content body from the response and json decode

 $ua = HTTP::API::Client->new(base_url => URI->new("http://google.com"));
 $ua->get("/search" => { q => "something" });
 my $hashref_from_decoded_json_string = $ua->json_response;
 ## ps. this is just an example to get json from a rest api

Send a query string to server

 $ua = HTTP::API::Client->new( content_type => "application/x-www-form-urlencoded" );
 $ua->post("http://google.com", { q => "something" });
 my $response = $ua->last_response; ## is a HTTP::Response object

At the moment, only support query string and json data in and out

=head1 ENVIRONMENT VARIABLES

These enviornment variables expose the controls without changing the existing code.

HTTP VARIABLES

 HTTP_USERNAME   - basic auth username
 HTTP_PASSWORD   - basic auth password
 HTTP_AUTH_TOKEN - basic auth token string
 HTTP_CHARSET    - content type charset. default utf8
 HTTP_TIMEOUT    - timeout the request for ??? seconds. default 60 seconds.
 SSL_VERIFY      - verify ssl url. default is off

DEBUG VARIABLES

 DEBUG_IN_OUT               - print out request and response in string to STDERR
 DEBUG_SEND_OUT             - print out request in string to STDERR
 DEBUG_RESPONSE             - print out response in string to STDERR
 DEBUG_RESPONSE_HEADER_ONLY - print out response header only without the body
 DEBUG_RESPONSE_IF_FAIL     - only print out response in string if fail.

RETRY VARIABLES

 RETRY_FAIL_RESPONSE  - number of time to retry if resposne comes back is failed. default 0 retry
 RETRY_FAIL_STATUS    - only retry if specified status code. e.g. 500,404
 RETRY_DELAY          - retry with wait time of ??? seconds in between

=cut

use Encode;
use HTTP::Headers;
use HTTP::Request;
use JSON::XS;
use LWP::UserAgent;
use Net::Curl::Simple;
use Mouse;
use Try::Tiny;
use URI;

has username => (
    is         => "rw",
    isa        => "Str",
    lazy_build => 1,
);

sub _build_username { $ENV{HTTP_USERNAME} || qq{} }

has password => (
    is         => "rw",
    isa        => "Str",
    lazy_build => 1,
);

sub _build_password { $ENV{HTTP_PASSWORD} || qq{} }

has auth_token => (
    is         => "rw",
    isa        => "Str",
    lazy_build => 1,
);

sub _build_auth_token { $ENV{HTTP_AUTH_TOKEN} || qq{} }

has base_url => (
    is  => "rw",
    isa => "URI",
);

has last_response => (
    is  => "rw",
    isa => "HTTP::Response",
);

has charset => (
    is         => "rw",
    isa        => "Str",
    lazy_build => 1,
);

sub _build_charset { $ENV{HTTP_CHARSET} || "utf8" }

has browser_id => (
    is         => "rw",
    isa        => "Str",
    lazy_build => 1,
);

sub _build_browser_id {
    my $self = shift;
    my $ver = $HTTP::API::Client::VERSION || -1;
    return "HTTP API Client v$ver";
}

has content_type => (
    is         => "rw",
    isa        => "Str",
    lazy_build => 1,
);

sub _build_content_type {
    my $self    = shift;
    my $charset = $self->charset;
    return "application/json; charset=$charset";
}

has engine => (
    is      => "ro",
    isa     => "Str",
    default => "LWP::UserAgent",
);

has ua => (
    is         => "rw",
    isa        => "Any",
    lazy_build => 1,
);

sub _build_ua {
    my $self       = shift;
    my $ssl_verify = $self->ssl_verify;
    my $engine     = $self->engine;

    my $ua;

    if ( $engine eq "LWP::UserAgent" ) {
        $ua = LWP::UserAgent->new( ssl_opts => { verify_hostname => $ssl_verify } );
        $ua->agent( $self->browser_id );
        $ua->timeout( $self->timeout );
    }
    elsif ( $engine eq "CURL" ) {
        $ua = Net::Curl::Simple->new( timeout => $self->timeout );
        $ua->ua->setopt( useragent => $self->browser_id );
    }

    return $ua;
}

has ssl_verify => (
    is         => "rw",
    isa        => "Bool",
    lazy_build => 1,
);

sub _build_ssl_verify {
    return _smart_or( $ENV{SSL_VERIFY}, 0 );
}

has retry => (
    is         => "rw",
    isa        => "HashRef",
    lazy_build => 1,
);

sub _build_retry {
    my $self   = shift;
    my %retry  = %{ $self->retry_config || {} };
    my $count  = $retry{fail_response};
    my %status = map { $_ => 1 } split /,/, $retry{fail_status};

    my $delay = $retry{delay};

    return {
        count  => $count,
        status => \%status,
        delay  => $delay,
    };
}

has retry_config => (
    is         => "rw",
    isa        => "HashRef",
    lazy_build => 1,
);

sub _build_retry_config {
    return {
        fail_response => _smart_or( $ENV{RETRY_FAIL_RESPONSE}, 0 ),
        fail_status => $ENV{RETRY_FAIL_STATUS} || q{},
        delay => _smart_or( $ENV{RETRY_DELAY}, 5 ),
    };
}

has timeout => (
    is         => "rw",
    isa        => "Int",
    lazy_build => 1,
);

sub _build_timeout { return $ENV{HTTP_TIMEOUT} || 60 }

has json => (
    is         => "rw",
    isa        => "JSON::XS",
    lazy_build => 1,
);

sub _build_json {
    my $self    = shift;
    my $json    = JSON::XS->new->canonical(1);
    my $charset = $self->charset;
    eval { $json->$charset };
    return $json;
}

has debug_flags => (
    is         => "rw",
    isa        => "HashRef",
    lazy_build => 1,
);

sub _build_debug_flags {
    return {
        in_out               => $ENV{DEBUG_IN_OUT},
        send_out             => $ENV{DEBUG_SEND_OUT},
        response             => $ENV{DEBUG_RESPONSE},
        response_header_only => $ENV{DEBUG_RESPONSE_HEADER_ONLY},
        response_if_fail     => $ENV{DEBUG_RESPONSE_IF_FAIL},
    };
}

has pre_defined_data => (
    is  => "rw",
    isa => "HashRef",
);

has pre_defined_headers => (
    is  => "rw",
    isa => "HashRef",
);

no Mouse;

sub get {
    my $self = shift;
    return $self->send( GET => @_ );
}

sub post {
    my $self = shift;
    return $self->send( POST => @_ );
}

sub put {
    my $self = shift;
    return $self->send( PUT => @_ );
}

sub head {
    my $self = shift;
    return $self->send( HEAD => @_ );
}

sub delete {
    my $self = shift;
    return $self->send( DELETE => @_ );
}

sub _execute_callbacks {
    my ($self, $type, %options) = @_;

    my $sth = $options{$type};

    while (my ($key, $callback) = each %$sth) {
        next if !defined $callback;
        next if !UNIVERSAL::isa($callback, 'CODE');
        $sth->{$key} = $self->$callback(key => $key, %options);
    }
}

sub send {
    my $self         = shift;
    my $method       = shift || "GET";
    my $path         = shift;
    my $data         = shift || {};
    my $headers      = shift || {};

    my %options = (
        method  => \$method,
        path    => \$path,
        data    => $data,
        headers => $headers,
    );

    if ( my $pd = $self->pre_defined_data ) {
        %$data = ( %$pd, %$data );
    }

    if ( my $ph = $self->pre_defined_headers ) {
        %$headers = ( %$ph, %$headers );
    }

    $self->_execute_callbacks(data    => %options);
    $self->_execute_callbacks(headers => %options);

    my $ua           = $self->ua;
    my $base_url     = $self->base_url;
    my $url          = $base_url ? $base_url . $path : $path;
    my $retry_count  = _smart_or( $self->retry->{count}, 1 );
    my %retry_status = %{ $self->retry->{status} || {} };
    my $retry_delay  = _smart_or( $self->retry->{delay}, 5 );
    my %debug        = %{ $self->debug_flags || {} };
    my $eng          = $self->engine;

    my $response;

  RETRY:
    foreach my $retry ( 0 .. $retry_count ) {
        my $started_time = time;

        if ( $eng eq 'LWP::UserAgent' ) {
            my $req   = $self->_request( $method, $url, $data, $headers );
            $response = $ua->request($req);
        }
        elsif ( $eng eq 'CURL' ) {
            $response = $ua->$method
        }

        if ( $debug{in_out} || $debug{send_out} ) {
            print STDERR "-- REQUEST --\n";
            if ( $retry_count && $retry ) {
                print STDERR "-- RETRY $retry of $retry_count\n";
            }
            print STDERR $response->request->as_string;
            print STDERR "\n";
        }

        my $debug_response = $debug{in_out} || $debug{response};

        $debug_response = 0
          if $debug{response_if_fail} && $response->is_success;

        if ($debug_response) {
            my $used_time = time - $started_time;

            print STDERR "-- RESPONSE $used_time sec(s) --\n";

            print STDERR $debug{response_header_only}
              ? $response->headers->as_string
              : $response->as_string;

            print STDERR ( "-" x 80 ) . "\n";
        }

        last RETRY    ## request is success, not further for retry
          if $response->is_success;

        if ( !%retry_status ) {
            sleep $retry_delay;
            ## no retry pattern at all then just retry
            next RETRY;
        }

        my $pattern = $retry_status{ $response->code }
          or
          last RETRY;  ## no retry pattern for this status code, just stop retry

        ## retry if pattern is match otherwise, just stop retry
        if ( $response->decode_content =~ /$pattern/ ) {
            sleep $retry_delay;
            next RETRY;
        }

        last RETRY;
    }

    return $self->last_response($response);
}

sub json_response {
    my $self     = shift;
    my $response = shift;
    try {
        my $last_response = $self->last_response->decoded_content;
        $response = $self->json->decode( $last_response || "{}" );
    }
    catch {
        my $error = $_;
        $response = { status => "error", error => $error };
    };
    return $response;
}

sub value_pair_response {
    my $self = shift;
    my @pairs = split /&/, $self->last_response->decoded_content || q{};
    my $data =
      { map { my ( $k, $v ) = split /=/, $_, 2; ( $k => $v ) } @pairs };
    if ( my $error = "$@" ) {
        $data = { status => "error", error => $error };
    }
    return $data;
}

sub _request {
    my $self    = shift;
    my $method  = uc shift;
    my $url     = shift;
    my $data    = shift;
    my $headers = shift || {};

    my $create_req = sub {
        my $uri = shift;
        my $req = HTTP::Request->new( $method => $uri );
        $req->content_type( $self->content_type )
          if $method !~ /get/i;
        if ( $self->username || $self->password ) {
            _basic_authenticator( $req, $self->username, $self->password );
        }
        elsif ( $self->auth_token ) {
            $headers->{authorization} ||= $self->auth_token;
        }
        return $req;
    };

    my $req = $create_req->($url);

    my $content = _tune_utf8( $self->_convert_data( $req, $data ) );

    if ( $method =~ /get/i ) {
        $req = $create_req->( $content ? "$url?$content" : $url );
    }

    foreach my $field ( keys %$headers ) {
        $req->header( $field => $headers->{$field} );
    }

    if ( $method !~ /get/i ) {
        $req->content($content);
    }

    return $req;
}

sub _tune_utf8 {
    my $content = shift;
    my $req = HTTP::Request->new( POST => "http://find-encoding.com" );
    try {
        $req->content($content);
    }
    catch {
        my $error = $_;
        if ( $error =~ /content must be bytes/ ) {
            eval { $content = Encode::encode( utf8 => $content ); };
        }
    };
    return $content;
}

sub _convert_data {
    my $self = shift;
    my $req  = shift;
    my $data = shift;

    return $data
      if !ref $data;

    my $ct = $req->content_type
      or return _hash_to_query_string(%$data);

    return $ct =~ /json/
      ? $self->json->encode($data)
      : _hash_to_query_string(%$data);
}

sub _hash_to_query_string {
    my %hash = @_;
    my $uri  = URI->new("http://parser.com");
    $uri->query_form( \%hash );
    my ( undef, $params ) = split /\?/, $uri->as_string;
    return $params;
}

sub _basic_authenticator {
    my $req      = shift;
    my $username = shift;
    my $password = shift;
    $req->headers->authorization_basic( $username, $password );
}

sub _smart_or {
    my $default_value = shift;
    my $or_value      = shift;
    return
      defined($default_value)
      && length($default_value) ? $default_value : $or_value;
}

1;
