package IO::K8s::Api::Extensions::V1beta1::ScaleSpec;
  use Moose;

  has 'replicas' => (is => 'ro', isa => 'Int'  );
1;
