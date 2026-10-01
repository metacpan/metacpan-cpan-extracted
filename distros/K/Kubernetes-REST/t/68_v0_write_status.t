#!/usr/bin/env perl
# karr k65: the v0 Replace*Status and Patch*Status methods write to the
# /status subresource, not to the main endpoint.
#
# ReplaceNamespacedPodStatus went out as PUT .../pods/web and
# PatchNamespacedPodStatus as PATCH .../pods/web. The API server strips the
# status stanza from a write to the main endpoint and still answers 2xx, so
# the status was silently discarded. Since k62 the Status suffix is parsed
# off; Replace*Status now dispatches to update_status and Patch*Status to
# patch_status, both of which target .../status - and each names that call in
# its deprecation warning.
use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/lib", "$FindBin::Bin/../lib";

use Test::Kubernetes::Mock ();
use Kubernetes::REST;

# Records every request as 'METHOD /path?query'.
{
    package Test::K65::IO;
    use Moo;
    extends 'Test::Kubernetes::Mock::IO';

    has calls => (is => 'ro', default => sub { [] });

    around call => sub {
        my ($orig, $self, $req) = @_;
        (my $path = $req->url) =~ s{\Ahttps?://[^/]+}{};
        push @{ $self->calls }, $req->method . ' ' . $path;
        return $self->$orig($req);
    };
}

sub api {
    return Kubernetes::REST->new(
        server      => { endpoint => 'http://mock.local' },
        credentials => { token => 'MockToken' },
        resource_map_from_cluster => 0,
        io          => Test::K65::IO->new,
    );
}

my $POD_PATH  = '/api/v1/namespaces/default/pods/web';
my $NODE_PATH = '/api/v1/nodes/n1';

sub pod {
    my ($api) = @_;
    return $api->new_object(Pod => {
        metadata => { name => 'web', namespace => 'default' },
        status   => { phase => 'Running' },
    });
}

sub node {
    my ($api) = @_;
    return $api->new_object(Node => { metadata => { name => 'n1' } });
}

subtest 'Replace*Status replaces through /status' => sub {
    local $ENV{HIDE_KUBERNETES_REST_V0_API_WARNING} = 1;
    my $api = api();
    $api->io->add_response('PUT', "$POD_PATH/status",
        { apiVersion => 'v1', kind => 'Pod',
          metadata => { name => 'web', namespace => 'default' },
          status   => { phase => 'Running' } });
    $api->io->add_response('PUT', "$NODE_PATH/status",
        { apiVersion => 'v1', kind => 'Node', metadata => { name => 'n1' } });

    my $pod = $api->Core->ReplaceNamespacedPodStatus(body => pod($api),
        name => 'web', namespace => 'default', pretty => 'true');
    isa_ok($pod, 'IO::K8s::Api::Core::V1::Pod', 'ReplaceNamespacedPodStatus');
    isa_ok($api->Core->ReplaceNodeStatus(body => node($api)),
        'IO::K8s::Api::Core::V1::Node', 'ReplaceNodeStatus');

    is_deeply($api->io->calls, [
        "PUT $POD_PATH/status",
        "PUT $NODE_PATH/status",
    ], 'each PUT to its /status, namespaced and cluster-scoped');
};

subtest 'Patch*Status patches through /status' => sub {
    local $ENV{HIDE_KUBERNETES_REST_V0_API_WARNING} = 1;
    my $api = api();
    $api->io->add_response('PATCH', "$POD_PATH/status",
        { apiVersion => 'v1', kind => 'Pod', metadata => { name => 'web' } });
    $api->io->add_response('PATCH', "$NODE_PATH/status",
        { apiVersion => 'v1', kind => 'Node', metadata => { name => 'n1' } });

    my $pod = $api->Core->PatchNamespacedPodStatus(name => 'web',
        namespace => 'default', patch => { status => { phase => 'Ready' } });
    isa_ok($pod, 'IO::K8s::Api::Core::V1::Pod', 'PatchNamespacedPodStatus');
    isa_ok($api->Core->PatchNodeStatus(name => 'n1',
        patch => { status => { phase => 'Ready' } }),
        'IO::K8s::Api::Core::V1::Node', 'PatchNodeStatus');

    is_deeply($api->io->calls, [
        "PATCH $POD_PATH/status",
        "PATCH $NODE_PATH/status",
    ], 'each PATCH to its /status, namespaced and cluster-scoped');
};

subtest 'Replace/Patch without Status still write the main endpoint' => sub {
    local $ENV{HIDE_KUBERNETES_REST_V0_API_WARNING} = 1;
    my $api = api();
    $api->io->add_response('PUT', $POD_PATH,
        { apiVersion => 'v1', kind => 'Pod',
          metadata => { name => 'web', namespace => 'default' } });
    $api->io->add_response('PATCH', $POD_PATH,
        { apiVersion => 'v1', kind => 'Pod',
          metadata => { name => 'web', namespace => 'default' } });

    $api->Core->ReplaceNamespacedPod(body => pod($api),
        name => 'web', namespace => 'default');
    $api->Core->PatchNamespacedPod(name => 'web', namespace => 'default',
        patch => { metadata => { labels => { a => 'b' } } });

    is_deeply($api->io->calls, [
        "PUT $POD_PATH",
        "PATCH $POD_PATH",
    ], 'the object itself, no /status suffix');
};

subtest 'the deprecation warning names the status write' => sub {
    local $ENV{HIDE_KUBERNETES_REST_V0_API_WARNING};
    delete $ENV{HIDE_KUBERNETES_REST_V0_API_WARNING};
    my $api = api();
    $api->io->add_response('PUT', "$POD_PATH/status",
        { apiVersion => 'v1', kind => 'Pod', metadata => { name => 'web' } });
    $api->io->add_response('PATCH', "$POD_PATH/status",
        { apiVersion => 'v1', kind => 'Pod', metadata => { name => 'web' } });

    my @warnings;
    local $SIG{__WARN__} = sub { push @warnings, $_[0] };
    $api->Core->ReplaceNamespacedPodStatus(body => pod($api),
        name => 'web', namespace => 'default');
    $api->Core->PatchNamespacedPodStatus(name => 'web',
        namespace => 'default', patch => { status => { phase => 'Ready' } });

    is(scalar @warnings, 2, 'one warning per call');
    like($warnings[0],
        qr/ReplaceNamespacedPodStatus\(\.\.\.\) should be: \$api->update_status\(\$object\)/,
        'Replace*Status: the update_status call');
    like($warnings[1],
        qr/PatchNamespacedPodStatus\(\.\.\.\) should be: \$api->patch_status\('IO::K8s::Api::Core::V1::Pod', name => 'web', namespace => 'default', patch => \\%patch\)/,
        'Patch*Status: the patch_status call');
};

done_testing;
