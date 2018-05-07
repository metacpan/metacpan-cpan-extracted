package IO::K8s::Api::Batch::V1::JobCondition;
  use Moose;

  has 'lastProbeTime' => (is => 'ro', isa => 'Str'  );
  has 'lastTransitionTime' => (is => 'ro', isa => 'Str'  );
  has 'message' => (is => 'ro', isa => 'Str'  );
  has 'reason' => (is => 'ro', isa => 'Str'  );
  has 'status' => (is => 'ro', isa => 'Str'  );
  has 'type' => (is => 'ro', isa => 'Str'  );
1;
