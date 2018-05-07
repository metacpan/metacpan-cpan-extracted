package IO::K8s::Api::Autoscaling::V1::ScaleStatus;
  use Moose;

  has 'replicas' => (is => 'ro', isa => 'Int'  );
  has 'selector' => (is => 'ro', isa => 'Str'  );
1;
