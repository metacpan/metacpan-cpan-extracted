package IO::K8s::Api::Apps::V1::ReplicaSetStatus;
  use Moose;

  has 'availableReplicas' => (is => 'ro', isa => 'Int'  );
  has 'conditions' => (is => 'ro', isa => 'ArrayRef[IO::K8s::Api::Apps::V1::ReplicaSetCondition]'  );
  has 'fullyLabeledReplicas' => (is => 'ro', isa => 'Int'  );
  has 'observedGeneration' => (is => 'ro', isa => 'Int'  );
  has 'readyReplicas' => (is => 'ro', isa => 'Int'  );
  has 'replicas' => (is => 'ro', isa => 'Int'  );
1;
