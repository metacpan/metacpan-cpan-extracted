package Linux::Event::HTTP::Server::Connection;
use v5.36;
use strict;
use warnings;

use parent 'Linux::Event::IO::Sock::Stream';

use Carp qw(croak);
use Scalar::Util qw(refaddr);
use utf8 ();

use Linux::Event::Framer ();
use Linux::Event::HTTP::_HTTP1 ();
use Linux::Event::HTTP::Request;
use Linux::Event::HTTP::Response;
use Linux::Event::HTTP::Transaction;

our $VERSION = '0.002';

Linux::Event::Framer->declare_native_consumer(
    __PACKAGE__,
    Linux::Event::HTTP::_HTTP1->_raw_consumer_definition,
);

my $PARSER = 'Linux::Event::HTTP::_HTTP1';
my $CHUNKED = 'Linux::Event::HTTP::_HTTP1::Chunked';
my $MAX_REQUEST_HEAD = 65_536;
my $MAX_HEADERS = 100;
my %CLASS_HANDLER;

sub _class_handler ($class, $name) {
    my $key = "$class\0$name";
    return $CLASS_HANDLER{$key} if exists $CLASS_HANDLER{$key};
    return $CLASS_HANDLER{$key} = $class->can($name);
}

sub _take_http_handler ($class, $name, $option) {
    if (exists $option->{$name}) {
        my $handler = delete $option->{$name};
        croak "new(): $name must be a coderef" if ref($handler) ne 'CODE';
        return $handler;
    }
    return _class_handler($class, $name);
}

sub new ($class, %option) {
    my $server_state = $option{data};
    if (ref($server_state)
        eq 'Linux::Event::HTTP::Server::_ConnectionState') {
        $option{data} = $server_state->{data};
        my $callbacks = $server_state->{callbacks};
        for my $name (qw(on_request on_body on_request_end)) {
            $option{$name} = $callbacks->{$name}
                if exists $callbacks->{$name};
        }
    }

    croak 'new(): Connection owns on_data; use on_request for HTTP requests'
        if exists $option{on_data};
    croak 'new(): Connection cannot use message framing callbacks'
        if exists($option{on_message}) || exists($option{on_messages});
    croak 'new(): on_request_final was removed; use on_request and Response->body or Transaction->response_body'
        if exists $option{on_request_final};

    my $loop = delete $option{loop};
    my $on_request = _take_http_handler($class, 'on_request', \%option);
    my $on_body = _take_http_handler($class, 'on_body', \%option);
    my $on_request_end = _take_http_handler($class, 'on_request_end', \%option);
    my $user_on_drain = _take_http_handler($class, 'on_drain', \%option);
    my $user_on_close = _take_http_handler($class, 'on_close', \%option);

    croak 'new(): HTTP Connection requires on_request callback or method'
        if !$on_request;

    $option{on_drain} = \&_http_transport_drain;
    $option{on_close} = \&_http_transport_close;

    my $self = $class->SUPER::new(%option);
    $self->{_http_on_request} = $on_request;
    $self->{_http_on_body} = $on_body;
    $self->{_http_on_request_end} = $on_request_end;
    $self->{_http_user_on_drain} = $user_on_drain;
    $self->{_http_user_on_close} = $user_on_close;
    $self->{_http_input} = '';
    $self->{_http_active_transaction} = undef;
    $self->{_http_active_request} = undef;
    $self->{_http_active_response} = undef;
    $self->{_http_request_state} = undef;
    $self->{_http_response_state} = undef;
    $self->{_http_response_output_started} = 0;
    $self->{_http_response_output_complete} = 0;
    $self->{_http_driving} = 0;
    $self->{_http_dispatching} = 0;
    $self->{_http_closing} = 0;

    $self->_attach_to_loop($loop) if $loop;
    return $self;
}

sub connect ($class, %option) {
    croak 'connect(): HTTP client support is not implemented by Linux::Event::HTTP::Server::Connection';
}

sub transaction ($self) {
    my $transaction = $self->{_http_active_transaction};
    return $transaction if $transaction;

    my $request = $self->{_http_active_request} or return;
    my $response = $self->{_http_active_response} or return;

    $transaction = Linux::Event::HTTP::Transaction
        ->_new_server_active($request, $response, $self);
    $transaction->{response_output_started} = 1
        if $self->{_http_response_output_started};
    $transaction->{response_output_complete} = 1
        if $self->{_http_response_output_complete};
    $self->{_http_active_transaction} = $transaction;
    return $transaction;
}

sub _http_native_protocol_400 ($self) {
    $self->_protocol_error(400);
    return 0;
}

sub _http_native_protocol_431 ($self) {
    $self->_protocol_error(431);
    return 0;
}

sub _http_native_protocol_501 ($self) {
    $self->_protocol_error(501);
    return 0;
}

sub _http_native_fallback_input ($self, $bytes) {
    return 0 if $self->{_http_closing} || $self->is_closed;

    $self->{_http_input} .= $bytes;
    $self->_drive_http1;

    return 0 if $self->{_http_closing} || $self->is_closed;
    return 1 if length($self->{_http_input});

    my $state = $self->{_http_request_state};
    return 1 if $self->{_http_active_request}
        && $state && !$state->{body_done};

    return 0;
}

sub _http_native_request ($self, $request) {
    return 0 if $self->{_http_closing} || $self->is_closed;
    croak 'raw HTTP input delivered a new Request while another Request is active'
        if $self->{_http_active_request};

    my $consumed = $request->_consumed;
    if ($consumed > $MAX_REQUEST_HEAD) {
        $self->_protocol_error(431, $request->version);
        return 0;
    }

    my $action = $self->_activate_native_http_request($request);
    return 0 if $action != 2;

    return $self->{_http_on_body} ? 5 : 4
        if $request->_http1_body_mode eq 'chunked';
    return $self->{_http_on_body} ? 3 : 2;
}

sub _http_native_chunked_body ($self, $bytes, $done) {
    return 0 if $self->{_http_closing} || $self->is_closed;

    my $request = $self->{_http_active_request} or return 0;
    my $response = $self->{_http_active_response} or return 0;
    my $state = $self->{_http_request_state} or return 0;

    croak 'raw chunked body delivery has wrong request state'
        if $state->{body_done} || $state->{mode} ne 'chunked';

    if (length($bytes) && !$self->_invoke_http_callback(
        $self->{_http_on_body}, $request, $response, $bytes,
    )) {
        return 0;
    }
    return 0 if $self->{_http_closing} || $self->is_closed;
    return 0 if !$self->{_http_active_request};

    if ($done) {
        $self->_finish_request_body;
        return 0;
    }

    return 1;
}

sub _http_native_chunked_complete ($self) {
    return 0 if $self->{_http_closing} || $self->is_closed;

    my $state = $self->{_http_request_state} or return 0;
    croak 'raw chunked drain has wrong request state'
        if $state->{body_done} || $state->{mode} ne 'chunked';
    croak 'raw chunked drain cannot bypass an on_body callback'
        if $self->{_http_on_body};

    $self->_finish_request_body;
    return 0;
}

sub _http_native_chunked_error ($self) {
    return 0 if $self->{_http_closing} || $self->is_closed;

    my $request = $self->{_http_active_request} or return 0;
    my $response = $self->{_http_active_response} or return 0;
    $self->_fail_active_transaction(400, $request, $response);
    return 0;
}

sub _http_native_content_length_body ($self, $bytes, $done) {
    return 0 if $self->{_http_closing} || $self->is_closed;

    my $request = $self->{_http_active_request} or return 0;
    my $response = $self->{_http_active_response} or return 0;
    my $state = $self->{_http_request_state} or return 0;

    croak 'raw Content-Length body delivery has wrong request state'
        if $state->{body_done} || $state->{mode} ne 'content-length';

    my $length = length($bytes);
    my $remaining = $state->{remaining} // 0;
    croak 'raw Content-Length body delivery exceeds remaining body'
        if $length > $remaining;

    $state->{remaining} = $remaining - $length;

    if ($length && !$self->_invoke_http_callback(
        $self->{_http_on_body}, $request, $response, $bytes,
    )) {
        return 0;
    }
    return 0 if $self->{_http_closing} || $self->is_closed;
    return 0 if !$self->{_http_active_request};

    if ($done) {
        croak 'raw Content-Length body completed before declared length'
            if $state->{remaining} != 0;
        $self->_finish_request_body;
        return 0;
    }

    croak 'raw Content-Length body reached zero without completion'
        if $state->{remaining} == 0;
    return 1;
}

sub _http_native_content_length_complete ($self) {
    return 0 if $self->{_http_closing} || $self->is_closed;

    my $state = $self->{_http_request_state} or return 0;
    croak 'raw Content-Length drain has wrong request state'
        if $state->{body_done} || $state->{mode} ne 'content-length';
    croak 'raw Content-Length drain cannot bypass an on_body callback'
        if $self->{_http_on_body};

    $state->{remaining} = 0;
    $self->_finish_request_body;
    return 0;
}

sub _http_transport_drain ($self) {
    if (my $transaction = $self->{_http_active_transaction}) {
        if (my $body = $transaction->_response_body_object) {
            $body->_drain;
        }
    }
    if (my $callback = $self->{_http_user_on_drain}) {
        $callback->($self);
    }
    return;
}

sub _http_transport_close ($self) {
    if (my $transaction = $self->{_http_active_transaction}) {
        $transaction->_mark_cancelled if !$transaction->is_terminal;
    }
    $self->_clear_transaction;

    my $callback = delete $self->{_http_user_on_close};
    delete $self->{_http_user_on_drain};
    $callback->($self) if $callback;
    return;
}

sub _new_request_state ($request, $mode = $request->_http1_body_mode) {
    my $state = {
        mode      => $mode,
        body_done => 0,
    };

    if ($mode eq 'content-length') {
        $state->{remaining} = $request->content_length // 0;
    } elsif ($mode eq 'chunked') {
        $state->{decoder} = $CHUNKED->new;
    }

    return $state;
}

sub _body_pending ($state) {
    return 0 if $state->{body_done};
    return 0 if $state->{mode} eq 'none';
    return $state->{remaining} > 0 if $state->{mode} eq 'content-length';
    return 1;
}

sub _expect_continue ($request) {
    my @values = $request->_header_values_list('Expect');
    return 0 if !@values;
    return -1 if $request->version ne '1.1';

    my $count = 0;
    for my $value (@values) {
        for my $member (split /,/, $value, -1) {
            $member =~ s/\A[ \t]+//;
            $member =~ s/[ \t]+\z//;
            return -1 if $member eq '' || lc($member) ne '100-continue';
            ++$count;
        }
    }

    return $count ? 1 : -1;
}

sub _invoke_http_callback ($self, $handler, $request, $response, @extra) {
    return 1 if !$handler;

    my $ok = eval {
        {
            local $self->{_http_dispatching} = 1;
            $handler->($self, $request, $response, @extra);
        }
        $self->_response_body_ready($response);
        1;
    };

    if (!$ok) {
        $self->_fail_active_transaction(500, $request, $response);
        return 0;
    }

    return 1;
}

sub _response_body_ready ($self, $response) {
    return if !$response;
    return if $self->{_http_dispatching};

    my $active_response = $self->{_http_active_response} or return;
    return if refaddr($active_response) != refaddr($response);

    return if $self->{_http_response_output_complete};

    my $transaction = $self->{_http_active_transaction};
    if ((($response->{_server_flags} // 0) & 1)
        && ($response->{body_kind} // '') eq 'scalar') {
        return if $self->_try_native_default_final(
            $transaction, $response->{body},
        );
    }

    return if ($response->{body_kind} // '') ne 'scalar';
    my $body = $response->{body};
    return if $self->_try_simple_scalar_final($response, $body);
    $self->_write_response(
        $response, $body, 1, 'send_response',
    );
    return;
}


sub _try_simple_scalar_final ($self, $response, $body) {
    my $request = $self->{_http_active_request} or return 0;
    return 0 if $self->{_http_response_state};

    my $wire = Linux::Event::HTTP::_HTTP1
        ->build_simple_scalar_final($request, $response, $body);
    return 0 if !defined $wire;

    my $request_state = $self->{_http_request_state};

    # The ordinary synchronous bodyless response has no materialized
    # Transaction and no later request-body phase that needs output state.
    # Keep only the started bit across write() for exception safety, then
    # retire the three live exchange references directly.
    if ($request_state && $request_state->{body_done}
        && !$self->{_http_active_transaction}) {
        $self->{_http_response_output_started} = 1;
        $self->write($wire);
        $self->{_http_active_request} = undef;
        $self->{_http_active_response} = undef;
        $self->{_http_request_state} = undef;
        $self->{_http_response_output_started} = 0;
        $self->resume_read if $self->is_read_paused;
        return 1;
    }

    $self->{_http_response_output_started} = 1;
    $self->{_http_response_output_complete} = 1;
    if (my $transaction = $self->{_http_active_transaction}) {
        $transaction->{response_output_started} = 1;
        $transaction->{response_output_complete} = 1;
    }

    $self->write($wire);

    if ($request_state && $request_state->{body_done}) {
        if (my $transaction = $self->{_http_active_transaction}) {
            $transaction->{state} = 'complete';
        }
        $self->_clear_transaction;
    }

    $self->resume_read if $self->is_read_paused;
    return 1;
}

sub _send_http_response ($self, $transaction) {
    croak 'send_response(): connection is closing or closed'
        if $self->{_http_closing} || $self->is_closed;

    my $active = $self->{_http_active_transaction};
    croak 'send_response(): Transaction is not active on this HTTP connection'
        if !$active || refaddr($active) != refaddr($transaction);
    croak 'send_response(): response output has already started'
        if $transaction->is_response_started;

    my $response = $transaction->response
        or croak 'send_response(): Transaction has no Response';
    croak 'send_response(): Response does not have a complete scalar body'
        if ($response->{body_kind} // '') ne 'scalar';

    my $body = $response->{body};
    return 1 if $self->_try_native_default_final($transaction, $body);
    return 1 if $self->_try_simple_scalar_final($response, $body);

    $self->_write_response($response, $body, 1, 'send_response');
    return 1;
}

sub _try_native_default_final ($self, $transaction, $body) {
    my $response = $transaction
        ? $transaction->{response}
        : $self->{_http_active_response};
    return 0 if !$response;
    return 0 if !(($response->{_server_flags} // 0) & 1);
    return 0 if (($response->{status} // 200) != 200);
    return 0 if defined $response->{reason};
    my $headers = $response->{headers};
    return 0 if defined($headers)
        && (ref($headers) ne 'ARRAY' || @$headers);
    return 0 if $self->{_http_response_state};

    my $request_state = $self->{_http_request_state} or return 0;
    my $body_done = $request_state->{body_done} ? 1 : 0;

    my $request = $transaction
        ? $transaction->{request}
        : $self->{_http_active_request};
    return 0 if !$request;
    my $wire = Linux::Event::HTTP::_HTTP1
        ->build_default_final($request, $body);
    return 0 if !defined $wire;

    $response->{committed} = 1;
    $self->{_http_response_output_started} = 1;
    $self->{_http_response_output_complete} = 1;
    if ($transaction) {
        $transaction->{response_output_started} = 1;
        $transaction->{response_output_complete} = 1;
    }
    $self->{_http_response_state} = undef;

    $self->write($wire);

    if ($body_done) {
        $transaction->{state} = 'complete' if $transaction;
        $self->_clear_transaction;
    }

    $self->resume_read if $self->is_read_paused;
    return 1;
}

sub _upgrade_http_transaction ($self, $transaction, $target_class) {
    require Linux::Event::HTTP::_Upgrade;
    Linux::Event::HTTP::_Upgrade->schedule(
        $self, $transaction, $target_class,
    );
    return $transaction;
}

sub _tunnel_http_transaction ($self, $transaction, $target_class) {
    require Linux::Event::HTTP::_ServerConnect;
    Linux::Event::HTTP::_ServerConnect->schedule(
        $self, $transaction, $target_class,
    );
    return $transaction;
}

sub _complete_active_transaction_state ($self) {
    my $transaction = $self->{_http_active_transaction} or return;
    return if $transaction->is_terminal;

    croak 'cannot complete server Transaction before Request body completion'
        if !$transaction->request->is_complete;
    my $response = $transaction->response;
    croak 'cannot complete server Transaction before Response body completion'
        if !$response || !$response->is_complete;
    croak 'cannot complete server Transaction before Response output completion'
        if !$transaction->_is_response_output_complete;

    $transaction->_mark_complete;
    return;
}

sub _fail_active_transaction_state ($self, $error) {
    my $transaction = $self->{_http_active_transaction} or return;
    return if $transaction->is_terminal;
    $transaction->_fail($error);
    return;
}

sub _clear_transaction ($self) {
    $self->{_http_active_transaction} = undef;
    $self->{_http_active_request} = undef;
    $self->{_http_active_response} = undef;
    $self->{_http_request_state} = undef;
    $self->{_http_response_state} = undef;
    $self->{_http_response_output_started} = 0;
    $self->{_http_response_output_complete} = 0;
    delete $self->{_http_pending_upgrade};
    delete $self->{_http_pending_tunnel};
    return;
}

sub _cancel_http_transaction ($self, $transaction) {
    return if $transaction->is_terminal;

    my $active = $self->{_http_active_transaction};
    croak 'cancel(): Transaction is not active on this HTTP connection'
        if !$active || refaddr($active) != refaddr($transaction);

    $transaction->_mark_cancelled;
    $self->_clear_transaction;
    $self->{_http_input} = '';
    $self->{_http_closing} = 1;
    $self->pause_read if !$self->is_read_paused;
    $self->end;
    return;
}

sub _abort_started_response ($self) {
    return if $self->{_http_closing} || $self->is_closed;

    $self->_clear_transaction;
    $self->{_http_input} = '';
    $self->{_http_closing} = 1;
    $self->pause_read if !$self->is_read_paused;
    $self->end;
    return;
}

sub _fail_active_transaction ($self, $status, $request, $response) {
    return if $self->{_http_closing} || $self->is_closed;

    my $transaction = $self->{_http_active_transaction};
    my $started = $self->{_http_response_output_started} ? 1 : 0;
    $self->_fail_active_transaction_state("HTTP server transaction failed ($status)");

    if ($started) {
        $self->_abort_started_response;
    } else {
        $self->_protocol_error($status, $request->version);
    }
    return;
}

sub _finish_request_body ($self) {
    my $request = $self->{_http_active_request} or return;
    my $response = $self->{_http_active_response} or return;
    my $state = $self->{_http_request_state} or return;
    return if $state->{body_done};

    $state->{body_done} = 1;
    $request->_mark_complete;
    delete $state->{decoder};
    delete $state->{remaining};

    return if !$self->_invoke_http_callback(
        $self->{_http_on_request_end}, $request, $response,
    );
    return if $self->{_http_closing} || $self->is_closed;
    return if !$self->{_http_active_request};

    if ($self->{_http_response_output_complete}) {
        $self->_finalize_transaction;
    } else {
        $self->pause_read if !$self->is_read_paused;
    }
    return;
}

sub _consume_request_body ($self) {
    my $request = $self->{_http_active_request} or return 0;
    my $response = $self->{_http_active_response} or return 0;
    my $state = $self->{_http_request_state} or return 0;
    return 0 if $state->{body_done};

    if ($state->{mode} eq 'content-length') {
        if (($state->{remaining} // 0) == 0) {
            $self->_finish_request_body;
            return 1;
        }
        return 0 if !length($self->{_http_input});

        my $available = length($self->{_http_input});
        my $take = $available < $state->{remaining}
            ? $available : $state->{remaining};

        my $chunk;
        if ($self->{_http_on_body}) {
            $chunk = substr($self->{_http_input}, 0, $take, '');
        } else {
            substr($self->{_http_input}, 0, $take, '');
        }
        $state->{remaining} -= $take;

        if (defined($chunk) && length($chunk)) {
            return 1 if !$self->_invoke_http_callback(
                $self->{_http_on_body}, $request, $response, $chunk,
            );
            return 1 if $self->{_http_closing} || $self->is_closed;
            return 1 if !$self->{_http_active_request};
        }

        $self->_finish_request_body if $state->{remaining} == 0;
        return 1;
    }

    if ($state->{mode} eq 'chunked') {
        return 0 if !length($self->{_http_input});

        my ($done, $decoded);
        my $ok = eval {
            ($done, $decoded) = $state->{decoder}->feed(
                $self->{_http_input}, $self->{_http_on_body} ? 1 : 0,
            );
            1;
        };
        if (!$ok) {
            $self->_fail_active_transaction(400, $request, $response);
            return 1;
        }

        if (defined($decoded) && length($decoded)) {
            return 1 if !$self->_invoke_http_callback(
                $self->{_http_on_body}, $request, $response, $decoded,
            );
            return 1 if $self->{_http_closing} || $self->is_closed;
            return 1 if !$self->{_http_active_request};
        }

        $self->_finish_request_body if $done;
        return 1;
    }

    $self->_finish_request_body;
    return 1;
}

sub _finalize_transaction ($self) {
    return if $self->{_http_closing} || $self->is_closed;

    my $request_state = $self->{_http_request_state};
    my $close_after = $request_state
        && $request_state->{close_after_response} ? 1 : 0;

    $self->_complete_active_transaction_state;
    $self->_clear_transaction;

    if ($close_after) {
        $self->{_http_input} = '';
        $self->{_http_closing} = 1;
        $self->pause_read if !$self->is_read_paused;
        $self->end;
        return;
    }

    $self->resume_read if $self->is_read_paused;
    $self->_drive_http1
        if !$self->{_http_driving} && !$self->{_http_dispatching};
    return;
}

sub _activate_native_http_request ($self, $request) {
    return 0 if $self->{_http_closing} || $self->is_closed;
    croak 'cannot activate a new HTTP Request while another Request is active'
        if $self->{_http_active_request};

    my $expect = $request->_expect_continue;
    if ($expect < 0) {
        $self->_protocol_error(417, $request->version);
        return 0;
    }

    my $body_mode = $request->_http1_body_mode;
    my $bodyless = $body_mode eq 'none';

    my $response = Linux::Event::HTTP::Response
        ->_new_server_default($request);

    my $request_state;
    if ($bodyless) {
        $request_state = $self->{_http_bodyless_state};
        if (!$request_state) {
            $request_state = $self->{_http_bodyless_state} = {
                mode      => 'none',
                body_done => $self->{_http_on_request_end} ? 0 : 1,
            };
        } elsif ($self->{_http_on_request_end}) {
            $request_state->{body_done} = 0;
        }
    } elsif ($body_mode eq 'chunked') {
        $request_state = {
            mode      => 'chunked',
            body_done => 0,
        };
    } else {
        $request_state = _new_request_state($request, $body_mode);
    }

    $self->{_http_active_request} = $request;
    $self->{_http_active_response} = $response;
    $self->{_http_request_state} = $request_state;

    if ($expect && _body_pending($request_state)) {
        $self->write("HTTP/1.1 100 Continue\r\n\r\n");
    }

    if (!$self->_invoke_http_callback(
        $self->{_http_on_request}, $request, $response,
    )) {
        return 0;
    }
    return 0 if $self->{_http_closing} || $self->is_closed;
    return 1 if !$self->{_http_active_request};

    if ($bodyless) {
        if ($self->{_http_on_request_end}) {
            $request_state->{body_done} = 1;
            return 0 if !$self->_invoke_http_callback(
                $self->{_http_on_request_end}, $request, $response,
            );
            return 0 if $self->{_http_closing} || $self->is_closed;
            return 1 if !$self->{_http_active_request};
        }

        if ($self->{_http_response_output_complete}) {
            $self->_finalize_transaction;
            return 0 if $self->{_http_closing} || $self->is_closed;
            return 1;
        }

        $self->pause_read if !$self->is_read_paused;
        return 0;
    }

    if (!_body_pending($request_state)) {
        $self->_finish_request_body;
        return 0 if $self->{_http_closing} || $self->is_closed;
        return 1 if !$self->{_http_active_request};
        return 0;
    }

    return 2;
}

sub _drive_http1 ($self) {
    return if $self->{_http_driving} || $self->{_http_closing}
        || $self->is_closed;

    local $self->{_http_driving} = 1;

    while (!$self->{_http_closing} && !$self->is_closed) {
        if (my $request = $self->{_http_active_request}) {
            my $response = $self->{_http_active_response};
            my $state = $self->{_http_request_state};
            my $transaction = $self->{_http_active_transaction};

            if (!$state->{body_done}) {
                if (!_body_pending($state)) {
                    $self->_finish_request_body;
                    next;
                }

                last if !length($self->{_http_input});
                $self->_consume_request_body;
                next;
            }

            if ($self->{_http_response_output_complete}) {
                $self->_finalize_transaction;
                next;
            }

            $self->pause_read if $response && !$self->is_read_paused;
            last;
        }

        last if !length($self->{_http_input});

        my $request = $PARSER->_parse_server_request(
            $self->{_http_input}, $MAX_REQUEST_HEAD, $MAX_HEADERS,
        );

        if (!defined $request) {
            last;
        }
        if (!ref $request) {
            $self->_protocol_error(0 + $request);
            last;
        }

        my $consumed = $request->_consumed;
        if ($consumed > $MAX_REQUEST_HEAD) {
            $self->_protocol_error(431, $request->version);
            last;
        }
        substr($self->{_http_input}, 0, $consumed, '');

        my $expect = $request->_expect_continue;
        if ($expect < 0) {
            $self->_protocol_error(417, $request->version);
            last;
        }

        my $body_mode = $request->_http1_body_mode;
        my $bodyless = $body_mode eq 'none';

        my $response = Linux::Event::HTTP::Response
            ->_new_server_default($request);

        my $request_state;
        if ($bodyless) {
            $request_state = $self->{_http_bodyless_state};
            if (!$request_state) {
                $request_state = $self->{_http_bodyless_state} = {
                    mode      => 'none',
                    body_done => $self->{_http_on_request_end} ? 0 : 1,
                };
            } elsif ($self->{_http_on_request_end}) {
                $request_state->{body_done} = 0;
            }

            # Native bodyless Requests are intrinsically complete: Request
            # derives this from the parser's body mode. Do not create a
            # fieldhash completion override for every ordinary request.
        } else {
            $request_state = _new_request_state($request, $body_mode);
        }

        # A new request is reached only after the previous exchange was
        # cleared (or on a freshly initialized Connection), so transaction,
        # response-state, and output-progress fields are already neutral.
        $self->{_http_active_request} = $request;
        $self->{_http_active_response} = $response;
        $self->{_http_request_state} = $request_state;

        if ($expect && _body_pending($request_state)) {
            $self->write("HTTP/1.1 100 Continue\r\n\r\n");
        }

        if (!$self->_invoke_http_callback(
            $self->{_http_on_request}, $request, $response,
        )) {
            last;
        }
        last if $self->{_http_closing} || $self->is_closed;
        next if !$self->{_http_active_request};

        if ($bodyless) {
            if ($self->{_http_on_request_end}) {
                $request_state->{body_done} = 1;
                last if !$self->_invoke_http_callback(
                    $self->{_http_on_request_end}, $request, $response,
                );
                last if $self->{_http_closing} || $self->is_closed;
                next if !$self->{_http_active_request};
            }

            if ($self->{_http_response_output_complete}) {
                $self->_finalize_transaction;
                next;
            }

            $self->pause_read if !$self->is_read_paused;
            last;
        }

        if (!_body_pending($request_state)) {
            $self->_finish_request_body;
        }
    }

    return;
}

sub _body_bytes ($operation, $body) {
    croak "$operation(): body must be a scalar byte string" if ref($body);

    my $bytes = defined($body) ? "$body" : '';
    if (utf8::is_utf8($bytes)) {
        croak "$operation(): body contains wide characters; encode it to bytes first"
            if !utf8::downgrade($bytes, 1);
    }
    return $bytes;
}

sub _canonical_decimal ($value) {
    return undef if !defined($value) || $value !~ /\A\d+\z/;
    my $decimal = "$value";
    $decimal =~ s/\A0+(?=\d)//;
    return $decimal;
}

sub _compare_count ($count, $decimal) {
    my $actual = "$count";
    return length($actual) <=> length($decimal)
        || $actual cmp $decimal;
}

sub _chunk_wire ($bytes) {
    return '' if !length($bytes);
    return sprintf('%x', length($bytes)) . "\r\n" . $bytes . "\r\n";
}

sub _chunked_transfer_encoding ($operation, $version, $values) {
    return 0 if !@$values;

    croak "$operation(): Transfer-Encoding is not valid for HTTP/1.0 responses"
        if $version ne '1.1';

    my @coding;
    for my $value (@$values) {
        for my $member (split /,/, $value, -1) {
            $member =~ s/\A[ \t]+//;
            $member =~ s/[ \t]+\z//;
            croak "$operation(): invalid Transfer-Encoding response value"
                if $member eq '' || $member =~ /;/;
            push @coding, lc $member;
        }
    }

    croak "$operation(): only chunked response Transfer-Encoding is supported"
        if @coding != 1 || $coding[0] ne 'chunked';

    return 1;
}

sub _response_start ($self, $response, $bytes, $final, $operation = undef) {
    my $transaction = $self->{_http_active_transaction};
    my $request = $self->{_http_active_request}
        or croak 'response output requires an active HTTP Request';
    my $version = $request->version;
    my $method = $request->method;
    my $status = $response->status;
    $operation //= $final ? 'complete' : 'write';

    croak "$operation(): informational responses require a future interim-response API"
        if $status >= 100 && $status < 200;

    my $body_forbidden = $status == 204 || $status == 304;
    croak "$operation(): this response status cannot carry a message body"
        if $body_forbidden && length($bytes);

    my @transfer_encoding = $response->_header_values_list('Transfer-Encoding');
    my @content_length = $response->_header_values_list('Content-Length');
    my $head_request = $method eq 'HEAD';

    croak "$operation(): response cannot contain both Transfer-Encoding and Content-Length"
        if @transfer_encoding && @content_length;

    croak "$operation(): HEAD responses cannot use a streaming body"
        if !$final && $head_request;
    croak "$operation(): this response status cannot use body streaming"
        if !$final && $body_forbidden;

    my $chunked = _chunked_transfer_encoding(
        $operation, $version, \@transfer_encoding,
    );
    my $close_delimited = 0;

    if (!@content_length && !$body_forbidden && !$chunked) {
        if ($final) {
            $response->header('Content-Length', length($bytes));
            @content_length = $response->_header_values_list('Content-Length');
        } elsif ($version eq '1.1') {
            $response->header('Transfer-Encoding', 'chunked');
            $chunked = 1;
        } else {
            $close_delimited = 1;
        }
    }

    my $expected;
    if (@content_length == 1) {
        $expected = _canonical_decimal($content_length[0]);
        croak "$operation(): Content-Length must be a decimal number"
            if !defined $expected;
    }

    if ($final && !$head_request && !$body_forbidden && defined $expected) {
        croak "$operation(): Content-Length does not match scalar body length"
            if _compare_count(length($bytes), $expected) != 0;
    }

    if (!$final && defined $expected
        && _compare_count(length($bytes), $expected) > 0) {
        croak "$operation(): response body exceeds Content-Length";
    }

    my @connection = $response->_header_values_list('Connection');
    my $keep_alive = $request->_http1_keep_alive;
    my $close_after = !$keep_alive
        || _has_connection_token(\@connection, 'close')
        || $close_delimited;

    if (!$keep_alive && $version eq '1.1') {
        $response->header('Connection', 'close');
        $close_after = 1;
    } elsif ($keep_alive && $version eq '1.0'
        && !@connection && !$close_after) {
        $response->header('Connection', 'keep-alive');
    }

    my $head = $response->_serialize_head($version);
    $response->_commit;
    $self->{_http_response_output_started} = 1;
    $transaction->_mark_response_started if $transaction;

    return (
        {
            expected      => $expected,
            sent          => 0,
            suppress_body => $head_request || $body_forbidden ? 1 : 0,
            close_after   => $close_after ? 1 : 0,
            chunked       => $chunked ? 1 : 0,
        },
        $head,
    );
}

sub _write_http_response_body ($self, $transaction, $body, $final, $operation) {
    my $active = $self->{_http_active_transaction};
    croak "$operation(): Transaction is not active on this HTTP connection"
        if !$active || refaddr($active) != refaddr($transaction);

    my $response = $transaction->response
        or croak "$operation(): Transaction has no Response";
    return $self->_write_response(
        $response, $body, $final, $operation,
    );
}

sub _write_response ($self, $response, $body, $final, $operation = undef) {
    $operation //= $final ? 'complete' : 'write';

    croak "$operation(): connection is closing or closed"
        if $self->{_http_closing} || $self->is_closed;

    my $active = $self->{_http_active_response};
    croak "$operation(): this Response is not the active HTTP transaction"
        if !$active || refaddr($active) != refaddr($response);

    my $bytes = _body_bytes($operation, $body);
    my $state = $self->{_http_response_state};

    if (!$state) {
        my ($created, $head) = $self->_response_start(
            $response, $bytes, $final, $operation,
        );
        $state = $self->{_http_response_state} = $created;

        if ($final) {
            my $wire_body = '';
            if (!$state->{suppress_body}) {
                $wire_body = $state->{chunked}
                    ? _chunk_wire($bytes) . "0\r\n\r\n"
                    : $bytes;
            }
            return $self->_complete_response(
                $response, $head . $wire_body, $state->{close_after},
            );
        }

        $state->{sent} = length($bytes);
        my $wire_body = $state->{chunked} ? _chunk_wire($bytes) : $bytes;
        return $self->write($head . $wire_body);
    }

    my $new_sent = $state->{sent} + length($bytes);
    if (defined($state->{expected})
        && _compare_count($new_sent, $state->{expected}) > 0) {
        croak "$operation(): response body exceeds Content-Length";
    }
    if ($final && defined($state->{expected})
        && _compare_count($new_sent, $state->{expected}) != 0) {
        croak "$operation(): response body length does not match Content-Length";
    }

    $state->{sent} = $new_sent;

    if ($final) {
        my $wire = $state->{chunked}
            ? _chunk_wire($bytes) . "0\r\n\r\n"
            : $bytes;
        return $self->_complete_response(
            $response, $wire, $state->{close_after},
        );
    }

    my $wire = $state->{chunked} ? _chunk_wire($bytes) : $bytes;
    return length($wire) ? $self->write($wire) : 1;
}

sub _complete_response ($self, $response, $wire, $close_after) {
    my $transaction = $self->{_http_active_transaction};
    $self->{_http_response_output_started} = 1;
    $self->{_http_response_output_complete} = 1;
    $transaction->_mark_response_output_complete if $transaction;
    $self->{_http_response_state} = undef;

    my $request_state = $self->{_http_request_state};
    if ($close_after && $request_state && !$request_state->{body_done}) {
        $request_state->{close_after_response} = 1;
        my $accepted = length($wire) ? $self->write($wire) : 1;
        $self->resume_read if $self->is_read_paused;
        return $accepted;
    }

    if ($close_after) {
        $self->_complete_active_transaction_state;
        $self->_clear_transaction;
        $self->{_http_closing} = 1;
        $self->{_http_input} = '';
        $self->pause_read if !$self->is_read_paused;
        $self->end($wire);
        return 1;
    }

    my $accepted = length($wire) ? $self->write($wire) : 1;
    if ($request_state && $request_state->{body_done}) {
        $self->_finalize_transaction;
    } else {
        $self->resume_read if $self->is_read_paused;
    }
    return $accepted;
}

sub _has_connection_token ($values, $wanted) {
    for my $value (@$values) {
        for my $token (split /,/, $value) {
            $token =~ s/\A[ \t]+//;
            $token =~ s/[ \t]+\z//;
            return 1 if lc($token) eq $wanted;
        }
    }
    return 0;
}

sub _protocol_error ($self, $status, $version = '1.1') {
    return if $self->{_http_closing} || $self->is_closed;

    $version = '1.1' if $version ne '1.0' && $version ne '1.1';

    my $response = Linux::Event::HTTP::Response->_new(
        status => $status,
        headers => [
            [ 'Content-Length', '0' ],
            [ 'Connection', 'close' ],
        ],
    );

    my $head = $response->_serialize_head($version);
    $self->_fail_active_transaction_state("HTTP protocol error ($status)");
    $self->_clear_transaction;
    $self->{_http_input} = '';
    $self->{_http_closing} = 1;
    $self->pause_read if !$self->is_read_paused;
    $self->end($head);
    return;
}

sub CLONE ($class) {
    %CLASS_HANDLER = ();
    Linux::Event::_Socket::Stream::CLONE($class);
    return;
}

sub CLONE_SKIP ($class) { 1 }

1;

__END__

=head1 NAME

Linux::Event::HTTP::Server::Connection - HTTP/1 connection protocol state

=head1 DESCRIPTION

C<Linux::Event::HTTP::Server::Connection> owns HTTP/1 request boundaries,
request sequencing, response serialization, persistence policy, and the mapping
between a streaming response body and Linux::Event transport backpressure.
Linux::Event continues to own the socket, TLS transport, readiness, and native
ordered-byte output queue.

Each active exchange is represented by one L<Linux::Event::HTTP::Transaction>
containing the Request and Response. The existing server callback API remains
C<on_request($conn, $req, $res)>; the active Transaction is available through
C<< $conn->transaction >> when lifecycle, streaming-body, Upgrade, or CONNECT
tunnel operations are needed.

Response message completion and server output completion are intentionally
separate. C<Response-E<gt>is_complete> describes the message body; Transaction
tracks whether response output has started or finished before the Connection
advances to a pipelined request.

=head1 TRANSACTION

C<transaction> returns the currently active HTTP Transaction, or undef when no
exchange is active on the connection. During C<on_request>, C<on_body>, and
C<on_request_end> it refers to the Transaction containing the supplied Request
and Response.

For a valid server-side HTTP/1.1 CONNECT request, C<< $conn->transaction->tunnel($class) >>
accepts the tunnel and schedules handoff of the same live stream object to the
target Linux::Event stream class after the successful response head is queued.
Rejecting CONNECT requires no special API: configure an ordinary non-2xx
Response instead.

=head1 RESPONSE BODIES

A complete scalar body is configured on the Response:

    $res->header('Content-Type', 'text/plain');
    $res->body("hello\n");

When configured during an HTTP callback, the scalar body is sent automatically
after that callback returns. For a Response completed later from another event,
explicitly tell the Transaction to send the now-complete message:

    my $tx = $conn->transaction;
    $tx->response->body("later\n");
    $tx->send_response;

A streaming body is produced through the active Transaction:

    my $body = $conn->transaction->response_body(
        on_drain  => sub ($body) { ... },
        on_cancel => sub ($body) { ... },
    );

    $body->write($bytes);
    $body->complete;

The writable producer belongs to the Transaction, not the Response message. It
does not maintain a second output queue. C<write> feeds the existing
Linux::Event ordered-byte destination. Its false return preserves the normal
high-watermark contract, and C<on_drain> is driven by the connection's native
drain transition. C<on_cancel> runs if the connection disappears before the
producer completes.

HTTP request bytes are consumed by the class-level native HTTP/1 consumer
before ordinary Perl C<on_data> delivery. C<on_data> is therefore protocol-owned
and is not a Connection subclass extension point; defining it on a subclass is
invalid. Customize request handling through C<on_request>, C<on_body>, and
C<on_request_end>, and customize transport policy through C<stream_tuning> and
the supported transport lifecycle callbacks.

Connection-level C<on_drain> and C<on_close> callbacks or subclass methods remain
supported; HTTP composes its body-stream bookkeeping with those lifecycle
callbacks rather than replacing them.

=head1 REQUEST BODY STREAMING

C<on_request> runs after the validated request head is available. C<on_body>
receives decoded request-body bytes. C<on_request_end> runs when the complete
request input boundary has been consumed. The Request's C<is_complete> state is
updated at that boundary. If no response body has been sent by then, input
pauses so a later asynchronous callback may finish configuring the Response
without allowing the next request to overtake it.

=head1 SEE ALSO

L<Linux::Event::HTTP::Server>, L<Linux::Event::HTTP::Transaction>,
L<Linux::Event::HTTP::Request>, L<Linux::Event::HTTP::Response>,
L<Linux::Event::HTTP::Body::Stream>, L<Linux::Event::IO::Sock::Stream>.

=cut
