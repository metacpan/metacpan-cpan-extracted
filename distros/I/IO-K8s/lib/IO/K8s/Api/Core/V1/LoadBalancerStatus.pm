package IO::K8s::Api::Core::V1::LoadBalancerStatus;
  use Moose;
  use IO::K8s;

  has 'ingress' => (is => 'ro', isa => 'ArrayRef[IO::K8s::Api::Core::V1::LoadBalancerIngress]'  );

  sub to_json { IO::K8s->new->object_to_json(shift) }
1;
