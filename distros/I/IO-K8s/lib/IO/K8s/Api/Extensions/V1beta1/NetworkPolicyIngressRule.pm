package IO::K8s::Api::Extensions::V1beta1::NetworkPolicyIngressRule;
  use Moose;

  has 'from' => (is => 'ro', isa => 'ArrayRef[IO::K8s::Api::Extensions::V1beta1::NetworkPolicyPeer]'  );
  has 'ports' => (is => 'ro', isa => 'ArrayRef[IO::K8s::Api::Extensions::V1beta1::NetworkPolicyPort]'  );
1;
