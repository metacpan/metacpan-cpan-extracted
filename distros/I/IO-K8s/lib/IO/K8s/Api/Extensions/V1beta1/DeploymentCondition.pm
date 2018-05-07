package IO::K8s::Api::Extensions::V1beta1::DeploymentCondition;
  use Moose;

  has 'lastTransitionTime' => (is => 'ro', isa => 'Str'  );
  has 'lastUpdateTime' => (is => 'ro', isa => 'Str'  );
  has 'message' => (is => 'ro', isa => 'Str'  );
  has 'reason' => (is => 'ro', isa => 'Str'  );
  has 'status' => (is => 'ro', isa => 'Str'  );
  has 'type' => (is => 'ro', isa => 'Str'  );
1;
