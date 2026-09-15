package Linux::Event::HTTP::_Upgrade;
use v5.36;
use strict;
use warnings;

use Carp qw(croak);
use Scalar::Util qw(refaddr);

use Linux::Event::IO::Sock::Stream ();
use Linux::Event::Kernel::Timer;

our $VERSION = '0.001';

sub _load_target ($target) {
    croak 'upgrade(): target class must be a package name'
        if !defined($target) || ref($target)
        || $target !~ /\A[A-Za-z_][A-Za-z0-9_]*(?:::[A-Za-z_][A-Za-z0-9_]*)*\z/;

    if (!$target->can('transition_to')) {
        (my $file = "$target.pm") =~ s{::}{/}g;
        require $file;
    }

    croak 'upgrade(): target class must inherit Linux::Event::IO::Sock::Stream'
        if !$target->isa('Linux::Event::IO::Sock::Stream');

    return $target;
}

sub _tokens ($where, @values) {
    my @token;
    for my $value (@values) {
        for my $member (split /,/, $value, -1) {
            $member =~ s/\A[ \t]+//;
            $member =~ s/[ \t]+\z//;
            croak "upgrade(): invalid $where field value"
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

sub schedule ($class, $conn, $transaction, $target) {
    croak 'upgrade(): connection is closing or closed'
        if $conn->{_http_closing} || $conn->is_closed;
    croak 'upgrade(): Transaction is already terminal'
        if $transaction->is_terminal;
    croak 'upgrade(): response output has already started'
        if $transaction->is_response_started;
    croak 'upgrade(): Transaction already has an Upgrade handoff pending'
        if $transaction->is_upgrading;

    my $active = $conn->{_http_active_transaction};
    croak 'upgrade(): Transaction is not active on this HTTP connection'
        if !$active || refaddr($active) != refaddr($transaction);

    my $req = $transaction->request
        or croak 'upgrade(): active Request is missing';
    my $response = $transaction->response
        or croak 'upgrade(): active Response is missing';

    croak 'upgrade(): response message has already been committed'
        if $response->_is_committed;
    croak 'upgrade(): response is already complete'
        if $response->is_complete;
    croak 'upgrade(): response already has an incremental body producer'
        if $response->_has_incremental_body;

    my $request_state = $conn->{_http_request_state}
        or croak 'upgrade(): request state is missing';

    croak 'upgrade(): HTTP Upgrade requires HTTP/1.1'
        if $req->version ne '1.1';
    croak 'upgrade(): request body must be empty before protocol handoff'
        if $req->_http1_body_mode eq 'chunked'
        || ($req->_http1_body_mode eq 'content-length'
            && ($req->content_length // '0') ne '0');

    my @request_connection = $req->_header_values_list('Connection');
    croak 'upgrade(): request Connection field must contain Upgrade'
        if !_connection_has(\@request_connection, 'upgrade');
    croak 'upgrade(): request cannot combine Connection: close with Upgrade'
        if _connection_has(\@request_connection, 'close')
        || !$req->_http1_keep_alive;

    my @offered = _tokens('request Upgrade', $req->_header_values_list('Upgrade'));
    croak 'upgrade(): request must contain an Upgrade field' if !@offered;

    my @selected = _tokens(
        'response Upgrade', $response->_header_values_list('Upgrade'),
    );
    croak 'upgrade(): response must select at least one Upgrade protocol'
        if !@selected;
    my %offered = map { $_ => 1 } @offered;
    for my $protocol (@selected) {
        croak "upgrade(): response selected protocol not offered by request: $protocol"
            if !$offered{$protocol};
    }

    croak 'upgrade(): response cannot contain Content-Length'
        if $response->_header_values_list('Content-Length');
    croak 'upgrade(): response cannot contain Transfer-Encoding'
        if $response->_header_values_list('Transfer-Encoding');

    my @response_connection = $response->_header_values_list('Connection');
    if (@response_connection) {
        croak 'upgrade(): response Connection field must contain Upgrade'
            if !_connection_has(\@response_connection, 'upgrade');
        croak 'upgrade(): response cannot combine Connection: close with Upgrade'
            if _connection_has(\@response_connection, 'close');
    }

    croak 'upgrade(): cannot replace an explicit non-upgrade status'
        if $response->status != 200 && $response->status != 101;

    $target = _load_target($target);
    croak "upgrade(): $target is already the active Connection class"
        if ref($conn) eq $target;

    $response->header('Connection', 'Upgrade') if !@response_connection;
    $response->status(101);
    $response->reason(undef);
    $response->_commit;

    $transaction->_set_upgrade_pending;
    $conn->{_http_pending_upgrade} = {
        transaction => $transaction,
        target      => $target,
        resume_read => $conn->is_read_paused ? 0 : 1,
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
    my $state = $timer->data;
    my $conn = $state->{connection};
    my $transaction = $state->{transaction};
    my $target = $state->{target};

    return if !$conn || $conn->is_closed || $conn->{_http_closing};
    return if !$transaction || $transaction->is_terminal;

    my $pending = $conn->{_http_pending_upgrade} or return;
    return if refaddr($pending->{transaction}) != refaddr($transaction);
    return if $pending->{target} ne $target;

    my $active = $conn->{_http_active_transaction};
    return if !$active || refaddr($active) != refaddr($transaction);

    my $request = $transaction->request;
    my $response = $transaction->response;
    my $request_state = $conn->{_http_request_state};
    if (!$request_state || !$request_state->{body_done}) {
        $transaction->_clear_upgrade_pending;
        delete $conn->{_http_pending_upgrade};
        $conn->_fail_active_transaction(500, $request, $response);
        return;
    }

    my $head;
    my $serialized = eval {
        $head = $response->_serialize_head('1.1');
        1;
    };
    if (!$serialized) {
        $transaction->_clear_upgrade_pending;
        delete $conn->{_http_pending_upgrade};
        $conn->_fail_active_transaction(500, $request, $response);
        return;
    }

    $response->_mark_complete;
    $transaction->_mark_response_started;
    $transaction->_mark_response_output_complete;
    $transaction->_clear_upgrade_pending;
    $conn->{_http_response_state} = undef;

    $conn->write($head);
    $conn->_complete_active_transaction_state;

    my $input = $conn->{_http_input};
    my $resume_read = $pending->{resume_read};
    $conn->{_http_input} = '';
    delete $conn->{_http_pending_upgrade};
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
