package Linux::Event::HTTP::_ClientConnect;
use v5.36;
use strict;
use warnings;

use Carp qw(croak);
use Scalar::Util qw(refaddr);

use Linux::Event::IO::Sock::Stream ();
use Linux::Event::Kernel::Timer;

our $VERSION = '0.002';

sub _load_target ($target) {
    croak 'request(): tunnel_to must be a package name'
        if !defined($target) || ref($target)
        || $target !~ /\A[A-Za-z_][A-Za-z0-9_]*(?:::[A-Za-z_][A-Za-z0-9_]*)*\z/;

    if (!$target->can('transition_to')) {
        (my $file = "$target.pm") =~ s{::}{/}g;
        require $file;
    }

    croak 'request(): tunnel_to class must inherit Linux::Event::IO::Sock::Stream'
        if !$target->isa('Linux::Event::IO::Sock::Stream');
    return $target;
}

sub _authority ($target) {
    croak 'request(): CONNECT target must be an authority-form host:port'
        if !defined($target) || ref($target);

    my ($host, $port);
    if ($target =~ /\A(\[[^\]\s]+\]):([0-9]+)\z/) {
        ($host, $port) = ($1, $2);
    } elsif ($target =~ /\A([^:\s\/?#@]+):([0-9]+)\z/) {
        ($host, $port) = ($1, $2);
    } else {
        croak 'request(): CONNECT target must be an authority-form host:port';
    }

    croak 'request(): CONNECT target port must be between 1 and 65535'
        if $port < 1 || $port > 65_535;
    return "$host:$port";
}

sub _trim ($value) {
    $value =~ s/\A[ \t]+//;
    $value =~ s/[ \t]+\z//;
    return $value;
}

sub prepare_request ($class, $request, $target, $request_state) {
    $target = _load_target($target);

    croak 'request(): tunnel_to requires CONNECT method'
        if uc($request->method) ne 'CONNECT';
    croak 'request(): CONNECT tunneling requires HTTP/1.1'
        if $request->version ne '1.1';
    croak 'request(): CONNECT does not support streaming Request bodies'
        if $request_state->{streaming};
    croak 'request(): CONNECT Request must not contain a scalar body'
        if $request->_has_scalar_body;

    my @length = $request->_header_values_list('Content-Length');
    croak 'request(): CONNECT Request must not contain Content-Length'
        if @length;
    my @transfer = $request->_header_values_list('Transfer-Encoding');
    croak 'request(): CONNECT Request must not contain Transfer-Encoding'
        if @transfer;

    my $authority = _authority($request->target);
    my @host = $request->_header_values_list('Host');
    croak 'request(): CONNECT requires exactly one Host field'
        if @host != 1;
    my $host = _trim("$host[0]");
    croak 'request(): CONNECT Host must match the authority-form request target'
        if lc($host) ne lc($authority);

    return $target;
}

sub schedule ($class, $conn, $transaction, $response, $target) {
    croak 'HTTP/1 CONNECT connection is closed'
        if $conn->is_closed;
    croak 'HTTP/1 CONNECT Transaction is already terminal'
        if $transaction->is_terminal;

    my $active = $conn->{_http_client_active_transaction};
    croak 'HTTP/1 CONNECT Transaction is not active on this connection'
        if !$active || refaddr($active) != refaddr($transaction);

    my $request = $transaction->request;
    croak 'HTTP/1 CONNECT handoff requires CONNECT method'
        if uc($request->method) ne 'CONNECT';
    my $request_state = $conn->{_http_client_request_state}
        or croak 'HTTP/1 CONNECT request state is unavailable';
    croak 'HTTP/1 CONNECT request output is not complete'
        if !$request_state->{complete};

    croak 'HTTP/1 CONNECT successful response must use HTTP/1.1'
        if $response->version ne '1.1';
    croak 'HTTP/1 CONNECT handoff requires a 2xx response'
        if $response->status < 200 || $response->status >= 300;

    $target = _load_target($target);
    croak "HTTP/1 CONNECT target $target is already the active connection class"
        if ref($conn) eq $target;

    $transaction->_set_response($response);
    $conn->_callback('on_response', $transaction, $response)
        if $conn->{_http_client_callbacks}{on_response};
    return $transaction if !$conn->_same_active_transaction($transaction);

    # RFC 9110/9112: a successful CONNECT response has no HTTP content and
    # Content-Length / Transfer-Encoding, if sent by a peer, are ignored.
    $response->_mark_complete;
    $conn->{_http_client_reusable} = 0;
    $conn->{_http_client_pending_connect} = {
        transaction => $transaction,
        response    => $response,
        target      => $target,
    };

    Linux::Event::Kernel::Timer->new(
        loop     => $conn->loop,
        after    => 0,
        data     => {
            connection  => $conn,
            transaction => $transaction,
            target      => $target,
        },
        on_timer => \&_handoff,
    );

    return $transaction;
}

sub _handoff ($timer) {
    my $timer_state = $timer->data;
    my $conn = $timer_state->{connection};
    my $transaction = $timer_state->{transaction};
    my $target = $timer_state->{target};

    return if !$conn || $conn->is_closed;
    return if !$transaction || $transaction->is_terminal;

    my $pending = $conn->{_http_client_pending_connect} or return;
    return if refaddr($pending->{transaction}) != refaddr($transaction);
    return if $pending->{target} ne $target;

    my $active = $conn->{_http_client_active_transaction};
    return if !$active || refaddr($active) != refaddr($transaction);

    my $callbacks = $conn->{_http_client_callbacks} || {};
    my $response = $pending->{response};
    my $input = $conn->{_http_client_input};

    $transaction->_mark_complete;
    $conn->{_http_client_input} = '';
    $conn->_clear_active_transaction;

    my $transitioned = eval {
        if (length($input)) {
            $conn->transition_to($target, input => $input);
        } else {
            $conn->transition_to($target);
        }
        1;
    };

    if (!$transitioned) {
        my $error = "$@";
        $error =~ s/\s+\z//;
        eval { $conn->close; 1 };
        $callbacks->{on_error}->(
            $transaction,
            "HTTP/1 CONNECT tunnel handoff failed: $error",
        ) if $callbacks->{on_error};
        return;
    }

    $callbacks->{on_tunnel}->($transaction, $response, $conn)
        if $callbacks->{on_tunnel};
    $callbacks->{on_complete}->($transaction)
        if $callbacks->{on_complete};
    return;
}

sub CLONE_SKIP ($class) { 1 }

1;
