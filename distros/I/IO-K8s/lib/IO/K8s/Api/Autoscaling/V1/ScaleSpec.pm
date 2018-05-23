package IO::K8s::Api::Autoscaling::V1::ScaleSpec;
  use Moose;
  use IO::K8s;

  has 'replicas' => (is => 'ro', isa => 'Int'  );

  sub to_json { IO::K8s->new->object_to_json(shift) }
1;
