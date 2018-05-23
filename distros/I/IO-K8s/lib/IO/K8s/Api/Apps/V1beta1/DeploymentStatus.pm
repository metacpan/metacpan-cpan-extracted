package IO::K8s::Api::Apps::V1beta1::DeploymentStatus;
  use Moose;
  use IO::K8s;

  has 'availableReplicas' => (is => 'ro', isa => 'Int'  );
  has 'collisionCount' => (is => 'ro', isa => 'Int'  );
  has 'conditions' => (is => 'ro', isa => 'ArrayRef[IO::K8s::Api::Apps::V1beta1::DeploymentCondition]'  );
  has 'observedGeneration' => (is => 'ro', isa => 'Int'  );
  has 'readyReplicas' => (is => 'ro', isa => 'Int'  );
  has 'replicas' => (is => 'ro', isa => 'Int'  );
  has 'unavailableReplicas' => (is => 'ro', isa => 'Int'  );
  has 'updatedReplicas' => (is => 'ro', isa => 'Int'  );

  sub to_json { IO::K8s->new->object_to_json(shift) }
1;
