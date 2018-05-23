package IO::K8s::Api::Apps::V1beta1::StatefulSetStatus;
  use Moose;
  use IO::K8s;

  has 'collisionCount' => (is => 'ro', isa => 'Int'  );
  has 'conditions' => (is => 'ro', isa => 'ArrayRef[IO::K8s::Api::Apps::V1beta1::StatefulSetCondition]'  );
  has 'currentReplicas' => (is => 'ro', isa => 'Int'  );
  has 'currentRevision' => (is => 'ro', isa => 'Str'  );
  has 'observedGeneration' => (is => 'ro', isa => 'Int'  );
  has 'readyReplicas' => (is => 'ro', isa => 'Int'  );
  has 'replicas' => (is => 'ro', isa => 'Int'  );
  has 'updatedReplicas' => (is => 'ro', isa => 'Int'  );
  has 'updateRevision' => (is => 'ro', isa => 'Str'  );

  sub to_json { IO::K8s->new->object_to_json(shift) }
1;
