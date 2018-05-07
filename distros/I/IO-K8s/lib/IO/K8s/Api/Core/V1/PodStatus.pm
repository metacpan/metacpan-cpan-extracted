package IO::K8s::Api::Core::V1::PodStatus;
  use Moose;

  has 'conditions' => (is => 'ro', isa => 'ArrayRef[IO::K8s::Api::Core::V1::PodCondition]'  );
  has 'containerStatuses' => (is => 'ro', isa => 'ArrayRef[IO::K8s::Api::Core::V1::ContainerStatus]'  );
  has 'hostIP' => (is => 'ro', isa => 'Str'  );
  has 'initContainerStatuses' => (is => 'ro', isa => 'ArrayRef[IO::K8s::Api::Core::V1::ContainerStatus]'  );
  has 'message' => (is => 'ro', isa => 'Str'  );
  has 'nominatedNodeName' => (is => 'ro', isa => 'Str'  );
  has 'phase' => (is => 'ro', isa => 'Str'  );
  has 'podIP' => (is => 'ro', isa => 'Str'  );
  has 'qosClass' => (is => 'ro', isa => 'Str'  );
  has 'reason' => (is => 'ro', isa => 'Str'  );
  has 'startTime' => (is => 'ro', isa => 'Str'  );
1;
