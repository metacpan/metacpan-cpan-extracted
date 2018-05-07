package IO::K8s::Api::Apps::V1beta2::DeploymentStrategy;
  use Moose;

  has 'rollingUpdate' => (is => 'ro', isa => 'IO::K8s::Api::Apps::V1beta2::RollingUpdateDeployment'  );
  has 'type' => (is => 'ro', isa => 'Str'  );
1;
