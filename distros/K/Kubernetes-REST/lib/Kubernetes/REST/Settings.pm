package Kubernetes::REST::Settings;
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
      method => $self->api_version . '::Settings::' . $method,
      params => $params,
      server => $self->server,
      credentials => $self->credentials,
    );
    my $req = $self->param_converter->params2request($call);
    my $result = $self->io->call($call, $req);
    return $self->result_parser->result2return($call, $req, $result);
  }

  
  sub CreateNamespacedPodPreset {
    my ($self, @params) = @_;
    $self->_invoke_versioned('CreateNamespacedPodPreset', \@params);
  }
  
  sub DeleteCollectionNamespacedPodPreset {
    my ($self, @params) = @_;
    $self->_invoke_versioned('DeleteCollectionNamespacedPodPreset', \@params);
  }
  
  sub DeleteNamespacedPodPreset {
    my ($self, @params) = @_;
    $self->_invoke_versioned('DeleteNamespacedPodPreset', \@params);
  }
  
  sub GetAPIResources {
    my ($self, @params) = @_;
    $self->_invoke_versioned('GetAPIResources', \@params);
  }
  
  sub GetSettingsAPIGroup {
    my ($self, @params) = @_;
    $self->_invoke_unversioned('GetSettingsAPIGroup', \@params);
  }
  
  sub ListNamespacedPodPreset {
    my ($self, @params) = @_;
    $self->_invoke_versioned('ListNamespacedPodPreset', \@params);
  }
  
  sub ListPodPresetForAllNamespaces {
    my ($self, @params) = @_;
    $self->_invoke_versioned('ListPodPresetForAllNamespaces', \@params);
  }
  
  sub PatchNamespacedPodPreset {
    my ($self, @params) = @_;
    $self->_invoke_versioned('PatchNamespacedPodPreset', \@params);
  }
  
  sub ReadNamespacedPodPreset {
    my ($self, @params) = @_;
    $self->_invoke_versioned('ReadNamespacedPodPreset', \@params);
  }
  
  sub ReplaceNamespacedPodPreset {
    my ($self, @params) = @_;
    $self->_invoke_versioned('ReplaceNamespacedPodPreset', \@params);
  }
  
  sub WatchNamespacedPodPreset {
    my ($self, @params) = @_;
    $self->_invoke_versioned('WatchNamespacedPodPreset', \@params);
  }
  
  sub WatchNamespacedPodPresetList {
    my ($self, @params) = @_;
    $self->_invoke_versioned('WatchNamespacedPodPresetList', \@params);
  }
  
  sub WatchPodPresetListForAllNamespaces {
    my ($self, @params) = @_;
    $self->_invoke_versioned('WatchPodPresetListForAllNamespaces', \@params);
  }
  
1;
