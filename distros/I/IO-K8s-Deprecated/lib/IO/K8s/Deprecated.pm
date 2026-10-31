package IO::K8s::Deprecated;
our $VERSION = '1.112';
# ABSTRACT: Registry of CPAN redirect stubs for renamed/retired IO::K8s modules

use strict;
use warnings;


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Deprecated - Registry of CPAN redirect stubs for renamed/retired IO::K8s modules

=head1 VERSION

version 1.112

=head1 DESCRIPTION

C<IO::K8s::Deprecated> is the permanent home for "tombstone" redirect stub
modules: when an IO::K8s class gets renamed or retired, the old module
name stays indexed on PAUSE forever against the last release that shipped
it -- PAUSE has no delete. Anyone still running C<cpanm Old::Module::Name>
would keep installing that stale, superseded code with no hint a
replacement exists.

PAUSE indexes per B<module name>, not per distribution: it resolves each
module name to whichever shipped release -- of any distribution, including
a later release of the I<same> one -- carries the highest C<$VERSION> for
that name. IO::K8s ships all ~700 of its API and CRD classes from a single
distribution, so a class that is genuinely dropped orphans its name exactly
the same way a cross-distribution rename would: PAUSE does not know or care
that "the dist is still actively released", it only sees that no shipped
release contains that module name above the version of the last one that
did.

B<Not every internally-deprecated IO::K8s class belongs here.> IO::K8s has
long shipped ~76 C<*List> classes (C<PodList>, C<ServiceList>, etc.) as
soft-deprecated warning stubs that pointed callers at the unified
L<IO::K8s::List> -- see C<perldoc -m IO::K8s> under "UPGRADING FROM
PREVIOUS VERSIONS" for the historical note. As long as those stubs kept
shipping under their own name in every IO-K8s release, PAUSE never orphaned
them and no tombstone was needed. Only once IO-K8s actually stopped
shipping them (dropped the files outright, no longer just warning) did
their names become tombstone candidates -- which is what the entries below
are. Before adding a tombstone for anything else, confirm the class is
truly gone from IO-K8s's current HEAD, not just soft-deprecated in place;
also check whether it was intentionally kept for backward compatibility
under an older API version (IO-K8s's own convention -- e.g. Autoscaling
V1/V2 and Cilium V2alpha1/V2 ship side by side -- some renames that look
tombstone-worthy at first glance turn out to be reverted for exactly this
reason).

This distribution fixes the genuine orphan case with the standard CPAN
redirect-takeover pattern: it ships a small stub package under the OLD
module name, with an explicit C<$VERSION> set strictly higher than the
last CPAN release of C<IO-K8s> that shipped that name. PAUSE then indexes
I<this> distribution as canonical for the old name. The stub does nothing
at runtime except C<die> immediately on load, naming the replacement
module, so C<cpanm Old::Module::Name> (or a cpanfile pinning it) now
installs a clear, actionable message instead of silently reinstalling dead
code.

This dist itself (C<IO::K8s::Deprecated>, this module) has no runtime
behaviour of its own -- it is a documentation landing page and the dzil
main module. Each tombstone module is self-contained and carries no
dependency on IO::K8s core.

=head1 VERSION POLICY

Every file here -- the main module and all tombstones alike -- versions
normally and uniformly with the rest of the distribution
(C<RewriteVersion::Transitional> / C<BumpVersionAfterRelease>, no
C<version_finder> restriction in C<dist.ini>). There is no per-tombstone
hand-frozen C<$VERSION>. The starting version, C<1.105>, was chosen for one
reason: it is safely past every IO-K8s release that shipped one of these
module names -- C<IO-K8s 1.100> for the C<*List> and classic DRA classes,
C<IO-K8s 0.03> (unversioned modules) for the classes of the 2018
releases -- and this distribution's own version only ever increases from
here, so it stays ahead of those targets for good without further
special-casing.

That rests on IO-K8s not shipping these names again -- which is an
assumption about another distribution, not something a version number can
enforce. It has failed once (see L</NO LONGER TOMBSTONED>), so it is
checked: C<t/02-name-guard.t> fails as soon as a package shipped here is
also shipped by the current IO-K8s. A name that comes back in IO-K8s
loses its tombstone here; it does not get a higher version.

If a future tombstone is ever added for a name whose last-shipped version
is higher than whatever version this dist has reached by then, confirm
that before releasing and bump first if needed -- an ordinary
version-ordering check, not a reason to reintroduce per-file version
overrides.

For the step-by-step procedure to add a new tombstone when a future rename
or removal happens -- including how to audit C<IO-K8s> for orphaned module
names -- see the C<io-k8s-deprecated> skill
(C<.claude/skills/io-k8s-deprecated/SKILL.md> in this repo; packaged into
the sharedir at build time).

=head1 CURRENT TOMBSTONES

=head2 Consolidated into the generic IO::K8s::List (74 classes)

IO-K8s replaced every per-resource C<*List> class with a single generic
L<IO::K8s::List> back in its C<1.00> Moose-to-Moo rewrite. Each of the
classes below was never a real class in the C<1.x> series -- it only
emitted a deprecation warning on load. C<IO-K8s> C<1.100> was the last CPAN
release to ship even that warning stub; all 76 such stubs were dropped from
the distribution outright afterwards. 74 of them stayed gone and are
tombstoned here (for the other two see L</NO LONGER TOMBSTONED>). Every one
of them redirects to the same successor:

  IO::K8s::Api::Admissionregistration::V1alpha1::InitializerConfigurationList
  IO::K8s::Api::Admissionregistration::V1beta1::MutatingWebhookConfigurationList
  IO::K8s::Api::Admissionregistration::V1beta1::ValidatingWebhookConfigurationList
  IO::K8s::Api::Apps::V1beta1::ControllerRevisionList
  IO::K8s::Api::Apps::V1beta1::DeploymentList
  IO::K8s::Api::Apps::V1beta1::StatefulSetList
  IO::K8s::Api::Apps::V1beta2::ControllerRevisionList
  IO::K8s::Api::Apps::V1beta2::DaemonSetList
  IO::K8s::Api::Apps::V1beta2::DeploymentList
  IO::K8s::Api::Apps::V1beta2::ReplicaSetList
  IO::K8s::Api::Apps::V1beta2::StatefulSetList
  IO::K8s::Api::Apps::V1::ControllerRevisionList
  IO::K8s::Api::Apps::V1::DaemonSetList
  IO::K8s::Api::Apps::V1::DeploymentList
  IO::K8s::Api::Apps::V1::ReplicaSetList
  IO::K8s::Api::Apps::V1::StatefulSetList
  IO::K8s::Api::Auditregistration::V1alpha1::AuditSinkList
  IO::K8s::Api::Autoscaling::V1::HorizontalPodAutoscalerList
  IO::K8s::Api::Autoscaling::V2beta1::HorizontalPodAutoscalerList
  IO::K8s::Api::Autoscaling::V2beta2::HorizontalPodAutoscalerList
  IO::K8s::Api::Batch::V1beta1::CronJobList
  IO::K8s::Api::Batch::V1::JobList
  IO::K8s::Api::Batch::V2alpha1::CronJobList
  IO::K8s::Api::Certificates::V1beta1::CertificateSigningRequestList
  IO::K8s::Api::Coordination::V1beta1::LeaseList
  IO::K8s::Api::Core::V1::ComponentStatusList
  IO::K8s::Api::Core::V1::ConfigMapList
  IO::K8s::Api::Core::V1::EndpointsList
  IO::K8s::Api::Core::V1::EventList
  IO::K8s::Api::Core::V1::LimitRangeList
  IO::K8s::Api::Core::V1::NamespaceList
  IO::K8s::Api::Core::V1::NodeList
  IO::K8s::Api::Core::V1::PersistentVolumeClaimList
  IO::K8s::Api::Core::V1::PersistentVolumeList
  IO::K8s::Api::Core::V1::PodList
  IO::K8s::Api::Core::V1::PodTemplateList
  IO::K8s::Api::Core::V1::ReplicationControllerList
  IO::K8s::Api::Core::V1::ResourceQuotaList
  IO::K8s::Api::Core::V1::SecretList
  IO::K8s::Api::Core::V1::ServiceAccountList
  IO::K8s::Api::Core::V1::ServiceList
  IO::K8s::Api::Events::V1beta1::EventList
  IO::K8s::ApiExtensionsApiServer::Pkg::Apis::Apiextensions::V1beta1::CustomResourceDefinitionList
  IO::K8s::Api::Extensions::V1beta1::DaemonSetList
  IO::K8s::Api::Extensions::V1beta1::DeploymentList
  IO::K8s::Api::Extensions::V1beta1::IngressList
  IO::K8s::Api::Extensions::V1beta1::NetworkPolicyList
  IO::K8s::Api::Extensions::V1beta1::PodSecurityPolicyList
  IO::K8s::Api::Extensions::V1beta1::ReplicaSetList
  IO::K8s::Api::Networking::V1::NetworkPolicyList
  IO::K8s::Api::Policy::V1beta1::PodDisruptionBudgetList
  IO::K8s::Api::Policy::V1beta1::PodSecurityPolicyList
  IO::K8s::Api::Rbac::V1alpha1::ClusterRoleBindingList
  IO::K8s::Api::Rbac::V1alpha1::ClusterRoleList
  IO::K8s::Api::Rbac::V1alpha1::RoleBindingList
  IO::K8s::Api::Rbac::V1alpha1::RoleList
  IO::K8s::Api::Rbac::V1beta1::ClusterRoleBindingList
  IO::K8s::Api::Rbac::V1beta1::ClusterRoleList
  IO::K8s::Api::Rbac::V1beta1::RoleBindingList
  IO::K8s::Api::Rbac::V1beta1::RoleList
  IO::K8s::Api::Rbac::V1::ClusterRoleBindingList
  IO::K8s::Api::Rbac::V1::ClusterRoleList
  IO::K8s::Api::Rbac::V1::RoleBindingList
  IO::K8s::Api::Rbac::V1::RoleList
  IO::K8s::Api::Scheduling::V1alpha1::PriorityClassList
  IO::K8s::Api::Scheduling::V1beta1::PriorityClassList
  IO::K8s::Api::Settings::V1alpha1::PodPresetList
  IO::K8s::Api::Storage::V1alpha1::VolumeAttachmentList
  IO::K8s::Api::Storage::V1beta1::StorageClassList
  IO::K8s::Api::Storage::V1beta1::VolumeAttachmentList
  IO::K8s::Api::Storage::V1::StorageClassList
  IO::K8s::Api::Storage::V1::VolumeAttachmentList
  IO::K8s::KubeAggregator::Pkg::Apis::Apiregistration::V1::APIServiceList
  IO::K8s::KubeAggregator::Pkg::Apis::Apiregistration::V1beta1::APIServiceList

All 74 redirect to: L<IO::K8s::List>.

=head2 Removed -- classic DRA control-plane-controller allocation (4 classes)

C<resource.k8s.io/v1alpha3> shipped an alpha-only (never GA) "classic DRA"
allocation flow that coordinated C<WaitForFirstConsumer> resource-claim
scheduling between the scheduler and an external controller. When Dynamic
Resource Allocation graduated to GA with an architecturally different
structured-parameters model at C<resource.k8s.io/v1>, that whole mechanism
-- including these four classes -- was dropped. There is no 1:1 successor
for any of them; the current DRA API is
L<IO::K8s::Api::Resource::V1::ResourceClaim> and
L<IO::K8s::Api::Resource::V1::DeviceClass>. Last shipped in C<IO-K8s>
C<1.100>:

  IO::K8s::Api::Resource::V1alpha3::PodSchedulingContext
  IO::K8s::Api::Resource::V1alpha3::PodSchedulingContextSpec
  IO::K8s::Api::Resource::V1alpha3::PodSchedulingContextStatus
  IO::K8s::Api::Resource::V1alpha3::ResourceClaimSchedulingStatus

Unlike the admission/auth/flowcontrol classes noted below, these had no
lingering old-cluster backward-compatibility rationale to keep them around
in IO-K8s: DRA itself was alpha-only when these shipped, never GA, so
there was no "still-supported older cluster" depending on this API the way
there is for a long-GA API's deprecated beta track.

=head2 Retired API versions from IO-K8s 0.03, with a successor (180 classes)

C<IO-K8s> C<0.01> to C<0.03> (May 2018) shipped classes for the alpha and
beta API versions of that time. Kubernetes has retired those API versions
since, and no C<IO-K8s> C<1.x> release ships these classes, so the PAUSE
index kept resolving their names to C<IO-K8s> C<0.03>. Installing that
release would also replace the classes of a current IO-K8s, C<IO::K8s>
itself included, with their 2018 versions. Each tombstone names its
successor in the current IO-K8s -- mostly the same class at the GA
version, or the group it moved to (C<extensions/v1beta1> workloads to
C<apps/v1>, Ingress and NetworkPolicy to C<networking.k8s.io/v1>, Scale to
C<autoscaling/v1>). Kubernetes renamed the core v1 C<Handler> to
C<LifecycleHandler>, and the v1 API has C<MutatingWebhook> and
C<ValidatingWebhook> in place of the v1beta1 C<Webhook>:

  IO::K8s::Api::Admissionregistration::V1beta1::MutatingWebhookConfiguration
    -> IO::K8s::Api::Admissionregistration::V1::MutatingWebhookConfiguration
  IO::K8s::Api::Admissionregistration::V1beta1::RuleWithOperations
    -> IO::K8s::Api::Admissionregistration::V1::RuleWithOperations
  IO::K8s::Api::Admissionregistration::V1beta1::ServiceReference
    -> IO::K8s::Api::Admissionregistration::V1::ServiceReference
  IO::K8s::Api::Admissionregistration::V1beta1::ValidatingWebhookConfiguration
    -> IO::K8s::Api::Admissionregistration::V1::ValidatingWebhookConfiguration
  IO::K8s::Api::Admissionregistration::V1beta1::Webhook
    -> IO::K8s::Api::Admissionregistration::V1::MutatingWebhook, IO::K8s::Api::Admissionregistration::V1::ValidatingWebhook
  IO::K8s::Api::Admissionregistration::V1beta1::WebhookClientConfig
    -> IO::K8s::Api::Admissionregistration::V1::WebhookClientConfig
  IO::K8s::Api::Apps::V1beta1::ControllerRevision
    -> IO::K8s::Api::Apps::V1::ControllerRevision
  IO::K8s::Api::Apps::V1beta1::Deployment
    -> IO::K8s::Api::Apps::V1::Deployment
  IO::K8s::Api::Apps::V1beta1::DeploymentCondition
    -> IO::K8s::Api::Apps::V1::DeploymentCondition
  IO::K8s::Api::Apps::V1beta1::DeploymentSpec
    -> IO::K8s::Api::Apps::V1::DeploymentSpec
  IO::K8s::Api::Apps::V1beta1::DeploymentStatus
    -> IO::K8s::Api::Apps::V1::DeploymentStatus
  IO::K8s::Api::Apps::V1beta1::DeploymentStrategy
    -> IO::K8s::Api::Apps::V1::DeploymentStrategy
  IO::K8s::Api::Apps::V1beta1::RollingUpdateDeployment
    -> IO::K8s::Api::Apps::V1::RollingUpdateDeployment
  IO::K8s::Api::Apps::V1beta1::RollingUpdateStatefulSetStrategy
    -> IO::K8s::Api::Apps::V1::RollingUpdateStatefulSetStrategy
  IO::K8s::Api::Apps::V1beta1::Scale
    -> IO::K8s::Api::Autoscaling::V1::Scale
  IO::K8s::Api::Apps::V1beta1::ScaleSpec
    -> IO::K8s::Api::Autoscaling::V1::ScaleSpec
  IO::K8s::Api::Apps::V1beta1::ScaleStatus
    -> IO::K8s::Api::Autoscaling::V1::ScaleStatus
  IO::K8s::Api::Apps::V1beta1::StatefulSet
    -> IO::K8s::Api::Apps::V1::StatefulSet
  IO::K8s::Api::Apps::V1beta1::StatefulSetCondition
    -> IO::K8s::Api::Apps::V1::StatefulSetCondition
  IO::K8s::Api::Apps::V1beta1::StatefulSetSpec
    -> IO::K8s::Api::Apps::V1::StatefulSetSpec
  IO::K8s::Api::Apps::V1beta1::StatefulSetStatus
    -> IO::K8s::Api::Apps::V1::StatefulSetStatus
  IO::K8s::Api::Apps::V1beta1::StatefulSetUpdateStrategy
    -> IO::K8s::Api::Apps::V1::StatefulSetUpdateStrategy
  IO::K8s::Api::Apps::V1beta2::ControllerRevision
    -> IO::K8s::Api::Apps::V1::ControllerRevision
  IO::K8s::Api::Apps::V1beta2::DaemonSet
    -> IO::K8s::Api::Apps::V1::DaemonSet
  IO::K8s::Api::Apps::V1beta2::DaemonSetCondition
    -> IO::K8s::Api::Apps::V1::DaemonSetCondition
  IO::K8s::Api::Apps::V1beta2::DaemonSetSpec
    -> IO::K8s::Api::Apps::V1::DaemonSetSpec
  IO::K8s::Api::Apps::V1beta2::DaemonSetStatus
    -> IO::K8s::Api::Apps::V1::DaemonSetStatus
  IO::K8s::Api::Apps::V1beta2::DaemonSetUpdateStrategy
    -> IO::K8s::Api::Apps::V1::DaemonSetUpdateStrategy
  IO::K8s::Api::Apps::V1beta2::Deployment
    -> IO::K8s::Api::Apps::V1::Deployment
  IO::K8s::Api::Apps::V1beta2::DeploymentCondition
    -> IO::K8s::Api::Apps::V1::DeploymentCondition
  IO::K8s::Api::Apps::V1beta2::DeploymentSpec
    -> IO::K8s::Api::Apps::V1::DeploymentSpec
  IO::K8s::Api::Apps::V1beta2::DeploymentStatus
    -> IO::K8s::Api::Apps::V1::DeploymentStatus
  IO::K8s::Api::Apps::V1beta2::DeploymentStrategy
    -> IO::K8s::Api::Apps::V1::DeploymentStrategy
  IO::K8s::Api::Apps::V1beta2::ReplicaSet
    -> IO::K8s::Api::Apps::V1::ReplicaSet
  IO::K8s::Api::Apps::V1beta2::ReplicaSetCondition
    -> IO::K8s::Api::Apps::V1::ReplicaSetCondition
  IO::K8s::Api::Apps::V1beta2::ReplicaSetSpec
    -> IO::K8s::Api::Apps::V1::ReplicaSetSpec
  IO::K8s::Api::Apps::V1beta2::ReplicaSetStatus
    -> IO::K8s::Api::Apps::V1::ReplicaSetStatus
  IO::K8s::Api::Apps::V1beta2::RollingUpdateDaemonSet
    -> IO::K8s::Api::Apps::V1::RollingUpdateDaemonSet
  IO::K8s::Api::Apps::V1beta2::RollingUpdateDeployment
    -> IO::K8s::Api::Apps::V1::RollingUpdateDeployment
  IO::K8s::Api::Apps::V1beta2::RollingUpdateStatefulSetStrategy
    -> IO::K8s::Api::Apps::V1::RollingUpdateStatefulSetStrategy
  IO::K8s::Api::Apps::V1beta2::Scale
    -> IO::K8s::Api::Autoscaling::V1::Scale
  IO::K8s::Api::Apps::V1beta2::ScaleSpec
    -> IO::K8s::Api::Autoscaling::V1::ScaleSpec
  IO::K8s::Api::Apps::V1beta2::ScaleStatus
    -> IO::K8s::Api::Autoscaling::V1::ScaleStatus
  IO::K8s::Api::Apps::V1beta2::StatefulSet
    -> IO::K8s::Api::Apps::V1::StatefulSet
  IO::K8s::Api::Apps::V1beta2::StatefulSetCondition
    -> IO::K8s::Api::Apps::V1::StatefulSetCondition
  IO::K8s::Api::Apps::V1beta2::StatefulSetSpec
    -> IO::K8s::Api::Apps::V1::StatefulSetSpec
  IO::K8s::Api::Apps::V1beta2::StatefulSetStatus
    -> IO::K8s::Api::Apps::V1::StatefulSetStatus
  IO::K8s::Api::Apps::V1beta2::StatefulSetUpdateStrategy
    -> IO::K8s::Api::Apps::V1::StatefulSetUpdateStrategy
  IO::K8s::Api::Authentication::V1beta1::TokenReview
    -> IO::K8s::Api::Authentication::V1::TokenReview
  IO::K8s::Api::Authentication::V1beta1::TokenReviewSpec
    -> IO::K8s::Api::Authentication::V1::TokenReviewSpec
  IO::K8s::Api::Authentication::V1beta1::TokenReviewStatus
    -> IO::K8s::Api::Authentication::V1::TokenReviewStatus
  IO::K8s::Api::Authentication::V1beta1::UserInfo
    -> IO::K8s::Api::Authentication::V1::UserInfo
  IO::K8s::Api::Authorization::V1beta1::LocalSubjectAccessReview
    -> IO::K8s::Api::Authorization::V1::LocalSubjectAccessReview
  IO::K8s::Api::Authorization::V1beta1::NonResourceAttributes
    -> IO::K8s::Api::Authorization::V1::NonResourceAttributes
  IO::K8s::Api::Authorization::V1beta1::NonResourceRule
    -> IO::K8s::Api::Authorization::V1::NonResourceRule
  IO::K8s::Api::Authorization::V1beta1::ResourceAttributes
    -> IO::K8s::Api::Authorization::V1::ResourceAttributes
  IO::K8s::Api::Authorization::V1beta1::ResourceRule
    -> IO::K8s::Api::Authorization::V1::ResourceRule
  IO::K8s::Api::Authorization::V1beta1::SelfSubjectAccessReview
    -> IO::K8s::Api::Authorization::V1::SelfSubjectAccessReview
  IO::K8s::Api::Authorization::V1beta1::SelfSubjectAccessReviewSpec
    -> IO::K8s::Api::Authorization::V1::SelfSubjectAccessReviewSpec
  IO::K8s::Api::Authorization::V1beta1::SelfSubjectRulesReview
    -> IO::K8s::Api::Authorization::V1::SelfSubjectRulesReview
  IO::K8s::Api::Authorization::V1beta1::SelfSubjectRulesReviewSpec
    -> IO::K8s::Api::Authorization::V1::SelfSubjectRulesReviewSpec
  IO::K8s::Api::Authorization::V1beta1::SubjectAccessReview
    -> IO::K8s::Api::Authorization::V1::SubjectAccessReview
  IO::K8s::Api::Authorization::V1beta1::SubjectAccessReviewSpec
    -> IO::K8s::Api::Authorization::V1::SubjectAccessReviewSpec
  IO::K8s::Api::Authorization::V1beta1::SubjectAccessReviewStatus
    -> IO::K8s::Api::Authorization::V1::SubjectAccessReviewStatus
  IO::K8s::Api::Authorization::V1beta1::SubjectRulesReviewStatus
    -> IO::K8s::Api::Authorization::V1::SubjectRulesReviewStatus
  IO::K8s::Api::Autoscaling::V2beta1::CrossVersionObjectReference
    -> IO::K8s::Api::Autoscaling::V2::CrossVersionObjectReference
  IO::K8s::Api::Autoscaling::V2beta1::ExternalMetricSource
    -> IO::K8s::Api::Autoscaling::V2::ExternalMetricSource
  IO::K8s::Api::Autoscaling::V2beta1::ExternalMetricStatus
    -> IO::K8s::Api::Autoscaling::V2::ExternalMetricStatus
  IO::K8s::Api::Autoscaling::V2beta1::HorizontalPodAutoscaler
    -> IO::K8s::Api::Autoscaling::V2::HorizontalPodAutoscaler
  IO::K8s::Api::Autoscaling::V2beta1::HorizontalPodAutoscalerCondition
    -> IO::K8s::Api::Autoscaling::V2::HorizontalPodAutoscalerCondition
  IO::K8s::Api::Autoscaling::V2beta1::HorizontalPodAutoscalerSpec
    -> IO::K8s::Api::Autoscaling::V2::HorizontalPodAutoscalerSpec
  IO::K8s::Api::Autoscaling::V2beta1::HorizontalPodAutoscalerStatus
    -> IO::K8s::Api::Autoscaling::V2::HorizontalPodAutoscalerStatus
  IO::K8s::Api::Autoscaling::V2beta1::MetricSpec
    -> IO::K8s::Api::Autoscaling::V2::MetricSpec
  IO::K8s::Api::Autoscaling::V2beta1::MetricStatus
    -> IO::K8s::Api::Autoscaling::V2::MetricStatus
  IO::K8s::Api::Autoscaling::V2beta1::ObjectMetricSource
    -> IO::K8s::Api::Autoscaling::V2::ObjectMetricSource
  IO::K8s::Api::Autoscaling::V2beta1::ObjectMetricStatus
    -> IO::K8s::Api::Autoscaling::V2::ObjectMetricStatus
  IO::K8s::Api::Autoscaling::V2beta1::PodsMetricSource
    -> IO::K8s::Api::Autoscaling::V2::PodsMetricSource
  IO::K8s::Api::Autoscaling::V2beta1::PodsMetricStatus
    -> IO::K8s::Api::Autoscaling::V2::PodsMetricStatus
  IO::K8s::Api::Autoscaling::V2beta1::ResourceMetricSource
    -> IO::K8s::Api::Autoscaling::V2::ResourceMetricSource
  IO::K8s::Api::Autoscaling::V2beta1::ResourceMetricStatus
    -> IO::K8s::Api::Autoscaling::V2::ResourceMetricStatus
  IO::K8s::Api::Batch::V1beta1::CronJob
    -> IO::K8s::Api::Batch::V1::CronJob
  IO::K8s::Api::Batch::V1beta1::CronJobSpec
    -> IO::K8s::Api::Batch::V1::CronJobSpec
  IO::K8s::Api::Batch::V1beta1::CronJobStatus
    -> IO::K8s::Api::Batch::V1::CronJobStatus
  IO::K8s::Api::Batch::V1beta1::JobTemplateSpec
    -> IO::K8s::Api::Batch::V1::JobTemplateSpec
  IO::K8s::Api::Batch::V2alpha1::CronJob
    -> IO::K8s::Api::Batch::V1::CronJob
  IO::K8s::Api::Batch::V2alpha1::CronJobSpec
    -> IO::K8s::Api::Batch::V1::CronJobSpec
  IO::K8s::Api::Batch::V2alpha1::CronJobStatus
    -> IO::K8s::Api::Batch::V1::CronJobStatus
  IO::K8s::Api::Batch::V2alpha1::JobTemplateSpec
    -> IO::K8s::Api::Batch::V1::JobTemplateSpec
  IO::K8s::Api::Certificates::V1beta1::CertificateSigningRequest
    -> IO::K8s::Api::Certificates::V1::CertificateSigningRequest
  IO::K8s::Api::Certificates::V1beta1::CertificateSigningRequestCondition
    -> IO::K8s::Api::Certificates::V1::CertificateSigningRequestCondition
  IO::K8s::Api::Certificates::V1beta1::CertificateSigningRequestSpec
    -> IO::K8s::Api::Certificates::V1::CertificateSigningRequestSpec
  IO::K8s::Api::Certificates::V1beta1::CertificateSigningRequestStatus
    -> IO::K8s::Api::Certificates::V1::CertificateSigningRequestStatus
  IO::K8s::Api::Core::V1::Handler
    -> IO::K8s::Api::Core::V1::LifecycleHandler
  IO::K8s::Api::Events::V1beta1::Event
    -> IO::K8s::Api::Events::V1::Event
  IO::K8s::Api::Events::V1beta1::EventSeries
    -> IO::K8s::Api::Events::V1::EventSeries
  IO::K8s::Api::Extensions::V1beta1::DaemonSet
    -> IO::K8s::Api::Apps::V1::DaemonSet
  IO::K8s::Api::Extensions::V1beta1::DaemonSetCondition
    -> IO::K8s::Api::Apps::V1::DaemonSetCondition
  IO::K8s::Api::Extensions::V1beta1::DaemonSetSpec
    -> IO::K8s::Api::Apps::V1::DaemonSetSpec
  IO::K8s::Api::Extensions::V1beta1::DaemonSetStatus
    -> IO::K8s::Api::Apps::V1::DaemonSetStatus
  IO::K8s::Api::Extensions::V1beta1::DaemonSetUpdateStrategy
    -> IO::K8s::Api::Apps::V1::DaemonSetUpdateStrategy
  IO::K8s::Api::Extensions::V1beta1::Deployment
    -> IO::K8s::Api::Apps::V1::Deployment
  IO::K8s::Api::Extensions::V1beta1::DeploymentCondition
    -> IO::K8s::Api::Apps::V1::DeploymentCondition
  IO::K8s::Api::Extensions::V1beta1::DeploymentSpec
    -> IO::K8s::Api::Apps::V1::DeploymentSpec
  IO::K8s::Api::Extensions::V1beta1::DeploymentStatus
    -> IO::K8s::Api::Apps::V1::DeploymentStatus
  IO::K8s::Api::Extensions::V1beta1::DeploymentStrategy
    -> IO::K8s::Api::Apps::V1::DeploymentStrategy
  IO::K8s::Api::Extensions::V1beta1::HTTPIngressPath
    -> IO::K8s::Api::Networking::V1::HTTPIngressPath
  IO::K8s::Api::Extensions::V1beta1::HTTPIngressRuleValue
    -> IO::K8s::Api::Networking::V1::HTTPIngressRuleValue
  IO::K8s::Api::Extensions::V1beta1::IPBlock
    -> IO::K8s::Api::Networking::V1::IPBlock
  IO::K8s::Api::Extensions::V1beta1::Ingress
    -> IO::K8s::Api::Networking::V1::Ingress
  IO::K8s::Api::Extensions::V1beta1::IngressBackend
    -> IO::K8s::Api::Networking::V1::IngressBackend
  IO::K8s::Api::Extensions::V1beta1::IngressRule
    -> IO::K8s::Api::Networking::V1::IngressRule
  IO::K8s::Api::Extensions::V1beta1::IngressSpec
    -> IO::K8s::Api::Networking::V1::IngressSpec
  IO::K8s::Api::Extensions::V1beta1::IngressStatus
    -> IO::K8s::Api::Networking::V1::IngressStatus
  IO::K8s::Api::Extensions::V1beta1::IngressTLS
    -> IO::K8s::Api::Networking::V1::IngressTLS
  IO::K8s::Api::Extensions::V1beta1::NetworkPolicy
    -> IO::K8s::Api::Networking::V1::NetworkPolicy
  IO::K8s::Api::Extensions::V1beta1::NetworkPolicyEgressRule
    -> IO::K8s::Api::Networking::V1::NetworkPolicyEgressRule
  IO::K8s::Api::Extensions::V1beta1::NetworkPolicyIngressRule
    -> IO::K8s::Api::Networking::V1::NetworkPolicyIngressRule
  IO::K8s::Api::Extensions::V1beta1::NetworkPolicyPeer
    -> IO::K8s::Api::Networking::V1::NetworkPolicyPeer
  IO::K8s::Api::Extensions::V1beta1::NetworkPolicyPort
    -> IO::K8s::Api::Networking::V1::NetworkPolicyPort
  IO::K8s::Api::Extensions::V1beta1::NetworkPolicySpec
    -> IO::K8s::Api::Networking::V1::NetworkPolicySpec
  IO::K8s::Api::Extensions::V1beta1::ReplicaSet
    -> IO::K8s::Api::Apps::V1::ReplicaSet
  IO::K8s::Api::Extensions::V1beta1::ReplicaSetCondition
    -> IO::K8s::Api::Apps::V1::ReplicaSetCondition
  IO::K8s::Api::Extensions::V1beta1::ReplicaSetSpec
    -> IO::K8s::Api::Apps::V1::ReplicaSetSpec
  IO::K8s::Api::Extensions::V1beta1::ReplicaSetStatus
    -> IO::K8s::Api::Apps::V1::ReplicaSetStatus
  IO::K8s::Api::Extensions::V1beta1::RollingUpdateDaemonSet
    -> IO::K8s::Api::Apps::V1::RollingUpdateDaemonSet
  IO::K8s::Api::Extensions::V1beta1::RollingUpdateDeployment
    -> IO::K8s::Api::Apps::V1::RollingUpdateDeployment
  IO::K8s::Api::Extensions::V1beta1::Scale
    -> IO::K8s::Api::Autoscaling::V1::Scale
  IO::K8s::Api::Extensions::V1beta1::ScaleSpec
    -> IO::K8s::Api::Autoscaling::V1::ScaleSpec
  IO::K8s::Api::Extensions::V1beta1::ScaleStatus
    -> IO::K8s::Api::Autoscaling::V1::ScaleStatus
  IO::K8s::Api::Policy::V1beta1::Eviction
    -> IO::K8s::Api::Policy::V1::Eviction
  IO::K8s::Api::Policy::V1beta1::PodDisruptionBudget
    -> IO::K8s::Api::Policy::V1::PodDisruptionBudget
  IO::K8s::Api::Policy::V1beta1::PodDisruptionBudgetSpec
    -> IO::K8s::Api::Policy::V1::PodDisruptionBudgetSpec
  IO::K8s::Api::Policy::V1beta1::PodDisruptionBudgetStatus
    -> IO::K8s::Api::Policy::V1::PodDisruptionBudgetStatus
  IO::K8s::Api::Rbac::V1alpha1::AggregationRule
    -> IO::K8s::Api::Rbac::V1::AggregationRule
  IO::K8s::Api::Rbac::V1alpha1::ClusterRole
    -> IO::K8s::Api::Rbac::V1::ClusterRole
  IO::K8s::Api::Rbac::V1alpha1::ClusterRoleBinding
    -> IO::K8s::Api::Rbac::V1::ClusterRoleBinding
  IO::K8s::Api::Rbac::V1alpha1::PolicyRule
    -> IO::K8s::Api::Rbac::V1::PolicyRule
  IO::K8s::Api::Rbac::V1alpha1::Role
    -> IO::K8s::Api::Rbac::V1::Role
  IO::K8s::Api::Rbac::V1alpha1::RoleBinding
    -> IO::K8s::Api::Rbac::V1::RoleBinding
  IO::K8s::Api::Rbac::V1alpha1::RoleRef
    -> IO::K8s::Api::Rbac::V1::RoleRef
  IO::K8s::Api::Rbac::V1alpha1::Subject
    -> IO::K8s::Api::Rbac::V1::Subject
  IO::K8s::Api::Rbac::V1beta1::AggregationRule
    -> IO::K8s::Api::Rbac::V1::AggregationRule
  IO::K8s::Api::Rbac::V1beta1::ClusterRole
    -> IO::K8s::Api::Rbac::V1::ClusterRole
  IO::K8s::Api::Rbac::V1beta1::ClusterRoleBinding
    -> IO::K8s::Api::Rbac::V1::ClusterRoleBinding
  IO::K8s::Api::Rbac::V1beta1::PolicyRule
    -> IO::K8s::Api::Rbac::V1::PolicyRule
  IO::K8s::Api::Rbac::V1beta1::Role
    -> IO::K8s::Api::Rbac::V1::Role
  IO::K8s::Api::Rbac::V1beta1::RoleBinding
    -> IO::K8s::Api::Rbac::V1::RoleBinding
  IO::K8s::Api::Rbac::V1beta1::RoleRef
    -> IO::K8s::Api::Rbac::V1::RoleRef
  IO::K8s::Api::Rbac::V1beta1::Subject
    -> IO::K8s::Api::Rbac::V1::Subject
  IO::K8s::Api::Scheduling::V1alpha1::PriorityClass
    -> IO::K8s::Api::Scheduling::V1::PriorityClass
  IO::K8s::Api::Storage::V1alpha1::VolumeAttachment
    -> IO::K8s::Api::Storage::V1::VolumeAttachment
  IO::K8s::Api::Storage::V1alpha1::VolumeAttachmentSource
    -> IO::K8s::Api::Storage::V1::VolumeAttachmentSource
  IO::K8s::Api::Storage::V1alpha1::VolumeAttachmentSpec
    -> IO::K8s::Api::Storage::V1::VolumeAttachmentSpec
  IO::K8s::Api::Storage::V1alpha1::VolumeAttachmentStatus
    -> IO::K8s::Api::Storage::V1::VolumeAttachmentStatus
  IO::K8s::Api::Storage::V1alpha1::VolumeError
    -> IO::K8s::Api::Storage::V1::VolumeError
  IO::K8s::Api::Storage::V1beta1::StorageClass
    -> IO::K8s::Api::Storage::V1::StorageClass
  IO::K8s::Api::Storage::V1beta1::VolumeAttachment
    -> IO::K8s::Api::Storage::V1::VolumeAttachment
  IO::K8s::Api::Storage::V1beta1::VolumeAttachmentSource
    -> IO::K8s::Api::Storage::V1::VolumeAttachmentSource
  IO::K8s::Api::Storage::V1beta1::VolumeAttachmentSpec
    -> IO::K8s::Api::Storage::V1::VolumeAttachmentSpec
  IO::K8s::Api::Storage::V1beta1::VolumeAttachmentStatus
    -> IO::K8s::Api::Storage::V1::VolumeAttachmentStatus
  IO::K8s::Api::Storage::V1beta1::VolumeError
    -> IO::K8s::Api::Storage::V1::VolumeError
  IO::K8s::ApiExtensionsApiServer::Pkg::Apis::Apiextensions::V1beta1::CustomResourceDefinition
    -> IO::K8s::ApiextensionsApiserver::Pkg::Apis::Apiextensions::V1::CustomResourceDefinition
  IO::K8s::ApiExtensionsApiServer::Pkg::Apis::Apiextensions::V1beta1::CustomResourceDefinitionCondition
    -> IO::K8s::ApiextensionsApiserver::Pkg::Apis::Apiextensions::V1::CustomResourceDefinitionCondition
  IO::K8s::ApiExtensionsApiServer::Pkg::Apis::Apiextensions::V1beta1::CustomResourceDefinitionNames
    -> IO::K8s::ApiextensionsApiserver::Pkg::Apis::Apiextensions::V1::CustomResourceDefinitionNames
  IO::K8s::ApiExtensionsApiServer::Pkg::Apis::Apiextensions::V1beta1::CustomResourceDefinitionSpec
    -> IO::K8s::ApiextensionsApiserver::Pkg::Apis::Apiextensions::V1::CustomResourceDefinitionSpec
  IO::K8s::ApiExtensionsApiServer::Pkg::Apis::Apiextensions::V1beta1::CustomResourceDefinitionStatus
    -> IO::K8s::ApiextensionsApiserver::Pkg::Apis::Apiextensions::V1::CustomResourceDefinitionStatus
  IO::K8s::ApiExtensionsApiServer::Pkg::Apis::Apiextensions::V1beta1::CustomResourceSubresourceScale
    -> IO::K8s::ApiextensionsApiserver::Pkg::Apis::Apiextensions::V1::CustomResourceSubresourceScale
  IO::K8s::ApiExtensionsApiServer::Pkg::Apis::Apiextensions::V1beta1::CustomResourceSubresources
    -> IO::K8s::ApiextensionsApiserver::Pkg::Apis::Apiextensions::V1::CustomResourceSubresources
  IO::K8s::ApiExtensionsApiServer::Pkg::Apis::Apiextensions::V1beta1::CustomResourceValidation
    -> IO::K8s::ApiextensionsApiserver::Pkg::Apis::Apiextensions::V1::CustomResourceValidation
  IO::K8s::ApiExtensionsApiServer::Pkg::Apis::Apiextensions::V1beta1::ExternalDocumentation
    -> IO::K8s::ApiextensionsApiserver::Pkg::Apis::Apiextensions::V1::ExternalDocumentation
  IO::K8s::ApiExtensionsApiServer::Pkg::Apis::Apiextensions::V1beta1::JSON
    -> IO::K8s::ApiextensionsApiserver::Pkg::Apis::Apiextensions::V1::JSON
  IO::K8s::ApiExtensionsApiServer::Pkg::Apis::Apiextensions::V1beta1::JSONSchemaProps
    -> IO::K8s::ApiextensionsApiserver::Pkg::Apis::Apiextensions::V1::JSONSchemaProps
  IO::K8s::ApiExtensionsApiServer::Pkg::Apis::Apiextensions::V1beta1::JSONSchemaPropsOrArray
    -> IO::K8s::ApiextensionsApiserver::Pkg::Apis::Apiextensions::V1::JSONSchemaPropsOrArray
  IO::K8s::ApiExtensionsApiServer::Pkg::Apis::Apiextensions::V1beta1::JSONSchemaPropsOrBool
    -> IO::K8s::ApiextensionsApiserver::Pkg::Apis::Apiextensions::V1::JSONSchemaPropsOrBool
  IO::K8s::ApiExtensionsApiServer::Pkg::Apis::Apiextensions::V1beta1::JSONSchemaPropsOrStringArray
    -> IO::K8s::ApiextensionsApiserver::Pkg::Apis::Apiextensions::V1::JSONSchemaPropsOrStringArray
  IO::K8s::KubeAggregator::Pkg::Apis::Apiregistration::V1beta1::APIService
    -> IO::K8s::KubeAggregator::Pkg::Apis::Apiregistration::V1::APIService
  IO::K8s::KubeAggregator::Pkg::Apis::Apiregistration::V1beta1::APIServiceCondition
    -> IO::K8s::KubeAggregator::Pkg::Apis::Apiregistration::V1::APIServiceCondition
  IO::K8s::KubeAggregator::Pkg::Apis::Apiregistration::V1beta1::APIServiceSpec
    -> IO::K8s::KubeAggregator::Pkg::Apis::Apiregistration::V1::APIServiceSpec
  IO::K8s::KubeAggregator::Pkg::Apis::Apiregistration::V1beta1::APIServiceStatus
    -> IO::K8s::KubeAggregator::Pkg::Apis::Apiregistration::V1::APIServiceStatus
  IO::K8s::KubeAggregator::Pkg::Apis::Apiregistration::V1beta1::ServiceReference
    -> IO::K8s::KubeAggregator::Pkg::Apis::Apiregistration::V1::ServiceReference

=head2 Dropped by Kubernetes, from IO-K8s 0.03 (32 classes)

Also shipped only by C<IO-K8s> C<0.01> to C<0.03>, and also resolved to
C<IO-K8s> C<0.03> by the PAUSE index -- but Kubernetes dropped these types
without a successor class, so each tombstone says why.

PodSecurityPolicy, removed in Kubernetes v1.25; Pod Security Admission
took its place and is set through namespace labels:

  IO::K8s::Api::Extensions::V1beta1::AllowedFlexVolume
  IO::K8s::Api::Extensions::V1beta1::AllowedHostPath
  IO::K8s::Api::Extensions::V1beta1::FSGroupStrategyOptions
  IO::K8s::Api::Extensions::V1beta1::HostPortRange
  IO::K8s::Api::Extensions::V1beta1::IDRange
  IO::K8s::Api::Extensions::V1beta1::PodSecurityPolicy
  IO::K8s::Api::Extensions::V1beta1::PodSecurityPolicySpec
  IO::K8s::Api::Extensions::V1beta1::RunAsUserStrategyOptions
  IO::K8s::Api::Extensions::V1beta1::SELinuxStrategyOptions
  IO::K8s::Api::Extensions::V1beta1::SupplementalGroupsStrategyOptions
  IO::K8s::Api::Policy::V1beta1::AllowedFlexVolume
  IO::K8s::Api::Policy::V1beta1::AllowedHostPath
  IO::K8s::Api::Policy::V1beta1::FSGroupStrategyOptions
  IO::K8s::Api::Policy::V1beta1::HostPortRange
  IO::K8s::Api::Policy::V1beta1::IDRange
  IO::K8s::Api::Policy::V1beta1::PodSecurityPolicy
  IO::K8s::Api::Policy::V1beta1::PodSecurityPolicySpec
  IO::K8s::Api::Policy::V1beta1::RunAsUserStrategyOptions
  IO::K8s::Api::Policy::V1beta1::SELinuxStrategyOptions
  IO::K8s::Api::Policy::V1beta1::SupplementalGroupsStrategyOptions

The alpha Initializers feature, removed in Kubernetes v1.14; mutating
admission webhooks (L<IO::K8s::Api::Admissionregistration::V1::MutatingWebhookConfiguration>)
took its place:

  IO::K8s::Api::Admissionregistration::V1alpha1::Initializer
  IO::K8s::Api::Admissionregistration::V1alpha1::InitializerConfiguration
  IO::K8s::Api::Admissionregistration::V1alpha1::Rule
  IO::K8s::Apimachinery::Pkg::Apis::Meta::V1::Initializer
  IO::K8s::Apimachinery::Pkg::Apis::Meta::V1::Initializers

The Deployment rollback of C<apps/v1beta1> and C<extensions/v1beta1>;
C<apps/v1> has no rollback subresource, a Deployment is rolled back by
setting its pod template to an earlier revision:

  IO::K8s::Api::Apps::V1beta1::DeploymentRollback
  IO::K8s::Api::Apps::V1beta1::RollbackConfig
  IO::K8s::Api::Extensions::V1beta1::DeploymentRollback
  IO::K8s::Api::Extensions::V1beta1::RollbackConfig

The alpha PodPreset API, removed in Kubernetes v1.20:

  IO::K8s::Api::Settings::V1alpha1::PodPreset
  IO::K8s::Api::Settings::V1alpha1::PodPresetSpec

RawExtension, which IO-K8s C<1.x> declares as an C<Opaque> field instead
of a class:

  IO::K8s::Apimachinery::Pkg::Runtime::RawExtension

=head1 NO LONGER TOMBSTONED

Release C<1.105> of this distribution shipped tombstones for two more names,
swept up with the C<*List> classes above because IO-K8s had carried them as
the same kind of warning stub up to C<1.100>:

  IO::K8s::Apimachinery::Pkg::Apis::Meta::V1::APIGroupList
  IO::K8s::Apimachinery::Pkg::Apis::Meta::V1::APIResourceList

They are not lists of resources, though, but the C<meta.v1> Kinds the API
server answers discovery requests with -- they carry C<groups> and
C<resources>, not C<items>, so L<IO::K8s::List> was never a replacement for
them. C<IO-K8s> C<1.106> ships both again as real classes. A name IO-K8s
ships is not an orphan, and a tombstone for it does harm: both
distributions install the same file, so whichever is installed last wins,
and installing this distribution after IO-K8s replaced the working classes
with stubs that die on load. Both tombstones were therefore removed.

If C<IO-K8s-Deprecated> C<1.105> was installed on top of C<IO-K8s> C<1.106>
or later, upgrading this distribution does not bring the two classes back
-- an installer does not delete files a newer release no longer ships.
Reinstall IO-K8s (C<cpanm --reinstall IO::K8s>) to restore them.

The rule this left behind -- no package shipped here may be shipped by the
current IO-K8s -- is held by C<t/02-name-guard.t>.

=head1 CONSIDERED BUT NOT TOMBSTONED

The Cilium v1.19.2 upgrade in C<IO-K8s> C<1.100> initially dropped 8
C<cilium.io/v2alpha1> classes (promoting 6 to C<cilium.io/v2>, removing 2
outright). Those classes were restored in C<IO-K8s> for backward
compatibility instead -- they now ship alongside their current-API-version
siblings, matching this dist's own convention of keeping multiple API
versions of a resource side by side. No tombstone was needed after the
restore; see C<io-k8s-p5>'s C<Changes> for the restoring release. Recorded
here so a future audit doesn't rediscover and re-tombstone the same names.

A v1.31 -> v1.36 upstream sync of C<IO-K8s> also flagged (and then kept,
not removed) the older served-but-superseded API tracks
C<admissionregistration.k8s.io/{v1alpha1,v1beta1}> C<ValidatingAdmissionPolicy>,
C<authentication.k8s.io/{v1alpha1,v1beta1}> C<SelfSubjectReview>, and
C<flowcontrol.apiserver.k8s.io/v1beta3> -- all long-GA APIs whose older
alpha/beta tracks may still be needed by callers targeting an older
cluster, the same backward-compatibility rationale as the Cilium restore
above. No tombstone needed for these either.

=head1 SEE ALSO

L<IO::K8s::List>, L<IO::K8s::Api::Resource::V1::ResourceClaim>, L<IO::K8s>

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests at
L<https://github.com/Getty/io-k8s-p5-deprecated/issues>.

=head2 IRC

Join C<#kubernetes> on C<irc.perl.org> or message Getty directly.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHORS

=over 4

=item *

Torsten Raudssus <torsten@raudssus.de>

=item *

Jose Luis Martinez Torres <jlmartin@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018-2026 by Jose Luis Martinez Torres <jlmartin@cpan.org>.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

L<https://raudssus.de/>

=cut
