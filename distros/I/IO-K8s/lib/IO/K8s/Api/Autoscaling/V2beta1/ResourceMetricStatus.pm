package IO::K8s::Api::Autoscaling::V2beta1::ResourceMetricStatus;
  use Moose;
  use IO::K8s;

  has 'currentAverageUtilization' => (is => 'ro', isa => 'Int'  );
  has 'currentAverageValue' => (is => 'ro', isa => 'Str'  );
  has 'name' => (is => 'ro', isa => 'Str'  );

  sub to_json { IO::K8s->new->object_to_json(shift) }
1;
