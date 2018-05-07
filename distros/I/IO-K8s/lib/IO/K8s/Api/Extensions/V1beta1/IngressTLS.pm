package IO::K8s::Api::Extensions::V1beta1::IngressTLS;
  use Moose;

  has 'hosts' => (is => 'ro', isa => 'ArrayRef[Str]'  );
  has 'secretName' => (is => 'ro', isa => 'Str'  );
1;
