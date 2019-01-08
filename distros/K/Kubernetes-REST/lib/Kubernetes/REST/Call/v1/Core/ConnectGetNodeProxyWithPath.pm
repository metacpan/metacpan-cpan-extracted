package Kubernetes::REST::Call::v1::Core::ConnectGetNodeProxyWithPath;
  use Moo;
  use Types::Standard qw/Str/;

  
  has name => (is => 'ro', isa => Str,required => 1);
  
  has path => (is => 'ro', isa => Str,required => 1);
  
  has path => (is => 'ro', isa => Str);
  

  sub _url_params { [
  
    { name => 'name' },
  
    { name => 'path' },
  
  ] }

  sub _query_params { [
  
    { name => 'path' },
  
  ] }

  sub _url { '/api/v1/nodes/{name}/proxy/{path}' }
  sub _method { 'GET' }
1;
