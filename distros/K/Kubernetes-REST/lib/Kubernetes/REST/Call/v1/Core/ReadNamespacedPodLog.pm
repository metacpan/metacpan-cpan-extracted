package Kubernetes::REST::Call::v1::Core::ReadNamespacedPodLog;
  use Moo;
  use Types::Standard qw/Bool Int Str/;

  
  has container => (is => 'ro', isa => Str);
  
  has follow => (is => 'ro', isa => Bool);
  
  has limitBytes => (is => 'ro', isa => Int);
  
  has name => (is => 'ro', isa => Str,required => 1);
  
  has namespace => (is => 'ro', isa => Str,required => 1);
  
  has pretty => (is => 'ro', isa => Str);
  
  has previous => (is => 'ro', isa => Bool);
  
  has sinceSeconds => (is => 'ro', isa => Int);
  
  has tailLines => (is => 'ro', isa => Int);
  
  has timestamps => (is => 'ro', isa => Bool);
  

  sub _url_params { [
  
    { name => 'name' },
  
    { name => 'namespace' },
  
  ] }

  sub _query_params { [
  
    { name => 'container' },
  
    { name => 'follow' },
  
    { name => 'limitBytes' },
  
    { name => 'pretty' },
  
    { name => 'previous' },
  
    { name => 'sinceSeconds' },
  
    { name => 'tailLines' },
  
    { name => 'timestamps' },
  
  ] }

  sub _url { '/api/v1/namespaces/{namespace}/pods/{name}/log' }
  sub _method { 'GET' }
1;
