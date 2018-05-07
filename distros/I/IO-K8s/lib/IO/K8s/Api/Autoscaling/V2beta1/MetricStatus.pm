package IO::K8s::Api::Autoscaling::V2beta1::MetricStatus;
  use Moose;

  has 'external' => (is => 'ro', isa => 'IO::K8s::Api::Autoscaling::V2beta1::ExternalMetricStatus'  );
  has 'object' => (is => 'ro', isa => 'IO::K8s::Api::Autoscaling::V2beta1::ObjectMetricStatus'  );
  has 'pods' => (is => 'ro', isa => 'IO::K8s::Api::Autoscaling::V2beta1::PodsMetricStatus'  );
  has 'resource' => (is => 'ro', isa => 'IO::K8s::Api::Autoscaling::V2beta1::ResourceMetricStatus'  );
  has 'type' => (is => 'ro', isa => 'Str'  );
1;
