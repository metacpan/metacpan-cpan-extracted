#!/usr/bin/env perl
# Non-ASCII payloads must survive the round trip, identically on every IO
# backend. Regression test for the "HTTP::Message content must be bytes" death
# on encode, and for the silent double decode on the LWP response path.
use strict;
use warnings;
use utf8;
use Test::More;
use Encode qw(encode decode);
use JSON::MaybeXS;
use FindBin;
use lib "$FindBin::Bin/../lib", "$FindBin::Bin/lib";

use Kubernetes::REST;
use Kubernetes::REST::Server;
use Kubernetes::REST::AuthToken;
use Kubernetes::REST::HTTPRequest;
use Kubernetes::REST::HTTPResponse;
use Kubernetes::REST::LWPIO;
use Kubernetes::REST::HTTPTinyIO;

# ============================================================================
# IO doubles - defined up front, the Moo class has to exist before first use
# ============================================================================

{
    package Test::CaptureIO;
    use Moo;
    with 'Kubernetes::REST::Role::IO';

    has last_request => (is => 'rw');

    sub call {
        my ($self, $req) = @_;
        $self->last_request($req);
        return Kubernetes::REST::HTTPResponse->new(
            status  => 200,
            content => $req->content // '{}',
        );
    }

    sub call_streaming {
        my ($self, $req, $cb) = @_;
        $self->last_request($req);
        return Kubernetes::REST::HTTPResponse->new(status => 200);
    }
}

# Mimics the parts of LWP::UserAgent / HTTP::Response that LWPIO touches.
{
    package Test::StaticLWP;

    sub new {
        my ($class, %args) = @_;
        return bless { %args }, $class;
    }

    sub request {
        my ($self, $req, $cb) = @_;
        $cb->($_) for @{ $self->{stream} // [] };
        return Test::StaticLWP::Response->new(
            code    => $self->{code},
            content => $self->{stream} ? '' : $self->{content},
        );
    }

    package Test::StaticLWP::Response;

    sub new {
        my ($class, %args) = @_;
        return bless { %args }, $class;
    }

    sub code { $_[0]->{code} }
    sub content { $_[0]->{content} }

    # charset => 'none' is what LWPIO must ask for; anything else is the bug
    # this double exists to catch.
    sub decoded_content {
        my ($self, %opts) = @_;
        die "LWPIO must call decoded_content(charset => 'none')"
            unless ($opts{charset} // '') eq 'none';
        return $self->{content};
    }
}

{
    package Test::StaticHTTPTiny;

    sub new {
        my ($class, %args) = @_;
        return bless { %args }, $class;
    }

    sub request {
        my ($self, $method, $url, $opts) = @_;
        if (my $cb = $opts->{data_callback}) {
            $cb->($_) for @{ $self->{stream} // [] };
        }
        return {
            status => $self->{status},
            (defined $self->{content} ? (content => $self->{content}) : ()),
        };
    }
}

# § and – are the characters that broke applying the upstream cert-manager CRDs
my $TEXT = "Café § – 日本";
my $TEXT_BYTES = encode('UTF-8', $TEXT);

sub api_with_io {
    my ($io) = @_;
    return Kubernetes::REST->new(
        server => Kubernetes::REST::Server->new(endpoint => 'http://mock.local'),
        credentials => Kubernetes::REST::AuthToken->new(token => 'test'),
        resource_map_from_cluster => 0,
        io => $io,
    );
}

# ============================================================================
# Request side: the body must leave as bytes
# ============================================================================

subtest 'request body is UTF-8 encoded' => sub {
    my $api = api_with_io(Test::CaptureIO->new);

    my $cm = $api->new_object(ConfigMap => {
        metadata => { name => 'utf8-probe', namespace => 'default' },
        data     => { note => $TEXT },
    });

    $api->create($cm);

    my $sent = $api->io->last_request->content;
    ok !utf8::is_utf8($sent) || $sent !~ /[^\x00-\xff]/, 'no character above U+00FF in body';
    like $sent, qr/\Q$TEXT_BYTES\E/, 'body carries the UTF-8 bytes of the value';

    # The actual failure mode from the ticket: HTTP::Request rejects the body
    my $http_req = HTTP::Request->new(POST => 'http://mock.local/', [], $sent);
    is $http_req->content, $sent, 'HTTP::Request accepts the body';
};

subtest 'JSON encoder emits bytes, not characters' => sub {
    my $api = api_with_io(Test::CaptureIO->new);
    my $encoded = $api->_json->encode({ note => $TEXT });
    unlike $encoded, qr/[^\x00-\xff]/, 'encoder output has no wide characters';
    is $api->_json->decode($encoded)->{note}, $TEXT, 'round trips back to characters';
};

# ============================================================================
# Response side: both backends must inflate to the same characters
# ============================================================================

my %BODY = (
    apiVersion => 'v1',
    kind       => 'ConfigMap',
    metadata   => { name => 'utf8-probe', namespace => 'default' },
    data       => { note => $TEXT },
);
my $BODY_BYTES = JSON::MaybeXS->new(utf8 => 1, canonical => 1)->encode(\%BODY);

subtest 'LWPIO hands back bytes' => sub {
    my $io = Kubernetes::REST::LWPIO->new;
    $io->{ua} = Test::StaticLWP->new(code => 200, content => $BODY_BYTES);

    my $res = $io->call(Kubernetes::REST::HTTPRequest->new(
        method => 'GET', url => 'http://mock.local/api/v1/x', headers => {},
    ));
    is $res->content, $BODY_BYTES, 'content is the undecoded body';
};

subtest 'HTTPTinyIO hands back bytes' => sub {
    my $io = Kubernetes::REST::HTTPTinyIO->new;
    $io->{ua} = Test::StaticHTTPTiny->new(status => 200, content => $BODY_BYTES);

    my $res = $io->call(Kubernetes::REST::HTTPRequest->new(
        method => 'GET', url => 'http://mock.local/api/v1/x', headers => {},
    ));
    is $res->content, $BODY_BYTES, 'content is the undecoded body';
};

subtest 'both backends inflate to identical objects' => sub {
    my %got;

    for my $case (
        [ lwp  => sub {
            my $io = Kubernetes::REST::LWPIO->new;
            $io->{ua} = Test::StaticLWP->new(code => 200, content => $BODY_BYTES);
            return $io;
        } ],
        [ tiny => sub {
            my $io = Kubernetes::REST::HTTPTinyIO->new;
            $io->{ua} = Test::StaticHTTPTiny->new(status => 200, content => $BODY_BYTES);
            return $io;
        } ],
    ) {
        my ($name, $build) = @$case;
        my $api = api_with_io($build->());
        my $cm = $api->get('ConfigMap', 'utf8-probe', namespace => 'default');
        $got{$name} = $cm->data->{note};
        is $got{$name}, $TEXT, "$name backend decodes the value once";
        is length $got{$name}, length $TEXT, "$name backend yields characters, not bytes";
    }

    is $got{lwp}, $got{tiny}, 'both backends agree';
};

# ============================================================================
# Error bodies are decoded for human consumption
# ============================================================================

subtest 'API error message is decoded' => sub {
    my $io = Kubernetes::REST::HTTPTinyIO->new;
    $io->{ua} = Test::StaticHTTPTiny->new(
        status  => 422,
        content => encode('UTF-8', qq|{"message":"invalid: $TEXT"}|),
    );
    my $api = api_with_io($io);

    eval { $api->get('ConfigMap', 'utf8-probe', namespace => 'default') };
    my $err = $@;
    ok $err, 'call died';
    like $err, qr/\Q$TEXT\E/, 'message contains the decoded text';
};

subtest 'undecodable error body does not kill the error' => sub {
    my $io = Kubernetes::REST::HTTPTinyIO->new;
    $io->{ua} = Test::StaticHTTPTiny->new(status => 500, content => "\xff\xfe broken");
    my $api = api_with_io($io);

    eval { $api->get('ConfigMap', 'utf8-probe', namespace => 'default') };
    like $@, qr/Kubernetes API error/, 'still reports the API error';
    like $@, qr/500/, 'still reports the status';
};

# ============================================================================
# Watch: NDJSON chunks arrive as bytes and inflate to characters
# ============================================================================

subtest 'watch events decode correctly' => sub {
    my $event = {
        type   => 'ADDED',
        object => {
            apiVersion => 'v1',
            kind       => 'ConfigMap',
            metadata   => { name => 'utf8-probe', namespace => 'default',
                            resourceVersion => '42' },
            data       => { note => $TEXT },
        },
    };
    my $line = JSON::MaybeXS->new(utf8 => 1, canonical => 1)->encode($event) . "\n";

    my $io = Kubernetes::REST::HTTPTinyIO->new;
    $io->{ua} = Test::StaticHTTPTiny->new(status => 200, stream => [ $line ]);
    my $api = api_with_io($io);

    my @seen;
    $api->watch('ConfigMap', namespace => 'default', timeout => 1,
        on_event => sub { push @seen, $_[0] });

    is scalar @seen, 1, 'one event seen';
    is $seen[0]->type, 'ADDED', 'event type';
    is $seen[0]->object->data->{note}, $TEXT, 'event payload decoded once';
};

# ============================================================================
# Log stays bytes on purpose - container output is not guaranteed to be text
# ============================================================================

subtest 'log returns raw bytes' => sub {
    my $io = Kubernetes::REST::HTTPTinyIO->new;
    $io->{ua} = Test::StaticHTTPTiny->new(status => 200, content => "$TEXT_BYTES\n");
    my $api = api_with_io($io);

    my $text = $api->log('Pod', 'utf8-probe', namespace => 'default');
    is $text, "$TEXT_BYTES\n", 'bytes handed through unchanged';
    is decode('UTF-8', $text), "$TEXT\n", 'caller can decode it';
};

done_testing;
