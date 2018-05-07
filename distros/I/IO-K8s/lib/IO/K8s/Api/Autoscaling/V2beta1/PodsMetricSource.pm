package IO::K8s::Api::Autoscaling::V2beta1::PodsMetricSource;
  use Moose;

  has 'metricName' => (is => 'ro', isa => 'Str'  );
  has 'targetAverageValue' => (is => 'ro', isa => 'Str'  );
1;
