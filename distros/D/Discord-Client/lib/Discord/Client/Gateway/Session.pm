package Discord::Client::Gateway::Session;

use v5.26;
use strict;
use warnings;
use Carp qw(croak);
use JSON::PP ();

use Discord::Client::Intents ();

our $VERSION = '0.002';

# Pure protocol decision logic: no sockets, event loop, timers, or callbacks.
# Each method returns a list reference of declarative actions for an IO driver.
# Deliberately internal and not a stable public API yet.

sub new {
    my ( $class, %args ) = @_;

    # Validate static session inputs before recording resumable state.
    croak 'token is required' if !defined( $args{token} ) || ref( $args{token} ) || $args{token} eq '';

    my $intents = $args{intents} // 0;
    if ( ref $intents eq 'ARRAY' ) {
        $intents = Discord::Client::Intents->bits(@$intents);
    }
    croak 'intents must be a nonnegative integer or arrayref of names'
        if ref($intents) || $intents !~ /\A\d+\z/;

    my $random = $args{random} // sub { rand() };
    croak 'random must be a coderef' if ref($random) ne 'CODE';
    my $shard = $args{shard};
    croak 'shard must contain a valid shard ID and total'
        if defined($shard)
        && (   ref($shard) ne 'ARRAY'
            || @$shard != 2
            || !_uint( $shard->[0] )
            || !_uint( $shard->[1] )
            || !$shard->[1]
            || $shard->[0] >= $shard->[1] );

    # A new session has neither a sequence nor a resumable connection identity.
    return bless {
        token => $args{token},
        intents => 0 + $intents,
        random => $random,
        shard => $shard ? [ map { 0 + $_ } @$shard ] : undef,
        state => 'disconnected',
        seq => undef,
        session_id => undef,
        resume_gateway_url => undef,
        heartbeat_interval_ms => undef,
        heartbeat_pending => 0,
    }, $class;
}

sub state { $_[0]->{state} }
sub sequence { $_[0]->{seq} }
sub session_id { $_[0]->{session_id} }
sub resume_gateway_url { $_[0]->{resume_gateway_url} }
sub heartbeat_interval_ms { $_[0]->{heartbeat_interval_ms} }
sub heartbeat_pending { $_[0]->{heartbeat_pending} }

sub can_resume {
    my ($self) = @_;

    # All three fields are required to resume the same Discord session.
    return
           defined( $self->{session_id} )
        && defined( $self->{seq} )
        && defined( $self->{resume_gateway_url} );
}

sub opened {
    my ($self) = @_;

    # A new socket awaits HELLO while retaining any resumable session identity.
    $self->{state} = 'awaiting_hello';
    $self->{heartbeat_pending} = 0;
    $self->{heartbeat_interval_ms} = undef;
    return [];
}

sub receive {
    my ( $self, $packet ) = @_;

    # Reject malformed envelopes before switching on the protocol opcode.
    croak 'gateway packet must be a hashref' if ref $packet ne 'HASH';
    my $op = $packet->{op};
    croak 'gateway packet opcode missing or invalid'
        if !defined($op) || ref($op) || $op !~ /\A\d+\z/;

    return $self->_receive_hello( $packet->{d} ) if $op == 10;

    if ( $op == 11 ) {    # HEARTBEAT ACK
        $self->{heartbeat_pending} = 0;
        return [];
    }

    if ( $op == 1 ) {    # Discord requests an immediate heartbeat
        croak 'HEARTBEAT received outside a session'
            unless $self->{state} eq 'authenticating' || $self->{state} eq 'ready';
        return [ $self->_heartbeat_action ];
    }

    return $self->_receive_dispatch($packet) if $op == 0;

    if ( $op == 7 ) {    # RECONNECT
        $self->{state} = 'disconnected';
        $self->{heartbeat_pending} = 0;
        return [ $self->_reconnect_action(0) ];
    }

    if ( $op == 9 ) {    # INVALID SESSION
        croak 'INVALID_SESSION requires a boolean'
            unless JSON::PP::is_bool( $packet->{d} )
            || ( defined( $packet->{d} ) && !ref( $packet->{d} ) && $packet->{d} =~ /\A[01]\z/ );
        my $resumable = $packet->{d} && $self->can_resume;
        $self->_forget_session unless $resumable;
        $self->{state} = 'disconnected';
        $self->{heartbeat_pending} = 0;

        # Discord requires a randomized delay before attempting a new session.
        return [ $self->_reconnect_action( 1000 + int( 4000 * $self->_random ) ) ];
    }

    # Preserve compatibility with future Gateway opcodes; consumer may inspect.
    return [ { action => 'opcode', op => 0 + $op, data => $packet->{d} } ];
}

sub _receive_hello {
    my ( $self, $data ) = @_;

    # Validate HELLO before committing the heartbeat schedule and authentication state.
    croak 'HELLO received outside handshake' if $self->{state} ne 'awaiting_hello';
    croak 'HELLO payload must be a hashref' if ref($data) ne 'HASH';
    my $interval = $data->{heartbeat_interval};
    croak 'invalid heartbeat interval'
        if !defined($interval) || ref($interval) || $interval !~ /\A\d+\z/ || $interval <= 0;

    # Jitter the first heartbeat, then choose Resume or Identify from saved state.
    my $first = int( $interval * $self->_random );
    $self->{heartbeat_interval_ms} = 0 + $interval;
    $self->{state} = 'authenticating';
    my $auth = $self->can_resume ? $self->_resume : $self->_identify;
    return [
        { action => 'heartbeat_schedule', first_delay_ms => $first, interval_ms => 0 + $interval },
        { action => 'send', payload => $auth },
    ];
}

sub _receive_dispatch {
    my ( $self, $packet ) = @_;

    # Validate dispatch data before updating the sequence used by heartbeats and Resume.
    croak 'DISPATCH received outside a session'
        unless $self->{state} eq 'authenticating' || $self->{state} eq 'ready';
    croak 'DISPATCH missing event name'
        if !defined( $packet->{t} ) || ref( $packet->{t} ) || !length( $packet->{t} );
    croak 'DISPATCH sequence is invalid' unless _uint( $packet->{s} );
    my $event = $packet->{t};
    my $data = $packet->{d};
    if ( $event eq 'READY' ) {
        croak 'READY requires session_id and resume_gateway_url'
            if ref($data) ne 'HASH'
            || !defined( $data->{session_id} )
            || ref( $data->{session_id} )
            || !length( $data->{session_id} )
            || !defined( $data->{resume_gateway_url} )
            || ref( $data->{resume_gateway_url} )
            || $data->{resume_gateway_url} !~ m{\Awss://[^\s]+\z};
        $self->{session_id} = $data->{session_id};
        $self->{resume_gateway_url} = $data->{resume_gateway_url};
        $self->{state} = 'ready';
    }
    elsif ( $event eq 'RESUMED' ) {
        $self->{state} = 'ready';
    }

    # Publish the new sequence only after validating session-establishing events.
    $self->{seq} = $packet->{s};
    return [ { action => 'event', name => $event, data => $data } ];
}

sub heartbeat_due {
    my ($self) = @_;
    return []
        if !defined( $self->{heartbeat_interval_ms} )
        || $self->{state} eq 'disconnected'
        || $self->{state} eq 'stopped';

    # Do not send another scheduled heartbeat to a connection that failed to acknowledge.
    if ( $self->{heartbeat_pending} ) {
        $self->{state} = 'disconnected';
        $self->{heartbeat_pending} = 0;
        return [ $self->_reconnect_action(0) ];
    }
    return [ $self->_heartbeat_action ];
}

sub closed {
    my ( $self, $code ) = @_;
    $code = 0 unless defined $code;
    $self->{heartbeat_pending} = 0;
    $self->{heartbeat_interval_ms} = undef;
    return [] if $self->{state} eq 'stopped';

    # Authentication and configuration rejections cannot be repaired by reconnecting.
    if ( $code =~ /\A(?:4004|4010|4011|4012|4013|4014)\z/ ) {
        $self->_forget_session;
        $self->{state} = 'stopped';
        return [ { action => 'fatal', close_code => 0 + $code } ];
    }

    # Only normal closure and invalid session/sequence codes discard resumable state.
    $self->_forget_session if $code =~ /\A(?:1000|1001|4007|4009)\z/;
    $self->{state} = 'disconnected';
    return [ $self->_reconnect_action(0) ];
}

sub stop {
    my ($self) = @_;

    # An explicit stop invalidates both heartbeat state and resumable identity.
    $self->_forget_session;
    $self->{heartbeat_interval_ms} = undef;
    $self->{heartbeat_pending} = 0;
    $self->{state} = 'stopped';
    return [];
}

sub _identify {
    my ($self) = @_;

    # Build only protocol data; the transport decides when an Identify may be sent.
    return {
        op => 2,
        d => {
            token => $self->{token},
            intents => $self->{intents},
            ( $self->{shard} ? ( shard => [ @{ $self->{shard} } ] ) : () ),
            properties => {
                os => $^O,
                browser => 'Discord-Client',
                device => 'Discord-Client',
            },
        },
    };
}

sub _resume {
    my ($self) = @_;

    # Resume the saved session at its last validated dispatch sequence.
    return {
        op => 6,
        d => {
            token => $self->{token},
            session_id => $self->{session_id},
            seq => $self->{seq},
        },
    };
}

sub _heartbeat_action {
    my ($self) = @_;
    $self->{heartbeat_pending} = 1;
    return { action => 'send', payload => { op => 1, d => $self->{seq} } };
}

sub _forget_session {
    my ($self) = @_;

    # Discard the whole resume identity so a later socket must Identify again.
    $self->{session_id} = undef;
    $self->{resume_gateway_url} = undef;
    $self->{seq} = undef;
}

sub _reconnect_action {
    my ( $self, $delay_ms ) = @_;
    return {
        action => 'reconnect',
        resume => $self->can_resume ? 1 : 0,
        delay_ms => $delay_ms,
    };
}

sub _random {
    my ($self) = @_;

    # Injected randomness must obey the same bounds as rand before it affects timing.
    my $value = $self->{random}->();
    croak 'random generator must return a number in [0, 1)'
        if !defined($value)
        || ref($value)
        || $value !~ /\A(?:\d+(?:\.\d*)?|\.\d+)\z/
        || $value < 0
        || $value >= 1;
    return $value;
}

sub _uint { defined( $_[0] ) && !ref( $_[0] ) && $_[0] =~ /\A\d+\z/ }

1;

__END__

=head1 NAME

Discord::Client::Gateway::Session - Pure Gateway session state engine

=head1 DESCRIPTION

Internal state engine used by the IO::Async Gateway driver. It consumes
already decoded Gateway packets and produces declarative actions. It does not
manage WebSockets, timers, reconnect backoff, identify concurrency, or REST.

Its API is internal and subject to change. Never log an entire C<send> action
because Identify/Resume payloads contain a bot token.

=cut
