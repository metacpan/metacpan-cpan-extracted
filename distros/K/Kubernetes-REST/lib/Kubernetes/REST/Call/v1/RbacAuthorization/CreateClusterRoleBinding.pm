package Kubernetes::REST::Call::v1::RbacAuthorization::CreateClusterRoleBinding;
  use Moo;
  use Types::Standard qw/Bool Defined Str/;

  
  has body => (is => 'ro', isa => Defined,required => 1);
  
  has dryRun => (is => 'ro', isa => Str);
  
  has includeUninitialized => (is => 'ro', isa => Bool);
  
  has pretty => (is => 'ro', isa => Str);
  
  sub _body_params { [
  
    { name => 'body' },
  
  ] }
  sub _url_params { [
  
  ] }

  sub _query_params { [
  
    { name => 'dryRun' },
  
    { name => 'includeUninitialized' },
  
    { name => 'pretty' },
  
  ] }

  sub _url { '/apis/rbac.authorization.k8s.io/v1/clusterrolebindings' }
  sub _method { 'POST' }
1;
