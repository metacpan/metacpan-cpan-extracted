package Kubernetes::REST::Server;
  use Moo;
  use Types::Standard qw/Str Bool/;

  has endpoint => (is => 'ro', isa => Str, required => 1);

  has ssl_verify_server => (is => 'ro', isa => Bool, default => 1);
  has ssl_cert_file => (is => 'ro');
  has ssl_key_file => (is => 'ro');
  has ssl_ca_file => (is => 'ro');

1;
