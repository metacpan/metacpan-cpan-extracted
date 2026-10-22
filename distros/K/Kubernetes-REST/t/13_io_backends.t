#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use IO::Socket::SSL qw( SSL_VERIFY_PEER SSL_VERIFY_NONE );
use HTTP::Tiny;
use FindBin;
use lib "$FindBin::Bin/../lib", "$FindBin::Bin/lib";

use Kubernetes::REST::HTTPRequest;
use Kubernetes::REST::HTTPResponse;

# ============================================================================
# Test LWPIO backend
# ============================================================================

subtest 'LWPIO - construction with defaults' => sub {
    use_ok('Kubernetes::REST::LWPIO');

    my $io = Kubernetes::REST::LWPIO->new;
    ok $io, 'LWPIO created';
    is $io->ssl_verify_server, 1, 'ssl_verify_server defaults to true';
    is $io->timeout, 310, 'timeout defaults to 310';
    ok !defined $io->ssl_cert_file, 'ssl_cert_file is undef';
    ok !defined $io->ssl_key_file, 'ssl_key_file is undef';
    ok !defined $io->ssl_ca_file, 'ssl_ca_file is undef';
};

subtest 'LWPIO - construction with custom SSL options' => sub {
    my $io = Kubernetes::REST::LWPIO->new(
        ssl_verify_server => 0,
        ssl_cert_file => '/tmp/cert.pem',
        ssl_key_file => '/tmp/key.pem',
        ssl_ca_file => '/tmp/ca.pem',
        timeout => 60,
    );
    is $io->ssl_verify_server, 0, 'ssl_verify_server set to false';
    is $io->ssl_cert_file, '/tmp/cert.pem', 'ssl_cert_file set';
    is $io->ssl_key_file, '/tmp/key.pem', 'ssl_key_file set';
    is $io->ssl_ca_file, '/tmp/ca.pem', 'ssl_ca_file set';
    is $io->timeout, 60, 'timeout set to 60';
};

subtest 'LWPIO - ua is LWP::UserAgent' => sub {
    my $io = Kubernetes::REST::LWPIO->new;
    my $ua = $io->ua;
    isa_ok $ua, 'LWP::UserAgent';
    like $ua->agent, qr/Kubernetes::REST/, 'user agent string set';
    is $ua->timeout, 310, 'ua timeout matches io timeout';
};

subtest 'LWPIO - ua SSL options with verify' => sub {
    my $io = Kubernetes::REST::LWPIO->new(ssl_verify_server => 1);
    my $ua = $io->ua;
    my $opts = $ua->ssl_opts('verify_hostname');
    is $opts, 1, 'verify_hostname enabled';
};

subtest 'LWPIO - ua SSL options without verify' => sub {
    my $io = Kubernetes::REST::LWPIO->new(ssl_verify_server => 0);
    my $ua = $io->ua;
    my $opts = $ua->ssl_opts('verify_hostname');
    is $opts, 0, 'verify_hostname disabled';
};

subtest 'LWPIO - call() makes HTTP request' => sub {
    # We can't easily mock LWP::UserAgent, but we can subclass
    my $io = Kubernetes::REST::LWPIO->new;

    # Replace the ua with a mock
    my $mock_ua = Test::MockLWP->new(
        code => 200,
        content => '{"kind":"Namespace","metadata":{"name":"default"}}',
    );
    $io->{ua} = $mock_ua;

    my $req = Kubernetes::REST::HTTPRequest->new(
        method => 'GET',
        url => 'http://mock.local/api/v1/namespaces/default',
        headers => { Authorization => 'Bearer test-token' },
    );

    my $res = $io->call($req);
    isa_ok $res, 'Kubernetes::REST::HTTPResponse';
    is $res->status, 200, 'status is 200';
    like $res->content, qr/Namespace/, 'content contains Namespace';
};

subtest 'LWPIO - call() with POST body' => sub {
    my $io = Kubernetes::REST::LWPIO->new;

    my $mock_ua = Test::MockLWP->new(
        code => 201,
        content => '{"kind":"Namespace","metadata":{"name":"test","uid":"abc123"}}',
    );
    $io->{ua} = $mock_ua;

    my $req = Kubernetes::REST::HTTPRequest->new(
        method => 'POST',
        url => 'http://mock.local/api/v1/namespaces',
        headers => { 'Content-Type' => 'application/json' },
        content => '{"metadata":{"name":"test"}}',
    );

    my $res = $io->call($req);
    is $res->status, 201, 'POST returns 201';
    like $res->content, qr/uid/, 'response contains uid';

    # Verify the request body was passed
    is $mock_ua->last_request->content, '{"metadata":{"name":"test"}}',
        'request body preserved';
};

subtest 'LWPIO - call_streaming() with data callback' => sub {
    my $io = Kubernetes::REST::LWPIO->new;

    # For streaming, LWP calls the callback with chunks
    my $mock_ua = Test::MockLWP->new(
        code => 200,
        content => '',
        streaming_chunks => [
            qq|{"type":"ADDED","object":{"kind":"Pod","metadata":{"name":"pod-1"}}}\n|,
            qq|{"type":"MODIFIED","object":{"kind":"Pod","metadata":{"name":"pod-1"}}}\n|,
        ],
    );
    $io->{ua} = $mock_ua;

    my $req = Kubernetes::REST::HTTPRequest->new(
        method => 'GET',
        url => 'http://mock.local/api/v1/namespaces/default/pods?watch=true',
        headers => { Authorization => 'Bearer test-token' },
    );

    my @chunks;
    my $res = $io->call_streaming($req, sub { push @chunks, $_[0] });

    isa_ok $res, 'Kubernetes::REST::HTTPResponse';
    is $res->status, 200, 'streaming returns 200';
    is scalar @chunks, 2, 'received 2 chunks';
    like $chunks[0], qr/ADDED/, 'first chunk is ADDED';
    like $chunks[1], qr/MODIFIED/, 'second chunk is MODIFIED';
};

subtest 'LWPIO - call() with empty response' => sub {
    my $io = Kubernetes::REST::LWPIO->new;

    my $mock_ua = Test::MockLWP->new(
        code => 204,
        content => '',
    );
    $io->{ua} = $mock_ua;

    my $req = Kubernetes::REST::HTTPRequest->new(
        method => 'DELETE',
        url => 'http://mock.local/api/v1/namespaces/test',
        headers => {},
    );

    my $res = $io->call($req);
    is $res->status, 204, 'status is 204';
};

subtest 'LWPIO - implements Role::IO' => sub {
    my $io = Kubernetes::REST::LWPIO->new;
    ok $io->does('Kubernetes::REST::Role::IO'), 'LWPIO does Role::IO';
};

# ============================================================================
# Test HTTPTinyIO backend
# ============================================================================

subtest 'HTTPTinyIO - construction with defaults' => sub {
    use_ok('Kubernetes::REST::HTTPTinyIO');

    my $io = Kubernetes::REST::HTTPTinyIO->new;
    ok $io, 'HTTPTinyIO created';
    is $io->ssl_verify_server, 1, 'ssl_verify_server defaults to true';
    is $io->timeout, 310, 'timeout defaults to 310';
};

subtest 'HTTPTinyIO - construction with custom options' => sub {
    my $io = Kubernetes::REST::HTTPTinyIO->new(
        ssl_verify_server => 0,
        ssl_cert_file => '/tmp/cert.pem',
        ssl_key_file => '/tmp/key.pem',
        ssl_ca_file => '/tmp/ca.pem',
        timeout => 120,
    );
    is $io->ssl_verify_server, 0, 'ssl_verify_server set';
    is $io->ssl_cert_file, '/tmp/cert.pem', 'ssl_cert_file set';
    is $io->ssl_key_file, '/tmp/key.pem', 'ssl_key_file set';
    is $io->ssl_ca_file, '/tmp/ca.pem', 'ssl_ca_file set';
    is $io->timeout, 120, 'timeout set';
};

subtest 'HTTPTinyIO - ua is HTTP::Tiny' => sub {
    my $io = Kubernetes::REST::HTTPTinyIO->new;
    my $ua = $io->ua;
    isa_ok $ua, 'HTTP::Tiny';
};

# What HTTP::Tiny really hands to IO::Socket::SSL for a connection, built the
# same way HTTP::Tiny::_open_handle builds its handle from the ua.
sub tiny_ssl_args {
    my ($ua, $host) = @_;
    my $handle = HTTP::Tiny::Handle->new(
        SSL_options => $ua->{SSL_options},
        verify_SSL  => $ua->{verify_SSL},
    );
    return $handle->_ssl_args($host);
}

subtest 'HTTPTinyIO - ssl_verify_server => 1 verifies cert and hostname' => sub {
    my $io = Kubernetes::REST::HTTPTinyIO->new(
        ssl_verify_server => 1,
        ssl_ca_file       => $INC{'Kubernetes/REST/HTTPTinyIO.pm'},
    );
    my $ua = $io->ua;
    is $ua->verify_SSL, 1, 'ua verify_SSL is 1';
    my $args = tiny_ssl_args($ua, 'k8s.example.com');
    is $args->{SSL_verifycn_scheme}, 'http', 'hostname verification on';
    is $args->{SSL_verifycn_name}, 'k8s.example.com', 'verified against the connect host';
    is $args->{SSL_verify_mode}, SSL_VERIFY_PEER, 'SSL_VERIFY_PEER';
};

subtest 'HTTPTinyIO - ssl_verify_server => 0 disables verification' => sub {
    my $io = Kubernetes::REST::HTTPTinyIO->new(ssl_verify_server => 0);
    my $ua = $io->ua;
    is $ua->verify_SSL, 0, 'ua verify_SSL is 0 (not left at the HTTP::Tiny default)';
    my $args = tiny_ssl_args($ua, 'k8s.example.com');
    is $args->{SSL_verifycn_scheme}, 'none', 'hostname verification off';
    is $args->{SSL_verify_mode}, SSL_VERIFY_NONE, 'SSL_VERIFY_NONE';
};

subtest 'HTTPTinyIO - implements Role::IO' => sub {
    my $io = Kubernetes::REST::HTTPTinyIO->new;
    ok $io->does('Kubernetes::REST::Role::IO'), 'HTTPTinyIO does Role::IO';
};

subtest 'HTTPTinyIO - call() makes HTTP request' => sub {
    my $io = Kubernetes::REST::HTTPTinyIO->new;

    # Replace the ua with a mock
    my $mock_ua = Test::MockHTTPTiny->new(
        status => 200,
        content => '{"kind":"Namespace","metadata":{"name":"default"}}',
    );
    $io->{ua} = $mock_ua;

    my $req = Kubernetes::REST::HTTPRequest->new(
        method => 'GET',
        url => 'http://mock.local/api/v1/namespaces/default',
        headers => { Authorization => 'Bearer test-token' },
    );

    my $res = $io->call($req);
    isa_ok $res, 'Kubernetes::REST::HTTPResponse';
    is $res->status, 200, 'status is 200';
    like $res->content, qr/Namespace/, 'content contains Namespace';
};

subtest 'HTTPTinyIO - call() with POST and content' => sub {
    my $io = Kubernetes::REST::HTTPTinyIO->new;

    my $mock_ua = Test::MockHTTPTiny->new(
        status => 201,
        content => '{"kind":"Namespace","metadata":{"name":"test","uid":"abc"}}',
    );
    $io->{ua} = $mock_ua;

    my $req = Kubernetes::REST::HTTPRequest->new(
        method => 'POST',
        url => 'http://mock.local/api/v1/namespaces',
        headers => { 'Content-Type' => 'application/json' },
        content => '{"metadata":{"name":"test"}}',
    );

    my $res = $io->call($req);
    is $res->status, 201, 'POST returns 201';

    # Verify content was passed
    my $last = $mock_ua->last_opts;
    is $last->{content}, '{"metadata":{"name":"test"}}', 'content passed to UA';
};

subtest 'HTTPTinyIO - call() with empty content' => sub {
    my $io = Kubernetes::REST::HTTPTinyIO->new;

    my $mock_ua = Test::MockHTTPTiny->new(
        status => 200,
        content => undef,
    );
    $io->{ua} = $mock_ua;

    my $req = Kubernetes::REST::HTTPRequest->new(
        method => 'GET',
        url => 'http://mock.local/api/v1/pods',
        headers => {},
    );

    my $res = $io->call($req);
    is $res->status, 200, 'status ok with no content';
};

subtest 'HTTPTinyIO - call_streaming() with data callback' => sub {
    my $io = Kubernetes::REST::HTTPTinyIO->new;

    my @delivered_chunks;
    my $mock_ua = Test::MockHTTPTiny->new(
        status => 200,
        content => undef,
        on_data_callback => sub {
            my ($cb) = @_;
            $cb->(qq|{"type":"ADDED","object":{"kind":"Pod"}}\n|);
            $cb->(qq|{"type":"DELETED","object":{"kind":"Pod"}}\n|);
        },
    );
    $io->{ua} = $mock_ua;

    my $req = Kubernetes::REST::HTTPRequest->new(
        method => 'GET',
        url => 'http://mock.local/api/v1/pods?watch=true',
        headers => {},
    );

    my @chunks;
    my $res = $io->call_streaming($req, sub { push @chunks, $_[0] });
    is $res->status, 200, 'streaming returns 200';
    is scalar @chunks, 2, 'received 2 chunks';
    like $chunks[0], qr/ADDED/, 'first chunk is ADDED';
    like $chunks[1], qr/DELETED/, 'second chunk is DELETED';
};

# ============================================================================
# Test that REST.pm uses LWPIO by default
# ============================================================================

subtest 'REST default IO is LWPIO' => sub {
    use Test::Kubernetes::Mock qw(mock_api);
    # The mock API uses Mock::IO, so test by creating a non-mock one
    require Kubernetes::REST;
    require Kubernetes::REST::Server;
    require Kubernetes::REST::AuthToken;

    my $api = Kubernetes::REST->new(
        server => Kubernetes::REST::Server->new(endpoint => 'http://test.local'),
        credentials => Kubernetes::REST::AuthToken->new(token => 'test'),
        resource_map_from_cluster => 0,
    );
    isa_ok $api->io, 'Kubernetes::REST::LWPIO', 'default IO is LWPIO';
};

subtest 'REST allows HTTPTinyIO override' => sub {
    require Kubernetes::REST;
    require Kubernetes::REST::Server;
    require Kubernetes::REST::AuthToken;
    require Kubernetes::REST::HTTPTinyIO;

    my $api = Kubernetes::REST->new(
        server => Kubernetes::REST::Server->new(endpoint => 'http://test.local'),
        credentials => Kubernetes::REST::AuthToken->new(token => 'test'),
        resource_map_from_cluster => 0,
        io => Kubernetes::REST::HTTPTinyIO->new,
    );
    isa_ok $api->io, 'Kubernetes::REST::HTTPTinyIO', 'can override with HTTPTinyIO';
};

# ============================================================================
# Real sockets: callback exceptions and transport failures (k71)
# ============================================================================

use IO::Socket::INET;
use POSIX ();

# Forked one-shot-per-connection server on 127.0.0.1. $handler gets the
# connected socket after the request head was read and writes the raw response.
sub spawn_server {
    my ($handler) = @_;
    my $listen = IO::Socket::INET->new(
        Listen => 5, LocalAddr => '127.0.0.1', LocalPort => 0, ReuseAddr => 1,
    ) or die "listen: $!";
    my $port = $listen->sockport;
    my $pid = fork;
    die "fork: $!" unless defined $pid;
    if (!$pid) {
        local $SIG{TERM} = sub { POSIX::_exit(0) };
        while (my $c = $listen->accept) {
            while (my $line = <$c>) { last if $line =~ /^\r?\n$/ }
            $handler->($c);
            close $c;
        }
        POSIX::_exit(0);
    }
    close $listen;
    return ($port, $pid);
}

sub stop_server { my ($pid) = @_; kill 'TERM', $pid; waitpid $pid, 0 }

sub closed_port {
    my $l = IO::Socket::INET->new(Listen => 1, LocalAddr => '127.0.0.1', LocalPort => 0)
        or die "listen: $!";
    my $port = $l->sockport;
    close $l;
    return $port;
}

sub get_req {
    my ($port) = @_;
    return Kubernetes::REST::HTTPRequest->new(
        method => 'GET', url => "http://127.0.0.1:$port/x", headers => {},
    );
}

my %backend = (
    LWPIO      => sub { Kubernetes::REST::LWPIO->new(timeout => 10) },
    HTTPTinyIO => sub { Kubernetes::REST::HTTPTinyIO->new(timeout => 10) },
);

package Test::CallbackError {
    sub new { bless { msg => $_[1] }, $_[0] }
    sub msg { $_[0]{msg} }
}

for my $name (sort keys %backend) {
    my $io = $backend{$name}->();

    subtest "$name - call_streaming rethrows a string exception from the callback" => sub {
        my ($port, $pid) = spawn_server(sub {
            my ($c) = @_;
            print $c "HTTP/1.1 200 OK\r\nContent-Length: 6\r\nConnection: close\r\n\r\nabc\ndef";
        });
        my $res = eval { $io->call_streaming(get_req($port), sub { die "boom in on_event\n" }) };
        my $err = $@;
        stop_server($pid);
        is $err, "boom in on_event\n", 'exception reaches the caller unchanged';
        ok !$res, 'no response returned';
    };

    subtest "$name - call_streaming rethrows an object exception from the callback" => sub {
        my ($port, $pid) = spawn_server(sub {
            my ($c) = @_;
            print $c "HTTP/1.1 200 OK\r\nContent-Length: 6\r\nConnection: close\r\n\r\nabc\ndef";
        });
        my $obj = Test::CallbackError->new('structured');
        eval { $io->call_streaming(get_req($port), sub { die $obj }) };
        my $err = $@;
        stop_server($pid);
        isa_ok $err, 'Test::CallbackError', 'object exception';
        is eval { $err->msg }, 'structured', 'payload intact';
    };

    subtest "$name - call_streaming with a well-behaved callback" => sub {
        my ($port, $pid) = spawn_server(sub {
            my ($c) = @_;
            print $c "HTTP/1.1 200 OK\r\nContent-Length: 7\r\nConnection: close\r\n\r\nabc\ndef";
        });
        my $got = '';
        my $res = $io->call_streaming(get_req($port), sub { $got .= $_[0] });
        stop_server($pid);
        is $res->status, 200, 'status 200';
        is $got, "abc\ndef", 'all bytes delivered to the callback';
    };

    subtest "$name - connect failure is a 599 with the message" => sub {
        my $port = closed_port();
        for my $mode (qw( call call_streaming )) {
            my $res = $mode eq 'call'
                ? $io->call(get_req($port))
                : $io->call_streaming(get_req($port), sub {});
            is $res->status, 599, "$mode: transport failure is 599";
            ok length($res->content // ''), "$mode: content carries the error message";
        }
    };

    subtest "$name - a real server 500 stays 500" => sub {
        my $body = '{"kind":"Status","code":500}';
        my ($port, $pid) = spawn_server(sub {
            my ($c) = @_;
            print $c "HTTP/1.1 500 Internal Server Error\r\nContent-Length: ".length($body)."\r\nConnection: close\r\n\r\n".$body;
        });
        my $res  = $io->call(get_req($port));
        my $res2 = $io->call_streaming(get_req($port), sub {});
        stop_server($pid);
        is $res->status,  500, 'call: 500 kept';
        is $res2->status, 500, 'call_streaming: 500 kept';
        is $res->content, $body, 'call: server body kept';
    };

    subtest "$name - connection dropped mid-body is a 599" => sub {
        my ($port, $pid) = spawn_server(sub {
            my ($c) = @_;
            print $c "HTTP/1.1 200 OK\r\nContent-Length: 100\r\nConnection: close\r\n\r\nshort";
        });
        my $res  = $io->call(get_req($port));
        my $got  = '';
        my $res2 = $io->call_streaming(get_req($port), sub { $got .= $_[0] });
        stop_server($pid);
        is $res->status,  599, 'call: truncated body is 599';
        is $res2->status, 599, 'call_streaming: truncated body is 599';
    };
}

subtest 'LWPIO - unsupported scheme (LWP internal 501) is a 599 with the message' => sub {
    my $io = Kubernetes::REST::LWPIO->new;
    my $res = $io->call(Kubernetes::REST::HTTPRequest->new(
        method => 'GET', url => 'nosuchscheme://localhost/x', headers => {},
    ));
    is $res->status, 599, 'internal 501 mapped to 599';
    like $res->content, qr/nosuchscheme/, 'message in content';
};

done_testing;

# ============================================================================
# Minimal mock LWP::UserAgent for testing LWPIO without network
# ============================================================================

package Test::MockLWP;
use strict;
use warnings;

sub new {
    my ($class, %args) = @_;
    bless {
        code => $args{code} // 200,
        content => $args{content} // '',
        streaming_chunks => $args{streaming_chunks} // [],
        last_request => undef,
    }, $class;
}

sub request {
    my ($self, $req, $content_cb) = @_;
    $self->{last_request} = $req;

    if ($content_cb && ref $content_cb eq 'CODE') {
        # Streaming mode: deliver chunks via callback
        for my $chunk (@{$self->{streaming_chunks}}) {
            $content_cb->($chunk);
        }
    }

    return Test::MockLWP::Response->new(
        code => $self->{code},
        content => $self->{content},
    );
}

sub last_request { $_[0]->{last_request} }

package Test::MockLWP::Response;
use strict;
use warnings;

sub new {
    my ($class, %args) = @_;
    bless \%args, $class;
}

sub code { $_[0]->{code} }
sub decoded_content { $_[0]->{content} }

# ============================================================================
# Minimal mock HTTP::Tiny for testing HTTPTinyIO without network
# ============================================================================

package Test::MockHTTPTiny;
use strict;
use warnings;

sub new {
    my ($class, %args) = @_;
    bless {
        status => $args{status} // 200,
        content => $args{content},
        on_data_callback => $args{on_data_callback},
        last_opts => undef,
    }, $class;
}

sub request {
    my ($self, $method, $url, $opts) = @_;
    $self->{last_opts} = $opts // {};

    # If there's a data_callback in opts and we have streaming setup, invoke it
    if ($opts->{data_callback} && $self->{on_data_callback}) {
        $self->{on_data_callback}->($opts->{data_callback});
    }

    return {
        status => $self->{status},
        (defined $self->{content} ? (content => $self->{content}) : ()),
    };
}

sub last_opts { $_[0]->{last_opts} }
