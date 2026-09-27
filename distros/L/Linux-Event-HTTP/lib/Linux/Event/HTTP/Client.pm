package Linux::Event::HTTP::Client;
use v5.36;
use strict;
use warnings;

use Carp qw(croak);
use Scalar::Util qw(blessed refaddr weaken);
use URI ();
use HTTP::CookieJar 0.014 ();

use Linux::Event::HTTP::Client::Connection;
use Linux::Event::HTTP::Client::Operation;
use Linux::Event::HTTP::Request;
use Linux::Event::HTTP::_ClientAuth ();

our $VERSION = '0.003';

my %CALLBACK = map { $_ => 1 } qw(
    on_response on_body on_complete on_error on_informational on_redirect
    on_upgrade on_tunnel
);

my %REDIRECT_STATUS = map { $_ => 1 } qw(301 302 303 307 308);

sub _load_connection_class ($class) {
    croak 'new(): connection_class must be a package name'
        if !defined($class) || ref($class)
        || $class !~ /\A[A-Za-z_][A-Za-z0-9_]*(?:::[A-Za-z_][A-Za-z0-9_]*)*\z/;

    if (!$class->can('connect')) {
        (my $file = "$class.pm") =~ s{::}{/}g;
        require $file;
    }

    croak 'new(): connection_class must inherit Linux::Event::HTTP::Client::Connection'
        if !$class->isa('Linux::Event::HTTP::Client::Connection');
    return $class;
}

sub _validate_tls_options ($option) {
    croak 'new(): tls must be a hash reference'
        if ref($option) ne 'HASH';
    my %known = map { $_ => 1 } qw(
        verify ca_file ca_path handshake_timeout shutdown_timeout
    );
    my @unknown = grep { !$known{$_} } keys %$option;
    croak 'new(): tls has unknown options: ' . join(', ', sort @unknown)
        if @unknown;
    return { %$option };
}

sub _validate_max_redirects ($value, $where) {
    croak "$where: max_redirects must be a non-negative integer"
        if !defined($value) || ref($value) || "$value" !~ /\A[0-9]+\z/;
    return 0 + $value;
}

sub _validate_max_auth_retries ($value, $where) {
    croak "$where: max_auth_retries must be a non-negative integer"
        if !defined($value) || ref($value) || "$value" !~ /\A[0-9]+\z/;
    return 0 + $value;
}

sub _parse_url ($url) {
    croak 'request(): URL must be a scalar' if !defined($url) || ref($url);

    my $uri = eval { URI->new("$url") };
    croak "request(): invalid URL: $@" if !$uri;

    my $scheme = lc($uri->scheme // '');
    croak 'request(): URL scheme must be http or https'
        if $scheme ne 'http' && $scheme ne 'https';

    my $host = $uri->host;
    croak 'request(): URL must contain a host'
        if !defined($host) || $host eq '';
    croak 'request(): URL userinfo is not supported; use explicit authentication policy'
        if defined($uri->userinfo) && length($uri->userinfo);

    my $port = eval { $uri->port };
    croak "request(): invalid URL port: $@" if !defined($port) || $@;
    croak 'request(): URL port must be between 1 and 65535'
        if $port !~ /\A[0-9]+\z/ || $port < 1 || $port > 65_535;

    my $target = $uri->path_query;
    $target = '/' if !defined($target) || $target eq '';

    my $default_port = $scheme eq 'https' ? 443 : 80;
    my $authority_host = $host =~ /:/ ? "[$host]" : $host;
    my $host_header = $authority_host;
    $host_header .= ":$port" if $port != $default_port;
    my $absolute_target = "$scheme://$host_header$target";
    my $auth_origin = "$scheme://$authority_host:$port";

    my $origin = join("\0", $scheme, lc($host), $port);
    return {
        scheme          => $scheme,
        host            => $host,
        port            => 0 + $port,
        target          => "$target",
        absolute_target => $absolute_target,
        host_header     => $host_header,
        auth_origin     => $auth_origin,
        origin          => $origin,
    };
}

sub _parse_proxy_url ($url, $where = 'request()') {
    croak "$where: proxy must be a non-empty scalar URL"
        if !defined($url) || ref($url) || $url eq '';

    my $destination;
    my $ok = eval {
        $destination = _parse_url($url);
        1;
    };
    if (!$ok) {
        my $error = "$@";
        $error =~ s/\Arequest\(\)/$where/;
        die $error;
    }

    croak "$where: proxy URL must not contain a path or query"
        if $destination->{target} ne '/';
    return $destination;
}

sub _http2_available () {
    return 0 if !eval {
        require Net::HTTP2::nghttp2;
        Net::HTTP2::nghttp2->VERSION('0.011');
        require Linux::Event::HTTP::_HTTP2::ClientSelector;
        1;
    };
    return Net::HTTP2::nghttp2->available ? 1 : 0;
}

sub new ($class, %option) {
    my $loop = delete $option{loop}
        // croak 'new(): loop is required';
    croak 'new(): loop must be an object implementing add() and watch_fd()'
        if !blessed($loop) || !$loop->can('add') || !$loop->can('watch_fd');

    my $connection_class_option = delete $option{connection_class};
    my $connection_class = _load_connection_class(
        $connection_class_option
            // 'Linux::Event::HTTP::Client::Connection',
    );
    my $http2 = exists($option{http2}) ? delete($option{http2}) : 0;
    my $has_http2_max_header_list_size =
        exists $option{http2_max_header_list_size};
    my $http2_max_header_list_size =
        $has_http2_max_header_list_size
            ? delete($option{http2_max_header_list_size})
            : 65_536;
    my $has_http2_max_buffered_response_bytes =
        exists $option{http2_max_buffered_response_bytes};
    my $http2_max_buffered_response_bytes =
        $has_http2_max_buffered_response_bytes
            ? delete($option{http2_max_buffered_response_bytes})
            : 67_108_864;
    croak 'new(): http2 must be zero or one'
        if !defined($http2) || ref($http2)
        || ("$http2" ne '0' && "$http2" ne '1');
    $http2 = $http2 ? 1 : 0;
    croak 'new(): http2_max_header_list_size must be a positive integer'
        if ref($http2_max_header_list_size)
        || "$http2_max_header_list_size" !~ /\A[0-9]+\z/
        || $http2_max_header_list_size < 1;
    croak 'new(): http2_max_header_list_size requires http2 => 1'
        if !$http2 && $has_http2_max_header_list_size;
    croak 'new(): http2_max_buffered_response_bytes must be a positive integer'
        if ref($http2_max_buffered_response_bytes)
        || "$http2_max_buffered_response_bytes" !~ /\A[0-9]+\z/
        || $http2_max_buffered_response_bytes < 1;
    croak 'new(): http2_max_buffered_response_bytes requires http2 => 1'
        if !$http2 && $has_http2_max_buffered_response_bytes;
    croak 'new(): http2 currently requires the default connection_class'
        if $http2 && defined($connection_class_option);
    croak 'new(): HTTP/2 support requires Net::HTTP2::nghttp2 0.011 or newer'
        if $http2 && !_http2_available();
    my $connect_timeout = delete $option{connect_timeout};
    my $max_redirects = _validate_max_redirects(
        exists($option{max_redirects}) ? delete($option{max_redirects}) : 5,
        'new()',
    );
    my $max_auth_retries = _validate_max_auth_retries(
        exists($option{max_auth_retries})
            ? delete($option{max_auth_retries})
            : 3,
        'new()',
    );
    my $tls = exists($option{tls})
        ? _validate_tls_options(delete $option{tls})
        : {};
    my $proxy_url = exists($option{proxy})
        ? delete($option{proxy})
        : undef;
    _parse_proxy_url($proxy_url, 'new()') if defined $proxy_url;

    my $cookie_jar = exists($option{cookie_jar})
        ? delete($option{cookie_jar})
        : undef;
    croak 'new(): cookie_jar must be an HTTP::CookieJar object'
        if defined($cookie_jar)
        && (!blessed($cookie_jar) || !$cookie_jar->isa('HTTP::CookieJar'));

    my $auth = exists($option{auth}) ? delete($option{auth}) : undef;
    my $proxy_auth = exists($option{proxy_auth})
        ? delete($option{proxy_auth})
        : undef;
    Linux::Event::HTTP::_ClientAuth::validate_manager($auth, 'new()', 'auth');
    Linux::Event::HTTP::_ClientAuth::validate_manager(
        $proxy_auth, 'new()', 'proxy_auth',
    );

    croak 'new(): unknown options: ' . join(', ', sort keys %option)
        if %option;

    return bless {
        loop             => $loop,
        connection_class => $connection_class,
        connect_timeout  => $connect_timeout,
        max_redirects    => $max_redirects,
        max_auth_retries => $max_auth_retries,
        tls              => $tls,
        proxy_url        => defined($proxy_url) ? "$proxy_url" : undef,
        cookie_jar       => $cookie_jar,
        auth             => $auth,
        proxy_auth       => $proxy_auth,
        http2            => $http2,
        http2_max_header_list_size => 0 + $http2_max_header_list_size,
        http2_max_buffered_response_bytes =>
            0 + $http2_max_buffered_response_bytes,
        idle             => {},
        h2_pool          => {},
        h2_negotiating   => {},
        connections      => {},
        closed           => 0,
    }, $class;
}

sub loop             ($self) { $self->{loop} }
sub connection_class ($self) { $self->{connection_class} }
sub max_redirects    ($self) { $self->{max_redirects} }
sub max_auth_retries ($self) { $self->{max_auth_retries} }
sub proxy            ($self) { $self->{proxy_url} }
sub cookie_jar       ($self) { $self->{cookie_jar} }
sub auth             ($self) { $self->{auth} }
sub proxy_auth       ($self) { $self->{proxy_auth} }
sub http2            ($self) { !!$self->{http2} }
sub http2_max_header_list_size ($self) {
    return $self->{http2_max_header_list_size};
}
sub http2_max_buffered_response_bytes ($self) {
    return $self->{http2_max_buffered_response_bytes};
}
sub is_closed        ($self) { !!$self->{closed} }

sub _copy_headers ($headers) {
    return [] if !defined $headers;
    croak 'request(): headers must be an array reference of [name, value] pairs'
        if ref($headers) ne 'ARRAY';

    my @copy;
    for my $pair (@$headers) {
        croak 'request(): each header must be a [name, value] pair'
            if ref($pair) ne 'ARRAY' || @$pair != 2;
        push @copy, [ $pair->[0], $pair->[1] ];
    }
    return \@copy;
}

sub _validate_buffer_body ($value) {
    croak 'request(): buffer_body must be a positive integer byte limit'
        if !defined($value) || ref($value) || "$value" !~ /\A[0-9]+\z/;
    croak 'request(): buffer_body must be greater than zero'
        if "$value" !~ /[1-9]/;
    return "$value";
}

sub _validate_stream_body ($value) {
    croak 'request(): stream_body must be a hash reference'
        if ref($value) ne 'HASH';
    my $copy = { %$value };
    require Linux::Event::HTTP::Body::Stream;
    Linux::Event::HTTP::Body::Stream->_validate_options('request', %$copy);
    return $copy;
}

sub _track_connection ($self, $connection) {
    my $id = refaddr($connection);
    $self->{connections}{$id} = $connection;
    weaken($self->{connections}{$id});
    return $connection;
}

sub _register_negotiating_connection ($self, $origin, $connection) {
    return if $self->{closed} || !$connection || $connection->is_closed;
    return if !$connection->can('_http2_capable')
        || !$connection->_http2_capable;

    my $protocol = $connection->protocol // '';
    return if $protocol ne 'negotiating' && $protocol ne 'selecting-h2';

    my $pool = $self->{h2_negotiating}{$origin} //= [];
    my $id = refaddr($connection);
    return $connection if grep { refaddr($_) == $id } @$pool;
    push @$pool, $connection;
    return $connection;
}

sub _remove_negotiating_connection ($self, $origin, $connection) {
    my $pool = $self->{h2_negotiating}{$origin} or return;
    my $id = refaddr($connection);
    my @keep = grep {
        $_ && refaddr($_) != $id && !$_->is_closed
    } @$pool;

    if (@keep) {
        $self->{h2_negotiating}{$origin} = \@keep;
    } else {
        delete $self->{h2_negotiating}{$origin};
    }
    return;
}

sub _take_negotiating_connection ($self, $origin) {
    my $pool = $self->{h2_negotiating}{$origin} or return undef;
    my @keep;
    my $selected;

    for my $connection (@$pool) {
        next if !$connection || $connection->is_closed;
        my $protocol = $connection->protocol // '';
        next if $protocol ne 'negotiating' && $protocol ne 'selecting-h2';

        push @keep, $connection;
        $selected //= $connection
            if $connection->can_queue_transaction;
    }

    if (@keep) {
        $self->{h2_negotiating}{$origin} = \@keep;
    } else {
        delete $self->{h2_negotiating}{$origin};
    }

    return $selected;
}

sub _register_h2_connection ($self, $origin, $connection) {
    return if $self->{closed} || !$connection || $connection->is_closed;
    return if !$connection->can('_http2_capable')
        || !$connection->_http2_capable;
    return if ($connection->protocol // '') ne 'h2';

    my $pool = $self->{h2_pool}{$origin} //= [];
    my $id = refaddr($connection);
    return $connection if grep { refaddr($_) == $id } @$pool;
    push @$pool, $connection;
    return $connection;
}

sub _take_h2_connection ($self, $origin) {
    my $pool = $self->{h2_pool}{$origin} or return undef;
    my @keep;
    my $selected;

    for my $connection (@$pool) {
        next if !$connection || $connection->is_closed;

        if (($connection->protocol // '') ne 'h2') {
            next;
        }

        if (!$connection->can_accept_transaction) {
            if ($connection->active_streams == 0) {
                $connection->close;
                next;
            }
            push @keep, $connection;
            next;
        }

        push @keep, $connection;
        $selected //= $connection;
    }

    if (@keep) {
        $self->{h2_pool}{$origin} = \@keep;
    } else {
        delete $self->{h2_pool}{$origin};
    }

    return $selected;
}

sub _take_idle_connection ($self, $origin, $allow_http2 = 0) {
    my $connection = delete $self->{idle}{$origin};
    return undef if !$connection;
    return undef if $connection->is_closed;
    return undef if defined $connection->transaction;

    my $is_selector = $connection->can('_http2_capable')
        && $connection->_http2_capable ? 1 : 0;

    if ($is_selector && ($connection->protocol // '') eq 'h2') {
        $self->_register_h2_connection($origin, $connection);
        return $allow_http2
            ? $self->_take_h2_connection($origin)
            : undef;
    }

    if ($allow_http2 && !$is_selector) {
        $connection->close;
        return undef;
    }

    return $connection;
}

sub _new_connection ($self, $destination, $allow_http2 = 0) {
    my %connect = (
        loop => $self->{loop},
        host => $destination->{host},
        port => $destination->{port},
    );
    $connect{timeout} = $self->{connect_timeout}
        if defined $self->{connect_timeout};

    if ($destination->{scheme} eq 'https') {
        require Linux::Event::TLS;
        $connect{transport} = Linux::Event::TLS->client(
            server_name => $destination->{host},
            alpn        => $allow_http2
                ? [ 'h2', 'http/1.1' ]
                : [ 'http/1.1' ],
            %{$self->{tls}},
        );
    }

    my $connection;
    if ($allow_http2 && $destination->{scheme} eq 'https') {
        require Linux::Event::HTTP::_HTTP2::ClientSelector;
        my $weak_self = $self;
        weaken($weak_self);
        my $origin = $destination->{origin};
        $connection = Linux::Event::HTTP::_HTTP2::ClientSelector->new(
            %connect,
            scheme    => $destination->{scheme},
            authority => $destination->{host_header},
            max_header_list_size => $self->{http2_max_header_list_size},
            max_buffered_response_bytes =>
                $self->{http2_max_buffered_response_bytes},
            http1_connection_factory => sub ($selected) {
                my $client = $weak_self
                    or die 'HTTP Client disappeared during ALPN selection';
                return $client->_new_connection($destination, 0);
            },
            on_selected => sub ($selected, $protocol) {
                my $client = $weak_self or return;
                $client->_remove_negotiating_connection(
                    $origin, $selected,
                );
                $client->_register_h2_connection($origin, $selected)
                    if $protocol eq 'h2';
            },
        );
        $self->_register_negotiating_connection($origin, $connection);
    } else {
        $connection = $self->{connection_class}->connect(%connect);
    }
    return $self->_track_connection($connection);
}

sub _connection_for ($self, $destination, $allow_http2 = 0) {
    if ($allow_http2) {
        my $h2 = $self->_take_h2_connection($destination->{origin});
        return $h2 if $h2;

        my $negotiating =
            $self->_take_negotiating_connection($destination->{origin});
        return $negotiating if $negotiating;
    }

    return $self->_take_idle_connection(
        $destination->{origin}, $allow_http2,
    ) // $self->_new_connection($destination, $allow_http2);
}

sub _release_connection ($self, $origin, $connection) {
    return if $self->{closed};
    return if !$connection || $connection->is_closed;

    if ($connection->can('_http2_capable')
        && $connection->_http2_capable
        && ($connection->protocol // '') eq 'h2') {
        $self->_register_h2_connection($origin, $connection);
        $self->_take_h2_connection($origin);
        return;
    }

    return if defined $connection->transaction;

    if (my $idle = $self->{idle}{$origin}) {
        if (!$idle->is_closed && refaddr($idle) != refaddr($connection)) {
            if ($connection->can('end')) {
                $connection->end;
            } else {
                $connection->close;
            }
            return;
        }
    }

    $self->{idle}{$origin} = $connection;
    return;
}

sub _resolve_redirect_url ($current_url, $location) {
    my $base = URI->new("$current_url");
    my $reference = URI->new("$location");
    my $inherit_fragment = !defined($reference->fragment)
        ? $base->fragment : undef;

    my $next = URI->new_abs($reference, $base);
    $next->fragment($inherit_fragment) if defined $inherit_fragment;
    return $next->as_string;
}

sub _redirect_headers ($headers, $drop_body, $cross_origin, $through_proxy = 0) {
    my @next;

    for my $pair (@$headers) {
        my ($name, $value) = @$pair;
        my $lower = defined($name) && !ref($name) ? lc($name) : '';

        next if $lower eq 'host';
        next if $lower eq 'connection';
        next if $lower eq 'keep-alive';
        next if $lower eq 'proxy-connection';
        next if $lower eq 'proxy-authorization' && !$through_proxy;
        next if $lower eq 'te';
        next if $lower eq 'trailer';
        next if $lower eq 'transfer-encoding';
        next if $lower eq 'upgrade';
        next if $lower eq 'content-length';

        if ($cross_origin) {
            next if $lower eq 'authorization';
            next if $lower eq 'cookie';
        }

        if ($drop_body) {
            next if $lower eq 'expect';
            next if $lower =~ /\Acontent-/;
        }

        push @next, [ $name, $value ];
    }

    return \@next;
}

sub _redirect_plan ($self, $operation, $spec, $destination, $response) {
    my $status = $response->status;
    return undef if !$REDIRECT_STATUS{$status};
    return undef if $spec->{max_redirects} == 0;

    my $location = $response->header_values('Location');
    return undef if !@$location;
    return { error => 'redirect response contains multiple Location fields' }
        if @$location != 1;
    return { error => 'maximum redirect count exceeded' }
        if $operation->redirect_count >= $spec->{max_redirects};

    my ($next_url, $next_destination);
    my $ok = eval {
        $next_url = _resolve_redirect_url($spec->{url}, $location->[0]);
        $next_destination = _parse_url($next_url);
        1;
    };
    if (!$ok) {
        my $error = "$@";
        $error =~ s/\s+\z//;
        return { error => "invalid redirect Location: $error" };
    }

    my $method = $spec->{method};
    my $drop_body = 0;

    if ($status == 303) {
        $method = uc($method) eq 'HEAD' ? 'HEAD' : 'GET';
        $drop_body = 1;
    }
    elsif (($status == 301 || $status == 302)
        && uc($method) eq 'POST') {
        $method = 'GET';
        $drop_body = 1;
    }

    if (!$drop_body && $spec->{has_stream_body}) {
        return {
            error => "cannot automatically follow $status redirect for a streaming Request body because the producer is not replayable",
        };
    }

    my $headers = _redirect_headers(
        $spec->{headers},
        $drop_body,
        $destination->{origin} ne $next_destination->{origin},
        defined($spec->{proxy_url}) ? 1 : 0,
    );

    if (defined $spec->{upgrade_to}) {
        push @$headers, [ Upgrade => $_->[1] ] for grep {
            defined($_->[0]) && !ref($_->[0]) && lc($_->[0]) eq 'upgrade'
        } @{$spec->{headers}};
        push @$headers, [ Connection => 'Upgrade' ];
    }

    my %next = (
        url                 => $next_url,
        proxy_url           => $spec->{proxy_url},
        method              => $method,
        headers             => $headers,
        version             => $spec->{version},
        version_explicit    => $spec->{version_explicit},
        has_body            => 0,
        body                => undef,
        has_stream_body     => 0,
        stream_body         => undef,
        has_buffer_body     => $spec->{has_buffer_body},
        buffer_body         => $spec->{buffer_body},
        max_redirects       => $spec->{max_redirects},
        max_auth_retries    => $spec->{max_auth_retries},
        auth                => $spec->{auth},
        proxy_auth          => $spec->{proxy_auth},
        authorization       => undef,
        proxy_authorization => undef,
        upgrade_to          => $spec->{upgrade_to},
        callback            => $spec->{callback},
        hop_kind            => 'redirect',
    );

    if (!$drop_body && $spec->{has_body}) {
        $next{has_body} = 1;
        $next{body} = $spec->{body};
    }

    return {
        url  => $next_url,
        spec => \%next,
    };
}

sub _auth_retry_plan (
    $self, $operation, $spec, $destination, $proxy, $message, $response,
) {
    return undef if $spec->{max_auth_retries} == 0;
    return undef if $operation->auth_retry_count >= $spec->{max_auth_retries};

    my $status = $response->status;
    my ($manager, $challenge_header, $origin, $field, $label);

    if ($status == 401 && $spec->{auth}) {
        $manager = $spec->{auth};
        $challenge_header = 'WWW-Authenticate';
        $origin = $destination->{auth_origin};
        $field = 'authorization';
        $label = 'target';
    }
    elsif ($status == 407 && $proxy && $spec->{proxy_auth}) {
        $manager = $spec->{proxy_auth};
        $challenge_header = 'Proxy-Authenticate';
        $origin = $proxy->{auth_origin};
        $field = 'proxy_authorization';
        $label = 'proxy';
    }
    else {
        return undef;
    }

    my $prepared = Linux::Event::HTTP::_ClientAuth::prepare_retry(
        manager          => $manager,
        response         => $response,
        challenge_header => $challenge_header,
        origin           => $origin,
        request          => $message,
        status           => $status,
        label            => $label,
    );
    return undef if !$prepared;
    return $prepared if defined $prepared->{error};

    my %next = %$spec;
    $next{hop_kind} = 'auth';
    $next{$field} = $prepared->{value};

    return {
        spec   => \%next,
        scheme => $prepared->{scheme},
        proxy  => $status == 407 ? 1 : 0,
    };
}

sub _start_operation_hop ($self, $operation, $spec) {
    die 'cannot start another HTTP hop for a terminal Client operation'
        if $operation->is_terminal;

    my $destination = _parse_url($spec->{url});
    my $proxy = defined($spec->{proxy_url})
        ? _parse_proxy_url($spec->{proxy_url})
        : undef;
    my $route = $proxy // $destination;
    my $headers = _copy_headers($spec->{headers});
    my $cookie_url = $destination->{absolute_target};

    if (my $jar = $self->{cookie_jar}) {
        my $cookie = $jar->cookie_header($cookie_url);
        push @$headers, [ Cookie => $cookie ]
            if defined($cookie) && length($cookie);
    }

    if ($proxy) {
        @$headers = grep {
            !defined($_->[0]) || ref($_->[0]) || lc($_->[0]) ne 'host'
        } @$headers;
        push @$headers, [ Host => $destination->{host_header} ];
    }
    else {
        my @host = grep {
            defined($_->[0]) && !ref($_->[0]) && lc($_->[0]) eq 'host'
        } @$headers;
        push @$headers, [ Host => $destination->{host_header} ] if !@host;
    }

    push @$headers, [ Authorization => $spec->{authorization} ]
        if defined $spec->{authorization};
    push @$headers, [ 'Proxy-Authorization' => $spec->{proxy_authorization} ]
        if defined $spec->{proxy_authorization};

    my %request = (
        method  => $spec->{method},
        target  => $proxy
            ? $destination->{absolute_target}
            : $destination->{target},
        version => $spec->{version},
        headers => $headers,
    );
    $request{body} = $spec->{body} if $spec->{has_body};
    my $message = Linux::Event::HTTP::Request->new(%request);

    my $allow_http2 = $self->{http2}
        && !$proxy
        && $destination->{scheme} eq 'https'
        && !$spec->{version_explicit}
        && !defined($spec->{upgrade_to});

    my $connection = $self->_connection_for($route, $allow_http2);
    my $callback = $spec->{callback};
    my ($auth_retry, $redirect);
    my $upgraded = 0;

    my %connection_callback;
    $connection_callback{on_response} = sub ($transaction, $response) {
        if (my $jar = $self->{cookie_jar}) {
            $jar->add($cookie_url, $_)
                for @{$response->header_values('Set-Cookie')};
        }

        $auth_retry = $self->_auth_retry_plan(
            $operation, $spec, $destination, $proxy, $message, $response,
        );
        $redirect = $self->_redirect_plan(
            $operation, $spec, $destination, $response,
        ) if !$auth_retry;

        if (!$auth_retry && !$redirect && $callback->{on_response}) {
            $callback->{on_response}->($transaction, $response);
            $operation->_mark_cancelled
                if $transaction->is_cancelled && !$operation->is_terminal;
        }
        return;
    };

    if ($callback->{on_body}) {
        $connection_callback{on_body} = sub ($transaction, $response, $bytes) {
            return if $auth_retry || $redirect;
            $callback->{on_body}->($transaction, $response, $bytes);
            $operation->_mark_cancelled
                if $transaction->is_cancelled && !$operation->is_terminal;
            return;
        };
    }

    if ($callback->{on_informational}) {
        $connection_callback{on_informational} = sub ($transaction, $response) {
            $callback->{on_informational}->($transaction, $response);
            $operation->_mark_cancelled
                if $transaction->is_cancelled && !$operation->is_terminal;
            return;
        };
    }

    $connection_callback{stream_body} = $spec->{stream_body}
        if $spec->{has_stream_body};
    $connection_callback{buffer_body} = $spec->{buffer_body}
        if $spec->{has_buffer_body};

    if ($allow_http2
        && $connection->can('_http2_capable')
        && $connection->_http2_capable) {
        $connection_callback{_http1_reassign} = sub ($replacement) {
            $connection = $replacement;
            return;
        };
    }

    if (defined $spec->{upgrade_to}) {
        $connection_callback{upgrade_to} = $spec->{upgrade_to};
        $connection_callback{on_upgrade} = sub (
            $transaction, $response, $upgraded_connection,
        ) {
            $upgraded = 1;
            $operation->_mark_complete if !$operation->is_terminal;
            $callback->{on_upgrade}->(
                $operation,
                $transaction,
                $response,
                $upgraded_connection,
            ) if $callback->{on_upgrade};
            return;
        };
    }

    $connection_callback{on_complete} = sub ($transaction) {
        if ($upgraded) {
            $callback->{on_complete}->($transaction)
                if $callback->{on_complete};
            return;
        }

        $self->_release_connection($route->{origin}, $connection);

        if ($auth_retry) {
            if (defined $auth_retry->{error}) {
                my $error = $auth_retry->{error};
                $operation->_fail($error) if !$operation->is_terminal;
                $callback->{on_error}->($transaction, $error)
                    if $callback->{on_error};
                return;
            }

            my $ok = eval {
                $self->_start_operation_hop($operation, $auth_retry->{spec});
                1;
            };
            if (!$ok) {
                my $error = "$@";
                $error =~ s/\s+\z//;
                $operation->_fail($error) if !$operation->is_terminal;
                $callback->{on_error}->($transaction, $error)
                    if $callback->{on_error};
            }
            return;
        }

        if ($redirect) {
            if (defined $redirect->{error}) {
                my $error = $redirect->{error};
                $operation->_fail($error) if !$operation->is_terminal;
                $callback->{on_error}->($transaction, $error)
                    if $callback->{on_error};
                return;
            }

            if (my $on_redirect = $callback->{on_redirect}) {
                $on_redirect->(
                    $operation,
                    $transaction,
                    $transaction->response,
                    $redirect->{url},
                );
                return if $operation->is_terminal;
            }

            my $ok = eval {
                $self->_start_operation_hop($operation, $redirect->{spec});
                1;
            };
            if (!$ok) {
                my $error = "$@";
                $error =~ s/\s+\z//;
                $operation->_fail($error) if !$operation->is_terminal;
                $callback->{on_error}->($transaction, $error)
                    if $callback->{on_error};
            }
            return;
        }

        $operation->_mark_complete if !$operation->is_terminal;
        $callback->{on_complete}->($transaction)
            if $callback->{on_complete};
        return;
    };

    $connection_callback{on_error} = sub ($transaction, $error) {
        $operation->_fail($error) if !$operation->is_terminal;
        $callback->{on_error}->($transaction, $error)
            if $callback->{on_error};
        return;
    };

    my $transaction;
    my $ok = eval {
        $transaction = $connection->request($message, %connection_callback);
        1;
    };
    if (!$ok) {
        my $error = $@;
        $self->_release_connection(
            $route->{origin}, $connection,
        ) if !$connection->is_closed && !defined($connection->transaction);
        die $error;
    }

    $operation->_append_transaction(
        $transaction, $spec->{url}, $spec->{hop_kind} // 'initial',
    );
    return $transaction;
}

sub request ($self, $method, $url, %option) {
    croak 'request(): Client is closed' if $self->{closed};
    croak 'request(): method is required'
        if !defined($method) || ref($method) || $method eq '';

    _parse_url($url);

    my $proxy_url = exists($option{proxy})
        ? delete($option{proxy})
        : $self->{proxy_url};
    _parse_proxy_url($proxy_url) if defined $proxy_url;
    croak 'request(): proxy cannot be used with CONNECT; use connect_tunnel()'
        if defined($proxy_url) && uc($method) eq 'CONNECT';

    my $auth = exists($option{auth}) ? delete($option{auth}) : $self->{auth};
    my $proxy_auth = exists($option{proxy_auth})
        ? delete($option{proxy_auth})
        : $self->{proxy_auth};
    Linux::Event::HTTP::_ClientAuth::validate_manager(
        $auth, 'request()', 'auth',
    );
    Linux::Event::HTTP::_ClientAuth::validate_manager(
        $proxy_auth, 'request()', 'proxy_auth',
    );

    my $headers = _copy_headers(delete $option{headers});
    for my $pair (@$headers) {
        next if !defined($pair->[0]) || ref($pair->[0]);
        my $name = lc($pair->[0]);
        croak 'request(): Cookie header is managed by cookie_jar; add cookies to the jar instead'
            if $self->{cookie_jar} && $name eq 'cookie';
        croak 'request(): Authorization header is managed by auth'
            if $auth && $name eq 'authorization';
        croak 'request(): Proxy-Authorization header is managed by proxy_auth'
            if $proxy_auth && $name eq 'proxy-authorization';
    }

    my $version_explicit = exists $option{version};
    my $version = delete($option{version}) // '1.1';
    my $has_body = exists $option{body};
    my $body = delete $option{body};
    my $has_stream_body = exists $option{stream_body};
    my $stream_body = $has_stream_body
        ? _validate_stream_body(delete $option{stream_body})
        : undef;
    my $has_buffer_body = exists $option{buffer_body};
    my $buffer_body = $has_buffer_body
        ? _validate_buffer_body(delete $option{buffer_body})
        : undef;
    my $upgrade_to = exists($option{upgrade_to})
        ? delete($option{upgrade_to})
        : undef;
    my $max_redirects = _validate_max_redirects(
        exists($option{max_redirects})
            ? delete($option{max_redirects})
            : $self->{max_redirects},
        'request()',
    );
    my $max_auth_retries = _validate_max_auth_retries(
        exists($option{max_auth_retries})
            ? delete($option{max_auth_retries})
            : $self->{max_auth_retries},
        'request()',
    );

    croak 'request(): body and stream_body are mutually exclusive'
        if $has_body && $has_stream_body;

    my %callback;
    for my $name (keys %CALLBACK) {
        next if !exists $option{$name};
        my $value = delete $option{$name};
        croak "request(): $name must be a coderef"
            if defined($value) && ref($value) ne 'CODE';
        $callback{$name} = $value if defined $value;
    }

    croak 'request(): buffer_body cannot be combined with on_body'
        if $has_buffer_body && $callback{on_body};
    croak 'request(): on_upgrade requires upgrade_to'
        if $callback{on_upgrade} && !defined($upgrade_to);
    croak 'request(): upgrade_to cannot be combined with buffer_body'
        if defined($upgrade_to) && $has_buffer_body;
    croak 'request(): upgrade_to cannot be combined with on_body'
        if defined($upgrade_to) && $callback{on_body};
    croak 'request(): on_tunnel is only valid with connect_tunnel()'
        if $callback{on_tunnel};
    croak 'request(): unknown options: ' . join(', ', sort keys %option)
        if %option;

    my $operation = Linux::Event::HTTP::Client::Operation->_new(
        initial_url      => "$url",
        max_redirects    => $max_redirects,
        max_auth_retries => $max_auth_retries,
    );

    my $spec = {
        url                 => "$url",
        proxy_url           => defined($proxy_url) ? "$proxy_url" : undef,
        method              => $method,
        headers             => $headers,
        version             => $version,
        version_explicit    => $version_explicit ? 1 : 0,
        has_body            => $has_body ? 1 : 0,
        body                => $body,
        has_stream_body     => $has_stream_body ? 1 : 0,
        stream_body         => $stream_body,
        has_buffer_body     => $has_buffer_body ? 1 : 0,
        buffer_body         => $buffer_body,
        max_redirects       => $max_redirects,
        max_auth_retries    => $max_auth_retries,
        auth                => $auth,
        proxy_auth          => $proxy_auth,
        authorization       => undef,
        proxy_authorization => undef,
        upgrade_to          => $upgrade_to,
        callback            => \%callback,
        hop_kind            => 'initial',
    };

    $self->_start_operation_hop($operation, $spec);
    return $operation;
}

sub _start_connect_tunnel_attempt ($self, $operation, $spec) {
    die 'cannot start another CONNECT attempt for a terminal Client operation'
        if $operation->is_terminal;

    my $destination = _parse_proxy_url(
        $spec->{proxy_url}, 'connect_tunnel()',
    );
    my $headers = _copy_headers($spec->{headers});
    push @$headers, [ 'Proxy-Authorization' => $spec->{proxy_authorization} ]
        if defined $spec->{proxy_authorization};

    my $message = Linux::Event::HTTP::Request->new(
        method  => 'CONNECT',
        target  => $spec->{target_authority},
        version => '1.1',
        headers => $headers,
    );
    my $connection = $self->_connection_for($destination, 0);
    my $callback = $spec->{callback};
    my ($auth_retry, $tunneled);

    my %connection_callback = (tunnel_to => $spec->{tunnel_to});
    $connection_callback{buffer_body} = $spec->{buffer_body}
        if $spec->{has_buffer_body};

    $connection_callback{on_response} = sub ($transaction, $response) {
        if ($response->status == 407
            && $spec->{proxy_auth}
            && $spec->{max_auth_retries} > 0
            && $operation->auth_retry_count < $spec->{max_auth_retries}) {
            my $prepared = Linux::Event::HTTP::_ClientAuth::prepare_retry(
                manager          => $spec->{proxy_auth},
                response         => $response,
                challenge_header => 'Proxy-Authenticate',
                origin           => $destination->{auth_origin},
                request          => $message,
                status           => 407,
                label            => 'proxy',
            );
            if ($prepared) {
                if (defined $prepared->{error}) {
                    $auth_retry = $prepared;
                }
                else {
                    my %next = %$spec;
                    $next{proxy_authorization} = $prepared->{value};
                    $next{hop_kind} = 'auth';
                    $auth_retry = { spec => \%next, scheme => $prepared->{scheme} };
                }
            }
        }

        if (!$auth_retry && $callback->{on_response}) {
            $callback->{on_response}->($transaction, $response);
            $operation->_mark_cancelled
                if $transaction->is_cancelled && !$operation->is_terminal;
        }
        return;
    };

    if ($callback->{on_body}) {
        $connection_callback{on_body} = sub ($transaction, $response, $bytes) {
            return if $auth_retry;
            $callback->{on_body}->($transaction, $response, $bytes);
            $operation->_mark_cancelled
                if $transaction->is_cancelled && !$operation->is_terminal;
            return;
        };
    }

    if ($callback->{on_informational}) {
        $connection_callback{on_informational} = sub ($transaction, $response) {
            $callback->{on_informational}->($transaction, $response);
            $operation->_mark_cancelled
                if $transaction->is_cancelled && !$operation->is_terminal;
            return;
        };
    }

    $connection_callback{on_tunnel} = sub (
        $transaction, $response, $tunnel_connection,
    ) {
        $tunneled = 1;
        $operation->_mark_complete if !$operation->is_terminal;
        $callback->{on_tunnel}->(
            $operation,
            $transaction,
            $response,
            $tunnel_connection,
        ) if $callback->{on_tunnel};
        return;
    };

    $connection_callback{on_complete} = sub ($transaction) {
        if ($tunneled) {
            $callback->{on_complete}->($transaction)
                if $callback->{on_complete};
            return;
        }

        $self->_release_connection($destination->{origin}, $connection);

        if ($auth_retry) {
            if (defined $auth_retry->{error}) {
                my $error = $auth_retry->{error};
                $operation->_fail($error) if !$operation->is_terminal;
                $callback->{on_error}->($transaction, $error)
                    if $callback->{on_error};
                return;
            }

            my $ok = eval {
                $self->_start_connect_tunnel_attempt(
                    $operation, $auth_retry->{spec},
                );
                1;
            };
            if (!$ok) {
                my $error = "$@";
                $error =~ s/\s+\z//;
                $operation->_fail($error) if !$operation->is_terminal;
                $callback->{on_error}->($transaction, $error)
                    if $callback->{on_error};
            }
            return;
        }

        $operation->_mark_complete if !$operation->is_terminal;
        $callback->{on_complete}->($transaction)
            if $callback->{on_complete};
        return;
    };

    $connection_callback{on_error} = sub ($transaction, $error) {
        $operation->_fail($error) if !$operation->is_terminal;
        $callback->{on_error}->($transaction, $error)
            if $callback->{on_error};
        return;
    };

    my $transaction;
    my $ok = eval {
        $transaction = $connection->request($message, %connection_callback);
        1;
    };
    if (!$ok) {
        my $error = $@;
        $self->_release_connection(
            $destination->{origin}, $connection,
        ) if !$connection->is_closed && !defined($connection->transaction);
        die $error;
    }

    $operation->_append_transaction(
        $transaction,
        $spec->{proxy_url},
        $spec->{hop_kind} // 'initial',
    );
    return $transaction;
}

sub connect_tunnel ($self, $proxy_url, $target_authority, %option) {
    croak 'connect_tunnel(): Client is closed' if $self->{closed};
    croak 'connect_tunnel(): target authority is required'
        if !defined($target_authority) || ref($target_authority)
        || $target_authority eq '';

    _parse_proxy_url($proxy_url, 'connect_tunnel()');

    my $proxy_auth = exists($option{proxy_auth})
        ? delete($option{proxy_auth})
        : $self->{proxy_auth};
    Linux::Event::HTTP::_ClientAuth::validate_manager(
        $proxy_auth, 'connect_tunnel()', 'proxy_auth',
    );

    my $headers = _copy_headers(delete $option{headers});
    for my $pair (@$headers) {
        next if !defined($pair->[0]) || ref($pair->[0]);
        croak 'connect_tunnel(): Proxy-Authorization header is managed by proxy_auth'
            if $proxy_auth && lc($pair->[0]) eq 'proxy-authorization';
    }

    my @host = grep {
        defined($_->[0]) && !ref($_->[0]) && lc($_->[0]) eq 'host'
    } @$headers;
    push @$headers, [ Host => "$target_authority" ] if !@host;

    my $tunnel_to = delete($option{tunnel_to})
        // croak 'connect_tunnel(): tunnel_to is required';
    my $has_buffer_body = exists $option{buffer_body};
    my $buffer_body = $has_buffer_body
        ? _validate_buffer_body(delete $option{buffer_body})
        : undef;
    my $max_auth_retries = _validate_max_auth_retries(
        exists($option{max_auth_retries})
            ? delete($option{max_auth_retries})
            : $self->{max_auth_retries},
        'connect_tunnel()',
    );

    my %callback;
    my %known_callback = map { $_ => 1 } qw(
        on_response on_body on_complete on_error on_informational on_tunnel
    );
    for my $name (keys %known_callback) {
        next if !exists $option{$name};
        my $value = delete $option{$name};
        croak "connect_tunnel(): $name must be a coderef"
            if defined($value) && ref($value) ne 'CODE';
        $callback{$name} = $value if defined $value;
    }

    croak 'connect_tunnel(): buffer_body cannot be combined with on_body'
        if $has_buffer_body && $callback{on_body};
    croak 'connect_tunnel(): unknown options: ' . join(', ', sort keys %option)
        if %option;

    my $operation = Linux::Event::HTTP::Client::Operation->_new(
        initial_url      => "$proxy_url",
        max_redirects    => 0,
        max_auth_retries => $max_auth_retries,
    );
    my $spec = {
        proxy_url           => "$proxy_url",
        target_authority    => "$target_authority",
        headers             => $headers,
        tunnel_to           => $tunnel_to,
        has_buffer_body     => $has_buffer_body ? 1 : 0,
        buffer_body         => $buffer_body,
        proxy_auth          => $proxy_auth,
        proxy_authorization => undef,
        max_auth_retries    => $max_auth_retries,
        callback            => \%callback,
        hop_kind            => 'initial',
    };

    $self->_start_connect_tunnel_attempt($operation, $spec);
    return $operation;
}

sub get ($self, $url, %option) {
    return $self->request('GET', $url, %option);
}

sub head ($self, $url, %option) {
    return $self->request('HEAD', $url, %option);
}

sub post ($self, $url, %option) {
    return $self->request('POST', $url, %option);
}

sub put ($self, $url, %option) {
    return $self->request('PUT', $url, %option);
}

sub delete ($self, $url, %option) {
    return $self->request('DELETE', $url, %option);
}

sub close ($self) {
    return $self if $self->{closed};
    $self->{closed} = 1;

    my %closed;
    my @h2 = map { @$_ } values %{$self->{h2_pool}};
    my @negotiating = map { @$_ } values %{$self->{h2_negotiating}};
    for my $connection (
        values %{$self->{idle}},
        @h2,
        @negotiating,
        values %{$self->{connections}},
    ) {
        next if !$connection;
        my $id = refaddr($connection);
        next if $closed{$id}++;
        $connection->close if !$connection->is_closed;
    }

    $self->{idle} = {};
    $self->{h2_pool} = {};
    $self->{h2_negotiating} = {};
    $self->{connections} = {};
    return $self;
}

1;

__END__

=head1 NAME

Linux::Event::HTTP::Client - high-level HTTP/1.x and HTTP/2 client

=head1 SYNOPSIS

    use v5.36;
    use Linux::Event::Loop;
    use Linux::Event::HTTP::Client;

    my $loop = Linux::Event::Loop->new;

    my $client = Linux::Event::HTTP::Client->new(
        loop  => $loop,
        http2 => 1,
    );

    my $operation = $client->get(
        'https://example.com/',

        buffer_body => 1_048_576,

        on_complete => sub ($tx) {
            say $tx->response->status;
            say $tx->response->body;

            $client->close;
            $loop->stop;
        },

        on_error => sub ($tx, $error) {
            warn $error;
            $client->close;
            $loop->stop;
        },
    );

    $loop->run;

=head1 DESCRIPTION

C<Linux::Event::HTTP::Client> is the ordinary outbound HTTP entry point.

It owns URL handling, connection selection and reuse, redirects, optional cookie
and authentication policy, explicit proxy routing, TLS policy, and HTTP/2
selection.

Client methods return a L<Linux::Event::HTTP::Client::Operation>. An Operation
normally contains one Transaction. Redirects and automatic authentication
retries create additional Transactions because one
L<Linux::Event::HTTP::Transaction> always means exactly one Request/Response
exchange.

=head1 CONSTRUCTOR

    my $client = Linux::Event::HTTP::Client->new(%options);

Common options include:

=over 4

=item * C<loop>

The L<Linux::Event::Loop>.

=item * C<http2>

Enables HTTP/2 negotiation for direct HTTPS requests. HTTP/2 requires
L<Net::HTTP2::nghttp2> 0.011 or newer.

=item * C<tls>

Linux::Event TLS options for HTTPS connections.

=item * C<max_redirects>

Default redirect limit. Default: 5.

=item * C<max_auth_retries>

Default automatic 401/407 authentication retry limit. Default: 3.

=item * C<cookie_jar>

An application-owned L<HTTP::CookieJar>.

=item * C<auth>

A L<Uniform::HTTP::Auth> manager for target-server authentication.

=item * C<proxy_auth>

A L<Uniform::HTTP::Auth> manager for proxy authentication.

=item * C<proxy>

Default explicit forward-proxy URL.

=item * C<http2_max_header_list_size>

Maximum decoded HTTP/2 response header-list size. Default: 65,536 bytes.

=item * C<http2_max_buffered_response_bytes>

Aggregate per-HTTP/2-connection budget for active buffered responses.
Default: 67,108,864 bytes (64 MiB).

=back

=head1 REQUESTS

The general form is:

    my $operation = $client->request(
        'POST',
        'https://example.com/items',
        body => $bytes,

        on_response => sub ($tx, $res) { ... },
        on_body     => sub ($tx, $res, $bytes) { ... },
        on_complete => sub ($tx) { ... },
        on_error    => sub ($tx, $error) { ... },
    );

Only absolute C<http> and C<https> target URLs are accepted.

Convenience methods C<get>, C<head>, C<post>, C<put>, and C<delete> call
C<request> with the corresponding method.

=head1 CALLBACKS

C<on_response> runs when the final response head is available.

C<on_body> receives decoded response-body bytes incrementally.

C<on_complete> runs after the complete final response boundary.

C<on_error> reports terminal operation failure.

C<on_redirect> runs when an actual redirect is followed.

Low-level informational responses may be exposed through the appropriate
connection callback path; redirect and authentication challenge bodies are
consumed internally when the Client is going to continue the Operation.

=head1 RESPONSE BODIES

Incoming response bodies are streaming-first.

Use C<on_body> for incremental consumption:

    on_body => sub ($tx, $res, $bytes) {
        process_bytes($bytes);
    }

If C<on_body> is absent, body bytes are drained rather than accumulated.

To request whole-body buffering, provide an explicit limit:

    buffer_body => 4 * 1024 * 1024

After successful completion:

    my $bytes = $tx->response->body;

There is no implicit unbounded response buffer.

=head1 REQUEST BODIES

For a complete body already in memory:

    $client->post(
        $url,
        body => $bytes,
        ...
    );

For incremental production:

    my $operation = $client->post(
        $url,

        stream_body => {
            on_drain  => sub ($body) { ... },
            on_cancel => sub ($body) { ... },
        },

        ...
    );

    my $body = $operation->request_body;
    $body->write($chunk);
    $body->complete;

A streaming producer is available immediately, including while HTTPS
TLS/ALPN selection is still in progress.

A supplied Content-Length is enforced. Unknown-length HTTP/1.1 streaming uses
chunked framing automatically. HTTP/2 uses its native DATA framing and does not
add Transfer-Encoding.

=head1 HTTP/2

Enable HTTP/2 with:

    my $client = Linux::Event::HTTP::Client->new(
        loop  => $loop,
        http2 => 1,
    );

For direct HTTPS requests the Client advertises C<h2> before C<http/1.1>. If H2
is selected, the same high-level Operation, Transaction, Request, and callback
model is used.

Selected HTTP/2 connections are pooled per origin and may carry concurrent
streams. The current local active-stream admission cap is 100 per connection;
nghttp2 also enforces peer SETTINGS.

A connection that receives GOAWAY is marked draining and receives no new
Operations. Existing streams are allowed to finish. Transparent replay based on
GOAWAY is not attempted without reliable last-stream-id information.

Current HTTP/2 boundaries:

=over 4

=item * Direct HTTPS + ALPN is the production HTTP/2 path.

=item * Cleartext h2c is not provided.

=item * Explicit forward proxies use the HTTP/1 path.

=item * HTTP/1 Upgrade and CONNECT handoff use the HTTP/1 path.

=item * Explicit HTTP version selection uses the HTTP/1 path.

=item * HTTP/2 currently requires the default Client connection class.

=back

=head1 REDIRECTS

The Client follows 301, 302, 303, 307, and 308 by default.

C<max_redirects> defaults to 5. Set it to 0 to disable automatic redirect
following.

Every followed redirect creates another Transaction in the Operation.

301 and 302 may convert POST to GET. 303 uses GET except for HEAD. 307 and 308
preserve method and body.

Complete scalar bodies can be replayed where required. Streaming body producers
are not automatically replayed.

Sensitive caller-supplied origin credentials are not propagated across origins.

=head1 COOKIES

Cookie policy is provided by an injected L<HTTP::CookieJar>:

    my $client = Linux::Event::HTTP::Client->new(
        loop       => $loop,
        cookie_jar => $jar,
    );

The jar is application-owned. Linux::Event::HTTP does not create an implicit
global cookie store.

Target URL identity remains separate from proxy route identity.

=head1 AUTHENTICATION

HTTP authentication mechanics are delegated to L<Uniform::HTTP::Auth>.

Use C<auth> for target-server 401 challenges and C<proxy_auth> for proxy 407
challenges.

Automatic authentication retry creates another Transaction in the same
Operation. The default retry limit is 3.

Streaming Request producers are not automatically replayed after a challenge.

=head1 FORWARD PROXIES

A default explicit proxy may be supplied to the Client:

    proxy => 'http://proxy.example:3128'

It may also be overridden per request.

The target URL remains the Operation identity while the proxy URL selects the
route connection. Target cookies and target authentication remain keyed to the
target; proxy authentication remains keyed to the proxy.

For an HTTPS proxy endpoint, TLS is established to the proxy itself. An HTTPS
target sent through ordinary forward-proxy mode is not silently converted into
a CONNECT tunnel.

=head1 CLIENT UPGRADE

An ordinary HTTP/1.1 request can opt into protocol Upgrade with:

    upgrade_to => 'MyProtocolConnection'

The Request must advertise the Upgrade normally. On a validated 101 response,
the HTTP Transaction completes and the same live Linux::Event stream transitions
to the requested class.

Already-read post-HTTP bytes are preserved for the new protocol.

Upgrade is an HTTP/1 transport handoff and therefore uses the HTTP/1 path even
when this Client has C<http2 =E<gt> 1>.

=head1 CONNECT TUNNELS

Use C<connect_tunnel> when a real HTTP/1.1 CONNECT tunnel is required:

    $client->connect_tunnel(
        $proxy_url,
        $target_authority,
        tunnel_to => 'MyTunnelConnection',
        ...
    );

A successful 2xx CONNECT response completes the HTTP Transaction at the
response-head boundary and transitions the same live Linux::Event stream to the
requested tunnel class.

Non-2xx responses remain ordinary HTTP responses.

=head1 CONNECTION REUSE

HTTP/1 connections are reused when response framing and persistence rules leave
the connection safe for another exchange.

Selected HTTP/2 connections remain in a per-origin pool while streams are
active and may carry concurrent Operations.

Forward-proxy HTTP/1 connections are pooled by route origin rather than target
origin.

=head1 METHODS

=head2 request

Starts one high-level HTTP Operation and returns it immediately.

=head2 get, head, post, put, delete

Convenience request methods.

=head2 connect_tunnel

Establishes an explicit HTTP/1.1 CONNECT tunnel.

=head2 loop

Returns the Loop.

=head2 http2

True when HTTP/2 support is enabled.

=head2 http2_max_header_list_size

Returns the HTTP/2 decoded response header-list limit.

=head2 http2_max_buffered_response_bytes

Returns the aggregate per-H2-connection buffered-response budget.

=head2 max_redirects

Returns the default redirect limit.

=head2 max_auth_retries

Returns the default automatic authentication retry limit.

=head2 cookie_jar

Returns the configured cookie jar or undef.

=head2 auth

Returns the configured target authentication manager or undef.

=head2 proxy_auth

Returns the configured proxy authentication manager or undef.

=head2 proxy

Returns the configured default forward-proxy URL or undef.

=head2 connection_class

Returns the configured HTTP/1 Client::Connection class.

=head2 is_closed

True after the Client has been closed.

=head2 close

Closes Client-owned idle and active connections according to Client shutdown
semantics.

=head1 SEE ALSO

L<Linux::Event::HTTP>, L<Linux::Event::HTTP::Server>,
L<Linux::Event::HTTP::Client::Operation>,
L<Linux::Event::HTTP::Client::Connection>,
L<Linux::Event::HTTP::Request>, L<Linux::Event::HTTP::Response>,
L<Linux::Event::HTTP::Transaction>, L<Linux::Event::HTTP::Body::Stream>,
L<Uniform::HTTP::Auth>, L<HTTP::CookieJar>.

=cut
