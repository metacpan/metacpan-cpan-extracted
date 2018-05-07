package IO::K8s::Api::Autoscaling::V2beta1::ResourceMetricStatus;
  use Moose;

  has 'currentAverageUtilization' => (is => 'ro', isa => 'Int'  );
  has 'currentAverageValue' => (is => 'ro', isa => 'Str'  );
  has 'name' => (is => 'ro', isa => 'Str'  );
1;
