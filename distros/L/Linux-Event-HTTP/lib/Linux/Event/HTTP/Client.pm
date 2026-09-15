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

our $VERSION = '0.001';

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

sub new ($class, %option) {
    my $loop = delete $option{loop}
        // croak 'new(): loop is required';
    croak 'new(): loop must be an object implementing add() and watch_fd()'
        if !blessed($loop) || !$loop->can('add') || !$loop->can('watch_fd');

    my $connection_class = _load_connection_class(
        delete($option{connection_class})
            // 'Linux::Event::HTTP::Client::Connection',
    );
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
        idle             => {},
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

sub _take_idle_connection ($self, $origin) {
    my $connection = delete $self->{idle}{$origin};
    return undef if !$connection;
    return undef if $connection->is_closed;
    return undef if defined $connection->transaction;
    return $connection;
}

sub _new_connection ($self, $destination) {
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
            alpn        => ['http/1.1'],
            %{$self->{tls}},
        );
    }

    my $connection = $self->{connection_class}->connect(%connect);
    return $self->_track_connection($connection);
}

sub _connection_for ($self, $destination) {
    return $self->_take_idle_connection($destination->{origin})
        // $self->_new_connection($destination);
}

sub _release_connection ($self, $origin, $connection) {
    return if $self->{closed};
    return if !$connection || $connection->is_closed;
    return if defined $connection->transaction;

    if (my $idle = $self->{idle}{$origin}) {
        if (!$idle->is_closed && refaddr($idle) != refaddr($connection)) {
            $connection->close;
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

    my $connection = $self->_connection_for($route);
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
    my $connection = $self->_connection_for($destination);
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
    for my $connection (values %{$self->{idle}}, values %{$self->{connections}}) {
        next if !$connection;
        my $id = refaddr($connection);
        next if $closed{$id}++;
        $connection->close if !$connection->is_closed;
    }

    $self->{idle} = {};
    $self->{connections} = {};
    return $self;
}

1;

__END__

=head1 NAME

Linux::Event::HTTP::Client - asynchronous HTTP client

=head1 SYNOPSIS

    use HTTP::CookieJar;
    use Uniform::HTTP::Auth;

    my $jar = HTTP::CookieJar->new;
    my $auth = Uniform::HTTP::Auth->new(
        credentials => sub ($context) {
            return lookup_credentials($context);
        },
    );

    my $client = Linux::Event::HTTP::Client->new(
        loop => $loop,
        max_redirects => 5,
        max_auth_retries => 3,
        proxy => 'http://proxy.example:3128',
        cookie_jar => $jar,
        auth => $auth,
        proxy_auth => $auth,
    );

    my $operation = $client->get(
        'https://example.com/start',
        on_redirect => sub ($op, $tx, $res, $next_url) {
            say "redirecting to $next_url";
        },
        on_complete => sub ($tx) {
            say $tx->response->status;
        },
        on_error => sub ($tx, $error) {
            warn $error;
        },
    );

=head1 DESCRIPTION

C<Linux::Event::HTTP::Client> is the high-level outbound HTTP entry point. It
owns URL parsing, destination selection, redirect and authentication retry
policy, connection creation, HTTPS transport policy, explicit forward-proxy
routing, optional cookie-jar integration, and a small bounded reuse policy.

Authentication mechanics are delegated to L<Uniform::HTTP::Auth>. The Client
only receives 401/407 responses, supplies the exact Request object and
protection-space origin, decides whether a Request is replayable, and performs
the retry as another Transaction.

Client methods return L<Linux::Event::HTTP::Client::Operation>. An operation
normally contains one L<Linux::Event::HTTP::Transaction>, but redirects and
automatic authentication retries create additional Transactions because a
Transaction always represents exactly one Request/Response exchange.

Outgoing Request bodies may be complete scalar bodies or explicit streaming
producers owned by Transaction. Incoming Response handling remains
incremental-first. C<on_body> consumes body chunks. Without C<on_body>, body
bytes are drained and discarded. Explicit C<buffer_body =E<gt> $max_bytes>
requests bounded whole-body buffering; there is no implicit unbounded buffering.

=head1 METHODS

=head2 request

    my $operation = $client->request(
        'POST',
        'https://example.com/api/items',
        body => $bytes,
        max_redirects => 5,
        max_auth_retries => 3,
        on_response => sub ($tx, $res) { ... },
        on_complete => sub ($tx) { ... },
        on_error => sub ($tx, $error) { ... },
    );

Builds the canonical Request for each exchange and starts the operation
immediately. Only absolute C<http> and C<https> target URLs are accepted.

Without a selected proxy, the Client obtains or creates a connection for the
target URL origin and sends the path/query in origin-form. With a selected
proxy, it connects to that route and sends the target URL in HTTP/1 absolute-form.
Host remains the target Host. Target identity and route identity remain separate.

Callbacks C<on_response>, C<on_body>, and C<on_complete> describe the final
response. Intermediate redirect and authentication-challenge response bodies are
consumed according to normal HTTP framing but are not delivered through
C<on_body>. C<on_redirect> runs only for actual redirects, not auth retries.

=head2 authentication

    my $auth = Uniform::HTTP::Auth->new(
        credentials => sub ($context) {
            return $store->lookup(
                $context->{origin},
                $context->{realm},
                $context->{scheme},
            );
        },
    );

    my $client = Linux::Event::HTTP::Client->new(
        loop => $loop,
        auth => $auth,
        proxy_auth => $auth,
    );

C<auth> handles target-server 401 challenges from C<WWW-Authenticate>.
C<proxy_auth> handles proxy 407 challenges from C<Proxy-Authenticate>. They may
be different Uniform::HTTP::Auth objects or the same callback-based object.
Both options can be overridden per ordinary request with another object or
explicitly disabled for that request with undef.

The Client passes the normalized target or proxy origin and the actual
L<Linux::Event::HTTP::Request> to C<Uniform::HTTP::Auth 0.02>. Request implements
the Uniform message contract directly, so authentication reads its exact method,
request-target, and buffered scalar body without consuming an incremental body
producer. The returned value is installed as C<Authorization> or
C<Proxy-Authorization> on a new Transaction.

Authentication responses are drained to their normal HTTP message boundary
before retry. A retry may reuse the persistent connection when framing and
connection state permit it, or establish another connection when necessary.
A proxy-authenticated request can subsequently receive a target 401; the target
authentication retry preserves the proxy field for that same request-target.

Generated authentication fields are attempt-local. They are not copied across
redirects because Digest authentication incorporates request-target state and
Uniform::HTTP::Auth 0.02 does not provide a preemptive-auth cache. A redirected
target or proxy can challenge again normally.

Streaming Request producers are not replayed automatically. If a satisfiable
401/407 challenge is received for a streaming Request, the operation terminates
with an error rather than guessing how to rewind application state.

C<max_auth_retries> defaults to 3 and is an operation-wide bound separate from
C<max_redirects>. Zero disables automatic challenge retry and exposes 401/407 as
ordinary final responses. When the limit is reached, the next challenge is also
exposed as the final response rather than retried again.

When C<auth> is configured, caller-supplied C<Authorization> is rejected for
that request. Likewise C<proxy_auth> owns C<Proxy-Authorization>. Disable the
corresponding manager for a request if manually constructing that field.

The C<auth>, C<proxy_auth>, and C<max_auth_retries> accessors return the Client
defaults.

=head2 cookie_jar

C<cookie_jar> is an optional injected L<HTTP::CookieJar>. The Client does not
create a jar implicitly. Before each ordinary Request exchange the Client asks
the jar for C<cookie_header($target_url)> and feeds every Response Set-Cookie
field back through C<add($target_url,$value)> before redirect/authentication
policy or application callbacks run.

Cookie identity is always the target URL. A selected proxy never becomes the
cookie origin. When C<cookie_jar> is configured, caller-supplied Cookie fields
are rejected so cookie selection has one owner. The C<cookie_jar> accessor
returns the configured jar object or undef.

=head2 connect_tunnel

C<connect_tunnel($proxy_url, $target_authority, ...)> establishes one explicit
HTTP/1.1 CONNECT tunnel through the named proxy endpoint. The Client-level
default proxy and cookie jar are not consulted for tunnel routing or cookies.
The Client-level C<proxy_auth> is consulted by default for 407 challenges and
can be overridden or disabled with the method's C<proxy_auth> option.

A successful 2xx response transitions the same live Linux::Event stream to the
required C<tunnel_to> class. Non-2xx responses remain ordinary HTTP. A
satisfiable 407 can be drained and retried as another CONNECT Transaction before
that final outcome.

=head2 redirect policy

C<max_redirects> is a non-negative integer and defaults to 5. It can be set on
the Client or overridden per request. Zero disables automatic redirect
following. Automatic redirects recognize 301, 302, 303, 307, and 308 when
exactly one Location field is present.

301 and 302 change POST to GET and discard the body. 303 uses GET, or HEAD when
the original method was HEAD, and discards the body. 307 and 308 preserve the
method and body. Complete scalar bodies can be replayed for method-preserving
redirects; streaming bodies are not replayed automatically.

Authorization and caller-managed Cookie fields are stripped on cross-origin
redirects. With C<cookie_jar>, Cookie is regenerated independently for every
hop from the new target URL. Uniform-managed Authorization and
Proxy-Authorization fields are attempt-local and are regenerated only after a
new challenge.

=head2 request bodies

C<body> supplies a complete scalar Request body. C<stream_body =E<gt> { ... }>
selects incremental body production instead; the two are mutually exclusive.
The producer belongs to the current Transaction and is available through the
returned operation.

A supplied Content-Length is enforced exactly; otherwise HTTP/1.1 uses chunked
transfer coding automatically. HTTP/1.0 streaming requires Content-Length.

=head2 client Upgrade

C<upgrade_to =E<gt> $class> requests a live HTTP/1.1 protocol handoff through
the low-level Client::Connection. On a validated 101 response, the HTTP
Transaction completes and the same live stream transitions to C<$class>.
Authentication challenges may precede the successful 101 when the Request is
otherwise replayable.

=head2 buffer_body

C<buffer_body =E<gt> $max_bytes> requests bounded whole-response buffering and
cannot be combined with C<on_body>. The limit applies after HTTP transfer
framing has been removed and also applies while redirect or authentication
challenge bodies are consumed.

=head2 get, head, post, put, delete

Convenience forms that call C<request> with the corresponding HTTP method.

=head2 loop

Returns the Linux::Event Loop.

=head2 connection_class

Returns the configured Client::Connection class.

=head2 max_redirects

Returns the Client default redirect limit.

=head2 max_auth_retries

Returns the Client default automatic authentication retry limit.

=head2 proxy

Returns the configured Client default forward-proxy URL, or undef when there is
no default proxy. An individual operation may override or bypass the default.

=head2 auth

Returns the configured default target L<Uniform::HTTP::Auth> object or undef.

=head2 proxy_auth

Returns the configured default proxy L<Uniform::HTTP::Auth> object or undef.

=head2 is_closed

True after C<close>.

=head2 close

Closes all reachable idle or active client connections and prevents new
requests. Returns the Client.

=head1 CONNECTION REUSE

At most one idle connection is retained per route origin. For direct requests,
the route origin is the target origin. For a request using a proxy route, the
route origin is the proxy endpoint, so sequential requests for different target
origins can reuse the same persistent proxy connection. Cookie and target-auth
selection do not use route origin; proxy authentication does.

A connection that successfully leaves HTTP through Upgrade or CONNECT is never
returned to the HTTP idle pool. A non-2xx CONNECT response remains HTTP and may
leave a reusable proxy connection when its normal response framing permits it.

=head1 HTTPS

HTTPS uses the same Client::Connection class with a Linux::Event TLS transport.
For a direct HTTPS request, TLS is established to the target URL host. For an
C<https> forward-proxy endpoint, TLS is established to the proxy and the target
URI is then sent in absolute-form. Cookie and target-auth origin identity remain
the target URL; proxy-auth origin identity remains the proxy endpoint.

=head1 SEE ALSO

L<Uniform::HTTP::Auth>, L<HTTP::CookieJar>,
L<Linux::Event::HTTP::Client::Operation>,
L<Linux::Event::HTTP::Client::Connection>, L<Linux::Event::HTTP::Request>,
L<Linux::Event::HTTP::Response>, L<Linux::Event::HTTP::Transaction>,
L<Linux::Event::HTTP::Body::Stream>.

=cut
