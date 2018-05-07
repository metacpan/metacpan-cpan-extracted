package IO::K8s::Api::Core::V1::ContainerStateTerminated;
  use Moose;

  has 'containerID' => (is => 'ro', isa => 'Str'  );
  has 'exitCode' => (is => 'ro', isa => 'Int'  );
  has 'finishedAt' => (is => 'ro', isa => 'Str'  );
  has 'message' => (is => 'ro', isa => 'Str'  );
  has 'reason' => (is => 'ro', isa => 'Str'  );
  has 'signal' => (is => 'ro', isa => 'Int'  );
  has 'startedAt' => (is => 'ro', isa => 'Str'  );
1;
