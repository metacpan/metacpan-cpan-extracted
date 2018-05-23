package IO::K8s::Api::Autoscaling::V2beta1::MetricSpec;
  use Moose;
  use IO::K8s;

  has 'external' => (is => 'ro', isa => 'IO::K8s::Api::Autoscaling::V2beta1::ExternalMetricSource'  );
  has 'object' => (is => 'ro', isa => 'IO::K8s::Api::Autoscaling::V2beta1::ObjectMetricSource'  );
  has 'pods' => (is => 'ro', isa => 'IO::K8s::Api::Autoscaling::V2beta1::PodsMetricSource'  );
  has 'resource' => (is => 'ro', isa => 'IO::K8s::Api::Autoscaling::V2beta1::ResourceMetricSource'  );
  has 'type' => (is => 'ro', isa => 'Str'  );

  sub to_json { IO::K8s->new->object_to_json(shift) }
1;
