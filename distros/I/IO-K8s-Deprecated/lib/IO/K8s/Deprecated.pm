package IO::K8s::Deprecated;
our $VERSION = '1.105';
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

version 1.105

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
under an older API version (IO-K8s's own convention -- e.g. Apps
V1beta1/V1beta2/V1 all still ship side by side -- some renames that look
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
reason: it is safely past C<IO-K8s 1.100>, the last CPAN release that
shipped any of these module names. IO-K8s will never ship these names
again (they are permanently removed, not merely between releases), and
this distribution's own version only ever increases from here, so
C<1.105> stays ahead of that target for good without further
special-casing.

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

=head2 Consolidated into the generic IO::K8s::List (76 classes)

IO-K8s replaced every per-resource C<*List> class with a single generic
L<IO::K8s::List> back in its C<1.00> Moose-to-Moo rewrite. Each of the
classes below was never a real class in the C<1.x> series -- it only
emitted a deprecation warning on load. C<IO-K8s> C<1.100> was the last CPAN
release to ship even that warning stub; all 76 were dropped from the
distribution outright afterwards. Every one of them redirects to the same
successor:

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
  IO::K8s::Apimachinery::Pkg::Apis::Meta::V1::APIGroupList
  IO::K8s::Apimachinery::Pkg::Apis::Meta::V1::APIResourceList
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

All 76 redirect to: L<IO::K8s::List>.

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

Please report bugs and feature requests on GitHub at
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

=cut
