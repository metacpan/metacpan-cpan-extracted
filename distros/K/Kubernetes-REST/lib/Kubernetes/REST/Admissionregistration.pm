package Kubernetes::REST::Admissionregistration;
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
      method => $self->api_version . '::Admissionregistration::' . $method,
      params => $params,
      server => $self->server,
      credentials => $self->credentials,
    );
    my $req = $self->param_converter->params2request($call);
    my $result = $self->io->call($call, $req);
    return $self->result_parser->result2return($call, $req, $result);
  }

  
  sub CreateInitializerConfiguration {
    my ($self, @params) = @_;
    $self->_invoke_versioned('CreateInitializerConfiguration', \@params);
  }
  
  sub CreateMutatingWebhookConfiguration {
    my ($self, @params) = @_;
    $self->_invoke_versioned('CreateMutatingWebhookConfiguration', \@params);
  }
  
  sub CreateValidatingWebhookConfiguration {
    my ($self, @params) = @_;
    $self->_invoke_versioned('CreateValidatingWebhookConfiguration', \@params);
  }
  
  sub DeleteCollectionInitializerConfiguration {
    my ($self, @params) = @_;
    $self->_invoke_versioned('DeleteCollectionInitializerConfiguration', \@params);
  }
  
  sub DeleteCollectionMutatingWebhookConfiguration {
    my ($self, @params) = @_;
    $self->_invoke_versioned('DeleteCollectionMutatingWebhookConfiguration', \@params);
  }
  
  sub DeleteCollectionValidatingWebhookConfiguration {
    my ($self, @params) = @_;
    $self->_invoke_versioned('DeleteCollectionValidatingWebhookConfiguration', \@params);
  }
  
  sub DeleteInitializerConfiguration {
    my ($self, @params) = @_;
    $self->_invoke_versioned('DeleteInitializerConfiguration', \@params);
  }
  
  sub DeleteMutatingWebhookConfiguration {
    my ($self, @params) = @_;
    $self->_invoke_versioned('DeleteMutatingWebhookConfiguration', \@params);
  }
  
  sub DeleteValidatingWebhookConfiguration {
    my ($self, @params) = @_;
    $self->_invoke_versioned('DeleteValidatingWebhookConfiguration', \@params);
  }
  
  sub GetAPIResources {
    my ($self, @params) = @_;
    $self->_invoke_versioned('GetAPIResources', \@params);
  }
  
  sub GetAdmissionregistrationAPIGroup {
    my ($self, @params) = @_;
    $self->_invoke_unversioned('GetAdmissionregistrationAPIGroup', \@params);
  }
  
  sub ListInitializerConfiguration {
    my ($self, @params) = @_;
    $self->_invoke_versioned('ListInitializerConfiguration', \@params);
  }
  
  sub ListMutatingWebhookConfiguration {
    my ($self, @params) = @_;
    $self->_invoke_versioned('ListMutatingWebhookConfiguration', \@params);
  }
  
  sub ListValidatingWebhookConfiguration {
    my ($self, @params) = @_;
    $self->_invoke_versioned('ListValidatingWebhookConfiguration', \@params);
  }
  
  sub PatchInitializerConfiguration {
    my ($self, @params) = @_;
    $self->_invoke_versioned('PatchInitializerConfiguration', \@params);
  }
  
  sub PatchMutatingWebhookConfiguration {
    my ($self, @params) = @_;
    $self->_invoke_versioned('PatchMutatingWebhookConfiguration', \@params);
  }
  
  sub PatchValidatingWebhookConfiguration {
    my ($self, @params) = @_;
    $self->_invoke_versioned('PatchValidatingWebhookConfiguration', \@params);
  }
  
  sub ReadInitializerConfiguration {
    my ($self, @params) = @_;
    $self->_invoke_versioned('ReadInitializerConfiguration', \@params);
  }
  
  sub ReadMutatingWebhookConfiguration {
    my ($self, @params) = @_;
    $self->_invoke_versioned('ReadMutatingWebhookConfiguration', \@params);
  }
  
  sub ReadValidatingWebhookConfiguration {
    my ($self, @params) = @_;
    $self->_invoke_versioned('ReadValidatingWebhookConfiguration', \@params);
  }
  
  sub ReplaceInitializerConfiguration {
    my ($self, @params) = @_;
    $self->_invoke_versioned('ReplaceInitializerConfiguration', \@params);
  }
  
  sub ReplaceMutatingWebhookConfiguration {
    my ($self, @params) = @_;
    $self->_invoke_versioned('ReplaceMutatingWebhookConfiguration', \@params);
  }
  
  sub ReplaceValidatingWebhookConfiguration {
    my ($self, @params) = @_;
    $self->_invoke_versioned('ReplaceValidatingWebhookConfiguration', \@params);
  }
  
  sub WatchInitializerConfiguration {
    my ($self, @params) = @_;
    $self->_invoke_versioned('WatchInitializerConfiguration', \@params);
  }
  
  sub WatchInitializerConfigurationList {
    my ($self, @params) = @_;
    $self->_invoke_versioned('WatchInitializerConfigurationList', \@params);
  }
  
  sub WatchMutatingWebhookConfiguration {
    my ($self, @params) = @_;
    $self->_invoke_versioned('WatchMutatingWebhookConfiguration', \@params);
  }
  
  sub WatchMutatingWebhookConfigurationList {
    my ($self, @params) = @_;
    $self->_invoke_versioned('WatchMutatingWebhookConfigurationList', \@params);
  }
  
  sub WatchValidatingWebhookConfiguration {
    my ($self, @params) = @_;
    $self->_invoke_versioned('WatchValidatingWebhookConfiguration', \@params);
  }
  
  sub WatchValidatingWebhookConfigurationList {
    my ($self, @params) = @_;
    $self->_invoke_versioned('WatchValidatingWebhookConfigurationList', \@params);
  }
  
1;
