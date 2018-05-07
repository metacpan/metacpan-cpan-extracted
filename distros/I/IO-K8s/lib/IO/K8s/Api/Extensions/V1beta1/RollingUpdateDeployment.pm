package IO::K8s::Api::Extensions::V1beta1::RollingUpdateDeployment;
  use Moose;

  has 'maxSurge' => (is => 'ro', isa => 'Str'  );
  has 'maxUnavailable' => (is => 'ro', isa => 'Str'  );
1;
