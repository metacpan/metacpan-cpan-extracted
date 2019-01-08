package Kubernetes::REST::Call::v1::Core::ConnectGetNamespacedPodAttach;
  use Moo;
  use Types::Standard qw/Bool Str/;

  
  has container => (is => 'ro', isa => Str);
  
  has name => (is => 'ro', isa => Str,required => 1);
  
  has namespace => (is => 'ro', isa => Str,required => 1);
  
  has stderr => (is => 'ro', isa => Bool);
  
  has stdin => (is => 'ro', isa => Bool);
  
  has stdout => (is => 'ro', isa => Bool);
  
  has tty => (is => 'ro', isa => Bool);
  

  sub _url_params { [
  
    { name => 'name' },
  
    { name => 'namespace' },
  
  ] }

  sub _query_params { [
  
    { name => 'container' },
  
    { name => 'stderr' },
  
    { name => 'stdin' },
  
    { name => 'stdout' },
  
    { name => 'tty' },
  
  ] }

  sub _url { '/api/v1/namespaces/{namespace}/pods/{name}/attach' }
  sub _method { 'GET' }
1;
