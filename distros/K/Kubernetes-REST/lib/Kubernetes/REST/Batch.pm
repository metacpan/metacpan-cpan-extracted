package Kubernetes::REST::Batch;
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
      method => $self->api_version . '::Batch::' . $method,
      params => $params,
      server => $self->server,
      credentials => $self->credentials,
    );
    my $req = $self->param_converter->params2request($call);
    my $result = $self->io->call($call, $req);
    return $self->result_parser->result2return($call, $req, $result);
  }

  
  sub CreateNamespacedCronJob {
    my ($self, @params) = @_;
    $self->_invoke_versioned('CreateNamespacedCronJob', \@params);
  }
  
  sub CreateNamespacedJob {
    my ($self, @params) = @_;
    $self->_invoke_versioned('CreateNamespacedJob', \@params);
  }
  
  sub DeleteCollectionNamespacedCronJob {
    my ($self, @params) = @_;
    $self->_invoke_versioned('DeleteCollectionNamespacedCronJob', \@params);
  }
  
  sub DeleteCollectionNamespacedJob {
    my ($self, @params) = @_;
    $self->_invoke_versioned('DeleteCollectionNamespacedJob', \@params);
  }
  
  sub DeleteNamespacedCronJob {
    my ($self, @params) = @_;
    $self->_invoke_versioned('DeleteNamespacedCronJob', \@params);
  }
  
  sub DeleteNamespacedJob {
    my ($self, @params) = @_;
    $self->_invoke_versioned('DeleteNamespacedJob', \@params);
  }
  
  sub GetAPIResources {
    my ($self, @params) = @_;
    $self->_invoke_versioned('GetAPIResources', \@params);
  }
  
  sub GetBatchAPIGroup {
    my ($self, @params) = @_;
    $self->_invoke_unversioned('GetBatchAPIGroup', \@params);
  }
  
  sub ListCronJobForAllNamespaces {
    my ($self, @params) = @_;
    $self->_invoke_versioned('ListCronJobForAllNamespaces', \@params);
  }
  
  sub ListJobForAllNamespaces {
    my ($self, @params) = @_;
    $self->_invoke_versioned('ListJobForAllNamespaces', \@params);
  }
  
  sub ListNamespacedCronJob {
    my ($self, @params) = @_;
    $self->_invoke_versioned('ListNamespacedCronJob', \@params);
  }
  
  sub ListNamespacedJob {
    my ($self, @params) = @_;
    $self->_invoke_versioned('ListNamespacedJob', \@params);
  }
  
  sub PatchNamespacedCronJob {
    my ($self, @params) = @_;
    $self->_invoke_versioned('PatchNamespacedCronJob', \@params);
  }
  
  sub PatchNamespacedCronJobStatus {
    my ($self, @params) = @_;
    $self->_invoke_versioned('PatchNamespacedCronJobStatus', \@params);
  }
  
  sub PatchNamespacedJob {
    my ($self, @params) = @_;
    $self->_invoke_versioned('PatchNamespacedJob', \@params);
  }
  
  sub PatchNamespacedJobStatus {
    my ($self, @params) = @_;
    $self->_invoke_versioned('PatchNamespacedJobStatus', \@params);
  }
  
  sub ReadNamespacedCronJob {
    my ($self, @params) = @_;
    $self->_invoke_versioned('ReadNamespacedCronJob', \@params);
  }
  
  sub ReadNamespacedCronJobStatus {
    my ($self, @params) = @_;
    $self->_invoke_versioned('ReadNamespacedCronJobStatus', \@params);
  }
  
  sub ReadNamespacedJob {
    my ($self, @params) = @_;
    $self->_invoke_versioned('ReadNamespacedJob', \@params);
  }
  
  sub ReadNamespacedJobStatus {
    my ($self, @params) = @_;
    $self->_invoke_versioned('ReadNamespacedJobStatus', \@params);
  }
  
  sub ReplaceNamespacedCronJob {
    my ($self, @params) = @_;
    $self->_invoke_versioned('ReplaceNamespacedCronJob', \@params);
  }
  
  sub ReplaceNamespacedCronJobStatus {
    my ($self, @params) = @_;
    $self->_invoke_versioned('ReplaceNamespacedCronJobStatus', \@params);
  }
  
  sub ReplaceNamespacedJob {
    my ($self, @params) = @_;
    $self->_invoke_versioned('ReplaceNamespacedJob', \@params);
  }
  
  sub ReplaceNamespacedJobStatus {
    my ($self, @params) = @_;
    $self->_invoke_versioned('ReplaceNamespacedJobStatus', \@params);
  }
  
  sub WatchCronJobListForAllNamespaces {
    my ($self, @params) = @_;
    $self->_invoke_versioned('WatchCronJobListForAllNamespaces', \@params);
  }
  
  sub WatchJobListForAllNamespaces {
    my ($self, @params) = @_;
    $self->_invoke_versioned('WatchJobListForAllNamespaces', \@params);
  }
  
  sub WatchNamespacedCronJob {
    my ($self, @params) = @_;
    $self->_invoke_versioned('WatchNamespacedCronJob', \@params);
  }
  
  sub WatchNamespacedCronJobList {
    my ($self, @params) = @_;
    $self->_invoke_versioned('WatchNamespacedCronJobList', \@params);
  }
  
  sub WatchNamespacedJob {
    my ($self, @params) = @_;
    $self->_invoke_versioned('WatchNamespacedJob', \@params);
  }
  
  sub WatchNamespacedJobList {
    my ($self, @params) = @_;
    $self->_invoke_versioned('WatchNamespacedJobList', \@params);
  }
  
1;
