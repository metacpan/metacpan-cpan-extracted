package Kubernetes::REST::Events;
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
      method => $self->api_version . '::Events::' . $method,
      params => $params,
      server => $self->server,
      credentials => $self->credentials,
    );
    my $req = $self->param_converter->params2request($call);
    my $result = $self->io->call($call, $req);
    return $self->result_parser->result2return($call, $req, $result);
  }

  
  sub CreateNamespacedEvent {
    my ($self, @params) = @_;
    $self->_invoke_versioned('CreateNamespacedEvent', \@params);
  }
  
  sub DeleteCollectionNamespacedEvent {
    my ($self, @params) = @_;
    $self->_invoke_versioned('DeleteCollectionNamespacedEvent', \@params);
  }
  
  sub DeleteNamespacedEvent {
    my ($self, @params) = @_;
    $self->_invoke_versioned('DeleteNamespacedEvent', \@params);
  }
  
  sub GetAPIResources {
    my ($self, @params) = @_;
    $self->_invoke_versioned('GetAPIResources', \@params);
  }
  
  sub GetEventsAPIGroup {
    my ($self, @params) = @_;
    $self->_invoke_unversioned('GetEventsAPIGroup', \@params);
  }
  
  sub ListEventForAllNamespaces {
    my ($self, @params) = @_;
    $self->_invoke_versioned('ListEventForAllNamespaces', \@params);
  }
  
  sub ListNamespacedEvent {
    my ($self, @params) = @_;
    $self->_invoke_versioned('ListNamespacedEvent', \@params);
  }
  
  sub PatchNamespacedEvent {
    my ($self, @params) = @_;
    $self->_invoke_versioned('PatchNamespacedEvent', \@params);
  }
  
  sub ReadNamespacedEvent {
    my ($self, @params) = @_;
    $self->_invoke_versioned('ReadNamespacedEvent', \@params);
  }
  
  sub ReplaceNamespacedEvent {
    my ($self, @params) = @_;
    $self->_invoke_versioned('ReplaceNamespacedEvent', \@params);
  }
  
  sub WatchEventListForAllNamespaces {
    my ($self, @params) = @_;
    $self->_invoke_versioned('WatchEventListForAllNamespaces', \@params);
  }
  
  sub WatchNamespacedEvent {
    my ($self, @params) = @_;
    $self->_invoke_versioned('WatchNamespacedEvent', \@params);
  }
  
  sub WatchNamespacedEventList {
    my ($self, @params) = @_;
    $self->_invoke_versioned('WatchNamespacedEventList', \@params);
  }
  
1;
