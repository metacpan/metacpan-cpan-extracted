package Kubernetes::REST::Auditregistration;
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
      method => $self->api_version . '::Auditregistration::' . $method,
      params => $params,
      server => $self->server,
      credentials => $self->credentials,
    );
    my $req = $self->param_converter->params2request($call);
    my $result = $self->io->call($call, $req);
    return $self->result_parser->result2return($call, $req, $result);
  }

  
  sub CreateAuditSink {
    my ($self, @params) = @_;
    $self->_invoke_versioned('CreateAuditSink', \@params);
  }
  
  sub DeleteAuditSink {
    my ($self, @params) = @_;
    $self->_invoke_versioned('DeleteAuditSink', \@params);
  }
  
  sub DeleteCollectionAuditSink {
    my ($self, @params) = @_;
    $self->_invoke_versioned('DeleteCollectionAuditSink', \@params);
  }
  
  sub GetAPIResources {
    my ($self, @params) = @_;
    $self->_invoke_versioned('GetAPIResources', \@params);
  }
  
  sub GetAuditregistrationAPIGroup {
    my ($self, @params) = @_;
    $self->_invoke_unversioned('GetAuditregistrationAPIGroup', \@params);
  }
  
  sub ListAuditSink {
    my ($self, @params) = @_;
    $self->_invoke_versioned('ListAuditSink', \@params);
  }
  
  sub PatchAuditSink {
    my ($self, @params) = @_;
    $self->_invoke_versioned('PatchAuditSink', \@params);
  }
  
  sub ReadAuditSink {
    my ($self, @params) = @_;
    $self->_invoke_versioned('ReadAuditSink', \@params);
  }
  
  sub ReplaceAuditSink {
    my ($self, @params) = @_;
    $self->_invoke_versioned('ReplaceAuditSink', \@params);
  }
  
  sub WatchAuditSink {
    my ($self, @params) = @_;
    $self->_invoke_versioned('WatchAuditSink', \@params);
  }
  
  sub WatchAuditSinkList {
    my ($self, @params) = @_;
    $self->_invoke_versioned('WatchAuditSinkList', \@params);
  }
  
1;
