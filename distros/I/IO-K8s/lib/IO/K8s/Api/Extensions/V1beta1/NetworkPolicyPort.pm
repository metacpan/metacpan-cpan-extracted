package IO::K8s::Api::Extensions::V1beta1::NetworkPolicyPort;
  use Moose;

  has 'port' => (is => 'ro', isa => 'Str'  );
  has 'protocol' => (is => 'ro', isa => 'Str'  );
1;
