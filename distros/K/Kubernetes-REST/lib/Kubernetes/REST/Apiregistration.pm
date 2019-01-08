package Kubernetes::REST::Apiregistration;
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
      method => $self->api_version . '::Apiregistration::' . $method,
      params => $params,
      server => $self->server,
      credentials => $self->credentials,
    );
    my $req = $self->param_converter->params2request($call);
    my $result = $self->io->call($call, $req);
    return $self->result_parser->result2return($call, $req, $result);
  }

  
  sub CreateAPIService {
    my ($self, @params) = @_;
    $self->_invoke_versioned('CreateAPIService', \@params);
  }
  
  sub DeleteAPIService {
    my ($self, @params) = @_;
    $self->_invoke_versioned('DeleteAPIService', \@params);
  }
  
  sub DeleteCollectionAPIService {
    my ($self, @params) = @_;
    $self->_invoke_versioned('DeleteCollectionAPIService', \@params);
  }
  
  sub GetAPIResources {
    my ($self, @params) = @_;
    $self->_invoke_versioned('GetAPIResources', \@params);
  }
  
  sub GetApiregistrationAPIGroup {
    my ($self, @params) = @_;
    $self->_invoke_unversioned('GetApiregistrationAPIGroup', \@params);
  }
  
  sub ListAPIService {
    my ($self, @params) = @_;
    $self->_invoke_versioned('ListAPIService', \@params);
  }
  
  sub PatchAPIService {
    my ($self, @params) = @_;
    $self->_invoke_versioned('PatchAPIService', \@params);
  }
  
  sub PatchAPIServiceStatus {
    my ($self, @params) = @_;
    $self->_invoke_versioned('PatchAPIServiceStatus', \@params);
  }
  
  sub ReadAPIService {
    my ($self, @params) = @_;
    $self->_invoke_versioned('ReadAPIService', \@params);
  }
  
  sub ReadAPIServiceStatus {
    my ($self, @params) = @_;
    $self->_invoke_versioned('ReadAPIServiceStatus', \@params);
  }
  
  sub ReplaceAPIService {
    my ($self, @params) = @_;
    $self->_invoke_versioned('ReplaceAPIService', \@params);
  }
  
  sub ReplaceAPIServiceStatus {
    my ($self, @params) = @_;
    $self->_invoke_versioned('ReplaceAPIServiceStatus', \@params);
  }
  
  sub WatchAPIService {
    my ($self, @params) = @_;
    $self->_invoke_versioned('WatchAPIService', \@params);
  }
  
  sub WatchAPIServiceList {
    my ($self, @params) = @_;
    $self->_invoke_versioned('WatchAPIServiceList', \@params);
  }
  
1;
