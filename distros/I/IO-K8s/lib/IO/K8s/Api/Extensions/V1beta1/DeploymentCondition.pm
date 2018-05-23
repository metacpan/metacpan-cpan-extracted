package IO::K8s::Api::Extensions::V1beta1::DeploymentCondition;
  use Moose;
  use IO::K8s;

  has 'lastTransitionTime' => (is => 'ro', isa => 'Str'  );
  has 'lastUpdateTime' => (is => 'ro', isa => 'Str'  );
  has 'message' => (is => 'ro', isa => 'Str'  );
  has 'reason' => (is => 'ro', isa => 'Str'  );
  has 'status' => (is => 'ro', isa => 'Str'  );
  has 'type' => (is => 'ro', isa => 'Str'  );

  sub to_json { IO::K8s->new->object_to_json(shift) }
1;
