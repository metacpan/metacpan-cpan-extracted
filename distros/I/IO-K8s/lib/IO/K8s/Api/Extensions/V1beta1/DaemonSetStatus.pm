package IO::K8s::Api::Extensions::V1beta1::DaemonSetStatus;
  use Moose;
  use IO::K8s;

  has 'collisionCount' => (is => 'ro', isa => 'Int'  );
  has 'conditions' => (is => 'ro', isa => 'ArrayRef[IO::K8s::Api::Extensions::V1beta1::DaemonSetCondition]'  );
  has 'currentNumberScheduled' => (is => 'ro', isa => 'Int'  );
  has 'desiredNumberScheduled' => (is => 'ro', isa => 'Int'  );
  has 'numberAvailable' => (is => 'ro', isa => 'Int'  );
  has 'numberMisscheduled' => (is => 'ro', isa => 'Int'  );
  has 'numberReady' => (is => 'ro', isa => 'Int'  );
  has 'numberUnavailable' => (is => 'ro', isa => 'Int'  );
  has 'observedGeneration' => (is => 'ro', isa => 'Int'  );
  has 'updatedNumberScheduled' => (is => 'ro', isa => 'Int'  );

  sub to_json { IO::K8s->new->object_to_json(shift) }
1;
