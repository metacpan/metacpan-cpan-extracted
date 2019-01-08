package Kubernetes::REST::Coordination;
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
      method => $self->api_version . '::Coordination::' . $method,
      params => $params,
      server => $self->server,
      credentials => $self->credentials,
    );
    my $req = $self->param_converter->params2request($call);
    my $result = $self->io->call($call, $req);
    return $self->result_parser->result2return($call, $req, $result);
  }

  
  sub CreateNamespacedLease {
    my ($self, @params) = @_;
    $self->_invoke_versioned('CreateNamespacedLease', \@params);
  }
  
  sub DeleteCollectionNamespacedLease {
    my ($self, @params) = @_;
    $self->_invoke_versioned('DeleteCollectionNamespacedLease', \@params);
  }
  
  sub DeleteNamespacedLease {
    my ($self, @params) = @_;
    $self->_invoke_versioned('DeleteNamespacedLease', \@params);
  }
  
  sub GetAPIResources {
    my ($self, @params) = @_;
    $self->_invoke_versioned('GetAPIResources', \@params);
  }
  
  sub GetCoordinationAPIGroup {
    my ($self, @params) = @_;
    $self->_invoke_unversioned('GetCoordinationAPIGroup', \@params);
  }
  
  sub ListLeaseForAllNamespaces {
    my ($self, @params) = @_;
    $self->_invoke_versioned('ListLeaseForAllNamespaces', \@params);
  }
  
  sub ListNamespacedLease {
    my ($self, @params) = @_;
    $self->_invoke_versioned('ListNamespacedLease', \@params);
  }
  
  sub PatchNamespacedLease {
    my ($self, @params) = @_;
    $self->_invoke_versioned('PatchNamespacedLease', \@params);
  }
  
  sub ReadNamespacedLease {
    my ($self, @params) = @_;
    $self->_invoke_versioned('ReadNamespacedLease', \@params);
  }
  
  sub ReplaceNamespacedLease {
    my ($self, @params) = @_;
    $self->_invoke_versioned('ReplaceNamespacedLease', \@params);
  }
  
  sub WatchLeaseListForAllNamespaces {
    my ($self, @params) = @_;
    $self->_invoke_versioned('WatchLeaseListForAllNamespaces', \@params);
  }
  
  sub WatchNamespacedLease {
    my ($self, @params) = @_;
    $self->_invoke_versioned('WatchNamespacedLease', \@params);
  }
  
  sub WatchNamespacedLeaseList {
    my ($self, @params) = @_;
    $self->_invoke_versioned('WatchNamespacedLeaseList', \@params);
  }
  
1;
