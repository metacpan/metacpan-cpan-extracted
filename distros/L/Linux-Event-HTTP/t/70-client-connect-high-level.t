use v5.36;
use strict;
use warnings;

use Test::More;
use Scalar::Util qw(refaddr);

use Linux::Event::HTTP::Client;
use Linux::Event::IO::Sock::Listener;
use Linux::Event::IO::Sock::Stream;
use Linux::Event::Kernel::Timer;
use Linux::Event::Loop;

{
    package T::HighLevelTunnelTarget;
    use parent 'Linux::Event::IO::Sock::Stream';
    use Scalar::Util qw(refaddr);

    our $STATE;

    sub on_data ($self, $bytes) {
        $STATE->{target_hits}++;
        $STATE->{target_input} .= $bytes;
        $STATE->{target_class} = ref($self);
        $STATE->{target_ref} = refaddr($self);
    }
}

subtest 'connect_tunnel separates proxy endpoint from tunnel target and leaves HTTP pool' => sub {
    my $loop = Linux::Event::Loop->new;
    my $state = {
        target_hits   => 0,
        target_input  => '',
        requests      => [],
        response_hits => 0,
        tunnel_hits   => 0,
    };
    $T::HighLevelTunnelTarget::STATE = $state;

    my %input;
    my $listener = Linux::Event::IO::Sock::Listener->new(
        loop => $loop,
        host => '127.0.0.1',
        port => 0,
        stream => {
            on_data => sub ($stream, $bytes) {
                my $id = refaddr($stream);
                $input{$id} .= $bytes;

                while ((my $end = index($input{$id}, "\r\n\r\n")) >= 0) {
                    my $head = substr($input{$id}, 0, $end + 4, '');
                    my ($request_line, @field) = split /\r\n/, $head;
                    my ($method, $target, $version)
                        = split / /, $request_line, 3;

                    my %header;
                    for my $line (@field) {
                        next if $line eq '';
                        my ($name, $value) = split /:\s*/, $line, 2;
                        push @{$header{lc $name}}, $value;
                    }

                    push @{$state->{requests}}, {
                        stream  => $id,
                        method  => $method,
                        target  => $target,
                        version => $version,
                        header  => \%header,
                    };

                    if ($method eq 'CONNECT') {
                        $stream->write(
                            "HTTP/1.1 200 Connection Established\r\n" .
                            "X-Proxy: ready\r\n" .
                            "\r\n" .
                            "READY"
                        );
                        next;
                    }

                    if ($target eq '/after') {
                        $stream->write(
                            "HTTP/1.1 200 OK\r\n" .
                            "Content-Length: 2\r\n" .
                            "Connection: close\r\n" .
                            "\r\n" .
                            "OK"
                        );
                        next;
                    }

                    die "unexpected high-level CONNECT request $request_line\n";
                }
            },
        },
    );

    my $guard = Linux::Event::Kernel::Timer->new(
        loop => $loop,
        after => 3,
        on_timer => sub ($timer) {
            die "high-level Client CONNECT test timed out\n";
        },
    );

    my $client = Linux::Event::HTTP::Client->new(
        loop => $loop,
        connect_timeout => 2,
    );
    my $proxy = 'http://127.0.0.1:' . $listener->port;

    my ($operation, $after_operation, $tunnel_connection);
    $operation = $client->connect_tunnel(
        $proxy,
        'target.example:8443',
        tunnel_to => 'T::HighLevelTunnelTarget',
        headers => [
            [ 'Proxy-Authorization' => 'Basic test' ],
        ],
        on_response => sub ($tx, $res) {
            ++$state->{response_hits};
            $state->{status} = $res->status;
            $state->{proxy_header} = $res->header('X-Proxy');
        },
        on_tunnel => sub ($op, $tx, $res, $connection) {
            ++$state->{tunnel_hits};
            $tunnel_connection = $connection;
            $state->{operation_complete_at_tunnel}
                = $op->is_complete ? 1 : 0;
            $state->{tx_complete_at_tunnel}
                = $tx->is_complete ? 1 : 0;
            $state->{tunnel_class} = ref($connection);
            $state->{tunnel_ref} = refaddr($connection);
        },
        on_complete => sub ($tx) {
            $state->{first_complete_hits}++;
            $state->{first_complete_tx} = $tx->is_complete ? 1 : 0;

            $after_operation = $client->get(
                "$proxy/after",
                on_body => sub ($after_tx, $res, $bytes) {
                    $state->{after_body} .= $bytes;
                },
                on_complete => sub ($after_tx) {
                    $state->{after_complete} = $after_tx->is_complete ? 1 : 0;
                    $guard->cancel;
                    $client->close;
                    $listener->close;
                    $loop->stop;
                },
                on_error => sub ($after_tx, $error) {
                    die "ordinary request after CONNECT failed: $error\n";
                },
            );
        },
        on_error => sub ($tx, $error) {
            die "high-level Client CONNECT failed: $error\n";
        },
    );

    isa_ok($operation, 'Linux::Event::HTTP::Client::Operation');
    $loop->run;

    is($operation->transaction_count, 1,
        'CONNECT operation contains exactly one HTTP Transaction');
    is($operation->redirect_count, 0,
        'CONNECT operation does not apply redirect policy');
    is($operation->initial_url, $proxy,
        'CONNECT operation records the proxy endpoint URL');
    is($operation->request->target, 'target.example:8443',
        'CONNECT Request retains the distinct tunnel authority');
    ok($operation->is_complete, 'CONNECT operation remains complete after handoff');

    is($state->{response_hits}, 1, 'on_response sees the successful CONNECT response');
    is($state->{status}, 200, 'CONNECT response status is preserved');
    is($state->{proxy_header}, 'ready', 'CONNECT response metadata remains available');
    is($state->{tunnel_hits}, 1, 'high-level on_tunnel runs once');
    ok($state->{operation_complete_at_tunnel},
        'Client operation is complete before high-level on_tunnel');
    ok($state->{tx_complete_at_tunnel},
        'CONNECT Transaction is complete before high-level on_tunnel');
    is($state->{tunnel_class}, 'T::HighLevelTunnelTarget',
        'on_tunnel receives the transitioned target class');
    is($state->{first_complete_hits}, 1,
        'ordinary on_complete follows successful tunnel handoff');
    ok($state->{first_complete_tx},
        'on_complete receives the completed CONNECT Transaction');

    is($state->{target_hits}, 1,
        'tunnel target receives bytes already read after the 2xx head');
    is($state->{target_input}, 'READY',
        'same-read post-CONNECT bytes survive the high-level handoff');
    is($state->{target_class}, 'T::HighLevelTunnelTarget',
        'post-head bytes are delivered under the target tunnel class');
    is($state->{target_ref}, $state->{tunnel_ref},
        'target protocol and on_tunnel observe the same live stream object');

    is(scalar @{$state->{requests}}, 2,
        'proxy observes CONNECT and one later ordinary HTTP request');
    my ($connect, $after) = @{$state->{requests}};
    is($connect->{method}, 'CONNECT', 'first wire request uses CONNECT');
    is($connect->{target}, 'target.example:8443',
        'CONNECT wire target is independent from proxy endpoint');
    is($connect->{header}{host}[0], 'target.example:8443',
        'CONNECT Host is synthesized from tunnel target');
    is($connect->{header}{'proxy-authorization'}[0], 'Basic test',
        'caller-supplied Proxy-Authorization reaches the proxy');
    isnt($after->{stream}, $connect->{stream},
        'ordinary request after tunnel handoff uses another HTTP connection');
    is($after->{target}, '/after', 'later HTTP request uses ordinary origin-form target');

    is($state->{after_body}, 'OK',
        'ordinary request after CONNECT receives its response normally');
    ok($state->{after_complete},
        'ordinary Transaction after CONNECT completes successfully');
    isa_ok($after_operation, 'Linux::Event::HTTP::Client::Operation');
    ok($after_operation->is_complete,
        'ordinary operation after CONNECT completes successfully');
    ok($tunnel_connection,
        'application retains the transitioned connection returned by on_tunnel');
};

subtest 'non-2xx connect_tunnel returns proxy connection to the HTTP pool' => sub {
    my $loop = Linux::Event::Loop->new;
    my $state = { requests => [], tunnel_hits => 0 };
    my %input;

    my $listener = Linux::Event::IO::Sock::Listener->new(
        loop => $loop,
        host => '127.0.0.1',
        port => 0,
        stream => {
            on_data => sub ($stream, $bytes) {
                my $id = refaddr($stream);
                $input{$id} .= $bytes;

                while ((my $end = index($input{$id}, "\r\n\r\n")) >= 0) {
                    my $head = substr($input{$id}, 0, $end + 4, '');
                    my ($request_line) = split /\r\n/, $head;
                    my ($method, $target) = split / /, $request_line, 3;
                    push @{$state->{requests}}, {
                        stream => $id,
                        method => $method,
                        target => $target,
                    };

                    if ($method eq 'CONNECT') {
                        $stream->write(
                            "HTTP/1.1 407 Proxy Authentication Required\r\n" .
                            "Content-Length: 4\r\n" .
                            "Connection: keep-alive\r\n" .
                            "\r\n" .
                            "nope"
                        );
                        next;
                    }

                    $stream->write(
                        "HTTP/1.1 200 OK\r\n" .
                        "Content-Length: 2\r\n" .
                        "Connection: close\r\n" .
                        "\r\n" .
                        "OK"
                    );
                }
            },
        },
    );

    my $guard = Linux::Event::Kernel::Timer->new(
        loop => $loop,
        after => 3,
        on_timer => sub ($timer) {
            die "high-level rejected CONNECT pool test timed out\n";
        },
    );

    my $client = Linux::Event::HTTP::Client->new(loop => $loop);
    my $proxy = 'http://127.0.0.1:' . $listener->port;
    my ($operation, $after_operation);

    $operation = $client->connect_tunnel(
        $proxy,
        'target.example:443',
        tunnel_to => 'T::HighLevelTunnelTarget',
        buffer_body => 64,
        on_tunnel => sub ($op, $tx, $res, $connection) {
            ++$state->{tunnel_hits};
        },
        on_complete => sub ($tx) {
            $state->{first_status} = $tx->response->status;
            $state->{first_body} = $tx->response->body;
            $state->{operation_complete} = $operation->is_complete ? 1 : 0;

            $after_operation = $client->get(
                "$proxy/reuse",
                on_body => sub ($after_tx, $res, $bytes) {
                    $state->{after_body} .= $bytes;
                },
                on_complete => sub ($after_tx) {
                    $guard->cancel;
                    $client->close;
                    $listener->close;
                    $loop->stop;
                },
                on_error => sub ($after_tx, $error) {
                    die "request after rejected high-level CONNECT failed: $error\n";
                },
            );
        },
        on_error => sub ($tx, $error) {
            die "rejected high-level CONNECT unexpectedly failed: $error\n";
        },
    );

    $loop->run;

    is($state->{first_status}, 407, 'proxy rejection is an ordinary final response');
    is($state->{first_body}, 'nope', 'buffer_body captures non-2xx proxy response body');
    is($state->{tunnel_hits}, 0, 'proxy rejection does not invoke on_tunnel');
    ok($state->{operation_complete}, 'rejected CONNECT operation completes normally');
    is(scalar @{$state->{requests}}, 2,
        'proxy sees rejected CONNECT followed by ordinary request');
    is($state->{requests}[0]{stream}, $state->{requests}[1]{stream},
        'persistent proxy connection is reused after non-2xx CONNECT');
    is($state->{after_body}, 'OK', 'reused proxy connection still parses ordinary HTTP');
    isa_ok($after_operation, 'Linux::Event::HTTP::Client::Operation');
    ok($after_operation->is_complete,
        'ordinary operation after rejected CONNECT completes');
};

done_testing;
