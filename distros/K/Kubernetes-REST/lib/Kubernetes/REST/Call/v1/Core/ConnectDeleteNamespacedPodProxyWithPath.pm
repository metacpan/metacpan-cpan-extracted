package Kubernetes::REST::Call::v1::Core::ConnectDeleteNamespacedPodProxyWithPath;
  use Moo;
  use Types::Standard qw/Str/;

  
  has name => (is => 'ro', isa => Str,required => 1);
  
  has namespace => (is => 'ro', isa => Str,required => 1);
  
  has path => (is => 'ro', isa => Str,required => 1);
  
  has path => (is => 'ro', isa => Str);
  

  sub _url_params { [
  
    { name => 'name' },
  
    { name => 'namespace' },
  
    { name => 'path' },
  
  ] }

  sub _query_params { [
  
    { name => 'path' },
  
  ] }

  sub _url { '/api/v1/namespaces/{namespace}/pods/{name}/proxy/{path}' }
  sub _method { 'DELETE' }
1;
