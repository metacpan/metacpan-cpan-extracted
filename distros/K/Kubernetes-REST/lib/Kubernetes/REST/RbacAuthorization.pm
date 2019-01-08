package Kubernetes::REST::RbacAuthorization;
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
      method => $self->api_version . '::RbacAuthorization::' . $method,
      params => $params,
      server => $self->server,
      credentials => $self->credentials,
    );
    my $req = $self->param_converter->params2request($call);
    my $result = $self->io->call($call, $req);
    return $self->result_parser->result2return($call, $req, $result);
  }

  
  sub CreateClusterRole {
    my ($self, @params) = @_;
    $self->_invoke_versioned('CreateClusterRole', \@params);
  }
  
  sub CreateClusterRoleBinding {
    my ($self, @params) = @_;
    $self->_invoke_versioned('CreateClusterRoleBinding', \@params);
  }
  
  sub CreateNamespacedRole {
    my ($self, @params) = @_;
    $self->_invoke_versioned('CreateNamespacedRole', \@params);
  }
  
  sub CreateNamespacedRoleBinding {
    my ($self, @params) = @_;
    $self->_invoke_versioned('CreateNamespacedRoleBinding', \@params);
  }
  
  sub DeleteClusterRole {
    my ($self, @params) = @_;
    $self->_invoke_versioned('DeleteClusterRole', \@params);
  }
  
  sub DeleteClusterRoleBinding {
    my ($self, @params) = @_;
    $self->_invoke_versioned('DeleteClusterRoleBinding', \@params);
  }
  
  sub DeleteCollectionClusterRole {
    my ($self, @params) = @_;
    $self->_invoke_versioned('DeleteCollectionClusterRole', \@params);
  }
  
  sub DeleteCollectionClusterRoleBinding {
    my ($self, @params) = @_;
    $self->_invoke_versioned('DeleteCollectionClusterRoleBinding', \@params);
  }
  
  sub DeleteCollectionNamespacedRole {
    my ($self, @params) = @_;
    $self->_invoke_versioned('DeleteCollectionNamespacedRole', \@params);
  }
  
  sub DeleteCollectionNamespacedRoleBinding {
    my ($self, @params) = @_;
    $self->_invoke_versioned('DeleteCollectionNamespacedRoleBinding', \@params);
  }
  
  sub DeleteNamespacedRole {
    my ($self, @params) = @_;
    $self->_invoke_versioned('DeleteNamespacedRole', \@params);
  }
  
  sub DeleteNamespacedRoleBinding {
    my ($self, @params) = @_;
    $self->_invoke_versioned('DeleteNamespacedRoleBinding', \@params);
  }
  
  sub GetAPIResources {
    my ($self, @params) = @_;
    $self->_invoke_versioned('GetAPIResources', \@params);
  }
  
  sub GetRbacAuthorizationAPIGroup {
    my ($self, @params) = @_;
    $self->_invoke_unversioned('GetRbacAuthorizationAPIGroup', \@params);
  }
  
  sub ListClusterRole {
    my ($self, @params) = @_;
    $self->_invoke_versioned('ListClusterRole', \@params);
  }
  
  sub ListClusterRoleBinding {
    my ($self, @params) = @_;
    $self->_invoke_versioned('ListClusterRoleBinding', \@params);
  }
  
  sub ListNamespacedRole {
    my ($self, @params) = @_;
    $self->_invoke_versioned('ListNamespacedRole', \@params);
  }
  
  sub ListNamespacedRoleBinding {
    my ($self, @params) = @_;
    $self->_invoke_versioned('ListNamespacedRoleBinding', \@params);
  }
  
  sub ListRoleBindingForAllNamespaces {
    my ($self, @params) = @_;
    $self->_invoke_versioned('ListRoleBindingForAllNamespaces', \@params);
  }
  
  sub ListRoleForAllNamespaces {
    my ($self, @params) = @_;
    $self->_invoke_versioned('ListRoleForAllNamespaces', \@params);
  }
  
  sub PatchClusterRole {
    my ($self, @params) = @_;
    $self->_invoke_versioned('PatchClusterRole', \@params);
  }
  
  sub PatchClusterRoleBinding {
    my ($self, @params) = @_;
    $self->_invoke_versioned('PatchClusterRoleBinding', \@params);
  }
  
  sub PatchNamespacedRole {
    my ($self, @params) = @_;
    $self->_invoke_versioned('PatchNamespacedRole', \@params);
  }
  
  sub PatchNamespacedRoleBinding {
    my ($self, @params) = @_;
    $self->_invoke_versioned('PatchNamespacedRoleBinding', \@params);
  }
  
  sub ReadClusterRole {
    my ($self, @params) = @_;
    $self->_invoke_versioned('ReadClusterRole', \@params);
  }
  
  sub ReadClusterRoleBinding {
    my ($self, @params) = @_;
    $self->_invoke_versioned('ReadClusterRoleBinding', \@params);
  }
  
  sub ReadNamespacedRole {
    my ($self, @params) = @_;
    $self->_invoke_versioned('ReadNamespacedRole', \@params);
  }
  
  sub ReadNamespacedRoleBinding {
    my ($self, @params) = @_;
    $self->_invoke_versioned('ReadNamespacedRoleBinding', \@params);
  }
  
  sub ReplaceClusterRole {
    my ($self, @params) = @_;
    $self->_invoke_versioned('ReplaceClusterRole', \@params);
  }
  
  sub ReplaceClusterRoleBinding {
    my ($self, @params) = @_;
    $self->_invoke_versioned('ReplaceClusterRoleBinding', \@params);
  }
  
  sub ReplaceNamespacedRole {
    my ($self, @params) = @_;
    $self->_invoke_versioned('ReplaceNamespacedRole', \@params);
  }
  
  sub ReplaceNamespacedRoleBinding {
    my ($self, @params) = @_;
    $self->_invoke_versioned('ReplaceNamespacedRoleBinding', \@params);
  }
  
  sub WatchClusterRole {
    my ($self, @params) = @_;
    $self->_invoke_versioned('WatchClusterRole', \@params);
  }
  
  sub WatchClusterRoleBinding {
    my ($self, @params) = @_;
    $self->_invoke_versioned('WatchClusterRoleBinding', \@params);
  }
  
  sub WatchClusterRoleBindingList {
    my ($self, @params) = @_;
    $self->_invoke_versioned('WatchClusterRoleBindingList', \@params);
  }
  
  sub WatchClusterRoleList {
    my ($self, @params) = @_;
    $self->_invoke_versioned('WatchClusterRoleList', \@params);
  }
  
  sub WatchNamespacedRole {
    my ($self, @params) = @_;
    $self->_invoke_versioned('WatchNamespacedRole', \@params);
  }
  
  sub WatchNamespacedRoleBinding {
    my ($self, @params) = @_;
    $self->_invoke_versioned('WatchNamespacedRoleBinding', \@params);
  }
  
  sub WatchNamespacedRoleBindingList {
    my ($self, @params) = @_;
    $self->_invoke_versioned('WatchNamespacedRoleBindingList', \@params);
  }
  
  sub WatchNamespacedRoleList {
    my ($self, @params) = @_;
    $self->_invoke_versioned('WatchNamespacedRoleList', \@params);
  }
  
  sub WatchRoleBindingListForAllNamespaces {
    my ($self, @params) = @_;
    $self->_invoke_versioned('WatchRoleBindingListForAllNamespaces', \@params);
  }
  
  sub WatchRoleListForAllNamespaces {
    my ($self, @params) = @_;
    $self->_invoke_versioned('WatchRoleListForAllNamespaces', \@params);
  }
  
1;
