package IO::K8s::Api::Autoscaling::V2beta1::ExternalMetricStatus;
  use Moose;

  has 'currentAverageValue' => (is => 'ro', isa => 'Str'  );
  has 'currentValue' => (is => 'ro', isa => 'Str'  );
  has 'metricName' => (is => 'ro', isa => 'Str'  );
  has 'metricSelector' => (is => 'ro', isa => 'IO::K8s::Apimachinery::Pkg::Apis::Meta::V1::LabelSelector'  );
1;
