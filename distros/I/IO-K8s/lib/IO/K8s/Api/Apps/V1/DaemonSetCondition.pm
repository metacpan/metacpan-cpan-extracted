package IO::K8s::Api::Apps::V1::DaemonSetCondition;
  use Moose;

  has 'lastTransitionTime' => (is => 'ro', isa => 'Str'  );
  has 'message' => (is => 'ro', isa => 'Str'  );
  has 'reason' => (is => 'ro', isa => 'Str'  );
  has 'status' => (is => 'ro', isa => 'Str'  );
  has 'type' => (is => 'ro', isa => 'Str'  );
1;
