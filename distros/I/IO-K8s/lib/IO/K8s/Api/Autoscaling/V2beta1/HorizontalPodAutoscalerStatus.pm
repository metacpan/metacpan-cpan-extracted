package IO::K8s::Api::Autoscaling::V2beta1::HorizontalPodAutoscalerStatus;
  use Moose;
  use IO::K8s;

  has 'conditions' => (is => 'ro', isa => 'ArrayRef[IO::K8s::Api::Autoscaling::V2beta1::HorizontalPodAutoscalerCondition]'  );
  has 'currentMetrics' => (is => 'ro', isa => 'ArrayRef[IO::K8s::Api::Autoscaling::V2beta1::MetricStatus]'  );
  has 'currentReplicas' => (is => 'ro', isa => 'Int'  );
  has 'desiredReplicas' => (is => 'ro', isa => 'Int'  );
  has 'lastScaleTime' => (is => 'ro', isa => 'Str'  );
  has 'observedGeneration' => (is => 'ro', isa => 'Int'  );

  sub to_json { IO::K8s->new->object_to_json(shift) }
1;
