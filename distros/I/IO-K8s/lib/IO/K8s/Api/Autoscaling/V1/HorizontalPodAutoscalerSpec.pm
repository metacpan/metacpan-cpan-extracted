package IO::K8s::Api::Autoscaling::V1::HorizontalPodAutoscalerSpec;
  use Moose;

  has 'maxReplicas' => (is => 'ro', isa => 'Int'  );
  has 'minReplicas' => (is => 'ro', isa => 'Int'  );
  has 'scaleTargetRef' => (is => 'ro', isa => 'IO::K8s::Api::Autoscaling::V1::CrossVersionObjectReference'  );
  has 'targetCPUUtilizationPercentage' => (is => 'ro', isa => 'Int'  );
1;
