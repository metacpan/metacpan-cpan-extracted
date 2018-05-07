package IO::K8s::Api::Autoscaling::V2beta1::PodsMetricStatus;
  use Moose;

  has 'currentAverageValue' => (is => 'ro', isa => 'Str'  );
  has 'metricName' => (is => 'ro', isa => 'Str'  );
1;
