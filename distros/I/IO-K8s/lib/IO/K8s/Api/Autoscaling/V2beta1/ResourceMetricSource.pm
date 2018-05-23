package IO::K8s::Api::Autoscaling::V2beta1::ResourceMetricSource;
  use Moose;
  use IO::K8s;

  has 'name' => (is => 'ro', isa => 'Str'  );
  has 'targetAverageUtilization' => (is => 'ro', isa => 'Int'  );
  has 'targetAverageValue' => (is => 'ro', isa => 'Str'  );

  sub to_json { IO::K8s->new->object_to_json(shift) }
1;
