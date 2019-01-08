package Kubernetes::REST::Call::v2alpha1::Batch::DeleteNamespacedCronJob;
  use Moo;
  use Types::Standard qw/Bool Defined Int Str/;

  
  has body => (is => 'ro', isa => Defined);
  
  has dryRun => (is => 'ro', isa => Str);
  
  has gracePeriodSeconds => (is => 'ro', isa => Int);
  
  has orphanDependents => (is => 'ro', isa => Bool);
  
  has propagationPolicy => (is => 'ro', isa => Str);
  
  has name => (is => 'ro', isa => Str,required => 1);
  
  has namespace => (is => 'ro', isa => Str,required => 1);
  
  has pretty => (is => 'ro', isa => Str);
  

  sub _url_params { [
  
    { name => 'name' },
  
    { name => 'namespace' },
  
  ] }

  sub _query_params { [
  
    { name => 'dryRun' },
  
    { name => 'gracePeriodSeconds' },
  
    { name => 'orphanDependents' },
  
    { name => 'propagationPolicy' },
  
    { name => 'pretty' },
  
  ] }

  sub _url { '/apis/batch/v2alpha1/namespaces/{namespace}/cronjobs/{name}' }
  sub _method { 'DELETE' }
1;
