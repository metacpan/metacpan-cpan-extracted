package IO::K8s::Api::Core::V1::NodeStatus;
  use Moose;
  use IO::K8s;

  has 'addresses' => (is => 'ro', isa => 'ArrayRef[IO::K8s::Api::Core::V1::NodeAddress]'  );
  has 'allocatable' => (is => 'ro', isa => 'HashRef[Str]'  );
  has 'capacity' => (is => 'ro', isa => 'HashRef[Str]'  );
  has 'conditions' => (is => 'ro', isa => 'ArrayRef[IO::K8s::Api::Core::V1::NodeCondition]'  );
  has 'daemonEndpoints' => (is => 'ro', isa => 'IO::K8s::Api::Core::V1::NodeDaemonEndpoints'  );
  has 'images' => (is => 'ro', isa => 'ArrayRef[IO::K8s::Api::Core::V1::ContainerImage]'  );
  has 'nodeInfo' => (is => 'ro', isa => 'IO::K8s::Api::Core::V1::NodeSystemInfo'  );
  has 'phase' => (is => 'ro', isa => 'Str'  );
  has 'volumesAttached' => (is => 'ro', isa => 'ArrayRef[IO::K8s::Api::Core::V1::AttachedVolume]'  );
  has 'volumesInUse' => (is => 'ro', isa => 'ArrayRef[Str]'  );

  sub to_json { IO::K8s->new->object_to_json(shift) }
1;
