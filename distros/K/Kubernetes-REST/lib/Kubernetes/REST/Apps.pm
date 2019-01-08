package Kubernetes::REST::Apps;
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
      method => $self->api_version . '::Apps::' . $method,
      params => $params,
      server => $self->server,
      credentials => $self->credentials,
    );
    my $req = $self->param_converter->params2request($call);
    my $result = $self->io->call($call, $req);
    return $self->result_parser->result2return($call, $req, $result);
  }

  
  sub CreateNamespacedControllerRevision {
    my ($self, @params) = @_;
    $self->_invoke_versioned('CreateNamespacedControllerRevision', \@params);
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
  
  sub CreateNamespacedReplicaSet {
    my ($self, @params) = @_;
    $self->_invoke_versioned('CreateNamespacedReplicaSet', \@params);
  }
  
  sub CreateNamespacedStatefulSet {
    my ($self, @params) = @_;
    $self->_invoke_versioned('CreateNamespacedStatefulSet', \@params);
  }
  
  sub DeleteCollectionNamespacedControllerRevision {
    my ($self, @params) = @_;
    $self->_invoke_versioned('DeleteCollectionNamespacedControllerRevision', \@params);
  }
  
  sub DeleteCollectionNamespacedDaemonSet {
    my ($self, @params) = @_;
    $self->_invoke_versioned('DeleteCollectionNamespacedDaemonSet', \@params);
  }
  
  sub DeleteCollectionNamespacedDeployment {
    my ($self, @params) = @_;
    $self->_invoke_versioned('DeleteCollectionNamespacedDeployment', \@params);
  }
  
  sub DeleteCollectionNamespacedReplicaSet {
    my ($self, @params) = @_;
    $self->_invoke_versioned('DeleteCollectionNamespacedReplicaSet', \@params);
  }
  
  sub DeleteCollectionNamespacedStatefulSet {
    my ($self, @params) = @_;
    $self->_invoke_versioned('DeleteCollectionNamespacedStatefulSet', \@params);
  }
  
  sub DeleteNamespacedControllerRevision {
    my ($self, @params) = @_;
    $self->_invoke_versioned('DeleteNamespacedControllerRevision', \@params);
  }
  
  sub DeleteNamespacedDaemonSet {
    my ($self, @params) = @_;
    $self->_invoke_versioned('DeleteNamespacedDaemonSet', \@params);
  }
  
  sub DeleteNamespacedDeployment {
    my ($self, @params) = @_;
    $self->_invoke_versioned('DeleteNamespacedDeployment', \@params);
  }
  
  sub DeleteNamespacedReplicaSet {
    my ($self, @params) = @_;
    $self->_invoke_versioned('DeleteNamespacedReplicaSet', \@params);
  }
  
  sub DeleteNamespacedStatefulSet {
    my ($self, @params) = @_;
    $self->_invoke_versioned('DeleteNamespacedStatefulSet', \@params);
  }
  
  sub GetAPIResources {
    my ($self, @params) = @_;
    $self->_invoke_versioned('GetAPIResources', \@params);
  }
  
  sub GetAppsAPIGroup {
    my ($self, @params) = @_;
    $self->_invoke_unversioned('GetAppsAPIGroup', \@params);
  }
  
  sub ListControllerRevisionForAllNamespaces {
    my ($self, @params) = @_;
    $self->_invoke_versioned('ListControllerRevisionForAllNamespaces', \@params);
  }
  
  sub ListDaemonSetForAllNamespaces {
    my ($self, @params) = @_;
    $self->_invoke_versioned('ListDaemonSetForAllNamespaces', \@params);
  }
  
  sub ListDeploymentForAllNamespaces {
    my ($self, @params) = @_;
    $self->_invoke_versioned('ListDeploymentForAllNamespaces', \@params);
  }
  
  sub ListNamespacedControllerRevision {
    my ($self, @params) = @_;
    $self->_invoke_versioned('ListNamespacedControllerRevision', \@params);
  }
  
  sub ListNamespacedDaemonSet {
    my ($self, @params) = @_;
    $self->_invoke_versioned('ListNamespacedDaemonSet', \@params);
  }
  
  sub ListNamespacedDeployment {
    my ($self, @params) = @_;
    $self->_invoke_versioned('ListNamespacedDeployment', \@params);
  }
  
  sub ListNamespacedReplicaSet {
    my ($self, @params) = @_;
    $self->_invoke_versioned('ListNamespacedReplicaSet', \@params);
  }
  
  sub ListNamespacedStatefulSet {
    my ($self, @params) = @_;
    $self->_invoke_versioned('ListNamespacedStatefulSet', \@params);
  }
  
  sub ListReplicaSetForAllNamespaces {
    my ($self, @params) = @_;
    $self->_invoke_versioned('ListReplicaSetForAllNamespaces', \@params);
  }
  
  sub ListStatefulSetForAllNamespaces {
    my ($self, @params) = @_;
    $self->_invoke_versioned('ListStatefulSetForAllNamespaces', \@params);
  }
  
  sub PatchNamespacedControllerRevision {
    my ($self, @params) = @_;
    $self->_invoke_versioned('PatchNamespacedControllerRevision', \@params);
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
  
  sub PatchNamespacedStatefulSet {
    my ($self, @params) = @_;
    $self->_invoke_versioned('PatchNamespacedStatefulSet', \@params);
  }
  
  sub PatchNamespacedStatefulSetScale {
    my ($self, @params) = @_;
    $self->_invoke_versioned('PatchNamespacedStatefulSetScale', \@params);
  }
  
  sub PatchNamespacedStatefulSetStatus {
    my ($self, @params) = @_;
    $self->_invoke_versioned('PatchNamespacedStatefulSetStatus', \@params);
  }
  
  sub ReadNamespacedControllerRevision {
    my ($self, @params) = @_;
    $self->_invoke_versioned('ReadNamespacedControllerRevision', \@params);
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
  
  sub ReadNamespacedStatefulSet {
    my ($self, @params) = @_;
    $self->_invoke_versioned('ReadNamespacedStatefulSet', \@params);
  }
  
  sub ReadNamespacedStatefulSetScale {
    my ($self, @params) = @_;
    $self->_invoke_versioned('ReadNamespacedStatefulSetScale', \@params);
  }
  
  sub ReadNamespacedStatefulSetStatus {
    my ($self, @params) = @_;
    $self->_invoke_versioned('ReadNamespacedStatefulSetStatus', \@params);
  }
  
  sub ReplaceNamespacedControllerRevision {
    my ($self, @params) = @_;
    $self->_invoke_versioned('ReplaceNamespacedControllerRevision', \@params);
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
  
  sub ReplaceNamespacedStatefulSet {
    my ($self, @params) = @_;
    $self->_invoke_versioned('ReplaceNamespacedStatefulSet', \@params);
  }
  
  sub ReplaceNamespacedStatefulSetScale {
    my ($self, @params) = @_;
    $self->_invoke_versioned('ReplaceNamespacedStatefulSetScale', \@params);
  }
  
  sub ReplaceNamespacedStatefulSetStatus {
    my ($self, @params) = @_;
    $self->_invoke_versioned('ReplaceNamespacedStatefulSetStatus', \@params);
  }
  
  sub WatchControllerRevisionListForAllNamespaces {
    my ($self, @params) = @_;
    $self->_invoke_versioned('WatchControllerRevisionListForAllNamespaces', \@params);
  }
  
  sub WatchDaemonSetListForAllNamespaces {
    my ($self, @params) = @_;
    $self->_invoke_versioned('WatchDaemonSetListForAllNamespaces', \@params);
  }
  
  sub WatchDeploymentListForAllNamespaces {
    my ($self, @params) = @_;
    $self->_invoke_versioned('WatchDeploymentListForAllNamespaces', \@params);
  }
  
  sub WatchNamespacedControllerRevision {
    my ($self, @params) = @_;
    $self->_invoke_versioned('WatchNamespacedControllerRevision', \@params);
  }
  
  sub WatchNamespacedControllerRevisionList {
    my ($self, @params) = @_;
    $self->_invoke_versioned('WatchNamespacedControllerRevisionList', \@params);
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
  
  sub WatchNamespacedReplicaSet {
    my ($self, @params) = @_;
    $self->_invoke_versioned('WatchNamespacedReplicaSet', \@params);
  }
  
  sub WatchNamespacedReplicaSetList {
    my ($self, @params) = @_;
    $self->_invoke_versioned('WatchNamespacedReplicaSetList', \@params);
  }
  
  sub WatchNamespacedStatefulSet {
    my ($self, @params) = @_;
    $self->_invoke_versioned('WatchNamespacedStatefulSet', \@params);
  }
  
  sub WatchNamespacedStatefulSetList {
    my ($self, @params) = @_;
    $self->_invoke_versioned('WatchNamespacedStatefulSetList', \@params);
  }
  
  sub WatchReplicaSetListForAllNamespaces {
    my ($self, @params) = @_;
    $self->_invoke_versioned('WatchReplicaSetListForAllNamespaces', \@params);
  }
  
  sub WatchStatefulSetListForAllNamespaces {
    my ($self, @params) = @_;
    $self->_invoke_versioned('WatchStatefulSetListForAllNamespaces', \@params);
  }
  
1;
