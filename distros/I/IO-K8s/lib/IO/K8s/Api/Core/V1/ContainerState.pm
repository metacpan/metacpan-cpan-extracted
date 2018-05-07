package IO::K8s::Api::Core::V1::ContainerState;
  use Moose;

  has 'running' => (is => 'ro', isa => 'IO::K8s::Api::Core::V1::ContainerStateRunning'  );
  has 'terminated' => (is => 'ro', isa => 'IO::K8s::Api::Core::V1::ContainerStateTerminated'  );
  has 'waiting' => (is => 'ro', isa => 'IO::K8s::Api::Core::V1::ContainerStateWaiting'  );
1;
