package IO::K8s::Api::Autoscaling::V2beta1::ObjectMetricSource;
  use Moose;
  use IO::K8s;

  has 'metricName' => (is => 'ro', isa => 'Str'  );
  has 'target' => (is => 'ro', isa => 'IO::K8s::Api::Autoscaling::V2beta1::CrossVersionObjectReference'  );
  has 'targetValue' => (is => 'ro', isa => 'Str'  );

  sub to_json { IO::K8s->new->object_to_json(shift) }
1;
