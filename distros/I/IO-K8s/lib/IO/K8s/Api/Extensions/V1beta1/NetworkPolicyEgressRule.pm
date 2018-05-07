package IO::K8s::Api::Extensions::V1beta1::NetworkPolicyEgressRule;
  use Moose;

  has 'ports' => (is => 'ro', isa => 'ArrayRef[IO::K8s::Api::Extensions::V1beta1::NetworkPolicyPort]'  );
  has 'to' => (is => 'ro', isa => 'ArrayRef[IO::K8s::Api::Extensions::V1beta1::NetworkPolicyPeer]'  );
1;
