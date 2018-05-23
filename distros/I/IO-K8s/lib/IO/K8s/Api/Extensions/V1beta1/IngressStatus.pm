package IO::K8s::Api::Extensions::V1beta1::IngressStatus;
  use Moose;
  use IO::K8s;

  has 'loadBalancer' => (is => 'ro', isa => 'IO::K8s::Api::Core::V1::LoadBalancerStatus'  );

  sub to_json { IO::K8s->new->object_to_json(shift) }
1;
