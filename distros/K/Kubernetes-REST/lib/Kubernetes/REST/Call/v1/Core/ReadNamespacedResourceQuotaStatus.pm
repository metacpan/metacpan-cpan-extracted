package Kubernetes::REST::Call::v1::Core::ReadNamespacedResourceQuotaStatus;
  use Moo;
  use Types::Standard qw/Str/;

  
  has name => (is => 'ro', isa => Str,required => 1);
  
  has namespace => (is => 'ro', isa => Str,required => 1);
  
  has pretty => (is => 'ro', isa => Str);
  

  sub _url_params { [
  
    { name => 'name' },
  
    { name => 'namespace' },
  
  ] }

  sub _query_params { [
  
    { name => 'pretty' },
  
  ] }

  sub _url { '/api/v1/namespaces/{namespace}/resourcequotas/{name}/status' }
  sub _method { 'GET' }
1;
