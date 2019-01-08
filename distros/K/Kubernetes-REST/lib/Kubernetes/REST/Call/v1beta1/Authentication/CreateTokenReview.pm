package Kubernetes::REST::Call::v1beta1::Authentication::CreateTokenReview;
  use Moo;
  use Types::Standard qw/Bool Defined Str/;

  
  has body => (is => 'ro', isa => Defined,required => 1);
  
  has dryRun => (is => 'ro', isa => Str);
  
  has includeUninitialized => (is => 'ro', isa => Bool);
  
  has pretty => (is => 'ro', isa => Str);
  

  sub _url_params { [
  
  ] }

  sub _query_params { [
  
    { name => 'dryRun' },
  
    { name => 'includeUninitialized' },
  
    { name => 'pretty' },
  
  ] }

  sub _url { '/apis/authentication.k8s.io/v1beta1/tokenreviews' }
  sub _method { 'POST' }
1;
