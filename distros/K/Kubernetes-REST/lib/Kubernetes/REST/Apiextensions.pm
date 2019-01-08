package Kubernetes::REST::Apiextensions;
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
      method => $self->api_version . '::Apiextensions::' . $method,
      params => $params,
      server => $self->server,
      credentials => $self->credentials,
    );
    my $req = $self->param_converter->params2request($call);
    my $result = $self->io->call($call, $req);
    return $self->result_parser->result2return($call, $req, $result);
  }

  
  sub CreateCustomResourceDefinition {
    my ($self, @params) = @_;
    $self->_invoke_versioned('CreateCustomResourceDefinition', \@params);
  }
  
  sub DeleteCollectionCustomResourceDefinition {
    my ($self, @params) = @_;
    $self->_invoke_versioned('DeleteCollectionCustomResourceDefinition', \@params);
  }
  
  sub DeleteCustomResourceDefinition {
    my ($self, @params) = @_;
    $self->_invoke_versioned('DeleteCustomResourceDefinition', \@params);
  }
  
  sub GetAPIResources {
    my ($self, @params) = @_;
    $self->_invoke_versioned('GetAPIResources', \@params);
  }
  
  sub GetApiextensionsAPIGroup {
    my ($self, @params) = @_;
    $self->_invoke_unversioned('GetApiextensionsAPIGroup', \@params);
  }
  
  sub ListCustomResourceDefinition {
    my ($self, @params) = @_;
    $self->_invoke_versioned('ListCustomResourceDefinition', \@params);
  }
  
  sub PatchCustomResourceDefinition {
    my ($self, @params) = @_;
    $self->_invoke_versioned('PatchCustomResourceDefinition', \@params);
  }
  
  sub PatchCustomResourceDefinitionStatus {
    my ($self, @params) = @_;
    $self->_invoke_versioned('PatchCustomResourceDefinitionStatus', \@params);
  }
  
  sub ReadCustomResourceDefinition {
    my ($self, @params) = @_;
    $self->_invoke_versioned('ReadCustomResourceDefinition', \@params);
  }
  
  sub ReadCustomResourceDefinitionStatus {
    my ($self, @params) = @_;
    $self->_invoke_versioned('ReadCustomResourceDefinitionStatus', \@params);
  }
  
  sub ReplaceCustomResourceDefinition {
    my ($self, @params) = @_;
    $self->_invoke_versioned('ReplaceCustomResourceDefinition', \@params);
  }
  
  sub ReplaceCustomResourceDefinitionStatus {
    my ($self, @params) = @_;
    $self->_invoke_versioned('ReplaceCustomResourceDefinitionStatus', \@params);
  }
  
  sub WatchCustomResourceDefinition {
    my ($self, @params) = @_;
    $self->_invoke_versioned('WatchCustomResourceDefinition', \@params);
  }
  
  sub WatchCustomResourceDefinitionList {
    my ($self, @params) = @_;
    $self->_invoke_versioned('WatchCustomResourceDefinitionList', \@params);
  }
  
1;
