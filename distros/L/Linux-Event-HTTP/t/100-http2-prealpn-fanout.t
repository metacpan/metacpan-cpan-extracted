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
plan skip_all => 'openssl command is required for pre-ALPN fanout test'
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
my @h2_operations;
my @h1_operations;

my $state = {
    h2_connections => {},
    h1_connections => {},
    h2_targets     => [],
    h1_targets     => [],
    h2_complete    => 0,
    h1_complete    => 0,
    h2_body        => {},
    h1_body        => {},
    errors         => [],
};

my $finish = sub {
    return if $state->{h2_complete} != 6;
    return if $state->{h1_complete} != 4;
    $loop->stop;
};

my $h2_server = Linux::Event::HTTP::Server->new(
    loop  => $loop,
    host  => '127.0.0.1',
    port  => 0,
    http2 => 1,
    tls   => {
        cert_file => $cert,
        key_file  => $key,
    },
    on_request => sub ($conn, $req, $res) {
        $state->{h2_connections}{refaddr($conn)} = 1;
        push @{$state->{h2_targets}}, $req->target;

        my $tx = $conn->transaction;
        my $target = $req->target;
        my $timer;
        $timer = Linux::Event::Kernel::Timer->new(
            loop  => $loop,
            after => 0.03,
            on_timer => sub ($self) {
                $res->body("h2:$target\n");
                $tx->send_response;
                $timer = undef;
            },
        );
        push @timers, $timer;
    },
    on_error => sub ($conn, $error) {
        push @{$state->{errors}}, "h2 server: $error";
        $loop->stop;
    },
);

my $h1_server = Linux::Event::HTTP::Server->new(
    loop => $loop,
    host => '127.0.0.1',
    port => 0,
    tls  => {
        cert_file => $cert,
        key_file  => $key,
        alpn      => [ 'http/1.1' ],
    },
    on_request => sub ($conn, $req, $res) {
        $state->{h1_connections}{refaddr($conn)} = 1;
        push @{$state->{h1_targets}}, $req->target;

        my $tx = $conn->transaction;
        my $target = $req->target;
        my $timer;
        $timer = Linux::Event::Kernel::Timer->new(
            loop  => $loop,
            after => 0.03,
            on_timer => sub ($self) {
                $res->body("h1:$target\n");
                $tx->send_response;
                $timer = undef;
            },
        );
        push @timers, $timer;
    },
    on_error => sub ($conn, $error) {
        push @{$state->{errors}}, "h1 server: $error";
        $loop->stop;
    },
);

my $guard = Linux::Event::Kernel::Timer->new(
    loop  => $loop,
    after => 10,
    on_timer => sub ($timer) {
        die sprintf(
            "pre-ALPN HTTP/2 selector fanout test timed out: "
            . "h2_complete=%d h1_complete=%d h2_connections=%d "
            . "h1_connections=%d h2_targets=%d h1_targets=%d errors=%s\n",
            $state->{h2_complete},
            $state->{h1_complete},
            scalar(keys %{$state->{h2_connections}}),
            scalar(keys %{$state->{h1_connections}}),
            scalar(@{$state->{h2_targets}}),
            scalar(@{$state->{h1_targets}}),
            join(' | ', @{$state->{errors}}),
        );
    },
);

my $h2_client = Linux::Event::HTTP::Client->new(
    loop  => $loop,
    http2 => 1,
    tls   => {
        verify => 0,
        handshake_timeout => 2,
        shutdown_timeout  => 1,
    },
);

my $h1_client = Linux::Event::HTTP::Client->new(
    loop  => $loop,
    http2 => 1,
    tls   => {
        verify => 0,
        handshake_timeout => 2,
        shutdown_timeout  => 1,
    },
);

my $h2_base = 'https://localhost:' . $h2_server->port;
for my $number (1 .. 6) {
    my $operation = $h2_client->get(
        "$h2_base/prealpn/$number",
        on_response => sub ($tx, $res) {
            $state->{h2_status}{$number} = $res->status;
        },
        on_body => sub ($tx, $res, $bytes) {
            $state->{h2_body}{$number} .= $bytes;
        },
        on_complete => sub ($tx) {
            ++$state->{h2_complete};
            $finish->();
        },
        on_error => sub ($tx, $error) {
            push @{$state->{errors}}, "h2 client $number: $error";
            $loop->stop;
        },
    );
    push @h2_operations, $operation;
}

my $h1_base = 'https://localhost:' . $h1_server->port;
for my $number (1 .. 4) {
    my $operation = $h1_client->get(
        "$h1_base/fallback/$number",
        on_response => sub ($tx, $res) {
            $state->{h1_status}{$number} = $res->status;
        },
        on_body => sub ($tx, $res, $bytes) {
            $state->{h1_body}{$number} .= $bytes;
        },
        on_complete => sub ($tx) {
            ++$state->{h1_complete};
            $finish->();
        },
        on_error => sub ($tx, $error) {
            push @{$state->{errors}}, "h1 client $number: $error";
            $loop->stop;
        },
    );
    push @h1_operations, $operation;
}

is(
    scalar(keys %{$h2_client->{connections}}),
    1,
    'six pre-ALPN H2-capable operations start one TLS negotiation',
);
is(
    scalar(keys %{$h1_client->{connections}}),
    1,
    'four pre-ALPN fallback operations also start one TLS negotiation',
);

for my $operation (@h2_operations, @h1_operations) {
    is(
        $operation->request->version,
        '1.1',
        'pre-ALPN Request remains provisionally HTTP/1.1-compatible',
    );
}

$loop->run;

$guard->cancel;
$h2_client->close;
$h1_client->close;
$h2_server->close;
$h1_server->close;

is_deeply($state->{errors}, [], 'pre-ALPN selector reports no errors');

is($state->{h2_complete}, 6, 'all queued H2 operations complete');
is(
    scalar(keys %{$state->{h2_connections}}),
    1,
    'queued pre-ALPN operations collapse onto one selected H2 connection',
);

for my $number (1 .. 6) {
    is($h2_operations[$number - 1]->request->version, '2',
        "H2 operation $number records selected protocol");
    is($state->{h2_status}{$number}, 200,
        "H2 operation $number receives status 200");
    is($state->{h2_body}{$number}, "h2:/prealpn/$number\n",
        "H2 operation $number receives independent body");
}

is($state->{h1_complete}, 4, 'all queued HTTP/1.1 fallback operations complete');
is(
    scalar(keys %{$state->{h1_connections}}),
    4,
    'HTTP/1.1 fallback fans queued operations onto separate connections',
);

for my $number (1 .. 4) {
    is($h1_operations[$number - 1]->request->version, '1.1',
        "fallback operation $number remains HTTP/1.1");
    is($state->{h1_status}{$number}, 200,
        "fallback operation $number receives status 200");
    is($state->{h1_body}{$number}, "h1:/fallback/$number\n",
        "fallback operation $number receives independent body");
}

is_deeply(
    [ sort @{$state->{h2_targets}} ],
    [ map { "/prealpn/$_" } 1 .. 6 ],
    'H2 server receives every queued target exactly once',
);
is_deeply(
    [ sort @{$state->{h1_targets}} ],
    [ map { "/fallback/$_" } 1 .. 4 ],
    'HTTP/1.1 fallback server receives every queued target exactly once',
);

done_testing;
