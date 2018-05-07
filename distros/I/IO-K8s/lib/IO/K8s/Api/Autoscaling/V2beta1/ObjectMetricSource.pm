package IO::K8s::Api::Autoscaling::V2beta1::ObjectMetricSource;
  use Moose;

  has 'metricName' => (is => 'ro', isa => 'Str'  );
  has 'target' => (is => 'ro', isa => 'IO::K8s::Api::Autoscaling::V2beta1::CrossVersionObjectReference'  );
  has 'targetValue' => (is => 'ro', isa => 'Str'  );
1;
