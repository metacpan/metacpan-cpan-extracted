package Kubernetes::REST::Autoscaling;
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
      method => $self->api_version . '::Autoscaling::' . $method,
      params => $params,
      server => $self->server,
      credentials => $self->credentials,
    );
    my $req = $self->param_converter->params2request($call);
    my $result = $self->io->call($call, $req);
    return $self->result_parser->result2return($call, $req, $result);
  }

  
  sub CreateNamespacedHorizontalPodAutoscaler {
    my ($self, @params) = @_;
    $self->_invoke_versioned('CreateNamespacedHorizontalPodAutoscaler', \@params);
  }
  
  sub DeleteCollectionNamespacedHorizontalPodAutoscaler {
    my ($self, @params) = @_;
    $self->_invoke_versioned('DeleteCollectionNamespacedHorizontalPodAutoscaler', \@params);
  }
  
  sub DeleteNamespacedHorizontalPodAutoscaler {
    my ($self, @params) = @_;
    $self->_invoke_versioned('DeleteNamespacedHorizontalPodAutoscaler', \@params);
  }
  
  sub GetAPIResources {
    my ($self, @params) = @_;
    $self->_invoke_versioned('GetAPIResources', \@params);
  }
  
  sub GetAutoscalingAPIGroup {
    my ($self, @params) = @_;
    $self->_invoke_unversioned('GetAutoscalingAPIGroup', \@params);
  }
  
  sub ListHorizontalPodAutoscalerForAllNamespaces {
    my ($self, @params) = @_;
    $self->_invoke_versioned('ListHorizontalPodAutoscalerForAllNamespaces', \@params);
  }
  
  sub ListNamespacedHorizontalPodAutoscaler {
    my ($self, @params) = @_;
    $self->_invoke_versioned('ListNamespacedHorizontalPodAutoscaler', \@params);
  }
  
  sub PatchNamespacedHorizontalPodAutoscaler {
    my ($self, @params) = @_;
    $self->_invoke_versioned('PatchNamespacedHorizontalPodAutoscaler', \@params);
  }
  
  sub PatchNamespacedHorizontalPodAutoscalerStatus {
    my ($self, @params) = @_;
    $self->_invoke_versioned('PatchNamespacedHorizontalPodAutoscalerStatus', \@params);
  }
  
  sub ReadNamespacedHorizontalPodAutoscaler {
    my ($self, @params) = @_;
    $self->_invoke_versioned('ReadNamespacedHorizontalPodAutoscaler', \@params);
  }
  
  sub ReadNamespacedHorizontalPodAutoscalerStatus {
    my ($self, @params) = @_;
    $self->_invoke_versioned('ReadNamespacedHorizontalPodAutoscalerStatus', \@params);
  }
  
  sub ReplaceNamespacedHorizontalPodAutoscaler {
    my ($self, @params) = @_;
    $self->_invoke_versioned('ReplaceNamespacedHorizontalPodAutoscaler', \@params);
  }
  
  sub ReplaceNamespacedHorizontalPodAutoscalerStatus {
    my ($self, @params) = @_;
    $self->_invoke_versioned('ReplaceNamespacedHorizontalPodAutoscalerStatus', \@params);
  }
  
  sub WatchHorizontalPodAutoscalerListForAllNamespaces {
    my ($self, @params) = @_;
    $self->_invoke_versioned('WatchHorizontalPodAutoscalerListForAllNamespaces', \@params);
  }
  
  sub WatchNamespacedHorizontalPodAutoscaler {
    my ($self, @params) = @_;
    $self->_invoke_versioned('WatchNamespacedHorizontalPodAutoscaler', \@params);
  }
  
  sub WatchNamespacedHorizontalPodAutoscalerList {
    my ($self, @params) = @_;
    $self->_invoke_versioned('WatchNamespacedHorizontalPodAutoscalerList', \@params);
  }
  
1;
