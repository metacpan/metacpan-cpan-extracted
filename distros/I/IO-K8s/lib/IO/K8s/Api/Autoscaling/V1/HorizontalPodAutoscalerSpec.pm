package IO::K8s::Api::Autoscaling::V1::HorizontalPodAutoscalerSpec;
  use Moose;
  use IO::K8s;

  has 'maxReplicas' => (is => 'ro', isa => 'Int'  );
  has 'minReplicas' => (is => 'ro', isa => 'Int'  );
  has 'scaleTargetRef' => (is => 'ro', isa => 'IO::K8s::Api::Autoscaling::V1::CrossVersionObjectReference'  );
  has 'targetCPUUtilizationPercentage' => (is => 'ro', isa => 'Int'  );

  sub to_json { IO::K8s->new->object_to_json(shift) }
1;
