package IO::K8s::Api::Apps::V1beta2::DaemonSetStatus;
  use Moose;

  has 'collisionCount' => (is => 'ro', isa => 'Int'  );
  has 'conditions' => (is => 'ro', isa => 'ArrayRef[IO::K8s::Api::Apps::V1beta2::DaemonSetCondition]'  );
  has 'currentNumberScheduled' => (is => 'ro', isa => 'Int'  );
  has 'desiredNumberScheduled' => (is => 'ro', isa => 'Int'  );
  has 'numberAvailable' => (is => 'ro', isa => 'Int'  );
  has 'numberMisscheduled' => (is => 'ro', isa => 'Int'  );
  has 'numberReady' => (is => 'ro', isa => 'Int'  );
  has 'numberUnavailable' => (is => 'ro', isa => 'Int'  );
  has 'observedGeneration' => (is => 'ro', isa => 'Int'  );
  has 'updatedNumberScheduled' => (is => 'ro', isa => 'Int'  );
1;
