package Kubernetes::REST::Call::v1::Core::ConnectHeadNodeProxy;
  use Moo;
  use Types::Standard qw/Str/;

  
  has name => (is => 'ro', isa => Str,required => 1);
  
  has path => (is => 'ro', isa => Str);
  

  sub _url_params { [
  
    { name => 'name' },
  
  ] }

  sub _query_params { [
  
    { name => 'path' },
  
  ] }

  sub _url { '/api/v1/nodes/{name}/proxy' }
  sub _method { 'HEAD' }
1;
