package Linux::Event::HTTP::_ClientUpgrade;
use v5.36;
use strict;
use warnings;

use Carp qw(croak);
use Scalar::Util qw(refaddr);

use Linux::Event::IO::Sock::Stream ();

our $VERSION = '0.003';

sub _load_target ($target) {
    croak 'request(): upgrade_to must be a package name'
        if !defined($target) || ref($target)
        || $target !~ /\A[A-Za-z_][A-Za-z0-9_]*(?:::[A-Za-z_][A-Za-z0-9_]*)*\z/;

    if (!$target->can('transition_to')) {
        (my $file = "$target.pm") =~ s{::}{/}g;
        require $file;
    }

    croak 'request(): upgrade_to class must inherit Linux::Event::IO::Sock::Stream'
        if !$target->isa('Linux::Event::IO::Sock::Stream');
    return $target;
}

sub _tokens ($where, @values) {
    my @token;
    for my $value (@values) {
        for my $member (split /,/, $value, -1) {
            $member =~ s/\A[ \t]+//;
            $member =~ s/[ \t]+\z//;
            croak "HTTP/1 Upgrade has invalid $where field value"
                if $member eq ''
                || $member !~ /\A[!#\$%&'*+\-.^_`|~0-9A-Za-z]+(?:\/[!#\$%&'*+\-.^_`|~0-9A-Za-z]+)?\z/;
            push @token, lc $member;
        }
    }
    return @token;
}

sub _connection_has ($values, $wanted) {
    for my $value (@$values) {
        for my $member (split /,/, $value, -1) {
            $member =~ s/\A[ \t]+//;
            $member =~ s/[ \t]+\z//;
            return 1 if lc($member) eq $wanted;
        }
    }
    return 0;
}

sub prepare_request ($class, $request, $target, $request_state) {
    $target = _load_target($target);

    croak 'request(): client Upgrade requires HTTP/1.1'
        if $request->version ne '1.1';
    croak 'request(): client Upgrade does not support streaming Request bodies'
        if $request_state->{streaming};

    my $body = $request->body;
    croak 'request(): client Upgrade Request body must be empty'
        if defined($body) && length($body);
    croak 'request(): client Upgrade Request body must be empty'
        if defined($request->content_length) && $request->content_length != 0;
    croak 'request(): client Upgrade cannot use Transfer-Encoding'
        if $request->_header_values_list('Transfer-Encoding');

    my @connection = $request->_header_values_list('Connection');
    croak 'request(): client Upgrade requires Connection: Upgrade'
        if !_connection_has(\@connection, 'upgrade');
    croak 'request(): client Upgrade cannot combine Connection: close with Upgrade'
        if _connection_has(\@connection, 'close');

    my @offered = _tokens(
        'request Upgrade', $request->_header_values_list('Upgrade'),
    );
    croak 'request(): client Upgrade requires an Upgrade field' if !@offered;

    return $target;
}

sub schedule ($class, $conn, $transaction, $response, $target) {
    croak 'HTTP/1 Upgrade connection is closed'
        if $conn->is_closed;
    croak 'HTTP/1 Upgrade Transaction is already terminal'
        if $transaction->is_terminal;

    my $active = $conn->{_http_client_active_transaction};
    croak 'HTTP/1 Upgrade Transaction is not active on this connection'
        if !$active || refaddr($active) != refaddr($transaction);

    my $request = $transaction->request;
    my $request_state = $conn->{_http_client_request_state}
        or croak 'HTTP/1 Upgrade request state is unavailable';
    croak 'HTTP/1 Upgrade request output is not complete'
        if !$request_state->{complete};

    croak 'HTTP/1 Upgrade response must use HTTP/1.1'
        if $response->version ne '1.1';
    croak 'HTTP/1 Upgrade response cannot contain Content-Length'
        if $response->_header_values_list('Content-Length');
    croak 'HTTP/1 Upgrade response cannot contain Transfer-Encoding'
        if $response->_header_values_list('Transfer-Encoding');

    my @connection = $response->_header_values_list('Connection');
    croak 'HTTP/1 Upgrade response requires Connection: Upgrade'
        if !_connection_has(\@connection, 'upgrade');
    croak 'HTTP/1 Upgrade response cannot combine Connection: close with Upgrade'
        if _connection_has(\@connection, 'close');

    my @offered = _tokens(
        'request Upgrade', $request->_header_values_list('Upgrade'),
    );
    my %offered = map { $_ => 1 } @offered;
    my @selected = _tokens(
        'response Upgrade', $response->_header_values_list('Upgrade'),
    );
    croak 'HTTP/1 Upgrade response must select a protocol' if !@selected;
    for my $protocol (@selected) {
        croak "HTTP/1 Upgrade response selected protocol not offered by request: $protocol"
            if !$offered{$protocol};
    }

    $target = _load_target($target);
    croak "HTTP/1 Upgrade target $target is already the active connection class"
        if ref($conn) eq $target;

    $transaction->_set_response($response);
    $conn->_callback('on_response', $transaction, $response)
        if $conn->{_http_client_callbacks}{on_response};
    return $transaction if !$conn->_same_active_transaction($transaction);

    $response->_mark_complete;
    $conn->{_http_client_reusable} = 0;
    my $resume_read = $conn->is_read_paused ? 0 : 1;
    $conn->pause_read if $resume_read;
    $conn->{_http_client_pending_upgrade} = {
        transaction => $transaction,
        response    => $response,
        target      => $target,
        resume_read => $resume_read,
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

    return if !$conn || $conn->is_closed;
    return if !$transaction || $transaction->is_terminal;

    my $pending = $conn->{_http_client_pending_upgrade} or return;
    return if refaddr($pending->{transaction}) != refaddr($transaction);
    return if $pending->{target} ne $target;

    my $active = $conn->{_http_client_active_transaction};
    return if !$active || refaddr($active) != refaddr($transaction);

    my $callbacks = $conn->{_http_client_callbacks} || {};
    my $response = $pending->{response};
    my $input = $conn->{_http_client_input};
    my $resume_read = $pending->{resume_read};

    $transaction->_mark_complete;
    $conn->{_http_client_input} = '';
    $conn->_clear_active_transaction;

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
        my $error = "$@";
        $error =~ s/\s+\z//;
        eval { $conn->close; 1 };
        $callbacks->{on_error}->(
            $transaction,
            "HTTP/1 Upgrade handoff failed: $error",
        ) if $callbacks->{on_error};
        return;
    }

    $callbacks->{on_upgrade}->($transaction, $response, $conn)
        if $callbacks->{on_upgrade};
    $callbacks->{on_complete}->($transaction)
        if $callbacks->{on_complete};
    return;
}

sub CLONE_SKIP ($class) { 1 }

1;
