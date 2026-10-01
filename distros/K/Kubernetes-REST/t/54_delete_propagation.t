#!/usr/bin/env perl
# karr k49: delete sends propagationPolicy; ensure_only prunes and ensure
# recreates a Job with Background.
#
# delete could not send DeleteOptions. A batch/v1 Job deleted without a
# propagationPolicy leaves its Pods behind (the API default for Jobs is to
# orphan them). delete now takes propagationPolicy => Background | Foreground
# | Orphan, sent as the query parameter the API server reads DeleteOptions
# from, and croaks on any other option key - a typo such as
# propagation_policy must not silently orphan Pods. ensure_only prunes with
# Background unless told otherwise (what kubectl delete does), and ensure
# deletes the failed Job it recreates with Background.
use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/lib", "$FindBin::Bin/../lib";

use Test::Kubernetes::Mock ();
use Kubernetes::REST;

# Records every request as 'METHOD /path?query' and answers every DELETE with
# success, whatever its query; everything else goes to the mock.
{
    package Test::Propagation::IO;
    use Moo;
    extends 'Test::Kubernetes::Mock::IO';

    use JSON::MaybeXS ();

    has calls => (is => 'ro', default => sub { [] });

    my $wire_json = JSON::MaybeXS->new(utf8 => 1, canonical => 1);

    around call => sub {
        my ($orig, $self, $req) = @_;
        (my $path = $req->url) =~ s{\Ahttps?://[^/]+}{};
        push @{ $self->calls }, $req->method . ' ' . $path;
        return $self->$orig($req) unless $req->method eq 'DELETE';
        return Test::Kubernetes::Mock::Response->new(
            status  => 200,
            content => $wire_json->encode(
                { kind => 'Status', apiVersion => 'v1', status => 'Success' }),
        );
    };
}

sub api {
    return Kubernetes::REST->new(
        server      => { endpoint => 'http://mock.local' },
        credentials => { token => 'MockToken' },
        resource_map_from_cluster => 0,
        io          => Test::Propagation::IO->new,
    );
}

my $PODS = '/api/v1/namespaces/default/pods';

subtest 'every call form sends the query parameter' => sub {
    my $pod_of = sub {
        $_[0]->new_object(Pod => { metadata => { name => 'web', namespace => 'default' } });
    };
    for my $case (
        [ 'object', 'Background', sub {
            $_[0]->delete($pod_of->($_[0]), propagationPolicy => 'Background') } ],
        [ 'shorthand name', 'Foreground', sub {
            $_[0]->delete('Pod', 'web', namespace => 'default', propagationPolicy => 'Foreground') } ],
        [ 'name =>', 'Orphan', sub {
            $_[0]->delete('Pod', name => 'web', namespace => 'default', propagationPolicy => 'Orphan') } ],
        [ 'option first', 'Background', sub {
            $_[0]->delete('Pod', propagationPolicy => 'Background', name => 'web', namespace => 'default') } ],
    ) {
        my ($form, $policy, $call) = @$case;
        my $api = api();
        ok($call->($api), "$form: delete returns true");
        is_deeply($api->io->calls, [ "DELETE $PODS/web?propagationPolicy=$policy" ],
            "$form: propagationPolicy=$policy in the query");
    }

    my $api = api();
    $api->delete('Namespace', 'ns1', propagationPolicy => 'Foreground');
    is_deeply($api->io->calls, [ 'DELETE /api/v1/namespaces/ns1?propagationPolicy=Foreground' ],
        'cluster-scoped shorthand: the name, then the option');
};

subtest 'without the option: no query, as before' => sub {
    for my $call (
        sub { $_[0]->delete('Pod', 'web', namespace => 'default') },
        sub { $_[0]->delete('Pod', 'web', namespace => 'default', propagationPolicy => undef) },
        sub { $_[0]->delete($_[0]->new_object(Pod =>
                  { metadata => { name => 'web', namespace => 'default' } })) },
    ) {
        my $api = api();
        $call->($api);
        is_deeply($api->io->calls, [ "DELETE $PODS/web" ], 'no propagationPolicy sent');
    }
};

subtest 'an unknown propagationPolicy croaks, before any request' => sub {
    my $api = api();
    eval { $api->delete('Pod', 'web', namespace => 'default', propagationPolicy => 'background') };
    like($@, qr/\AUnknown propagationPolicy 'background' for delete\(\) \(use: Background, Foreground, Orphan\)/,
        'names the value and the allowed ones');
    is_deeply($api->io->calls, [], 'nothing was sent');
};

subtest 'an unknown option croaks, before any request' => sub {
    my $pod = api()->new_object(Pod => { metadata => { name => 'web', namespace => 'default' } });
    for my $case (
        [ 'object, typo', 'propagation_policy', sub {
            $_[0]->delete($pod, propagation_policy => 'Orphan') } ],
        [ 'object, namespace', 'namespace', sub {
            $_[0]->delete($pod, namespace => 'other') } ],
        [ 'shorthand, typo', 'propagation_policy', sub {
            $_[0]->delete('Pod', 'web', namespace => 'default', propagation_policy => 'Orphan') } ],
        [ 'name =>, other option', 'gracePeriodSeconds', sub {
            $_[0]->delete('Pod', name => 'web', namespace => 'default', gracePeriodSeconds => 0) } ],
    ) {
        my ($form, $key, $call) = @$case;
        my $api = api();
        eval { $call->($api) };
        like($@, qr/\AUnknown argument '\Q$key\E' to delete\(\)/, "$form: croaks naming '$key'");
        like($@, qr/propagationPolicy/, "$form: lists what is allowed");
        is_deeply($api->io->calls, [], "$form: nothing was sent");
    }
};

# ensure_only: a labelled ConfigMap 'stale' that is not in the set is pruned.
my $CM  = '/api/v1/namespaces/default/configmaps';
my $SEL = '?labelSelector=app=demo';

sub cm_item {
    my ($name) = @_;
    return { metadata => { name => $name, namespace => 'default', labels => { app => 'demo' } } };
}

sub prune_api {
    my $api = api();
    $api->io->add_response('POST', $CM, {
        apiVersion => 'v1', kind => 'ConfigMap',
        metadata   => { %{ cm_item('keep-me')->{metadata} }, resourceVersion => '1' },
    });
    $api->io->add_response('GET', $CM . $SEL, {
        apiVersion => 'v1', kind => 'ConfigMapList',
        items      => [ cm_item('keep-me'), cm_item('stale') ],
    });
    return $api;
}

sub prune {
    my ($api, @opts) = @_;
    my @warnings;
    local $SIG{__WARN__} = sub { push @warnings, @_ };
    my @applied = $api->ensure_only(
        label      => 'app=demo',
        objects    => [ { apiVersion => 'v1', kind => 'ConfigMap', %{ cm_item('keep-me') } } ],
        kinds      => ['ConfigMap'],
        namespaces => ['default'],
        @opts,
    );
    return (\@applied, \@warnings);
}

subtest 'ensure_only prunes with Background by default' => sub {
    my $api = prune_api();
    my ($applied, $warnings) = prune($api);
    is(scalar @$applied, 1, 'the object is applied');
    is_deeply($warnings, [], 'no warning');
    is_deeply([ grep { /^DELETE / } @{ $api->io->calls } ],
        [ "DELETE $CM/stale?propagationPolicy=Background" ],
        'only stale is deleted, with propagationPolicy=Background');
};

subtest 'ensure_only takes another propagationPolicy' => sub {
    my $api = prune_api();
    prune($api, propagationPolicy => 'Orphan');
    is_deeply([ grep { /^DELETE / } @{ $api->io->calls } ],
        [ "DELETE $CM/stale?propagationPolicy=Orphan" ],
        'the stale item is deleted with propagationPolicy=Orphan');
};

subtest 'ensure_only with an unknown propagationPolicy croaks before applying anything' => sub {
    my $api = prune_api();
    eval { prune($api, propagationPolicy => 'Everything') };
    like($@, qr/\AUnknown propagationPolicy 'Everything' for ensure_only\(\) \(use: Background, Foreground, Orphan\)/,
        'names the value and the allowed ones');
    is_deeply($api->io->calls, [], 'nothing was sent');
};

# ensure: an existing failed batch/v1 Job is deleted and recreated - its Pods
# must go with it.
subtest 'ensure deletes a failed Job with Background before recreating it' => sub {
    my $JOBS = '/apis/batch/v1/namespaces/default/jobs';
    my %job = (
        apiVersion => 'batch/v1', kind => 'Job',
        metadata   => { name => 'broken', namespace => 'default' },
        spec       => { template => { spec => { restartPolicy => 'Never',
                          containers => [ { name => 'c', image => 'busybox' } ] } } },
    );
    my $api = api();
    $api->io->add_response('GET', "$JOBS/broken",
        { %job, metadata => { %{ $job{metadata} }, resourceVersion => '5' },
          status => { failed => 1 } });
    $api->io->add_response('POST', $JOBS,
        { %job, metadata => { %{ $job{metadata} }, resourceVersion => '6' } });

    my $result = $api->ensure({ %job });
    is($result->metadata->resourceVersion, '6', 'the recreated Job is returned');
    is_deeply($api->io->calls,
        [ "GET $JOBS/broken", "DELETE $JOBS/broken?propagationPolicy=Background", "POST $JOBS" ],
        'deleted with propagationPolicy=Background, then created');
};

# The v0 layer hands its parameters to delete as they came; the v0 ones delete
# does not take are dropped there, as they always were, instead of croaking.
subtest 'v0 DeleteNamespacedPod keeps working with v0-only parameters' => sub {
    local $ENV{HIDE_KUBERNETES_REST_V0_API_WARNING} = 1;
    my $api = api();
    ok($api->Core->DeleteNamespacedPod(
        name               => 'web',
        namespace          => 'default',
        body               => { gracePeriodSeconds => 0 },
        gracePeriodSeconds => 0,
        propagationPolicy  => 'Foreground',
    ), 'the v0 call succeeds');
    is_deeply($api->io->calls, [ "DELETE $PODS/web?propagationPolicy=Foreground" ],
        'propagationPolicy is passed on, the other v0 parameters are dropped');
};

done_testing;
