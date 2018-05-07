package IO::K8s::Api::Batch::V1::JobStatus;
  use Moose;

  has 'active' => (is => 'ro', isa => 'Int'  );
  has 'completionTime' => (is => 'ro', isa => 'Str'  );
  has 'conditions' => (is => 'ro', isa => 'ArrayRef[IO::K8s::Api::Batch::V1::JobCondition]'  );
  has 'failed' => (is => 'ro', isa => 'Int'  );
  has 'startTime' => (is => 'ro', isa => 'Str'  );
  has 'succeeded' => (is => 'ro', isa => 'Int'  );
1;
