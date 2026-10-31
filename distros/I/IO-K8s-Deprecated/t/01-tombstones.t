use strict;
use warnings;
use Test::More;

# Each tombstone must die unconditionally on load. This is the whole
# contract of a redirect stub -- if it stops dying, the takeover is
# silently useless.
#
# All 74 of these are the "consolidated" shape: IO-K8s replaced every
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

# IO-K8s 0.01 to 0.03 (May 2018) shipped classes that no IO-K8s 1.x release
# has: the alpha/beta API versions Kubernetes has retired since, plus a few
# types Kubernetes dropped altogether. The PAUSE index resolves each of
# these names to IO-K8s 0.03, so each one gets a tombstone here. 180 of them
# have a successor in the current IO-K8s, and the die message names it --
# two successors for admissionregistration v1beta1 Webhook, which v1 split
# into MutatingWebhook and ValidatingWebhook.
my %retired_api_successor = (
  'IO::K8s::Api::Admissionregistration::V1beta1::MutatingWebhookConfiguration'
    => 'IO::K8s::Api::Admissionregistration::V1::MutatingWebhookConfiguration',
  'IO::K8s::Api::Admissionregistration::V1beta1::RuleWithOperations'
    => 'IO::K8s::Api::Admissionregistration::V1::RuleWithOperations',
  'IO::K8s::Api::Admissionregistration::V1beta1::ServiceReference'
    => 'IO::K8s::Api::Admissionregistration::V1::ServiceReference',
  'IO::K8s::Api::Admissionregistration::V1beta1::ValidatingWebhookConfiguration'
    => 'IO::K8s::Api::Admissionregistration::V1::ValidatingWebhookConfiguration',
  'IO::K8s::Api::Admissionregistration::V1beta1::Webhook'
    => ['IO::K8s::Api::Admissionregistration::V1::MutatingWebhook', 'IO::K8s::Api::Admissionregistration::V1::ValidatingWebhook'],
  'IO::K8s::Api::Admissionregistration::V1beta1::WebhookClientConfig'
    => 'IO::K8s::Api::Admissionregistration::V1::WebhookClientConfig',
  'IO::K8s::Api::Apps::V1beta1::ControllerRevision'
    => 'IO::K8s::Api::Apps::V1::ControllerRevision',
  'IO::K8s::Api::Apps::V1beta1::Deployment'
    => 'IO::K8s::Api::Apps::V1::Deployment',
  'IO::K8s::Api::Apps::V1beta1::DeploymentCondition'
    => 'IO::K8s::Api::Apps::V1::DeploymentCondition',
  'IO::K8s::Api::Apps::V1beta1::DeploymentSpec'
    => 'IO::K8s::Api::Apps::V1::DeploymentSpec',
  'IO::K8s::Api::Apps::V1beta1::DeploymentStatus'
    => 'IO::K8s::Api::Apps::V1::DeploymentStatus',
  'IO::K8s::Api::Apps::V1beta1::DeploymentStrategy'
    => 'IO::K8s::Api::Apps::V1::DeploymentStrategy',
  'IO::K8s::Api::Apps::V1beta1::RollingUpdateDeployment'
    => 'IO::K8s::Api::Apps::V1::RollingUpdateDeployment',
  'IO::K8s::Api::Apps::V1beta1::RollingUpdateStatefulSetStrategy'
    => 'IO::K8s::Api::Apps::V1::RollingUpdateStatefulSetStrategy',
  'IO::K8s::Api::Apps::V1beta1::Scale'
    => 'IO::K8s::Api::Autoscaling::V1::Scale',
  'IO::K8s::Api::Apps::V1beta1::ScaleSpec'
    => 'IO::K8s::Api::Autoscaling::V1::ScaleSpec',
  'IO::K8s::Api::Apps::V1beta1::ScaleStatus'
    => 'IO::K8s::Api::Autoscaling::V1::ScaleStatus',
  'IO::K8s::Api::Apps::V1beta1::StatefulSet'
    => 'IO::K8s::Api::Apps::V1::StatefulSet',
  'IO::K8s::Api::Apps::V1beta1::StatefulSetCondition'
    => 'IO::K8s::Api::Apps::V1::StatefulSetCondition',
  'IO::K8s::Api::Apps::V1beta1::StatefulSetSpec'
    => 'IO::K8s::Api::Apps::V1::StatefulSetSpec',
  'IO::K8s::Api::Apps::V1beta1::StatefulSetStatus'
    => 'IO::K8s::Api::Apps::V1::StatefulSetStatus',
  'IO::K8s::Api::Apps::V1beta1::StatefulSetUpdateStrategy'
    => 'IO::K8s::Api::Apps::V1::StatefulSetUpdateStrategy',
  'IO::K8s::Api::Apps::V1beta2::ControllerRevision'
    => 'IO::K8s::Api::Apps::V1::ControllerRevision',
  'IO::K8s::Api::Apps::V1beta2::DaemonSet'
    => 'IO::K8s::Api::Apps::V1::DaemonSet',
  'IO::K8s::Api::Apps::V1beta2::DaemonSetCondition'
    => 'IO::K8s::Api::Apps::V1::DaemonSetCondition',
  'IO::K8s::Api::Apps::V1beta2::DaemonSetSpec'
    => 'IO::K8s::Api::Apps::V1::DaemonSetSpec',
  'IO::K8s::Api::Apps::V1beta2::DaemonSetStatus'
    => 'IO::K8s::Api::Apps::V1::DaemonSetStatus',
  'IO::K8s::Api::Apps::V1beta2::DaemonSetUpdateStrategy'
    => 'IO::K8s::Api::Apps::V1::DaemonSetUpdateStrategy',
  'IO::K8s::Api::Apps::V1beta2::Deployment'
    => 'IO::K8s::Api::Apps::V1::Deployment',
  'IO::K8s::Api::Apps::V1beta2::DeploymentCondition'
    => 'IO::K8s::Api::Apps::V1::DeploymentCondition',
  'IO::K8s::Api::Apps::V1beta2::DeploymentSpec'
    => 'IO::K8s::Api::Apps::V1::DeploymentSpec',
  'IO::K8s::Api::Apps::V1beta2::DeploymentStatus'
    => 'IO::K8s::Api::Apps::V1::DeploymentStatus',
  'IO::K8s::Api::Apps::V1beta2::DeploymentStrategy'
    => 'IO::K8s::Api::Apps::V1::DeploymentStrategy',
  'IO::K8s::Api::Apps::V1beta2::ReplicaSet'
    => 'IO::K8s::Api::Apps::V1::ReplicaSet',
  'IO::K8s::Api::Apps::V1beta2::ReplicaSetCondition'
    => 'IO::K8s::Api::Apps::V1::ReplicaSetCondition',
  'IO::K8s::Api::Apps::V1beta2::ReplicaSetSpec'
    => 'IO::K8s::Api::Apps::V1::ReplicaSetSpec',
  'IO::K8s::Api::Apps::V1beta2::ReplicaSetStatus'
    => 'IO::K8s::Api::Apps::V1::ReplicaSetStatus',
  'IO::K8s::Api::Apps::V1beta2::RollingUpdateDaemonSet'
    => 'IO::K8s::Api::Apps::V1::RollingUpdateDaemonSet',
  'IO::K8s::Api::Apps::V1beta2::RollingUpdateDeployment'
    => 'IO::K8s::Api::Apps::V1::RollingUpdateDeployment',
  'IO::K8s::Api::Apps::V1beta2::RollingUpdateStatefulSetStrategy'
    => 'IO::K8s::Api::Apps::V1::RollingUpdateStatefulSetStrategy',
  'IO::K8s::Api::Apps::V1beta2::Scale'
    => 'IO::K8s::Api::Autoscaling::V1::Scale',
  'IO::K8s::Api::Apps::V1beta2::ScaleSpec'
    => 'IO::K8s::Api::Autoscaling::V1::ScaleSpec',
  'IO::K8s::Api::Apps::V1beta2::ScaleStatus'
    => 'IO::K8s::Api::Autoscaling::V1::ScaleStatus',
  'IO::K8s::Api::Apps::V1beta2::StatefulSet'
    => 'IO::K8s::Api::Apps::V1::StatefulSet',
  'IO::K8s::Api::Apps::V1beta2::StatefulSetCondition'
    => 'IO::K8s::Api::Apps::V1::StatefulSetCondition',
  'IO::K8s::Api::Apps::V1beta2::StatefulSetSpec'
    => 'IO::K8s::Api::Apps::V1::StatefulSetSpec',
  'IO::K8s::Api::Apps::V1beta2::StatefulSetStatus'
    => 'IO::K8s::Api::Apps::V1::StatefulSetStatus',
  'IO::K8s::Api::Apps::V1beta2::StatefulSetUpdateStrategy'
    => 'IO::K8s::Api::Apps::V1::StatefulSetUpdateStrategy',
  'IO::K8s::Api::Authentication::V1beta1::TokenReview'
    => 'IO::K8s::Api::Authentication::V1::TokenReview',
  'IO::K8s::Api::Authentication::V1beta1::TokenReviewSpec'
    => 'IO::K8s::Api::Authentication::V1::TokenReviewSpec',
  'IO::K8s::Api::Authentication::V1beta1::TokenReviewStatus'
    => 'IO::K8s::Api::Authentication::V1::TokenReviewStatus',
  'IO::K8s::Api::Authentication::V1beta1::UserInfo'
    => 'IO::K8s::Api::Authentication::V1::UserInfo',
  'IO::K8s::Api::Authorization::V1beta1::LocalSubjectAccessReview'
    => 'IO::K8s::Api::Authorization::V1::LocalSubjectAccessReview',
  'IO::K8s::Api::Authorization::V1beta1::NonResourceAttributes'
    => 'IO::K8s::Api::Authorization::V1::NonResourceAttributes',
  'IO::K8s::Api::Authorization::V1beta1::NonResourceRule'
    => 'IO::K8s::Api::Authorization::V1::NonResourceRule',
  'IO::K8s::Api::Authorization::V1beta1::ResourceAttributes'
    => 'IO::K8s::Api::Authorization::V1::ResourceAttributes',
  'IO::K8s::Api::Authorization::V1beta1::ResourceRule'
    => 'IO::K8s::Api::Authorization::V1::ResourceRule',
  'IO::K8s::Api::Authorization::V1beta1::SelfSubjectAccessReview'
    => 'IO::K8s::Api::Authorization::V1::SelfSubjectAccessReview',
  'IO::K8s::Api::Authorization::V1beta1::SelfSubjectAccessReviewSpec'
    => 'IO::K8s::Api::Authorization::V1::SelfSubjectAccessReviewSpec',
  'IO::K8s::Api::Authorization::V1beta1::SelfSubjectRulesReview'
    => 'IO::K8s::Api::Authorization::V1::SelfSubjectRulesReview',
  'IO::K8s::Api::Authorization::V1beta1::SelfSubjectRulesReviewSpec'
    => 'IO::K8s::Api::Authorization::V1::SelfSubjectRulesReviewSpec',
  'IO::K8s::Api::Authorization::V1beta1::SubjectAccessReview'
    => 'IO::K8s::Api::Authorization::V1::SubjectAccessReview',
  'IO::K8s::Api::Authorization::V1beta1::SubjectAccessReviewSpec'
    => 'IO::K8s::Api::Authorization::V1::SubjectAccessReviewSpec',
  'IO::K8s::Api::Authorization::V1beta1::SubjectAccessReviewStatus'
    => 'IO::K8s::Api::Authorization::V1::SubjectAccessReviewStatus',
  'IO::K8s::Api::Authorization::V1beta1::SubjectRulesReviewStatus'
    => 'IO::K8s::Api::Authorization::V1::SubjectRulesReviewStatus',
  'IO::K8s::Api::Autoscaling::V2beta1::CrossVersionObjectReference'
    => 'IO::K8s::Api::Autoscaling::V2::CrossVersionObjectReference',
  'IO::K8s::Api::Autoscaling::V2beta1::ExternalMetricSource'
    => 'IO::K8s::Api::Autoscaling::V2::ExternalMetricSource',
  'IO::K8s::Api::Autoscaling::V2beta1::ExternalMetricStatus'
    => 'IO::K8s::Api::Autoscaling::V2::ExternalMetricStatus',
  'IO::K8s::Api::Autoscaling::V2beta1::HorizontalPodAutoscaler'
    => 'IO::K8s::Api::Autoscaling::V2::HorizontalPodAutoscaler',
  'IO::K8s::Api::Autoscaling::V2beta1::HorizontalPodAutoscalerCondition'
    => 'IO::K8s::Api::Autoscaling::V2::HorizontalPodAutoscalerCondition',
  'IO::K8s::Api::Autoscaling::V2beta1::HorizontalPodAutoscalerSpec'
    => 'IO::K8s::Api::Autoscaling::V2::HorizontalPodAutoscalerSpec',
  'IO::K8s::Api::Autoscaling::V2beta1::HorizontalPodAutoscalerStatus'
    => 'IO::K8s::Api::Autoscaling::V2::HorizontalPodAutoscalerStatus',
  'IO::K8s::Api::Autoscaling::V2beta1::MetricSpec'
    => 'IO::K8s::Api::Autoscaling::V2::MetricSpec',
  'IO::K8s::Api::Autoscaling::V2beta1::MetricStatus'
    => 'IO::K8s::Api::Autoscaling::V2::MetricStatus',
  'IO::K8s::Api::Autoscaling::V2beta1::ObjectMetricSource'
    => 'IO::K8s::Api::Autoscaling::V2::ObjectMetricSource',
  'IO::K8s::Api::Autoscaling::V2beta1::ObjectMetricStatus'
    => 'IO::K8s::Api::Autoscaling::V2::ObjectMetricStatus',
  'IO::K8s::Api::Autoscaling::V2beta1::PodsMetricSource'
    => 'IO::K8s::Api::Autoscaling::V2::PodsMetricSource',
  'IO::K8s::Api::Autoscaling::V2beta1::PodsMetricStatus'
    => 'IO::K8s::Api::Autoscaling::V2::PodsMetricStatus',
  'IO::K8s::Api::Autoscaling::V2beta1::ResourceMetricSource'
    => 'IO::K8s::Api::Autoscaling::V2::ResourceMetricSource',
  'IO::K8s::Api::Autoscaling::V2beta1::ResourceMetricStatus'
    => 'IO::K8s::Api::Autoscaling::V2::ResourceMetricStatus',
  'IO::K8s::Api::Batch::V1beta1::CronJob'
    => 'IO::K8s::Api::Batch::V1::CronJob',
  'IO::K8s::Api::Batch::V1beta1::CronJobSpec'
    => 'IO::K8s::Api::Batch::V1::CronJobSpec',
  'IO::K8s::Api::Batch::V1beta1::CronJobStatus'
    => 'IO::K8s::Api::Batch::V1::CronJobStatus',
  'IO::K8s::Api::Batch::V1beta1::JobTemplateSpec'
    => 'IO::K8s::Api::Batch::V1::JobTemplateSpec',
  'IO::K8s::Api::Batch::V2alpha1::CronJob'
    => 'IO::K8s::Api::Batch::V1::CronJob',
  'IO::K8s::Api::Batch::V2alpha1::CronJobSpec'
    => 'IO::K8s::Api::Batch::V1::CronJobSpec',
  'IO::K8s::Api::Batch::V2alpha1::CronJobStatus'
    => 'IO::K8s::Api::Batch::V1::CronJobStatus',
  'IO::K8s::Api::Batch::V2alpha1::JobTemplateSpec'
    => 'IO::K8s::Api::Batch::V1::JobTemplateSpec',
  'IO::K8s::Api::Certificates::V1beta1::CertificateSigningRequest'
    => 'IO::K8s::Api::Certificates::V1::CertificateSigningRequest',
  'IO::K8s::Api::Certificates::V1beta1::CertificateSigningRequestCondition'
    => 'IO::K8s::Api::Certificates::V1::CertificateSigningRequestCondition',
  'IO::K8s::Api::Certificates::V1beta1::CertificateSigningRequestSpec'
    => 'IO::K8s::Api::Certificates::V1::CertificateSigningRequestSpec',
  'IO::K8s::Api::Certificates::V1beta1::CertificateSigningRequestStatus'
    => 'IO::K8s::Api::Certificates::V1::CertificateSigningRequestStatus',
  'IO::K8s::Api::Core::V1::Handler'
    => 'IO::K8s::Api::Core::V1::LifecycleHandler',
  'IO::K8s::Api::Events::V1beta1::Event'
    => 'IO::K8s::Api::Events::V1::Event',
  'IO::K8s::Api::Events::V1beta1::EventSeries'
    => 'IO::K8s::Api::Events::V1::EventSeries',
  'IO::K8s::Api::Extensions::V1beta1::DaemonSet'
    => 'IO::K8s::Api::Apps::V1::DaemonSet',
  'IO::K8s::Api::Extensions::V1beta1::DaemonSetCondition'
    => 'IO::K8s::Api::Apps::V1::DaemonSetCondition',
  'IO::K8s::Api::Extensions::V1beta1::DaemonSetSpec'
    => 'IO::K8s::Api::Apps::V1::DaemonSetSpec',
  'IO::K8s::Api::Extensions::V1beta1::DaemonSetStatus'
    => 'IO::K8s::Api::Apps::V1::DaemonSetStatus',
  'IO::K8s::Api::Extensions::V1beta1::DaemonSetUpdateStrategy'
    => 'IO::K8s::Api::Apps::V1::DaemonSetUpdateStrategy',
  'IO::K8s::Api::Extensions::V1beta1::Deployment'
    => 'IO::K8s::Api::Apps::V1::Deployment',
  'IO::K8s::Api::Extensions::V1beta1::DeploymentCondition'
    => 'IO::K8s::Api::Apps::V1::DeploymentCondition',
  'IO::K8s::Api::Extensions::V1beta1::DeploymentSpec'
    => 'IO::K8s::Api::Apps::V1::DeploymentSpec',
  'IO::K8s::Api::Extensions::V1beta1::DeploymentStatus'
    => 'IO::K8s::Api::Apps::V1::DeploymentStatus',
  'IO::K8s::Api::Extensions::V1beta1::DeploymentStrategy'
    => 'IO::K8s::Api::Apps::V1::DeploymentStrategy',
  'IO::K8s::Api::Extensions::V1beta1::HTTPIngressPath'
    => 'IO::K8s::Api::Networking::V1::HTTPIngressPath',
  'IO::K8s::Api::Extensions::V1beta1::HTTPIngressRuleValue'
    => 'IO::K8s::Api::Networking::V1::HTTPIngressRuleValue',
  'IO::K8s::Api::Extensions::V1beta1::IPBlock'
    => 'IO::K8s::Api::Networking::V1::IPBlock',
  'IO::K8s::Api::Extensions::V1beta1::Ingress'
    => 'IO::K8s::Api::Networking::V1::Ingress',
  'IO::K8s::Api::Extensions::V1beta1::IngressBackend'
    => 'IO::K8s::Api::Networking::V1::IngressBackend',
  'IO::K8s::Api::Extensions::V1beta1::IngressRule'
    => 'IO::K8s::Api::Networking::V1::IngressRule',
  'IO::K8s::Api::Extensions::V1beta1::IngressSpec'
    => 'IO::K8s::Api::Networking::V1::IngressSpec',
  'IO::K8s::Api::Extensions::V1beta1::IngressStatus'
    => 'IO::K8s::Api::Networking::V1::IngressStatus',
  'IO::K8s::Api::Extensions::V1beta1::IngressTLS'
    => 'IO::K8s::Api::Networking::V1::IngressTLS',
  'IO::K8s::Api::Extensions::V1beta1::NetworkPolicy'
    => 'IO::K8s::Api::Networking::V1::NetworkPolicy',
  'IO::K8s::Api::Extensions::V1beta1::NetworkPolicyEgressRule'
    => 'IO::K8s::Api::Networking::V1::NetworkPolicyEgressRule',
  'IO::K8s::Api::Extensions::V1beta1::NetworkPolicyIngressRule'
    => 'IO::K8s::Api::Networking::V1::NetworkPolicyIngressRule',
  'IO::K8s::Api::Extensions::V1beta1::NetworkPolicyPeer'
    => 'IO::K8s::Api::Networking::V1::NetworkPolicyPeer',
  'IO::K8s::Api::Extensions::V1beta1::NetworkPolicyPort'
    => 'IO::K8s::Api::Networking::V1::NetworkPolicyPort',
  'IO::K8s::Api::Extensions::V1beta1::NetworkPolicySpec'
    => 'IO::K8s::Api::Networking::V1::NetworkPolicySpec',
  'IO::K8s::Api::Extensions::V1beta1::ReplicaSet'
    => 'IO::K8s::Api::Apps::V1::ReplicaSet',
  'IO::K8s::Api::Extensions::V1beta1::ReplicaSetCondition'
    => 'IO::K8s::Api::Apps::V1::ReplicaSetCondition',
  'IO::K8s::Api::Extensions::V1beta1::ReplicaSetSpec'
    => 'IO::K8s::Api::Apps::V1::ReplicaSetSpec',
  'IO::K8s::Api::Extensions::V1beta1::ReplicaSetStatus'
    => 'IO::K8s::Api::Apps::V1::ReplicaSetStatus',
  'IO::K8s::Api::Extensions::V1beta1::RollingUpdateDaemonSet'
    => 'IO::K8s::Api::Apps::V1::RollingUpdateDaemonSet',
  'IO::K8s::Api::Extensions::V1beta1::RollingUpdateDeployment'
    => 'IO::K8s::Api::Apps::V1::RollingUpdateDeployment',
  'IO::K8s::Api::Extensions::V1beta1::Scale'
    => 'IO::K8s::Api::Autoscaling::V1::Scale',
  'IO::K8s::Api::Extensions::V1beta1::ScaleSpec'
    => 'IO::K8s::Api::Autoscaling::V1::ScaleSpec',
  'IO::K8s::Api::Extensions::V1beta1::ScaleStatus'
    => 'IO::K8s::Api::Autoscaling::V1::ScaleStatus',
  'IO::K8s::Api::Policy::V1beta1::Eviction'
    => 'IO::K8s::Api::Policy::V1::Eviction',
  'IO::K8s::Api::Policy::V1beta1::PodDisruptionBudget'
    => 'IO::K8s::Api::Policy::V1::PodDisruptionBudget',
  'IO::K8s::Api::Policy::V1beta1::PodDisruptionBudgetSpec'
    => 'IO::K8s::Api::Policy::V1::PodDisruptionBudgetSpec',
  'IO::K8s::Api::Policy::V1beta1::PodDisruptionBudgetStatus'
    => 'IO::K8s::Api::Policy::V1::PodDisruptionBudgetStatus',
  'IO::K8s::Api::Rbac::V1alpha1::AggregationRule'
    => 'IO::K8s::Api::Rbac::V1::AggregationRule',
  'IO::K8s::Api::Rbac::V1alpha1::ClusterRole'
    => 'IO::K8s::Api::Rbac::V1::ClusterRole',
  'IO::K8s::Api::Rbac::V1alpha1::ClusterRoleBinding'
    => 'IO::K8s::Api::Rbac::V1::ClusterRoleBinding',
  'IO::K8s::Api::Rbac::V1alpha1::PolicyRule'
    => 'IO::K8s::Api::Rbac::V1::PolicyRule',
  'IO::K8s::Api::Rbac::V1alpha1::Role'
    => 'IO::K8s::Api::Rbac::V1::Role',
  'IO::K8s::Api::Rbac::V1alpha1::RoleBinding'
    => 'IO::K8s::Api::Rbac::V1::RoleBinding',
  'IO::K8s::Api::Rbac::V1alpha1::RoleRef'
    => 'IO::K8s::Api::Rbac::V1::RoleRef',
  'IO::K8s::Api::Rbac::V1alpha1::Subject'
    => 'IO::K8s::Api::Rbac::V1::Subject',
  'IO::K8s::Api::Rbac::V1beta1::AggregationRule'
    => 'IO::K8s::Api::Rbac::V1::AggregationRule',
  'IO::K8s::Api::Rbac::V1beta1::ClusterRole'
    => 'IO::K8s::Api::Rbac::V1::ClusterRole',
  'IO::K8s::Api::Rbac::V1beta1::ClusterRoleBinding'
    => 'IO::K8s::Api::Rbac::V1::ClusterRoleBinding',
  'IO::K8s::Api::Rbac::V1beta1::PolicyRule'
    => 'IO::K8s::Api::Rbac::V1::PolicyRule',
  'IO::K8s::Api::Rbac::V1beta1::Role'
    => 'IO::K8s::Api::Rbac::V1::Role',
  'IO::K8s::Api::Rbac::V1beta1::RoleBinding'
    => 'IO::K8s::Api::Rbac::V1::RoleBinding',
  'IO::K8s::Api::Rbac::V1beta1::RoleRef'
    => 'IO::K8s::Api::Rbac::V1::RoleRef',
  'IO::K8s::Api::Rbac::V1beta1::Subject'
    => 'IO::K8s::Api::Rbac::V1::Subject',
  'IO::K8s::Api::Scheduling::V1alpha1::PriorityClass'
    => 'IO::K8s::Api::Scheduling::V1::PriorityClass',
  'IO::K8s::Api::Storage::V1alpha1::VolumeAttachment'
    => 'IO::K8s::Api::Storage::V1::VolumeAttachment',
  'IO::K8s::Api::Storage::V1alpha1::VolumeAttachmentSource'
    => 'IO::K8s::Api::Storage::V1::VolumeAttachmentSource',
  'IO::K8s::Api::Storage::V1alpha1::VolumeAttachmentSpec'
    => 'IO::K8s::Api::Storage::V1::VolumeAttachmentSpec',
  'IO::K8s::Api::Storage::V1alpha1::VolumeAttachmentStatus'
    => 'IO::K8s::Api::Storage::V1::VolumeAttachmentStatus',
  'IO::K8s::Api::Storage::V1alpha1::VolumeError'
    => 'IO::K8s::Api::Storage::V1::VolumeError',
  'IO::K8s::Api::Storage::V1beta1::StorageClass'
    => 'IO::K8s::Api::Storage::V1::StorageClass',
  'IO::K8s::Api::Storage::V1beta1::VolumeAttachment'
    => 'IO::K8s::Api::Storage::V1::VolumeAttachment',
  'IO::K8s::Api::Storage::V1beta1::VolumeAttachmentSource'
    => 'IO::K8s::Api::Storage::V1::VolumeAttachmentSource',
  'IO::K8s::Api::Storage::V1beta1::VolumeAttachmentSpec'
    => 'IO::K8s::Api::Storage::V1::VolumeAttachmentSpec',
  'IO::K8s::Api::Storage::V1beta1::VolumeAttachmentStatus'
    => 'IO::K8s::Api::Storage::V1::VolumeAttachmentStatus',
  'IO::K8s::Api::Storage::V1beta1::VolumeError'
    => 'IO::K8s::Api::Storage::V1::VolumeError',
  'IO::K8s::ApiExtensionsApiServer::Pkg::Apis::Apiextensions::V1beta1::CustomResourceDefinition'
    => 'IO::K8s::ApiextensionsApiserver::Pkg::Apis::Apiextensions::V1::CustomResourceDefinition',
  'IO::K8s::ApiExtensionsApiServer::Pkg::Apis::Apiextensions::V1beta1::CustomResourceDefinitionCondition'
    => 'IO::K8s::ApiextensionsApiserver::Pkg::Apis::Apiextensions::V1::CustomResourceDefinitionCondition',
  'IO::K8s::ApiExtensionsApiServer::Pkg::Apis::Apiextensions::V1beta1::CustomResourceDefinitionNames'
    => 'IO::K8s::ApiextensionsApiserver::Pkg::Apis::Apiextensions::V1::CustomResourceDefinitionNames',
  'IO::K8s::ApiExtensionsApiServer::Pkg::Apis::Apiextensions::V1beta1::CustomResourceDefinitionSpec'
    => 'IO::K8s::ApiextensionsApiserver::Pkg::Apis::Apiextensions::V1::CustomResourceDefinitionSpec',
  'IO::K8s::ApiExtensionsApiServer::Pkg::Apis::Apiextensions::V1beta1::CustomResourceDefinitionStatus'
    => 'IO::K8s::ApiextensionsApiserver::Pkg::Apis::Apiextensions::V1::CustomResourceDefinitionStatus',
  'IO::K8s::ApiExtensionsApiServer::Pkg::Apis::Apiextensions::V1beta1::CustomResourceSubresourceScale'
    => 'IO::K8s::ApiextensionsApiserver::Pkg::Apis::Apiextensions::V1::CustomResourceSubresourceScale',
  'IO::K8s::ApiExtensionsApiServer::Pkg::Apis::Apiextensions::V1beta1::CustomResourceSubresources'
    => 'IO::K8s::ApiextensionsApiserver::Pkg::Apis::Apiextensions::V1::CustomResourceSubresources',
  'IO::K8s::ApiExtensionsApiServer::Pkg::Apis::Apiextensions::V1beta1::CustomResourceValidation'
    => 'IO::K8s::ApiextensionsApiserver::Pkg::Apis::Apiextensions::V1::CustomResourceValidation',
  'IO::K8s::ApiExtensionsApiServer::Pkg::Apis::Apiextensions::V1beta1::ExternalDocumentation'
    => 'IO::K8s::ApiextensionsApiserver::Pkg::Apis::Apiextensions::V1::ExternalDocumentation',
  'IO::K8s::ApiExtensionsApiServer::Pkg::Apis::Apiextensions::V1beta1::JSON'
    => 'IO::K8s::ApiextensionsApiserver::Pkg::Apis::Apiextensions::V1::JSON',
  'IO::K8s::ApiExtensionsApiServer::Pkg::Apis::Apiextensions::V1beta1::JSONSchemaProps'
    => 'IO::K8s::ApiextensionsApiserver::Pkg::Apis::Apiextensions::V1::JSONSchemaProps',
  'IO::K8s::ApiExtensionsApiServer::Pkg::Apis::Apiextensions::V1beta1::JSONSchemaPropsOrArray'
    => 'IO::K8s::ApiextensionsApiserver::Pkg::Apis::Apiextensions::V1::JSONSchemaPropsOrArray',
  'IO::K8s::ApiExtensionsApiServer::Pkg::Apis::Apiextensions::V1beta1::JSONSchemaPropsOrBool'
    => 'IO::K8s::ApiextensionsApiserver::Pkg::Apis::Apiextensions::V1::JSONSchemaPropsOrBool',
  'IO::K8s::ApiExtensionsApiServer::Pkg::Apis::Apiextensions::V1beta1::JSONSchemaPropsOrStringArray'
    => 'IO::K8s::ApiextensionsApiserver::Pkg::Apis::Apiextensions::V1::JSONSchemaPropsOrStringArray',
  'IO::K8s::KubeAggregator::Pkg::Apis::Apiregistration::V1beta1::APIService'
    => 'IO::K8s::KubeAggregator::Pkg::Apis::Apiregistration::V1::APIService',
  'IO::K8s::KubeAggregator::Pkg::Apis::Apiregistration::V1beta1::APIServiceCondition'
    => 'IO::K8s::KubeAggregator::Pkg::Apis::Apiregistration::V1::APIServiceCondition',
  'IO::K8s::KubeAggregator::Pkg::Apis::Apiregistration::V1beta1::APIServiceSpec'
    => 'IO::K8s::KubeAggregator::Pkg::Apis::Apiregistration::V1::APIServiceSpec',
  'IO::K8s::KubeAggregator::Pkg::Apis::Apiregistration::V1beta1::APIServiceStatus'
    => 'IO::K8s::KubeAggregator::Pkg::Apis::Apiregistration::V1::APIServiceStatus',
  'IO::K8s::KubeAggregator::Pkg::Apis::Apiregistration::V1beta1::ServiceReference'
    => 'IO::K8s::KubeAggregator::Pkg::Apis::Apiregistration::V1::ServiceReference',
);

for my $mod (sort keys %retired_api_successor) {
  my $ok = eval "require $mod; 1";
  ok(!$ok, "$mod dies on load");
  my $successors = $retired_api_successor{$mod};
  for my $successor (ref $successors ? @$successors : $successors) {
    like($@, qr/\Q$successor\E\b/, "$mod die message points at $successor");
  }
  like($@, qr/IO-K8s shipped (?:it|the old name) only in 0\.01 to\s+0\.03/,
    "$mod die message says which IO-K8s releases shipped it");
}

# The other 32 are gone from Kubernetes itself, with no successor class:
# PodSecurityPolicy (extensions and policy v1beta1), the alpha Initializers,
# the Deployment rollback types of apps and extensions v1beta1, the alpha
# PodPreset, and RawExtension, which IO-K8s 1.x declares as an Opaque field
# instead of a class. Each die message names the reason.
my %removed_reason = (
  psp          => qr/PodSecurityPolicy.*Pod\s+Security\s+Admission/s,
  initializers => qr/Initializers feature/,
  rollback     => qr/Deployment rollback/,
  podpreset    => qr/PodPreset API/,
  rawextension => qr/Opaque/,
);
my %retired_api_removed = (
  'IO::K8s::Api::Admissionregistration::V1alpha1::Initializer' => 'initializers',
  'IO::K8s::Api::Admissionregistration::V1alpha1::InitializerConfiguration' => 'initializers',
  'IO::K8s::Api::Admissionregistration::V1alpha1::Rule' => 'initializers',
  'IO::K8s::Api::Apps::V1beta1::DeploymentRollback' => 'rollback',
  'IO::K8s::Api::Apps::V1beta1::RollbackConfig' => 'rollback',
  'IO::K8s::Api::Extensions::V1beta1::AllowedFlexVolume' => 'psp',
  'IO::K8s::Api::Extensions::V1beta1::AllowedHostPath' => 'psp',
  'IO::K8s::Api::Extensions::V1beta1::DeploymentRollback' => 'rollback',
  'IO::K8s::Api::Extensions::V1beta1::FSGroupStrategyOptions' => 'psp',
  'IO::K8s::Api::Extensions::V1beta1::HostPortRange' => 'psp',
  'IO::K8s::Api::Extensions::V1beta1::IDRange' => 'psp',
  'IO::K8s::Api::Extensions::V1beta1::PodSecurityPolicy' => 'psp',
  'IO::K8s::Api::Extensions::V1beta1::PodSecurityPolicySpec' => 'psp',
  'IO::K8s::Api::Extensions::V1beta1::RollbackConfig' => 'rollback',
  'IO::K8s::Api::Extensions::V1beta1::RunAsUserStrategyOptions' => 'psp',
  'IO::K8s::Api::Extensions::V1beta1::SELinuxStrategyOptions' => 'psp',
  'IO::K8s::Api::Extensions::V1beta1::SupplementalGroupsStrategyOptions' => 'psp',
  'IO::K8s::Api::Policy::V1beta1::AllowedFlexVolume' => 'psp',
  'IO::K8s::Api::Policy::V1beta1::AllowedHostPath' => 'psp',
  'IO::K8s::Api::Policy::V1beta1::FSGroupStrategyOptions' => 'psp',
  'IO::K8s::Api::Policy::V1beta1::HostPortRange' => 'psp',
  'IO::K8s::Api::Policy::V1beta1::IDRange' => 'psp',
  'IO::K8s::Api::Policy::V1beta1::PodSecurityPolicy' => 'psp',
  'IO::K8s::Api::Policy::V1beta1::PodSecurityPolicySpec' => 'psp',
  'IO::K8s::Api::Policy::V1beta1::RunAsUserStrategyOptions' => 'psp',
  'IO::K8s::Api::Policy::V1beta1::SELinuxStrategyOptions' => 'psp',
  'IO::K8s::Api::Policy::V1beta1::SupplementalGroupsStrategyOptions' => 'psp',
  'IO::K8s::Api::Settings::V1alpha1::PodPreset' => 'podpreset',
  'IO::K8s::Api::Settings::V1alpha1::PodPresetSpec' => 'podpreset',
  'IO::K8s::Apimachinery::Pkg::Apis::Meta::V1::Initializer' => 'initializers',
  'IO::K8s::Apimachinery::Pkg::Apis::Meta::V1::Initializers' => 'initializers',
  'IO::K8s::Apimachinery::Pkg::Runtime::RawExtension' => 'rawextension',
);

for my $mod (sort keys %retired_api_removed) {
  my $ok = eval "require $mod; 1";
  ok(!$ok, "$mod dies on load");
  like($@, qr/has been removed/i, "$mod die message says it was removed");
  unlike($@, qr/renamed/i, "$mod die message does not falsely claim a rename");
  like($@, $removed_reason{ $retired_api_removed{$mod} },
    "$mod die message names why ($retired_api_removed{$mod})");
}

done_testing;
