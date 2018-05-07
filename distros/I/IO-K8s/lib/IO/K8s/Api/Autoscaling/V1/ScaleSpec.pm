package IO::K8s::Api::Autoscaling::V1::ScaleSpec;
  use Moose;

  has 'replicas' => (is => 'ro', isa => 'Int'  );
1;
