package Kubernetes::REST::Call::v1::Core::ReadComponentStatus;
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

  sub _url { '/api/v1/componentstatuses/{name}' }
  sub _method { 'GET' }
1;
