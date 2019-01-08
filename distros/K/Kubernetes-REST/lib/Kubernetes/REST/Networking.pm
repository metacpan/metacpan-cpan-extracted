package Kubernetes::REST::Networking;
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
      method => $self->api_version . '::Networking::' . $method,
      params => $params,
      server => $self->server,
      credentials => $self->credentials,
    );
    my $req = $self->param_converter->params2request($call);
    my $result = $self->io->call($call, $req);
    return $self->result_parser->result2return($call, $req, $result);
  }

  
  sub CreateNamespacedNetworkPolicy {
    my ($self, @params) = @_;
    $self->_invoke_versioned('CreateNamespacedNetworkPolicy', \@params);
  }
  
  sub DeleteCollectionNamespacedNetworkPolicy {
    my ($self, @params) = @_;
    $self->_invoke_versioned('DeleteCollectionNamespacedNetworkPolicy', \@params);
  }
  
  sub DeleteNamespacedNetworkPolicy {
    my ($self, @params) = @_;
    $self->_invoke_versioned('DeleteNamespacedNetworkPolicy', \@params);
  }
  
  sub GetAPIResources {
    my ($self, @params) = @_;
    $self->_invoke_versioned('GetAPIResources', \@params);
  }
  
  sub GetNetworkingAPIGroup {
    my ($self, @params) = @_;
    $self->_invoke_unversioned('GetNetworkingAPIGroup', \@params);
  }
  
  sub ListNamespacedNetworkPolicy {
    my ($self, @params) = @_;
    $self->_invoke_versioned('ListNamespacedNetworkPolicy', \@params);
  }
  
  sub ListNetworkPolicyForAllNamespaces {
    my ($self, @params) = @_;
    $self->_invoke_versioned('ListNetworkPolicyForAllNamespaces', \@params);
  }
  
  sub PatchNamespacedNetworkPolicy {
    my ($self, @params) = @_;
    $self->_invoke_versioned('PatchNamespacedNetworkPolicy', \@params);
  }
  
  sub ReadNamespacedNetworkPolicy {
    my ($self, @params) = @_;
    $self->_invoke_versioned('ReadNamespacedNetworkPolicy', \@params);
  }
  
  sub ReplaceNamespacedNetworkPolicy {
    my ($self, @params) = @_;
    $self->_invoke_versioned('ReplaceNamespacedNetworkPolicy', \@params);
  }
  
  sub WatchNamespacedNetworkPolicy {
    my ($self, @params) = @_;
    $self->_invoke_versioned('WatchNamespacedNetworkPolicy', \@params);
  }
  
  sub WatchNamespacedNetworkPolicyList {
    my ($self, @params) = @_;
    $self->_invoke_versioned('WatchNamespacedNetworkPolicyList', \@params);
  }
  
  sub WatchNetworkPolicyListForAllNamespaces {
    my ($self, @params) = @_;
    $self->_invoke_versioned('WatchNetworkPolicyListForAllNamespaces', \@params);
  }
  
1;
