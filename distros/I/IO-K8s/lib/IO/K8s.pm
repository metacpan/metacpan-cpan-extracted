package IO::K8s;
# ABSTRACT: Objects representing things found in the Kubernetes API

use v5.10;
use Moo;
use Carp qw(croak);
use Module::Runtime qw(require_module);
use JSON::MaybeXS;
use Scalar::Util ();
use IO::K8s::AutoGen;
use IO::K8s::Resource ();
use IO::K8s::Unstructured ();
use namespace::clean;

our $VERSION = '1.108';

# Track which classes we've auto-generated
my %_autogen_cache;

# Generated classes outlive their IO::K8s instance, so a freed instance's
# reusable object address cannot identify its namespace.
my $_autogen_namespace_sequence = 0;

# Classes load_class() has already pulled in successfully.
#
# ONLY successes are recorded, and only after require_module has returned:
# a failed load dies before the store, so a name that was not loadable when
# it was first asked for is tried again on the next call. That is the whole
# point of not writing this as a plain memo of the outcome -- a negative
# entry would make a package that only becomes available later (defined at
# runtime and registered in %INC, or a module installed mid-process)
# permanently unloadable, and the resulting failure would depend on which
# lookup happened first.
my %_loaded_class;

# Default resource map. Two kinds of key live here:
#
#   'Pod'          short name: what new_object('Pod') and any lookup
#                  without an apiVersion resolve to. One per Kind, pointing
#                  at the newest stable shipped version.
#   'v1/Pod'       domain-qualified '$api_version/$Kind': what inflate()
#                  dispatches on (it always passes the payload's apiVersion)
#                  and what expand_class($kind, $api_version) consults first.
#                  One per SHIPPED version of the Kind.
#
# Values are class paths relative to IO::K8s, or a full class name with a
# '+' prefix.
#
# Both key kinds are plain literals on purpose. The qualified ones used to
# be derived in BUILD by loading every target class to ask for its
# api_version(), which made IO::K8s->new pull in ~110 modules and cost
# ~0.4s even for a caller that only wanted a ConfigMap. The set is
# statically known, so it is written out. Writing it out also keeps the
# class-method path (IO::K8s->expand_class(...), which reads
# %DEFAULT_RESOURCE_MAP directly and never runs BUILD) in sync with what
# an instance sees. add() still introspects, because external providers
# are not known at compile time.
#
# Adding a Kind: one short name pointing at the newest stable shipped
# version, plus one qualified key per shipped version. Omitting the
# qualified key means an explicit GVK request fails closed, even when a
# bare compatibility alias exists for the Kind -- see k11 and k17.
#
# Deliberately absent: Kinds served only by CRD providers (those live in
# the provider's own resource_map, opt in via
# IO::K8s->new(with => [...])), and the upstream *TemplateSpec types
# (PodTemplateSpec, JobTemplateSpec, PersistentVolumeClaimTemplate,
# ResourceClaimTemplateSpec) -- they carry metadata but have no
# x-kubernetes-group-version-kind and never appear as a 'kind:' on the wire.
my %DEFAULT_RESOURCE_MAP = (
    # -- Core (v1) ---------------------------------------------------------
    Binding                    => 'Api::Core::V1::Binding',
    ComponentStatus            => 'Api::Core::V1::ComponentStatus',
    ConfigMap                  => 'Api::Core::V1::ConfigMap',
    Endpoints                  => 'Api::Core::V1::Endpoints',
    Event                      => 'Api::Core::V1::Event',
    LimitRange                 => 'Api::Core::V1::LimitRange',
    Namespace                  => 'Api::Core::V1::Namespace',
    Node                       => 'Api::Core::V1::Node',
    PersistentVolume           => 'Api::Core::V1::PersistentVolume',
    PersistentVolumeClaim      => 'Api::Core::V1::PersistentVolumeClaim',
    Pod                        => 'Api::Core::V1::Pod',
    PodTemplate                => 'Api::Core::V1::PodTemplate',
    ReplicationController      => 'Api::Core::V1::ReplicationController',
    ResourceQuota              => 'Api::Core::V1::ResourceQuota',
    Secret                     => 'Api::Core::V1::Secret',
    Service                    => 'Api::Core::V1::Service',
    ServiceAccount             => 'Api::Core::V1::ServiceAccount',
    'v1/Binding'               => 'Api::Core::V1::Binding',
    'v1/ComponentStatus'       => 'Api::Core::V1::ComponentStatus',
    'v1/ConfigMap'             => 'Api::Core::V1::ConfigMap',
    'v1/Endpoints'             => 'Api::Core::V1::Endpoints',
    'v1/Event'                 => 'Api::Core::V1::Event',
    'v1/LimitRange'            => 'Api::Core::V1::LimitRange',
    'v1/Namespace'             => 'Api::Core::V1::Namespace',
    'v1/Node'                  => 'Api::Core::V1::Node',
    'v1/PersistentVolume'      => 'Api::Core::V1::PersistentVolume',
    'v1/PersistentVolumeClaim' => 'Api::Core::V1::PersistentVolumeClaim',
    'v1/Pod'                   => 'Api::Core::V1::Pod',
    'v1/PodTemplate'           => 'Api::Core::V1::PodTemplate',
    'v1/ReplicationController' => 'Api::Core::V1::ReplicationController',
    'v1/ResourceQuota'         => 'Api::Core::V1::ResourceQuota',
    'v1/Secret'                => 'Api::Core::V1::Secret',
    'v1/Service'               => 'Api::Core::V1::Service',
    'v1/ServiceAccount'        => 'Api::Core::V1::ServiceAccount',
    'events.k8s.io/v1/Event'   => 'Api::Events::V1::Event',

    # -- Apps --------------------------------------------------------------
    ControllerRevision           => 'Api::Apps::V1::ControllerRevision',
    DaemonSet                    => 'Api::Apps::V1::DaemonSet',
    Deployment                   => 'Api::Apps::V1::Deployment',
    ReplicaSet                   => 'Api::Apps::V1::ReplicaSet',
    StatefulSet                  => 'Api::Apps::V1::StatefulSet',
    'apps/v1/ControllerRevision' => 'Api::Apps::V1::ControllerRevision',
    'apps/v1/DaemonSet'          => 'Api::Apps::V1::DaemonSet',
    'apps/v1/Deployment'         => 'Api::Apps::V1::Deployment',
    'apps/v1/ReplicaSet'         => 'Api::Apps::V1::ReplicaSet',
    'apps/v1/StatefulSet'        => 'Api::Apps::V1::StatefulSet',

    # -- Batch -------------------------------------------------------------
    CronJob            => 'Api::Batch::V1::CronJob',
    Job                => 'Api::Batch::V1::Job',
    'batch/v1/CronJob' => 'Api::Batch::V1::CronJob',
    'batch/v1/Job'     => 'Api::Batch::V1::Job',

    # -- Networking --------------------------------------------------------
    IPAddress                               => 'Api::Networking::V1::IPAddress',
    Ingress                                 => 'Api::Networking::V1::Ingress',
    IngressClass                            => 'Api::Networking::V1::IngressClass',
    NetworkPolicy                           => 'Api::Networking::V1::NetworkPolicy',
    ServiceCIDR                             => 'Api::Networking::V1::ServiceCIDR',
    'networking.k8s.io/v1/IPAddress'        => 'Api::Networking::V1::IPAddress',
    'networking.k8s.io/v1/Ingress'          => 'Api::Networking::V1::Ingress',
    'networking.k8s.io/v1/IngressClass'     => 'Api::Networking::V1::IngressClass',
    'networking.k8s.io/v1/NetworkPolicy'    => 'Api::Networking::V1::NetworkPolicy',
    'networking.k8s.io/v1/ServiceCIDR'      => 'Api::Networking::V1::ServiceCIDR',
    'networking.k8s.io/v1beta1/IPAddress'   => 'Api::Networking::V1beta1::IPAddress',
    'networking.k8s.io/v1beta1/ServiceCIDR' => 'Api::Networking::V1beta1::ServiceCIDR',

    # -- Storage -----------------------------------------------------------
    CSIDriver                                       => 'Api::Storage::V1::CSIDriver',
    CSINode                                         => 'Api::Storage::V1::CSINode',
    CSIStorageCapacity                              => 'Api::Storage::V1::CSIStorageCapacity',
    StorageClass                                    => 'Api::Storage::V1::StorageClass',
    VolumeAttachment                                => 'Api::Storage::V1::VolumeAttachment',
    VolumeAttributesClass                           => 'Api::Storage::V1::VolumeAttributesClass',
    'storage.k8s.io/v1/CSIDriver'                   => 'Api::Storage::V1::CSIDriver',
    'storage.k8s.io/v1/CSINode'                     => 'Api::Storage::V1::CSINode',
    'storage.k8s.io/v1/CSIStorageCapacity'          => 'Api::Storage::V1::CSIStorageCapacity',
    'storage.k8s.io/v1/StorageClass'                => 'Api::Storage::V1::StorageClass',
    'storage.k8s.io/v1/VolumeAttachment'            => 'Api::Storage::V1::VolumeAttachment',
    'storage.k8s.io/v1/VolumeAttributesClass'       => 'Api::Storage::V1::VolumeAttributesClass',
    'storage.k8s.io/v1alpha1/VolumeAttributesClass' => 'Api::Storage::V1alpha1::VolumeAttributesClass',
    'storage.k8s.io/v1beta1/VolumeAttributesClass'  => 'Api::Storage::V1beta1::VolumeAttributesClass',

    # -- Resource (Dynamic Resource Allocation) ----------------------------
    DeviceClass                                          => 'Api::Resource::V1::DeviceClass',
    DeviceTaintRule                                      => 'Api::Resource::V1::DeviceTaintRule',
    ResourceClaim                                        => 'Api::Resource::V1::ResourceClaim',
    ResourceClaimTemplate                                => 'Api::Resource::V1::ResourceClaimTemplate',
    ResourcePoolStatusRequest                            => 'Api::Resource::V1alpha3::ResourcePoolStatusRequest',
    ResourceSlice                                        => 'Api::Resource::V1::ResourceSlice',
    'resource.k8s.io/v1/DeviceClass'                     => 'Api::Resource::V1::DeviceClass',
    'resource.k8s.io/v1/DeviceTaintRule'                 => 'Api::Resource::V1::DeviceTaintRule',
    'resource.k8s.io/v1/ResourceClaim'                   => 'Api::Resource::V1::ResourceClaim',
    'resource.k8s.io/v1/ResourceClaimTemplate'           => 'Api::Resource::V1::ResourceClaimTemplate',
    'resource.k8s.io/v1/ResourceSlice'                   => 'Api::Resource::V1::ResourceSlice',
    'resource.k8s.io/v1alpha3/DeviceClass'               => 'Api::Resource::V1alpha3::DeviceClass',
    'resource.k8s.io/v1alpha3/DeviceTaintRule'           => 'Api::Resource::V1alpha3::DeviceTaintRule',
    'resource.k8s.io/v1alpha3/ResourceClaim'             => 'Api::Resource::V1alpha3::ResourceClaim',
    'resource.k8s.io/v1alpha3/ResourceClaimTemplate'     => 'Api::Resource::V1alpha3::ResourceClaimTemplate',
    'resource.k8s.io/v1alpha3/ResourcePoolStatusRequest' => 'Api::Resource::V1alpha3::ResourcePoolStatusRequest',
    'resource.k8s.io/v1alpha3/ResourceSlice'             => 'Api::Resource::V1alpha3::ResourceSlice',
    'resource.k8s.io/v1beta1/DeviceClass'                => 'Api::Resource::V1beta1::DeviceClass',
    'resource.k8s.io/v1beta1/ResourceClaim'              => 'Api::Resource::V1beta1::ResourceClaim',
    'resource.k8s.io/v1beta1/ResourceClaimTemplate'      => 'Api::Resource::V1beta1::ResourceClaimTemplate',
    'resource.k8s.io/v1beta1/ResourceSlice'              => 'Api::Resource::V1beta1::ResourceSlice',
    'resource.k8s.io/v1beta2/DeviceClass'                => 'Api::Resource::V1beta2::DeviceClass',
    'resource.k8s.io/v1beta2/DeviceTaintRule'            => 'Api::Resource::V1beta2::DeviceTaintRule',
    'resource.k8s.io/v1beta2/ResourceClaim'              => 'Api::Resource::V1beta2::ResourceClaim',
    'resource.k8s.io/v1beta2/ResourceClaimTemplate'      => 'Api::Resource::V1beta2::ResourceClaimTemplate',
    'resource.k8s.io/v1beta2/ResourceSlice'              => 'Api::Resource::V1beta2::ResourceSlice',

    # -- Authorization -----------------------------------------------------
    LocalSubjectAccessReview                           => 'Api::Authorization::V1::LocalSubjectAccessReview',
    SelfSubjectAccessReview                            => 'Api::Authorization::V1::SelfSubjectAccessReview',
    SelfSubjectRulesReview                             => 'Api::Authorization::V1::SelfSubjectRulesReview',
    SubjectAccessReview                                => 'Api::Authorization::V1::SubjectAccessReview',
    'authorization.k8s.io/v1/LocalSubjectAccessReview' => 'Api::Authorization::V1::LocalSubjectAccessReview',
    'authorization.k8s.io/v1/SelfSubjectAccessReview'  => 'Api::Authorization::V1::SelfSubjectAccessReview',
    'authorization.k8s.io/v1/SelfSubjectRulesReview'   => 'Api::Authorization::V1::SelfSubjectRulesReview',
    'authorization.k8s.io/v1/SubjectAccessReview'      => 'Api::Authorization::V1::SubjectAccessReview',

    # -- Authentication ----------------------------------------------------
    SelfSubjectReview                                  => 'Api::Authentication::V1::SelfSubjectReview',
    TokenRequest                                       => 'Api::Authentication::V1::TokenRequest',
    TokenReview                                        => 'Api::Authentication::V1::TokenReview',
    'authentication.k8s.io/v1/SelfSubjectReview'       => 'Api::Authentication::V1::SelfSubjectReview',
    'authentication.k8s.io/v1/TokenRequest'            => 'Api::Authentication::V1::TokenRequest',
    'authentication.k8s.io/v1/TokenReview'             => 'Api::Authentication::V1::TokenReview',
    'authentication.k8s.io/v1alpha1/SelfSubjectReview' => 'Api::Authentication::V1alpha1::SelfSubjectReview',
    'authentication.k8s.io/v1beta1/SelfSubjectReview'  => 'Api::Authentication::V1beta1::SelfSubjectReview',

    # -- RBAC --------------------------------------------------------------
    ClusterRole                                       => 'Api::Rbac::V1::ClusterRole',
    ClusterRoleBinding                                => 'Api::Rbac::V1::ClusterRoleBinding',
    Role                                              => 'Api::Rbac::V1::Role',
    RoleBinding                                       => 'Api::Rbac::V1::RoleBinding',
    'rbac.authorization.k8s.io/v1/ClusterRole'        => 'Api::Rbac::V1::ClusterRole',
    'rbac.authorization.k8s.io/v1/ClusterRoleBinding' => 'Api::Rbac::V1::ClusterRoleBinding',
    'rbac.authorization.k8s.io/v1/Role'               => 'Api::Rbac::V1::Role',
    'rbac.authorization.k8s.io/v1/RoleBinding'        => 'Api::Rbac::V1::RoleBinding',

    # -- Policy ------------------------------------------------------------
    Eviction                        => 'Api::Policy::V1::Eviction',
    PodDisruptionBudget             => 'Api::Policy::V1::PodDisruptionBudget',
    'policy/v1/Eviction'            => 'Api::Policy::V1::Eviction',
    'policy/v1/PodDisruptionBudget' => 'Api::Policy::V1::PodDisruptionBudget',

    # -- Autoscaling -------------------------------------------------------
    HorizontalPodAutoscaler                  => 'Api::Autoscaling::V2::HorizontalPodAutoscaler',
    Scale                                    => 'Api::Autoscaling::V1::Scale',
    'autoscaling/v1/HorizontalPodAutoscaler' => 'Api::Autoscaling::V1::HorizontalPodAutoscaler',
    'autoscaling/v1/Scale'                   => 'Api::Autoscaling::V1::Scale',
    'autoscaling/v2/HorizontalPodAutoscaler' => 'Api::Autoscaling::V2::HorizontalPodAutoscaler',

    # -- Certificates ------------------------------------------------------
    CertificateSigningRequest                           => 'Api::Certificates::V1::CertificateSigningRequest',
    ClusterTrustBundle                                  => 'Api::Certificates::V1::ClusterTrustBundle',
    PodCertificateRequest                               => 'Api::Certificates::V1::PodCertificateRequest',
    'certificates.k8s.io/v1/CertificateSigningRequest'  => 'Api::Certificates::V1::CertificateSigningRequest',
    'certificates.k8s.io/v1/ClusterTrustBundle'         => 'Api::Certificates::V1::ClusterTrustBundle',
    'certificates.k8s.io/v1/PodCertificateRequest'      => 'Api::Certificates::V1::PodCertificateRequest',
    'certificates.k8s.io/v1alpha1/ClusterTrustBundle'   => 'Api::Certificates::V1alpha1::ClusterTrustBundle',
    'certificates.k8s.io/v1beta1/ClusterTrustBundle'    => 'Api::Certificates::V1beta1::ClusterTrustBundle',
    'certificates.k8s.io/v1beta1/PodCertificateRequest' => 'Api::Certificates::V1beta1::PodCertificateRequest',

    # -- Coordination ------------------------------------------------------
    Lease                                         => 'Api::Coordination::V1::Lease',
    LeaseCandidate                                => 'Api::Coordination::V1beta1::LeaseCandidate',
    'coordination.k8s.io/v1/Lease'                => 'Api::Coordination::V1::Lease',
    'coordination.k8s.io/v1alpha1/LeaseCandidate' => 'Api::Coordination::V1alpha1::LeaseCandidate',
    'coordination.k8s.io/v1alpha2/LeaseCandidate' => 'Api::Coordination::V1alpha2::LeaseCandidate',
    'coordination.k8s.io/v1beta1/LeaseCandidate'  => 'Api::Coordination::V1beta1::LeaseCandidate',

    # -- Discovery ---------------------------------------------------------
    EndpointSlice                       => 'Api::Discovery::V1::EndpointSlice',
    'discovery.k8s.io/v1/EndpointSlice' => 'Api::Discovery::V1::EndpointSlice',

    # -- Scheduling --------------------------------------------------------
    CompositePodGroup                     => 'Api::Scheduling::V1alpha3::CompositePodGroup',
    PodGroup                              => 'Api::Scheduling::V1beta1::PodGroup',
    PriorityClass                         => 'Api::Scheduling::V1::PriorityClass',
    Workload                              => 'Api::Scheduling::V1beta1::Workload',
    'scheduling.k8s.io/v1/PriorityClass'           => 'Api::Scheduling::V1::PriorityClass',
    'scheduling.k8s.io/v1alpha2/PodGroup'          => 'Api::Scheduling::V1alpha2::PodGroup',
    'scheduling.k8s.io/v1alpha2/Workload'          => 'Api::Scheduling::V1alpha2::Workload',
    'scheduling.k8s.io/v1alpha3/CompositePodGroup' => 'Api::Scheduling::V1alpha3::CompositePodGroup',
    'scheduling.k8s.io/v1alpha3/PodGroup'          => 'Api::Scheduling::V1alpha3::PodGroup',
    'scheduling.k8s.io/v1alpha3/Workload'          => 'Api::Scheduling::V1alpha3::Workload',
    'scheduling.k8s.io/v1beta1/PodGroup'           => 'Api::Scheduling::V1beta1::PodGroup',
    'scheduling.k8s.io/v1beta1/Workload'           => 'Api::Scheduling::V1beta1::Workload',

    # -- Node --------------------------------------------------------------
    RuntimeClass                  => 'Api::Node::V1::RuntimeClass',
    'node.k8s.io/v1/RuntimeClass' => 'Api::Node::V1::RuntimeClass',

    # -- Flowcontrol -------------------------------------------------------
    FlowSchema                                                        => 'Api::Flowcontrol::V1::FlowSchema',
    PriorityLevelConfiguration                                        => 'Api::Flowcontrol::V1::PriorityLevelConfiguration',
    'flowcontrol.apiserver.k8s.io/v1/FlowSchema'                      => 'Api::Flowcontrol::V1::FlowSchema',
    'flowcontrol.apiserver.k8s.io/v1/PriorityLevelConfiguration'      => 'Api::Flowcontrol::V1::PriorityLevelConfiguration',
    'flowcontrol.apiserver.k8s.io/v1beta3/FlowSchema'                 => 'Api::Flowcontrol::V1beta3::FlowSchema',
    'flowcontrol.apiserver.k8s.io/v1beta3/PriorityLevelConfiguration' => 'Api::Flowcontrol::V1beta3::PriorityLevelConfiguration',

    # -- Admissionregistration ---------------------------------------------
    MutatingAdmissionPolicy                                                  => 'Api::Admissionregistration::V1::MutatingAdmissionPolicy',
    MutatingAdmissionPolicyBinding                                           => 'Api::Admissionregistration::V1::MutatingAdmissionPolicyBinding',
    MutatingWebhookConfiguration                                             => 'Api::Admissionregistration::V1::MutatingWebhookConfiguration',
    ValidatingAdmissionPolicy                                                => 'Api::Admissionregistration::V1::ValidatingAdmissionPolicy',
    ValidatingAdmissionPolicyBinding                                         => 'Api::Admissionregistration::V1::ValidatingAdmissionPolicyBinding',
    ValidatingWebhookConfiguration                                           => 'Api::Admissionregistration::V1::ValidatingWebhookConfiguration',
    'admissionregistration.k8s.io/v1/MutatingAdmissionPolicy'                => 'Api::Admissionregistration::V1::MutatingAdmissionPolicy',
    'admissionregistration.k8s.io/v1/MutatingAdmissionPolicyBinding'         => 'Api::Admissionregistration::V1::MutatingAdmissionPolicyBinding',
    'admissionregistration.k8s.io/v1/MutatingWebhookConfiguration'           => 'Api::Admissionregistration::V1::MutatingWebhookConfiguration',
    'admissionregistration.k8s.io/v1/ValidatingAdmissionPolicy'              => 'Api::Admissionregistration::V1::ValidatingAdmissionPolicy',
    'admissionregistration.k8s.io/v1/ValidatingAdmissionPolicyBinding'       => 'Api::Admissionregistration::V1::ValidatingAdmissionPolicyBinding',
    'admissionregistration.k8s.io/v1/ValidatingWebhookConfiguration'         => 'Api::Admissionregistration::V1::ValidatingWebhookConfiguration',
    'admissionregistration.k8s.io/v1alpha1/MutatingAdmissionPolicy'          => 'Api::Admissionregistration::V1alpha1::MutatingAdmissionPolicy',
    'admissionregistration.k8s.io/v1alpha1/MutatingAdmissionPolicyBinding'   => 'Api::Admissionregistration::V1alpha1::MutatingAdmissionPolicyBinding',
    'admissionregistration.k8s.io/v1alpha1/ValidatingAdmissionPolicy'        => 'Api::Admissionregistration::V1alpha1::ValidatingAdmissionPolicy',
    'admissionregistration.k8s.io/v1alpha1/ValidatingAdmissionPolicyBinding' => 'Api::Admissionregistration::V1alpha1::ValidatingAdmissionPolicyBinding',
    'admissionregistration.k8s.io/v1beta1/MutatingAdmissionPolicy'           => 'Api::Admissionregistration::V1beta1::MutatingAdmissionPolicy',
    'admissionregistration.k8s.io/v1beta1/MutatingAdmissionPolicyBinding'    => 'Api::Admissionregistration::V1beta1::MutatingAdmissionPolicyBinding',
    'admissionregistration.k8s.io/v1beta1/ValidatingAdmissionPolicy'         => 'Api::Admissionregistration::V1beta1::ValidatingAdmissionPolicy',
    'admissionregistration.k8s.io/v1beta1/ValidatingAdmissionPolicyBinding'  => 'Api::Admissionregistration::V1beta1::ValidatingAdmissionPolicyBinding',

    # -- Lifecycle ---------------------------------------------------------
    # Eviction is a collision Kind: the bare short name stays with the
    # established policy/v1 Eviction, so lifecycle.k8s.io's Eviction is
    # reachable by its qualified GVK only.
    EvictionRequest                             => 'Api::Lifecycle::V1alpha1::EvictionRequest',
    'lifecycle.k8s.io/v1alpha1/Eviction'        => 'Api::Lifecycle::V1alpha1::Eviction',
    'lifecycle.k8s.io/v1alpha1/EvictionRequest' => 'Api::Lifecycle::V1alpha1::EvictionRequest',

    # -- Storage version migration -----------------------------------------
    StorageVersionMigration                                    => 'Api::Storagemigration::V1::StorageVersionMigration',
    'storagemigration.k8s.io/v1/StorageVersionMigration'       => 'Api::Storagemigration::V1::StorageVersionMigration',
    'storagemigration.k8s.io/v1alpha1/StorageVersionMigration' => 'Api::Storagemigration::V1alpha1::StorageVersionMigration',
    'storagemigration.k8s.io/v1beta1/StorageVersionMigration'  => 'Api::Storagemigration::V1beta1::StorageVersionMigration',

    # -- Internal apiserver ------------------------------------------------
    StorageVersion                                      => 'Api::Apiserverinternal::V1alpha1::StorageVersion',
    'internal.apiserver.k8s.io/v1alpha1/StorageVersion' => 'Api::Apiserverinternal::V1alpha1::StorageVersion',

    # -- Extension APIs (different base paths) -----------------------------
    APIService                                         => 'KubeAggregator::Pkg::Apis::Apiregistration::V1::APIService',
    CustomResourceDefinition                           => 'ApiextensionsApiserver::Pkg::Apis::Apiextensions::V1::CustomResourceDefinition',
    'apiextensions.k8s.io/v1/CustomResourceDefinition' => 'ApiextensionsApiserver::Pkg::Apis::Apiextensions::V1::CustomResourceDefinition',
    'apiregistration.k8s.io/v1/APIService'             => 'KubeAggregator::Pkg::Apis::Apiregistration::V1::APIService',
);

has json => (is => 'ro', default => sub {
    return JSON::MaybeXS->new(utf8 => 1, canonical => 1);
});

# Resource map - can be customized per instance
# Returns a copy so add() can safely mutate without affecting other instances
has resource_map => (
    is => 'ro',
    lazy => 1,
    default => sub { +{ %DEFAULT_RESOURCE_MAP } },
);

# OpenAPI spec for auto-generating unknown types
has openapi_spec => (
    is => 'ro',
    predicate => 1,
);

# External resource map providers to merge at construction time
# e.g. with => ['IO::K8s::Cilium'] or with => [IO::K8s::Cilium->new]
has with => (
    is => 'ro',
    default => sub { [] },
);

# Unknown-field policy for this instance's entry points (D1). 0: a field no
# class declares is kept and emitted again by TO_JSON. 1: it dies naming the
# class and the field. Applied by localizing $IO::K8s::Resource::STRICT in
# inflate, new_object, json_to_object and struct_to_object, so it reaches
# every nested constructor -- including the inline-struct coercers, which
# never pass through _inflate_struct. load and load_yaml inherit it through
# new_object / inflate.
has strict => (
    is      => 'ro',
    default => sub { 0 },
);

# Unknown-Kind policy (D4). '': the current fail-closed default -- inflate
# and new_object die with the GVK resolution error below when apiVersion/kind
# resolves to no registered class (built-in, CRD-registered, or AutoGen'd).
# 'unstructured': build an IO::K8s::Unstructured from the document instead of
# dying. Any other value keeps the fail-closed default unchanged -- only the
# literal string 'unstructured' opts in.
has unknown_kinds => (
    is      => 'ro',
    default => sub { '' },
);

# User namespaces to search for pre-built classes (checked before IO::K8s::)
# e.g. ['MyProject::K8s'] will look for MyProject::K8s::HelmChart before IO::K8s::...
has class_namespaces => (
    is => 'ro',
    default => sub { [] },
);

# Internal: unique autogen namespace for this instance (isolated, collision-free)
has _autogen_namespace => (
    is => 'ro',
    lazy => 1,
    default => sub {
        # A process-wide sequence remains unique after an instance is freed.
        my $id = sprintf('%x', ++$_autogen_namespace_sequence);
        return "IO::K8s::_AUTOGEN_$id";
    },
);

# Class method to get default resource map
sub default_resource_map { \%DEFAULT_RESOURCE_MAP }

sub BUILD {
    my ($self) = @_;

    # The built-in map already carries its domain-qualified keys as
    # literals (see %DEFAULT_RESOURCE_MAP above), so there is nothing to
    # derive here. Only external providers need introspecting, and add()
    # does that itself.
    $self->add(@{$self->with}) if @{$self->with};
}

# Add a '$api_version/$kind' qualified entry to $map if the target class
# can be loaded and reports an api_version. No-op if the qualified key
# already exists. Only used by add(): the built-in map spells its
# qualified keys out as literals, but an external provider's classes are
# not known until it is merged, so those have to be introspected.
sub _qualify_class_path {
    my ($map, $kind, $class_path) = @_;

    # A key that already carries a '/' is an exact GVK request, not a bare
    # Kind: it is meant to be registered verbatim (see the GatewayAPI
    # ReferenceGrant and AgentSandbox entries). Re-qualifying it would build a
    # junk "$group/$version/$group/$version/$Kind" key (k61).
    return if $kind =~ m{/};

    my $full_class = $class_path =~ /^\+/
        ? substr($class_path, 1) : "IO::K8s::$class_path";

    return unless _class_exists($full_class) && $full_class->can('api_version');
    # Ask as a class method, but only accept an answer that comes back without
    # error (same guard as IO::K8s::List::api_version). An external provider's
    # class may implement api_version as an instance attribute rather than a
    # constant, in which case the class-method call dies -- skip qualifying it
    # instead of letting add() blow up.
    my $api_version = eval { $full_class->api_version };
    return if $@;
    return unless $api_version;

    my $qkey = "$api_version/$kind";
    return if exists $map->{$qkey};
    $map->{$qkey} = $class_path;
}

# Merge external resource maps into this instance
# Accepts: class names, objects with resource_map(), or plain hashrefs
sub add {
    my ($self, @providers) = @_;
    my $map = $self->resource_map;

    for my $provider (@providers) {
        my $ext_map;
        if (ref $provider eq 'HASH') {
            $ext_map = $provider;
        } else {
            my $obj = ref $provider ? $provider : do {
                require_module($provider); $provider->new;
            };
            $ext_map = $obj->resource_map;
        }

        for my $kind (keys %$ext_map) {
            my $class_path = $ext_map->{$kind};

            if (exists $map->{$kind}) {
                # COLLISION: short name already taken
                # Ensure the original entry also has a domain-qualified key
                _qualify_class_path($map, $kind, $map->{$kind});
                # New entry: domain-qualified only (no short name)
                _qualify_class_path($map, $kind, $class_path);
            } else {
                # No collision: register short name + domain-qualified
                $map->{$kind} = $class_path;
                _qualify_class_path($map, $kind, $class_path);
            }
        }
    }
    return $self;
}


sub add_crd {
    my ($self, @inputs) = @_;
    require IO::K8s::CRD;
    my %opts;
    if (@inputs > 1 && ref $inputs[-1] eq 'HASH' && !exists $inputs[-1]{kind}) {
        %opts = %{ pop @inputs };
    }
    my %registered;
    for my $input (@inputs) {
        for my $crd (@{ IO::K8s::CRD->load($input) }) {
            my $classes = IO::K8s::CRD->generate($crd, $self->_autogen_namespace, %opts);
            my $kind    = $crd->{spec}{names}{kind};
            my $storage = $classes->{storage};
            my %map = map { ("$_/$kind" => '+' . $classes->{$_}) } grep { $_ ne 'storage' } keys %$classes;
            $map{$kind} = '+' . $classes->{$storage};
            $self->add(\%map);
            # See the POD above: merge into an existing registration for this
            # Kind (two CRDs from different groups sharing a bare Kind) rather
            # than overwriting it -- 'storage' is left alone so it keeps the
            # first registration's value.
            if (my $reg = $registered{$kind}) {
                $reg->{$_} = $classes->{$_} for grep { $_ ne 'storage' && !exists $reg->{$_} } keys %$classes;
            } else {
                $registered{$kind} = { %$classes };
            }
        }
    }
    return \%registered;
}

# Expand short class name to full class path
# Supports:
#   'Pod'                    -> lookup in resource_map -> IO::K8s::Api::Core::V1::Pod
#   'Api::Core::V1::Pod'     -> IO::K8s::Api::Core::V1::Pod
#   'IO::K8s::...'           -> returned as-is
#   '+MyApp::K8s::Resource'  -> MyApp::K8s::Resource (+ prefix = full class name)
#
# Search order (versionless path; an explicitly supplied apiVersion takes the
# exact-GVK path above and never falls through to these):
#   1. '+Full::Class' / 'IO::K8s::...'  - verbatim
#   2. resource_map, domain-qualified key then short name (via _resolve_mapped,
#      which checks class_namespaces first)
#   3. User's class_namespaces
#   4. A loaded or loadable class of exactly that name -- multi-segment names
#      only ('My::StaticWebSite'); a single-segment bare name is read as a
#      Kubernetes Kind and skips this step (k35)
#   5. IO::K8s relative path
#   6. Auto-generate from openapi_spec (if available)
sub expand_class {
    my $api_version_supplied = @_ >= 3;
    my ($self, $class, $api_version) = @_;

    # +FullClassName - strip + and use as-is
    return substr($class, 1) if $class =~ /^\+/;

    my $map = ref($self) ? $self->resource_map : \%DEFAULT_RESOURCE_MAP;

    # An explicitly supplied apiVersion is an exact GVK request, including
    # undef or an empty string. It never falls through to a bare Kind or
    # class-name fallback: a class that cannot confirm the requested version
    # must not be substituted silently (k17). The one exception is the
    # resource_map's own short-name key — a legitimate GVK source when the
    # mapped class's api_version() matches the request (k31). AutoGen
    # joins in only for an exact group/version match in the openapi_spec's
    # x-kubernetes-group-version-kind metadata and fails closed otherwise
    # (no silent fallback to another version).
    if ($api_version_supplied) {
        return undef unless defined $api_version;
        my $qualified = "$api_version/$class";
        if (exists $map->{$qualified}) {
            return $self->_resolve_mapped($map->{$qualified}, $class);
        }
        # No qualified key: the short-name key is a GVK source when the
        # mapped class itself confirms the requested version (k31).
        # It has priority over AutoGen — the user explicitly registered it.
        if (my $mapped_class = $self->_resolve_short_name_gvk($map, $class, $api_version)) {
            return $mapped_class;
        }
        if (ref($self) && $self->has_openapi_spec) {
            my $autogen = $self->_autogen_class_for($class, $api_version);
            return $autogen if $autogen;
        }
        return undef;
    }

    # Already a full IO::K8s class name - return as-is
    return $class if $class =~ /^IO::K8s::/;

    # Domain-qualified string: 'cilium.io/v2/NetworkPolicy'
    if ($class =~ m{/}) {
        if (exists $map->{$class}) {
            return $self->_resolve_mapped($map->{$class}, (split m{/}, $class)[-1]);
        }
        # k31: same short-name fallback, apiVersion taken from the string.
        my ($av, $kind) = $class =~ m{\A(.*)/([^/]*)\z};
        if (my $mapped_class = $self->_resolve_short_name_gvk($map, $kind, $av)) {
            return $mapped_class;
        }
        return undef;
    }

    # Short name like "Pod" - look up in resource_map
    if (my $mapped = $map->{$class}) {
        return $self->_resolve_mapped($mapped, $class);
    }

    # Not in resource_map - might be a CRD or relative path
    # 1. Check user's class_namespaces
    if (ref($self)) {
        for my $ns (@{$self->class_namespaces}) {
            my $user_class = "${ns}::${class}";
            return $user_class if _class_exists($user_class);
        }
    }

    # 2. A MULTI-SEGMENT class name that is loaded, or loadable from @INC.
    #    This is the documented CRD case: a class named in full, e.g.
    #    'My::StaticWebSite'. It has to load, not just test — _resolve_mapped()
    #    returns a '+'-prefixed resource_map value without loading it, and a
    #    consumer may name their class here before anything has pulled it in.
    #
    #    Must stay *below* the resource_map lookup (k34, GH #7/#8). A bare
    #    Kind is a Kubernetes Kind first and a package name second: with this
    #    ahead of the map, smokers that had the CPAN distributions Event or Role
    #    installed got those back from expand_class('Event')/('Role') instead of
    #    IO::K8s::Api::Core::V1::Event / IO::K8s::Api::Rbac::V1::Role.
    #
    #    Single-segment names are excluded outright (k35). Below the map
    #    they were only reachable for a Kind the model does not know, but that
    #    still shadowed AutoGen: with an openapi_spec defining kind 'Widget'
    #    and a top-level Widget.pm installed, expand_class('Widget') returned
    #    the foreign distribution instead of the generated class. A one-segment
    #    bare name carries no namespace to tell a Kind from a package, so it is
    #    read as a Kind: it goes on to IO::K8s::<Kind> and then to AutoGen.
    #    Multi-segment names are unambiguous and keep the probe.
    #
    #    What used to force this check to also catch single-segment names was
    #    struct_to_object() re-expanding an already-resolved class. It no
    #    longer does — new_object()/json_to_object()/_inflate_struct() hand
    #    their resolved name to _struct_to_object_expanded() instead (k35),
    #    so a resource_map value of '+Widget', or new_object('+Widget'),
    #    never reaches expand_class() a second time.
    #
    #    Escape hatches for a single-segment class of your own, all documented:
    #    '+Widget', class_namespaces, or a resource_map entry.
    return $class if $class =~ /::/ && _class_exists($class);

    # 3. Check IO::K8s relative path
    my $builtin_class = 'IO::K8s::' . $class;
    return $builtin_class if _class_exists($builtin_class);

    # 4. Try auto-generation for unknown types
    if (ref($self) && $self->has_openapi_spec) {
        my $autogen = $self->_autogen_class_for($class);
        return $autogen if $autogen;
    }

    # Fall back
    return $builtin_class;
}

# Turn a resource_map VALUE into an actual class name.
#
# Shared by all three lookup branches of expand_class() so that a hit on a
# domain-qualified key ('$api_version/$Kind') resolves exactly like a hit on
# the bare short name. It did not use to: the qualified branches built
# "IO::K8s::$mapped" directly and skipped the class_namespaces search, so a
# consumer with class_namespaces => ['My::K8s'] got their own subclass from
# expand_class('Pod') but the IO::K8s class from expand_class('Pod', 'v1') --
# and inflate() always passes the apiVersion. That branch was effectively
# dead while the built-in map had no qualified keys; adding them made it the
# normal path.
#
# $kind is only used for the openapi_spec autogen fallback.
sub _resolve_mapped {
    my ($self, $mapped, $kind) = @_;

    # Mapped value with + prefix = full class name, used as-is (no
    # class_namespaces lookup - the provider named an exact class).
    return substr($mapped, 1) if $mapped =~ /^\+/;

    # 1. Check user's class_namespaces first
    if (ref($self)) {
        for my $ns (@{$self->class_namespaces}) {
            my $user_class = "${ns}::${mapped}";
            return $user_class if _class_exists($user_class);
        }
    }

    # 2. Check IO::K8s built-in
    my $builtin_class = 'IO::K8s::' . $mapped;
    return $builtin_class if _class_exists($builtin_class);

    # 3. Try auto-generation if we have openapi_spec
    if (ref($self) && $self->has_openapi_spec) {
        my $autogen = $self->_autogen_class_for($kind);
        return $autogen if $autogen;
    }

    # Fall back to IO::K8s:: path (might not exist, but let load_class handle error)
    return $builtin_class;
}

# k31: resolve a resource_map short-name key as a GVK source on the
# explicit-apiVersion path. The qualified '$api_version/$Kind' key is the
# primary lookup; this is the fallback for a map that only carries the
# short name (e.g. a CRD registered as 'StaticWebSite => "+My::StaticWebSite"').
#
# Fail closed: the mapped class must exist, expose api_version(), and report
# exactly the requested version — otherwise undef (k17 semantics: never
# substitute a class that cannot verify the request). No class is loaded
# unless the short-name key exists, and _class_exists short-circuits on
# $class->can('new'), so the common qualified-key hit costs nothing.
sub _resolve_short_name_gvk {
    my ($self, $map, $kind, $api_version) = @_;

    return unless exists $map->{$kind};
    my $mapped = $map->{$kind};

    # Same full-class derivation as _qualify_class_path: a '+' prefix means
    # the mapped value is already a full class name.
    my $full_class = $mapped =~ /^\+/
        ? substr($mapped, 1) : "IO::K8s::$mapped";

    return unless _class_exists($full_class) && $full_class->can('api_version');
    # Ask as a class method, but only accept an answer that comes back without
    # error (same guard as IO::K8s::List::api_version). A class registered via
    # resource_map need not be an IO::K8s::APIObject: api_version may be an
    # instance attribute (class-method call dies) or simply return undef. Both
    # fail closed here rather than dying or warning.
    my $class_api_version = eval { $full_class->api_version };
    return if $@;
    return unless defined $class_api_version && $class_api_version eq $api_version;

    return $self->_resolve_mapped($mapped, $kind);
}

# Check if a class exists (is loaded or can be loaded)
sub _class_exists {
    my ($class) = @_;
    # Check if already loaded
    return 1 if $class->can('new');
    # Try to load it
    eval { require_module($class) };
    return !$@;
}

# Auto-generate a class from OpenAPI spec for unknown type
#
# $api_version is optional. When given, this is an exact GVK request: the
# definition must carry a matching x-kubernetes-group-version-kind entry
# (handled by _find_definition_for_kind) and the generated class gets that
# apiVersion. When omitted, the versionless compatibility fallback picks a
# deterministic default definition and version.
#
# The cache key is GVK-specific so the same definition requested under two
# apiVersions (a definition with several GVK entries) yields two classes.
sub _autogen_class_for {
    my ($self, $kind, $api_version) = @_;

    return unless $self->has_openapi_spec;

    my $spec = $self->openapi_spec;
    my $defs = $spec->{definitions} // {};

    # Find the definition for this kind
    my $def_name = $self->_find_definition_for_kind($kind, $api_version, $defs);
    return unless $def_name;

    # Cache key is GVK-specific
    my $cache_key = $self->_autogen_namespace . '::' . $def_name;
    $cache_key .= "::$api_version" if defined $api_version;
    return $_autogen_cache{$cache_key} if $_autogen_cache{$cache_key};

    # Generate the class
    my %autogen_opts;
    $autogen_opts{api_version} = $api_version if defined $api_version;
    my $class = IO::K8s::AutoGen::get_or_generate(
        $def_name,
        $defs->{$def_name},
        $defs,
        $self->_autogen_namespace,
        %autogen_opts,
    );

    $_autogen_cache{$cache_key} = $class;
    return $class;
}

# Find OpenAPI definition name for a given kind.
#
# With an $api_version this is an EXACT GVK request: only definitions whose
# x-kubernetes-group-version-kind metadata carries that exact group/version
# count as candidates (a def_name suffix match cannot verify the version and
# is ignored). Exactly one candidate is returned; several are an ambiguity
# error (the defs are listed sorted, so the error is deterministic); none is
# undef (fail closed).
#
# Without an $api_version this is the deterministic versionless
# compatibility fallback: every def that matches the kind -- by GVK metadata
# or by def_name suffix -- is a candidate, and the lexicographically first
# def_name wins. Hash iteration order never influences the pick.
sub _find_definition_for_kind {
    my ($self, $kind, $api_version, $defs) = @_;

    my %candidates;
    for my $def_name (keys %$defs) {
        my $def = $defs->{$def_name};
        my $gvk_list = $def->{'x-kubernetes-group-version-kind'};

        if ($gvk_list) {
            for my $gvk (@$gvk_list) {
                next unless $gvk->{kind} eq $kind;
                if (defined $api_version) {
                    my $av = _gvk_api_version($gvk);
                    $candidates{$def_name} = 1 if $av eq $api_version;
                } else {
                    $candidates{$def_name} = 1;
                }
            }
        }

        # Versionless only: a def_name ending in the kind is a candidate too
        if (!defined $api_version && $def_name =~ /\.\Q$kind\E$/) {
            $candidates{$def_name} = 1;
        }
    }

    my @candidates = sort keys %candidates;

    if (defined $api_version) {
        if (@candidates > 1) {
            croak "GVK ambiguity for kind '$kind', apiVersion '$api_version': "
                . 'multiple definitions match ('
                . join(', ', @candidates) . ')';
        }
        return $candidates[0];
    }

    return $candidates[0];
}

# Wire apiVersion a GVK entry represents: group/version, or bare version
# when the group is empty (core group).
sub _gvk_api_version {
    my ($entry) = @_;
    my $group = $entry->{group} // '';
    my $version = $entry->{version} // '';
    return $group ? "$group/$version" : $version;
}

sub load_class {
    my ($self, $class) = @_;

    # Memoised: this is called once per nested object on every inflate and
    # once per hashref coercion into a named class, and require_module does
    # real work every time -- validate the module name, rewrite '::' to '/',
    # append '.pm', then require -- to reach a %INC hit that has been true
    # since the first call. Measured at ~1.9us per call against ~0.05us for
    # the lookup below, worth ~15% of a full inflate (k102 round).
    #
    # `defined` first: an undef $class must keep dying out of Module::Runtime
    # with its own 'argument is not a module name' message (the k39 path),
    # not warn about an uninitialized hash key on the way there.
    return 1 if defined $class && $_loaded_class{$class};
    require_module $class;
    $_loaded_class{$class} = 1;
    return 1;
}

sub json_to_object {
    my ($self, $class_or_json, $json) = @_;
    local $IO::K8s::Resource::STRICT = $self->strict;

    # If only one argument, auto-detect class from kind
    if (!defined $json) {
        return $self->inflate($class_or_json);
    }

    # Two arguments: class and JSON
    my $class = $self->_expand_class_or_die($class_or_json);
    my $struct = $self->json->decode($json);
    return $self->_struct_to_object_expanded($class, $struct);
}

sub struct_to_object {
    my ($self, $class_or_struct, $params) = @_;
    local $IO::K8s::Resource::STRICT = $self->strict;

    # If only one argument (a hashref), auto-detect class from kind
    if (!defined $params && ref($class_or_struct) eq 'HASH') {
        return $self->inflate($class_or_struct);
    }

    # Two arguments: a class name that still needs resolving, plus params.
    # This is the public entry point, so the name may be anything
    # expand_class() accepts (a short Kind, a domain-qualified GVK string, a
    # '+' full class). Callers that already hold a resolved class name must
    # use _struct_to_object_expanded() instead — see k35.
    return $self->_struct_to_object_expanded(
        $self->_expand_class_or_die($class_or_struct), $params);
}

# struct_to_object() minus the name resolution: $class is already the final
# class name.
#
# Split out for k35. new_object()/json_to_object() used to call
# expand_class() and then hand the result to struct_to_object(), which
# expanded it a second time. That second pass re-entered the full search
# order, so an exactly-resolved name could be re-interpreted:
# new_object('+Secret', ...) resolved to 'Secret', and the re-expansion found
# 'Secret' in the resource_map and returned the core v1 Kind instead of the
# caller's class. It also forced expand_class()'s loadable-class probe to
# stay broad enough to catch already-resolved names, which is what kept the
# shadow window open.
sub _struct_to_object_expanded {
    my ($self, $class, $params) = @_;

    # Already an object of the right class — pass through as-is
    return $params if Scalar::Util::blessed($params) && $params->isa($class);

    $self->load_class($class);

    # Self-inflating classes (union types like the apiextensions JSONSchemaProps*
    # alternatives) take over completely: they serialize as a bare value, not as
    # a hashref of attributes, so the generic path below would lose the data.
    return $class->FROM_STRUCT($params, $self) if $class->can('FROM_STRUCT');

    my $inflated = $self->_inflate_struct($class, $params);
    return $class->new(%$inflated);
}

sub inflate {
    my ($self, $data) = @_;
    local $IO::K8s::Resource::STRICT = $self->strict;

    # Accept both JSON string and hashref
    my $struct = ref($data) eq 'HASH' ? $data : $self->json->decode($data);

    my $kind = $struct->{kind}
        or die "Cannot inflate: missing 'kind' field in data";

    # A List-shaped Kind ('List' itself, or any '...List') routes to the
    # generic IO::K8s::List container rather than expand_class(): the
    # per-Kind *List classes were removed in 1.105 in favour of it, so no
    # resource_map entry -- qualified or bare -- will ever resolve one, and
    # it owns its own inflation (deriving item types from its own
    # kind/apiVersion; see IO::K8s::List::FROM_STRUCT, k46).
    if ($kind =~ /List\z/) {
        require IO::K8s::List;
        return IO::K8s::List->FROM_STRUCT($struct, $self);
    }

    my $api_version_supplied = exists $struct->{apiVersion};
    my $api_version = $struct->{apiVersion};

    my $class = $api_version_supplied
        ? $self->expand_class($kind, $api_version)
        : $self->_expand_class_or_die($kind);
    if ($api_version_supplied && !defined $class) {
        return $self->_unstructured_from_struct($struct)
            if $self->unknown_kinds eq 'unstructured';
        _die_resolution_error($kind, $api_version);
    }
    $self->load_class($class);
    my $inflated = $self->_inflate_struct($class, $struct);
    return $class->new(%$inflated);
}

sub new_object {
    my ($self, $short_class, @args) = @_;
    local $IO::K8s::Resource::STRICT = $self->strict;

    # Support:
    #   ->new_object('Pod', { ... })
    #   ->new_object('Pod', foo => 'bar')
    #   ->new_object('Pod', { ... }, 'cilium.io/v2')  # with api_version
    my ($params, $api_version);
    my $api_version_supplied = 0;
    if (@args >= 2 && ref($args[0]) eq 'HASH' && !ref($args[1])) {
        ($params, $api_version) = @args;
        $api_version_supplied = 1;
    } elsif (@args == 1 && ref($args[0]) eq 'HASH') {
        $params = $args[0];
    } else {
        $params = { @args };
    }

    # An apiVersion inside the params hash is an exact-GVK request too -- the
    # same key inflate() reads and honours. new_object used to ignore it and
    # resolve the short name to whatever version it defaults to, silently
    # substituting a version the caller did not ask for (k62). Honour it
    # for symmetry with inflate; when an explicit positional api_version is
    # also given the two must agree, or it is a genuine conflict and we fail
    # closed rather than pick one (the house line of k37/k39).
    if (ref($params) eq 'HASH' && exists $params->{apiVersion}) {
        my $inner = $params->{apiVersion};
        if ($api_version_supplied) {
            croak "new_object: conflicting apiVersion for kind '$short_class' -- "
                . "params hash says '" . (defined $inner ? $inner : '<undef>')
                . "', positional argument says '"
                . (defined $api_version ? $api_version : '<undef>') . "'"
                if (defined $inner xor defined $api_version)
                || (defined $inner && defined $api_version && $inner ne $api_version);
        } else {
            $api_version = $inner;
            $api_version_supplied = 1;
        }
    }

    my $class = $api_version_supplied
        ? $self->expand_class($short_class, $api_version)
        : $self->_expand_class_or_die($short_class);
    if ($api_version_supplied && !defined $class) {
        if ($self->unknown_kinds eq 'unstructured') {
            my %struct = (ref($params) eq 'HASH') ? %$params : ();
            $struct{kind} = $short_class unless exists $struct{kind};
            $struct{apiVersion} = $api_version unless exists $struct{apiVersion};
            return $self->_unstructured_from_struct(\%struct);
        }
        _die_resolution_error($short_class, $api_version);
    }
    return $self->_struct_to_object_expanded($class, $params);
}

# unknown_kinds => 'unstructured' opt-in (D4): build an untyped
# IO::K8s::Unstructured envelope from a document instead of dying, called
# only from the two GVK-resolution-failure sites above -- inflate()'s
# apiVersion-supplied branch and new_object()'s equivalent. apiVersion/kind
# land on their own typed attributes; everything else preserved through
# FROM_HASH's normal D1 handling (an undeclared constructor key is kept in
# _unknown_fields and re-emitted by TO_JSON).
#
# strict => 1 is deliberately exempted here: inflate/new_object localize
# $IO::K8s::Resource::STRICT for the whole call, but Unstructured never
# declares spec/status/etc, so every field beyond apiVersion/kind/metadata
# would trip strict on the one class whose entire purpose is preserving
# them. The exemption is scoped to this fallback alone -- a registered
# Kind (a Pod with a bogus field, say) still dies under strict, since this
# sub is only ever reached once resolution has already failed.
sub _unstructured_from_struct {
    my ($self, $struct) = @_;
    local $IO::K8s::Resource::STRICT = 0;
    return IO::K8s::Unstructured->FROM_HASH($struct);
}

# expand_class() for a caller-supplied name that carries no separate
# $api_version argument, failing closed the way the explicit-apiVersion path
# already does.
#
# A name with its apiVersion inside the string ('cilium.io/v2/UnknownKind') is
# an exact GVK request just like a separate argument, so an unresolvable one
# comes back undef. That undef must become the GVK error here: passed on, it
# reaches load_class() and dies out of Module::Runtime with 'argument is not a
# module name', which names neither the kind nor the apiVersion (k39).
#
# A name WITHOUT a domain qualifier is not an undef case and must not become
# one: expand_class() falls back to IO::K8s::<Name> there, so an unknown bare
# Kind keeps failing on the missing module, not on GVK resolution.
sub _expand_class_or_die {
    my ($self, $name) = @_;
    my $class = $self->expand_class($name);
    if (!defined($class) && $name =~ m{\A(.*)/([^/]*)\z}) {
        _die_resolution_error($2, $1);
    }
    return $class;
}

sub _die_resolution_error {
    my ($kind, $api_version) = @_;
    my $display = !defined($api_version) ? '<undef>'
        : length($api_version) ? $api_version
        : '<empty>';
    die "Cannot resolve Kubernetes GVK: kind '$kind', apiVersion '$display'\n";
}

sub _inflate_struct {
    my ($self, $class, $params) = @_;

    # Blessed objects should be caught by struct_to_object before reaching
    # here.  If one does slip through (defensive), extract its data rather
    # than silently returning {} which would create an empty object.
    if (Scalar::Util::blessed($params)) {
        return $params->TO_JSON if $params->can('TO_JSON');
        return {};
    }

    return {} unless ref $params eq 'HASH';

    # Opaque fields that should be passed through as-is (complex JSON structures)
    my %opaque_fields = map { $_ => 1 } qw(fieldsV1 rawExtension raw);

    # Get attribute info from the registry (keyed by Perl attr name)
    my $attr_info = $class->_k8s_attr_info;

    # Build reverse map: JSON key → Perl attr name (for sanitized names)
    my %json_to_perl;
    for my $perl_name (keys %$attr_info) {
        my $json_key = $attr_info->{$perl_name}{json_key} // $perl_name;
        $json_to_perl{$json_key} = $perl_name;
    }

    my %args;

    for my $attr (keys %$params) {
        my $value = $params->{$attr};
        next unless defined $value;

        # Pass through opaque fields without type coercion -- but not as the
        # caller's own reference (k54), see the else branch below.
        if ($opaque_fields{$attr}) {
            $args{$attr} = _shallow_copy($value);
            next;
        }

        # Look up by Perl attr name (handles sanitized JSON keys like x-kubernetes-*)
        my $perl_name = $json_to_perl{$attr} // $attr;
        my $info = $attr_info->{$perl_name} // {};

        # The registry's {class} is always a final class name: the k8s DSL
        # runs every declared type through IO::K8s::Resource::_expand_class
        # before storing it, and generated inline structs are named in full.
        # So these go straight to the pre-expanded path — sending them back
        # through expand_class() would re-interpret a name that is already
        # resolved (k35).
        if ($info->{is_array_of_objects}) {
            my $inner_class = $info->{class};
            $args{$attr} = [ map { $self->_struct_to_object_expanded($inner_class, $_) } @$value ];
        } elsif ($info->{is_hash_of_objects}) {
            my $inner_class = $info->{class};
            $args{$attr} = { map { $_ => $self->_struct_to_object_expanded($inner_class, $value->{$_}) } keys %$value };
        } elsif ($info->{is_object}) {
            $args{$attr} = $self->_struct_to_object_expanded($info->{class}, $value);
        } elsif ($info->{is_bool}) {
            # Same normalization the Bool coercer in IO::K8s::Resource applies.
            # It has to be the same one: this runs before $class->new(%args),
            # so whatever it decides is all the coercer ever gets to see, and
            # a wrong answer here cannot be rescued downstream (k37).
            # On bad data it dies without naming the field; the constructor
            # path gets that context for free from Moo's coercion wrapper,
            # this path has to attach it itself (k42). $attr is the JSON
            # key -- the name that appears in the caller's manifest.
            $args{$attr} = eval { IO::K8s::Resource::_normalize_bool($value) };
            if (my $err = $@) {
                $err =~ s/\n\z//;
                die "$err while inflating $class field $attr\n";
            }
        } else {
            # Arrays of scalars, hashes of scalars and anything untyped: the
            # inflated object must not share the caller's containers, or later
            # edits to the source struct silently rewrite the object (k54).
            # One level only, matching the output side in
            # IO::K8s::Role::Resource::TO_JSON: a nested structure under an
            # opaque hash attribute (fieldsV1, a free-form HashRef) still
            # shares its inner refs with the struct it was inflated from.
            $args{$attr} = _shallow_copy($value);
        }
    }

    return \%args;
}

# One level of copying for a plain container, deliberately not deeper -- see
# the callers above (k54). Anything that is not a plain ARRAY or HASH
# (a scalar, a blessed value, a JSON boolean object) is returned untouched.
sub _shallow_copy {
    my ($value) = @_;
    return [ @$value ] if ref $value eq 'ARRAY';
    return { %$value } if ref $value eq 'HASH';
    return $value;
}

sub object_to_struct {
    my ($self, $object) = @_;
    return $object->TO_JSON;
}

sub object_to_json {
    my ($self, $object) = @_;
    return $object->to_json;
}

sub load {
    my ($self, $file) = @_;

    require IO::K8s::Manifest;

    # Set k8s instance for DSL functions
    local $IO::K8s::Manifest::_k8s_instance = $self;

    return IO::K8s::Manifest->_load_file($file, $self);
}

sub load_yaml {
    my ($self, $file_or_string, %opts) = @_;

    require YAML::PP;

    my $content;
    if ($file_or_string !~ /\n/ && -f $file_or_string) {
        # It's a file path
        open my $fh, '<', $file_or_string or die "Cannot open $file_or_string: $!";
        $content = do { local $/; <$fh> };
        close $fh;
    } else {
        # It's YAML content
        $content = $file_or_string;
    }

    # Parse multi-document YAML (Load returns all docs in list context)
    my @docs = YAML::PP::Load($content);

    my $collect_errors = $opts{collect_errors};
    my @objects;
    my @errors;

    # Inflate each document - this validates types!
    for my $i (0 .. $#docs) {
        my $doc = $docs[$i];
        next unless $doc && ref($doc) eq 'HASH';

        if ($collect_errors) {
            eval { push @objects, $self->inflate($doc) };
            if ($@) {
                my $name = $doc->{metadata}{name} // "document $i";
                my $kind = $doc->{kind} // 'unknown';
                push @errors, "$kind/$name: $@";
            }
        } else {
            push @objects, $self->inflate($doc);
        }
    }

    # In collect_errors mode, return (objects, errors) in list context
    if ($collect_errors) {
        return (\@objects, \@errors);
    }

    return \@objects;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s - Objects representing things found in the Kubernetes API

=head1 VERSION

version 1.108

=head1 SYNOPSIS

  use IO::K8s;

  my $k8s = IO::K8s->new;

  # Load .pk8s manifest files (Perl DSL)
  my $resources = $k8s->load('myapp.pk8s');

  # Load YAML manifests and validate declared field types
  my $resources = $k8s->load_yaml('deployment.yaml');

  # Also reject fields the current model does not declare
  my $strict_k8s = IO::K8s->new(strict => 1);
  my $strict_resources = $strict_k8s->load_yaml('deployment.yaml');

  # Validate with error collection
  my ($objs, $errors) = $k8s->load_yaml($yaml, collect_errors => 1);

  # Create objects programmatically
  my $pod = $k8s->new_object('Pod',
      metadata => { name => 'my-pod', namespace => 'default' },
      spec => { containers => [{ name => 'app', image => 'nginx' }] }
  );

  # Export to YAML and save
  print $pod->to_yaml;
  $pod->save('pod.yaml');

  # Inflate JSON/struct into typed objects
  my $svc = $k8s->json_to_object('Service', '{"kind":"Service",...}');
  my $obj = $k8s->inflate($json_with_kind);  # Auto-detect class from 'kind'

  # Serialize back
  my $json = $k8s->object_to_json($svc);
  my $struct = $k8s->object_to_struct($pod);

  # With OpenAPI spec for Custom Resources (CRDs)
  my $k8s = IO::K8s->new(openapi_spec => $spec_from_cluster);
  my $helmchart = $k8s->inflate($helmchart_json);  # Auto-generates class!

  # With external resource map providers (e.g. IO::K8s::Cilium)
  my $k8s = IO::K8s->new(with => ['IO::K8s::Cilium']);

  # Or add at runtime
  $k8s->add('IO::K8s::Cilium');           # class name
  $k8s->add(IO::K8s::Cilium->new);        # instance
  $k8s->add({ MyThing => '+My::Thing' }); # raw hashref

  # Disambiguate colliding kind names (e.g. both core and Cilium have NetworkPolicy)
  $k8s->new_object('NetworkPolicy', { ... });                  # core (first-registered)
  $k8s->new_object('NetworkPolicy', { ... }, 'cilium.io/v2');  # Cilium
  $k8s->new_object('cilium.io/v2/NetworkPolicy', { ... });     # domain-qualified

  # inflate() auto-uses apiVersion from the data for disambiguation
  $k8s->inflate('{"kind":"NetworkPolicy","apiVersion":"cilium.io/v2",...}');

=head1 DESCRIPTION

This module provides objects and serialization / deserialization methods that represent
the structures found in the Kubernetes API L<https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.37/>

Kubernetes API is strict about input types. When a value is expected to be an integer,
sending it as a string will cause rejection. This module ensures correct value types
in JSON that can be sent to Kubernetes.

It also inflates JSON returned by Kubernetes into typed Perl objects.

=head2 add_crd

    my $registered = $k8s->add_crd('crds/knobs.yaml', $crd_object, \%crd_hash, ...);

Loads each argument through L<IO::K8s::CRD/load>, generates one class per
served version in this instance's AutoGen namespace, and registers them:
every version under its domain-qualified key (C<group/version/Kind>), the
storage version under the bare Kind -- through L</add>, so a class already
holding the short name (a provider merged earlier) keeps it and the CRD's
class stays reachable by its qualified key. Returns
C<< { $Kind => { $api_version => $class, ..., storage => $api_version } } >>.
Classes are cached by group/version/Kind within this instance's AutoGen
namespace (L<IO::K8s::CRD/generate>), so re-adding an edited manifest on
the same C<$k8s> silently returns the class generated the first time --
call C<add_crd> on a fresh instance to pick up schema changes; classes
generated by any call live for the life of the process regardless, so a
reload loop that builds a fresh C<$k8s> per iteration (rather than calling
C<add_crd> again on the same one) accumulates classes rather than freeing
the old ones -- C<add_crd> is meant to run once at startup, not inside a
polling loop.

Two CRDs can legitimately share a bare Kind across groups (their
domain-qualified keys, not the Kind alone, are what actually disambiguate
them) -- calling C<add_crd> for both merges the second's version entries
into the first's return value under that Kind rather than replacing it
outright, and C<storage> stays whichever the FIRST registration reported,
mirroring L</add>'s own first-registration-wins rule for a short-name
collision.

A trailing hashref of options is forwarded to L<IO::K8s::CRD/generate> (and
from there to L<IO::K8s::AutoGen/get_or_generate>) for every CRD in this
call:

    $k8s->add_crd('crds/knobs.yaml', { reuse_core => 0 });

Distinguished from a CRD document by the absence of a C<kind> key -- every
CRD hashref L<IO::K8s::CRD/load> accepts has one -- so it must be the LAST
argument and only one is read per call.

=head1 NAME

IO::K8s - Objects representing things found in the Kubernetes API

=head1 CLASS ARCHITECTURE

IO::K8s uses a layered architecture. Understanding these layers helps when
working with built-in resources or writing your own CRD classes.

=head2 IO::K8s::Resource (setup layer)

Declaring a class with C<use IO::K8s::Resource> imports L<Moo>, installs the
C<k8s> DSL, and composes L<IO::K8s::Role::Resource>. It does not make that
class C<isa('IO::K8s::Resource')>. It provides:

=over 4

=item * L<Moo> class setup

=item * The C<k8s> DSL for declaring attributes with Kubernetes types

=item * C<TO_JSON> / C<to_json> serialization

=item * Type registry for inflation (JSON -> objects)

=back

The C<k8s> DSL supports these type specifications:

  k8s name     => 'Str';                   # string attribute
  k8s replicas => 'Int';                   # integer attribute
  k8s ready    => 'Bool';                  # boolean attribute
  k8s spec     => 'Core::V1::PodSpec';     # nested IO::K8s object
  k8s ports    => ['Core::V1::ServicePort']; # array of objects
  k8s labels   => { Str => 1 };            # hash of strings
  k8s items    => ['+Full::Class::Name'];  # array with full class (+ prefix)

=head2 IO::K8s::APIObject (top-level resources)

L<IO::K8s::APIObject> uses the same setup for top-level API objects
(Pod, Deployment, Service, etc.) and additionally composes
L<IO::K8s::Role::APIObject>. It adds:

=over 4

=item * C<metadata> attribute (L<IO::K8s::Apimachinery::Pkg::Apis::Meta::V1::ObjectMeta>)

=item * C<api_version()> - derived from class name for built-in types, or set via import parameter for CRDs

=item * C<kind()> - derived from the last segment of the class name

=item * C<resource_plural()> - the plural Kubernetes addresses the Kind by
(C<pods>, C<networkpolicies>, C<ingresses>), from a table generated off the
upstream spec for built-in types; CRDs declare their own

=item * C<to_yaml()> - serialize to YAML suitable for C<kubectl apply -f>

=item * C<save($file)> - write YAML to file

=back

=head2 IO::K8s::Role::Namespaced (marker role)

L<IO::K8s::Role::Namespaced> is a marker role for namespace-scoped resources.
L<Kubernetes::REST> checks this to build the correct URL path (with or without
C</namespaces/{ns}/>).

=head1 WRITING CRD CLASSES

To use Custom Resource Definitions with L<Kubernetes::REST>, write a Perl
class using C<IO::K8s::APIObject>. It gives a custom class the same Moo/DSL
setup and top-level APIObject role composition as built-in Kubernetes types
like Pod, Deployment, and Service.

=head2 Minimal CRD class

  package My::StaticWebSite;
  use IO::K8s::APIObject
      api_version     => 'homelab.example.com/v1',
      resource_plural => 'staticwebsites';
  with 'IO::K8s::Role::Namespaced';

  k8s spec   => { Str => 1 };
  k8s status => { Str => 1 };
  1;

That's it - 6 lines of actual code. This class now supports:

  my $site = My::StaticWebSite->new(
      metadata => $meta_object,
      spec     => { domain => 'blog.example.com', image => 'nginx' },
  );
  $site->kind;          # "StaticWebSite"
  $site->api_version;   # "homelab.example.com/v1"
  $site->to_yaml;       # full YAML output
  $site->TO_JSON;       # hashref for JSON encoding

=head2 Import parameters

C<use IO::K8s::APIObject> accepts these parameters:

=over 4

=item C<api_version> (required for CRDs)

The CRD's C<group/version>, e.g. C<'homelab.example.com/v1'>. For built-in
types this is derived from the class name (C<IO::K8s::Api::Core::V1::Pod>
gives C<v1>), but CRDs must specify it explicitly since their class names
don't follow the C<IO::K8s::Api::*> convention.

=item C<resource_plural> (recommended for CRDs)

The plural resource name for URL building and RBAC C<resources:> rules,
e.g. C<'staticwebsites'>. Must match the CRD's C<spec.names.plural>. An
explicit value always wins over anything IO::K8s knows.

Built-in Kinds do not need this: their plurals come from a table generated
off the upstream OpenAPI spec's REST paths. CRDs do, because there is no
spec to read them from. If omitted, C<resource_plural()> returns C<undef>
and the caller is left to pluralize the kind name itself
(C<StaticWebSite> -E<gt> C<staticwebsites>) -- that heuristic does not work
for all names, which is exactly why declaring it is recommended.

=back

=head2 Namespaced vs cluster-scoped

Apply C<IO::K8s::Role::Namespaced> for namespace-scoped CRDs (the common
case). Omit it for cluster-scoped CRDs:

  # Namespaced CRD (most CRDs):
  package My::StaticWebSite;
  use IO::K8s::APIObject api_version => 'homelab.example.com/v1', ...;
  with 'IO::K8s::Role::Namespaced';

  # Cluster-scoped CRD (rare):
  package My::ClusterBackupPolicy;
  use IO::K8s::APIObject api_version => 'backup.example.com/v1', ...;
  # No 'with Namespaced' - this is cluster-wide

=head2 Registering with Kubernetes::REST

Register your CRD class in the resource map using the C<+> prefix (which
means "use this full class name as-is"):

  use Kubernetes::REST::Kubeconfig;
  use My::StaticWebSite;

  my $api = Kubernetes::REST::Kubeconfig->new->api;
  $api->resource_map->{StaticWebSite} = '+My::StaticWebSite';

  # Now use it like any built-in resource
  my $site = $api->create($api->new_object(StaticWebSite =>
      metadata => { name => 'my-blog', namespace => 'default' },
      spec     => { domain => 'blog.example.com', image => 'nginx' },
  ));

See L<Kubernetes::REST::Example> for complete CRUD examples with CRDs.

=head1 AUTO-GENERATION

IO::K8s can automatically generate classes for Custom Resources and other
types not included in the built-in classes. This is an alternative to
writing CRD classes by hand.

=head2 From cluster OpenAPI spec

Provide the cluster's OpenAPI spec and IO::K8s will auto-generate classes
on demand:

  use IO::K8s;
  use Kubernetes::REST::Kubeconfig;

  # Get OpenAPI spec from cluster
  my $api = Kubernetes::REST::Kubeconfig->new->api;
  my $resp = $api->_request('GET', '/openapi/v2');
  my $spec = JSON::MaybeXS->new->decode($resp->content);

  # Create IO::K8s with auto-generation enabled
  my $k8s = IO::K8s->new(openapi_spec => $spec);

  # An unknown Kind with an unambiguous GVK definition in this spec auto-generates a class
  my $addon = $k8s->inflate($k3s_addon_json);   # k3s.cattle.io/v1 Addon
  my $chart = $k8s->inflate($helmchart_json);   # helm.cattle.io/v1 HelmChart

Auto-generated classes are placed in a unique namespace per IO::K8s instance
(e.g., C<IO::K8s::_AUTOGEN_abc123::...>) to avoid collisions.

=head2 From a CustomResourceDefinition manifest

Loading a CRD manifest directly -- see L</add_crd> -- generates one class
per served version and goes further than the OpenAPI-spec path above: every
inline C<type: object> schema below the top level, which is how a CRD
schema is written everywhere below its Kind, becomes its own nested class
named after its place in the parent (C<< <Kind>::<Prop> >>, with an
C<Item> / C<Value> suffix for array items and map values) instead of an
opaque hash of strings, so field options and the unknown-field bag apply at
every level. Hash-style access on such a field still works -- a Moo object
is a blessed hash keyed by attribute name -- so code that reads
C<< $obj->{spec}{mode} >> does not need to change either way. Only a
property-less object and an C<additionalProperties>-only map (nothing
underneath to attach options to) stay opaque. L<IO::K8s::CRD::Emitter>
renders the same classes as checked-in source.

=head2 Explicit generation with IO::K8s::AutoGen

For more control, use L<IO::K8s::AutoGen> directly:

  use IO::K8s::AutoGen;

  my $class = IO::K8s::AutoGen::get_or_generate(
      'com.example.homelab.v1.StaticWebSite',  # definition name
      $schema,                                   # OpenAPI schema
      {},                                        # all definitions
      'MyApp::K8s',                              # namespace
      api_version     => 'homelab.example.com/v1',
      kind            => 'StaticWebSite',
      resource_plural => 'staticwebsites',
      is_namespaced   => 1,
  );

  # Register with Kubernetes::REST
  $api->resource_map->{StaticWebSite} = "+$class";

=head2 Custom Class Namespaces

You can provide your own pre-built classes that take precedence over both
built-in and auto-generated classes:

  my $k8s = IO::K8s->new(
      class_namespaces => ['MyApp::K8s'],
      openapi_spec => $spec,
  );

With this configuration, the class lookup order is:

  1. MyApp::K8s::...          (your classes)
  2. IO::K8s::...             (built-in classes)
  3. IO::K8s::_AUTOGEN_...    (auto-generated)

This lets you create optimized or customized classes for specific resources
while falling back to auto-generation for everything else.

=head1 ATTRIBUTES

=head2 with

Optional. ArrayRef of external resource map providers to merge at construction
time. Each entry can be a class name (string) or an object instance. Classes
must consume L<IO::K8s::Role::ResourceMap> or otherwise provide a
C<resource_map()> method.

    my $k8s = IO::K8s->new(with => ['IO::K8s::Cilium']);

When kinds collide (e.g. both core and Cilium have C<NetworkPolicy>), the
first-registered entry keeps the short name. All entries are always reachable
via domain-qualified names (C<api_version/Kind>).

=head2 strict

Optional. Boolean, default C<0>. Governs what happens when a constructor key
matches no declared attribute, at any nesting level. With the default C<0> the
field is kept and re-emitted by C<TO_JSON> (see
L<IO::K8s::Role::Resource/UNKNOWN FIELDS>); with C<1> it dies instead, with
C<Unknown field 'E<lt>nameE<gt>' for E<lt>classE<gt>>.

    my $k8s = IO::K8s->new(strict => 1);
    $k8s->new_object('Pod', { spec => { bogusField => 1 } });
    # dies: Unknown field 'bogusField' for IO::K8s::Api::Core::V1::PodSpec

C<strict> is read by L</inflate>, L</new_object>, L</json_to_object> and
L</struct_to_object>; L</load> and L</load_yaml> inherit it because both
build on C<inflate>/C<new_object>. It applies for the duration of that one
call, including every nested object it constructs along the way.

Since k99, L<IO::K8s::List>, the envelope a list Kind inflates to, also
composes L<IO::K8s::Role::Resource>: its own top-level keys are preserved
and checked under C<strict> exactly like any other resource's, alongside
the objects inside C<items>, each through its own class.

=head2 unknown_kinds

Optional. String, default C<''>. Governs what L</inflate> and L</new_object>
do when a document's C<apiVersion>/C<kind> (or an explicit C<api_version>
argument) amount to a GVK request that resolves to no registered class --
built-in, CRD-registered via C<add()>/C<add_crd()>, or AutoGen'd from
C<openapi_spec>. With the default C<''> this keeps failing closed exactly as
without the option, dying with:

    Cannot resolve Kubernetes GVK: kind '<kind>', apiVersion '<apiVersion>'

With C<< unknown_kinds => 'unstructured' >>, that failure instead builds an
L<IO::K8s::Unstructured> from the document: C<apiVersion>, C<kind> and
C<metadata> land on typed attributes, everything else round-trips through
the C<_unknown_fields> bag (D1) exactly as an undeclared field on any other
class does.

    my $k8s = IO::K8s->new(unknown_kinds => 'unstructured');
    my $obj = $k8s->inflate($document);   # an IO::K8s::Unstructured, not a die

Any value other than the literal string C<'unstructured'> -- including one
left unset -- keeps the fail-closed default; this is strictly opt-in. C<<
strict => 1 >> combined with this option still dies on a registered Kind
with an unexpected field the normal way; the C<Unstructured> envelope itself
is exempt from C<strict>, since every field beyond
C<apiVersion>/C<kind>/C<metadata> is precisely what it exists to preserve.

=head2 openapi_spec

Optional. The OpenAPI v2 specification from a Kubernetes cluster. When provided,
enables auto-generation of classes for types not found in the built-in classes.

=head2 class_namespaces

Optional. ArrayRef of namespace prefixes to search for classes before checking
IO::K8s built-ins. Useful for providing your own implementations.

=head2 resource_map

HashRef mapping short names (like C<Pod>) and domain-qualified names
(like C<networking.k8s.io/v1/NetworkPolicy>) to class paths. Defaults to
built-in mappings for standard Kubernetes resources. Each instance gets its
own copy, so modifications via C<add()> do not affect other instances.

=head2 json

A L<JSON::MaybeXS> encoder/decoder configured with C<utf8 =E<gt> 1> and
C<canonical =E<gt> 1>. Used by L</object_to_json>, L</json_to_object> and
L</inflate> for their default encoding/decoding. Override at construction
when the caller needs a different encoder (for example, to disable
C<canonical> for tighter output, or to swap in a different backend):

    my $k8s = IO::K8s->new(json => JSON::MaybeXS->new(utf8 => 1));

=head1 METHODS

=head2 add

    $k8s->add('IO::K8s::Cilium');             # class name
    $k8s->add(IO::K8s::Cilium->new);          # instance
    $k8s->add({ MyKind => '+My::Class' });     # raw hashref
    $k8s->add($provider1, $provider2);         # multiple at once

Merge external resource maps into this instance. Accepts class names, object
instances with a C<resource_map()> method, or plain hashrefs.

When a kind name already exists in the resource map (collision), the
first-registered entry keeps the short name. Both the existing and new
entries are registered under domain-qualified names (C<api_version/Kind>)
so they remain reachable.

Returns C<$self> for chaining.

=head2 load

    my $resources = $k8s->load('myapp.pk8s');

Load a C<.pk8s> manifest file and return an ArrayRef of IO::K8s objects.

B<Trust boundary:> A C<.pk8s> manifest is Perl code, not data. The loader
C<eval>s the file content in-process, so a C<.pk8s> file can execute
arbitrary code with the full privileges of the running program. Only load
C<.pk8s> files from sources you trust. For data-only manifests (YAML or
JSON), use C<load_yaml>, which parses without executing any code.

The C<.pk8s> file format is Perl code with a DSL for defining Kubernetes
resources:

    # myapp.pk8s
    ConfigMap {
        name => 'my-config',
        namespace => 'default',
        data => { key => 'value' }
    };

    Deployment {
        name => 'my-app',
        namespace => 'default',
        spec => {
            replicas => 3,
            selector => { matchLabels => { app => 'my-app' } },
            template => {
                metadata => { labels => { app => 'my-app' } },
                spec => {
                    containers => [{
                        name => 'app',
                        image => 'my-app:latest',
                    }],
                },
            },
        }
    };

Inside C<{}> blocks, C<name>, C<namespace>, C<labels>, and C<annotations>
are automatically moved to C<metadata>.

With CRDs (requires openapi_spec):

    my $k8s = IO::K8s->new(openapi_spec => $spec);
    my $resources = $k8s->load('helmchart.pk8s');

=head2 load_yaml

    my $resources = $k8s->load_yaml('manifest.yaml');
    my $resources = $k8s->load_yaml($yaml_string);

Load a YAML manifest file (or YAML string) and return an ArrayRef of IO::K8s
objects. Supports multi-document YAML (separated by C<--->).

This method validates declared fields against the Kubernetes types. A declared
field with the wrong type throws an error. By default, an undeclared field is
kept for forward-compatible round-tripping; construct C<IO::K8s> with
C<< strict => 1 >> to reject it instead. This is useful for validating
manifests before applying them to a cluster.

    # Validate a manifest file and reject undeclared fields
    my $strict_k8s = IO::K8s->new(strict => 1);
    eval {
        my $objs = $strict_k8s->load_yaml('deployment.yaml');
        say "Valid! Contains " . scalar(@$objs) . " resources";
    };
    if ($@) {
        say "Invalid manifest: $@";
    }

B<Options:>

=over 4

=item collect_errors => 1

Collect all validation errors instead of stopping at the first one. Returns
a list of C<(objects, errors)> where C<objects> contains successfully parsed
resources and C<errors> is an ArrayRef of error messages.

    my ($objs, $errors) = $k8s->load_yaml($yaml, collect_errors => 1);
    if (@$errors) {
        say "Found " . scalar(@$errors) . " errors:";
        say "  - $_" for @$errors;
    }

=back

=head2 new_object

    my $pod = $k8s->new_object('Pod', %args);
    my $pod = $k8s->new_object('Pod', \%args);
    my $np  = $k8s->new_object('NetworkPolicy', \%args, 'cilium.io/v2');
    my $np  = $k8s->new_object('cilium.io/v2/NetworkPolicy', \%args);

Create a new Kubernetes object of the given type. The type can be a short name
(like C<Pod>), a domain-qualified name (like C<cilium.io/v2/NetworkPolicy>),
or a full class path (like C<My::StaticWebSite>).

A bare one-word name is always read as a Kubernetes Kind, never as a package
name, so it resolves through the resource map, C<class_namespaces>,
C<IO::K8s::>E<lt>KindE<gt> and auto-generation -- a same-named top-level
distribution that happens to be installed is not consulted. To name a
single-segment class of your own, prefix it: C<< $k8s->new_object('+Widget',
\%args) >>.

An optional third argument specifies the C<api_version> to disambiguate when
multiple providers register the same kind name.

An C<apiVersion> key inside the params hash is honoured symmetrically with
L</inflate>: it is treated as the exact GVK the caller wants, and the
short name resolves against it instead of whichever version the class
defaults to. When a positional C<api_version> is also given and the two
disagree -- including one being defined and the other undef -- this
croaks rather than picking one (k62):

    new_object: conflicting apiVersion for kind 'NetworkPolicy' --
    params hash says 'cilium.io/v2', positional argument says 'networking.k8s.io/v1'

If the name is domain-qualified (like C<cilium.io/v2/NetworkPolicy>) or an
explicit C<api_version> argument is given, it is a GVK (Group/Version/Kind)
request. When such a request cannot be resolved to a class, the call dies
rather than silently falling back to a different version or a similarly-named
class:

    Cannot resolve Kubernetes GVK: kind 'UnknownKind', apiVersion 'nonexistent.io/v1'

A bare unqualified name is not a GVK request and is exempt from this check --
as described above, it falls back to C<IO::K8s::>E<lt>KindE<gt>, and if that
class doesn't exist either, the failure is Perl's own module-loading error
(C<Can't locate ... in @INC>), not the GVK error.

This same fail-closed behaviour applies uniformly across C<new_object>,
C<inflate>, C<json_to_object> and C<struct_to_object>.

=head2 inflate

    my $obj = $k8s->inflate($json_string);
    my $obj = $k8s->inflate(\%hashref);

Inflate a JSON string or hashref into a typed IO::K8s object. The class is
auto-detected from the C<kind> field in the data. When external resource maps
have been added via C<add()>, the C<apiVersion> field is used to disambiguate
colliding kind names.

If C<kind>/C<apiVersion> amount to a GVK request that cannot be resolved, this
dies with the same fail-closed error as L</new_object> -- see there for the
exact message and the bare-Kind exemption.

=head2 json_to_object

    my $obj = $k8s->json_to_object($json_with_kind);
    my $obj = $k8s->json_to_object('Pod', $json_string);

Convert JSON to an IO::K8s object. With one argument, auto-detects the class
from C<kind>. With two arguments, uses the specified class.

When the class argument is a GVK request (domain-qualified, or paired with an
C<api_version>) that cannot be resolved, this dies with the same fail-closed
error as L</new_object> -- see there for the exact message and the bare-Kind
exemption.

=head2 struct_to_object

    my $obj = $k8s->struct_to_object(\%hashref_with_kind);
    my $obj = $k8s->struct_to_object('Pod', \%hashref);

Convert a Perl hashref to an IO::K8s object. With one argument, auto-detects
the class from C<kind>. With two arguments, uses the specified class.

When the class argument is a GVK request (domain-qualified, or paired with an
C<api_version>) that cannot be resolved, this dies with the same fail-closed
error as L</new_object> -- see there for the exact message and the bare-Kind
exemption.

If the target class provides a C<FROM_STRUCT> class method, it is called as
C<< $class->FROM_STRUCT($struct, $k8s) >> and its return value is used as-is,
bypassing the generic field-by-field inflation. This is the hook for union
types that serialize as a bare alternative rather than as a hashref of
attributes -- see
L<IO::K8s::ApiextensionsApiserver::Pkg::Apis::Apiextensions::V1::JSONSchemaPropsOrBool>
and its siblings, where C<additionalProperties: false> has to stay a boolean
instead of collapsing into an empty object. A class implementing
C<FROM_STRUCT> is responsible for its own C<TO_JSON> as well, so that the two
directions stay symmetric.

=head2 object_to_json

    my $json = $k8s->object_to_json($obj);

Serialize an IO::K8s object to JSON.

=head2 object_to_struct

    my $hashref = $k8s->object_to_struct($obj);

Convert an IO::K8s object to a plain Perl hashref.

=head2 expand_class

    my $class = $k8s->expand_class('Pod');
    my $class = $k8s->expand_class('cilium.io/v2/NetworkPolicy');
    my $class = $k8s->expand_class('NetworkPolicy', 'cilium.io/v2');

Resolve a name to a Perl class. The name can be a short Kind, a
domain-qualified C<api_version/Kind>, or a full class path (prefix with
C<+> for a verbatim class name, or write the C<IO::K8s::> prefix in
full). Returns the class name as a string -- this method does not load
the class.

An explicit C<api_version> makes the lookup an exact GVK request: when
no class can confirm the requested version, returns C<undef>. The
qualified C<api_version/Kind> form is checked first against the resource
map, then a short-name key whose mapped class itself reports the
requested C<api_version>, then the C<openapi_spec> for an auto-generated
class. Anything else fails closed rather than substituting a different
version (k17).

A bare unqualified name is B<not> a GVK request: it falls through to
C<IO::K8s::>E<lt>KindE<gt> and then to auto-generation, and a name that
resolves to nothing fails with the usual module-loading exception, not
the GVK error.

=head2 load_class

    $k8s->load_class('IO::K8s::Api::Core::V1::Pod');

Load (C<< require >>) a class by name. Used internally after
L</expand_class> to make sure the class is in C<%INC> before the caller
hands it to C<< $class->new >>. Dies with the usual C<Can't locate ... in
@INC> message when the class is not installable.

Successful loads are remembered process-wide, so the second and every
later call for the same name costs a hash lookup instead of a
C<require>. Failures are B<not> remembered: a name that did not load is
attempted again on the next call, which is what keeps a package that
only becomes available later -- one defined at runtime and registered in
C<%INC>, or a module installed mid-process -- reachable.

=head1 CILIUM CRD SUPPORT

IO::K8s includes L<IO::K8s::Cilium> with 31 resource-map entries: 22
short-name Kinds (17 C<cilium.io/v2> + 5 C<cilium.io/v2alpha1>) and 9
domain-qualified back-compat tracks for v2alpha1 BGP/CIDR/LoadBalancerIPPool,
CiliumBGPPeeringPolicy, and CiliumExternalWorkload. The compatibility tracks
remain reachable for older clusters without displacing the current short-name
Kind. These are not loaded by default -- opt in at construction:

  my $k8s = IO::K8s->new(with => ['IO::K8s::Cilium']);

  my $cnp = $k8s->new_object('CiliumNetworkPolicy',
      metadata => { name => 'allow-dns', namespace => 'kube-system' },
      spec => { endpointSelector => { matchLabels => { app => 'dns' } } },
  );

  print $cnp->to_yaml;

All Cilium kinds are C<Cilium>-prefixed, so there are no collisions with
core Kubernetes kind names.

=head1 EXTERNAL RESOURCE MAPS

IO::K8s supports merging resource maps from external packages (like
L<IO::K8s::Cilium> for Cilium CRDs). This allows multiple packages to
provide typed Kubernetes objects that work together.

=head2 Writing a resource map provider

Create a class that consumes L<IO::K8s::Role::ResourceMap>:

  package My::CRD::Provider;
  use Moo;
  with 'IO::K8s::Role::ResourceMap';

  sub resource_map {
      return {
          MyCustomKind => '+My::CRD::V1::MyCustomKind',
      };
  }

See L<IO::K8s::Cilium> for a real-world provider with 22 current short-name
Kinds and nine domain-qualified compatibility tracks.

=head2 Collision handling

When two providers register the same kind name, the first-registered entry
keeps the short name. Both entries are always reachable via domain-qualified
names (C<api_version/Kind>):

  my $k8s = IO::K8s->new(with => ['My::Firewall::Provider']);

  # Short name -> core (first-registered)
  $k8s->expand_class('NetworkPolicy');
  # -> IO::K8s::Api::Networking::V1::NetworkPolicy

  # Domain-qualified -> specific version
  $k8s->expand_class('firewall.example.com/v1/NetworkPolicy');
  # -> My::Firewall::V1::NetworkPolicy

  # api_version parameter for disambiguation
  $k8s->expand_class('NetworkPolicy', 'firewall.example.com/v1');
  # -> My::Firewall::V1::NetworkPolicy

=head2 Disambiguation in pk8s DSL

In C<.pk8s> manifest files, pass the api_version as a second argument:

  # Core NetworkPolicy (default)
  NetworkPolicy { name => 'deny-all', spec => { ... } };

  # Firewall NetworkPolicy (disambiguated, no comma - like grep/map syntax)
  NetworkPolicy { name => 'deny-all', spec => { ... } } 'firewall.example.com/v1';

=head1 UPGRADING FROM PREVIOUS VERSIONS

B<WARNING: Version 1.00 contains breaking changes!>

This version has been completely rewritten. Key changes that may affect your code:

=over 4

=item * B<Moose to Moo migration>

All classes now use L<Moo> instead of L<Moose>. This means faster startup and
lighter dependencies, but Moose-specific features (meta introspection, etc.)
are no longer available.

=item * B<List classes removed>

Individual C<*List> classes (e.g., C<IO::K8s::Api::Core::V1::PodList>) have been
replaced with the unified L<IO::K8s::List> class. The old class names emitted
deprecation warnings for a while; as of this release they have been dropped
from this distribution entirely. If you need the old name to fail loudly
instead of silently resolving to a stale prior release, install
L<IO::K8s::Deprecated>, which ships CPAN redirect stubs for all 76 of them.

=item * B<Updated to Kubernetes v1.37 API>

API objects have been updated from v1.14 to v1.37. Some fields may have changed,
been added, or removed according to upstream Kubernetes API changes.

=item * B<New Role for namespaced resources>

Resources that are namespaced now consume L<IO::K8s::Role::Namespaced>. Use
C<< $class->does('IO::K8s::Role::Namespaced') >> to check if a resource is
namespace-scoped.

=back

=head1 SEE ALSO

L<Kubernetes::REST> - REST client for the Kubernetes API, uses IO::K8s for typed request/response objects

L<IO::K8s::Deprecated> - CPAN redirect stubs for IO::K8s module names that were renamed or removed

Bundled CRD providers: L<IO::K8s::Cilium>, L<IO::K8s::Traefik>,
L<IO::K8s::CertManager>, L<IO::K8s::K3s>, L<IO::K8s::GatewayAPI>,
L<IO::K8s::AgentSandbox>, L<IO::K8s::PrometheusOperator>,
L<IO::K8s::VolumeSnapshot>, and L<IO::K8s::ExternalSecrets>

L<Kubernetes::REST::Example> - Comprehensive examples for using Kubernetes::REST with IO::K8s against a real cluster (Minikube, K3s, etc.)

L<https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.37/>

=head1 BUGS and SOURCE

The source code is located here: L<https://github.com/pplu/io-k8s-p5>

Please report bugs to: L<https://github.com/pplu/io-k8s-p5/issues>

=head1 COPYRIGHT and LICENSE

Copyright (c) 2018 by Jose Luis Martinez
Copyright (c) 2026 by Torsten Raudssus

This code is distributed under the Apache 2 License. The full text of the
license can be found in the LICENSE file included with this module.

=head1 AUTHORS

=over 4

=item *

Torsten Raudssus <torsten@raudssus.de> (current maintainer)

=item *

Jose Luis Martinez <jlmartin@cpan.org> (original author)

=back

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/pplu/io-k8s-p5/issues>.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHORS

=over 4

=item *

Torsten Raudssus <getty@cpan.org>

=item *

Jose Luis Martinez Torres <jlmartin@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018-2026 by Jose Luis Martinez Torres <jlmartin@cpan.org>.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
