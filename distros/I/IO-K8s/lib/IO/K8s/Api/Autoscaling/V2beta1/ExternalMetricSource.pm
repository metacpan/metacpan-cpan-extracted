package IO::K8s::Api::Autoscaling::V2beta1::ExternalMetricSource;
  use Moose;
  use IO::K8s;

  has 'metricName' => (is => 'ro', isa => 'Str'  );
  has 'metricSelector' => (is => 'ro', isa => 'IO::K8s::Apimachinery::Pkg::Apis::Meta::V1::LabelSelector'  );
  has 'targetAverageValue' => (is => 'ro', isa => 'Str'  );
  has 'targetValue' => (is => 'ro', isa => 'Str'  );

  sub to_json { IO::K8s->new->object_to_json(shift) }
1;
