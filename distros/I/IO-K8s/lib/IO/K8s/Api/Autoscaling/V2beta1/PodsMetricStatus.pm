package IO::K8s::Api::Autoscaling::V2beta1::PodsMetricStatus;
  use Moose;
  use IO::K8s;

  has 'currentAverageValue' => (is => 'ro', isa => 'Str'  );
  has 'metricName' => (is => 'ro', isa => 'Str'  );

  sub to_json { IO::K8s->new->object_to_json(shift) }
1;
