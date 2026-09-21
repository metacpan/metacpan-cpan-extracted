#!/usr/bin/env perl
use v5.36;
use strict;
use warnings;

use Linux::Event::Loop;
use Linux::Event::HTTP::Server::Connection;
use Linux::Event::HTTP::Server;

my $port = $ENV{BENCH_PORT} // die "BENCH_PORT is required\n";
my $response_bytes = $ENV{BENCH_RESPONSE_BYTES} // 32;
my $mode = $ENV{BENCH_LINUXEVENT_MODE} // 'natural';
our $READ_BUDGET_BYTES = 0 + ($ENV{BENCH_READ_BUDGET_BYTES} // 0);
my $payload = 'x' x $response_bytes;

{
    package Linux::Event::HTTP::Bench::LegacyCallbackCompareConnection;
    use parent 'Linux::Event::HTTP::Server::Connection';

    sub stream_tuning ($class) {
        return read_budget_bytes => $main::READ_BUDGET_BYTES;
    }

    sub on_request ($self, $request, $response) {
        $response->body($self->data->{payload});
        return;
    }

    sub _invoke_http_callback ($self, $handler, $request, $response, @extra) {
        return 1 if !$handler;

        my $ok;
        {
            local $self->{_http_dispatching} = 1;
            $ok = eval {
                $handler->($self, $request, $response, @extra);
                1;
            };
        }

        if (!$ok) {
            $self->_fail_active_transaction(500, $request, $response);
            return 0;
        }

        my $ready = eval {
            $self->_response_body_ready($response);
            1;
        };
        if (!$ready) {
            $self->_fail_active_transaction(500, $request, $response);
            return 0;
        }

        return 1;
    }
}

{
    package Linux::Event::HTTP::Bench::LegacyEligibilityCompareConnection;
    use parent 'Linux::Event::HTTP::Server::Connection';
    use Scalar::Util qw(refaddr);

    sub stream_tuning ($class) {
        return read_budget_bytes => $main::READ_BUDGET_BYTES;
    }

    sub on_request ($self, $request, $response) {
        $response->body($self->data->{payload});
        return;
    }

    sub _try_native_default_final ($self, $transaction, $body) {
        my $response = $transaction->response or return 0;
        return 0 if ref($response) ne 'Linux::Event::HTTP::Response';
        return 0 if $response->status != 200 || defined($response->reason);
        return 0 if $response->header_count;
        return 0 if $self->{_http_closing} || $self->is_closed;
        return 0 if $self->{_http_response_state};

        my $active = $self->{_http_active_transaction} or return 0;
        return 0 if refaddr($active) != refaddr($transaction);

        my $request = $transaction->request or return 0;
        my $request_state = $self->{_http_request_state} or return 0;
        return 0 if !$request_state->{body_done};

        my $wire = Linux::Event::HTTP::_HTTP1
            ->build_default_final($request, $body);
        return 0 if !defined $wire;

        $response->_commit;
        $transaction->_mark_response_started;
        $transaction->_mark_response_output_complete;
        $self->{_http_response_state} = undef;

        $self->write($wire);
        $self->_complete_active_transaction_state;
        $self->_clear_transaction;

        $self->resume_read if $self->is_read_paused;
        return 1;
    }
}

{
    package Linux::Event::HTTP::Bench::LegacyReadyCompareConnection;
    use parent 'Linux::Event::HTTP::Server::Connection';
    use Scalar::Util qw(refaddr);

    sub stream_tuning ($class) {
        return read_budget_bytes => $main::READ_BUDGET_BYTES;
    }

    sub on_request ($self, $request, $response) {
        $response->body($self->data->{payload});
        return;
    }

    sub _response_body_ready ($self, $response) {
        return if !$response || !$response->_has_scalar_body;
        return if $self->{_http_dispatching};

        my $transaction = $self->{_http_active_transaction} or return;
        return if $transaction->_is_response_output_complete;
        my $active = $transaction->response;
        return if !$active || refaddr($active) != refaddr($response);

        $self->_send_http_response($transaction);
        return;
    }
}

{
    package Linux::Event::HTTP::Bench::ContentTypeCompareConnection;
    use parent 'Linux::Event::HTTP::Server::Connection';

    sub stream_tuning ($class) {
        return read_budget_bytes => $main::READ_BUDGET_BYTES;
    }

    sub on_request ($self, $request, $response) {
        $response->header('Content-Type', 'application/octet-stream');
        $response->body($self->data->{payload});
        return;
    }
}

{
    package Linux::Event::HTTP::Bench::NaturalCompareConnection;
    use parent 'Linux::Event::HTTP::Server::Connection';

    sub stream_tuning ($class) {
        return read_budget_bytes => $main::READ_BUDGET_BYTES;
    }

    sub on_request ($self, $request, $response) {
        $response->body($self->data->{payload});
        return;
    }
}

{
    package Linux::Event::HTTP::Bench::RequestEndCompareConnection;
    use parent 'Linux::Event::HTTP::Server::Connection';

    sub stream_tuning ($class) {
        return read_budget_bytes => $main::READ_BUDGET_BYTES;
    }

    sub on_request ($self, $request, $response) {
        return;
    }

    sub on_request_end ($self, $request, $response) {
        $response->body($self->data->{payload});
        return;
    }
}

{
    package Linux::Event::HTTP::Bench::BodyIgnoreCompareConnection;
    use parent 'Linux::Event::HTTP::Server::Connection';

    sub stream_tuning ($class) {
        return read_budget_bytes => $main::READ_BUDGET_BYTES;
    }

    sub on_request ($self, $request, $response) {
        $response->header('Content-Type', 'application/octet-stream');
        $response->body($self->data->{payload});
        return;
    }
}

{
    package Linux::Event::HTTP::Bench::BodyCallbackCompareConnection;
    use parent -norequire, 'Linux::Event::HTTP::Bench::BodyIgnoreCompareConnection';

    sub on_body ($self, $request, $response, $bytes) {
        return;
    }
}

{
    package Linux::Event::HTTP::Bench::BodyEndCompareConnection;
    use parent 'Linux::Event::HTTP::Server::Connection';

    sub stream_tuning ($class) {
        return read_budget_bytes => $main::READ_BUDGET_BYTES;
    }

    sub on_request ($self, $request, $response) {
        return;
    }

    sub on_request_end ($self, $request, $response) {
        $response->header('Content-Type', 'application/octet-stream');
        $response->body($self->data->{payload});
        return;
    }
}

{
    package Linux::Event::HTTP::Bench::BodyCallbackEndCompareConnection;
    use parent -norequire, 'Linux::Event::HTTP::Bench::BodyEndCompareConnection';

    sub on_body ($self, $request, $response, $bytes) {
        return;
    }
}

my $connection_class = $mode eq 'natural'
    ? 'Linux::Event::HTTP::Bench::NaturalCompareConnection'
    : $mode eq 'content-type'
        ? 'Linux::Event::HTTP::Bench::ContentTypeCompareConnection'
    : $mode eq 'body-ignore'
        ? 'Linux::Event::HTTP::Bench::BodyIgnoreCompareConnection'
    : $mode eq 'body-callback'
        ? 'Linux::Event::HTTP::Bench::BodyCallbackCompareConnection'
    : $mode eq 'body-end'
        ? 'Linux::Event::HTTP::Bench::BodyEndCompareConnection'
    : $mode eq 'body-callback-end'
        ? 'Linux::Event::HTTP::Bench::BodyCallbackEndCompareConnection'
    : $mode eq 'legacy-ready'
        ? 'Linux::Event::HTTP::Bench::LegacyReadyCompareConnection'
        : $mode eq 'legacy-eligibility'
            ? 'Linux::Event::HTTP::Bench::LegacyEligibilityCompareConnection'
    : $mode eq 'legacy-callback'
        ? 'Linux::Event::HTTP::Bench::LegacyCallbackCompareConnection'
        : $mode eq 'request-end'
            ? 'Linux::Event::HTTP::Bench::RequestEndCompareConnection'
            : die "unknown BENCH_LINUXEVENT_MODE: $mode\n";

my $loop = Linux::Event::Loop->new;
my $server = Linux::Event::HTTP::Server->new(
    loop             => $loop,
    host             => '127.0.0.1',
    port             => 0 + $port,
    data             => { payload => $payload },
    connection_class => $connection_class,
);

$loop->run;
