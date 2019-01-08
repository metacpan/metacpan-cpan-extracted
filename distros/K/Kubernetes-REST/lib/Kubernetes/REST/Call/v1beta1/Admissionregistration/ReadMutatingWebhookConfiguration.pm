package Kubernetes::REST::Call::v1beta1::Admissionregistration::ReadMutatingWebhookConfiguration;
  use Moo;
  use Types::Standard qw/Bool Str/;

  
  has exact => (is => 'ro', isa => Bool);
  
  has export => (is => 'ro', isa => Bool);
  
  has name => (is => 'ro', isa => Str,required => 1);
  
  has pretty => (is => 'ro', isa => Str);
  

  sub _url_params { [
  
    { name => 'name' },
  
  ] }

  sub _query_params { [
  
    { name => 'exact' },
  
    { name => 'export' },
  
    { name => 'pretty' },
  
  ] }

  sub _url { '/apis/admissionregistration.k8s.io/v1beta1/mutatingwebhookconfigurations/{name}' }
  sub _method { 'GET' }
1;
