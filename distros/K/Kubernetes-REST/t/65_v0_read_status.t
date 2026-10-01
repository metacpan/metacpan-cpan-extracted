#!/usr/bin/env perl
# karr k62: the v0 Read*Status methods read the status subresource.
#
# V0Group parsed the Status suffix off ReadNamespacedPodStatus and dropped
# it: the call read the object itself, GET .../pods/web instead of
# .../pods/web/status. Since k58 get takes subresource => 'status', and
# Read*Status now passes it on - and says so in its deprecation warning, the
# call to migrate to.
use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/lib", "$FindBin::Bin/../lib";

use Test::Kubernetes::Mock ();
use Kubernetes::REST;

# Records every request as 'METHOD /path?query'.
{
    package Test::K62::IO;
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
        io          => Test::K62::IO->new,
    );
}

my $POD_PATH = '/api/v1/namespaces/default/pods/web';
my %POD = (apiVersion => 'v1', kind => 'Pod',
    metadata => { name => 'web', namespace => 'default' },
    status   => { phase => 'Running' });

subtest 'Read*Status reads the status subresource' => sub {
    local $ENV{HIDE_KUBERNETES_REST_V0_API_WARNING} = 1;
    my $api = api();
    $api->io->add_response('GET', "$POD_PATH/status", \%POD);
    $api->io->add_response('GET', '/api/v1/nodes/n1/status',
        { apiVersion => 'v1', kind => 'Node', metadata => { name => 'n1' } });
    $api->io->add_response('GET', '/apis/apps/v1/namespaces/default/deployments/web/status',
        { apiVersion => 'apps/v1', kind => 'Deployment',
          metadata => { name => 'web', namespace => 'default' },
          spec     => { selector => { matchLabels => { app => 'web' } },
                        template => { spec => { containers => [
                            { name => 'web', image => 'nginx' } ] } } } });

    my $pod = $api->Core->ReadNamespacedPodStatus(name => 'web', namespace => 'default',
        pretty => 'true');
    isa_ok($pod, 'IO::K8s::Api::Core::V1::Pod', 'ReadNamespacedPodStatus');
    is($pod->status->phase, 'Running', 'with its status');
    isa_ok($api->Core->ReadNodeStatus(name => 'n1'), 'IO::K8s::Api::Core::V1::Node',
        'ReadNodeStatus');
    isa_ok($api->Apps->ReadNamespacedDeploymentStatus(name => 'web', namespace => 'default'),
        'IO::K8s::Api::Apps::V1::Deployment', 'ReadNamespacedDeploymentStatus');

    is_deeply($api->io->calls, [
        "GET $POD_PATH/status",
        'GET /api/v1/nodes/n1/status',
        'GET /apis/apps/v1/namespaces/default/deployments/web/status',
    ], 'each from its /status, namespaced and cluster-scoped');
};

subtest 'Read* without Status still reads the object' => sub {
    local $ENV{HIDE_KUBERNETES_REST_V0_API_WARNING} = 1;
    my $api = api();
    $api->io->add_response('GET', $POD_PATH, \%POD);
    $api->Core->ReadNamespacedPod(name => 'web', namespace => 'default');
    is_deeply($api->io->calls, [ "GET $POD_PATH" ], 'the object itself');
};

subtest 'the deprecation warning names the status subresource' => sub {
    local $ENV{HIDE_KUBERNETES_REST_V0_API_WARNING};
    delete $ENV{HIDE_KUBERNETES_REST_V0_API_WARNING};
    my $api = api();
    $api->io->add_response('GET', "$POD_PATH/status", \%POD);
    $api->io->add_response('GET', $POD_PATH, \%POD);

    my @warnings;
    local $SIG{__WARN__} = sub { push @warnings, $_[0] };
    $api->Core->ReadNamespacedPodStatus(name => 'web', namespace => 'default');
    $api->Core->ReadNamespacedPod(name => 'web', namespace => 'default');

    is(scalar @warnings, 2, 'one warning per call');
    like($warnings[0], qr/ReadNamespacedPodStatus\(\.\.\.\) should be: \$api->get\('IO::K8s::Api::Core::V1::Pod', name => 'web', namespace => 'default', subresource => 'status'\)/,
        'Read*Status: the get call that reads /status');
    like($warnings[1], qr/ReadNamespacedPod\(\.\.\.\) should be: \$api->get\('IO::K8s::Api::Core::V1::Pod', name => 'web', namespace => 'default'\) at /,
        'Read*: the get call without it');
};

done_testing;
