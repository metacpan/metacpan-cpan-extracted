package Kubernetes::REST::Call::v1::Core::ConnectPostNamespacedPodPortforward;
  use Moo;
  use Types::Standard qw/Int Str/;

  
  has name => (is => 'ro', isa => Str,required => 1);
  
  has namespace => (is => 'ro', isa => Str,required => 1);
  
  has ports => (is => 'ro', isa => Int);
  

  sub _url_params { [
  
    { name => 'name' },
  
    { name => 'namespace' },
  
  ] }

  sub _query_params { [
  
    { name => 'ports' },
  
  ] }

  sub _url { '/api/v1/namespaces/{namespace}/pods/{name}/portforward' }
  sub _method { 'POST' }
1;
