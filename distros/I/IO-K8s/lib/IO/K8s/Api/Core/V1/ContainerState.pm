package IO::K8s::Api::Core::V1::ContainerState;
  use Moose;
  use IO::K8s;

  has 'running' => (is => 'ro', isa => 'IO::K8s::Api::Core::V1::ContainerStateRunning'  );
  has 'terminated' => (is => 'ro', isa => 'IO::K8s::Api::Core::V1::ContainerStateTerminated'  );
  has 'waiting' => (is => 'ro', isa => 'IO::K8s::Api::Core::V1::ContainerStateWaiting'  );

  sub to_json { IO::K8s->new->object_to_json(shift) }
1;
