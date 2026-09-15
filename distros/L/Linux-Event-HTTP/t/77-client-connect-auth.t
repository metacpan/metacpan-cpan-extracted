use v5.36;
use strict;
use warnings;

use Test::More;
use Scalar::Util qw(refaddr);
use Uniform::HTTP::Auth;

use Linux::Event::HTTP::Client;
use Linux::Event::IO::Sock::Listener;
use Linux::Event::IO::Sock::Stream;
use Linux::Event::Kernel::Timer;
use Linux::Event::Loop;

{
    package T::AuthenticatedTunnelTarget;
    use parent 'Linux::Event::IO::Sock::Stream';
    use Scalar::Util qw(refaddr);

    our $STATE;

    sub on_data ($self, $bytes) {
        $STATE->{target_input} .= $bytes;
        $STATE->{target_ref} = refaddr($self);
    }
}

subtest 'connect_tunnel retries 407 with Uniform proxy authentication' => sub {
    my $loop = Linux::Event::Loop->new;
    my $state = {
        requests => [],
        response_hits => 0,
        tunnel_hits => 0,
        target_input => '',
    };
    $T::AuthenticatedTunnelTarget::STATE = $state;
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
                    my ($method, $target) = split / /, $request_line, 3;
                    my %header;
                    for my $line (@field) {
                        next if $line eq '';
                        my ($name, $value) = split /:\s*/, $line, 2;
                        push @{$header{lc $name}}, $value;
                    }

                    push @{$state->{requests}}, {
                        stream => $id,
                        method => $method,
                        target => $target,
                        header => \%header,
                    };

                    if (!defined $header{'proxy-authorization'}) {
                        $stream->write(
                            "HTTP/1.1 407 Proxy Authentication Required\r\n" .
                            "Proxy-Authenticate: Basic realm=\"Proxy\"\r\n" .
                            "Content-Length: 0\r\n" .
                            "Connection: keep-alive\r\n" .
                            "\r\n"
                        );
                        next;
                    }

                    $stream->write(
                        "HTTP/1.1 200 Connection Established\r\n" .
                        "\r\n" .
                        "READY"
                    );
                }
            },
        },
    );

    my $proxy_url = 'http://127.0.0.1:' . $listener->port;
    my $proxy_auth = Uniform::HTTP::Auth->new(
        origin => $proxy_url,
        schemes => ['basic'],
        credentials => {
            username => 'proxy-user',
            password => 'secret',
        },
    );
    my $client = Linux::Event::HTTP::Client->new(
        loop => $loop,
        proxy_auth => $proxy_auth,
        max_auth_retries => 2,
    );

    my $guard = Linux::Event::Kernel::Timer->new(
        loop => $loop,
        after => 3,
        on_timer => sub ($timer) {
            die "authenticated CONNECT test timed out\n";
        },
    );

    my ($operation, $tunnel_connection);
    $operation = $client->connect_tunnel(
        $proxy_url,
        'target.example:443',
        tunnel_to => 'T::AuthenticatedTunnelTarget',
        on_response => sub ($tx, $res) {
            ++$state->{response_hits};
            $state->{final_status} = $res->status;
        },
        on_tunnel => sub ($op, $tx, $res, $connection) {
            ++$state->{tunnel_hits};
            $tunnel_connection = $connection;
            $state->{tunnel_ref} = refaddr($connection);
            $state->{operation_complete_at_tunnel} = $op->is_complete ? 1 : 0;
        },
        on_complete => sub ($tx) {
            $guard->cancel;
            $client->close;
            $listener->close;
            $loop->stop;
        },
        on_error => sub ($tx, $error) {
            die "authenticated CONNECT failed: $error\n";
        },
    );

    $loop->run;

    is($operation->transaction_count, 2,
        '407 retry creates a second CONNECT Transaction');
    is($operation->auth_retry_count, 1,
        'CONNECT Operation records one authentication retry');
    is($operation->redirect_count, 0,
        'CONNECT authentication does not count as redirect');
    ok($operation->is_complete, 'authenticated CONNECT operation completes');
    is($state->{response_hits}, 1,
        'on_response sees only successful CONNECT response');
    is($state->{final_status}, 200, 'final CONNECT response is successful');
    is($state->{tunnel_hits}, 1, 'on_tunnel runs once');
    ok($state->{operation_complete_at_tunnel},
        'Operation is complete before on_tunnel');

    is(scalar @{$state->{requests}}, 2,
        'proxy sees initial and authenticated CONNECT attempts');
    my ($initial, $retry) = @{$state->{requests}};
    ok(!defined $initial->{header}{'proxy-authorization'},
        'initial CONNECT is not preemptively authenticated');
    like($retry->{header}{'proxy-authorization'}[0] // '', qr/\ABasic /,
        'retry carries generated Proxy-Authorization');
    is($initial->{stream}, $retry->{stream},
        'completed 407 response permits proxy connection reuse for retry');
    is($retry->{target}, 'target.example:443',
        'authenticated retry preserves CONNECT authority target');

    is($state->{target_input}, 'READY',
        'post-2xx bytes survive authenticated CONNECT handoff');
    is($state->{target_ref}, $state->{tunnel_ref},
        'target protocol and on_tunnel observe the same live stream');
    ok($tunnel_connection, 'application retains transitioned tunnel connection');
};

done_testing;
