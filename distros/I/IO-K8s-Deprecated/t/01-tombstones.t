use strict;
use warnings;
use Test::More;

# Each tombstone must die unconditionally on load. This is the whole
# contract of a redirect stub -- if it stops dying, the takeover is
# silently useless.
#
# All 76 of these are the "consolidated" shape: IO-K8s replaced every
# per-resource *List class with a single generic IO::K8s::List back in its
# 1.00 Moose-to-Moo rewrite. Each one only ever emitted a deprecation
# warning after that (never a real class in the 1.x series) and has now
# been dropped outright, so every entry here shares one successor and one
# expected message pattern -- generated from a flat list rather than a
# renamed/removed-typed hash like the (currently empty) two-shapes model in
# the skill, since there is exactly one shape in play.
my @old_list_classes = (
  'IO::K8s::Api::Admissionregistration::V1alpha1::InitializerConfigurationList',
  'IO::K8s::Api::Admissionregistration::V1beta1::MutatingWebhookConfigurationList',
  'IO::K8s::Api::Admissionregistration::V1beta1::ValidatingWebhookConfigurationList',
  'IO::K8s::Api::Apps::V1::ControllerRevisionList',
  'IO::K8s::Api::Apps::V1::DaemonSetList',
  'IO::K8s::Api::Apps::V1::DeploymentList',
  'IO::K8s::Api::Apps::V1::ReplicaSetList',
  'IO::K8s::Api::Apps::V1::StatefulSetList',
  'IO::K8s::Api::Apps::V1beta1::ControllerRevisionList',
  'IO::K8s::Api::Apps::V1beta1::DeploymentList',
  'IO::K8s::Api::Apps::V1beta1::StatefulSetList',
  'IO::K8s::Api::Apps::V1beta2::ControllerRevisionList',
  'IO::K8s::Api::Apps::V1beta2::DaemonSetList',
  'IO::K8s::Api::Apps::V1beta2::DeploymentList',
  'IO::K8s::Api::Apps::V1beta2::ReplicaSetList',
  'IO::K8s::Api::Apps::V1beta2::StatefulSetList',
  'IO::K8s::Api::Auditregistration::V1alpha1::AuditSinkList',
  'IO::K8s::Api::Autoscaling::V1::HorizontalPodAutoscalerList',
  'IO::K8s::Api::Autoscaling::V2beta1::HorizontalPodAutoscalerList',
  'IO::K8s::Api::Autoscaling::V2beta2::HorizontalPodAutoscalerList',
  'IO::K8s::Api::Batch::V1::JobList',
  'IO::K8s::Api::Batch::V1beta1::CronJobList',
  'IO::K8s::Api::Batch::V2alpha1::CronJobList',
  'IO::K8s::Api::Certificates::V1beta1::CertificateSigningRequestList',
  'IO::K8s::Api::Coordination::V1beta1::LeaseList',
  'IO::K8s::Api::Core::V1::ComponentStatusList',
  'IO::K8s::Api::Core::V1::ConfigMapList',
  'IO::K8s::Api::Core::V1::EndpointsList',
  'IO::K8s::Api::Core::V1::EventList',
  'IO::K8s::Api::Core::V1::LimitRangeList',
  'IO::K8s::Api::Core::V1::NamespaceList',
  'IO::K8s::Api::Core::V1::NodeList',
  'IO::K8s::Api::Core::V1::PersistentVolumeClaimList',
  'IO::K8s::Api::Core::V1::PersistentVolumeList',
  'IO::K8s::Api::Core::V1::PodList',
  'IO::K8s::Api::Core::V1::PodTemplateList',
  'IO::K8s::Api::Core::V1::ReplicationControllerList',
  'IO::K8s::Api::Core::V1::ResourceQuotaList',
  'IO::K8s::Api::Core::V1::SecretList',
  'IO::K8s::Api::Core::V1::ServiceAccountList',
  'IO::K8s::Api::Core::V1::ServiceList',
  'IO::K8s::Api::Events::V1beta1::EventList',
  'IO::K8s::Api::Extensions::V1beta1::DaemonSetList',
  'IO::K8s::Api::Extensions::V1beta1::DeploymentList',
  'IO::K8s::Api::Extensions::V1beta1::IngressList',
  'IO::K8s::Api::Extensions::V1beta1::NetworkPolicyList',
  'IO::K8s::Api::Extensions::V1beta1::PodSecurityPolicyList',
  'IO::K8s::Api::Extensions::V1beta1::ReplicaSetList',
  'IO::K8s::Api::Networking::V1::NetworkPolicyList',
  'IO::K8s::Api::Policy::V1beta1::PodDisruptionBudgetList',
  'IO::K8s::Api::Policy::V1beta1::PodSecurityPolicyList',
  'IO::K8s::Api::Rbac::V1::ClusterRoleBindingList',
  'IO::K8s::Api::Rbac::V1::ClusterRoleList',
  'IO::K8s::Api::Rbac::V1::RoleBindingList',
  'IO::K8s::Api::Rbac::V1::RoleList',
  'IO::K8s::Api::Rbac::V1alpha1::ClusterRoleBindingList',
  'IO::K8s::Api::Rbac::V1alpha1::ClusterRoleList',
  'IO::K8s::Api::Rbac::V1alpha1::RoleBindingList',
  'IO::K8s::Api::Rbac::V1alpha1::RoleList',
  'IO::K8s::Api::Rbac::V1beta1::ClusterRoleBindingList',
  'IO::K8s::Api::Rbac::V1beta1::ClusterRoleList',
  'IO::K8s::Api::Rbac::V1beta1::RoleBindingList',
  'IO::K8s::Api::Rbac::V1beta1::RoleList',
  'IO::K8s::Api::Scheduling::V1alpha1::PriorityClassList',
  'IO::K8s::Api::Scheduling::V1beta1::PriorityClassList',
  'IO::K8s::Api::Settings::V1alpha1::PodPresetList',
  'IO::K8s::Api::Storage::V1::StorageClassList',
  'IO::K8s::Api::Storage::V1::VolumeAttachmentList',
  'IO::K8s::Api::Storage::V1alpha1::VolumeAttachmentList',
  'IO::K8s::Api::Storage::V1beta1::StorageClassList',
  'IO::K8s::Api::Storage::V1beta1::VolumeAttachmentList',
  'IO::K8s::ApiExtensionsApiServer::Pkg::Apis::Apiextensions::V1beta1::CustomResourceDefinitionList',
  'IO::K8s::Apimachinery::Pkg::Apis::Meta::V1::APIGroupList',
  'IO::K8s::Apimachinery::Pkg::Apis::Meta::V1::APIResourceList',
  'IO::K8s::KubeAggregator::Pkg::Apis::Apiregistration::V1::APIServiceList',
  'IO::K8s::KubeAggregator::Pkg::Apis::Apiregistration::V1beta1::APIServiceList',
);

for my $mod (@old_list_classes) {
  my $ok = eval "require $mod; 1";
  ok(!$ok, "$mod dies on load");
  like($@, qr/IO::K8s::List\b/, "$mod die message points at IO::K8s::List");
}

# The four "classic DRA" (resource.k8s.io/v1alpha3 control-plane-controller
# allocation) tombstones are a different shape from the List consolidation
# above: genuinely removed with no single successor class (the whole
# allocation mechanism was replaced, not one class renamed to another), so
# each die message is checked against the same "removed" pattern rather
# than a shared successor class name.
my @classic_dra_removed = (
  'IO::K8s::Api::Resource::V1alpha3::PodSchedulingContext',
  'IO::K8s::Api::Resource::V1alpha3::PodSchedulingContextSpec',
  'IO::K8s::Api::Resource::V1alpha3::PodSchedulingContextStatus',
  'IO::K8s::Api::Resource::V1alpha3::ResourceClaimSchedulingStatus',
);

for my $mod (@classic_dra_removed) {
  my $ok = eval "require $mod; 1";
  ok(!$ok, "$mod dies on load");
  like($@, qr/has been removed/i, "$mod die message says it was removed");
  unlike($@, qr/renamed/i, "$mod die message does not falsely claim a rename");
  like($@, qr/resource\.k8s\.io\/v1\b/, "$mod die message points at the current resource.k8s.io/v1 DRA API");
}

done_testing;
