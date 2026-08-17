package HTTP::API::Core;

use strict;
use warnings;
use HTTP::Tiny;
use JSON::PP qw(encode_json);
use Scalar::Util qw(blessed);
use Time::HiRes qw(sleep time);

use HTTP::API::Core::Response;
use HTTP::API::Core::Error;
use HTTP::API::Core::Pagination;

our $VERSION = '1.00';

sub new {
    my ($class, %args) = @_;

    my $base_url = delete $args{base_url};
    die "base_url is required\n" if !defined($base_url) || $base_url eq '';
    $base_url =~ s{/+\z}{};

    my $headers = delete($args{headers}) || {};
    die "headers must be a hash reference\n" if ref($headers) ne 'HASH';

    my $timeout = exists $args{timeout} ? delete($args{timeout}) : 10;
    die "timeout must be a positive number\n"
        if !defined($timeout)
        || $timeout !~ /\A(?:\d+(?:\.\d*)?|\.\d+)\z/
        || $timeout <= 0;

    my $transport = delete $args{transport};
    die "transport must be a code reference or object with request()\n"
        if defined($transport)
        && ref($transport) ne 'CODE'
        && !(blessed($transport) && $transport->can('request'));

    my $retry = exists $args{retry} ? delete($args{retry}) : {};
    die "retry must be a hash reference\n" if ref($retry) ne 'HASH';
    $retry = _normalize_retry($retry);

    my $hooks = exists $args{hooks} ? delete($args{hooks}) : {};
    $hooks = _normalize_hooks($hooks);

    die "unknown constructor option: $_\n" for sort keys %args;

    my $self = bless {
        base_url  => $base_url,
        headers   => { %$headers },
        timeout   => $timeout,
        transport => $transport,
        retry     => $retry,
        hooks     => $hooks,
    }, $class;

    $self->{http} = HTTP::Tiny->new(timeout => $timeout) if !$transport;
    return $self;
}

sub base_url { $_[0]->{base_url} }
sub timeout  { $_[0]->{timeout} }
sub retry    { +{ %{ $_[0]->{retry} }, methods => [ @{ $_[0]->{retry}{methods} } ] } }
sub hooks    { _clone_hooks($_[0]->{hooks}) }

sub get    { my ($self, $path, %opts) = @_; return $self->request('GET',    $path, %opts) }
sub post   { my ($self, $path, %opts) = @_; return $self->request('POST',   $path, %opts) }
sub put    { my ($self, $path, %opts) = @_; return $self->request('PUT',    $path, %opts) }
sub patch  { my ($self, $path, %opts) = @_; return $self->request('PATCH',  $path, %opts) }
sub delete { my ($self, $path, %opts) = @_; return $self->request('DELETE', $path, %opts) }

sub paginate {
    my ($self, $path, %opts) = @_;
    return HTTP::API::Core::Pagination->new(
        client => $self,
        path   => $path,
        %opts,
    );
}

sub request {
    my ($self, $method, $path, %opts) = @_;
    $method = uc($method // '');
    die "method is required\n" if $method eq '';
    die "path is required\n" if !defined $path;

    my $url = $path =~ m{\Ahttps?://} ? $path : $self->_join_url($path);

    my $query = exists $opts{query} ? delete($opts{query}) : {};
    die "query must be a hash reference\n" if ref($query) ne 'HASH';
    $url = _append_query($url, $query);

    my %headers = (%{ $self->{headers} }, %{ delete($opts{headers}) || {} });

    if (exists $opts{idempotency}) {
        my $idempotency = delete $opts{idempotency};
        die "idempotency must be a hash reference\n"
            if ref($idempotency) ne 'HASH';

        my %copy = %$idempotency;
        my $key = delete $copy{key};
        my $header = delete $copy{header};

        die "idempotency key must be a non-empty scalar\n"
            if !defined($key) || ref($key) || $key eq '';
        die "idempotency header must be a non-empty scalar\n"
            if !defined($header) || ref($header) || $header eq '';
        die "unknown idempotency option: $_\n" for sort keys %copy;

        my $wanted = lc $header;
        my $already = grep { lc($_) eq $wanted } keys %headers;
        $headers{$header} = "$key" if !$already;
    }

    my $content;

    if (exists $opts{json}) {
        my $value = delete $opts{json};
        $content = eval { encode_json($value) };
        if ($@) {
            die HTTP::API::Core::Error->new(
                category => 'encode',
                method   => $method,
                url      => $url,
                message  => "failed to encode JSON request: $@",
            );
        }
        $headers{'content-type'} ||= 'application/json';
        $headers{'accept'}       ||= 'application/json';
    }
    elsif (exists $opts{content}) {
        $content = delete $opts{content};
    }

    my $retry = exists $opts{retry} ? delete($opts{retry}) : $self->{retry};
    if (ref($retry) eq 'HASH' && $retry != $self->{retry}) {
        $retry = _normalize_retry($retry);
    }
    elsif (!ref($retry)) {
        $retry = $retry ? $self->{retry} : _normalize_retry({ attempts => 1 });
    }

    my $request_hooks = exists $opts{hooks}
        ? _normalize_hooks(delete($opts{hooks}))
        : {};
    my $hooks = _merge_hooks($self->{hooks}, $request_hooks);

    die "unknown request option: $_\n" for sort keys %opts;

    my $attempts = _method_is_retryable($method, $retry)
        ? $retry->{attempts}
        : 1;
    my $attempt = 0;

    while (++$attempt <= $attempts) {
        my $context = {
            method  => $method,
            url     => $url,
            headers => { %headers },
            content => $content,
            attempt => $attempt,
        };

        my $hook_error = _run_hooks($hooks->{before_request}, $context);
        die _hook_error($hook_error, $method, $url) if $hook_error;

        my $started_at = time;
        $context->{started_at} = $started_at;

        my ($response, $error, $elapsed) = $self->_request_once(
            $context->{method},
            $context->{url},
            $context->{headers},
            $context->{content},
        );

        $context->{elapsed} = $elapsed;
        $context->{request_id} = $response
            ? $response->request_id
            : $error ? $error->request_id : undef;

        if ($response) {
            my $after_error = _run_hooks(
                $hooks->{after_response},
                $response,
                $context,
            );
            die _hook_error(
                $after_error,
                $context->{method},
                $context->{url},
            ) if $after_error;
            return $response;
        }

        my $on_error_error = _run_hooks($hooks->{on_error}, $error, $context);
        die _hook_error(
            $on_error_error,
            $context->{method},
            $context->{url},
        ) if $on_error_error;

        die $error if $attempt >= $attempts || !$error->retryable;

        my $delay = _retry_delay($retry, $attempt, $error);
        sleep($delay) if $delay > 0;
    }

    die "unreachable retry state\n";
}

sub _request_once {
    my ($self, $method, $url, $headers, $content) = @_;
    my $raw;
    my $started_at = time;

    eval {
        if ($self->{transport}) {
            my $request_opts = {
                headers => $headers,
                (defined($content) ? (content => $content) : ()),
            };

            if (ref($self->{transport}) eq 'CODE') {
                $raw = $self->{transport}->($method, $url, $request_opts);
            }
            else {
                $raw = $self->{transport}->request($method, $url, $request_opts);
            }
        }
        else {
            $raw = $self->{http}->request($method, $url, {
                headers => $headers,
                (defined($content) ? (content => $content) : ()),
            });
        }
        1;
    } or do {
        my $cause = $@;
        return (undef, $cause, time - $started_at)
            if blessed($cause) && $cause->isa('HTTP::API::Core::Error');

        my $elapsed = time - $started_at;
        return (undef, HTTP::API::Core::Error->new(
            category  => 'transport',
            method    => $method,
            url       => $url,
            retryable => 1,
            elapsed   => $elapsed,
            message   => "HTTP transport failed: $cause",
        ), $elapsed);
    };

    if (ref($raw) ne 'HASH' || !exists $raw->{status}) {
        my $elapsed = time - $started_at;
        return (undef, HTTP::API::Core::Error->new(
            category  => 'transport',
            method    => $method,
            url       => $url,
            retryable => 1,
            elapsed   => $elapsed,
            message   => 'HTTP transport returned an invalid response',
        ), $elapsed);
    }

    my $elapsed = time - $started_at;
    my $response = HTTP::API::Core::Response->new(
        status  => 0 + $raw->{status},
        reason  => $raw->{reason},
        headers => $raw->{headers} || {},
        content => defined($raw->{content}) ? $raw->{content} : '',
        method  => $method,
        url     => $url,
        elapsed => $elapsed,
    );

    return ($response, undef, $elapsed) if $response->is_success;

    my $rate_limit = $response->rate_limit;
    my $rate_limited = ($response->status == 403 || $response->status == 429)
        && $rate_limit->exhausted;

    return (undef, HTTP::API::Core::Error->new(
        category    => 'http',
        status      => $response->status,
        method      => $method,
        url         => $url,
        retryable   => _retryable_status($response->status) || $rate_limited,
        retry_after => $response->header('retry-after'),
        request_id  => $response->request_id,
        elapsed     => $elapsed,
        response    => $response,
        message     => sprintf(
            'HTTP %d%s',
            $response->status,
            defined($response->reason) && length($response->reason)
                ? ' ' . $response->reason
                : '',
        ),
    ), $elapsed);
}

sub _normalize_hooks {
    my ($hooks) = @_;
    $hooks = {} if !defined $hooks;
    die "hooks must be a hash reference\n" if ref($hooks) ne 'HASH';

    my %copy = %$hooks;
    my %normalized;
    for my $name (qw(before_request after_response on_error)) {
        my $value = delete $copy{$name};
        next if !defined $value;

        my @callbacks = ref($value) eq 'ARRAY' ? @$value : ($value);
        die "hook $name must be a code reference or array reference of code references\n"
            if grep { ref($_) ne 'CODE' } @callbacks;
        $normalized{$name} = \@callbacks;
    }

    die "unknown hook: $_\n" for sort keys %copy;
    return \%normalized;
}

sub _clone_hooks {
    my ($hooks) = @_;
    return {
        map { $_ => [ @{ $hooks->{$_} || [] } ] }
        qw(before_request after_response on_error)
    };
}

sub _merge_hooks {
    my ($first, $second) = @_;
    return {
        map {
            $_ => [
                @{ $first->{$_} || [] },
                @{ $second->{$_} || [] },
            ]
        } qw(before_request after_response on_error)
    };
}

sub _run_hooks {
    my ($callbacks, @args) = @_;
    for my $callback (@{ $callbacks || [] }) {
        my $ok = eval { $callback->(@args); 1 };
        return $@ if !$ok;
    }
    return undef;
}

sub _hook_error {
    my ($cause, $method, $url) = @_;
    return $cause if blessed($cause) && $cause->isa('HTTP::API::Core::Error');
    return HTTP::API::Core::Error->new(
        category  => 'hook',
        method    => $method,
        url       => $url,
        retryable => 0,
        message   => "HTTP API core hook failed: $cause",
    );
}

sub _normalize_retry {
    my ($retry) = @_;
    my %copy = %$retry;

    my $attempts = exists $copy{attempts} ? delete($copy{attempts}) : 3;
    die "retry attempts must be a positive integer\n"
        if $attempts !~ /\A\d+\z/ || $attempts < 1;

    my $base_delay = exists $copy{base_delay}
        ? delete($copy{base_delay})
        : 0.25;
    die "retry base_delay must be a non-negative number\n"
        if !_non_negative_number($base_delay);

    my $max_delay = exists $copy{max_delay}
        ? delete($copy{max_delay})
        : 5;
    die "retry max_delay must be a non-negative number\n"
        if !_non_negative_number($max_delay);

    my $jitter = exists $copy{jitter} ? delete($copy{jitter}) : 1;
    $jitter = $jitter ? 1 : 0;

    my $methods = exists $copy{methods}
        ? delete($copy{methods})
        : [qw(GET HEAD PUT DELETE OPTIONS)];
    die "retry methods must be an array reference\n"
        if ref($methods) ne 'ARRAY';

    my @methods = map { uc($_ // '') } @$methods;
    die "retry methods must not contain empty values\n"
        if grep { $_ eq '' } @methods;

    die "unknown retry option: $_\n" for sort keys %copy;

    return {
        attempts   => 0 + $attempts,
        base_delay => 0 + $base_delay,
        max_delay  => 0 + $max_delay,
        jitter     => $jitter,
        methods    => \@methods,
    };
}

sub _method_is_retryable {
    my ($method, $retry) = @_;
    my %allowed = map { $_ => 1 } @{ $retry->{methods} };
    return $allowed{$method} ? 1 : 0;
}

sub _retry_delay {
    my ($retry, $attempt, $error) = @_;

    my $retry_after = $error->retry_after;
    if (defined($retry_after)
        && $retry_after =~ /\A(?:\d+(?:\.\d*)?|\.\d+)\z/)
    {
        return 0 + $retry_after;
    }

    my $rate_limit = $error->rate_limit;
    if ($rate_limit && $rate_limit->exhausted) {
        my $wait = $rate_limit->wait_seconds;
        return $wait if defined $wait;
    }

    my $delay = $retry->{base_delay} * (2 ** ($attempt - 1));
    $delay = $retry->{max_delay} if $delay > $retry->{max_delay};
    $delay = rand($delay) if $retry->{jitter} && $delay > 0;
    return $delay;
}

sub _append_query {
    my ($url, $query) = @_;
    my @pairs;

    for my $key (sort keys %$query) {
        my $value = $query->{$key};
        next if !defined $value;

        my @values;
        if (ref($value) eq 'ARRAY') {
            @values = grep { defined $_ } @$value;
        }
        elsif (ref($value)) {
            die "query values must be scalars, array references, or undef\n";
        }
        else {
            @values = ($value);
        }

        push @pairs, map {
            _uri_escape($key) . '=' . _uri_escape($_)
        } @values;
    }

    return $url if !@pairs;

    my $fragment = '';
    if ($url =~ s/(#.*)\z//) {
        $fragment = $1;
    }

    my $separator = index($url, '?') >= 0 ? '&' : '?';
    return $url . $separator . join('&', @pairs) . $fragment;
}

sub _uri_escape {
    my ($value) = @_;
    my $bytes = defined($value) ? "$value" : '';
    utf8::encode($bytes) if utf8::is_utf8($bytes);
    $bytes =~ s/([^A-Za-z0-9\-._~])/sprintf('%%%02X', ord($1))/ge;
    return $bytes;
}

sub _non_negative_number {
    my ($value) = @_;
    return defined($value)
        && $value =~ /\A(?:\d+(?:\.\d*)?|\.\d+)\z/
        && $value >= 0;
}

sub _join_url {
    my ($self, $path) = @_;
    $path =~ s{\A/+}{};
    return $self->{base_url} . '/' . $path;
}

sub _retryable_status {
    my ($status) = @_;
    return 1 if $status == 408 || $status == 425 || $status == 429;
    return 1 if $status >= 500 && $status <= 599;
    return 0;
}

1;

__END__

=head1 NAME

HTTP::API::Core - Small foundation for JSON HTTP API clients

=head1 SYNOPSIS

  use HTTP::API::Core;

  my $api = HTTP::API::Core->new(
      base_url => 'https://api.example.com',
      headers  => { Authorization => "Bearer $token" },
      timeout  => 10,
      retry    => {
          attempts   => 3,
          base_delay => 0.25,
          max_delay  => 5,
          jitter     => 1,
      },
      hooks => {
          before_request => sub {
              my ($ctx) = @_;
              $ctx->{headers}{'X-Trace-Id'} = make_trace_id();
          },
      },
  );

  my $response = $api->get('/users');
  my $users = $response->json;
  my $rate = $response->rate_limit;

  my $pager = $api->paginate(
      '/users',
      mode  => 'cursor',
      items => 'data.users',
      next  => 'meta.next_cursor',
  );

  while (my $user = $pager->next) {
      ...
  }

=head1 DESCRIPTION

HTTP::API::Core is a deliberately small base layer for building HTTP API
clients. It provides base URL handling, default headers, JSON request/response
helpers, timeout configuration, structured errors, conservative retries,
pagination helpers, normalized rate-limit metadata, and lifecycle hooks.

Retry is enabled by default for GET, HEAD, PUT, DELETE, and OPTIONS. POST and
PATCH are not retried automatically. Retryable failures include transport
errors, HTTP 408, 425, 429, 5xx responses, and 403 responses that explicitly
report an exhausted rate limit.

=head1 METHODS

=head2 new

  my $api = HTTP::API::Core->new(
      base_url => 'https://api.example.com',
      headers  => { ... },
      timeout  => 10,
      retry    => { attempts => 3 },
      hooks    => { ... },
  );

C<base_url> is required. C<headers>, C<timeout>, C<retry>, and C<hooks> are
optional. Retry defaults to three attempts with exponential backoff and jitter.

=head2 get, post, put, patch, delete

Convenience methods around C<request>.

=head2 paginate

Returns an L<HTTP::API::Core::Pagination> iterator. Supported modes are
C<next_url>, C<page>, and C<cursor>.

=head2 request

Pass C<json> to encode a Perl value as JSON, or C<content> to send raw content.
Pass C<query> as a hash reference to append percent-encoded query parameters.
Array-reference values produce repeated keys and undefined values are omitted.
Per-request C<headers> override default headers. Pass C<retry =E<gt> 0> to
disable retry for one request, or a retry hash to override the policy. A
C<hooks> hash can add request-local hooks after client-level hooks.

Non-2xx responses throw L<HTTP::API::Core::Error> after retry is exhausted.
Successful responses expose normalized rate-limit metadata through
C<$response-E<gt>rate_limit>.

=head1 HOOKS

Hooks may be configured on the client or per request. Supported hook names are
C<before_request>, C<after_response>, and C<on_error>. Each value may be a
coderef or an arrayref of coderefs.

=head1 RETRY POLICY

The retry hash accepts C<attempts>, C<base_delay>, C<max_delay>, C<jitter>, and
C<methods>. Exponential backoff is capped by C<max_delay>. A numeric
C<Retry-After> response header takes precedence over the calculated delay.

=head1 RATE LIMITS

L<HTTP::API::Core::RateLimit> normalizes C<RateLimit-*>, C<X-RateLimit-*>, and
C<Retry-After> response headers.

=head1 ERROR HANDLING

Errors expose stable fields such as C<category>, C<status>, C<method>, C<url>,
C<retryable>, C<retry_after>, C<request_id>, and C<rate_limit>.

=head1 TRANSPORT CONTRACT

The C<transport> constructor option accepts either a code reference or an object
with a C<request> method. Both are called as
C<request($method, $url, \%options)> and must return a hash reference containing
at least C<status>, with optional C<reason>, C<headers>, and C<content> fields.

=head1 IDEMPOTENCY

Pass C<idempotency =E<gt> { key =E<gt> ..., header =E<gt> ... }> to add an
API-specific idempotency-key header to a request. The core deliberately does not
assume a universal header name.

=head1 LICENSE

This library is free software; you may redistribute it and/or modify it under
the same terms as Perl itself.

=cut