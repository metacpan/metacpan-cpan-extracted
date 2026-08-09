#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Test::Exception;
use IO::K8s;

my $io = IO::K8s->new;

# --- MutatingAdmissionPolicy: served at v1 (GA), v1beta1, v1alpha1 simultaneously ---

subtest 'load all MutatingAdmissionPolicy classes (v1, v1beta1, v1alpha1)' => sub {
    for my $ver (qw(V1 V1beta1 V1alpha1)) {
        for my $kind (qw(
            MutatingAdmissionPolicy
            MutatingAdmissionPolicySpec
            MutatingAdmissionPolicyBinding
            MutatingAdmissionPolicyBindingSpec
            Mutation
            ApplyConfiguration
            JSONPatch
        )) {
            my $class = "IO::K8s::Api::Admissionregistration::${ver}::${kind}";
            use_ok($class) or BAIL_OUT("Cannot load $class");
        }
    }
};

subtest 'MutatingAdmissionPolicy (v1) api_version/kind' => sub {
    my $class = 'IO::K8s::Api::Admissionregistration::V1::MutatingAdmissionPolicy';
    is($class->api_version, 'admissionregistration.k8s.io/v1', 'api_version');
    is($class->kind, 'MutatingAdmissionPolicy', 'kind');
};

subtest 'MutatingAdmissionPolicy (v1) full construction via struct_to_object' => sub {
    my $obj = $io->struct_to_object(
        'IO::K8s::Api::Admissionregistration::V1::MutatingAdmissionPolicy',
        {
            metadata => { name => 'my-policy' },
            spec => {
                failurePolicy => 'Fail',
                reinvocationPolicy => 'Never',
                paramKind => { apiVersion => 'v1', kind => 'ConfigMap' },
                matchConstraints => {
                    resourceRules => [
                        { apiGroups => [''], apiVersions => ['v1'], resources => ['pods'], operations => ['CREATE'] },
                    ],
                },
                mutations => [
                    {
                        patchType => 'ApplyConfiguration',
                        applyConfiguration => { expression => 'Object{spec: Object.spec{serviceAccountName: "example"}}' },
                    },
                    {
                        patchType => 'JSONPatch',
                        jsonPatch => { expression => '[JSONPatch{op: "add", path: "/spec/example", value: "Red"}]' },
                    },
                ],
                variables => [
                    { name => 'foo', expression => "'bar'" },
                ],
            },
        }
    );

    isa_ok($obj, 'IO::K8s::Api::Admissionregistration::V1::MutatingAdmissionPolicy');
    is($obj->metadata->name, 'my-policy', 'metadata.name');
    is($obj->spec->failurePolicy, 'Fail', 'spec.failurePolicy');
    is($obj->spec->reinvocationPolicy, 'Never', 'spec.reinvocationPolicy');
    isa_ok($obj->spec->paramKind, 'IO::K8s::Api::Admissionregistration::V1::ParamKind');
    is($obj->spec->paramKind->kind, 'ConfigMap', 'spec.paramKind.kind');
    isa_ok($obj->spec->matchConstraints, 'IO::K8s::Api::Admissionregistration::V1::MatchResources');

    is(scalar @{ $obj->spec->mutations }, 2, 'two mutations');
    isa_ok($obj->spec->mutations->[0], 'IO::K8s::Api::Admissionregistration::V1::Mutation');
    is($obj->spec->mutations->[0]->patchType, 'ApplyConfiguration', 'mutation[0].patchType');
    isa_ok($obj->spec->mutations->[0]->applyConfiguration, 'IO::K8s::Api::Admissionregistration::V1::ApplyConfiguration');
    is($obj->spec->mutations->[1]->patchType, 'JSONPatch', 'mutation[1].patchType');
    isa_ok($obj->spec->mutations->[1]->jsonPatch, 'IO::K8s::Api::Admissionregistration::V1::JSONPatch');

    is($obj->spec->variables->[0]->name, 'foo', 'variables[0].name');

    my $json = $io->object_to_json($obj);
    like($json, qr/MutatingAdmissionPolicy/, 'serializes with kind');
};

subtest 'MutatingAdmissionPolicyBinding (v1) construction' => sub {
    my $obj = $io->struct_to_object(
        'IO::K8s::Api::Admissionregistration::V1::MutatingAdmissionPolicyBinding',
        {
            metadata => { name => 'my-binding' },
            spec => {
                policyName => 'my-policy',
                paramRef => { name => 'my-config', parameterNotFoundAction => 'Deny' },
            },
        }
    );

    isa_ok($obj, 'IO::K8s::Api::Admissionregistration::V1::MutatingAdmissionPolicyBinding');
    is($obj->spec->policyName, 'my-policy', 'spec.policyName');
    isa_ok($obj->spec->paramRef, 'IO::K8s::Api::Admissionregistration::V1::ParamRef');
};

# --- PodCertificateRequest (certificates.k8s.io/v1beta1, kubelet-driven, namespaced) ---

subtest 'PodCertificateRequest classes load and construct' => sub {
    for my $kind (qw(PodCertificateRequest PodCertificateRequestSpec PodCertificateRequestStatus)) {
        my $class = "IO::K8s::Api::Certificates::V1beta1::${kind}";
        use_ok($class) or BAIL_OUT("Cannot load $class");
    }

    my $class = 'IO::K8s::Api::Certificates::V1beta1::PodCertificateRequest';
    is($class->api_version, 'certificates.k8s.io/v1beta1', 'api_version');
    is($class->kind, 'PodCertificateRequest', 'kind');
    ok($class->does('IO::K8s::Role::Namespaced'), 'PodCertificateRequest is namespaced');

    my $obj = $io->struct_to_object(
        $class,
        {
            metadata => { name => 'my-pod-abcd1234', namespace => 'default' },
            spec => {
                signerName => 'kubernetes.io/kube-apiserver-client-pod',
                podName => 'my-pod',
                podUID => 'pod-uid-1',
                serviceAccountName => 'default',
                serviceAccountUID => 'sa-uid-1',
                nodeName => 'node-1',
                nodeUID => 'node-uid-1',
                stubPKCS10Request => 'ZmFrZS1jc3I=',
            },
            status => {
                certificateChain => 'fake-pem-chain',
                conditions => [
                    { type => 'Issued', status => 'True', reason => 'Issued', message => 'ok', lastTransitionTime => '2026-08-08T00:00:00Z' },
                ],
            },
        }
    );

    isa_ok($obj, $class);
    is($obj->spec->podName, 'my-pod', 'spec.podName');
    is($obj->spec->nodeName, 'node-1', 'spec.nodeName');
    isa_ok($obj->status, 'IO::K8s::Api::Certificates::V1beta1::PodCertificateRequestStatus');
    isa_ok($obj->status->conditions->[0], 'IO::K8s::Apimachinery::Pkg::Apis::Meta::V1::Condition');
};

# --- ClusterTrustBundle graduates to certificates.k8s.io/v1beta1 (alongside v1alpha1) ---

subtest 'ClusterTrustBundle v1beta1 classes load and construct' => sub {
    for my $kind (qw(ClusterTrustBundle ClusterTrustBundleSpec)) {
        my $class = "IO::K8s::Api::Certificates::V1beta1::${kind}";
        use_ok($class) or BAIL_OUT("Cannot load $class");
    }

    my $class = 'IO::K8s::Api::Certificates::V1beta1::ClusterTrustBundle';
    is($class->api_version, 'certificates.k8s.io/v1beta1', 'api_version');
    is($class->kind, 'ClusterTrustBundle', 'kind');

    my $obj = $io->struct_to_object(
        $class,
        {
            metadata => { name => 'example.com:foo:v1' },
            spec => {
                signerName => 'example.com/foo',
                trustBundle => "-----BEGIN CERTIFICATE-----\nfake\n-----END CERTIFICATE-----\n",
            },
        }
    );

    isa_ok($obj, $class);
    is($obj->spec->signerName, 'example.com/foo', 'spec.signerName');
};

done_testing;
