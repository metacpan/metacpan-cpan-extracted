#!/usr/bin/env perl
use v5.36;
use strict;
use warnings;

use Linux::Event::Loop;
use Linux::Event::IO::Sock::Listener;
use Linux::Event::HTTP::Server::Connection;
use Linux::Event::HTTP::Response;
use Linux::Event::HTTP::Transaction;
use Linux::Event::HTTP::_HTTP1 ();

my $port = $ENV{BENCH_PORT} // die "BENCH_PORT is required\n";
my $response_bytes = 0 + ($ENV{BENCH_RESPONSE_BYTES} // 32);
our $READ_BUDGET_BYTES = 0 + ($ENV{BENCH_READ_BUDGET_BYTES} // 0);
our $STAGE = $ENV{BENCH_TRANSACTION_STAGE} // die "BENCH_TRANSACTION_STAGE is required\n";
die "unknown BENCH_TRANSACTION_STAGE=$STAGE\n"
    if $STAGE !~ /\A(?:parse|bound|state|callbacks|fused|eligibility|build|mark|commit|complete|checked|bodyless)\z/;

my $payload = 'x' x $response_bytes;
my $wire = "HTTP/1.1 200 OK\r\nContent-Length: $response_bytes\r\n\r\n$payload";

{
    package Linux::Event::HTTP::Bench::TransactionStageConnection;
    use parent 'Linux::Event::HTTP::Server::Connection';
    use Scalar::Util qw(refaddr);

    my $PARSER = 'Linux::Event::HTTP::_HTTP1';
    my $MAX_HEADERS = 100;
    my $MAX_REQUEST_HEAD = 65_536;
    my $NOOP = sub ($connection, $request, $response) { return };
    my $COMPLETE = sub ($connection, $request, $response) {
        $response->body($connection->data->{payload});
        return;
    };

    sub stream_tuning ($class) {
        return read_budget_bytes => $main::READ_BUDGET_BYTES;
    }

    sub on_request ($self, $request, $response) {
        $response->body($self->data->{payload})
            if $main::STAGE eq 'bodyless';
        return;
    }

    sub _new_bench_transaction ($self, $request, $response) {
        my $transaction = Linux::Event::HTTP::Transaction->_new(
            request    => $request,
            controller => $self,
        );
        $transaction->_set_response($response);
        $transaction->_activate;
        return $transaction;
    }

    sub _bodyless_state ($self, $request) {
        my $state = $self->{_http_bodyless_state} //= {
            mode      => 'none',
            body_done => 0,
        };
        $state->{body_done} = 1;
        delete $state->{close_after_response};
        $request->_mark_complete;
        return $state;
    }

    sub native_default_context ($self, $response) {
        return if ref($response) ne 'Linux::Event::HTTP::Response';
        return if $response->status != 200 || defined($response->reason);
        return if $response->header_count;
        return if $self->{_http_closing} || $self->is_closed;
        return if $self->{_http_response_state};

        my $transaction = $self->{_http_active_transaction} or return;
        my $active = $transaction->response or return;
        return if refaddr($active) != refaddr($response);

        my $request = $transaction->request or return;
        my $request_state = $self->{_http_request_state} or return;
        return if !$request_state->{body_done};
        return $request;
    }

    sub on_data ($self, $bytes) {
        return $self->SUPER::on_data($bytes)
            if $main::STAGE eq 'bodyless';

        $self->{_bench_input} = '' if !defined $self->{_bench_input};
        $self->{_bench_input} .= $bytes;

        while (length($self->{_bench_input})) {
            my $request;
            if ($main::STAGE eq 'checked') {
                my $parsed = eval {
                    $request = $PARSER->parse_request(
                        $self->{_bench_input}, 0, $MAX_HEADERS,
                    );
                    1;
                };
                if (!$parsed) {
                    my $failure = "$@";
                    my $status = $failure =~ /semantic error \(501\)/ ? 501 : 400;
                    $self->_protocol_error($status);
                    last;
                }
                if (!defined $request) {
                    if (length($self->{_bench_input}) > $MAX_REQUEST_HEAD) {
                        $self->_protocol_error(431);
                    }
                    last;
                }
            } else {
                $request = $PARSER->parse_request(
                    $self->{_bench_input}, 0, $MAX_HEADERS,
                );
                last if !defined $request;
            }

            my $consumed = $request->_consumed;
            if ($main::STAGE eq 'checked' && $consumed > $MAX_REQUEST_HEAD) {
                $self->_protocol_error(431, $request->version);
                last;
            }
            substr($self->{_bench_input}, 0, $consumed, '');

            my $expect = 0;
            if ($main::STAGE eq 'checked') {
                $expect = Linux::Event::HTTP::Server::Connection::_expect_continue(
                    $request,
                );
                if ($expect < 0) {
                    $self->_protocol_error(417, $request->version);
                    last;
                }
            }

            if ($main::STAGE eq 'parse') {
                $self->write($self->data->{wire});
                next;
            }

            my $response = Linux::Event::HTTP::Response->new(
                version => $request->version,
            );

            if ($main::STAGE eq 'bound') {
                $self->write($self->data->{wire});
                next;
            }

            my $transaction = $self->_new_bench_transaction(
                $request, $response,
            );

            my $body_mode = $request->_http1_body_mode;
            die "bodyless benchmark unexpectedly parsed $body_mode request\n"
                if $body_mode ne 'none';
            my $request_state = $self->_bodyless_state($request);

            $self->{_http_active_transaction} = $transaction;
            $self->{_http_active_request} = $request;
            $self->{_http_active_response} = $response;
            $self->{_http_request_state} = $request_state;
            $self->{_http_response_state} = undef;

            if ($expect
                && Linux::Event::HTTP::Server::Connection::_body_pending(
                    $request_state,
                )) {
                $self->write("HTTP/1.1 100 Continue\r\n\r\n");
            }

            if ($main::STAGE eq 'state') {
                Linux::Event::HTTP::Server::Connection::_clear_transaction($self);
                $self->write($self->data->{wire});
                next;
            }

            my $handler
                = ($main::STAGE eq 'complete' || $main::STAGE eq 'checked')
                ? $COMPLETE : $NOOP;
            if ($main::STAGE eq 'callbacks'
                || $main::STAGE eq 'complete'
                || $main::STAGE eq 'checked') {
                last if !$self->_invoke_http_callback(
                    $NOOP, $request, $response,
                );
                last if $self->{_http_closing} || $self->is_closed;
                next if !$self->{_http_active_request};
                last if !$self->_invoke_http_callback(
                    $handler, $request, $response,
                );
                last if $self->{_http_closing} || $self->is_closed;
                next if !$self->{_http_active_request};
            } else {
                my $ok;
                {
                    local $self->{_http_dispatching} = 1;
                    $ok = eval {
                        $NOOP->($self, $request, $response);
                        $handler->($self, $request, $response);
                        1;
                    };
                }
                if (!$ok) {
                    $self->_fail_active_transaction(
                        500, $request, $response,
                    );
                    last;
                }
            }

            if ($main::STAGE eq 'callbacks') {
                Linux::Event::HTTP::Server::Connection::_clear_transaction($self);
                $self->write($self->data->{wire});
                next;
            }

            if ($main::STAGE eq 'fused') {
                Linux::Event::HTTP::Server::Connection::_clear_transaction($self);
                $self->write($self->data->{wire});
                next;
            }

            if ($main::STAGE eq 'complete' || $main::STAGE eq 'checked') {
                die "guarded public Response body did not finalize transaction\n"
                    if $self->{_http_active_transaction};
                next;
            }

            my $native_request = $self->native_default_context($response)
                or die "native default response unexpectedly ineligible\n";

            if ($main::STAGE eq 'eligibility') {
                Linux::Event::HTTP::Server::Connection::_clear_transaction($self);
                $self->write($self->data->{wire});
                next;
            }

            my $native_wire = Linux::Event::HTTP::_HTTP1
                ->build_default_final(
                    $native_request, $self->data->{payload},
                );
            die "native default response build unexpectedly failed\n"
                if !defined $native_wire;

            if ($main::STAGE eq 'build') {
                Linux::Event::HTTP::Server::Connection::_clear_transaction($self);
                $self->write($native_wire);
                next;
            }

            $response->body($self->data->{payload});
            $response->_commit;
            $transaction->_mark_response_started;
            $transaction->_mark_response_output_complete;
            $self->{_http_response_state} = undef;

            if ($main::STAGE eq 'mark') {
                Linux::Event::HTTP::Server::Connection::_clear_transaction($self);
                $self->write($native_wire);
                next;
            }

            $self->write($native_wire);
            $self->_complete_active_transaction_state;
            $self->_clear_transaction;
            $self->resume_read if $self->is_read_paused;
        }
        return;
    }
}

my $loop = Linux::Event::Loop->new;
my $server = Linux::Event::IO::Sock::Listener->new(
    loop => $loop,
    host => '127.0.0.1',
    port => 0 + $port,
    stream => {
        class => 'Linux::Event::HTTP::Bench::TransactionStageConnection',
        data  => {
            wire    => $wire,
            payload => $payload,
        },
    },
);

$loop->run;
