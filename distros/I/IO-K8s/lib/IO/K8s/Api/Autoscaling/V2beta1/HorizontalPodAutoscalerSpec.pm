package IO::K8s::Api::Autoscaling::V2beta1::HorizontalPodAutoscalerSpec;
  use Moose;

  has 'maxReplicas' => (is => 'ro', isa => 'Int'  );
  has 'metrics' => (is => 'ro', isa => 'ArrayRef[IO::K8s::Api::Autoscaling::V2beta1::MetricSpec]'  );
  has 'minReplicas' => (is => 'ro', isa => 'Int'  );
  has 'scaleTargetRef' => (is => 'ro', isa => 'IO::K8s::Api::Autoscaling::V2beta1::CrossVersionObjectReference'  );
1;
