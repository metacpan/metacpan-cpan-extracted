package IO::K8s::Api::Core::V1::ServiceStatus;
  use Moose;
  use IO::K8s;

  has 'loadBalancer' => (is => 'ro', isa => 'IO::K8s::Api::Core::V1::LoadBalancerStatus'  );

  sub to_json { IO::K8s->new->object_to_json(shift) }
1;
