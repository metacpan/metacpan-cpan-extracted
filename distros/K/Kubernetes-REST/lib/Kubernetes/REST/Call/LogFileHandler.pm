package Kubernetes::REST::Call::LogFileHandler;
  use Moo;
  use Types::Standard qw/Str/;

  
  has logpath => (is => 'ro', isa => Str,required => 1);
  

  sub _url_params { [
  
    { name => 'logpath' },
  
  ] }

  sub _query_params { [
  
  ] }

  sub _url { '/logs/{logpath}' }
  sub _method { 'GET' }
1;
