package IO::K8s::Api::Core::V1::ContainerStateTerminated;
  use Moose;
  use IO::K8s;

  has 'containerID' => (is => 'ro', isa => 'Str'  );
  has 'exitCode' => (is => 'ro', isa => 'Int'  );
  has 'finishedAt' => (is => 'ro', isa => 'Str'  );
  has 'message' => (is => 'ro', isa => 'Str'  );
  has 'reason' => (is => 'ro', isa => 'Str'  );
  has 'signal' => (is => 'ro', isa => 'Int'  );
  has 'startedAt' => (is => 'ro', isa => 'Str'  );

  sub to_json { IO::K8s->new->object_to_json(shift) }
1;
