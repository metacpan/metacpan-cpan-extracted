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
    package T::HighLevelUpgradeTarget;
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

my $loop = Linux::Event::Loop->new;
my $state = {
    target_hits  => 0,
    target_input => '',
    requests     => [],
    redirect_hits => 0,
    response_hits => 0,
    upgrade_hits  => 0,
};
$T::HighLevelUpgradeTarget::STATE = $state;

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

                if ($target eq '/start') {
                    $stream->write(
                        "HTTP/1.1 302 Found\r\n" .
                        "Location: /switch\r\n" .
                        "Content-Length: 0\r\n" .
                        "\r\n"
                    );
                    next;
                }

                if ($target eq '/switch') {
                    $stream->write(
                        "HTTP/1.1 101 Switching Protocols\r\n" .
                        "Connection: Upgrade\r\n" .
                        "Upgrade: test-proto\r\n" .
                        "X-Handshake: redirected\r\n" .
                        "\r\n" .
                        "WELCOME"
                    );
                    next;
                }

                if ($target eq '/after') {
                    $stream->write(
                        "HTTP/1.1 200 OK\r\n" .
                        "Content-Length: 2\r\n" .
                        "\r\n" .
                        "OK"
                    );
                    next;
                }

                die "unexpected high-level Upgrade target $target\n";
            }
        },
    },
);

my $guard = Linux::Event::Kernel::Timer->new(
    loop => $loop,
    after => 3,
    on_timer => sub ($timer) {
        die "high-level Client Upgrade test timed out\n";
    },
);

my $client = Linux::Event::HTTP::Client->new(
    loop => $loop,
    connect_timeout => 2,
);
my $base = 'http://127.0.0.1:' . $listener->port;

my ($operation, $after_operation, $upgraded_connection);
$operation = $client->get(
    "$base/start",
    headers => [
        [ Connection => 'Upgrade' ],
        [ Upgrade    => 'test-proto' ],
    ],
    upgrade_to => 'T::HighLevelUpgradeTarget',
    max_redirects => 2,
    on_redirect => sub ($op, $tx, $res, $next_url) {
        ++$state->{redirect_hits};
        $state->{redirect_status} = $res->status;
        $state->{redirect_url} = $next_url;
        $state->{redirect_tx_complete} = $tx->is_complete ? 1 : 0;
        $state->{redirect_operation_same}
            = refaddr($op) == refaddr($operation) ? 1 : 0;
    },
    on_response => sub ($tx, $res) {
        ++$state->{response_hits};
        $state->{final_status} = $res->status;
        $state->{handshake} = $res->header('X-Handshake');
    },
    on_upgrade => sub ($op, $tx, $res, $connection) {
        ++$state->{upgrade_hits};
        $upgraded_connection = $connection;
        $state->{operation_complete_at_upgrade}
            = $op->is_complete ? 1 : 0;
        $state->{tx_complete_at_upgrade}
            = $tx->is_complete ? 1 : 0;
        $state->{upgrade_status} = $res->status;
        $state->{upgrade_class} = ref($connection);
        $state->{upgrade_client_ref} = refaddr($connection);
    },
    on_complete => sub ($tx) {
        $state->{first_complete_hits}++;
        $state->{first_complete_tx} = $tx->is_complete ? 1 : 0;

        $after_operation = $client->get(
            "$base/after",
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
                die "ordinary request after Upgrade failed: $error\n";
            },
        );
    },
    on_error => sub ($tx, $error) {
        die "high-level Client Upgrade failed: $error\n";
    },
);

isa_ok($operation, 'Linux::Event::HTTP::Client::Operation');
$loop->run;

is($state->{redirect_hits}, 1, 'one redirect hop is reported');
is($state->{redirect_status}, 302, 'redirect callback receives intermediate 302');
is($state->{redirect_url}, "$base/switch",
    'relative Upgrade redirect resolves against the current URL');
ok($state->{redirect_tx_complete},
    'redirect Transaction is complete before the next Upgrade hop');
ok($state->{redirect_operation_same},
    'redirect callback receives the original Client operation');

is($state->{response_hits}, 1,
    'on_response remains final-only and sees only the 101 response');
is($state->{final_status}, 101, 'final response is the switching response');
is($state->{handshake}, 'redirected', 'final 101 metadata remains available');
is($state->{upgrade_hits}, 1, 'high-level on_upgrade runs once');
ok($state->{operation_complete_at_upgrade},
    'Client operation is complete before high-level on_upgrade');
ok($state->{tx_complete_at_upgrade},
    'final Transaction is complete before high-level on_upgrade');
is($state->{upgrade_status}, 101, 'on_upgrade receives the 101 Response');
is($state->{upgrade_class}, 'T::HighLevelUpgradeTarget',
    'on_upgrade receives the transitioned target class');
is($state->{first_complete_hits}, 1,
    'ordinary on_complete follows the successful Upgrade callback');
ok($state->{first_complete_tx}, 'on_complete receives the completed final Transaction');

is($operation->transaction_count, 2,
    'redirected Upgrade operation retains both HTTP Transactions');
is($operation->redirect_count, 1,
    'redirected Upgrade operation records one redirect');
ok($operation->is_complete, 'Upgrade operation remains successfully complete');
is($operation->response->status, 101,
    'Operation final Response remains the 101 handshake message');

is($state->{target_hits}, 1,
    'target protocol receives bytes already read after the 101 head');
is($state->{target_input}, 'WELCOME',
    'same-read post-101 bytes survive the high-level handoff');
is($state->{target_class}, 'T::HighLevelUpgradeTarget',
    'post-101 bytes are delivered under the target protocol class');
is($state->{target_ref}, $state->{upgrade_client_ref},
    'target protocol and on_upgrade observe the same client stream object');

is(scalar @{$state->{requests}}, 3,
    'server observes redirect hop, Upgrade hop, and later ordinary request');
my ($start, $switch, $after) = @{$state->{requests}};
is($start->{target}, '/start', 'first wire request uses redirect source target');
is($switch->{target}, '/switch', 'second wire request uses redirected Upgrade target');
is($after->{target}, '/after', 'third wire request is ordinary HTTP');
is($start->{stream}, $switch->{stream},
    'same reusable HTTP connection carries the redirect and Upgrade hops');
isnt($after->{stream}, $switch->{stream},
    'ordinary request after Upgrade uses a different HTTP connection');

for my $request ($start, $switch) {
    my $connection = join(',', @{$request->{header}{connection} // []});
    my $upgrade = join(',', @{$request->{header}{upgrade} // []});
    like(lc($connection), qr/(?:^|,\s*)upgrade(?:,|$)/,
        'Upgrade hop advertises Connection: Upgrade');
    is(lc($upgrade), 'test-proto',
        'Upgrade protocol offer is present on each redirect hop');
}
ok(!exists($after->{header}{upgrade}),
    'later ordinary HTTP request does not inherit Upgrade headers');

is($state->{after_body}, 'OK',
    'ordinary request after Upgrade receives its response normally');
ok($state->{after_complete},
    'ordinary Transaction after Upgrade completes successfully');
isa_ok($after_operation, 'Linux::Event::HTTP::Client::Operation');
ok($after_operation->is_complete,
    'ordinary operation after Upgrade completes successfully');

ok($upgraded_connection,
    'application retains the transitioned connection returned by on_upgrade');

done_testing;
