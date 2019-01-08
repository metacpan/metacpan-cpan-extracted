package Kubernetes::REST::Call::v1alpha1::Storage::DeleteCollectionVolumeAttachment;
  use Moo;
  use Types::Standard qw/Bool Int Str/;

  
  has continue => (is => 'ro', isa => Str);
  
  has fieldSelector => (is => 'ro', isa => Str);
  
  has labelSelector => (is => 'ro', isa => Str);
  
  has limit => (is => 'ro', isa => Int);
  
  has resourceVersion => (is => 'ro', isa => Str);
  
  has timeoutSeconds => (is => 'ro', isa => Int);
  
  has watch => (is => 'ro', isa => Bool);
  
  has includeUninitialized => (is => 'ro', isa => Bool);
  
  has pretty => (is => 'ro', isa => Str);
  

  sub _url_params { [
  
  ] }

  sub _query_params { [
  
    { name => 'continue' },
  
    { name => 'fieldSelector' },
  
    { name => 'labelSelector' },
  
    { name => 'limit' },
  
    { name => 'resourceVersion' },
  
    { name => 'timeoutSeconds' },
  
    { name => 'watch' },
  
    { name => 'includeUninitialized' },
  
    { name => 'pretty' },
  
  ] }

  sub _url { '/apis/storage.k8s.io/v1alpha1/volumeattachments' }
  sub _method { 'DELETE' }
1;
