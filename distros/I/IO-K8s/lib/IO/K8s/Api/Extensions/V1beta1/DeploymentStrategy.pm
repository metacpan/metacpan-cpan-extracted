package IO::K8s::Api::Extensions::V1beta1::DeploymentStrategy;
  use Moose;

  has 'rollingUpdate' => (is => 'ro', isa => 'IO::K8s::Api::Extensions::V1beta1::RollingUpdateDeployment'  );
  has 'type' => (is => 'ro', isa => 'Str'  );
1;
