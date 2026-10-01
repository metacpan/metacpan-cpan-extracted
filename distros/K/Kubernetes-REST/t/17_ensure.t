#!/usr/bin/env perl
# Tests for ensure / ensure_all idempotent apply

use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/lib";
use lib "$FindBin::Bin/../lib";

use Test::Kubernetes::Mock qw(mock_api);
use Kubernetes::REST;
use Kubernetes::REST::Server;
use Kubernetes::REST::AuthToken;
use IO::K8s::Unstructured;

my $api = mock_api();
my $io  = $api->io;
my $k8s = $api->k8s;

sub add {
    my ($method, $path, $data) = @_;
    $io->add_response($method, $path, $data);
}

sub ns_obj {
    my ($name) = @_;
    return $k8s->new_object('Namespace', metadata => { name => $name });
}

# Case 1: resource does not exist — ensure creates it.
{
    # The mock returns 404 by default for unknown GETs; register a POST mock.
    add('POST', '/api/v1/namespaces', {
        apiVersion => 'v1',
        kind       => 'Namespace',
        metadata   => { name => 'new-ns', resourceVersion => '1' },
    });

    my $obj = ns_obj('new-ns');
    my $result = $api->ensure($obj);
    isa_ok($result, 'IO::K8s::Api::Core::V1::Namespace', 'create path: typed result');
    is($result->metadata->name, 'new-ns', 'create path: name matches');
    is($result->metadata->resourceVersion, '1', 'create path: resourceVersion present');
}

# Case 2: resource exists — ensure updates it and preserves resourceVersion.
{
    add('GET', '/api/v1/namespaces/existing-ns', {
        apiVersion => 'v1',
        kind       => 'Namespace',
        metadata   => { name => 'existing-ns', resourceVersion => '42' },
    });
    add('PUT', '/api/v1/namespaces/existing-ns', {
        apiVersion => 'v1',
        kind       => 'Namespace',
        metadata   => { name => 'existing-ns', resourceVersion => '43' },
    });

    my $obj = ns_obj('existing-ns');
    my $result = $api->ensure($obj);
    is($result->metadata->name, 'existing-ns', 'update path: name matches');
    is($result->metadata->resourceVersion, '43', 'update path: new resourceVersion');
    is($obj->metadata->resourceVersion, '42', 'update path: rv copied from existing before PUT');
}

# Case 3: ensure_all applies each object.
{
    add('POST', '/api/v1/namespaces', {
        apiVersion => 'v1',
        kind       => 'Namespace',
        metadata   => { name => 'batch-a' },
    });

    my @results = $api->ensure_all(ns_obj('batch-a'));
    is(scalar @results, 1, 'ensure_all returns one result per input');
    is($results[0]->metadata->name, 'batch-a', 'ensure_all preserves order');
}

# Case 4: PVC is immutable — existing PVC returned unchanged, no PUT attempted.
{
    add('GET', '/api/v1/namespaces/default/persistentvolumeclaims/data', {
        apiVersion => 'v1',
        kind       => 'PersistentVolumeClaim',
        metadata   => { name => 'data', namespace => 'default', resourceVersion => '7' },
        spec       => { accessModes => ['ReadWriteOnce'] },
    });
    # Deliberately no PUT mock — ensure must not attempt one.

    my $pvc = $k8s->new_object('PersistentVolumeClaim',
        metadata => { name => 'data', namespace => 'default' },
    );
    my $result = eval { $api->ensure($pvc) };
    ok(!$@, 'ensure on existing PVC does not die') or diag $@;
    is($result && $result->metadata->name, 'data', 'PVC: returns existing object');
}

# Case 5: hashref input — inflated via struct_to_object, then create.
{
    add('POST', '/api/v1/namespaces/default/secrets', {
        apiVersion => 'v1',
        kind       => 'Secret',
        metadata   => { name => 'my-secret', namespace => 'default', resourceVersion => '1' },
    });

    my $result = $api->ensure({
        apiVersion => 'v1',
        kind       => 'Secret',
        metadata   => { name => 'my-secret', namespace => 'default' },
        stringData => { password => 'hunter2' },
    });
    isa_ok($result, 'IO::K8s::Api::Core::V1::Secret', 'hashref path: typed result');
    is($result->metadata->name, 'my-secret', 'hashref path: name matches');
}

# karr k34: a hashref manifest resolves through its apiVersion. The bare Kind
# HorizontalPodAutoscaler maps to autoscaling/v2; an autoscaling/v1 manifest
# must stay v1 - class, endpoint and the apiVersion in the request body.
my $HPA_V1 = '/apis/autoscaling/v1/namespaces/default/horizontalpodautoscalers';
my $HPA_V2 = '/apis/autoscaling/v2/namespaces/default/horizontalpodautoscalers';

sub hpa_manifest {
    my ($name, %extra) = @_;
    return {
        kind     => 'HorizontalPodAutoscaler',
        metadata => { name => $name, namespace => 'default' },
        spec     => {
            scaleTargetRef => { apiVersion => 'apps/v1', kind => 'Deployment', name => 'web' },
            maxReplicas    => 3,
        },
        %extra,
    };
}

sub requests_since {
    my ($mark) = @_;
    my @requests = @{ $io->requests };
    return @requests[ $mark .. $#requests ];
}

# Case 6: apiVersion autoscaling/v1 - v1 class, v1 endpoint, v1 body.
{
    add('POST', $HPA_V1, {
        %{ hpa_manifest('hpa-v1', apiVersion => 'autoscaling/v1') },
        metadata => { name => 'hpa-v1', namespace => 'default', resourceVersion => '1' },
    });

    my $mark = @{ $io->requests };
    my $result = eval { $api->ensure(hpa_manifest('hpa-v1', apiVersion => 'autoscaling/v1')) };
    is($@, '', 'apiVersion hashref: ensure does not die');
    isa_ok($result, 'IO::K8s::Api::Autoscaling::V1::HorizontalPodAutoscaler',
        'apiVersion hashref: result');

    my ($post) = grep { $_->{method} eq 'POST' } requests_since($mark);
    is($post && $post->{path}, $HPA_V1,
        'apiVersion hashref: created on the autoscaling/v1 endpoint');
    like($post && $post->{content}, qr{"apiVersion":"autoscaling/v1"},
        'apiVersion hashref: the body still says autoscaling/v1');
}

# Case 7: no apiVersion - the bare Kind resolves as before (its default, v2).
{
    add('POST', $HPA_V2, {
        %{ hpa_manifest('hpa-bare', apiVersion => 'autoscaling/v2') },
        metadata => { name => 'hpa-bare', namespace => 'default', resourceVersion => '1' },
    });

    my $mark = @{ $io->requests };
    my $result = eval { $api->ensure(hpa_manifest('hpa-bare')) };
    is($@, '', 'bare-Kind hashref: ensure does not die');
    isa_ok($result, 'IO::K8s::Api::Autoscaling::V2::HorizontalPodAutoscaler',
        'bare-Kind hashref: result');
    my ($post) = grep { $_->{method} eq 'POST' } requests_since($mark);
    is($post && $post->{path}, $HPA_V2,
        'bare-Kind hashref: created on the default (v2) endpoint');
}

# Case 8: an apiVersion no class serves croaks - no silent fallback to the
# bare Kind's default version, and nothing is sent.
{
    my $mark = @{ $io->requests };
    eval { $api->ensure(hpa_manifest('hpa-v9', apiVersion => 'autoscaling/v9')) };
    like($@, qr{autoscaling/v9}, 'unknown apiVersion: the error names the apiVersion');
    like($@, qr{HorizontalPodAutoscaler}, 'unknown apiVersion: the error names the Kind');
    is(scalar(my @sent = requests_since($mark)), 0, 'unknown apiVersion: no request sent');
}

# ---------------------------------------------------------------------------
# karr k36: the PersistentVolumeClaim and Job special cases belong to the
# built-in Kinds - core v1 PersistentVolumeClaim and batch/v1 Job - recognised
# by apiVersion and Kind, not by the last segment of the class name. A custom
# resource that reuses one of those Kind names in its own group is ensured like
# any other object: GET, then PUT at the server's resourceVersion.
# ---------------------------------------------------------------------------
sub calls_since {
    my ($api_io, $mark) = @_;
    my @requests = @{ $api_io->requests };
    return [ map { "$_->{method} $_->{path}" } @requests[ $mark .. $#requests ] ];
}

my $PIPELINE = '/apis/pipeline.example.com/v1/namespaces/default';

# Case 9: a CRD Kind named Job in its own group. The Job path would call
# status->succeeded on its plain-map status and die, or - without a status -
# delete and recreate the object instead of updating it.
{
    add('GET', "$PIPELINE/jobs/nightly", {
        apiVersion => 'pipeline.example.com/v1',
        kind       => 'Job',
        metadata   => { name => 'nightly', namespace => 'default', resourceVersion => '5' },
        spec       => { schedule => 'daily' },
        status     => { phase => 'Running' },
    });
    add('PUT', "$PIPELINE/jobs/nightly", {
        apiVersion => 'pipeline.example.com/v1',
        kind       => 'Job',
        metadata   => { name => 'nightly', namespace => 'default', resourceVersion => '6' },
        spec       => { schedule => 'hourly' },
    });

    my $job = $k8s->new_object('+My::Pipeline::Job',
        metadata => { name => 'nightly', namespace => 'default' },
        spec     => { schedule => 'hourly' },
    );
    my $mark = @{ $io->requests };
    my $result = eval { $api->ensure($job) };
    is($@, '', 'CRD Job: ensure does not die');
    isa_ok($result, 'My::Pipeline::Job', 'CRD Job: result');
    is_deeply(calls_since($io, $mark),
        [ "GET $PIPELINE/jobs/nightly", "PUT $PIPELINE/jobs/nightly" ],
        'CRD Job: a plain GET then PUT - no batch Job delete/recreate');
    is($job->metadata->resourceVersion, '5', 'CRD Job: PUT at the server resourceVersion');
    is($result && $result->metadata->resourceVersion, '6', 'CRD Job: the updated object is returned');
}

# Case 10: a CRD Kind named PersistentVolumeClaim in its own group. The PVC
# path would return the existing object and silently drop the update.
{
    add('GET', "$PIPELINE/persistentvolumeclaims/cache", {
        apiVersion => 'pipeline.example.com/v1',
        kind       => 'PersistentVolumeClaim',
        metadata   => { name => 'cache', namespace => 'default', resourceVersion => '8' },
        spec       => { size => '1Gi' },
    });
    add('PUT', "$PIPELINE/persistentvolumeclaims/cache", {
        apiVersion => 'pipeline.example.com/v1',
        kind       => 'PersistentVolumeClaim',
        metadata   => { name => 'cache', namespace => 'default', resourceVersion => '9' },
        spec       => { size => '2Gi' },
    });

    my $claim = $k8s->new_object('+My::Pipeline::PersistentVolumeClaim',
        metadata => { name => 'cache', namespace => 'default' },
        spec     => { size => '2Gi' },
    );
    my $mark = @{ $io->requests };
    my $result = eval { $api->ensure($claim) };
    is($@, '', 'CRD PersistentVolumeClaim: ensure does not die');
    is_deeply(calls_since($io, $mark),
        [ "GET $PIPELINE/persistentvolumeclaims/cache", "PUT $PIPELINE/persistentvolumeclaims/cache" ],
        'CRD PersistentVolumeClaim: updated, not returned unchanged');
    is($result && $result->metadata->resourceVersion, '9',
        'CRD PersistentVolumeClaim: the updated object is returned');
}

# Cases 11 and 12: the real batch/v1 Job keeps its special case - a succeeded
# Job is returned unchanged, a failed one is deleted and recreated. Never a PUT.
my $JOBS = '/apis/batch/v1/namespaces/default/jobs';

sub batch_job {
    my ($name, %extra) = @_;
    return {
        apiVersion => 'batch/v1',
        kind       => 'Job',
        metadata   => { name => $name, namespace => 'default' },
        spec       => {
            template => {
                spec => {
                    restartPolicy => 'Never',
                    containers    => [ { name => 'run', image => 'busybox' } ],
                },
            },
        },
        %extra,
    };
}

{
    add('GET', "$JOBS/done", {
        %{ batch_job('done', status => { succeeded => 1 }) },
        metadata => { name => 'done', namespace => 'default', resourceVersion => '3' },
    });

    my $mark = @{ $io->requests };
    my $result = eval { $api->ensure(batch_job('done')) };
    is($@, '', 'batch/v1 Job succeeded: ensure does not die');
    isa_ok($result, 'IO::K8s::Api::Batch::V1::Job', 'batch/v1 Job succeeded: result');
    is_deeply(calls_since($io, $mark), [ "GET $JOBS/done" ],
        'batch/v1 Job succeeded: returned unchanged, nothing written');
    is($result && $result->metadata->resourceVersion, '3',
        'batch/v1 Job succeeded: the existing object is returned');
}

{
    add('GET', "$JOBS/broken", {
        %{ batch_job('broken', status => { failed => 1 }) },
        metadata => { name => 'broken', namespace => 'default', resourceVersion => '4' },
    });
    add('DELETE', "$JOBS/broken?propagationPolicy=Background",
        { kind => 'Status', apiVersion => 'v1', status => 'Success' });
    add('POST', $JOBS, {
        %{ batch_job('broken') },
        metadata => { name => 'broken', namespace => 'default', resourceVersion => '10' },
    });

    my $mark = @{ $io->requests };
    my $result = eval { $api->ensure(batch_job('broken')) };
    is($@, '', 'batch/v1 Job failed: ensure does not die');
    is_deeply(calls_since($io, $mark),
        [ "GET $JOBS/broken", "DELETE $JOBS/broken", "POST $JOBS" ],
        'batch/v1 Job failed: deleted and recreated, no PUT');
    is($result && $result->metadata->resourceVersion, '10',
        'batch/v1 Job failed: the recreated object is returned');
}

# Cases 13-15: IO::K8s::Unstructured follows the same rule through its
# instance data - its class name says nothing about the Kind it holds.
{
    my $uio = Test::Kubernetes::Mock::IO->new;
    $uio->add_response('GET', '/api', {
        kind  => 'APIGroupDiscoveryList',
        items => [ { metadata => { name => '' }, versions => [ { version => 'v1', resources => [] } ] } ],
    });
    my $jobs_in = sub {
        my ($group, $version) = @_;
        return {
            version   => $version,
            resources => [ {
                resource     => 'jobs',
                responseKind => { group => $group, version => $version, kind => 'Job' },
                scope        => 'Namespaced',
            } ],
        };
    };
    # batch/v2 does not exist; it stands for "an apiVersion the Job special
    # case was not written for".
    $uio->add_response('GET', '/apis', {
        kind  => 'APIGroupDiscoveryList',
        items => [
            { metadata => { name => 'batch' },
              versions => [ $jobs_in->('batch', 'v1'), $jobs_in->('batch', 'v2') ] },
            { metadata => { name => 'example.com' },
              versions => [ $jobs_in->('example.com', 'v1') ] },
        ],
    });
    my $uapi = Kubernetes::REST->new(
        server      => Kubernetes::REST::Server->new(endpoint => 'http://mock.local'),
        credentials => Kubernetes::REST::AuthToken->new(token => 'MockToken'),
        io          => $uio,
    );

    # The resource calls only - the first path build fetches discovery.
    my $resource_calls = sub {
        my ($mark) = @_;
        return [ grep { !m{\AGET /apis?\z} } @{ calls_since($uio, $mark) } ];
    };

    my $unstructured = sub {
        my ($api_version, $name) = @_;
        return IO::K8s::Unstructured->FROM_HASH({
            apiVersion => $api_version,
            kind       => 'Job',
            metadata   => { name => $name, namespace => 'default' },
        });
    };

    # Case 13: apiVersion batch/v1, Kind Job - the real Job, special-cased.
    my $BATCH = '/apis/batch/v1/namespaces/default/jobs';
    $uio->add_response('GET', "$BATCH/u-done", {
        apiVersion => 'batch/v1', kind => 'Job',
        metadata   => { name => 'u-done', namespace => 'default', resourceVersion => '3' },
        status     => { succeeded => 1 },
    });
    my $mark = @{ $uio->requests };
    my $result = eval { $uapi->ensure($unstructured->('batch/v1', 'u-done')) };
    is($@, '', 'Unstructured batch/v1 Job: ensure does not die');
    isa_ok($result, 'IO::K8s::Unstructured', 'Unstructured batch/v1 Job: result');
    is_deeply($resource_calls->($mark), [ "GET $BATCH/u-done" ],
        'Unstructured batch/v1 Job: succeeded, returned unchanged');

    # Cases 14 and 15: Kind Job in another group, or under an apiVersion other
    # than batch/v1, is an ordinary object - GET then PUT.
    for my $case (
        [ 'example.com/v1', '/apis/example.com/v1/namespaces/default/jobs', 'Job in its own group' ],
        [ 'batch/v2',       '/apis/batch/v2/namespaces/default/jobs',       'Job under batch/v2' ],
    ) {
        my ($api_version, $collection, $label) = @$case;
        $uio->add_response('GET', "$collection/u-run", {
            apiVersion => $api_version, kind => 'Job',
            metadata   => { name => 'u-run', namespace => 'default', resourceVersion => '5' },
            status     => { phase => 'Running' },
        });
        $uio->add_response('PUT', "$collection/u-run", {
            apiVersion => $api_version, kind => 'Job',
            metadata   => { name => 'u-run', namespace => 'default', resourceVersion => '6' },
        });

        my $object = $unstructured->($api_version, 'u-run');
        my $mark = @{ $uio->requests };
        my $result = eval { $uapi->ensure($object) };
        is($@, '', "Unstructured $label: ensure does not die");
        is_deeply($resource_calls->($mark), [ "GET $collection/u-run", "PUT $collection/u-run" ],
            "Unstructured $label: a plain GET then PUT");
        is($object->metadata->resourceVersion, '5',
            "Unstructured $label: PUT at the server resourceVersion");
    }
}

# ---------------------------------------------------------------------------
# karr k41: the object appears between ensure's GET and its POST, and the POST
# answers 409 AlreadyExists. From there on it is an existing object like any
# other: a batch/v1 Job gets the Job special case - never a PUT onto its
# immutable Pod template - and a PersistentVolumeClaim is returned unchanged.
#
# The mock answers every request for a path the same way; the race needs a
# sequence (the GET before the POST finds nothing, the one after the 409 finds
# the object). This subclass answers from a per-request script first -
# 'METHOD /path' => [ [ status, body ], ... ], consumed in order - and hands
# everything else to the mock.
# ---------------------------------------------------------------------------
{
    package Test::Ensure::ScriptedIO;
    use Moo;
    extends 'Test::Kubernetes::Mock::IO';

    use JSON::MaybeXS ();

    has script => (is => 'ro', default => sub { {} });

    my $wire_json = JSON::MaybeXS->new(utf8 => 1, canonical => 1);

    around call => sub {
        my ($orig, $self, $req) = @_;
        (my $path = $req->url) =~ s{\Ahttps?://[^/]+}{};
        my $steps = $self->script->{ $req->method . ' ' . $path };
        return $self->$orig($req) unless $steps && @$steps;
        my ($status, $body) = @{ shift @$steps };
        push @{ $self->requests },
            { method => $req->method, path => $path, content => $req->content };
        return Test::Kubernetes::Mock::Response->new(
            status  => $status,
            content => $wire_json->encode($body),
        );
    };
}

sub scripted_api {
    my (%script) = @_;
    return Kubernetes::REST->new(
        server      => Kubernetes::REST::Server->new(endpoint => 'http://mock.local'),
        credentials => Kubernetes::REST::AuthToken->new(token => 'MockToken'),
        resource_map_from_cluster => 0,
        io          => Test::Ensure::ScriptedIO->new(script => \%script),
    );
}

sub failure {
    my ($code, $reason) = @_;
    return [ $code, { kind => 'Status', apiVersion => 'v1', status => 'Failure',
                      code => $code, reason => $reason } ];
}

sub served {
    my ($manifest, $rv) = @_;
    return [ 200, { %$manifest, metadata => { %{ $manifest->{metadata} }, resourceVersion => $rv } } ];
}

# Case 16: an active Job appeared - returned as it is, no PUT.
{
    my $sapi = scripted_api(
        "GET $JOBS/late"  => [ failure(404, 'NotFound'),
                               served(batch_job('late', status => { active => 1 }), '11') ],
        "POST $JOBS"      => [ failure(409, 'AlreadyExists') ],
    );
    my $result = eval { $sapi->ensure(batch_job('late')) };
    is($@, '', 'Job after 409, active: ensure does not die');
    is_deeply(calls_since($sapi->io, 0),
        [ "GET $JOBS/late", "POST $JOBS", "GET $JOBS/late" ],
        'Job after 409, active: returned unchanged - no PUT onto the Pod template');
    is($result && $result->metadata->resourceVersion, '11',
        'Job after 409, active: the existing object is returned');
}

# Case 17: a failed Job appeared - deleted and recreated, as in the main path.
{
    my $sapi = scripted_api(
        "GET $JOBS/late"    => [ failure(404, 'NotFound'),
                                 served(batch_job('late', status => { failed => 1 }), '11') ],
        "POST $JOBS"        => [ failure(409, 'AlreadyExists'), served(batch_job('late'), '12') ],
        "DELETE $JOBS/late?propagationPolicy=Background"
                            => [ [ 200, { kind => 'Status', apiVersion => 'v1', status => 'Success' } ] ],
    );
    my $result = eval { $sapi->ensure(batch_job('late')) };
    is($@, '', 'Job after 409, failed: ensure does not die');
    is_deeply(calls_since($sapi->io, 0),
        [ "GET $JOBS/late", "POST $JOBS", "GET $JOBS/late",
          "DELETE $JOBS/late?propagationPolicy=Background", "POST $JOBS" ],
        'Job after 409, failed: deleted and recreated, no PUT');
    is($result && $result->metadata->resourceVersion, '12',
        'Job after 409, failed: the recreated object is returned');
}

# Case 18: unchanged - a PersistentVolumeClaim that appeared is returned as it is.
{
    my $PVCS = '/api/v1/namespaces/default/persistentvolumeclaims';
    my $claim = {
        apiVersion => 'v1', kind => 'PersistentVolumeClaim',
        metadata   => { name => 'late', namespace => 'default' },
        spec       => { accessModes => ['ReadWriteOnce'] },
    };
    my $sapi = scripted_api(
        "GET $PVCS/late" => [ failure(404, 'NotFound'), served($claim, '21') ],
        "POST $PVCS"     => [ failure(409, 'AlreadyExists') ],
    );
    my $result = eval { $sapi->ensure($claim) };
    is($@, '', 'PVC after 409: ensure does not die');
    is_deeply(calls_since($sapi->io, 0),
        [ "GET $PVCS/late", "POST $PVCS", "GET $PVCS/late" ],
        'PVC after 409: returned unchanged, no PUT');
    is($result && $result->metadata->resourceVersion, '21',
        'PVC after 409: the existing object is returned');
}

# Cases 19 and 20: any other object that appeared is updated at the server's
# resourceVersion - and that update is retried once on a 409 Conflict, as on
# the main path.
{
    my $CMS = '/api/v1/namespaces/default/configmaps';
    my $cm = {
        apiVersion => 'v1', kind => 'ConfigMap',
        metadata   => { name => 'late', namespace => 'default' },
        data       => { key => 'value' },
    };

    my $sapi = scripted_api(
        "GET $CMS/late" => [ failure(404, 'NotFound'), served($cm, '7') ],
        "POST $CMS"     => [ failure(409, 'AlreadyExists') ],
        "PUT $CMS/late" => [ served($cm, '8') ],
    );
    my $object = $sapi->k8s->struct_to_object('ConfigMap', $cm);
    my $result = eval { $sapi->ensure($object) };
    is($@, '', 'ConfigMap after 409: ensure does not die');
    is_deeply(calls_since($sapi->io, 0),
        [ "GET $CMS/late", "POST $CMS", "GET $CMS/late", "PUT $CMS/late" ],
        'ConfigMap after 409: updated');
    is($object->metadata->resourceVersion, '7', 'ConfigMap after 409: PUT at the server resourceVersion');
    is($result && $result->metadata->resourceVersion, '8', 'ConfigMap after 409: the updated object is returned');

    $sapi = scripted_api(
        "GET $CMS/late" => [ failure(404, 'NotFound'), served($cm, '7'), served($cm, '9') ],
        "POST $CMS"     => [ failure(409, 'AlreadyExists') ],
        "PUT $CMS/late" => [ failure(409, 'Conflict'), served($cm, '10') ],
    );
    $object = $sapi->k8s->struct_to_object('ConfigMap', $cm);
    $result = eval { $sapi->ensure($object) };
    is($@, '', 'ConfigMap after 409, update conflict: ensure does not die');
    is_deeply(calls_since($sapi->io, 0),
        [ "GET $CMS/late", "POST $CMS", "GET $CMS/late", "PUT $CMS/late",
          "GET $CMS/late", "PUT $CMS/late" ],
        'ConfigMap after 409, update conflict: re-fetched and retried once');
    is($object->metadata->resourceVersion, '9',
        'ConfigMap after 409, update conflict: the retry uses the re-fetched resourceVersion');
    is($result && $result->metadata->resourceVersion, '10',
        'ConfigMap after 409, update conflict: the updated object is returned');
}

# ---------------------------------------------------------------------------
# karr k44: ensure branches on the status of a response, never on the text of
# an error. A 500 or 422 whose message merely contains "404" or "409" is a
# failure - not a missing object, an AlreadyExists or a Conflict - and ensure
# croaks with it instead of creating, re-fetching or retrying.
# ---------------------------------------------------------------------------
sub failure_saying {
    my ($code, $reason, $message) = @_;
    my $failure = failure($code, $reason);
    $failure->[1]{message} = $message;
    return $failure;
}

{
    my $CMS = '/api/v1/namespaces/default/configmaps';
    my $cm = {
        apiVersion => 'v1', kind => 'ConfigMap',
        metadata   => { name => 'digits', namespace => 'default' },
        data       => { key => 'value' },
    };

    # Case 21: the GET fails - it did not find nothing.
    my $sapi = scripted_api(
        "GET $CMS/digits" => [ failure_saying(500, 'InternalError', 'etcd timed out after 404 ms') ],
    );
    my $object = $sapi->k8s->struct_to_object('ConfigMap', $cm);
    eval { $sapi->ensure($object) };
    like($@, qr/ensure get ConfigMap\/digits\): 500 /, 'GET 500 saying 404: ensure croaks with the 500');
    is_deeply(calls_since($sapi->io, 0), [ "GET $CMS/digits" ],
        'GET 500 saying 404: nothing is created');

    # Case 22: the POST is rejected - it did not collide with an existing object.
    $sapi = scripted_api(
        "GET $CMS/digits" => [ failure(404, 'NotFound') ],
        "POST $CMS"       => [ failure_saying(422, 'Invalid', 'data.port: Invalid value: 409') ],
    );
    $object = $sapi->k8s->struct_to_object('ConfigMap', $cm);
    eval { $sapi->ensure($object) };
    like($@, qr/create IO::K8s::Api::Core::V1::ConfigMap\): 422 /,
        'POST 422 saying 409: ensure croaks with the 422');
    is_deeply(calls_since($sapi->io, 0), [ "GET $CMS/digits", "POST $CMS" ],
        'POST 422 saying 409: not re-fetched as AlreadyExists');

    # Case 23: the PUT fails - it did not lose a resourceVersion race.
    $sapi = scripted_api(
        "GET $CMS/digits" => [ served($cm, '7') ],
        "PUT $CMS/digits" => [ failure_saying(500, 'InternalError', 'retry after 409 ms') ],
    );
    $object = $sapi->k8s->struct_to_object('ConfigMap', $cm);
    eval { $sapi->ensure($object) };
    like($@, qr/update IO::K8s::Api::Core::V1::ConfigMap\): 500 /,
        'PUT 500 saying 409: ensure croaks with the 500');
    is_deeply(calls_since($sapi->io, 0), [ "GET $CMS/digits", "PUT $CMS/digits" ],
        'PUT 500 saying 409: not re-fetched and retried as a Conflict');
}

done_testing;
