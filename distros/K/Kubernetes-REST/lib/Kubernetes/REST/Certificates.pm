package Kubernetes::REST::Certificates;
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
      method => $self->api_version . '::Certificates::' . $method,
      params => $params,
      server => $self->server,
      credentials => $self->credentials,
    );
    my $req = $self->param_converter->params2request($call);
    my $result = $self->io->call($call, $req);
    return $self->result_parser->result2return($call, $req, $result);
  }

  
  sub CreateCertificateSigningRequest {
    my ($self, @params) = @_;
    $self->_invoke_versioned('CreateCertificateSigningRequest', \@params);
  }
  
  sub DeleteCertificateSigningRequest {
    my ($self, @params) = @_;
    $self->_invoke_versioned('DeleteCertificateSigningRequest', \@params);
  }
  
  sub DeleteCollectionCertificateSigningRequest {
    my ($self, @params) = @_;
    $self->_invoke_versioned('DeleteCollectionCertificateSigningRequest', \@params);
  }
  
  sub GetAPIResources {
    my ($self, @params) = @_;
    $self->_invoke_versioned('GetAPIResources', \@params);
  }
  
  sub GetCertificatesAPIGroup {
    my ($self, @params) = @_;
    $self->_invoke_unversioned('GetCertificatesAPIGroup', \@params);
  }
  
  sub ListCertificateSigningRequest {
    my ($self, @params) = @_;
    $self->_invoke_versioned('ListCertificateSigningRequest', \@params);
  }
  
  sub PatchCertificateSigningRequest {
    my ($self, @params) = @_;
    $self->_invoke_versioned('PatchCertificateSigningRequest', \@params);
  }
  
  sub PatchCertificateSigningRequestStatus {
    my ($self, @params) = @_;
    $self->_invoke_versioned('PatchCertificateSigningRequestStatus', \@params);
  }
  
  sub ReadCertificateSigningRequest {
    my ($self, @params) = @_;
    $self->_invoke_versioned('ReadCertificateSigningRequest', \@params);
  }
  
  sub ReadCertificateSigningRequestStatus {
    my ($self, @params) = @_;
    $self->_invoke_versioned('ReadCertificateSigningRequestStatus', \@params);
  }
  
  sub ReplaceCertificateSigningRequest {
    my ($self, @params) = @_;
    $self->_invoke_versioned('ReplaceCertificateSigningRequest', \@params);
  }
  
  sub ReplaceCertificateSigningRequestApproval {
    my ($self, @params) = @_;
    $self->_invoke_versioned('ReplaceCertificateSigningRequestApproval', \@params);
  }
  
  sub ReplaceCertificateSigningRequestStatus {
    my ($self, @params) = @_;
    $self->_invoke_versioned('ReplaceCertificateSigningRequestStatus', \@params);
  }
  
  sub WatchCertificateSigningRequest {
    my ($self, @params) = @_;
    $self->_invoke_versioned('WatchCertificateSigningRequest', \@params);
  }
  
  sub WatchCertificateSigningRequestList {
    my ($self, @params) = @_;
    $self->_invoke_versioned('WatchCertificateSigningRequestList', \@params);
  }
  
1;
