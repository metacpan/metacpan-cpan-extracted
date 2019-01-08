package Kubernetes::REST::AuthToken;
  use Moo;
  use Types::Standard qw/Str/;

  has token => (is => 'ro', isa => Str, required => 1);

1;
