package IO::K8s::Api::Networking::V1::NetworkPolicyEgressRule;
  use Moose;
  use IO::K8s;

  has 'ports' => (is => 'ro', isa => 'ArrayRef[IO::K8s::Api::Networking::V1::NetworkPolicyPort]'  );
  has 'to' => (is => 'ro', isa => 'ArrayRef[IO::K8s::Api::Networking::V1::NetworkPolicyPeer]'  );

  sub to_json { IO::K8s->new->object_to_json(shift) }
1;
