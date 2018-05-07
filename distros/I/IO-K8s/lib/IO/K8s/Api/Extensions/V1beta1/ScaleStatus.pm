package IO::K8s::Api::Extensions::V1beta1::ScaleStatus;
  use Moose;

  has 'replicas' => (is => 'ro', isa => 'Int'  );
  has 'selector' => (is => 'ro', isa => 'HashRef[Str]'  );
  has 'targetSelector' => (is => 'ro', isa => 'Str'  );
1;
