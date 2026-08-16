#!/usr/bin/env perl
# Tests for the /status subresource writers: patch_status() and update_status().
#
# The bug these pin is a silent one: once a CRD declares
# subresources: {status: {}}, the API server strips the status stanza from
# every write to the main endpoint and still answers 2xx. So the thing that
# has to be asserted here is the URL and the Content-Type that actually go
# out on the wire, not just that a call returns an object.
#
# Run:
#   prove -lv t/26_status_subresource.t

use strict;
use warnings;
use Test::More;
use Test::Exception;
use FindBin;
use lib "$FindBin::Bin/lib";
use lib "$FindBin::Bin/../lib";

use Kubernetes::REST;
use Kubernetes::REST::Server;
use Kubernetes::REST::AuthToken;
use Kubernetes::REST::HTTPResponse;
use JSON::MaybeXS ();
use IO::K8s;

# A CRD with a status subresource - the case from the ticket.
use My::StaticWebSite;

# ============================================================================
# Recording IO backend: keeps every request it was handed so the tests can
# assert on the exact URL, method, headers and body, and answers with a
# canned document so the pipeline still inflates an object.
# ============================================================================

{
    package Test::Status::RecordingIO;
    use Moo;
    with 'Kubernetes::REST::Role::IO';

    use JSON::MaybeXS ();

    has requests => (is => 'ro', default => sub { [] });
    has body     => (is => 'rw', default => sub { {} });
    has status   => (is => 'rw', default => sub { 200 });

    # Bytes on the wire, like a real backend
    my $wire_json = JSON::MaybeXS->new(utf8 => 1, canonical => 1);

    sub last_request { return $_[0]->requests->[-1] }

    sub call {
        my ($self, $req) = @_;
        push @{ $self->requests }, $req;
        return Kubernetes::REST::HTTPResponse->new(
            status  => $self->status,
            content => $wire_json->encode($self->body),
        );
    }

    sub call_streaming {
        my ($self, $req, $cb) = @_;
        push @{ $self->requests }, $req;
        return Kubernetes::REST::HTTPResponse->new(status => 200, content => '');
    }
}

my $json = JSON::MaybeXS->new(canonical => 1);

sub make_api {
    my ($io) = @_;
    my $default_map = IO::K8s->default_resource_map;
    return Kubernetes::REST->new(
        server      => Kubernetes::REST::Server->new(endpoint => 'https://mock.local'),
        credentials => Kubernetes::REST::AuthToken->new(token => 'MockToken'),
        resource_map_from_cluster => 0,
        resource_map => {
            %$default_map,
            StaticWebSite => '+My::StaticWebSite',
        },
        io => $io,
    );
}

# The document the server hands back for every status write below.
my %SITE = (
    apiVersion => 'homelab.example.com/v1',
    kind       => 'StaticWebSite',
    metadata   => {
        name            => 'blog',
        namespace       => 'web',
        resourceVersion => '4711',
        uid             => 'uid-site-1',
    },
    spec   => { domain => 'example.com' },
    status => { phase => 'Ready', url => 'https://example.com' },
);

# ============================================================================
# The consumer contract from the ticket
# ============================================================================

subtest 'patch_status and update_status are published methods' => sub {
    ok(Kubernetes::REST->can('patch_status'),
        'patch_status() exists - downstream probes for it with can()');
    ok(Kubernetes::REST->can('update_status'),
        'update_status() exists');
};

# ============================================================================
# _build_path / build_path with a subresource
# ============================================================================

subtest '_build_path addresses a subresource' => sub {
    my $api = make_api(Test::Status::RecordingIO->new);

    is $api->_build_path('My::StaticWebSite',
            name => 'blog', namespace => 'web', subresource => 'status'),
        '/apis/homelab.example.com/v1/namespaces/web/staticwebsites/blog/status',
        'namespaced CRD status path';

    is $api->_build_path('IO::K8s::Api::Core::V1::Node',
            name => 'cp-1', subresource => 'status'),
        '/api/v1/nodes/cp-1/status',
        'cluster-scoped core status path';

    is $api->_build_path('IO::K8s::Api::Core::V1::Pod',
            name => 'nginx', namespace => 'default'),
        '/api/v1/namespaces/default/pods/nginx',
        'no subresource argument leaves the path exactly as before';

    is $api->_build_path('IO::K8s::Api::Core::V1::Pod',
            name => 'nginx', namespace => 'default', subresource => undef),
        '/api/v1/namespaces/default/pods/nginx',
        'undef subresource is a no-op';
};

subtest '_build_path refuses a subresource without a name' => sub {
    my $api = make_api(Test::Status::RecordingIO->new);

    throws_ok {
        $api->_build_path('My::StaticWebSite',
            namespace => 'web', subresource => 'status');
    } qr/subresource 'status' requires a name/,
        'a nameless subresource would silently hit the collection endpoint';
};

subtest 'build_path is additive for async wrappers' => sub {
    my $api = make_api(Test::Status::RecordingIO->new);
    my $class = $api->expand_class('Pod');

    # The existing published call form must be untouched
    is $api->build_path($class, name => 'nginx', namespace => 'default'),
        '/api/v1/namespaces/default/pods/nginx',
        'two-argument form unchanged';

    is $api->build_path($class,
            name => 'nginx', namespace => 'default', subresource => 'status'),
        '/api/v1/namespaces/default/pods/nginx/status',
        'subresource reaches through the public wrapper';
};

# ============================================================================
# The four subresources that used to concatenate their own suffix
# ============================================================================

subtest 'streaming subresources build the same paths as before' => sub {
    my $api = make_api(Test::Status::RecordingIO->new);
    my $class = $api->expand_class('Pod');
    my $base = '/api/v1/namespaces/default/pods/nginx';

    for my $sub (qw(log exec attach portforward)) {
        is $api->_build_path($class,
                name => 'nginx', namespace => 'default', subresource => $sub),
            "$base/$sub", "$sub path";
    }
};

# ============================================================================
# patch_status - URL, method and Content-Type on the wire
# ============================================================================

subtest 'patch_status writes to /status with merge patch by default' => sub {
    my $io  = Test::Status::RecordingIO->new(body => \%SITE);
    my $api = make_api($io);

    my $site = $api->patch_status('StaticWebSite', 'blog',
        namespace => 'web',
        patch     => { status => { phase => 'Ready' } },
    );

    my $req = $io->last_request;
    is $req->method, 'PATCH', 'PATCH, not PUT';
    is $req->url,
        'https://mock.local/apis/homelab.example.com/v1/namespaces/web/staticwebsites/blog/status',
        'URL carries the /status suffix';
    is $req->headers->{'Content-Type'}, 'application/merge-patch+json',
        'defaults to merge patch - custom resources answer 415 to strategic';
    is_deeply $json->decode($req->content), { status => { phase => 'Ready' } },
        'patch document sent through unchanged';

    isa_ok $site, 'My::StaticWebSite';
    is $site->status->{phase}, 'Ready', 'response inflated into a typed object';
};

subtest 'patch_status honours an explicit patch type' => sub {
    my %expected = (
        strategic => 'application/strategic-merge-patch+json',
        merge     => 'application/merge-patch+json',
        json      => 'application/json-patch+json',
    );

    for my $type (sort keys %expected) {
        my $io  = Test::Status::RecordingIO->new(body => \%SITE);
        my $api = make_api($io);

        $api->patch_status('StaticWebSite', 'blog',
            namespace => 'web',
            type      => $type,
            patch     => { status => { phase => 'Ready' } },
        );

        is $io->last_request->headers->{'Content-Type'}, $expected{$type},
            "type '$type' sets the matching Content-Type";
        like $io->last_request->url, qr{/staticwebsites/blog/status$},
            "type '$type' still targets /status";
    }
};

subtest 'patch_status accepts a JSON Patch array' => sub {
    my $io  = Test::Status::RecordingIO->new(body => \%SITE);
    my $api = make_api($io);

    $api->patch_status('StaticWebSite', 'blog',
        namespace => 'web',
        type      => 'json',
        patch     => [{ op => 'replace', path => '/status/phase', value => 'Ready' }],
    );

    is_deeply $json->decode($io->last_request->content),
        [{ op => 'replace', path => '/status/phase', value => 'Ready' }],
        'arrayref patch document survives';
};

subtest 'patch_status takes an object like patch does' => sub {
    my $io  = Test::Status::RecordingIO->new(body => \%SITE);
    my $api = make_api($io);

    my $site = $api->k8s->struct_to_object('My::StaticWebSite', {
        apiVersion => 'homelab.example.com/v1',
        kind       => 'StaticWebSite',
        metadata   => { name => 'blog', namespace => 'web' },
        spec       => { domain => 'example.com' },
    });

    $api->patch_status($site, patch => { status => { phase => 'Ready' } });

    is $io->last_request->url,
        'https://mock.local/apis/homelab.example.com/v1/namespaces/web/staticwebsites/blog/status',
        'name and namespace taken from the object metadata';
    is $io->last_request->headers->{'Content-Type'}, 'application/merge-patch+json',
        'object form defaults to merge patch too';
};

subtest 'patch_status takes the fully keyed call form' => sub {
    my $io  = Test::Status::RecordingIO->new(body => \%SITE);
    my $api = make_api($io);

    $api->patch_status('StaticWebSite',
        name      => 'blog',
        namespace => 'web',
        patch     => { status => { phase => 'Ready' } },
    );

    like $io->last_request->url, qr{/namespaces/web/staticwebsites/blog/status$},
        'name => ... form reaches the same URL as the shorthand';
};

subtest 'patch_status on a cluster-scoped built-in' => sub {
    my $io = Test::Status::RecordingIO->new(body => {
        apiVersion => 'v1',
        kind       => 'Node',
        metadata   => { name => 'cp-1' },
        status     => { phase => 'Running' },
    });
    my $api = make_api($io);

    my $node = $api->patch_status('Node', 'cp-1',
        type  => 'strategic',
        patch => { status => { phase => 'Running' } },
    );

    is $io->last_request->url, 'https://mock.local/api/v1/nodes/cp-1/status',
        'cluster-scoped status URL has no namespace segment';
    isa_ok $node, 'IO::K8s::Api::Core::V1::Node';
};

# ============================================================================
# patch_status - croak behaviour, matching patch()
# ============================================================================

subtest 'patch_status croaks like patch does' => sub {
    my $api = make_api(Test::Status::RecordingIO->new(body => \%SITE));

    throws_ok {
        $api->patch_status('StaticWebSite', name => 'blog', namespace => 'web');
    } qr/patch_status requires 'patch' parameter/, 'dies without patch document';

    throws_ok {
        $api->patch_status('StaticWebSite', patch => { status => {} });
    } qr/name required for patch_status/, 'dies without name';

    throws_ok {
        $api->patch_status('StaticWebSite', 'blog',
            namespace => 'web',
            type      => 'invalid',
            patch     => { status => {} },
        );
    } qr/Unknown patch type 'invalid'/, 'dies on an unknown patch type';

    throws_ok {
        $api->patch_status('StaticWebSite', 'namespace');
    } qr/Invalid arguments to patch_status\(\)/, 'dies on an odd keyed argument list';
};

subtest 'patch() croak messages are unchanged' => sub {
    my $api = make_api(Test::Status::RecordingIO->new(body => \%SITE));

    throws_ok {
        $api->patch('StaticWebSite', name => 'blog', namespace => 'web');
    } qr/patch requires 'patch' parameter/, 'patch keeps its own wording';

    throws_ok {
        $api->patch('StaticWebSite', patch => {});
    } qr/name required for patch/, 'patch keeps its own name error';

    throws_ok {
        $api->patch('StaticWebSite', 'namespace');
    } qr/Invalid arguments to patch\(\)/, 'patch keeps its own argument error';
};

subtest 'patch_status propagates API errors' => sub {
    my $io  = Test::Status::RecordingIO->new(body => { message => 'nope' }, status => 422);
    my $api = make_api($io);

    throws_ok {
        $api->patch_status('StaticWebSite', 'blog',
            namespace => 'web',
            patch     => { status => { phase => 'Ready' } },
        );
    } qr/Kubernetes API error \(patch_status My::StaticWebSite\)/,
        'croak context names the method';
};

# ============================================================================
# update_status
# ============================================================================

subtest 'update_status PUTs the whole object to /status' => sub {
    my $io  = Test::Status::RecordingIO->new(body => \%SITE);
    my $api = make_api($io);

    my $site = $api->k8s->struct_to_object('My::StaticWebSite', {
        apiVersion => 'homelab.example.com/v1',
        kind       => 'StaticWebSite',
        metadata   => { name => 'blog', namespace => 'web', resourceVersion => '4711' },
        spec       => { domain => 'example.com' },
        status     => { phase => 'Ready', url => 'https://example.com' },
    });

    my $updated = $api->update_status($site);

    my $req = $io->last_request;
    is $req->method, 'PUT', 'PUT, not PATCH';
    is $req->url,
        'https://mock.local/apis/homelab.example.com/v1/namespaces/web/staticwebsites/blog/status',
        'URL carries the /status suffix';
    is $req->headers->{'Content-Type'}, 'application/json',
        'plain JSON body, no patch media type';

    my $sent = $json->decode($req->content);
    is $sent->{metadata}{resourceVersion}, '4711',
        'resourceVersion sent - a full replace needs it';
    is_deeply $sent->{status}, { phase => 'Ready', url => 'https://example.com' },
        'whole status sent';
    is $sent->{spec}{domain}, 'example.com', 'spec sent as part of the full object';

    isa_ok $updated, 'My::StaticWebSite';
    is $updated->status->{phase}, 'Ready', 'response inflated';
};

subtest 'update_status on a cluster-scoped built-in' => sub {
    my $io = Test::Status::RecordingIO->new(body => {
        apiVersion => 'v1',
        kind       => 'Node',
        metadata   => { name => 'cp-1' },
        status     => { phase => 'Running' },
    });
    my $api = make_api($io);

    my $node = $api->k8s->struct_to_object('IO::K8s::Api::Core::V1::Node', {
        apiVersion => 'v1',
        kind       => 'Node',
        metadata   => { name => 'cp-1' },
        status     => { phase => 'Running' },
    });

    $api->update_status($node);

    is $io->last_request->url, 'https://mock.local/api/v1/nodes/cp-1/status',
        'cluster-scoped status URL has no namespace segment';
};

subtest 'update_status croaks like update does' => sub {
    my $api = make_api(Test::Status::RecordingIO->new(body => \%SITE));

    my $nameless = $api->k8s->struct_to_object('My::StaticWebSite', {
        apiVersion => 'homelab.example.com/v1',
        kind       => 'StaticWebSite',
        metadata   => { namespace => 'web' },
    });

    throws_ok { $api->update_status($nameless) }
        qr/object must have metadata\.name/, 'dies without metadata.name';
};

subtest 'update_status propagates API errors' => sub {
    my $io  = Test::Status::RecordingIO->new(body => { message => 'conflict' }, status => 409);
    my $api = make_api($io);

    my $site = $api->k8s->struct_to_object('My::StaticWebSite', {
        apiVersion => 'homelab.example.com/v1',
        kind       => 'StaticWebSite',
        metadata   => { name => 'blog', namespace => 'web' },
        status     => { phase => 'Ready' },
    });

    throws_ok { $api->update_status($site) }
        qr/Kubernetes API error \(update_status My::StaticWebSite\): 409/,
        'croak context names the method and keeps the status code';
};

# ============================================================================
# The regression itself: a plain write must not go to /status, and a status
# write must not go to the main endpoint.
# ============================================================================

subtest 'the main endpoint and the status endpoint stay apart' => sub {
    my $io  = Test::Status::RecordingIO->new(body => \%SITE);
    my $api = make_api($io);

    $api->patch('StaticWebSite', 'blog',
        namespace => 'web',
        type      => 'merge',
        patch     => { spec => { domain => 'example.com' } },
    );
    unlike $io->last_request->url, qr{/status$},
        'patch() still writes to the main endpoint';

    $api->patch_status('StaticWebSite', 'blog',
        namespace => 'web',
        patch     => { status => { phase => 'Ready' } },
    );
    like $io->last_request->url, qr{/staticwebsites/blog/status$},
        'patch_status() writes to the status endpoint';

    is scalar @{ $io->requests }, 2, 'two requests, one each';
};

done_testing;
