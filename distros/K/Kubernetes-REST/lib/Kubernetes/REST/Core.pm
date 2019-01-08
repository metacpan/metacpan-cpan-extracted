package Kubernetes::REST::Core;
  use Moo;
  use Kubernetes::REST::CallContext;

  has param_converter => (is => 'ro', required => 1);
  has io => (is => 'ro', required => 1);
  has result_parser => (is => 'ro', required => 1);
  has server => (is => 'ro', required => 1);
  has credentials => (is => 'ro', required => 1);
  has api_version => (is => 'ro', required => 1);

  sub _invoke_unversioned {
    my ($self, $method, $params) = @_;

    my $call = Kubernetes::REST::CallContext->new(
      method => $method,
      params => $params,
      server => $self->server,
      credentials => $self->credentials,
    );
    my $req = $self->param_converter->params2request($call);
    my $result = $self->io->call($call, $req);
    return $self->result_parser->result2return($call, $req, $result);
  }

  sub _invoke_versioned {
    my ($self, $method, $params) = @_;

    my $call = Kubernetes::REST::CallContext->new(
      method => $self->api_version . '::Core::' . $method,
      params => $params,
      server => $self->server,
      credentials => $self->credentials,
    );
    my $req = $self->param_converter->params2request($call);
    my $result = $self->io->call($call, $req);
    return $self->result_parser->result2return($call, $req, $result);
  }

  
  sub ConnectDeleteNamespacedPodProxy {
    my ($self, @params) = @_;
    $self->_invoke_versioned('ConnectDeleteNamespacedPodProxy', \@params);
  }
  
  sub ConnectDeleteNamespacedPodProxyWithPath {
    my ($self, @params) = @_;
    $self->_invoke_versioned('ConnectDeleteNamespacedPodProxyWithPath', \@params);
  }
  
  sub ConnectDeleteNamespacedServiceProxy {
    my ($self, @params) = @_;
    $self->_invoke_versioned('ConnectDeleteNamespacedServiceProxy', \@params);
  }
  
  sub ConnectDeleteNamespacedServiceProxyWithPath {
    my ($self, @params) = @_;
    $self->_invoke_versioned('ConnectDeleteNamespacedServiceProxyWithPath', \@params);
  }
  
  sub ConnectDeleteNodeProxy {
    my ($self, @params) = @_;
    $self->_invoke_versioned('ConnectDeleteNodeProxy', \@params);
  }
  
  sub ConnectDeleteNodeProxyWithPath {
    my ($self, @params) = @_;
    $self->_invoke_versioned('ConnectDeleteNodeProxyWithPath', \@params);
  }
  
  sub ConnectGetNamespacedPodAttach {
    my ($self, @params) = @_;
    $self->_invoke_versioned('ConnectGetNamespacedPodAttach', \@params);
  }
  
  sub ConnectGetNamespacedPodExec {
    my ($self, @params) = @_;
    $self->_invoke_versioned('ConnectGetNamespacedPodExec', \@params);
  }
  
  sub ConnectGetNamespacedPodPortforward {
    my ($self, @params) = @_;
    $self->_invoke_versioned('ConnectGetNamespacedPodPortforward', \@params);
  }
  
  sub ConnectGetNamespacedPodProxy {
    my ($self, @params) = @_;
    $self->_invoke_versioned('ConnectGetNamespacedPodProxy', \@params);
  }
  
  sub ConnectGetNamespacedPodProxyWithPath {
    my ($self, @params) = @_;
    $self->_invoke_versioned('ConnectGetNamespacedPodProxyWithPath', \@params);
  }
  
  sub ConnectGetNamespacedServiceProxy {
    my ($self, @params) = @_;
    $self->_invoke_versioned('ConnectGetNamespacedServiceProxy', \@params);
  }
  
  sub ConnectGetNamespacedServiceProxyWithPath {
    my ($self, @params) = @_;
    $self->_invoke_versioned('ConnectGetNamespacedServiceProxyWithPath', \@params);
  }
  
  sub ConnectGetNodeProxy {
    my ($self, @params) = @_;
    $self->_invoke_versioned('ConnectGetNodeProxy', \@params);
  }
  
  sub ConnectGetNodeProxyWithPath {
    my ($self, @params) = @_;
    $self->_invoke_versioned('ConnectGetNodeProxyWithPath', \@params);
  }
  
  sub ConnectHeadNamespacedPodProxy {
    my ($self, @params) = @_;
    $self->_invoke_versioned('ConnectHeadNamespacedPodProxy', \@params);
  }
  
  sub ConnectHeadNamespacedPodProxyWithPath {
    my ($self, @params) = @_;
    $self->_invoke_versioned('ConnectHeadNamespacedPodProxyWithPath', \@params);
  }
  
  sub ConnectHeadNamespacedServiceProxy {
    my ($self, @params) = @_;
    $self->_invoke_versioned('ConnectHeadNamespacedServiceProxy', \@params);
  }
  
  sub ConnectHeadNamespacedServiceProxyWithPath {
    my ($self, @params) = @_;
    $self->_invoke_versioned('ConnectHeadNamespacedServiceProxyWithPath', \@params);
  }
  
  sub ConnectHeadNodeProxy {
    my ($self, @params) = @_;
    $self->_invoke_versioned('ConnectHeadNodeProxy', \@params);
  }
  
  sub ConnectHeadNodeProxyWithPath {
    my ($self, @params) = @_;
    $self->_invoke_versioned('ConnectHeadNodeProxyWithPath', \@params);
  }
  
  sub ConnectOptionsNamespacedPodProxy {
    my ($self, @params) = @_;
    $self->_invoke_versioned('ConnectOptionsNamespacedPodProxy', \@params);
  }
  
  sub ConnectOptionsNamespacedPodProxyWithPath {
    my ($self, @params) = @_;
    $self->_invoke_versioned('ConnectOptionsNamespacedPodProxyWithPath', \@params);
  }
  
  sub ConnectOptionsNamespacedServiceProxy {
    my ($self, @params) = @_;
    $self->_invoke_versioned('ConnectOptionsNamespacedServiceProxy', \@params);
  }
  
  sub ConnectOptionsNamespacedServiceProxyWithPath {
    my ($self, @params) = @_;
    $self->_invoke_versioned('ConnectOptionsNamespacedServiceProxyWithPath', \@params);
  }
  
  sub ConnectOptionsNodeProxy {
    my ($self, @params) = @_;
    $self->_invoke_versioned('ConnectOptionsNodeProxy', \@params);
  }
  
  sub ConnectOptionsNodeProxyWithPath {
    my ($self, @params) = @_;
    $self->_invoke_versioned('ConnectOptionsNodeProxyWithPath', \@params);
  }
  
  sub ConnectPatchNamespacedPodProxy {
    my ($self, @params) = @_;
    $self->_invoke_versioned('ConnectPatchNamespacedPodProxy', \@params);
  }
  
  sub ConnectPatchNamespacedPodProxyWithPath {
    my ($self, @params) = @_;
    $self->_invoke_versioned('ConnectPatchNamespacedPodProxyWithPath', \@params);
  }
  
  sub ConnectPatchNamespacedServiceProxy {
    my ($self, @params) = @_;
    $self->_invoke_versioned('ConnectPatchNamespacedServiceProxy', \@params);
  }
  
  sub ConnectPatchNamespacedServiceProxyWithPath {
    my ($self, @params) = @_;
    $self->_invoke_versioned('ConnectPatchNamespacedServiceProxyWithPath', \@params);
  }
  
  sub ConnectPatchNodeProxy {
    my ($self, @params) = @_;
    $self->_invoke_versioned('ConnectPatchNodeProxy', \@params);
  }
  
  sub ConnectPatchNodeProxyWithPath {
    my ($self, @params) = @_;
    $self->_invoke_versioned('ConnectPatchNodeProxyWithPath', \@params);
  }
  
  sub ConnectPostNamespacedPodAttach {
    my ($self, @params) = @_;
    $self->_invoke_versioned('ConnectPostNamespacedPodAttach', \@params);
  }
  
  sub ConnectPostNamespacedPodExec {
    my ($self, @params) = @_;
    $self->_invoke_versioned('ConnectPostNamespacedPodExec', \@params);
  }
  
  sub ConnectPostNamespacedPodPortforward {
    my ($self, @params) = @_;
    $self->_invoke_versioned('ConnectPostNamespacedPodPortforward', \@params);
  }
  
  sub ConnectPostNamespacedPodProxy {
    my ($self, @params) = @_;
    $self->_invoke_versioned('ConnectPostNamespacedPodProxy', \@params);
  }
  
  sub ConnectPostNamespacedPodProxyWithPath {
    my ($self, @params) = @_;
    $self->_invoke_versioned('ConnectPostNamespacedPodProxyWithPath', \@params);
  }
  
  sub ConnectPostNamespacedServiceProxy {
    my ($self, @params) = @_;
    $self->_invoke_versioned('ConnectPostNamespacedServiceProxy', \@params);
  }
  
  sub ConnectPostNamespacedServiceProxyWithPath {
    my ($self, @params) = @_;
    $self->_invoke_versioned('ConnectPostNamespacedServiceProxyWithPath', \@params);
  }
  
  sub ConnectPostNodeProxy {
    my ($self, @params) = @_;
    $self->_invoke_versioned('ConnectPostNodeProxy', \@params);
  }
  
  sub ConnectPostNodeProxyWithPath {
    my ($self, @params) = @_;
    $self->_invoke_versioned('ConnectPostNodeProxyWithPath', \@params);
  }
  
  sub ConnectPutNamespacedPodProxy {
    my ($self, @params) = @_;
    $self->_invoke_versioned('ConnectPutNamespacedPodProxy', \@params);
  }
  
  sub ConnectPutNamespacedPodProxyWithPath {
    my ($self, @params) = @_;
    $self->_invoke_versioned('ConnectPutNamespacedPodProxyWithPath', \@params);
  }
  
  sub ConnectPutNamespacedServiceProxy {
    my ($self, @params) = @_;
    $self->_invoke_versioned('ConnectPutNamespacedServiceProxy', \@params);
  }
  
  sub ConnectPutNamespacedServiceProxyWithPath {
    my ($self, @params) = @_;
    $self->_invoke_versioned('ConnectPutNamespacedServiceProxyWithPath', \@params);
  }
  
  sub ConnectPutNodeProxy {
    my ($self, @params) = @_;
    $self->_invoke_versioned('ConnectPutNodeProxy', \@params);
  }
  
  sub ConnectPutNodeProxyWithPath {
    my ($self, @params) = @_;
    $self->_invoke_versioned('ConnectPutNodeProxyWithPath', \@params);
  }
  
  sub CreateNamespace {
    my ($self, @params) = @_;
    $self->_invoke_versioned('CreateNamespace', \@params);
  }
  
  sub CreateNamespacedBinding {
    my ($self, @params) = @_;
    $self->_invoke_versioned('CreateNamespacedBinding', \@params);
  }
  
  sub CreateNamespacedConfigMap {
    my ($self, @params) = @_;
    $self->_invoke_versioned('CreateNamespacedConfigMap', \@params);
  }
  
  sub CreateNamespacedEndpoints {
    my ($self, @params) = @_;
    $self->_invoke_versioned('CreateNamespacedEndpoints', \@params);
  }
  
  sub CreateNamespacedEvent {
    my ($self, @params) = @_;
    $self->_invoke_versioned('CreateNamespacedEvent', \@params);
  }
  
  sub CreateNamespacedLimitRange {
    my ($self, @params) = @_;
    $self->_invoke_versioned('CreateNamespacedLimitRange', \@params);
  }
  
  sub CreateNamespacedPersistentVolumeClaim {
    my ($self, @params) = @_;
    $self->_invoke_versioned('CreateNamespacedPersistentVolumeClaim', \@params);
  }
  
  sub CreateNamespacedPod {
    my ($self, @params) = @_;
    $self->_invoke_versioned('CreateNamespacedPod', \@params);
  }
  
  sub CreateNamespacedPodBinding {
    my ($self, @params) = @_;
    $self->_invoke_versioned('CreateNamespacedPodBinding', \@params);
  }
  
  sub CreateNamespacedPodEviction {
    my ($self, @params) = @_;
    $self->_invoke_versioned('CreateNamespacedPodEviction', \@params);
  }
  
  sub CreateNamespacedPodTemplate {
    my ($self, @params) = @_;
    $self->_invoke_versioned('CreateNamespacedPodTemplate', \@params);
  }
  
  sub CreateNamespacedReplicationController {
    my ($self, @params) = @_;
    $self->_invoke_versioned('CreateNamespacedReplicationController', \@params);
  }
  
  sub CreateNamespacedResourceQuota {
    my ($self, @params) = @_;
    $self->_invoke_versioned('CreateNamespacedResourceQuota', \@params);
  }
  
  sub CreateNamespacedSecret {
    my ($self, @params) = @_;
    $self->_invoke_versioned('CreateNamespacedSecret', \@params);
  }
  
  sub CreateNamespacedService {
    my ($self, @params) = @_;
    $self->_invoke_versioned('CreateNamespacedService', \@params);
  }
  
  sub CreateNamespacedServiceAccount {
    my ($self, @params) = @_;
    $self->_invoke_versioned('CreateNamespacedServiceAccount', \@params);
  }
  
  sub CreateNode {
    my ($self, @params) = @_;
    $self->_invoke_versioned('CreateNode', \@params);
  }
  
  sub CreatePersistentVolume {
    my ($self, @params) = @_;
    $self->_invoke_versioned('CreatePersistentVolume', \@params);
  }
  
  sub DeleteCollectionNamespacedConfigMap {
    my ($self, @params) = @_;
    $self->_invoke_versioned('DeleteCollectionNamespacedConfigMap', \@params);
  }
  
  sub DeleteCollectionNamespacedEndpoints {
    my ($self, @params) = @_;
    $self->_invoke_versioned('DeleteCollectionNamespacedEndpoints', \@params);
  }
  
  sub DeleteCollectionNamespacedEvent {
    my ($self, @params) = @_;
    $self->_invoke_versioned('DeleteCollectionNamespacedEvent', \@params);
  }
  
  sub DeleteCollectionNamespacedLimitRange {
    my ($self, @params) = @_;
    $self->_invoke_versioned('DeleteCollectionNamespacedLimitRange', \@params);
  }
  
  sub DeleteCollectionNamespacedPersistentVolumeClaim {
    my ($self, @params) = @_;
    $self->_invoke_versioned('DeleteCollectionNamespacedPersistentVolumeClaim', \@params);
  }
  
  sub DeleteCollectionNamespacedPod {
    my ($self, @params) = @_;
    $self->_invoke_versioned('DeleteCollectionNamespacedPod', \@params);
  }
  
  sub DeleteCollectionNamespacedPodTemplate {
    my ($self, @params) = @_;
    $self->_invoke_versioned('DeleteCollectionNamespacedPodTemplate', \@params);
  }
  
  sub DeleteCollectionNamespacedReplicationController {
    my ($self, @params) = @_;
    $self->_invoke_versioned('DeleteCollectionNamespacedReplicationController', \@params);
  }
  
  sub DeleteCollectionNamespacedResourceQuota {
    my ($self, @params) = @_;
    $self->_invoke_versioned('DeleteCollectionNamespacedResourceQuota', \@params);
  }
  
  sub DeleteCollectionNamespacedSecret {
    my ($self, @params) = @_;
    $self->_invoke_versioned('DeleteCollectionNamespacedSecret', \@params);
  }
  
  sub DeleteCollectionNamespacedServiceAccount {
    my ($self, @params) = @_;
    $self->_invoke_versioned('DeleteCollectionNamespacedServiceAccount', \@params);
  }
  
  sub DeleteCollectionNode {
    my ($self, @params) = @_;
    $self->_invoke_versioned('DeleteCollectionNode', \@params);
  }
  
  sub DeleteCollectionPersistentVolume {
    my ($self, @params) = @_;
    $self->_invoke_versioned('DeleteCollectionPersistentVolume', \@params);
  }
  
  sub DeleteNamespace {
    my ($self, @params) = @_;
    $self->_invoke_versioned('DeleteNamespace', \@params);
  }
  
  sub DeleteNamespacedConfigMap {
    my ($self, @params) = @_;
    $self->_invoke_versioned('DeleteNamespacedConfigMap', \@params);
  }
  
  sub DeleteNamespacedEndpoints {
    my ($self, @params) = @_;
    $self->_invoke_versioned('DeleteNamespacedEndpoints', \@params);
  }
  
  sub DeleteNamespacedEvent {
    my ($self, @params) = @_;
    $self->_invoke_versioned('DeleteNamespacedEvent', \@params);
  }
  
  sub DeleteNamespacedLimitRange {
    my ($self, @params) = @_;
    $self->_invoke_versioned('DeleteNamespacedLimitRange', \@params);
  }
  
  sub DeleteNamespacedPersistentVolumeClaim {
    my ($self, @params) = @_;
    $self->_invoke_versioned('DeleteNamespacedPersistentVolumeClaim', \@params);
  }
  
  sub DeleteNamespacedPod {
    my ($self, @params) = @_;
    $self->_invoke_versioned('DeleteNamespacedPod', \@params);
  }
  
  sub DeleteNamespacedPodTemplate {
    my ($self, @params) = @_;
    $self->_invoke_versioned('DeleteNamespacedPodTemplate', \@params);
  }
  
  sub DeleteNamespacedReplicationController {
    my ($self, @params) = @_;
    $self->_invoke_versioned('DeleteNamespacedReplicationController', \@params);
  }
  
  sub DeleteNamespacedResourceQuota {
    my ($self, @params) = @_;
    $self->_invoke_versioned('DeleteNamespacedResourceQuota', \@params);
  }
  
  sub DeleteNamespacedSecret {
    my ($self, @params) = @_;
    $self->_invoke_versioned('DeleteNamespacedSecret', \@params);
  }
  
  sub DeleteNamespacedService {
    my ($self, @params) = @_;
    $self->_invoke_versioned('DeleteNamespacedService', \@params);
  }
  
  sub DeleteNamespacedServiceAccount {
    my ($self, @params) = @_;
    $self->_invoke_versioned('DeleteNamespacedServiceAccount', \@params);
  }
  
  sub DeleteNode {
    my ($self, @params) = @_;
    $self->_invoke_versioned('DeleteNode', \@params);
  }
  
  sub DeletePersistentVolume {
    my ($self, @params) = @_;
    $self->_invoke_versioned('DeletePersistentVolume', \@params);
  }
  
  sub GetAPIResources {
    my ($self, @params) = @_;
    $self->_invoke_versioned('GetAPIResources', \@params);
  }
  
  sub GetCoreAPIVersions {
    my ($self, @params) = @_;
    $self->_invoke_unversioned('GetCoreAPIVersions', \@params);
  }
  
  sub ListComponentStatus {
    my ($self, @params) = @_;
    $self->_invoke_versioned('ListComponentStatus', \@params);
  }
  
  sub ListConfigMapForAllNamespaces {
    my ($self, @params) = @_;
    $self->_invoke_versioned('ListConfigMapForAllNamespaces', \@params);
  }
  
  sub ListEndpointsForAllNamespaces {
    my ($self, @params) = @_;
    $self->_invoke_versioned('ListEndpointsForAllNamespaces', \@params);
  }
  
  sub ListEventForAllNamespaces {
    my ($self, @params) = @_;
    $self->_invoke_versioned('ListEventForAllNamespaces', \@params);
  }
  
  sub ListLimitRangeForAllNamespaces {
    my ($self, @params) = @_;
    $self->_invoke_versioned('ListLimitRangeForAllNamespaces', \@params);
  }
  
  sub ListNamespace {
    my ($self, @params) = @_;
    $self->_invoke_versioned('ListNamespace', \@params);
  }
  
  sub ListNamespacedConfigMap {
    my ($self, @params) = @_;
    $self->_invoke_versioned('ListNamespacedConfigMap', \@params);
  }
  
  sub ListNamespacedEndpoints {
    my ($self, @params) = @_;
    $self->_invoke_versioned('ListNamespacedEndpoints', \@params);
  }
  
  sub ListNamespacedEvent {
    my ($self, @params) = @_;
    $self->_invoke_versioned('ListNamespacedEvent', \@params);
  }
  
  sub ListNamespacedLimitRange {
    my ($self, @params) = @_;
    $self->_invoke_versioned('ListNamespacedLimitRange', \@params);
  }
  
  sub ListNamespacedPersistentVolumeClaim {
    my ($self, @params) = @_;
    $self->_invoke_versioned('ListNamespacedPersistentVolumeClaim', \@params);
  }
  
  sub ListNamespacedPod {
    my ($self, @params) = @_;
    $self->_invoke_versioned('ListNamespacedPod', \@params);
  }
  
  sub ListNamespacedPodTemplate {
    my ($self, @params) = @_;
    $self->_invoke_versioned('ListNamespacedPodTemplate', \@params);
  }
  
  sub ListNamespacedReplicationController {
    my ($self, @params) = @_;
    $self->_invoke_versioned('ListNamespacedReplicationController', \@params);
  }
  
  sub ListNamespacedResourceQuota {
    my ($self, @params) = @_;
    $self->_invoke_versioned('ListNamespacedResourceQuota', \@params);
  }
  
  sub ListNamespacedSecret {
    my ($self, @params) = @_;
    $self->_invoke_versioned('ListNamespacedSecret', \@params);
  }
  
  sub ListNamespacedService {
    my ($self, @params) = @_;
    $self->_invoke_versioned('ListNamespacedService', \@params);
  }
  
  sub ListNamespacedServiceAccount {
    my ($self, @params) = @_;
    $self->_invoke_versioned('ListNamespacedServiceAccount', \@params);
  }
  
  sub ListNode {
    my ($self, @params) = @_;
    $self->_invoke_versioned('ListNode', \@params);
  }
  
  sub ListPersistentVolume {
    my ($self, @params) = @_;
    $self->_invoke_versioned('ListPersistentVolume', \@params);
  }
  
  sub ListPersistentVolumeClaimForAllNamespaces {
    my ($self, @params) = @_;
    $self->_invoke_versioned('ListPersistentVolumeClaimForAllNamespaces', \@params);
  }
  
  sub ListPodForAllNamespaces {
    my ($self, @params) = @_;
    $self->_invoke_versioned('ListPodForAllNamespaces', \@params);
  }
  
  sub ListPodTemplateForAllNamespaces {
    my ($self, @params) = @_;
    $self->_invoke_versioned('ListPodTemplateForAllNamespaces', \@params);
  }
  
  sub ListReplicationControllerForAllNamespaces {
    my ($self, @params) = @_;
    $self->_invoke_versioned('ListReplicationControllerForAllNamespaces', \@params);
  }
  
  sub ListResourceQuotaForAllNamespaces {
    my ($self, @params) = @_;
    $self->_invoke_versioned('ListResourceQuotaForAllNamespaces', \@params);
  }
  
  sub ListSecretForAllNamespaces {
    my ($self, @params) = @_;
    $self->_invoke_versioned('ListSecretForAllNamespaces', \@params);
  }
  
  sub ListServiceAccountForAllNamespaces {
    my ($self, @params) = @_;
    $self->_invoke_versioned('ListServiceAccountForAllNamespaces', \@params);
  }
  
  sub ListServiceForAllNamespaces {
    my ($self, @params) = @_;
    $self->_invoke_versioned('ListServiceForAllNamespaces', \@params);
  }
  
  sub PatchNamespace {
    my ($self, @params) = @_;
    $self->_invoke_versioned('PatchNamespace', \@params);
  }
  
  sub PatchNamespaceStatus {
    my ($self, @params) = @_;
    $self->_invoke_versioned('PatchNamespaceStatus', \@params);
  }
  
  sub PatchNamespacedConfigMap {
    my ($self, @params) = @_;
    $self->_invoke_versioned('PatchNamespacedConfigMap', \@params);
  }
  
  sub PatchNamespacedEndpoints {
    my ($self, @params) = @_;
    $self->_invoke_versioned('PatchNamespacedEndpoints', \@params);
  }
  
  sub PatchNamespacedEvent {
    my ($self, @params) = @_;
    $self->_invoke_versioned('PatchNamespacedEvent', \@params);
  }
  
  sub PatchNamespacedLimitRange {
    my ($self, @params) = @_;
    $self->_invoke_versioned('PatchNamespacedLimitRange', \@params);
  }
  
  sub PatchNamespacedPersistentVolumeClaim {
    my ($self, @params) = @_;
    $self->_invoke_versioned('PatchNamespacedPersistentVolumeClaim', \@params);
  }
  
  sub PatchNamespacedPersistentVolumeClaimStatus {
    my ($self, @params) = @_;
    $self->_invoke_versioned('PatchNamespacedPersistentVolumeClaimStatus', \@params);
  }
  
  sub PatchNamespacedPod {
    my ($self, @params) = @_;
    $self->_invoke_versioned('PatchNamespacedPod', \@params);
  }
  
  sub PatchNamespacedPodStatus {
    my ($self, @params) = @_;
    $self->_invoke_versioned('PatchNamespacedPodStatus', \@params);
  }
  
  sub PatchNamespacedPodTemplate {
    my ($self, @params) = @_;
    $self->_invoke_versioned('PatchNamespacedPodTemplate', \@params);
  }
  
  sub PatchNamespacedReplicationController {
    my ($self, @params) = @_;
    $self->_invoke_versioned('PatchNamespacedReplicationController', \@params);
  }
  
  sub PatchNamespacedReplicationControllerScale {
    my ($self, @params) = @_;
    $self->_invoke_versioned('PatchNamespacedReplicationControllerScale', \@params);
  }
  
  sub PatchNamespacedReplicationControllerStatus {
    my ($self, @params) = @_;
    $self->_invoke_versioned('PatchNamespacedReplicationControllerStatus', \@params);
  }
  
  sub PatchNamespacedResourceQuota {
    my ($self, @params) = @_;
    $self->_invoke_versioned('PatchNamespacedResourceQuota', \@params);
  }
  
  sub PatchNamespacedResourceQuotaStatus {
    my ($self, @params) = @_;
    $self->_invoke_versioned('PatchNamespacedResourceQuotaStatus', \@params);
  }
  
  sub PatchNamespacedSecret {
    my ($self, @params) = @_;
    $self->_invoke_versioned('PatchNamespacedSecret', \@params);
  }
  
  sub PatchNamespacedService {
    my ($self, @params) = @_;
    $self->_invoke_versioned('PatchNamespacedService', \@params);
  }
  
  sub PatchNamespacedServiceAccount {
    my ($self, @params) = @_;
    $self->_invoke_versioned('PatchNamespacedServiceAccount', \@params);
  }
  
  sub PatchNamespacedServiceStatus {
    my ($self, @params) = @_;
    $self->_invoke_versioned('PatchNamespacedServiceStatus', \@params);
  }
  
  sub PatchNode {
    my ($self, @params) = @_;
    $self->_invoke_versioned('PatchNode', \@params);
  }
  
  sub PatchNodeStatus {
    my ($self, @params) = @_;
    $self->_invoke_versioned('PatchNodeStatus', \@params);
  }
  
  sub PatchPersistentVolume {
    my ($self, @params) = @_;
    $self->_invoke_versioned('PatchPersistentVolume', \@params);
  }
  
  sub PatchPersistentVolumeStatus {
    my ($self, @params) = @_;
    $self->_invoke_versioned('PatchPersistentVolumeStatus', \@params);
  }
  
  sub ReadComponentStatus {
    my ($self, @params) = @_;
    $self->_invoke_versioned('ReadComponentStatus', \@params);
  }
  
  sub ReadNamespace {
    my ($self, @params) = @_;
    $self->_invoke_versioned('ReadNamespace', \@params);
  }
  
  sub ReadNamespaceStatus {
    my ($self, @params) = @_;
    $self->_invoke_versioned('ReadNamespaceStatus', \@params);
  }
  
  sub ReadNamespacedConfigMap {
    my ($self, @params) = @_;
    $self->_invoke_versioned('ReadNamespacedConfigMap', \@params);
  }
  
  sub ReadNamespacedEndpoints {
    my ($self, @params) = @_;
    $self->_invoke_versioned('ReadNamespacedEndpoints', \@params);
  }
  
  sub ReadNamespacedEvent {
    my ($self, @params) = @_;
    $self->_invoke_versioned('ReadNamespacedEvent', \@params);
  }
  
  sub ReadNamespacedLimitRange {
    my ($self, @params) = @_;
    $self->_invoke_versioned('ReadNamespacedLimitRange', \@params);
  }
  
  sub ReadNamespacedPersistentVolumeClaim {
    my ($self, @params) = @_;
    $self->_invoke_versioned('ReadNamespacedPersistentVolumeClaim', \@params);
  }
  
  sub ReadNamespacedPersistentVolumeClaimStatus {
    my ($self, @params) = @_;
    $self->_invoke_versioned('ReadNamespacedPersistentVolumeClaimStatus', \@params);
  }
  
  sub ReadNamespacedPod {
    my ($self, @params) = @_;
    $self->_invoke_versioned('ReadNamespacedPod', \@params);
  }
  
  sub ReadNamespacedPodLog {
    my ($self, @params) = @_;
    $self->_invoke_versioned('ReadNamespacedPodLog', \@params);
  }
  
  sub ReadNamespacedPodStatus {
    my ($self, @params) = @_;
    $self->_invoke_versioned('ReadNamespacedPodStatus', \@params);
  }
  
  sub ReadNamespacedPodTemplate {
    my ($self, @params) = @_;
    $self->_invoke_versioned('ReadNamespacedPodTemplate', \@params);
  }
  
  sub ReadNamespacedReplicationController {
    my ($self, @params) = @_;
    $self->_invoke_versioned('ReadNamespacedReplicationController', \@params);
  }
  
  sub ReadNamespacedReplicationControllerScale {
    my ($self, @params) = @_;
    $self->_invoke_versioned('ReadNamespacedReplicationControllerScale', \@params);
  }
  
  sub ReadNamespacedReplicationControllerStatus {
    my ($self, @params) = @_;
    $self->_invoke_versioned('ReadNamespacedReplicationControllerStatus', \@params);
  }
  
  sub ReadNamespacedResourceQuota {
    my ($self, @params) = @_;
    $self->_invoke_versioned('ReadNamespacedResourceQuota', \@params);
  }
  
  sub ReadNamespacedResourceQuotaStatus {
    my ($self, @params) = @_;
    $self->_invoke_versioned('ReadNamespacedResourceQuotaStatus', \@params);
  }
  
  sub ReadNamespacedSecret {
    my ($self, @params) = @_;
    $self->_invoke_versioned('ReadNamespacedSecret', \@params);
  }
  
  sub ReadNamespacedService {
    my ($self, @params) = @_;
    $self->_invoke_versioned('ReadNamespacedService', \@params);
  }
  
  sub ReadNamespacedServiceAccount {
    my ($self, @params) = @_;
    $self->_invoke_versioned('ReadNamespacedServiceAccount', \@params);
  }
  
  sub ReadNamespacedServiceStatus {
    my ($self, @params) = @_;
    $self->_invoke_versioned('ReadNamespacedServiceStatus', \@params);
  }
  
  sub ReadNode {
    my ($self, @params) = @_;
    $self->_invoke_versioned('ReadNode', \@params);
  }
  
  sub ReadNodeStatus {
    my ($self, @params) = @_;
    $self->_invoke_versioned('ReadNodeStatus', \@params);
  }
  
  sub ReadPersistentVolume {
    my ($self, @params) = @_;
    $self->_invoke_versioned('ReadPersistentVolume', \@params);
  }
  
  sub ReadPersistentVolumeStatus {
    my ($self, @params) = @_;
    $self->_invoke_versioned('ReadPersistentVolumeStatus', \@params);
  }
  
  sub ReplaceNamespace {
    my ($self, @params) = @_;
    $self->_invoke_versioned('ReplaceNamespace', \@params);
  }
  
  sub ReplaceNamespaceFinalize {
    my ($self, @params) = @_;
    $self->_invoke_versioned('ReplaceNamespaceFinalize', \@params);
  }
  
  sub ReplaceNamespaceStatus {
    my ($self, @params) = @_;
    $self->_invoke_versioned('ReplaceNamespaceStatus', \@params);
  }
  
  sub ReplaceNamespacedConfigMap {
    my ($self, @params) = @_;
    $self->_invoke_versioned('ReplaceNamespacedConfigMap', \@params);
  }
  
  sub ReplaceNamespacedEndpoints {
    my ($self, @params) = @_;
    $self->_invoke_versioned('ReplaceNamespacedEndpoints', \@params);
  }
  
  sub ReplaceNamespacedEvent {
    my ($self, @params) = @_;
    $self->_invoke_versioned('ReplaceNamespacedEvent', \@params);
  }
  
  sub ReplaceNamespacedLimitRange {
    my ($self, @params) = @_;
    $self->_invoke_versioned('ReplaceNamespacedLimitRange', \@params);
  }
  
  sub ReplaceNamespacedPersistentVolumeClaim {
    my ($self, @params) = @_;
    $self->_invoke_versioned('ReplaceNamespacedPersistentVolumeClaim', \@params);
  }
  
  sub ReplaceNamespacedPersistentVolumeClaimStatus {
    my ($self, @params) = @_;
    $self->_invoke_versioned('ReplaceNamespacedPersistentVolumeClaimStatus', \@params);
  }
  
  sub ReplaceNamespacedPod {
    my ($self, @params) = @_;
    $self->_invoke_versioned('ReplaceNamespacedPod', \@params);
  }
  
  sub ReplaceNamespacedPodStatus {
    my ($self, @params) = @_;
    $self->_invoke_versioned('ReplaceNamespacedPodStatus', \@params);
  }
  
  sub ReplaceNamespacedPodTemplate {
    my ($self, @params) = @_;
    $self->_invoke_versioned('ReplaceNamespacedPodTemplate', \@params);
  }
  
  sub ReplaceNamespacedReplicationController {
    my ($self, @params) = @_;
    $self->_invoke_versioned('ReplaceNamespacedReplicationController', \@params);
  }
  
  sub ReplaceNamespacedReplicationControllerScale {
    my ($self, @params) = @_;
    $self->_invoke_versioned('ReplaceNamespacedReplicationControllerScale', \@params);
  }
  
  sub ReplaceNamespacedReplicationControllerStatus {
    my ($self, @params) = @_;
    $self->_invoke_versioned('ReplaceNamespacedReplicationControllerStatus', \@params);
  }
  
  sub ReplaceNamespacedResourceQuota {
    my ($self, @params) = @_;
    $self->_invoke_versioned('ReplaceNamespacedResourceQuota', \@params);
  }
  
  sub ReplaceNamespacedResourceQuotaStatus {
    my ($self, @params) = @_;
    $self->_invoke_versioned('ReplaceNamespacedResourceQuotaStatus', \@params);
  }
  
  sub ReplaceNamespacedSecret {
    my ($self, @params) = @_;
    $self->_invoke_versioned('ReplaceNamespacedSecret', \@params);
  }
  
  sub ReplaceNamespacedService {
    my ($self, @params) = @_;
    $self->_invoke_versioned('ReplaceNamespacedService', \@params);
  }
  
  sub ReplaceNamespacedServiceAccount {
    my ($self, @params) = @_;
    $self->_invoke_versioned('ReplaceNamespacedServiceAccount', \@params);
  }
  
  sub ReplaceNamespacedServiceStatus {
    my ($self, @params) = @_;
    $self->_invoke_versioned('ReplaceNamespacedServiceStatus', \@params);
  }
  
  sub ReplaceNode {
    my ($self, @params) = @_;
    $self->_invoke_versioned('ReplaceNode', \@params);
  }
  
  sub ReplaceNodeStatus {
    my ($self, @params) = @_;
    $self->_invoke_versioned('ReplaceNodeStatus', \@params);
  }
  
  sub ReplacePersistentVolume {
    my ($self, @params) = @_;
    $self->_invoke_versioned('ReplacePersistentVolume', \@params);
  }
  
  sub ReplacePersistentVolumeStatus {
    my ($self, @params) = @_;
    $self->_invoke_versioned('ReplacePersistentVolumeStatus', \@params);
  }
  
  sub WatchConfigMapListForAllNamespaces {
    my ($self, @params) = @_;
    $self->_invoke_versioned('WatchConfigMapListForAllNamespaces', \@params);
  }
  
  sub WatchEndpointsListForAllNamespaces {
    my ($self, @params) = @_;
    $self->_invoke_versioned('WatchEndpointsListForAllNamespaces', \@params);
  }
  
  sub WatchEventListForAllNamespaces {
    my ($self, @params) = @_;
    $self->_invoke_versioned('WatchEventListForAllNamespaces', \@params);
  }
  
  sub WatchLimitRangeListForAllNamespaces {
    my ($self, @params) = @_;
    $self->_invoke_versioned('WatchLimitRangeListForAllNamespaces', \@params);
  }
  
  sub WatchNamespace {
    my ($self, @params) = @_;
    $self->_invoke_versioned('WatchNamespace', \@params);
  }
  
  sub WatchNamespaceList {
    my ($self, @params) = @_;
    $self->_invoke_versioned('WatchNamespaceList', \@params);
  }
  
  sub WatchNamespacedConfigMap {
    my ($self, @params) = @_;
    $self->_invoke_versioned('WatchNamespacedConfigMap', \@params);
  }
  
  sub WatchNamespacedConfigMapList {
    my ($self, @params) = @_;
    $self->_invoke_versioned('WatchNamespacedConfigMapList', \@params);
  }
  
  sub WatchNamespacedEndpoints {
    my ($self, @params) = @_;
    $self->_invoke_versioned('WatchNamespacedEndpoints', \@params);
  }
  
  sub WatchNamespacedEndpointsList {
    my ($self, @params) = @_;
    $self->_invoke_versioned('WatchNamespacedEndpointsList', \@params);
  }
  
  sub WatchNamespacedEvent {
    my ($self, @params) = @_;
    $self->_invoke_versioned('WatchNamespacedEvent', \@params);
  }
  
  sub WatchNamespacedEventList {
    my ($self, @params) = @_;
    $self->_invoke_versioned('WatchNamespacedEventList', \@params);
  }
  
  sub WatchNamespacedLimitRange {
    my ($self, @params) = @_;
    $self->_invoke_versioned('WatchNamespacedLimitRange', \@params);
  }
  
  sub WatchNamespacedLimitRangeList {
    my ($self, @params) = @_;
    $self->_invoke_versioned('WatchNamespacedLimitRangeList', \@params);
  }
  
  sub WatchNamespacedPersistentVolumeClaim {
    my ($self, @params) = @_;
    $self->_invoke_versioned('WatchNamespacedPersistentVolumeClaim', \@params);
  }
  
  sub WatchNamespacedPersistentVolumeClaimList {
    my ($self, @params) = @_;
    $self->_invoke_versioned('WatchNamespacedPersistentVolumeClaimList', \@params);
  }
  
  sub WatchNamespacedPod {
    my ($self, @params) = @_;
    $self->_invoke_versioned('WatchNamespacedPod', \@params);
  }
  
  sub WatchNamespacedPodList {
    my ($self, @params) = @_;
    $self->_invoke_versioned('WatchNamespacedPodList', \@params);
  }
  
  sub WatchNamespacedPodTemplate {
    my ($self, @params) = @_;
    $self->_invoke_versioned('WatchNamespacedPodTemplate', \@params);
  }
  
  sub WatchNamespacedPodTemplateList {
    my ($self, @params) = @_;
    $self->_invoke_versioned('WatchNamespacedPodTemplateList', \@params);
  }
  
  sub WatchNamespacedReplicationController {
    my ($self, @params) = @_;
    $self->_invoke_versioned('WatchNamespacedReplicationController', \@params);
  }
  
  sub WatchNamespacedReplicationControllerList {
    my ($self, @params) = @_;
    $self->_invoke_versioned('WatchNamespacedReplicationControllerList', \@params);
  }
  
  sub WatchNamespacedResourceQuota {
    my ($self, @params) = @_;
    $self->_invoke_versioned('WatchNamespacedResourceQuota', \@params);
  }
  
  sub WatchNamespacedResourceQuotaList {
    my ($self, @params) = @_;
    $self->_invoke_versioned('WatchNamespacedResourceQuotaList', \@params);
  }
  
  sub WatchNamespacedSecret {
    my ($self, @params) = @_;
    $self->_invoke_versioned('WatchNamespacedSecret', \@params);
  }
  
  sub WatchNamespacedSecretList {
    my ($self, @params) = @_;
    $self->_invoke_versioned('WatchNamespacedSecretList', \@params);
  }
  
  sub WatchNamespacedService {
    my ($self, @params) = @_;
    $self->_invoke_versioned('WatchNamespacedService', \@params);
  }
  
  sub WatchNamespacedServiceAccount {
    my ($self, @params) = @_;
    $self->_invoke_versioned('WatchNamespacedServiceAccount', \@params);
  }
  
  sub WatchNamespacedServiceAccountList {
    my ($self, @params) = @_;
    $self->_invoke_versioned('WatchNamespacedServiceAccountList', \@params);
  }
  
  sub WatchNamespacedServiceList {
    my ($self, @params) = @_;
    $self->_invoke_versioned('WatchNamespacedServiceList', \@params);
  }
  
  sub WatchNode {
    my ($self, @params) = @_;
    $self->_invoke_versioned('WatchNode', \@params);
  }
  
  sub WatchNodeList {
    my ($self, @params) = @_;
    $self->_invoke_versioned('WatchNodeList', \@params);
  }
  
  sub WatchPersistentVolume {
    my ($self, @params) = @_;
    $self->_invoke_versioned('WatchPersistentVolume', \@params);
  }
  
  sub WatchPersistentVolumeClaimListForAllNamespaces {
    my ($self, @params) = @_;
    $self->_invoke_versioned('WatchPersistentVolumeClaimListForAllNamespaces', \@params);
  }
  
  sub WatchPersistentVolumeList {
    my ($self, @params) = @_;
    $self->_invoke_versioned('WatchPersistentVolumeList', \@params);
  }
  
  sub WatchPodListForAllNamespaces {
    my ($self, @params) = @_;
    $self->_invoke_versioned('WatchPodListForAllNamespaces', \@params);
  }
  
  sub WatchPodTemplateListForAllNamespaces {
    my ($self, @params) = @_;
    $self->_invoke_versioned('WatchPodTemplateListForAllNamespaces', \@params);
  }
  
  sub WatchReplicationControllerListForAllNamespaces {
    my ($self, @params) = @_;
    $self->_invoke_versioned('WatchReplicationControllerListForAllNamespaces', \@params);
  }
  
  sub WatchResourceQuotaListForAllNamespaces {
    my ($self, @params) = @_;
    $self->_invoke_versioned('WatchResourceQuotaListForAllNamespaces', \@params);
  }
  
  sub WatchSecretListForAllNamespaces {
    my ($self, @params) = @_;
    $self->_invoke_versioned('WatchSecretListForAllNamespaces', \@params);
  }
  
  sub WatchServiceAccountListForAllNamespaces {
    my ($self, @params) = @_;
    $self->_invoke_versioned('WatchServiceAccountListForAllNamespaces', \@params);
  }
  
  sub WatchServiceListForAllNamespaces {
    my ($self, @params) = @_;
    $self->_invoke_versioned('WatchServiceListForAllNamespaces', \@params);
  }
  
1;
