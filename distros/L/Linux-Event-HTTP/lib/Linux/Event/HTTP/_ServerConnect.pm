package Linux::Event::HTTP::_ServerConnect;
use v5.36;
use strict;
use warnings;

use Carp qw(croak);
use Scalar::Util qw(refaddr);

use Linux::Event::IO::Sock::Stream ();

our $VERSION = '0.003';

sub _load_target ($target) {
    croak 'tunnel(): target class must be a package name'
        if !defined($target) || ref($target)
        || $target !~ /\A[A-Za-z_][A-Za-z0-9_]*(?:::[A-Za-z_][A-Za-z0-9_]*)*\z/;

    if (!$target->can('transition_to')) {
        (my $file = "$target.pm") =~ s{::}{/}g;
        require $file;
    }

    croak 'tunnel(): target class must inherit Linux::Event::IO::Sock::Stream'
        if !$target->isa('Linux::Event::IO::Sock::Stream');
    return $target;
}

sub _authority ($target) {
    croak 'tunnel(): CONNECT target must be an authority-form host:port'
        if !defined($target) || ref($target);

    my ($host, $port);
    if ($target =~ /\A(\[[^\]\s]+\]):([0-9]+)\z/) {
        ($host, $port) = ($1, $2);
    } elsif ($target =~ /\A([^:\s\/?#@]+):([0-9]+)\z/) {
        ($host, $port) = ($1, $2);
    } else {
        croak 'tunnel(): CONNECT target must be an authority-form host:port';
    }

    croak 'tunnel(): CONNECT target port must be between 1 and 65535'
        if $port < 1 || $port > 65_535;
    return "$host:$port";
}

sub _trim ($value) {
    $value =~ s/\A[ \t]+//;
    $value =~ s/[ \t]+\z//;
    return $value;
}

sub _connection_has ($values, $wanted) {
    for my $value (@$values) {
        for my $member (split /,/, $value, -1) {
            $member = _trim($member);
            return 1 if lc($member) eq $wanted;
        }
    }
    return 0;
}

sub schedule ($class, $conn, $transaction, $target) {
    croak 'tunnel(): connection is closing or closed'
        if $conn->{_http_closing} || $conn->is_closed;
    croak 'tunnel(): Transaction is already terminal'
        if $transaction->is_terminal;
    croak 'tunnel(): response output has already started'
        if $transaction->is_response_started;
    croak 'tunnel(): Transaction already has a protocol handoff pending'
        if $transaction->is_upgrading || $transaction->is_tunneling;

    my $active = $conn->{_http_active_transaction};
    croak 'tunnel(): Transaction is not active on this HTTP connection'
        if !$active || refaddr($active) != refaddr($transaction);

    my $request = $transaction->request
        or croak 'tunnel(): active Request is missing';
    my $response = $transaction->response
        or croak 'tunnel(): active Response is missing';

    croak 'tunnel(): CONNECT requires HTTP/1.1'
        if $request->version ne '1.1';
    croak 'tunnel(): requires a CONNECT Request'
        if uc($request->method) ne 'CONNECT';

    my $authority = _authority($request->target);
    my @host = $request->_header_values_list('Host');
    croak 'tunnel(): CONNECT requires exactly one Host field'
        if @host != 1;
    croak 'tunnel(): CONNECT Host must match the authority-form request target'
        if lc(_trim("$host[0]")) ne lc($authority);

    my @request_length = $request->_header_values_list('Content-Length');
    my @request_transfer = $request->_header_values_list('Transfer-Encoding');
    croak 'tunnel(): CONNECT Request must not contain Content-Length'
        if @request_length;
    croak 'tunnel(): CONNECT Request must not contain Transfer-Encoding'
        if @request_transfer;
    croak 'tunnel(): CONNECT Request must not contain a message body'
        if $request->_http1_body_mode ne 'none';

    croak 'tunnel(): response message has already been committed'
        if $response->_is_committed;
    croak 'tunnel(): response is already complete'
        if $response->is_complete;
    croak 'tunnel(): response already has an incremental body producer'
        if $response->_has_incremental_body;
    croak 'tunnel(): successful CONNECT response must not have a scalar body'
        if $response->_has_scalar_body;
    croak 'tunnel(): successful CONNECT response status must be 2xx'
        if $response->status < 200 || $response->status >= 300;

    my @response_length = $response->_header_values_list('Content-Length');
    my @response_transfer = $response->_header_values_list('Transfer-Encoding');
    croak 'tunnel(): successful CONNECT response must not contain Content-Length'
        if @response_length;
    croak 'tunnel(): successful CONNECT response must not contain Transfer-Encoding'
        if @response_transfer;

    my @connection = $response->_header_values_list('Connection');
    croak 'tunnel(): successful CONNECT response cannot request Connection: close'
        if _connection_has(\@connection, 'close');

    my $request_state = $conn->{_http_request_state}
        or croak 'tunnel(): request state is missing';

    $target = _load_target($target);
    croak "tunnel(): $target is already the active Connection class"
        if ref($conn) eq $target;

    $response->_commit;
    $transaction->_set_tunnel_pending;
    $conn->{_http_pending_tunnel} = {
        transaction => $transaction,
        target      => $target,
        resume_read => $conn->is_read_paused ? 0 : 1,
    };

    my $state = {
        connection  => $conn,
        transaction => $transaction,
        target      => $target,
    };
    $conn->loop->defer(sub { _handoff($state) });

    return $transaction;
}

sub _handoff ($state) {
    my $conn = $state->{connection};
    my $transaction = $state->{transaction};
    my $target = $state->{target};

    return if !$conn || $conn->is_closed || $conn->{_http_closing};
    return if !$transaction || $transaction->is_terminal;

    my $pending = $conn->{_http_pending_tunnel} or return;
    return if refaddr($pending->{transaction}) != refaddr($transaction);
    return if $pending->{target} ne $target;

    my $active = $conn->{_http_active_transaction};
    return if !$active || refaddr($active) != refaddr($transaction);

    my $request = $transaction->request;
    my $response = $transaction->response;
    my $request_state = $conn->{_http_request_state};
    if (!$request_state || !$request_state->{body_done}) {
        $transaction->_clear_tunnel_pending;
        delete $conn->{_http_pending_tunnel};
        $conn->_fail_active_transaction(500, $request, $response);
        return;
    }

    my $head;
    my $serialized = eval {
        $head = $response->_serialize_head('1.1');
        1;
    };
    if (!$serialized) {
        $transaction->_clear_tunnel_pending;
        delete $conn->{_http_pending_tunnel};
        $conn->_fail_active_transaction(500, $request, $response);
        return;
    }

    $response->_mark_complete;
    $transaction->_mark_response_started;
    $transaction->_mark_response_output_complete;
    $transaction->_clear_tunnel_pending;
    $conn->{_http_response_state} = undef;

    $conn->write($head);
    $conn->_complete_active_transaction_state;

    my $input = $conn->{_http_input};
    my $resume_read = $pending->{resume_read};
    $conn->{_http_input} = '';
    delete $conn->{_http_pending_tunnel};
    $conn->_clear_transaction;

    my $transitioned = eval {
        if (length($input)) {
            $conn->transition_to($target, input => $input);
        } else {
            $conn->transition_to($target);
        }
        $conn->resume_read if $resume_read && $conn->is_read_paused;
        1;
    };
    if (!$transitioned) {
        eval { $conn->close; 1 };
    }
    return;
}

sub CLONE_SKIP ($class) { 1 }

1;
