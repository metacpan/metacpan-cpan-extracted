package Discord::Client::REST;

use v5.26;
use strict;
use warnings;
use Carp qw(croak);
use Digest::SHA qw(sha256_hex);
use HTTP::Request;
use IO::Async::Loop;
use JSON::PP ();
use Net::Async::HTTP;
use Scalar::Util qw(blessed);
use Time::HiRes qw(clock_gettime CLOCK_MONOTONIC time);
use URI;
use URI::Escape qw(uri_unescape);
use Discord::Client ();
use Discord::Client::REST::Error;
use Discord::Client::REST::RateLimiter;

our $VERSION = '0.002';

sub new {
    my ( $class, %args ) = @_;

    # Validate authentication and capacity before creating a transport.
    my $auth = $args{auth} // 1;
    croak 'auth must be zero or one' unless !ref($auth) && $auth =~ /\A[01]\z/;
    croak 'token is required' if $auth && ( !defined( $args{token} ) || !length( $args{token} ) );
    croak 'token must be a scalar without whitespace'
        if defined( $args{token} )
        && ( ref( $args{token} ) || $args{token} =~ /[\s\x00-\x1f\x7f]/ );
    my $loop = $args{loop} // IO::Async::Loop->new;
    my %limits = _scheduler_limits( \%args );
    my $timeout = $args{timeout} // 30;
    croak 'timeout must be positive'
        if ref($timeout)
        || $timeout !~ /\A\d+(?:\.\d+)?\z/
        || $timeout <= 0;

    # Build an explicit API origin; credentials, query strings and fragments are invalid.
    my $base = $args{base_url} // 'https://discord.com/api/v10';
    my $uri = URI->new($base);
    croak 'base_url must be an absolute HTTP(S) URL without credentials, query or fragment'
        unless ( $uri->scheme // '' ) =~ /\Ahttps?\z/
        && $uri->host
        && !defined( $uri->userinfo )
        && !defined( $uri->query )
        && !defined( $uri->fragment );
    $base =~ s{/\z}{};
    my $url = $args{user_agent_url} // 'https://github.com/viasnake/Discord-Client';
    croak 'user_agent_url must be an HTTP(S) URL without whitespace or parentheses'
        if ref($url) || $url !~ m{\Ahttps?://[^\s()]+\z};

    for my $key (qw(clock wall_clock delay on_diagnostic)) {
        croak "$key must be a code reference" if exists( $args{$key} ) && ref( $args{$key} ) ne 'CODE';
    }

    # A supplied transport stays caller-owned; an owned transport verifies TLS.
    my $http = $args{http};
    my $owns_http = !$http;
    if ($owns_http) {
        $http = Net::Async::HTTP->new(
            fail_on_error => 0,
            max_redirects => 0,
            pipeline => 0,
            SSL_verify_mode => 1,
            SSL_verifycn_scheme => 'http',
            max_connections_per_host => $limits{max_in_flight},
            timeout => $timeout,
        );
        $loop->add($http);
    }
    croak 'http must provide do_request' unless blessed($http) && $http->can('do_request');
    my $self = bless {
        token => $args{token},
        auth => 0 + $auth,
        loop => $loop,
        http => $http,
        owns_http => $owns_http,
        base_url => $base,
        timeout => $timeout,
        user_agent => "DiscordBot ($url, $Discord::Client::VERSION)",
        json => JSON::PP->new->utf8->allow_nonref,
    }, $class;

    # Inject clocks and delays so scheduling is deterministic without network I/O.
    $self->{limiter} = Discord::Client::REST::RateLimiter->new(
        %limits,
        loop => $loop,
        on_diagnostic => $args{on_diagnostic},
        clock => $args{clock} // sub { clock_gettime(CLOCK_MONOTONIC) },
        wall_clock => $args{wall_clock} // sub { time() },
        delay => $args{delay} // sub { $loop->delay_future( after => $_[0] ) },
    );
    return $self;
}

sub _scheduler_limits {
    my ($options) = @_;

    # Retries may be disabled; queue and concurrency capacities must remain positive.
    my %limits = ( max_pending => 1000, max_buckets => 1024, max_in_flight => 8, max_retries => 3 );
    for my $key ( keys %limits ) {
        $limits{$key} = $options->{$key} if exists $options->{$key};
        my $requirement = $key eq 'max_retries' ? 'a nonnegative integer' : 'a positive integer';
        croak "$key must be $requirement"
            if !defined( $limits{$key} )
            || ref( $limits{$key} )
            || $limits{$key} !~ /\A\d+\z/
            || ( $limits{$key} == 0 && $key ne 'max_retries' );
    }
    return %limits;
}

sub loop { $_[0]->{loop} }
sub stats { $_[0]->{limiter}->stats }

sub _endpoint {
    my ( $self, $method, $pattern, $ids, %args ) = @_;

    # Validate each resource segment before inserting it into a fixed endpoint.
    for my $id (@$ids) {
        return $self->_fail( $self->{loop}->new_future, 'Invalid resource ID', 'request' )
            unless defined($id) && !ref($id) && $id =~ /\A\d{1,20}\z/;
        $pattern =~ s/\{id\}/$id/;
    }
    return $self->request( $method, $pattern, %args );
}
sub get_current_user { $_[0]->request( 'GET', '/users/@me' ) }

sub get_user {
    my ( $self, $user_id ) = @_;
    return $self->_endpoint( 'GET', '/users/{id}', [$user_id] );
}

sub get_channel {
    my ( $self, $channel_id ) = @_;
    return $self->_endpoint( 'GET', '/channels/{id}', [$channel_id] );
}

sub get_guild {
    my ( $self, $guild_id, %query ) = @_;
    return $self->_endpoint( 'GET', '/guilds/{id}', [$guild_id], query => \%query );
}

sub get_guild_channels {
    my ( $self, $guild_id ) = @_;
    return $self->_endpoint( 'GET', '/guilds/{id}/channels', [$guild_id] );
}

sub get_guild_member {
    my ( $self, $guild_id, $user_id ) = @_;
    return $self->_endpoint( 'GET', '/guilds/{id}/members/{id}', [ $guild_id, $user_id ] );
}

sub get_message {
    my ( $self, $channel_id, $message_id ) = @_;
    return $self->_endpoint( 'GET', '/channels/{id}/messages/{id}', [ $channel_id, $message_id ] );
}

sub get_messages {
    my ( $self, $channel_id, %query ) = @_;
    return $self->_fail( $self->{loop}->new_future, 'Invalid message pagination', 'request' )
        unless _valid_message_query( \%query );
    return $self->_endpoint( 'GET', '/channels/{id}/messages', [$channel_id], query => \%query );
}

sub _valid_message_query {
    my ($query) = @_;

    # Pagination selects at most one position and a bounded page size.
    return 0 if grep { $_ !~ /\A(?:before|after|around|limit)\z/ } keys %$query;
    return 0 if ( grep { exists $query->{$_} } qw(before after around) ) > 1;
    for my $key (qw(before after around)) {
        next unless exists $query->{$key};
        my $id = $query->{$key};
        return 0 unless defined($id) && !ref($id) && $id =~ /\A\d{1,20}\z/;
    }
    if ( exists $query->{limit} ) {
        my $limit = $query->{limit};
        return 0
            unless defined($limit)
            && !ref($limit)
            && $limit =~ /\A\d+\z/
            && $limit >= 1
            && $limit <= 100;
    }
    return 1;
}

sub _message_body {
    my ( $self, $method, $path, $ids, $body ) = @_;

    # Accept text as a convenience while preserving native Discord message fields.
    $body = { content => "$body" } if defined($body) && !ref($body);
    return $self->_fail( $self->{loop}->new_future, 'Message body must be text or a hash reference', 'request' )
        unless ref($body) eq 'HASH';
    return $self->_endpoint( $method, $path, $ids, json => $body );
}

sub create_message {
    my ( $self, $channel_id, $body ) = @_;
    return $self->_message_body( 'POST', '/channels/{id}/messages', [$channel_id], $body );
}

sub edit_message {
    my ( $self, $channel_id, $message_id, $body ) = @_;
    return $self->_message_body( 'PATCH', '/channels/{id}/messages/{id}', [ $channel_id, $message_id ], $body );
}

sub delete_message {
    my ( $self, $channel_id, $message_id ) = @_;
    return $self->_endpoint( 'DELETE', '/channels/{id}/messages/{id}', [ $channel_id, $message_id ] );
}

sub create_dm {
    my ( $self, $id ) = @_;
    return $self->_fail( $self->{loop}->new_future, 'Invalid resource ID', 'request' )
        unless defined($id) && !ref($id) && $id =~ /\A\d{1,20}\z/;
    return $self->request( 'POST', '/users/@me/channels', json => { recipient_id => "$id" } );
}

sub trigger_typing {
    my ( $self, $channel_id ) = @_;
    return $self->_endpoint( 'POST', '/channels/{id}/typing', [$channel_id] );
}

sub request {
    my ( $self, $method, $path, %args ) = @_;

    # Reject invalid arguments before admitting the request to the scheduler.
    my $future = $self->{loop}->new_future;
    my $auth = exists( $args{auth} ) ? $args{auth} : $self->{auth};
    return $self->_fail( $future, 'auth must be zero or one', 'request' )
        unless defined($auth) && !ref($auth) && $auth =~ /\A[01]\z/;
    return $self->_fail( $future, 'Bot authorization requires a token', 'request' )
        if $auth && ( !defined( $self->{token} ) || !length( $self->{token} ) );
    return $self->_fail( $future, 'Invalid HTTP method', 'request' )
        unless defined($method) && !ref($method) && $method =~ /\A(?:GET|POST|PUT|PATCH|DELETE|HEAD)\z/;
    return $self->_fail( $future, 'Path must be relative to the Discord API', 'request' )
        unless defined($path)
        && !ref($path)
        && $path =~ m{\A/[^/]}
        && $path !~ /[\s\x00-\x1f\x7f#]/
        && $path !~ m{(?:\A|/)\.\.?(?:/|\?|\z)};

    # Prepare the complete wire request before reserving any scheduler capacity.
    my ( $request, $error ) = $self->_build_request( $method, $path, $auth, \%args );
    return $self->_fail( $future, $error, 'request' ) if defined $error;
    my $uri = $request->uri;

    # Separate route scheduling from secret values retained only for error redaction.
    my ( $route, $major, $secrets ) = _route( $method, URI->new($path)->path );
    push @$secrets, $self->{token} if defined $self->{token};
    my $source = $self->{limiter}->submit(
        route => $route,
        major => $major,
        auth => 0 + $auth,
        global_scope => $auth ? 'bot' : 'unauthenticated',
        send => sub {
            $self->{http}->do_request(
                request => $request,
                host => $uri->host,
                port => $uri->port,
                SSL => $uri->scheme eq 'https',
                timeout => $self->{timeout},
                max_redirects => 0,
            );
        },
    );

    # Propagate cancellation inward and sanitize transport results on the way out.
    $future->on_cancel( sub { $source->cancel unless $source->is_ready } );
    $source->on_ready(
        sub {
            $self->_complete_request( $future, $source, $method, $secrets, $args{raw_response} );
        }
    );
    return $future;
}

sub _build_request {
    my ( $self, $method, $path, $auth, $options ) = @_;

    # Resolve the API-relative path and encode repeated query parameters explicitly.
    my $uri = URI->new( $self->{base_url} . $path );

    if ( exists $options->{query} ) {
        return ( undef, 'query must be a hash reference' )
            unless ref( $options->{query} ) eq 'HASH';
        my @query;
        for my $key ( sort keys %{ $options->{query} } ) {
            my $value = $options->{query}{$key};
            push @query, $key, $_ for ref($value) eq 'ARRAY' ? @$value : ($value);
        }
        $uri->query_form(@query);
    }

    # Construct the wire request without allowing caller-supplied authorization headers.
    my $request = HTTP::Request->new( $method => $uri );
    $request->protocol('HTTP/1.1');
    $request->header( 'Host' => $uri->authority );
    $request->header( 'Authorization' => 'Bot ' . $self->{token} ) if $auth;
    $request->header( 'User-Agent' => $self->{user_agent} );
    $request->header( 'Content-Type' => 'application/json' );
    $request->header( 'Accept' => 'application/json' );

    # Serialize once so any rate-limit retry sends identical request bytes.
    if ( exists $options->{json} ) {
        my $body = eval { $self->{json}->encode( $options->{json} ) };
        return ( undef, 'Request body is not JSON encodable' ) if $@;
        $request->content($body);
    }

    return ( $request, undef );
}

sub _complete_request {
    my ( $self, $future, $source, $method, $secrets, $raw_response ) = @_;

    # Cancellation callbacks run before readiness; do not re-enter cancellation
    # when the scheduler reports the cancellation we just propagated inward.
    return if $future->is_ready || $future->is_cancelled;
    if ( $source->is_cancelled ) {
        $future->cancel;
        return;
    }

    # Scheduler failures may carry an HTTP response with useful status information.
    my ( $message, $category, $response );
    if ( $source->is_failed ) {
        ( $message, $category, $response ) = $source->failure;
        return $self->_fail( $future, $message, $category ) unless $response;
    }
    else {
        ($response) = $source->result;
    }

    # HEAD and 204 responses have no JSON body to decode.
    my $data;
    my $valid_json = 1;
    if ( $response->code != 204 && $method ne 'HEAD' ) {
        $data = eval { $self->{json}->decode( $response->content ) };
        $valid_json = !$@;
    }

    # Expose structured diagnostics only after removing known credentials.
    if ( !$response->is_success || defined $category ) {
        $category //= _http_error_category( $response->code );
        $message //= 'Discord REST request failed (HTTP ' . $response->code . ')';
        my $request_id = $response->header('X-Request-ID') // $response->header('CF-Ray');
        return $self->_fail(
            $future, $message, $category,
            status => $response->code,
            discord_code => _discord_error_code($data),
            request_id => _sanitize( $request_id, $secrets ),
            details => $valid_json ? _sanitize( $data, $secrets ) : undef,
        );
    }
    return $self->_fail( $future, 'Discord returned invalid JSON', 'json', status => $response->code )
        unless $valid_json;

    # A raw response must not retain the authenticated originating request.
    if ($raw_response) {
        my $copy = $response->clone;
        $copy->request(undef);
        $future->done($copy);
    }
    else {
        $future->done($data);
    }
}

sub _http_error_category {
    my ($status) = @_;
    return 'authentication' if $status == 401;
    return 'permission' if $status == 403;
    return 'not_found' if $status == 404;
    return 'server' if $status >= 500;
    return 'http';
}

sub _discord_error_code {
    my ($data) = @_;

    # Only expose a scalar numeric Discord code from the decoded response.
    return undef
        unless ref($data) eq 'HASH'
        && defined( $data->{code} )
        && !ref( $data->{code} )
        && $data->{code} =~ /\A\d+\z/;
    return $data->{code};
}

sub _route {
    my ( $method, $path ) = @_;

    # Keep major resource IDs distinct while normalizing ordinary resource IDs.
    my @segments = split m{/}, $path;
    my ( @major, @secrets );
    for ( my $segment_index = 1 ; $segment_index < @segments ; ++$segment_index ) {
        my $segment = $segments[$segment_index];

        # Major resource IDs partition buckets even when the remaining route shape matches.
        if ( $segment =~ /\A(?:channels|guilds|webhooks)\z/ && defined( $segments[ $segment_index + 1 ] ) ) {
            push @major, $segment, $segments[ $segment_index + 1 ];
            ++$segment_index;
            $segments[$segment_index] = ':major';

            # Reserved subresource names are not treated as webhook token segments.
            my $token = $segments[ $segment_index + 1 ];
            if ( $segment eq 'webhooks' && defined($token) && $token !~ /\A(?:messages|github|slack)\z/ ) {

                # Hash the token for bucket identity, but retain both spellings for redaction.
                push @major, sha256_hex($token);
                push @secrets, $token, uri_unescape($token);
                ++$segment_index;
                $segments[$segment_index] = ':token';
            }
            next;
        }

        # Callback tokens are opaque, including tokens consisting only of digits.
        if ( $segments[1] eq 'interactions' && $segment_index == 3 ) {
            push @secrets, $segment, uri_unescape($segment);
            $segments[$segment_index] = ':token';
            next;
        }
        $segments[$segment_index] = ':id' if $segment =~ /\A\d+\z/;
    }

    # Only token hashes participate in bucket keys; plaintext is used for redaction.
    my $major = join( ':', @major );
    return ( $method . ' ' . join( '/', @segments ) . ' ' . $major, $major, \@secrets );
}

sub _sanitize {
    my ( $value, $secrets ) = @_;

    # Redact both sensitive field names and known secrets nested in response data.
    if ( ref($value) eq 'HASH' ) {
        return {
            map { $_ => /(?:token|authorization|secret)/i ? '[REDACTED]' : _sanitize( $value->{$_}, $secrets ) }
                keys %$value
        };
    }
    if ( ref($value) eq 'ARRAY' ) {
        return [ map { _sanitize( $_, $secrets ) } @$value ];
    }
    return $value if !defined($value) || ref($value);
    for my $secret (@$secrets) {
        $value =~ s/\Q$secret\E/[REDACTED]/g if length $secret;
    }
    return $value;
}

sub _fail {
    my ( $self, $future, $message, $category, %details ) = @_;

    # Use the same sanitized details in the Future tuple and structured REST error.
    my $error = Discord::Client::REST::Error->new(
        message => $message,
        category => $category,
        %details,
    );
    return $future->fail( $message, $category, $error );
}

sub close {
    my ($self) = @_;

    # Stop scheduled requests before detaching an owned HTTP transport.
    my $future = $self->{limiter}->close;
    if ( $self->{owns_http} && $self->{http}->loop ) {
        $self->{loop}->remove( $self->{http} );
    }
    return $future;
}

1;

__END__

=encoding UTF-8

=head1 NAME

Discord::Client::REST - Future-based Discord REST API v10 client

=head1 SYNOPSIS

    use Discord::Client::REST;

    # Create a standalone REST client.
    my $rest = Discord::Client::REST->new(token => $ENV{DISCORD_BOT_TOKEN});

    # Wait for one request outside a handler.
    my $request = $rest->get_current_user;
    $rest->loop->await($request);
    my $user = $request->get;

    # Release owned resources.
    $rest->close->get;

=head1 DESCRIPTION

Makes Discord API v10 HTTP requests without a Gateway connection.
The caller drives the loop. Asynchronous methods return Futures with decoded
JSON, string IDs and unknown fields preserved. HTTP 204 returns undef.
Message helpers send JSON, not multipart file uploads.

=head1 METHODS

=head2 new

    my $rest = Discord::Client::REST->new(token => $token, loop => $loop);

Returns a client without network I/O. C<loop> is optional; otherwise one is
created. C<auth =E<gt> 0> needs no bot token and omits Bot authorization by
default. C<http> can inject a caller-owned transport.

C<base_url> defaults to C<https://discord.com/api/v10> and accepts another HTTP(S)
URL for testing. HTTPS verifies the peer and hostname; redirects are disabled.
C<user_agent_url> sets the URL in C<DiscordBot (URL, VERSION)>.
Resource limits are described under L</RATE LIMITS AND OPTIONS>.

=head2 request

C<request(method, path, query =E<gt> $hashref, json =E<gt> $body)> returns a
Future for an API request. Query and JSON arguments are optional.

    # Fetch one page of messages.
    my $page = $rest->request('GET', '/channels/'.$channel_id.'/messages',
        query => {limit => 20, before => $message_id},
    );

    # Send a JSON message.
    my $send = $rest->request('POST', '/channels/'.$channel_id.'/messages',
        json => {content => 'Hello'},
    );

Methods are uppercase C<GET>, C<HEAD>, C<POST>, C<PUT>, C<PATCH> or C<DELETE>.
Paths start with one slash and are relative to the base URL.
Requests use Bot authorization by default. Query arrays become repeated keys;
JSON is UTF-8. Invalid arguments return a failed Future before I/O.

Success returns decoded JSON with string IDs and unknown fields preserved.
HTTP 204 and HEAD return undef. C<raw_response =E<gt> 1> returns a cloned
C<HTTP::Response> with its original request removed. Successful JSON is still
validated. Malformed JSON fails with C<json>.

For interaction callbacks and webhooks, C<auth =E<gt> 0> on a request omits Bot
authorization and uses a separate global-limit scope. A client constructed
with C<auth =E<gt> 0> needs no bot token and uses that scope by default.

=head2 get_current_user

Returns a Future containing the bot user hashref.

=head2 get_user

C<get_user(user_id)> returns a Future containing a user hashref.

=head2 get_channel

C<get_channel(channel_id)> returns a Future containing a channel hashref.

=head2 get_guild

C<get_guild(guild_id, query_pairs)> returns a Future containing a guild hashref.
Query pairs are optional.

=head2 get_guild_channels

C<get_guild_channels(guild_id)> returns a Future containing an arrayref of channels.

=head2 get_guild_member

C<get_guild_member(guild_id, user_id)> returns a Future containing a member hashref.

=head2 get_message

C<get_message(channel_id, message_id)> returns a Future containing a message hashref.

=head2 get_messages

C<get_messages(channel_id, query_pairs)> returns a Future containing one page of
messages as an arrayref. Accepts C<limit> (1-100) and at most one of C<before>,
C<after> or C<around>. It does not scan further pages.

=head2 create_message

C<create_message(channel_id, text_or_hash)> returns a Future containing the
created message. Hashrefs preserve embeds, components, C<allowed_mentions>
and other supplied JSON fields.

=head2 edit_message

C<edit_message(channel_id, message_id, text_or_hash)> returns a Future containing
the edited message.

=head2 delete_message

C<delete_message(channel_id, message_id)> returns a Future resolving to undef.

=head2 create_dm

C<create_dm(user_id)> returns a Future containing the DM channel hashref.

=head2 trigger_typing

C<trigger_typing(channel_id)> returns a Future resolving to undef.

Helper IDs are decimal strings. Invalid IDs, pagination or body shapes fail
before I/O. Discord validates endpoint permissions and payload semantics.

=head2 close

Returns a Future after failing outstanding work with C<shutdown>, cancelling
I/O and timers, and removing the owned HTTP notifier. Repeated calls succeed.
An injected HTTP transport remains caller-owned.

=head2 loop

Returns the configured IO::Async::Loop.

=head2 stats

Returns a copied hashref of request, retry and queue counters.

=head1 ERRORS AND CANCELLATION

    # Inspect a failed Future.
    my ($message, $category, $error) = $request->failure;
    my $status = $error->status;
    my $code = $error->discord_code;

The error is a C<Discord::Client::REST::Error>. It exposes C<message>, C<category>,
C<status>, C<discord_code>, C<request_id> and C<details>. HTTP status and Discord
code are separate. C<request_id> comes from C<X-Request-ID> or C<CF-Ray>.
Validation details redact known credentials and sensitive fields. Error strings
omit tokens, bodies and raw transport exceptions.

=over 4

=item C<request>

Invalid request arguments.

=item C<authentication>

HTTP 401 or previously rejected bot token.

=item C<permission>

HTTP 403.

=item C<not_found>

HTTP 404.

=item C<http>

Other unsuccessful HTTP response.

=item C<server>

HTTP 5xx.

=item C<json>

Invalid successful JSON response.

=item C<rate_limit>

Exhausted retries or unusable 429 delay.

=item C<timeout>

HTTP request or stall timeout.

=item C<transport>

Transport failure or invalid result.

=item C<queue_full>

Request or route capacity exhausted.

=item C<shutdown>

Client closed.

=back

A Bot-authorized 401 rejects queued and future requests without sending them.
Already sent requests may finish but cannot retry. Create a new client with a
corrected token. Cancelling a Future cancels active local I/O; it does not undo
an operation Discord may have received.

=head1 RATE LIMITS AND OPTIONS

Limits are learned from L<response headers|https://docs.discord.com/developers/topics/rate-limits>. Channel, guild and webhook ID/token
pairs separate buckets. One request runs per bucket; separate buckets can run
concurrently. C<X-RateLimit-Bucket> joins routes sharing quota.
C<X-RateLimit-Reset-After> is preferred over C<X-RateLimit-Reset>.

A 429 waits for the larger usable delay from JSON C<retry_after> and C<Retry-After>.
Global and shared limits are respected. Missing or nonpositive delays fail.
Only received 429 responses are retried. Network failures, timeouts and 5xx
responses are not retried automatically.

=over 4

=item C<max_pending>

Queued and active requests; default 1000.

=item C<max_in_flight>

Concurrent HTTP requests; default 8.

=item C<max_buckets>

Route identities and learned bucket mappings; default 1024.

=item C<max_retries>

Additional 429 attempts; zero disables retries; default 3.

=item C<timeout>

Seconds per HTTP attempt; default 30.

=back

Capacity exhaustion fails with C<queue_full>. There is no queue-wait deadline;
callers can cancel Futures. Use one REST client per bot token because separate
clients do not coordinate limits.

C<stats> returns request, retry and queue counters. C<on_diagnostic =E<gt> CODE>
receives synchronous events with counts, status and timing, excluding request
paths, headers, bodies and credentials.

=head1 TRANSPORT INJECTION

Pass C<http =E<gt> $transport> to supply an object with C<do_request(%args)>.
It returns a cancellable Future yielding an C<HTTP::Response>; an C<http> failure
containing a response is also accepted. Arguments include C<request>, C<host>,
C<port>, C<SSL>, C<timeout> and C<max_redirects>. Attach the transport to the supplied
loop and honor those options.

Tests can supply C<clock> for monotonic seconds, C<wall_clock> for Unix seconds,
and C<delay> returning a cancellable Future for the given delay in seconds.

=head1 LICENSE

Apache License 2.0.

=cut
