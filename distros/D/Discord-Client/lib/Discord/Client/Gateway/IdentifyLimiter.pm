package Discord::Client::Gateway::IdentifyLimiter;

use v5.26;
use strict;
use warnings;
use Carp qw(croak);
use Scalar::Util qw(blessed);
use Time::HiRes qw(clock_gettime CLOCK_MONOTONIC);
use Discord::Client::Error;

our $VERSION = '0.002';

sub new {
    my ( $class, %args ) = @_;

    # One scheduler shares metadata, pending permits and concurrency buckets.
    croak 'loop and REST client are required' unless $args{loop} && $args{rest};
    return bless {
        loop => $args{loop},
        rest => $args{rest},
        clock => $args{clock} // sub { clock_gettime(CLOCK_MONOTONIC) },
        delay => $args{delay} // sub { $args{loop}->delay_future( after => $_[0] ) },
        max_pending => $args{max_pending} // 1024,
        waiters => [],
        bucket_until => {},
    }, $class;
}

sub _fail {
    my ( $self, $future, $message, $category ) = @_;
    my $error = Discord::Client::Error->new( message => $message, category => $category );
    return $future->fail( $message, $category, $error );
}

sub info {
    my ($self) = @_;

    # Serve cached metadata or join the current discovery request.
    my $future = $self->{loop}->new_future;
    return $self->_fail( $future, 'Identify limiter is closed', 'shutdown' ) if $self->{closed};
    return $future->done( $self->{info} ) if $self->{info};
    my $load = $self->_load;
    $load->on_ready(
        sub {
            return if $future->is_ready;
            if ( $load->is_done ) {
                $future->done( $self->{info} );
            }
            elsif ( $load->is_failed ) {
                $future->fail( $load->failure );
            }
            else {
                $self->_fail( $future, 'Gateway discovery cancelled', 'transport' );
            }
        }
    );
    return $future;
}

sub _load {
    my ($self) = @_;

    # Coalesce discovery so concurrent callers cannot reset the budget separately.
    return $self->{load} if $self->{load};
    my $result = $self->{loop}->new_future;
    $self->{load} = $result;
    my $http = eval { $self->{rest}->request( 'GET', '/gateway/bot' ) };
    unless ( blessed($http) && $http->isa('Future') ) {
        delete $self->{load};
        return $self->_fail( $result, 'Gateway discovery transport failed', 'transport' );
    }
    $self->{http} = $http;
    $http->on_ready(
        sub {
            # Clear discovery ownership before notifying callbacks that may re-enter.
            delete @{$self}{qw(http load)};
            return if $result->is_ready;
            $self->_complete_discovery( $result, $http );

            if ( $result->is_failed ) {

                # Fail queued requests together when no usable budget can be discovered.
                my @waiters = @{ $self->{waiters} };
                $self->{waiters} = [];
                $_->{future}->fail( $result->failure )
                    for grep { !$_->{future}->is_ready } @waiters;
            }
            $self->_pump;
        }
    );
    return $result;
}

sub _complete_discovery {
    my ( $self, $result, $http ) = @_;

    # Settle terminal failures before inspecting or installing any metadata.
    return $self->_fail( $result, 'Identify limiter is closed', 'shutdown' ) if $self->{closed};
    return $result->fail( $http->failure ) if $http->is_failed;
    return $self->_fail( $result, 'Gateway discovery cancelled', 'transport' ) if $http->is_cancelled;

    my ($info) = $http->result;
    return $self->_fail( $result, 'Invalid Gateway Bot metadata', 'protocol' )
        unless $self->_valid_info($info);

    # Install the validated budget before notifying callers that may request permits.
    # Zero reset_after supplies no future reset time.
    my $limit = $info->{session_start_limit};
    $self->{info} = $info;
    $self->{remaining} = $limit->{remaining};
    $self->{reset_at} =
          $limit->{reset_after} > 0
        ? $self->{clock}->() + $limit->{reset_after} / 1000
        : undef;
    $self->{max_concurrency} = $limit->{max_concurrency};
    return $result->done($info);
}

sub _valid_info {
    my ( $self, $info ) = @_;

    # Reject malformed fields before they become scheduling state.
    return 0
        unless ref($info) eq 'HASH'
        && defined( $info->{url} )
        && !ref( $info->{url} )
        && $info->{url} =~ m{\Awss://[^\s]+\z}
        && ref( $info->{session_start_limit} ) eq 'HASH';
    my $limits = $info->{session_start_limit};
    for my $field (qw(total remaining reset_after max_concurrency)) {
        return 0
            unless defined( $limits->{$field} )
            && !ref( $limits->{$field} )
            && $limits->{$field} =~ /\A\d+\z/;
    }
    return
           $limits->{total} > 0
        && $limits->{max_concurrency} > 0
        && $limits->{remaining} <= $limits->{total};
}

sub acquire {
    my ( $self, $shard_id ) = @_;

    # Validate and bound requests before adding a waiter to the shared queue.
    my $future = $self->{loop}->new_future;
    return $self->_fail( $future, 'Identify limiter is closed', 'shutdown' ) if $self->{closed};
    return $self->_fail( $future, 'Invalid shard ID', 'request' )
        unless defined($shard_id) && !ref($shard_id) && $shard_id =~ /\A\d+\z/;
    return $self->_fail( $future, 'Identify queue capacity exceeded', 'queue_full' )
        if @{ $self->{waiters} } >= $self->{max_pending};
    my $job = { shard => $shard_id, future => $future };
    push @{ $self->{waiters} }, $job;

    # Cancellation removes an ungranted request and recomputes queue timing.
    $future->on_cancel(
        sub {
            @{ $self->{waiters} } = grep { $_ != $job } @{ $self->{waiters} };
            $self->_pump;
        }
    );
    $self->_pump;
    return $future;
}

sub _pump {
    my ($self) = @_;
    return if $self->{closed} || $self->{pumping};
    local $self->{pumping} = 1;

    # Recompute wake-up timing whenever the queue or server budget changes.
    if ( my $timer = delete $self->{timer} ) {
        $timer->cancel unless $timer->is_ready;
    }
    return unless @{ $self->{waiters} };

    # Expired metadata must be refreshed before another Identify can be granted.
    delete $self->{info}
        if $self->{info}
        && defined( $self->{reset_at} )
        && $self->{clock}->() >= $self->{reset_at};
    if ( !$self->{info} ) {
        my $load = $self->_load;
        if ( $load->is_failed ) {
            my @jobs = @{ $self->{waiters} };
            $self->{waiters} = [];
            $_->{future}->fail( $load->failure ) for grep { !$_->{future}->is_ready } @jobs;
        }
        return unless $self->{info};
    }
    my $now = $self->{clock}->();
    my $next_attempt_at;

    # Reserve each free concurrency bucket and consume one start per permit.
    while ( $self->{remaining} > 0 ) {
        my $job;
        $next_attempt_at = undef;
        for my $candidate ( @{ $self->{waiters} } ) {
            my $bucket = $candidate->{shard} % $self->{max_concurrency};
            next if $self->{reserved}{$bucket};
            my $available_at = $self->{bucket_until}{$bucket} // 0;
            if ( $available_at > $now ) {
                $next_attempt_at = $available_at
                    if !defined($next_attempt_at) || $available_at < $next_attempt_at;
                next;
            }
            $job = $candidate;
            $self->{reserved}{$bucket} = 1;
            $job->{key} = $bucket;
            last;
        }
        last unless $job;
        @{ $self->{waiters} } = grep { $_ != $job } @{ $self->{waiters} };
        --$self->{remaining};
        $job->{future}->done( bless { limiter => $self, key => $job->{key} },
            'Discord::Client::Gateway::IdentifyLimiter::Permit' );
        last if $self->{closed};
    }
    return if $self->{closed} || !@{ $self->{waiters} };

    # A zero reset delay supplies no future reset time. Poll an exhausted
    # budget conservatively rather than scheduling a busy loop.
    if ( $self->{remaining} <= 0 ) {
        $self->{reset_at} //= $now + 1;
        $next_attempt_at = $self->{reset_at};
    }
    return unless defined $next_attempt_at;

    # Refresh metadata before the next bucket wake-up if its reset is earlier.
    $next_attempt_at = $self->{reset_at}
        if defined( $self->{reset_at} ) && $next_attempt_at > $self->{reset_at};
    my $timer = $self->{delay}->( $next_attempt_at - $self->{clock}->() );
    $self->{timer} = $timer;
    $timer->on_done(
        sub {
            delete $self->{timer};
            $self->_pump;
        }
    );
}

sub stats {
    my ($self) = @_;
    return {
        remaining => $self->{remaining},
        max_concurrency => $self->{max_concurrency},
        pending => scalar( @{ $self->{waiters} } )
    };
}

sub close {
    my ($self) = @_;

    # Release timers and pending work without closing the caller-owned REST client.
    $self->{closed} = 1;
    if ( my $timer = delete $self->{timer} ) {
        $timer->cancel unless $timer->is_ready;
    }
    if ( my $http = delete $self->{http} ) {
        $http->cancel unless $http->is_ready;
    }
    my @jobs = @{ $self->{waiters} };
    $self->{waiters} = [];
    $self->_fail( $_->{future}, 'Identify limiter is closed', 'shutdown' )
        for grep { !$_->{future}->is_ready } @jobs;
    return $self->{loop}->new_future->done;
}

package Discord::Client::Gateway::IdentifyLimiter::Permit;

sub commit {
    my ($self) = @_;

    # Sends commit just before writing. Unused permits also commit on release
    # so abandoning a reservation cannot bypass the shared bucket cooldown.
    return if $self->{committed};
    $self->{committed} = 1;
    my $limiter = $self->{limiter};
    delete $limiter->{reserved}{ $self->{key} };
    $limiter->{bucket_until}{ $self->{key} } = $limiter->{clock}->() + 5;
    $limiter->_pump;
}

sub cancel { $_[0]->commit }
sub DESTROY { $_[0]->cancel unless $_[0]->{committed} }

1;
