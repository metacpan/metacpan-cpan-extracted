package Kubernetes::REST::Call::v1beta1::RbacAuthorization::ReadNamespacedRole;
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

  sub _url { '/apis/rbac.authorization.k8s.io/v1beta1/namespaces/{namespace}/roles/{name}' }
  sub _method { 'GET' }
1;
