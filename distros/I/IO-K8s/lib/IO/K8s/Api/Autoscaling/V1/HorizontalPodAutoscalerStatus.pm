package IO::K8s::Api::Autoscaling::V1::HorizontalPodAutoscalerStatus;
  use Moose;
  use IO::K8s;

  has 'currentCPUUtilizationPercentage' => (is => 'ro', isa => 'Int'  );
  has 'currentReplicas' => (is => 'ro', isa => 'Int'  );
  has 'desiredReplicas' => (is => 'ro', isa => 'Int'  );
  has 'lastScaleTime' => (is => 'ro', isa => 'Str'  );
  has 'observedGeneration' => (is => 'ro', isa => 'Int'  );

  sub to_json { IO::K8s->new->object_to_json(shift) }
1;
