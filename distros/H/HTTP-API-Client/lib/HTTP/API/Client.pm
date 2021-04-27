package HTTP::API::Client;
$HTTP::API::Client::VERSION = '1.04';
use Moo;

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
use Try::Tiny;
use URI;
use URI::Escape qw( uri_escape uri_unescape );
use Scalar::Util qw( looks_like_number );
use HTTP::API::DataTypeMarker;

extends 'Exporter';

our @EXPORT = qw( xCSV xBOOLEAN
    xTRUE xFALSE
    xTrue xFalse
    xtrue xfalse
    xt__e xf___e
);

has username => (
    is      => "rw",
    lazy    => 1,
    builder => 1,
);

sub _build_username { _defor($ENV{HTTP_USERNAME}, '') }

has password => (
    is      => "rw",
    lazy    => 1,
    builder => 1,
);

sub _build_password { _defor($ENV{HTTP_PASSWORD}, '') }

has auth_token => (
    is      => "rw",
    lazy    => 1,
    builder => 1,
);

sub _build_auth_token { _defor($ENV{HTTP_AUTH_TOKEN}, '') }

has base_url => (
    is      => "rw",
    lazy    => 1,
    builder => 1,
);

sub _build_base_url {}

has last_response => (
    is      => "rw",
    lazy    => 1,
    builder => 1,
);

sub _build_last_response {}

has charset => (
    is      => "rw",
    lazy    => 1,
    builder => 1,
);

sub _build_charset { _defor($ENV{HTTP_CHARSET}, "utf8") }

has browser_id => (
    is      => "rw",
    lazy    => 1,
    builder => 1,
);

sub _build_browser_id {
    my $ver = _defor($HTTP::API::Client::VERSION, -1);
    return "HTTP API Client v$ver";
}

has content_type => (
    is      => "rw",
    lazy    => 1,
    builder => 1,
);

sub _build_content_type {}

sub get_content_type {
    my ($self, %o) = @_;
    my $content_type = $self->content_type;

    if ($content_type) {
        return $content_type;
    }

    my $method = ${$o{method}};

    if ($method eq 'GET') {
        return 'application/x-www-form-urlencoded';
    }

    my $charset = $self->charset;
    return "application/json; charset=$charset";
}

has engine => (
    is      => "ro",
    lazy    => 1,
    builder => 1,
);

sub _build_engine {"LWP::UserAgent"}

has ua => (
    is      => "rw",
    lazy    => 1,
    builder => 1,
);

sub _build_ua {
    my ($self)     = @_;
    my $ssl_verify = $self->ssl_verify;
    my $engine     = $self->engine;

    my $ua;

    if ( $engine eq "LWP::UserAgent" ) {
        $ua = LWP::UserAgent->new( ssl_opts => { verify_hostname => $ssl_verify } );
        $ua->agent( $self->browser_id );
        $ua->timeout( $self->timeout );
    }
    else {
        $ua = $self->$engine($ssl_verify);
    }

    return $ua;
}

has ssl_verify => (
    is      => "rw",
    lazy    => 1,
    builder => 1,
);

sub _build_ssl_verify {
    return _defor( $ENV{SSL_VERIFY}, 0 );
}

has retry => (
    is      => "rw",
    lazy    => 1,
    builder => 1,
);

sub _build_retry {
    my ($self) = @_;
    my %retry  = %{ _defor($self->retry_config, {}) };
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
    is      => "rw",
    lazy    => 1,
    builder => 1,
);

sub _build_retry_config {
    return {
        fail_response => _defor( $ENV{RETRY_FAIL_RESPONSE}, 0 ),
        fail_status => _defor($ENV{RETRY_FAIL_STATUS}, ''),
        delay => _defor( $ENV{RETRY_DELAY}, 5 ),
    };
}

has timeout => (
    is      => "rw",
    lazy    => 1,
    builder => 1,
);

sub _build_timeout { _defor($ENV{HTTP_TIMEOUT}, 60) }

has json => (
    is      => "rw",
    lazy    => 1,
    builder => 1,
);

sub _build_json {
    my ($self)  = @_;
    my $json    = JSON::XS->new->canonical->allow_nonref;
    my $charset = $self->charset;
    eval { $json->$charset };
    return $json;
}

has debug_flags => (
    is      => "rw",
    lazy    => 1,
    builder => 1,
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
    is      => "rw",
    lazy    => 1,
    builder => 1,
);

sub _build_pre_defined_data {{}}

has pre_defined_headers => (
    is      => "rw",
    lazy    => 1,
    builder => 1,
);

sub _build_pre_defined_headers {{}}

has pre_defined_events => (
    is      => "rw",
    lazy    => 1,
    builder => 1,
);

sub _build_pre_defined_events {{}}

sub get {
    my ($self, @args) = @_;
    return $self->send( GET => @args );
}

sub post {
    my ($self, @args) = @_;
    return $self->send( POST => @args );
}

sub put {
    my ($self, @args) = @_;
    return $self->send( PUT => @args );
}

sub head {
    my ($self, @args) = @_;
    return $self->send( HEAD => @args );
}

sub delete {
    my ($self, @args) = @_;
    return $self->send( DELETE => @args );
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
    my ($self, $method, $path,
        $data, $headers, $events) = @_;

    $method  = uc $method;
    $data    = _defor( $data,    {} );
    $headers = _defor( $headers, {} );
    $events  = _defor( $events,  {} );

    my $base_url     = $self->base_url;
    my $url          = $base_url ? $base_url . $path : $path;
    my $ua           = $self->ua;
    my $retry_count  = _defor( $self->retry->{count}, 1 );
    my $retry_delay  = _defor( $self->retry->{delay}, 5 );
    my %retry_status = %{ _defor($self->retry->{status}, {}) };
    my %debug        = %{ _defor($self->debug_flags, {}) };
    my $eng          = $self->engine;

    if ( my $pd = $self->pre_defined_data ) {
        %$data = ( %$pd, %$data );
    }

    if ( my $ph = $self->pre_defined_headers ) {
        %$headers = ( %$ph, %$headers );
    }

    if ( my $pe = $self->pre_defined_events ) {
        %$events = ( %$pe, %$events );
    }

    my %options = (
        method  => \$method,
        url     => \$url,
        path    => \$path,
        data    => $data,
        headers => $headers,
        events  => $events,
    );

    $self->_execute_callbacks(data    => %options);
    $self->_execute_callbacks(headers => %options);

    my $response;

  RETRY:
    foreach my $retry ( 0 .. $retry_count ) {
        my $started_time = time;

        if ( $eng eq 'LWP::UserAgent' ) {
            my $req = $self->new_request( %options );

            if ($events->{test_request_object}) {
                return $req;
            }

            $response = $ua->request($req);
        }

        if ( $debug{in_out} || $debug{send_out} ) {
            print STDERR "-- REQUEST --\n";
            if ( $retry_count && $retry ) {
                print STDERR "-- RETRY $retry of $retry_count\n";
            }
            print STDERR $response->request->as_string;
            print STDERR "\n";
        }

        my $debug_response = _defor($debug{in_out}, $debug{response});

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
    my ($self) = @_;

    my $response = try {
        my $content = _defor($self->last_response->decoded_content, '{}');
        $self->json->decode($content);
    }
    catch {
        my $error = $_;
        { status => "error", error => $error };
    };

    return $response;
}

sub kvp_response {
    my ($self) = @_;

    my $content = $self->last_response->decoded_content
        or return {};

    my %data = map {
        my ( $k, $v ) = map { uri_unescape($_) } split /=/, $_, 2;
    } split /&/, $content;

    return \%data;
}

sub new_request {
    my ($self, %o) = @_;

    my ($method, $url) = map { $$_ } @o{qw(method url)};

    my ($data, $headers, $events) = @o{qw(data headers events)};

    my $content_type = $self->get_content_type(%o);

    my $content = $self->convert_data(%o);

    if ($content) {
        if ($self->charset eq 'utf8') {
            $content = _tune_utf8($content);
        }
    }

    my $request;

    if ($method eq 'GET') {
        if ($content_type ne 'application/x-www-form-urlencoded') {
            die "Unable to create a get request with content_type: $content_type";
        }
        elsif ($content) {
            if ($url =~ m/\?/) {
                $request = $self->prepare_request(%o, url => \"$url&$content");
            }
            else {
                $request = $self->prepare_request(%o, url => \"$url?$content");
            }
        }
        else {
            $request = $self->prepare_request(%o);
        }
    }
    elsif ($content) {
        $request = $self->prepare_request(%o);
        $request->content($content);
    }

    %o = (%o,
        request => $request,
        content => \$content,
    );

    if (my $do = $events->{before_headers}) {
        $self->$do(%o);
    }

    my @keys;

    if (my $keys = $events->{headers_keys}) {
        @keys = $self->$keys(%o);
    }
    elsif (my $add = $events->{add_headers_keys}) {
        @keys = sort $self->$add(%o), keys %$headers;
    }
    else {
        @keys = sort keys %$headers;
    }

    foreach my $key ( @keys ) {
        if (my $do = $events->{before_header}{$key}) {
            $headers->{$key} = $self->$do(%o);
        }

        next if $o{skip_headers}{$key} || !exists $headers->{$key} || !defined $headers->{$key};

        $request->header( $key => $headers->{$key} );

        if (my $do = $events->{after_header}{$key}) {
            $self->$do(%o);
        }
    }

    if (my $do = $events->{after_header_keys}) {
        $self->$do(%o);
    }

    return $request;
}

sub prepare_request {
    my ($self, %o) = @_;

    my ($method, $url) = map { $$_ } @o{qw(method url)};

    my ($headers) = @o{qw(headers)};

    my $request = HTTP::Request->new( $method => $url );

    $request->content_type($self->get_content_type(%o));

    my ($u, $p, $at) = map { _defor($self->$_, '') }
        qw(username password auth_token);

    if ($u || $p) {
        $self->basic_authenticator($request, $u, $p);
    }
    elsif ($at) {
        $headers->{authorization} = $at;
    }

    return $request;
}

sub _tune_utf8 {
    my ($content) = @_;

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

sub convert_data {
    my ($self, %o) = @_;

    my ($data, $events) = @o{qw(data events)};

    my $content_type = $self->get_content_type(%o);

    if ($content_type =~ m/json/) {
        return $self->kvp2json(%o);
    }
    elsif ($content_type eq 'application/x-www-form-urlencoded') {
        return $self->kvp2str(%o);
    }
    else {
        return $data;
    }
}

sub kvp2json {
    my ($self, %o) = @_;

    my ($data, $events) = @o{qw(data events)};

    my @keys;

    if (my $do = $events->{keys}) {
        @keys = $self->$do(%o);
    }
    else {
        @keys = keys %$data;
    }

    my %data = ();

    foreach my $key(@keys) {
        if ($events->{not_include}{$key}) {
            next
        }
        next if $o{skip_key}{$key} || !exists $data->{$key} || !defined $data->{$key};
        $data{$key} = $self->kvp2json_each(%o, value => $data->{$key});
    }

    return $self->json->encode(\%data);
}

sub kvp2json_each {
    my ($self, %o) = @_;

    my ($v) = map { _defor($_, '') } @o{qw( value )};

    if (UNIVERSAL::isa($v, 'CODE')) {
        $v = $self->$v(%o);
    }

    if (!ref $v) {
        return looks_like_number($v) ? $v+0 : $v;
    }
    elsif (ref $v eq 'BOOL') {
        return $v->[0];
    }
    elsif (UNIVERSAL::isa($v, 'ARRAY')) {
        my @parts;

        foreach my $val(@$v) {
            push @parts, $self->kvp2json_each(%o, value => $val);
        }

        return \@parts;
    }
    elsif (UNIVERSAL::isa($v, 'HASH')) {
        my %parts;

        foreach my $key(keys %$v) {
            $parts{$key} = $self->kvp2json_each(%o, value => $v->{$key});
        }

        return \%parts;
    }

    return $v;
}

sub kvp2str {
    my ($self, %o) = @_;

    my ($data, $events) = @o{qw(data events)};

    my @keys;

    if (my $do = $events->{before_sorting_keys}) {
        $self->$do(%o, keys => \@keys);
    }

    if (my $do = $events->{keys}) {
        @keys = $self->$do(%o);
    }
    else {
        @keys = sort keys %$data;
    }

    if (my $do = $events->{after_sorting_keys}) {
        $self->$do(%o, keys => \@keys);
    }

    my @parts;

    foreach my $key(@keys) {
        next if $o{skip_key}{$key} || !exists $data->{$key} || !defined $data->{$key};
        push @parts, $self->kvp2str_each(%o, key => $key, value => $data->{$key});
    }

    return join '&', @parts;
}

sub kvp2str_each {
    my ($self, %o) = @_;

    my ($k, $v) = map { _defor($_, '') } @o{qw( key value )};

    $k = uri_escape($k);

    if (UNIVERSAL::isa($v, 'CODE')) {
        $v = $self->$v(%o, key => $k);
    }

    if (!ref $v) {
        $v = uri_escape($v);

        $v = $v + 0 if looks_like_number($v);

        if ($o{no_key}) {
            return $v;
        }
        else {
            return "$k=$v";
        }
    }
    elsif (ref $v eq 'BOOL') {
        return ref $v->[0] eq 'SCALAR'
            ? "$k=${$v->[0]}"
            : "$k=$v->[0]";

    }
    elsif (ref $v eq 'ARRAY') {
        my @parts;

        foreach my $val(@$v) {
            push @parts, $self->kvp2str_each(%o, key => $k, value => $val, no_key => 0);
        }

        return ($o{no_key} ? '&' : '') . join '&', @parts;
    }
    elsif (ref $v eq 'CSV') {
        my @csv;
        my @parts;

        foreach my $val(@$v) {
            my $part = $self->kvp2str_each(%o, key => $k, value => $val, no_key => 1);

            if ($part =~ m/&/) {
                push @parts, $part;
            }
            else {
                push @csv, $part;
            }
        }

        my $csv = "$k=".join( ',', @csv);
        
        if (@parts) {
            return join '&', $csv, @parts;
        }

        return $csv;
    }

    return $v;
}

sub basic_authenticator {
    my ($self, $req, $u, $p) = @_;
    return $req->headers->authorization_basic($u, $p);
}

sub _defor {
    my ($default, $or) = @_;
    return (defined($default) && length($default)) ? $default : $or;
}

no Moo;

1;
