#!/usr/bin/env perl
# Regression coverage for karr ticket #13:
#
# IO::K8s::Role::APIObject::api_version() used to derive the wire
# apiVersion string by lc()-ing the CamelCase group component of the
# class name whenever the group was not in the %API_GROUP_MAP. That
# assumes the upstream API group has no ".k8s.io" / ".apiserver.k8s.io"
# suffix -- an assumption that is wrong for two shipped groups:
#
#   - IO::K8s::Api::Storagemigration::*  used to compute
#     "storagemigration/v1beta1", upstream is "storagemigration.k8s.io"
#   - IO::K8s::Api::Apiserverinternal::*  used to compute
#     "apiserverinternal/v1alpha1", upstream is
#     "internal.apiserver.k8s.io"
#
# Because TO_JSON always calls $self->api_version (see
# lib/IO/K8s/Role/Resource.pm, ~line 42), every serialised manifest for
# these two groups carried a syntactically plausible but wrong apiVersion
# that a real Kubernetes API server would reject. This test asserts the
# derived string directly (the claim) and the serialised apiVersion key
# (the consequence) for one shipped kind per affected group. It also
# spot-checks every other shipped group covered by %_class_prefix to
# make sure adding the two new map entries did not regress any sibling.

use strict;
use warnings;
use Test::More;
use JSON::MaybeXS;

use IO::K8s;

my $k8s  = IO::K8s->new;
my $json = JSON::MaybeXS->new(utf8 => 0, canonical => 1, allow_nonref => 1);

# Expected wire apiVersion for at least one shipped top-level kind per
# shipped CamelCase group under lib/IO/K8s/Api/. "Core" maps to bare "v1"
# (no group prefix). The groups whose CamelCase lc-form already matches
# the upstream group (apps, batch, autoscaling, policy) intentionally
# exercise the lc()-fallback path and prove it is correct for them.
my %EXPECTED = (
    'IO::K8s::Api::Admissionregistration::V1::ValidatingAdmissionPolicy'
        => 'admissionregistration.k8s.io/v1',
    'IO::K8s::Api::Apiserverinternal::V1alpha1::StorageVersion'
        => 'internal.apiserver.k8s.io/v1alpha1',
    'IO::K8s::Api::Apps::V1::Deployment'                 => 'apps/v1',
    'IO::K8s::Api::Authentication::V1::TokenRequest'     => 'authentication.k8s.io/v1',
    'IO::K8s::Api::Authorization::V1::SubjectAccessReview'
        => 'authorization.k8s.io/v1',
    'IO::K8s::Api::Autoscaling::V1::HorizontalPodAutoscaler'
        => 'autoscaling/v1',
    'IO::K8s::Api::Batch::V1::Job'                       => 'batch/v1',
    'IO::K8s::Api::Certificates::V1::CertificateSigningRequest'
        => 'certificates.k8s.io/v1',
    'IO::K8s::Api::Coordination::V1::Lease'              => 'coordination.k8s.io/v1',
    'IO::K8s::Api::Core::V1::Pod'                        => 'v1',
    'IO::K8s::Api::Discovery::V1::EndpointSlice'         => 'discovery.k8s.io/v1',
    'IO::K8s::Api::Events::V1::Event'                    => 'events.k8s.io/v1',
    'IO::K8s::Api::Flowcontrol::V1::FlowSchema'          => 'flowcontrol.apiserver.k8s.io/v1',
    'IO::K8s::Api::Networking::V1::NetworkPolicy'        => 'networking.k8s.io/v1',
    'IO::K8s::Api::Node::V1::RuntimeClass'               => 'node.k8s.io/v1',
    'IO::K8s::Api::Policy::V1::PodDisruptionBudget'      => 'policy/v1',
    'IO::K8s::Api::Rbac::V1::Role'                       => 'rbac.authorization.k8s.io/v1',
    'IO::K8s::Api::Resource::V1alpha3::ResourceClaim'    => 'resource.k8s.io/v1alpha3',
    'IO::K8s::Api::Scheduling::V1::PriorityClass'        => 'scheduling.k8s.io/v1',
    'IO::K8s::Api::Storage::V1::StorageClass'            => 'storage.k8s.io/v1',
    'IO::K8s::Api::Storagemigration::V1alpha1::StorageVersionMigration'
        => 'storagemigration.k8s.io/v1alpha1',
);

subtest 'api_version() returns the upstream-correct apiVersion for every shipped group' => sub {
    for my $class (sort keys %EXPECTED) {
        ok( eval { $k8s->load_class($class); 1 }, "$class loads" )
            or diag("load error: $@");
        my $got = eval { $class->api_version };
        is( $got, $EXPECTED{$class}, "$class api_version"
                . " expected '" . $EXPECTED{$class} . "'"
                . " got '" . ($got // '<undef>') . "'" );
    }
};

# Consequence check: serialised apiVersion key carries the upstream form
# for the two groups that were wrong before the fix. StorageVersion needs
# its required spec/status to inflate, so we go through struct_to_object.
subtest 'serialised apiVersion is upstream-correct for the two fixed groups' => sub {
    my @cases = (
        [ 'IO::K8s::Api::Apiserverinternal::V1alpha1::StorageVersion',
          {   name => 'widgets.example.com',
              spec => {},
              status => {
                  commonEncodingVersion => 'v1',
                  conditions            => [],
                  storageVersions       => [],
              },
          },
          'internal.apiserver.k8s.io/v1alpha1',
          'StorageVersion',
        ],
        [ 'IO::K8s::Api::Storagemigration::V1alpha1::StorageVersionMigration',
          {   name      => 'widgets.example.com',
              spec      => {
                  continueToken     => '',
                  resource          => { group => 'apps', resource => 'deployments', version => 'v1' },
              },
          },
          'storagemigration.k8s.io/v1alpha1',
          'StorageVersionMigration',
        ],
    );

    for my $case (@cases) {
        my ($class, $extra_fields, $expected_api, $expected_kind) = @$case;
        my $hash = {
            apiVersion => 'placeholder/will-be-overwritten-by-class',
            kind       => 'placeholder',
            metadata   => { name => 'widgets.example.com' },
            %$extra_fields,
        };
        my $obj = eval { $k8s->struct_to_object($class, $hash) }
            or BAIL_OUT("inflate $class failed: $@");
        my $struct = $k8s->object_to_struct($obj);
        is( $struct->{apiVersion}, $expected_api,
            "$class serialises apiVersion as '$expected_api'" );
        is( $struct->{kind}, $expected_kind,
            "$class serialises kind as '$expected_kind'" );
    }
};

done_testing;
