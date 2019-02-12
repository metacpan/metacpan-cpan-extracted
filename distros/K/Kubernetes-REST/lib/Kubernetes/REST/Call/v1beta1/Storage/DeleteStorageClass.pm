package Kubernetes::REST::Call::v1beta1::Storage::DeleteStorageClass;
  use Moo;
  use Types::Standard qw/Bool Defined Int Str/;

  
  has body => (is => 'ro', isa => Defined);
  
  has dryRun => (is => 'ro', isa => Str);
  
  has gracePeriodSeconds => (is => 'ro', isa => Int);
  
  has orphanDependents => (is => 'ro', isa => Bool);
  
  has propagationPolicy => (is => 'ro', isa => Str);
  
  has name => (is => 'ro', isa => Str,required => 1);
  
  has pretty => (is => 'ro', isa => Str);
  
  sub _body_params { [
  
    { name => 'body' },
  
  ] }
  sub _url_params { [
  
    { name => 'name' },
  
  ] }

  sub _query_params { [
  
    { name => 'dryRun' },
  
    { name => 'gracePeriodSeconds' },
  
    { name => 'orphanDependents' },
  
    { name => 'propagationPolicy' },
  
    { name => 'pretty' },
  
  ] }

  sub _url { '/apis/storage.k8s.io/v1beta1/storageclasses/{name}' }
  sub _method { 'DELETE' }
1;
