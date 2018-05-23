package IO::K8s::Api::Networking::V1::NetworkPolicyIngressRule;
  use Moose;
  use IO::K8s;

  has 'from' => (is => 'ro', isa => 'ArrayRef[IO::K8s::Api::Networking::V1::NetworkPolicyPeer]'  );
  has 'ports' => (is => 'ro', isa => 'ArrayRef[IO::K8s::Api::Networking::V1::NetworkPolicyPort]'  );

  sub to_json { IO::K8s->new->object_to_json(shift) }
1;
