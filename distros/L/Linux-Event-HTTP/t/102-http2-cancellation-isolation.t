use v5.36;
use strict;
use warnings;

use Test::More;
use File::Spec;
use File::Temp qw(tempdir);
use Scalar::Util qw(refaddr);

BEGIN {
    eval {
        require Net::HTTP2::nghttp2;
        Net::HTTP2::nghttp2->VERSION('0.011');
        1;
    } or plan skip_all => 'Net::HTTP2::nghttp2 is not installed';

    Net::HTTP2::nghttp2->available
        or plan skip_all => 'nghttp2 library is not available';
}

use Linux::Event::HTTP::Client;
use Linux::Event::HTTP::Server;
use Linux::Event::Kernel::Timer;
use Linux::Event::Loop;

my $openssl = -x '/usr/bin/openssl' ? '/usr/bin/openssl' : undef;
if (!defined $openssl) {
    for my $dir (File::Spec->path) {
        my $candidate = File::Spec->catfile($dir, 'openssl');
        if (-x $candidate) {
            $openssl = $candidate;
            last;
        }
    }
}
plan skip_all => 'openssl command is required for HTTP/2 cancellation test'
    if !defined $openssl;

my $temp = tempdir(CLEANUP => 1);
my $cert = File::Spec->catfile($temp, 'server-cert.pem');
my $key = File::Spec->catfile($temp, 'server-key.pem');

my $generated;
{
    local $ENV{OPENSSL_CONF};
    delete $ENV{OPENSSL_CONF};
    $generated = system(
        $openssl, 'req', '-x509', '-newkey', 'rsa:2048', '-nodes',
        '-keyout', $key,
        '-out', $cert,
        '-subj', '/CN=localhost',
        '-addext', 'subjectAltName=DNS:localhost',
        '-days', '1',
    );
}
plan skip_all => 'openssl could not generate temporary TLS certificate'
    if $generated != 0 || !-s $cert || !-s $key;

my $loop = Linux::Event::Loop->new;
my @timers;
my $state = {
    connections      => {},
    requests         => [],
    bodies           => {},
    errors           => [],
    survivor_done    => 0,
    remote_error_hit => 0,
};

my ($client_cancel_server_tx, $server_cancel_tx);

my $server = Linux::Event::HTTP::Server->new(
    loop  => $loop,
    host  => '127.0.0.1',
    port  => 0,
    http2 => 1,
    tls   => {
        cert_file => $cert,
        key_file  => $key,
    },
    on_request => sub ($conn, $req, $res) {
        $state->{connections}{refaddr($conn)} = 1;
        push @{$state->{requests}}, $req->target;

        if ($req->target eq '/warmup') {
            $res->body('warmup');
            return;
        }

        if ($req->target eq '/client-cancel') {
            $client_cancel_server_tx = $conn->transaction;
            return;
        }

        if ($req->target eq '/client-survivor') {
            my $tx = $conn->transaction;
            my $timer;
            $timer = Linux::Event::Kernel::Timer->new(
                loop  => $loop,
                after => 0.05,
                on_timer => sub ($self) {
                    $res->body('client-survivor');
                    $tx->send_response;
                    $timer = undef;
                },
            );
            push @timers, $timer;
            return;
        }

        if ($req->target eq '/server-cancel') {
            $server_cancel_tx = $conn->transaction;
            my $timer;
            $timer = Linux::Event::Kernel::Timer->new(
                loop  => $loop,
                after => 0.01,
                on_timer => sub ($self) {
                    $server_cancel_tx->cancel
                        if !$server_cancel_tx->is_terminal;
                    $timer = undef;
                },
            );
            push @timers, $timer;
            return;
        }

        if ($req->target eq '/server-survivor') {
            my $tx = $conn->transaction;
            my $timer;
            $timer = Linux::Event::Kernel::Timer->new(
                loop  => $loop,
                after => 0.05,
                on_timer => sub ($self) {
                    $res->body('server-survivor');
                    $tx->send_response;
                    $timer = undef;
                },
            );
            push @timers, $timer;
            return;
        }

        die 'unexpected cancellation test target ' . $req->target;
    },
    on_error => sub ($conn, $error) {
        push @{$state->{errors}}, "server transport: $error";
        $loop->stop;
    },
);

my $guard = Linux::Event::Kernel::Timer->new(
    loop  => $loop,
    after => 10,
    on_timer => sub ($timer) {
        die "HTTP/2 cancellation isolation test timed out\n";
    },
);

my $client = Linux::Event::HTTP::Client->new(
    loop  => $loop,
    http2 => 1,
    tls   => {
        verify => 0,
        handshake_timeout => 2,
        shutdown_timeout  => 1,
    },
);

my $base = 'https://localhost:' . $server->port;
my ($client_cancel, $client_survivor, $server_cancel, $server_survivor);

my $finish = sub {
    return if !$state->{client_survivor_done};
    return if !$state->{server_survivor_done};
    return if !$state->{remote_error_hit};

    $guard->cancel;
    $client->close;
    $server->close;
    $loop->stop;
};

my $start_server_cancel_phase = sub {
    $server_cancel = $client->get(
        "$base/server-cancel",
        on_complete => sub ($tx) {
            die "server-cancel operation unexpectedly completed\n";
        },
        on_error => sub ($tx, $error) {
            ++$state->{remote_error_hit};
            $state->{remote_error} = "$error";
            $finish->();
        },
    );

    $server_survivor = $client->get(
        "$base/server-survivor",
        on_response => sub ($tx, $res) {
            $state->{server_survivor_status} = $res->status;
        },
        on_body => sub ($tx, $res, $bytes) {
            $state->{bodies}{server_survivor} .= $bytes;
        },
        on_complete => sub ($tx) {
            $state->{server_survivor_done} = 1;
            $finish->();
        },
        on_error => sub ($tx, $error) {
            push @{$state->{errors}}, "server survivor: $error";
            $loop->stop;
        },
    );
};

my $start_client_cancel_phase = sub {
    $client_cancel = $client->get(
        "$base/client-cancel",
        on_complete => sub ($tx) {
            die "client-cancel operation unexpectedly completed\n";
        },
        on_error => sub ($tx, $error) {
            push @{$state->{errors}}, "client-cancel callback: $error";
            $loop->stop;
        },
    );

    $client_survivor = $client->get(
        "$base/client-survivor",
        on_response => sub ($tx, $res) {
            $state->{client_survivor_status} = $res->status;
        },
        on_body => sub ($tx, $res, $bytes) {
            $state->{bodies}{client_survivor} .= $bytes;
        },
        on_complete => sub ($tx) {
            $state->{client_survivor_done} = 1;
            $start_server_cancel_phase->();
        },
        on_error => sub ($tx, $error) {
            push @{$state->{errors}}, "client survivor: $error";
            $loop->stop;
        },
    );

    my $timer;
    $timer = Linux::Event::Kernel::Timer->new(
        loop  => $loop,
        after => 0.01,
        on_timer => sub ($self) {
            $client_cancel->cancel;
            $timer = undef;
        },
    );
    push @timers, $timer;
};

my $warmup = $client->get(
    "$base/warmup",
    on_complete => sub ($tx) {
        $start_client_cancel_phase->();
    },
    on_error => sub ($tx, $error) {
        push @{$state->{errors}}, "warmup: $error";
        $loop->stop;
    },
);

$loop->run;

is_deeply($state->{errors}, [], 'H2 cancellation isolation has no transport errors');
is(scalar(keys %{$state->{connections}}), 1,
    'all cancellation cases share one H2 TLS connection');

ok($client_cancel->is_cancelled,
    'client-side cancel marks high-level Operation cancelled');
ok($client_cancel->transaction->is_cancelled,
    'client-side cancel marks only its Transaction cancelled');
ok(defined($client_cancel_server_tx) && $client_cancel_server_tx->is_terminal,
    'server observes cancelled client stream become terminal');

ok($state->{client_survivor_done},
    'sibling stream survives client-side cancellation');
is($state->{client_survivor_status}, 200,
    'client-cancel sibling receives status 200');
is($state->{bodies}{client_survivor}, 'client-survivor',
    'client-cancel sibling receives complete body');
ok($client_survivor->is_complete,
    'client-cancel sibling Operation completes');

ok(defined($server_cancel_tx) && $server_cancel_tx->is_cancelled,
    'server Transaction cancel marks only that server stream cancelled');
ok($state->{remote_error_hit},
    'server-side reset reaches matching client Operation as an error');
like($state->{remote_error} // '', qr/HTTP\/2 stream closed with error 8/,
    'server cancellation uses HTTP/2 CANCEL reset code');
ok($server_cancel->state eq 'error',
    'remote server cancellation marks client Operation error');

ok($state->{server_survivor_done},
    'sibling stream survives server-side cancellation');
is($state->{server_survivor_status}, 200,
    'server-cancel sibling receives status 200');
is($state->{bodies}{server_survivor}, 'server-survivor',
    'server-cancel sibling receives complete body');
ok($server_survivor->is_complete,
    'server-cancel sibling Operation completes');

is_deeply(
    [ sort @{$state->{requests}} ],
    [
        '/client-cancel',
        '/client-survivor',
        '/server-cancel',
        '/server-survivor',
        '/warmup',
    ],
    'server receives every cancellation test request exactly once',
);

done_testing;
