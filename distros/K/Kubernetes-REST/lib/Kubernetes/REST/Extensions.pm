package Kubernetes::REST::Extensions;
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
      method => $self->api_version . '::Extensions::' . $method,
      params => $params,
      server => $self->server,
      credentials => $self->credentials,
    );
    my $req = $self->param_converter->params2request($call);
    my $result = $self->io->call($call, $req);
    return $self->result_parser->result2return($call, $req, $result);
  }

  
  sub CreateNamespacedDaemonSet {
    my ($self, @params) = @_;
    $self->_invoke_versioned('CreateNamespacedDaemonSet', \@params);
  }
  
  sub CreateNamespacedDeployment {
    my ($self, @params) = @_;
    $self->_invoke_versioned('CreateNamespacedDeployment', \@params);
  }
  
  sub CreateNamespacedDeploymentRollback {
    my ($self, @params) = @_;
    $self->_invoke_versioned('CreateNamespacedDeploymentRollback', \@params);
  }
  
  sub CreateNamespacedIngress {
    my ($self, @params) = @_;
    $self->_invoke_versioned('CreateNamespacedIngress', \@params);
  }
  
  sub CreateNamespacedNetworkPolicy {
    my ($self, @params) = @_;
    $self->_invoke_versioned('CreateNamespacedNetworkPolicy', \@params);
  }
  
  sub CreateNamespacedReplicaSet {
    my ($self, @params) = @_;
    $self->_invoke_versioned('CreateNamespacedReplicaSet', \@params);
  }
  
  sub CreatePodSecurityPolicy {
    my ($self, @params) = @_;
    $self->_invoke_versioned('CreatePodSecurityPolicy', \@params);
  }
  
  sub DeleteCollectionNamespacedDaemonSet {
    my ($self, @params) = @_;
    $self->_invoke_versioned('DeleteCollectionNamespacedDaemonSet', \@params);
  }
  
  sub DeleteCollectionNamespacedDeployment {
    my ($self, @params) = @_;
    $self->_invoke_versioned('DeleteCollectionNamespacedDeployment', \@params);
  }
  
  sub DeleteCollectionNamespacedIngress {
    my ($self, @params) = @_;
    $self->_invoke_versioned('DeleteCollectionNamespacedIngress', \@params);
  }
  
  sub DeleteCollectionNamespacedNetworkPolicy {
    my ($self, @params) = @_;
    $self->_invoke_versioned('DeleteCollectionNamespacedNetworkPolicy', \@params);
  }
  
  sub DeleteCollectionNamespacedReplicaSet {
    my ($self, @params) = @_;
    $self->_invoke_versioned('DeleteCollectionNamespacedReplicaSet', \@params);
  }
  
  sub DeleteCollectionPodSecurityPolicy {
    my ($self, @params) = @_;
    $self->_invoke_versioned('DeleteCollectionPodSecurityPolicy', \@params);
  }
  
  sub DeleteNamespacedDaemonSet {
    my ($self, @params) = @_;
    $self->_invoke_versioned('DeleteNamespacedDaemonSet', \@params);
  }
  
  sub DeleteNamespacedDeployment {
    my ($self, @params) = @_;
    $self->_invoke_versioned('DeleteNamespacedDeployment', \@params);
  }
  
  sub DeleteNamespacedIngress {
    my ($self, @params) = @_;
    $self->_invoke_versioned('DeleteNamespacedIngress', \@params);
  }
  
  sub DeleteNamespacedNetworkPolicy {
    my ($self, @params) = @_;
    $self->_invoke_versioned('DeleteNamespacedNetworkPolicy', \@params);
  }
  
  sub DeleteNamespacedReplicaSet {
    my ($self, @params) = @_;
    $self->_invoke_versioned('DeleteNamespacedReplicaSet', \@params);
  }
  
  sub DeletePodSecurityPolicy {
    my ($self, @params) = @_;
    $self->_invoke_versioned('DeletePodSecurityPolicy', \@params);
  }
  
  sub GetAPIResources {
    my ($self, @params) = @_;
    $self->_invoke_versioned('GetAPIResources', \@params);
  }
  
  sub GetExtensionsAPIGroup {
    my ($self, @params) = @_;
    $self->_invoke_unversioned('GetExtensionsAPIGroup', \@params);
  }
  
  sub ListDaemonSetForAllNamespaces {
    my ($self, @params) = @_;
    $self->_invoke_versioned('ListDaemonSetForAllNamespaces', \@params);
  }
  
  sub ListDeploymentForAllNamespaces {
    my ($self, @params) = @_;
    $self->_invoke_versioned('ListDeploymentForAllNamespaces', \@params);
  }
  
  sub ListIngressForAllNamespaces {
    my ($self, @params) = @_;
    $self->_invoke_versioned('ListIngressForAllNamespaces', \@params);
  }
  
  sub ListNamespacedDaemonSet {
    my ($self, @params) = @_;
    $self->_invoke_versioned('ListNamespacedDaemonSet', \@params);
  }
  
  sub ListNamespacedDeployment {
    my ($self, @params) = @_;
    $self->_invoke_versioned('ListNamespacedDeployment', \@params);
  }
  
  sub ListNamespacedIngress {
    my ($self, @params) = @_;
    $self->_invoke_versioned('ListNamespacedIngress', \@params);
  }
  
  sub ListNamespacedNetworkPolicy {
    my ($self, @params) = @_;
    $self->_invoke_versioned('ListNamespacedNetworkPolicy', \@params);
  }
  
  sub ListNamespacedReplicaSet {
    my ($self, @params) = @_;
    $self->_invoke_versioned('ListNamespacedReplicaSet', \@params);
  }
  
  sub ListNetworkPolicyForAllNamespaces {
    my ($self, @params) = @_;
    $self->_invoke_versioned('ListNetworkPolicyForAllNamespaces', \@params);
  }
  
  sub ListPodSecurityPolicy {
    my ($self, @params) = @_;
    $self->_invoke_versioned('ListPodSecurityPolicy', \@params);
  }
  
  sub ListReplicaSetForAllNamespaces {
    my ($self, @params) = @_;
    $self->_invoke_versioned('ListReplicaSetForAllNamespaces', \@params);
  }
  
  sub PatchNamespacedDaemonSet {
    my ($self, @params) = @_;
    $self->_invoke_versioned('PatchNamespacedDaemonSet', \@params);
  }
  
  sub PatchNamespacedDaemonSetStatus {
    my ($self, @params) = @_;
    $self->_invoke_versioned('PatchNamespacedDaemonSetStatus', \@params);
  }
  
  sub PatchNamespacedDeployment {
    my ($self, @params) = @_;
    $self->_invoke_versioned('PatchNamespacedDeployment', \@params);
  }
  
  sub PatchNamespacedDeploymentScale {
    my ($self, @params) = @_;
    $self->_invoke_versioned('PatchNamespacedDeploymentScale', \@params);
  }
  
  sub PatchNamespacedDeploymentStatus {
    my ($self, @params) = @_;
    $self->_invoke_versioned('PatchNamespacedDeploymentStatus', \@params);
  }
  
  sub PatchNamespacedIngress {
    my ($self, @params) = @_;
    $self->_invoke_versioned('PatchNamespacedIngress', \@params);
  }
  
  sub PatchNamespacedIngressStatus {
    my ($self, @params) = @_;
    $self->_invoke_versioned('PatchNamespacedIngressStatus', \@params);
  }
  
  sub PatchNamespacedNetworkPolicy {
    my ($self, @params) = @_;
    $self->_invoke_versioned('PatchNamespacedNetworkPolicy', \@params);
  }
  
  sub PatchNamespacedReplicaSet {
    my ($self, @params) = @_;
    $self->_invoke_versioned('PatchNamespacedReplicaSet', \@params);
  }
  
  sub PatchNamespacedReplicaSetScale {
    my ($self, @params) = @_;
    $self->_invoke_versioned('PatchNamespacedReplicaSetScale', \@params);
  }
  
  sub PatchNamespacedReplicaSetStatus {
    my ($self, @params) = @_;
    $self->_invoke_versioned('PatchNamespacedReplicaSetStatus', \@params);
  }
  
  sub PatchNamespacedReplicationControllerDummyScale {
    my ($self, @params) = @_;
    $self->_invoke_versioned('PatchNamespacedReplicationControllerDummyScale', \@params);
  }
  
  sub PatchPodSecurityPolicy {
    my ($self, @params) = @_;
    $self->_invoke_versioned('PatchPodSecurityPolicy', \@params);
  }
  
  sub ReadNamespacedDaemonSet {
    my ($self, @params) = @_;
    $self->_invoke_versioned('ReadNamespacedDaemonSet', \@params);
  }
  
  sub ReadNamespacedDaemonSetStatus {
    my ($self, @params) = @_;
    $self->_invoke_versioned('ReadNamespacedDaemonSetStatus', \@params);
  }
  
  sub ReadNamespacedDeployment {
    my ($self, @params) = @_;
    $self->_invoke_versioned('ReadNamespacedDeployment', \@params);
  }
  
  sub ReadNamespacedDeploymentScale {
    my ($self, @params) = @_;
    $self->_invoke_versioned('ReadNamespacedDeploymentScale', \@params);
  }
  
  sub ReadNamespacedDeploymentStatus {
    my ($self, @params) = @_;
    $self->_invoke_versioned('ReadNamespacedDeploymentStatus', \@params);
  }
  
  sub ReadNamespacedIngress {
    my ($self, @params) = @_;
    $self->_invoke_versioned('ReadNamespacedIngress', \@params);
  }
  
  sub ReadNamespacedIngressStatus {
    my ($self, @params) = @_;
    $self->_invoke_versioned('ReadNamespacedIngressStatus', \@params);
  }
  
  sub ReadNamespacedNetworkPolicy {
    my ($self, @params) = @_;
    $self->_invoke_versioned('ReadNamespacedNetworkPolicy', \@params);
  }
  
  sub ReadNamespacedReplicaSet {
    my ($self, @params) = @_;
    $self->_invoke_versioned('ReadNamespacedReplicaSet', \@params);
  }
  
  sub ReadNamespacedReplicaSetScale {
    my ($self, @params) = @_;
    $self->_invoke_versioned('ReadNamespacedReplicaSetScale', \@params);
  }
  
  sub ReadNamespacedReplicaSetStatus {
    my ($self, @params) = @_;
    $self->_invoke_versioned('ReadNamespacedReplicaSetStatus', \@params);
  }
  
  sub ReadNamespacedReplicationControllerDummyScale {
    my ($self, @params) = @_;
    $self->_invoke_versioned('ReadNamespacedReplicationControllerDummyScale', \@params);
  }
  
  sub ReadPodSecurityPolicy {
    my ($self, @params) = @_;
    $self->_invoke_versioned('ReadPodSecurityPolicy', \@params);
  }
  
  sub ReplaceNamespacedDaemonSet {
    my ($self, @params) = @_;
    $self->_invoke_versioned('ReplaceNamespacedDaemonSet', \@params);
  }
  
  sub ReplaceNamespacedDaemonSetStatus {
    my ($self, @params) = @_;
    $self->_invoke_versioned('ReplaceNamespacedDaemonSetStatus', \@params);
  }
  
  sub ReplaceNamespacedDeployment {
    my ($self, @params) = @_;
    $self->_invoke_versioned('ReplaceNamespacedDeployment', \@params);
  }
  
  sub ReplaceNamespacedDeploymentScale {
    my ($self, @params) = @_;
    $self->_invoke_versioned('ReplaceNamespacedDeploymentScale', \@params);
  }
  
  sub ReplaceNamespacedDeploymentStatus {
    my ($self, @params) = @_;
    $self->_invoke_versioned('ReplaceNamespacedDeploymentStatus', \@params);
  }
  
  sub ReplaceNamespacedIngress {
    my ($self, @params) = @_;
    $self->_invoke_versioned('ReplaceNamespacedIngress', \@params);
  }
  
  sub ReplaceNamespacedIngressStatus {
    my ($self, @params) = @_;
    $self->_invoke_versioned('ReplaceNamespacedIngressStatus', \@params);
  }
  
  sub ReplaceNamespacedNetworkPolicy {
    my ($self, @params) = @_;
    $self->_invoke_versioned('ReplaceNamespacedNetworkPolicy', \@params);
  }
  
  sub ReplaceNamespacedReplicaSet {
    my ($self, @params) = @_;
    $self->_invoke_versioned('ReplaceNamespacedReplicaSet', \@params);
  }
  
  sub ReplaceNamespacedReplicaSetScale {
    my ($self, @params) = @_;
    $self->_invoke_versioned('ReplaceNamespacedReplicaSetScale', \@params);
  }
  
  sub ReplaceNamespacedReplicaSetStatus {
    my ($self, @params) = @_;
    $self->_invoke_versioned('ReplaceNamespacedReplicaSetStatus', \@params);
  }
  
  sub ReplaceNamespacedReplicationControllerDummyScale {
    my ($self, @params) = @_;
    $self->_invoke_versioned('ReplaceNamespacedReplicationControllerDummyScale', \@params);
  }
  
  sub ReplacePodSecurityPolicy {
    my ($self, @params) = @_;
    $self->_invoke_versioned('ReplacePodSecurityPolicy', \@params);
  }
  
  sub WatchDaemonSetListForAllNamespaces {
    my ($self, @params) = @_;
    $self->_invoke_versioned('WatchDaemonSetListForAllNamespaces', \@params);
  }
  
  sub WatchDeploymentListForAllNamespaces {
    my ($self, @params) = @_;
    $self->_invoke_versioned('WatchDeploymentListForAllNamespaces', \@params);
  }
  
  sub WatchIngressListForAllNamespaces {
    my ($self, @params) = @_;
    $self->_invoke_versioned('WatchIngressListForAllNamespaces', \@params);
  }
  
  sub WatchNamespacedDaemonSet {
    my ($self, @params) = @_;
    $self->_invoke_versioned('WatchNamespacedDaemonSet', \@params);
  }
  
  sub WatchNamespacedDaemonSetList {
    my ($self, @params) = @_;
    $self->_invoke_versioned('WatchNamespacedDaemonSetList', \@params);
  }
  
  sub WatchNamespacedDeployment {
    my ($self, @params) = @_;
    $self->_invoke_versioned('WatchNamespacedDeployment', \@params);
  }
  
  sub WatchNamespacedDeploymentList {
    my ($self, @params) = @_;
    $self->_invoke_versioned('WatchNamespacedDeploymentList', \@params);
  }
  
  sub WatchNamespacedIngress {
    my ($self, @params) = @_;
    $self->_invoke_versioned('WatchNamespacedIngress', \@params);
  }
  
  sub WatchNamespacedIngressList {
    my ($self, @params) = @_;
    $self->_invoke_versioned('WatchNamespacedIngressList', \@params);
  }
  
  sub WatchNamespacedNetworkPolicy {
    my ($self, @params) = @_;
    $self->_invoke_versioned('WatchNamespacedNetworkPolicy', \@params);
  }
  
  sub WatchNamespacedNetworkPolicyList {
    my ($self, @params) = @_;
    $self->_invoke_versioned('WatchNamespacedNetworkPolicyList', \@params);
  }
  
  sub WatchNamespacedReplicaSet {
    my ($self, @params) = @_;
    $self->_invoke_versioned('WatchNamespacedReplicaSet', \@params);
  }
  
  sub WatchNamespacedReplicaSetList {
    my ($self, @params) = @_;
    $self->_invoke_versioned('WatchNamespacedReplicaSetList', \@params);
  }
  
  sub WatchNetworkPolicyListForAllNamespaces {
    my ($self, @params) = @_;
    $self->_invoke_versioned('WatchNetworkPolicyListForAllNamespaces', \@params);
  }
  
  sub WatchPodSecurityPolicy {
    my ($self, @params) = @_;
    $self->_invoke_versioned('WatchPodSecurityPolicy', \@params);
  }
  
  sub WatchPodSecurityPolicyList {
    my ($self, @params) = @_;
    $self->_invoke_versioned('WatchPodSecurityPolicyList', \@params);
  }
  
  sub WatchReplicaSetListForAllNamespaces {
    my ($self, @params) = @_;
    $self->_invoke_versioned('WatchReplicaSetListForAllNamespaces', \@params);
  }
  
1;
