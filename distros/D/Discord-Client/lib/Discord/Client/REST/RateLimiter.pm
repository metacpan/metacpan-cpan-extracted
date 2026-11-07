package Discord::Client::REST::RateLimiter;

use v5.26;
use strict;
use warnings;
use JSON::PP ();

our $VERSION = '0.002';

# Internal scheduler. One request per bucket avoids speculative quota use and
# out-of-order updates; unrelated buckets can still make progress concurrently.
sub new {
    my ( $class, %args ) = @_;

    # Keep route aliases, quota state and pending jobs local to this REST scheduler.
    return bless {
        %args,
        jobs => [],
        routes => {},
        buckets => {},
        active => 0,
        global_until => {},
        stopped => undef,
        counters => {},
    }, $class;
}

sub submit {
    my ( $self, %args ) = @_;

    # Reject work before allocating queue or bucket capacity.
    my $future = $self->{loop}->new_future;
    return $future->fail( 'REST client is closed', 'shutdown' ) if $self->{stopped};
    return $future->fail( 'Bot authentication is invalid', 'authentication' )
        if $self->{auth_failed} && $args{auth};
    return $future->fail( 'REST request capacity exceeded', 'queue_full' )
        if @{ $self->{jobs} } >= $self->{max_pending};

    # Reclaim only inactive, expired route entries before admitting a new route.
    $self->_prune;
    if ( !exists $self->{routes}{ $args{route} } ) {
        return $future->fail( 'REST bucket capacity exceeded', 'queue_full' )
            if keys( %{ $self->{routes} } ) >= $self->{max_buckets};
        $self->{routes}{ $args{route} } = { active => 0, blocked => 0 };
    }

    # Keep a request in its queue position across rate-limit retries.
    my $job = { %args, future => $future, retries => 0 };
    push @{ $self->{jobs} }, $job;
    $self->_emit('request_queued');

    # Release scheduling capacity before cancelling transport work that may call back.
    $future->on_cancel(
        sub {
            $self->_remove($job);
            $self->_emit('request_cancelled');
            my $transport_future = delete $job->{transport_future};
            $transport_future->cancel if $transport_future && !$transport_future->is_ready;
            $self->_pump;
        }
    );
    $self->_pump;
    return $future;
}

sub _root {
    my ($bucket) = @_;

    # Merged routes share one bucket; compress parent chains while resolving it.
    my @parents;
    while ( $bucket->{parent} ) {
        push @parents, $bucket;
        $bucket = $bucket->{parent};
    }
    $_->{parent} = $bucket for @parents;
    return $bucket;
}

sub _prune {
    my ($self) = @_;
    return if keys( %{ $self->{routes} } ) < $self->{max_buckets};

    # Active requests and unexpired limits must survive capacity-driven eviction.
    my %used = map { $_->{route} => 1 } @{ $self->{jobs} };
    my $now = $self->{clock}->();
    for my $route ( keys %{ $self->{routes} } ) {
        my $bucket = _root( $self->{routes}{$route} );
        next
            if $used{$route}
            || $bucket->{active}
            || $bucket->{blocked} > $now
            || ( $bucket->{reset} // 0 ) > $now;
        delete $self->{routes}{$route};
    }

    # Discard server bucket aliases only when no surviving route refers to them.
    my %live = map { _root($_) => 1 } values %{ $self->{routes} };
    for my $key ( keys %{ $self->{buckets} } ) {
        delete $self->{buckets}{$key} unless $live{ _root( $self->{buckets}{$key} ) };
    }
}

sub _pump {
    my ($self) = @_;
    return if $self->{pumping} || $self->{stopped};

    # Completion callbacks can re-enter scheduling; the outer pump owns progress.
    local $self->{pumping} = 1;
    if ( my $timer = delete $self->{timer} ) {
        $timer->cancel unless $timer->is_ready;
    }
    my $earliest;

    # Restart after each send: mock transports may finish synchronously and
    # callers may enqueue or cancel from completion callbacks.
    while ( $self->{active} < $self->{max_in_flight} ) {
        my $candidate;
        ( $candidate, $earliest ) = $self->_next_ready_job( $self->{clock}->() );
        last unless $candidate;
        $self->_send($candidate);
    }

    # One timer wakes the scheduler at the earliest known bucket or global deadline.
    if ( defined $earliest && !$self->{stopped} ) {
        my $delay = $earliest - $self->{clock}->();
        $delay = 0 if $delay < 0;
        my $timer = $self->{delay}->($delay);
        $self->{timer} = $timer;
        $timer->on_done(
            sub {
                delete $self->{timer};
                $self->_pump;
            }
        );
    }
}

sub _next_ready_job {
    my ( $self, $now ) = @_;
    my $earliest;

    # Keep FIFO order within each bucket while allowing unrelated buckets to progress.
    # Active buckets wake the pump on completion; timed limits contribute a wake-up deadline.
    for my $job ( @{ $self->{jobs} } ) {
        next if $job->{active};
        my $bucket = _root( $self->{routes}{ $job->{route} } );
        next if $bucket->{active};
        my $available_at = $self->_bucket_available_at( $bucket, $job->{global_scope}, $now );
        return ( $job, $earliest ) if $available_at <= $now;
        $earliest = $available_at if !defined($earliest) || $available_at < $earliest;
    }
    return ( undef, $earliest );
}

sub _bucket_available_at {
    my ( $self, $bucket, $global_scope, $now ) = @_;

    # An expired window invalidates its remaining-quota estimate.
    if ( defined( $bucket->{reset} ) && $bucket->{reset} <= $now ) {
        delete @{$bucket}{qw(reset remaining)};
    }

    # Every applicable limit must have elapsed before the request may start.
    my $available_at = $bucket->{blocked};
    my $global_reset_at = $self->{global_until}{$global_scope} // 0;
    $available_at = $global_reset_at if $global_reset_at > $available_at;
    if ( defined( $bucket->{remaining} ) && $bucket->{remaining} <= 0 ) {

        # Without a reset time, permit a probe instead of blocking the route forever.
        $available_at = $bucket->{reset}
            if defined( $bucket->{reset} ) && $bucket->{reset} > $available_at;
    }
    return $available_at;
}

sub _send {
    my ( $self, $job ) = @_;

    # Reserve both bucket and client capacity before invoking the transport.
    my $bucket = _root( $self->{routes}{ $job->{route} } );
    $job->{bucket} = $bucket;
    $job->{active} = 1;
    ++$bucket->{active};
    ++$self->{active};
    $self->_emit('http_started');
    return if $job->{removed} || $self->{stopped};
    --$bucket->{remaining} if defined( $bucket->{remaining} ) && $bucket->{remaining} > 0;

    # A transport exception is an uncertain failure and must not trigger a retry.
    my $transport_future = eval { $job->{send}->() };

    if ( !$transport_future || !eval { $transport_future->isa('Future') } ) {
        $self->_finish( $job, 'HTTP transport failed', 'transport' );
        return;
    }
    $job->{transport_future} = $transport_future;

    # Release the active slot before processing quota updates or notifying callers.
    $transport_future->on_ready(
        sub {
            delete $job->{transport_future};
            return if $job->{removed};
            $self->_release($job);
            $self->_complete_transport( $job, $transport_future );
            $self->_pump;
        }
    );
}

sub _complete_transport {
    my ( $self, $job, $transport_future ) = @_;

    # Cancellation and transport failures are uncertain deliveries, not retry opportunities.
    return $self->_finish( $job, 'HTTP transport was cancelled', 'transport' )
        if $transport_future->is_cancelled;
    if ( $transport_future->is_failed ) {
        my ( undef, $category, $response ) = $transport_future->failure;

        # Injected clients may fail on non-2xx HTTP responses. Preserve those responses
        # so authentication and 429 handling still pass through the normal response path.
        return $self->_response( $job, $response )
            if ref($response) && eval { $response->isa('HTTP::Response') };
        my $failure_category = ( $category // '' ) =~ /\A(?:timeout|stall_timeout)\z/ ? 'timeout' : 'transport';
        return $self->_finish( $job, 'HTTP request failed', $failure_category );
    }

    # A successful transport Future must still contain the expected response object.
    my ($response) = $transport_future->result;
    return $self->_finish( $job, 'Invalid HTTP transport response', 'transport' )
        unless ref($response) && eval { $response->isa('HTTP::Response') };
    return $self->_response( $job, $response );
}

sub _number {
    my ($value) = @_;

    # Accept nonnegative decimal header syntax without coercing arbitrary strings to numbers.
    return undef
        unless defined($value)
        && !ref($value)
        && $value =~ /\A\d+(?:\.\d+)?\z/;
    return 0 + $value;
}

sub _response {
    my ( $self, $job, $response ) = @_;
    my $now = $self->{clock}->();
    $self->_emit( 'http_response', status => $response->code );
    return if $job->{removed} || $self->{stopped};

    # Learn shared buckets and limits even when the HTTP status indicates a failure.
    my $bucket = $self->_response_bucket( $job, $response );
    $self->_update_bucket_limits( $bucket, $response, $now );

    # Authentication and rate-limit responses change scheduling, not just the result.
    if ( $response->code == 401 && $job->{auth} ) {
        $self->_invalidate_authentication( $job, $response );
        return;
    }
    if ( $response->code == 429 ) {
        $self->_handle_rate_limit( $job, $bucket, $response, $now );
        return;
    }
    $self->_finish( $job, undef, undef, $response );
}

sub _response_bucket {
    my ( $self, $job, $response ) = @_;
    my $bucket = _root( $self->{routes}{ $job->{route} } );

    # The server bucket hash is scoped by major resource IDs, including webhook tokens.
    my $hash = $response->header('X-RateLimit-Bucket');
    return $bucket unless defined($hash) && length($hash);

    my $key = $hash . ':' . $job->{major};
    my $known = $self->{buckets}{$key};

    # Merge learned aliases conservatively while other requests may still be active.
    if ( $known && _root($known) != $bucket ) {
        $known = _root($known);
        $known->{active} += $bucket->{active};
        for my $field (qw(blocked reset)) {
            $known->{$field} = $bucket->{$field}
                if defined( $bucket->{$field} )
                && ( !defined( $known->{$field} ) || $bucket->{$field} > $known->{$field} );
        }
        if ( defined $bucket->{remaining} ) {
            $known->{remaining} = $bucket->{remaining}
                if !defined( $known->{remaining} ) || $bucket->{remaining} < $known->{remaining};
        }
        $bucket->{parent} = $known;
        $bucket = $known;
        $_ = _root($_) for values %{ $self->{routes} }, values %{ $self->{buckets} };
    }
    $self->{buckets}{$key} = $bucket
        if exists( $self->{buckets}{$key} )
        || keys( %{ $self->{buckets} } ) < $self->{max_buckets};
    return $bucket;
}

sub _update_bucket_limits {
    my ( $self, $bucket, $response, $now ) = @_;

    # An overlapping response must not increase quota already consumed by another request.
    my $remaining = _number( $response->header('X-RateLimit-Remaining') );
    if ( defined $remaining ) {
        $bucket->{remaining} = $remaining
            if !$bucket->{active}
            || !defined( $bucket->{remaining} )
            || $remaining < $bucket->{remaining};
    }

    # Prefer relative reset times; translate epoch resets using the injected wall clock.
    my $after = _number( $response->header('X-RateLimit-Reset-After') );
    if ( !defined $after ) {
        my $epoch = _number( $response->header('X-RateLimit-Reset') );
        $after = $epoch - $self->{wall_clock}->() if defined $epoch;
    }
    if ( defined $after ) {
        $after = 0 if $after < 0;
        my $reset = $now + $after;
        $bucket->{reset} = $reset if !defined( $bucket->{reset} ) || $reset > $bucket->{reset};
    }
}

sub _invalidate_authentication {
    my ( $self, $job, $response ) = @_;

    # Fail queued Bot-authorized requests while leaving token-only requests independent.
    $self->{auth_failed} = 1;
    $self->_finish( $job, undef, undef, $response );
    my @queued = @{ $self->{jobs} };
    for my $queued (@queued) {
        next if $queued->{active} || !$queued->{auth};
        $self->_finish( $queued, 'Bot authentication is invalid', 'authentication' );
    }
}

sub _handle_rate_limit {
    my ( $self, $job, $bucket, $response, $now ) = @_;
    if ( $self->{auth_failed} && $job->{auth} ) {
        $self->_finish( $job, 'Bot authentication is invalid', 'authentication', $response );
        return;
    }

    # Honor the larger valid body/header delay rather than retrying too early.
    my $data = eval { JSON::PP->new->utf8->decode( $response->content ) };
    $data = {} unless ref($data) eq 'HASH';
    my $retry = _number( $data->{retry_after} );
    my $header = _number( $response->header('Retry-After') );
    $retry = $header if defined($header) && ( !defined($retry) || $header > $retry );
    if ( !defined($retry) || $retry <= 0 ) {
        $self->_finish( $job, 'Rate limit response has no positive retry delay', 'rate_limit', $response );
        return;
    }

    # Global limits apply to the authentication scope; other limits block only this bucket.
    my $until = $now + $retry;
    my $global =
           $data->{global}
        || ( $response->header('X-RateLimit-Global') // '' ) eq 'true'
        || ( $response->header('X-RateLimit-Scope') // '' ) eq 'global';
    $self->_emit( 'rate_limit', global => $global ? 1 : 0, retry_after => $retry );
    return if $job->{removed} || $self->{stopped};
    if ($global) {
        my $scope = $job->{global_scope};
        $self->{global_until}{$scope} = $until if $until > ( $self->{global_until}{$scope} // 0 );
    }
    else {
        $bucket->{blocked} = $until if $until > $bucket->{blocked};
    }

    # Record the limit even when this request has exhausted its retry budget.
    if ( $job->{retries}++ >= $self->{max_retries} ) {
        $self->_finish( $job, 'Rate limit retry budget exhausted', 'rate_limit', $response );
    }
    else {
        $self->_emit('request_retry');
    }

    # Otherwise the same job remains at its original queue position.
}

sub _release {
    my ( $self, $job ) = @_;

    # Release a reservation once, including when its bucket has since been merged.
    return unless delete $job->{active};
    --_root( $job->{bucket} )->{active};
    --$self->{active};
    delete $job->{bucket};
}

sub _remove {
    my ( $self, $job ) = @_;

    # Release capacity once; transport cancellation can re-enter removal.
    return if $job->{removed};
    $job->{removed} = 1;
    $self->_release($job);
    @{ $self->{jobs} } = grep { $_ != $job } @{ $self->{jobs} };
}

sub _finish {
    my ( $self, $job, $message, $category, $response ) = @_;

    # Detach the job before resolving its Future and running application callbacks.
    $self->_remove($job);
    return if $job->{future}->is_ready;
    $self->_emit( 'request_finished', category => $category // 'response' );
    if ( defined $category ) {
        $job->{future}->fail( $message, $category, $response );
    }
    else {
        $job->{future}->done($response);
    }
}

sub _emit {
    my ( $self, $type, %fields ) = @_;

    # Diagnostics contain scheduling metadata only and cannot interrupt request handling.
    ++$self->{counters}{$type};
    return unless $self->{on_diagnostic};
    my $ok = eval {
        $self->{on_diagnostic}->(
            {
                type => $type,
                %fields,
                pending => scalar( @{ $self->{jobs} } ),
                active => $self->{active}
            }
        );
        1;
    };
    warn "REST diagnostic handler failed\n" unless $ok;
}

sub stats {
    my ($self) = @_;
    return { %{ $self->{counters} }, pending => scalar( @{ $self->{jobs} } ), active => $self->{active} };
}

sub close {
    my ($self) = @_;

    # Stop admission and timers before failing queued requests and cancelling active I/O.
    $self->{stopped} = 1;
    if ( my $timer = delete $self->{timer} ) {
        $timer->cancel unless $timer->is_ready;
    }
    my @jobs = @{ $self->{jobs} };
    for my $job (@jobs) {
        my $transport_future = delete $job->{transport_future};
        $self->_finish( $job, 'REST client is closed', 'shutdown' );
        $transport_future->cancel if $transport_future && !$transport_future->is_ready;
    }
    $self->{routes} = {};
    $self->{buckets} = {};
    return $self->{loop}->new_future->done;
}

1;
