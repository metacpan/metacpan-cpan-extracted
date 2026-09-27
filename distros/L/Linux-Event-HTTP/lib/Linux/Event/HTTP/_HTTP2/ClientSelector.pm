package Linux::Event::HTTP::_HTTP2::ClientSelector;
use v5.36;
use strict;
use warnings;

use Carp qw(croak);
use Scalar::Util qw(blessed refaddr weaken);

use Linux::Event::HTTP::Transaction;

our $VERSION = '0.003';

my $BODY_HIGH_WATER = 65_536;

sub new ($class, %option) {
    my $loop = delete $option{loop};
    my $host = delete $option{host};
    my $port = delete $option{port};
    my $transport = delete $option{transport};
    my $timeout = delete $option{timeout};
    my $scheme = delete($option{scheme}) // 'https';
    my $authority = delete $option{authority};
    my $on_selected = delete $option{on_selected};
    my $http1_connection_factory =
        delete $option{http1_connection_factory};
    my $max_header_list_size =
        delete($option{max_header_list_size}) // 65_536;
    my $max_buffered_response_bytes =
        delete($option{max_buffered_response_bytes}) // 67_108_864;

    croak 'new(): loop is required' if !blessed($loop);
    croak 'new(): host is required'
        if !defined($host) || ref($host) || $host eq '';
    croak 'new(): port is required'
        if !defined($port) || ref($port);
    croak 'new(): transport is required' if !blessed($transport);
    croak 'new(): authority is required'
        if !defined($authority) || ref($authority) || $authority eq '';
    croak 'new(): on_selected must be a coderef'
        if defined($on_selected) && ref($on_selected) ne 'CODE';
    croak 'new(): http1_connection_factory must be a coderef'
        if defined($http1_connection_factory)
        && ref($http1_connection_factory) ne 'CODE';
    croak 'new(): max_header_list_size must be a positive integer'
        if ref($max_header_list_size)
        || "$max_header_list_size" !~ /\A[0-9]+\z/
        || $max_header_list_size < 1;
    croak 'new(): max_buffered_response_bytes must be a positive integer'
        if ref($max_buffered_response_bytes)
        || "$max_buffered_response_bytes" !~ /\A[0-9]+\z/
        || $max_buffered_response_bytes < 1;
    croak 'new(): unknown options: ' . join(', ', sort keys %option)
        if %option;

    require Linux::Event::HTTP::_HTTP2::ClientSelectorConnection;
    require Linux::Event::HTTP::_HTTP2::Client;
    require Linux::Event::HTTP::_HTTP2::ClientConnection;

    my $self = bless {
        protocol    => 'negotiating',
        scheme      => "$scheme",
        authority   => "$authority",
        stream      => undef,
        executor    => undef,
        transaction => undef,
        pending     => [],
        pending_by_tx => {},
        closed      => 0,
        on_selected => $on_selected,
        http1_connection_factory => $http1_connection_factory,
        max_header_list_size => 0 + $max_header_list_size,
        max_buffered_response_bytes => 0 + $max_buffered_response_bytes,
    }, $class;

    my %connect = (
        loop      => $loop,
        host      => $host,
        port      => $port,
        transport => $transport,
    );
    $connect{timeout} = $timeout if defined $timeout;

    my $stream = Linux::Event::HTTP::_HTTP2::ClientSelectorConnection
        ->connect(%connect);
    $stream->{_http2_selector} = $self;
    weaken($stream->{_http2_selector});
    $self->{stream} = $stream;

    return $self;
}

sub stream ($self) { $self->{stream} }

sub is_closed ($self) {
    return 1 if $self->{closed};
    return !$self->{stream} || $self->{stream}->is_closed ? 1 : 0;
}

sub protocol ($self) { $self->{protocol} }

sub _http2_capable ($self) { 1 }

sub can_accept_transaction ($self) {
    return 0 if $self->is_closed;
    return 0 if $self->{protocol} ne 'h2';
    my $executor = $self->{executor} or return 0;
    return $executor->can_accept_transaction;
}

sub active_streams ($self) {
    return 0 if $self->{protocol} ne 'h2' || !$self->{executor};
    return $self->{executor}->stream_count;
}

sub can_queue_transaction ($self) {
    return 0 if $self->is_closed;
    return 0 if $self->{protocol} ne 'negotiating'
        && $self->{protocol} ne 'selecting-h2';
    return @{$self->{pending}} < 100 ? 1 : 0;
}

sub _notify_selected ($self) {
    my $callback = $self->{on_selected} or return;
    $callback->($self, $self->{protocol});
    return;
}

sub transaction ($self) {
    if ($self->{protocol} eq 'negotiating'
        || $self->{protocol} eq 'selecting-h2') {
        for my $pending (@{$self->{pending}}) {
            my $tx = $pending->{transaction};
            return $tx if $tx && !$tx->is_terminal;
        }
        return undef;
    }

    my $tx = $self->{transaction} or return undef;
    return undef if $tx->is_terminal;
    return $tx;
}

sub request ($self, $request, %option) {
    croak 'request(): selector is closed' if $self->is_closed;
    croak 'request(): requires a Linux::Event::HTTP::Request'
        if !blessed($request)
        || !$request->isa('Linux::Event::HTTP::Request');

    my $http1_reassign = delete $option{_http1_reassign};
    croak 'request(): _http1_reassign must be a coderef'
        if defined($http1_reassign) && ref($http1_reassign) ne 'CODE';

    if ($self->{protocol} eq 'http/1.1') {
        my $tx = $self->{stream}->request($request, %option);
        $self->{transaction} = $tx;
        return $tx;
    }

    if ($self->{protocol} eq 'h2') {
        $self->_prepare_h2_request($request);
        my $tx = $self->{executor}->request($request, %option);
        $self->{transaction} = $tx;
        return $tx;
    }

    croak 'request(): selector cannot queue another Transaction'
        if !$self->can_queue_transaction;

    croak 'request(): HTTP/1 Upgrade cannot be negotiated through an HTTP/2-capable selector'
        if exists $option{upgrade_to};
    croak 'request(): CONNECT tunnel handoff cannot be negotiated through an HTTP/2-capable selector'
        if exists $option{tunnel_to};

    my $stream_body;
    if (exists $option{stream_body}) {
        $stream_body = $option{stream_body};
        croak 'request(): stream_body must be a hash reference'
            if ref($stream_body) ne 'HASH';
        $stream_body = { %$stream_body };
        $option{stream_body} = $stream_body;
    }

    my $tx = Linux::Event::HTTP::Transaction->_new(
        request    => $request,
        controller => $self,
    );
    $tx->_activate;

    my $pending_body;
    if ($stream_body) {
        $request->_begin_stream_body;
        $tx->request_body(%$stream_body);
        $pending_body = {
            queue    => '',
            expected => $request->content_length,
            sent     => 0,
            eof      => 0,
        };
    }

    my $pending = {
        request        => $request,
        transaction    => $tx,
        option         => { %option },
        body           => $pending_body,
        http1_reassign => $http1_reassign,
    };
    push @{$self->{pending}}, $pending;
    $self->{pending_by_tx}{refaddr($tx)} = $pending;
    return $tx;
}

sub _prepare_h2_request ($self, $request) {
    croak 'HTTP/2 selector cannot change a committed Request'
        if !$request->is_mutable;

    my $host = $request->header_values('Host');
    croak 'HTTP/2 selector requires at most one Host field'
        if @$host > 1;
    my $authority = @$host ? $host->[0] : $self->{authority};

    $request->version('2') if ($request->version // '') ne '2';
    $request->scheme($self->{scheme});
    $request->authority($authority);
    $request->remove_header('Host');
    return;
}

sub _transport_ready ($self, $stream) {
    return if $self->{closed};

    my $alpn = $stream->selected_alpn // '';
    if ($alpn eq 'http/1.1') {
        $self->{protocol} = 'http/1.1';
        $self->_notify_selected;
        $self->_submit_pending_http1;
        return;
    }

    if ($alpn ne 'h2') {
        $self->_fail_pending(
            "TLS selected unsupported HTTP ALPN '$alpn'",
        );
        $stream->close if !$stream->is_closed;
        return;
    }

    $self->{protocol} = 'selecting-h2';
    $stream->pause_read;
    $stream->loop->defer(sub {
        return if $self->{closed} || $stream->is_closed;

        my $executor = Linux::Event::HTTP::_HTTP2::Client->new(
            stream    => $stream,
            autostart => 0,
            max_header_list_size => $self->{max_header_list_size},
            max_buffered_response_bytes =>
                $self->{max_buffered_response_bytes},
        );
        $self->{executor} = $executor;
        $stream->{_http2_executor} = $executor;

        $stream->transition_to(
            'Linux::Event::HTTP::_HTTP2::ClientConnection',
        );
        $executor->start;
        $self->{protocol} = 'h2';
        $self->_notify_selected;

        $self->_submit_pending_h2;
        $stream->resume_read if $stream->is_read_paused;
    });
    return;
}

sub _remove_pending ($self, $pending) {
    my $tx = $pending->{transaction};
    delete $self->{pending_by_tx}{refaddr($tx)};
    @{$self->{pending}} = grep {
        refaddr($_->{transaction}) != refaddr($tx)
    } @{$self->{pending}};
    return;
}

sub _submit_pending_http1_on ($self, $connection, $pending, $reassign = 0) {
    my $tx = $pending->{transaction};
    return 1 if $tx->is_terminal;

    if ($reassign && $pending->{http1_reassign}) {
        $pending->{http1_reassign}->($connection);
    }

    $connection->request(
        $pending->{request},
        %{$pending->{option}},
        _transaction => $tx,
    );
    $self->_transfer_pending_body($connection, $pending);
    $self->_remove_pending($pending);
    return 1;
}

sub _submit_pending_http1 ($self) {
    my @pending = @{$self->{pending}};
    return if !@pending;

    my $leader_used = 0;
    for my $pending (@pending) {
        my $tx = $pending->{transaction};
        if ($tx->is_terminal) {
            $self->_remove_pending($pending);
            next;
        }

        my $connection;
        my $reassign = 0;
        if (!$leader_used) {
            $connection = $self->{stream};
            $leader_used = 1;
            $self->{transaction} = $tx;
        } else {
            my $factory = $self->{http1_connection_factory};
            if (!$factory) {
                $self->_fail_one_pending(
                    $pending,
                    'HTTP/1.1 fallback requires another connection',
                );
                next;
            }
            $connection = eval { $factory->($self) };
            if (!$connection || $@) {
                my $error = "$@";
                $error =~ s/\s+\z//;
                $error ||= 'HTTP/1.1 fallback connection creation failed';
                $self->_fail_one_pending($pending, $error);
                next;
            }
            $reassign = 1;
        }

        my $ok = eval {
            $self->_submit_pending_http1_on(
                $connection, $pending, $reassign,
            );
            1;
        };
        if (!$ok) {
            $self->_fail_one_pending($pending, "$@");
            $connection->close
                if $reassign && $connection && !$connection->is_closed;
        }
    }
    return;
}

sub _submit_pending_h2 ($self) {
    my @pending = @{$self->{pending}};
    for my $pending (@pending) {
        my $tx = $pending->{transaction};
        if ($tx->is_terminal) {
            $self->_remove_pending($pending);
            next;
        }

        my $ok = eval {
            $self->_prepare_h2_request($pending->{request});
            $self->{executor}->request(
                $pending->{request},
                %{$pending->{option}},
                _transaction => $tx,
            );
            $self->_transfer_pending_body(
                $self->{executor}, $pending,
            );
            $self->_remove_pending($pending);
            1;
        };
        $self->_fail_one_pending($pending, "$@") if !$ok;
    }
    return;
}

sub _fail_one_pending ($self, $pending, $error) {
    $error = 'HTTP connection failed during protocol selection'
        if !defined($error) || $error eq '';
    $error =~ s/\s+\z//;

    $self->_remove_pending($pending);
    my $tx = $pending->{transaction};
    $tx->_fail($error) if !$tx->is_terminal;

    my $callback = $pending->{option}{on_error};
    $callback->($tx, $error) if $callback && $tx;
    return;
}

sub _fail_pending ($self, $error) {
    my @pending = @{$self->{pending}};
    $self->_fail_one_pending($_, $error) for @pending;
    return;
}

sub _transport_error ($self, $error) {
    return if $self->{protocol} ne 'negotiating'
        && $self->{protocol} ne 'selecting-h2';
    $self->_fail_pending($error);
    return;
}

sub end ($self) {
    my $stream = $self->{stream} or return $self;
    $stream->end if !$stream->is_closed;
    return $self;
}

sub close ($self) {
    return $self if $self->{closed};
    $self->{closed} = 1;

    my @pending = @{$self->{pending}};
    $self->_fail_one_pending(
        $_, 'HTTP connection closed before protocol selection',
    ) for @pending;

    if (my $stream = $self->{stream}) {
        $stream->close if !$stream->is_closed;
    }
    return $self;
}

sub _cancel_http_transaction ($self, $tx) {
    my $pending = $self->{pending_by_tx}{refaddr($tx)}
        or croak 'cancel(): Transaction is not pending on this HTTP selector';

    $self->_remove_pending($pending);
    $tx->_mark_cancelled if !$tx->is_terminal;
    return;
}

sub _write_http_request_body ($self, $tx, $bytes, $final, $operation) {
    my $pending = $self->{pending_by_tx}{refaddr($tx)}
        or croak "$operation(): Request is no longer pending protocol selection";

    my $state = $pending->{body}
        or croak "$operation(): Request does not have a streaming body";
    croak "$operation(): body must be a scalar" if ref $bytes;
    $bytes = '' if !defined $bytes;
    croak "$operation(): streaming Request body is already complete"
        if $state->{eof};

    my $new_sent = $state->{sent} + length($bytes);
    if (defined($state->{expected}) && $new_sent > $state->{expected}) {
        croak "$operation(): Request body exceeds Content-Length";
    }
    if ($final && defined($state->{expected})
        && $new_sent != $state->{expected}) {
        croak "$operation(): Request body length does not match Content-Length";
    }

    $state->{queue} .= $bytes;
    $state->{sent} = $new_sent;
    $state->{eof} = 1 if $final;

    return length($state->{queue}) >= $BODY_HIGH_WATER ? 0 : 1;
}

sub _transfer_pending_body ($self, $controller, $pending) {
    my $state = $pending->{body} or return;
    my $tx = $pending->{transaction};
    my $body = $tx->_request_body_object
        or croak 'streaming Request lost its Body::Stream producer';

    my $bytes = $state->{queue};
    my $final = $state->{eof} ? 1 : 0;
    return if !length($bytes) && !$final;

    my $accepted = $controller->_write_http_request_body(
        $tx,
        $bytes,
        $final,
        $final ? 'request_body->complete' : 'request_body->write',
    );

    if (!$body->is_complete) {
        if ($accepted) {
            $body->_drain;
        } else {
            $body->_block;
        }
    }

    $state->{queue} = '';
    return;
}

sub _write_http_response_body ($self, $tx, $bytes, $final, $operation) {
    croak "$operation(): client selector cannot write a Response body";
}

sub _upgrade_http_transaction ($self, $tx, $target_class) {
    croak 'upgrade(): unavailable while HTTP protocol selection is pending';
}

sub _tunnel_http_transaction ($self, $tx, $target_class) {
    croak 'tunnel(): unavailable while HTTP protocol selection is pending';
}

1;

__END__

=head1 NAME

Linux::Event::HTTP::_HTTP2::ClientSelector - private HTTPS ALPN selector

=head1 DESCRIPTION

This private object preserves the high-level Client's synchronous Transaction
identity while delaying wire submission until TLS ALPN selects HTTP/1.1 or
HTTP/2.

=cut
