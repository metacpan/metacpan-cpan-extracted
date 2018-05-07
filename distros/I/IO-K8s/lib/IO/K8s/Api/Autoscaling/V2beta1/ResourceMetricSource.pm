package IO::K8s::Api::Autoscaling::V2beta1::ResourceMetricSource;
  use Moose;

  has 'name' => (is => 'ro', isa => 'Str'  );
  has 'targetAverageUtilization' => (is => 'ro', isa => 'Int'  );
  has 'targetAverageValue' => (is => 'ro', isa => 'Str'  );
1;
