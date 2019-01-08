package Kubernetes::REST::Call::v1beta1::Apiregistration::ReadAPIServiceStatus;
  use Moo;
  use Types::Standard qw/Str/;

  
  has name => (is => 'ro', isa => Str,required => 1);
  
  has pretty => (is => 'ro', isa => Str);
  

  sub _url_params { [
  
    { name => 'name' },
  
  ] }

  sub _query_params { [
  
    { name => 'pretty' },
  
  ] }

  sub _url { '/apis/apiregistration.k8s.io/v1beta1/apiservices/{name}/status' }
  sub _method { 'GET' }
1;
