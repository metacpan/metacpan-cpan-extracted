package Kubernetes::REST::Policy;
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
      method => $self->api_version . '::Policy::' . $method,
      params => $params,
      server => $self->server,
      credentials => $self->credentials,
    );
    my $req = $self->param_converter->params2request($call);
    my $result = $self->io->call($call, $req);
    return $self->result_parser->result2return($call, $req, $result);
  }

  
  sub CreateNamespacedPodDisruptionBudget {
    my ($self, @params) = @_;
    $self->_invoke_versioned('CreateNamespacedPodDisruptionBudget', \@params);
  }
  
  sub CreatePodSecurityPolicy {
    my ($self, @params) = @_;
    $self->_invoke_versioned('CreatePodSecurityPolicy', \@params);
  }
  
  sub DeleteCollectionNamespacedPodDisruptionBudget {
    my ($self, @params) = @_;
    $self->_invoke_versioned('DeleteCollectionNamespacedPodDisruptionBudget', \@params);
  }
  
  sub DeleteCollectionPodSecurityPolicy {
    my ($self, @params) = @_;
    $self->_invoke_versioned('DeleteCollectionPodSecurityPolicy', \@params);
  }
  
  sub DeleteNamespacedPodDisruptionBudget {
    my ($self, @params) = @_;
    $self->_invoke_versioned('DeleteNamespacedPodDisruptionBudget', \@params);
  }
  
  sub DeletePodSecurityPolicy {
    my ($self, @params) = @_;
    $self->_invoke_versioned('DeletePodSecurityPolicy', \@params);
  }
  
  sub GetAPIResources {
    my ($self, @params) = @_;
    $self->_invoke_versioned('GetAPIResources', \@params);
  }
  
  sub GetPolicyAPIGroup {
    my ($self, @params) = @_;
    $self->_invoke_unversioned('GetPolicyAPIGroup', \@params);
  }
  
  sub ListNamespacedPodDisruptionBudget {
    my ($self, @params) = @_;
    $self->_invoke_versioned('ListNamespacedPodDisruptionBudget', \@params);
  }
  
  sub ListPodDisruptionBudgetForAllNamespaces {
    my ($self, @params) = @_;
    $self->_invoke_versioned('ListPodDisruptionBudgetForAllNamespaces', \@params);
  }
  
  sub ListPodSecurityPolicy {
    my ($self, @params) = @_;
    $self->_invoke_versioned('ListPodSecurityPolicy', \@params);
  }
  
  sub PatchNamespacedPodDisruptionBudget {
    my ($self, @params) = @_;
    $self->_invoke_versioned('PatchNamespacedPodDisruptionBudget', \@params);
  }
  
  sub PatchNamespacedPodDisruptionBudgetStatus {
    my ($self, @params) = @_;
    $self->_invoke_versioned('PatchNamespacedPodDisruptionBudgetStatus', \@params);
  }
  
  sub PatchPodSecurityPolicy {
    my ($self, @params) = @_;
    $self->_invoke_versioned('PatchPodSecurityPolicy', \@params);
  }
  
  sub ReadNamespacedPodDisruptionBudget {
    my ($self, @params) = @_;
    $self->_invoke_versioned('ReadNamespacedPodDisruptionBudget', \@params);
  }
  
  sub ReadNamespacedPodDisruptionBudgetStatus {
    my ($self, @params) = @_;
    $self->_invoke_versioned('ReadNamespacedPodDisruptionBudgetStatus', \@params);
  }
  
  sub ReadPodSecurityPolicy {
    my ($self, @params) = @_;
    $self->_invoke_versioned('ReadPodSecurityPolicy', \@params);
  }
  
  sub ReplaceNamespacedPodDisruptionBudget {
    my ($self, @params) = @_;
    $self->_invoke_versioned('ReplaceNamespacedPodDisruptionBudget', \@params);
  }
  
  sub ReplaceNamespacedPodDisruptionBudgetStatus {
    my ($self, @params) = @_;
    $self->_invoke_versioned('ReplaceNamespacedPodDisruptionBudgetStatus', \@params);
  }
  
  sub ReplacePodSecurityPolicy {
    my ($self, @params) = @_;
    $self->_invoke_versioned('ReplacePodSecurityPolicy', \@params);
  }
  
  sub WatchNamespacedPodDisruptionBudget {
    my ($self, @params) = @_;
    $self->_invoke_versioned('WatchNamespacedPodDisruptionBudget', \@params);
  }
  
  sub WatchNamespacedPodDisruptionBudgetList {
    my ($self, @params) = @_;
    $self->_invoke_versioned('WatchNamespacedPodDisruptionBudgetList', \@params);
  }
  
  sub WatchPodDisruptionBudgetListForAllNamespaces {
    my ($self, @params) = @_;
    $self->_invoke_versioned('WatchPodDisruptionBudgetListForAllNamespaces', \@params);
  }
  
  sub WatchPodSecurityPolicy {
    my ($self, @params) = @_;
    $self->_invoke_versioned('WatchPodSecurityPolicy', \@params);
  }
  
  sub WatchPodSecurityPolicyList {
    my ($self, @params) = @_;
    $self->_invoke_versioned('WatchPodSecurityPolicyList', \@params);
  }
  
1;
