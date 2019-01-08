package Kubernetes::REST::Scheduling;
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
      method => $self->api_version . '::Scheduling::' . $method,
      params => $params,
      server => $self->server,
      credentials => $self->credentials,
    );
    my $req = $self->param_converter->params2request($call);
    my $result = $self->io->call($call, $req);
    return $self->result_parser->result2return($call, $req, $result);
  }

  
  sub CreatePriorityClass {
    my ($self, @params) = @_;
    $self->_invoke_versioned('CreatePriorityClass', \@params);
  }
  
  sub DeleteCollectionPriorityClass {
    my ($self, @params) = @_;
    $self->_invoke_versioned('DeleteCollectionPriorityClass', \@params);
  }
  
  sub DeletePriorityClass {
    my ($self, @params) = @_;
    $self->_invoke_versioned('DeletePriorityClass', \@params);
  }
  
  sub GetAPIResources {
    my ($self, @params) = @_;
    $self->_invoke_versioned('GetAPIResources', \@params);
  }
  
  sub GetSchedulingAPIGroup {
    my ($self, @params) = @_;
    $self->_invoke_unversioned('GetSchedulingAPIGroup', \@params);
  }
  
  sub ListPriorityClass {
    my ($self, @params) = @_;
    $self->_invoke_versioned('ListPriorityClass', \@params);
  }
  
  sub PatchPriorityClass {
    my ($self, @params) = @_;
    $self->_invoke_versioned('PatchPriorityClass', \@params);
  }
  
  sub ReadPriorityClass {
    my ($self, @params) = @_;
    $self->_invoke_versioned('ReadPriorityClass', \@params);
  }
  
  sub ReplacePriorityClass {
    my ($self, @params) = @_;
    $self->_invoke_versioned('ReplacePriorityClass', \@params);
  }
  
  sub WatchPriorityClass {
    my ($self, @params) = @_;
    $self->_invoke_versioned('WatchPriorityClass', \@params);
  }
  
  sub WatchPriorityClassList {
    my ($self, @params) = @_;
    $self->_invoke_versioned('WatchPriorityClassList', \@params);
  }
  
1;
