#!/usr/bin/env perl
# karr k66: a v0 method for a Kind whose own name ends in Status resolves the
# whole Kind, not a Status subresource of a shorter one.
#
# ListComponentStatus / ReadComponentStatus were parsed as the Kind Component
# plus a Status suffix and died in the module loader with "Can't locate
# IO/K8s/Api/Core/V1/Component.pm", although IO::K8s ships ComponentStatus.
# _parse_method now recognises the Kinds IO::K8s knows that end in Status and
# keeps them whole, while a genuine status subresource (ReadNamespacedPodStatus,
# k62) still splits off its /status suffix.
use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/lib", "$FindBin::Bin/../lib";

use Test::Kubernetes::Mock ();
use Kubernetes::REST;
use Kubernetes::REST::V0Group;

# Records every request as 'METHOD /path?query'.
{
    package Test::K66::IO;
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
        io          => Test::K66::IO->new,
    );
}

my $CS = '/api/v1/componentstatuses';

subtest '_parse_method keeps a Status-named Kind whole' => sub {
    is_deeply([ Kubernetes::REST::V0Group::_parse_method('ListComponentStatus') ],
        [ 'list', 0, 'ComponentStatus', 0 ],
        'ListComponentStatus is the whole Kind, no status suffix');
    is_deeply([ Kubernetes::REST::V0Group::_parse_method('ReadComponentStatus') ],
        [ 'read', 0, 'ComponentStatus', 0 ],
        'ReadComponentStatus is the whole Kind, no status suffix');

    # A genuine status subresource still splits (k62): its shorter Kind is a
    # real Kind, ComponentStatus's leading "Component" is not.
    is_deeply([ Kubernetes::REST::V0Group::_parse_method('ReadNamespacedPodStatus') ],
        [ 'read', 1, 'Pod', 1 ],
        'ReadNamespacedPodStatus still splits Pod + status');
    is_deeply([ Kubernetes::REST::V0Group::_parse_method('ReadNamespacedDeploymentStatus') ],
        [ 'read', 1, 'Deployment', 1 ],
        'ReadNamespacedDeploymentStatus still splits Deployment + status');
};

subtest 'ListComponentStatus reaches componentstatuses' => sub {
    local $ENV{HIDE_KUBERNETES_REST_V0_API_WARNING} = 1;
    my $api = api();
    $api->io->add_response('GET', $CS,
        { apiVersion => 'v1', kind => 'ComponentStatusList', items => [
            { apiVersion => 'v1', kind => 'ComponentStatus',
              metadata => { name => 'scheduler' } },
        ] });

    my $list = $api->Core->ListComponentStatus;
    isa_ok($list, 'IO::K8s::List', 'ListComponentStatus');
    is_deeply($api->io->calls, [ "GET $CS" ], 'the whole-Kind collection path');
};

subtest 'ReadComponentStatus reaches one componentstatus' => sub {
    local $ENV{HIDE_KUBERNETES_REST_V0_API_WARNING} = 1;
    my $api = api();
    $api->io->add_response('GET', "$CS/scheduler",
        { apiVersion => 'v1', kind => 'ComponentStatus',
          metadata => { name => 'scheduler' } });

    my $cs = $api->Core->ReadComponentStatus(name => 'scheduler');
    isa_ok($cs, 'IO::K8s::Api::Core::V1::ComponentStatus', 'ReadComponentStatus');
    is_deeply($api->io->calls, [ "GET $CS/scheduler" ], 'the whole-Kind item path');
};

subtest 'a real status subresource still reads /status' => sub {
    local $ENV{HIDE_KUBERNETES_REST_V0_API_WARNING} = 1;
    my $api = api();
    my $pod_path = '/api/v1/namespaces/default/pods/web';
    $api->io->add_response('GET', "$pod_path/status",
        { apiVersion => 'v1', kind => 'Pod',
          metadata => { name => 'web', namespace => 'default' },
          status   => { phase => 'Running' } });

    my $pod = $api->Core->ReadNamespacedPodStatus(name => 'web', namespace => 'default');
    isa_ok($pod, 'IO::K8s::Api::Core::V1::Pod', 'ReadNamespacedPodStatus');
    is_deeply($api->io->calls, [ "GET $pod_path/status" ], 'still the /status subresource');
};

done_testing;
