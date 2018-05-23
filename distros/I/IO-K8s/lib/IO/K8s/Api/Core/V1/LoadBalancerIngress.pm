package IO::K8s::Api::Core::V1::LoadBalancerIngress;
  use Moose;
  use IO::K8s;

  has 'hostname' => (is => 'ro', isa => 'Str'  );
  has 'ip' => (is => 'ro', isa => 'Str'  );

  sub to_json { IO::K8s->new->object_to_json(shift) }
1;
