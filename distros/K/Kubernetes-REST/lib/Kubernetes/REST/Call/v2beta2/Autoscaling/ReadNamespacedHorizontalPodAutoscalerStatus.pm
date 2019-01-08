package Kubernetes::REST::Call::v2beta2::Autoscaling::ReadNamespacedHorizontalPodAutoscalerStatus;
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

  sub _url { '/apis/autoscaling/v2beta2/namespaces/{namespace}/horizontalpodautoscalers/{name}/status' }
  sub _method { 'GET' }
1;
