package Kubernetes::REST::Storage;
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
      method => $self->api_version . '::Storage::' . $method,
      params => $params,
      server => $self->server,
      credentials => $self->credentials,
    );
    my $req = $self->param_converter->params2request($call);
    my $result = $self->io->call($call, $req);
    return $self->result_parser->result2return($call, $req, $result);
  }

  
  sub CreateStorageClass {
    my ($self, @params) = @_;
    $self->_invoke_versioned('CreateStorageClass', \@params);
  }
  
  sub CreateVolumeAttachment {
    my ($self, @params) = @_;
    $self->_invoke_versioned('CreateVolumeAttachment', \@params);
  }
  
  sub DeleteCollectionStorageClass {
    my ($self, @params) = @_;
    $self->_invoke_versioned('DeleteCollectionStorageClass', \@params);
  }
  
  sub DeleteCollectionVolumeAttachment {
    my ($self, @params) = @_;
    $self->_invoke_versioned('DeleteCollectionVolumeAttachment', \@params);
  }
  
  sub DeleteStorageClass {
    my ($self, @params) = @_;
    $self->_invoke_versioned('DeleteStorageClass', \@params);
  }
  
  sub DeleteVolumeAttachment {
    my ($self, @params) = @_;
    $self->_invoke_versioned('DeleteVolumeAttachment', \@params);
  }
  
  sub GetAPIResources {
    my ($self, @params) = @_;
    $self->_invoke_versioned('GetAPIResources', \@params);
  }
  
  sub GetStorageAPIGroup {
    my ($self, @params) = @_;
    $self->_invoke_unversioned('GetStorageAPIGroup', \@params);
  }
  
  sub ListStorageClass {
    my ($self, @params) = @_;
    $self->_invoke_versioned('ListStorageClass', \@params);
  }
  
  sub ListVolumeAttachment {
    my ($self, @params) = @_;
    $self->_invoke_versioned('ListVolumeAttachment', \@params);
  }
  
  sub PatchStorageClass {
    my ($self, @params) = @_;
    $self->_invoke_versioned('PatchStorageClass', \@params);
  }
  
  sub PatchVolumeAttachment {
    my ($self, @params) = @_;
    $self->_invoke_versioned('PatchVolumeAttachment', \@params);
  }
  
  sub ReadStorageClass {
    my ($self, @params) = @_;
    $self->_invoke_versioned('ReadStorageClass', \@params);
  }
  
  sub ReadVolumeAttachment {
    my ($self, @params) = @_;
    $self->_invoke_versioned('ReadVolumeAttachment', \@params);
  }
  
  sub ReplaceStorageClass {
    my ($self, @params) = @_;
    $self->_invoke_versioned('ReplaceStorageClass', \@params);
  }
  
  sub ReplaceVolumeAttachment {
    my ($self, @params) = @_;
    $self->_invoke_versioned('ReplaceVolumeAttachment', \@params);
  }
  
  sub WatchStorageClass {
    my ($self, @params) = @_;
    $self->_invoke_versioned('WatchStorageClass', \@params);
  }
  
  sub WatchStorageClassList {
    my ($self, @params) = @_;
    $self->_invoke_versioned('WatchStorageClassList', \@params);
  }
  
  sub WatchVolumeAttachment {
    my ($self, @params) = @_;
    $self->_invoke_versioned('WatchVolumeAttachment', \@params);
  }
  
  sub WatchVolumeAttachmentList {
    my ($self, @params) = @_;
    $self->_invoke_versioned('WatchVolumeAttachmentList', \@params);
  }
  
1;
